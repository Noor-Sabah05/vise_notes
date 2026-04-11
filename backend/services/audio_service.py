from pathlib import Path
import numpy as np
import soundfile as sf
import noisereduce as nr


def load_audio(file_path: Path):
    """Load audio file and return waveform + sample rate."""
    try:
        audio, sr = sf.read(str(file_path))
        return audio, sr
    except Exception as e:
        raise ValueError(f"Could not read audio: {e}")


def convert_to_mono(audio: np.ndarray):
    """Convert stereo audio to mono."""
    if audio.ndim > 1:
        return audio.mean(axis=1)
    return audio


def reduce_noise(audio: np.ndarray, sr: int):
    """Apply noise reduction."""
    return nr.reduce_noise(y=audio, sr=sr)


def normalize_audio(audio: np.ndarray):
    """Peak normalization."""
    peak = np.max(np.abs(audio))
    if peak > 0:
        return audio / peak
    return audio


def save_audio(file_path: Path, audio: np.ndarray, sr: int):
    """Save processed audio."""
    sf.write(str(file_path), audio, sr)


def preprocess_audio(input_path: Path, output_path: Path):
    """
    Full preprocessing pipeline:
    load → mono → denoise → normalize → save
    """
    audio, sr = load_audio(input_path)
    audio = convert_to_mono(audio)
    audio = reduce_noise(audio, sr)
    audio = normalize_audio(audio)
    save_audio(output_path, audio, sr)

    return {
        "sample_rate": sr,
        "duration": len(audio) / sr
    }