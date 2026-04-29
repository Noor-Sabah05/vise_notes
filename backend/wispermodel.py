from faster_whisper import WhisperModel

class WhisperModelManager:
    """Singleton manager for Whisper model with optimizations for mobile app."""
    _instance = None
    
    @classmethod
    def get_model(cls):
        """Lazy-load model once on first call."""
        if cls._instance is None:
            print("Loading Whisper model (tiny + int8 for mobile optimization)...")
            cls._instance = WhisperModel(
                "tiny",  # Much faster than 'small' (~5-10x speedup)
                device="cpu",
                compute_type="int8"  # Better CPU support and good performance
            )
            print("✓ Whisper model ready!")
        return cls._instance
