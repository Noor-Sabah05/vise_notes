"""
Audio Processing Service
Handles noise reduction, normalization, and transcription
"""

import shutil
from pathlib import Path
import uuid
import os

import noisereduce as nr
import soundfile as sf
import numpy as np
from faster_whisper import WhisperModel

from config import UPLOADS_DIR, WHISPER_MODEL_NAME, WHISPER_DEVICE, WHISPER_COMPUTE_TYPE, WHISPER_BEAM_SIZE


class AudioProcessor:
    """Service for audio processing and transcription"""
    
    def __init__(self):
        """Initialize with Whisper model loaded at startup"""
        try:
            print(f"🔄 Loading Whisper model ({WHISPER_MODEL_NAME})...")
            print(f"   Device: {WHISPER_DEVICE} | Compute Type: {WHISPER_COMPUTE_TYPE}")
            
            self.model = WhisperModel(
                WHISPER_MODEL_NAME,
                device=WHISPER_DEVICE,
                compute_type=WHISPER_COMPUTE_TYPE,
                download_root=None,  # Use default cache location
            )
            print("✓ Whisper model loaded successfully")
        except Exception as e:
            print(f"⚠️  ERROR loading Whisper model: {str(e)}")
            print(f"⚠️  Trying to load with CPU fallback...")
            try:
                self.model = WhisperModel(
                    WHISPER_MODEL_NAME,
                    device="cpu",
                    compute_type="int8",
                )
                print("✓ Whisper model loaded with CPU fallback")
            except Exception as e2:
                print(f"❌ CRITICAL: Could not load Whisper model: {str(e2)}")
                raise
    
    def process_audio_file(self, raw_path: str, output_filename: str = None) -> dict:
        """
        Process audio through complete pipeline:
        1. Load audio
        2. Convert stereo to mono
        3. Noise reduction
        4. Peak normalization
        5. Save cleaned audio
        6. Transcribe with Whisper
        
        Args:
            raw_path: Path to raw audio file
            output_filename: Optional custom output filename
            
        Returns:
            dict: {
                'transcript': str,
                'language': str,
                'duration_seconds': float,
                'cleaned_audio_path': str,
                'file_id': str
            }
        """
        file_id = str(uuid.uuid4())
        
        try:
            # Step 1: Load audio
            print(f"  [1/5] Loading audio from {raw_path}...")
            audio, sr = sf.read(str(raw_path))
            
            # Step 2: Convert stereo to mono
            if audio.ndim > 1:
                print(f"  [2/5] Converting stereo to mono...")
                audio = audio.mean(axis=1)
            else:
                print(f"  [2/5] Audio is already mono")
            
            # Step 3: Noise reduction
            print(f"  [3/5] Applying noise reduction...")
            reduced = nr.reduce_noise(y=audio, sr=sr)
            
            # Step 4: Peak normalization
            print(f"  [4/5] Normalizing audio...")
            peak = np.max(np.abs(reduced))
            if peak > 0:
                normalized = reduced / peak
            else:
                normalized = reduced
            
            # Step 5: Save cleaned audio
            print(f"  [5/5] Saving cleaned audio...")
            clean_path = Path(UPLOADS_DIR) / f"{file_id}_clean.wav"
            sf.write(str(clean_path), normalized, sr)
            
            # Step 6: Transcribe with Whisper
            print(f"  [6/5] Transcribing with Whisper...")
            
            segments, info = self.model.transcribe(
                str(clean_path),
                beam_size=WHISPER_BEAM_SIZE,
                vad_filter=True,  # Skip silent parts automatically
            )
            
            # Join all segments into one transcript
            transcript = " ".join(seg.text.strip() for seg in segments)
            
            print(f"✓ Audio processing complete")
            
            return {
                'file_id': file_id,
                'transcript': transcript,
                'language': info.language,
                'duration_seconds': round(info.duration, 2),
                'cleaned_audio_path': str(clean_path),
            }
        
        except Exception as e:
            print(f"✗ Error processing audio: {str(e)}")
            raise Exception(f"Audio Processing Error: {str(e)}")
    
    def save_raw_audio(self, file_bytes: bytes, original_filename: str) -> tuple:
        """
        Save uploaded audio file temporarily
        
        Args:
            file_bytes: Raw file bytes
            original_filename: Original filename from upload
            
        Returns:
            tuple: (raw_path, file_extension)
        """
        try:
            # Get file extension
            ext = Path(original_filename).suffix.lower()
            
            # Create temporary path
            temp_id = str(uuid.uuid4())
            raw_path = Path(UPLOADS_DIR) / f"{temp_id}_raw{ext}"
            
            # Save file
            with open(raw_path, "wb") as f:
                f.write(file_bytes)
            
            print(f"✓ Audio saved: {raw_path}")
            return str(raw_path), ext
        
        except Exception as e:
            raise Exception(f"File Save Error: {str(e)}")
    
    def cleanup_raw_file(self, raw_path: str) -> bool:
        """Delete temporary raw audio file"""
        try:
            path = Path(raw_path)
            if path.exists():
                path.unlink()
                print(f"✓ Cleaned up: {raw_path}")
                return True
            return False
        except Exception as e:
            print(f"⚠ Warning: Could not delete {raw_path}: {str(e)}")
            return False
    
    def cleanup_files(self, cleaned_audio_path: str, pdf_path: str = None) -> bool:
        """Clean up files when record is deleted"""
        try:
            cleaned_path = Path(cleaned_audio_path)
            if cleaned_path.exists():
                cleaned_path.unlink()
                print(f"✓ Deleted cleaned audio: {cleaned_audio_path}")
            
            if pdf_path:
                pdf_path_obj = Path(pdf_path)
                if pdf_path_obj.exists():
                    pdf_path_obj.unlink()
                    print(f"✓ Deleted PDF: {pdf_path}")
            
            return True
        except Exception as e:
            print(f"⚠ Warning during cleanup: {str(e)}")
            return False


# Global instance
audio_processor = AudioProcessor()
