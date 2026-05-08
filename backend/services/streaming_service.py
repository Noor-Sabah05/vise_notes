import io
import numpy as np
import soundfile as sf
from pathlib import Path
from wispermodel import WhisperModelManager


class StreamingTranscriptionManager:
    """
    Manages real-time audio streaming transcription.
    Buffers incoming audio chunks and transcribes every 2-3 seconds.
    """

    def __init__(self, sample_rate: int = 16000, buffer_duration: float = 2.5):
        """
        Initialize streaming transcription manager.
        
        Args:
            sample_rate: Audio sample rate (default 16kHz for Whisper)
            buffer_duration: Seconds of audio to buffer before transcribing (default 2.5s)
        """
        self.sample_rate = sample_rate
        self.buffer_duration = buffer_duration
        self.buffer_size = int(sample_rate * buffer_duration)  # Number of samples
        
        # Audio buffer: accumulate PCM samples
        self.audio_buffer = []
        
        # Full accumulated audio for final processing
        self.full_audio = []
        
        # Transcription state
        self.full_transcript = ""
        self.last_timestamp = 0.0
        
        # Whisper model (cached)
        self.whisper_model = WhisperModelManager.get_model()

    def add_audio_chunk(self, audio_bytes: bytes) -> dict:
        """
        Add incoming audio chunk to buffer.
        
        Args:
            audio_bytes: Raw PCM audio bytes (mono, 16-bit, 16kHz)
        
        Returns:
            dict with keys:
            - "partial_transcript": str - transcribed text if buffer is ready, "" otherwise
            - "is_final": bool - False (always partial during streaming)
            - "buffer_status": str - "buffering" or "processing"
        """
        # Convert bytes to numpy array (16-bit PCM, mono)
        try:
            audio_data = np.frombuffer(audio_bytes, dtype=np.int16)
            # Normalize to float [-1.0, 1.0]
            audio_data = audio_data.astype(np.float32) / 32768.0
        except Exception as e:
            return {
                "partial_transcript": "",
                "is_final": False,
                "error": f"Audio processing error: {str(e)}"
            }

        # Add to both buffers
        self.audio_buffer.extend(audio_data)
        self.full_audio.extend(audio_data)

        # Check if buffer is ready for transcription
        if len(self.audio_buffer) >= self.buffer_size:
            return self._transcribe_buffer()
        else:
            return {
                "partial_transcript": "",
                "is_final": False,
                "buffer_status": "buffering",
                "samples_buffered": len(self.audio_buffer),
                "samples_needed": self.buffer_size
            }

    def _transcribe_buffer(self) -> dict:
        """
        Transcribe the current audio buffer using Whisper.
        """
        try:
            # Convert buffer to temporary WAV file
            audio_array = np.array(self.audio_buffer, dtype=np.float32)
            
            # Create temporary file path
            temp_path = Path("/tmp/stream_chunk.wav")
            
            # Write WAV file
            sf.write(str(temp_path), audio_array, self.sample_rate)
            
            # Transcribe with Whisper
            segments, info = self.whisper_model.transcribe(str(temp_path))
            partial_transcript = " ".join(s.text.strip() for s in segments)
            
            # Update full transcript
            if partial_transcript.strip():
                if self.full_transcript:
                    self.full_transcript += " " + partial_transcript
                else:
                    self.full_transcript = partial_transcript
            
            # Clear buffer for next chunk
            self.audio_buffer = []
            
            # Clean up temp file
            temp_path.unlink(missing_ok=True)
            
            return {
                "partial_transcript": partial_transcript,
                "is_final": False,
                "buffer_status": "processed",
                "language": info.language
            }
        except Exception as e:
            return {
                "partial_transcript": "",
                "is_final": False,
                "error": f"Transcription error: {str(e)}"
            }

    def finalize_transcription(self) -> dict:
        """
        Finalize transcription by processing any remaining buffered audio.
        Called when recording stops.
        
        Returns:
            dict with final transcript and metadata
        """
        # Process any remaining audio in buffer
        if self.audio_buffer:
            result = self._transcribe_buffer()
            if result.get("partial_transcript"):
                # Already merged into self.full_transcript
                pass
        
        # Calculate total duration
        total_samples = len(self.full_audio)
        total_duration = total_samples / self.sample_rate
        
        return {
            "full_transcript": self.full_transcript,
            "total_duration": round(total_duration, 2),
            "total_samples": total_samples,
            "is_final": True
        }

    def get_full_audio_array(self) -> np.ndarray:
        """
        Get the full accumulated audio as numpy array.
        """
        return np.array(self.full_audio, dtype=np.float32)

    def save_full_audio(self, output_path: str):
        """
        Save full accumulated audio to WAV file.
        """
        audio_array = self.get_full_audio_array()
        sf.write(output_path, audio_array, self.sample_rate)
