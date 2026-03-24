import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Base directory
BASE_DIR = Path(__file__).parent

# API Configuration
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', 'AIzaSyAZobAyuL6eQEfqHqnV4L0ilbKuUBrE0WU')
GEMINI_MODEL = 'models/gemini-2.5-flash'

# Database Configuration
DATABASE_PATH = os.path.join(BASE_DIR, 'database', 'notes.db')

# File Storage Configuration
UPLOADS_DIR = os.path.join(BASE_DIR, 'uploads')
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Server Configuration
HOST = os.getenv('HOST', '0.0.0.0')
PORT = int(os.getenv('PORT', 8000))
DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

# CORS Configuration
ALLOWED_ORIGINS = [
    'http://localhost:8080',
    'http://192.168.x.x:*',
    'http://127.0.0.1:*',
]
