import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Base directory
BASE_DIR = Path(__file__).parent

# ======================== API & GEMINI CONFIGURATION ========================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyAZobAyuL6eQEfqHqnV4L0ilbKuUBrE0WU")
GEMINI_MODEL = 'models/gemini-2.5-flash'

# ======================== DATABASE CONFIGURATION ========================
DATABASE_PATH = os.path.join(BASE_DIR, 'database', 'visenotes_integrated.db')

# ======================== FILE STORAGE CONFIGURATION ========================
UPLOADS_DIR = os.path.join(BASE_DIR, 'uploads')
os.makedirs(UPLOADS_DIR, exist_ok=True)

# ======================== SERVER CONFIGURATION ========================
HOST = os.getenv('HOST', '0.0.0.0')
PORT = int(os.getenv('PORT', 8000))
DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

# ======================== CORS CONFIGURATION ========================
ALLOWED_ORIGINS = [
    'http://localhost:8080',
    'http://192.168.x.x:*',
    'http://127.0.0.1:*',
]

# ======================== AUDIO PROCESSING CONFIGURATION ========================
# Whisper Model Configuration
WHISPER_MODEL_NAME = 'small'  # Options: tiny, base, small, medium, large
WHISPER_DEVICE = 'cpu'  # Options: cpu, cuda
WHISPER_COMPUTE_TYPE = 'int8'  # Options: int8, int16, float16, float32
WHISPER_BEAM_SIZE = 5

# Allowed audio formats
ALLOWED_AUDIO_FORMATS = {'.wav', '.mp3', '.m4a', '.ogg', '.flac'}

# ======================== NOTE GENERATION CONFIGURATION ========================
# Categories for notes
NOTE_CATEGORIES = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Literature',
    'Programming',
    'General',
    'Other'
]
