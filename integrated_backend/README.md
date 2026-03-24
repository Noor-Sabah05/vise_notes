# ViseNotes Integrated Backend

**Complete audio → transcription → notes generation pipeline**

## 📋 Overview

The integrated backend combines two separate pipelines into a single, unified FastAPI application:

1. **Audio Processing Pipeline** (originally from `audio_processing_flutter_backend`)
   - Audio format validation
   - Noise reduction
   - Peak normalization
   - Whisper-based transcription

2. **Notes Generation Pipeline** (originally from `notes_generation_flutter_backend`)
   - AI-powered note generation using Google Gemini
   - Structured note formatting
   - PDF document generation

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                        │
│            (Upload audio with metadata)                      │
└──────────────────────────────┬───────────────────────────────┘
                               │
                    POST /api/upload
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│          INTEGRATED BACKEND (FastAPI)                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Audio Processing Service                          │  │
│  │    - Validate format                                 │  │
│  │    - Noise reduction (noisereduce)                   │  │
│  │    - Peak normalization                              │  │
│  │    - Save cleaned audio                              │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│  ┌─────────────────────▼────────────────────────────────┐  │
│  │ 2. Audio Transcription Service                       │  │
│  │    - Faster Whisper (small model, CPU)               │  │
│  │    - VAD filter enabled (skip silence)               │  │
│  │    - Return: transcript text                         │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│  ┌─────────────────────▼────────────────────────────────┐  │
│  │ 3. Note Generation Service                           │  │
│  │    - Google Gemini 2.5 Flash API                     │  │
│  │    - Category-aware prompts                          │  │
│  │    - JSON response parsing                           │  │
│  │    - Return: title, summary, content                 │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│  ┌─────────────────────▼────────────────────────────────┐  │
│  │ 4. PDF Generation Service                            │  │
│  │    - ReportLab for professional PDFs                 │  │
│  │    - Formatted content with sections                 │  │
│  │    - Metadata and styling                            │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│  ┌─────────────────────▼────────────────────────────────┐  │
│  │ 5. Database (SQLite)                                 │  │
│  │    - Unified schema: recordings_with_notes           │  │
│  │    - Stores complete audio → notes lifecycle        │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                               │
                    Response: Complete note + PDF
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│               FLUTTER APP (Display Results)                  │
│    - Transcript text                                        │
│    - Generated notes                                        │
│    - PDF document                                           │
│    - Cleaned audio file                                     │
└──────────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
integrated_backend/
├── config.py                    # Configuration (API keys, paths, models)
├── main.py                      # FastAPI application & routes
├── requirements.txt             # Python dependencies
├── README.md                    # This file
│
├── database/
│   ├── __init__.py
│   └── integrated_db.py         # Database operations & schema
│
├── services/
│   ├── __init__.py
│   ├── audio_processor.py       # Noise reduction + transcription
│   ├── note_generator.py        # AI note generation (Gemini)
│   └── pdf_generator.py         # PDF creation (ReportLab)
│
├── uploads/                     # Generated files directory
│   ├── [file_id]_clean.wav     # Cleaned audio
│   └── [title]_[id].pdf        # Generated PDF
│
└── database/
    └── visenotes_integrated.db  # SQLite database
```

## 🚀 Quick Start

### 1. Installation

```bash
# Navigate to backend directory
cd integrated_backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configuration

Create a `.env` file in the `integrated_backend` directory:

```env
# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key_here

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=True

# Optional: Override defaults from config.py
# WHISPER_MODEL_NAME=base
# WHISPER_DEVICE=cuda
```

Get your Gemini API key from: https://makersuite.google.com/app/apikey

### 3. Run the Server

```bash
# Basic run (development)
python main.py

# Or with uvicorn directly:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# ⚠️ IMPORTANT: For production with long transcription times (15+ minutes):
# Must disable request timeout to allow full transcription completion
uvicorn main:app --host 0.0.0.0 --port 8000 --timeout-keep-alive 0 --timeout-notify 0
```

**Timeout Configuration:**
- `--timeout-keep-alive 0`: Disable keep-alive timeout (allows long requests)
- `--timeout-notify 0`: Disable graceful shutdown notify (prevents premature disconnect)
- Without these, Uvicorn defaults to 5-second timeouts which will interrupt transcription

The API will be available at: `http://localhost:8000`

## 📡 API Endpoints

### 1. Health Check
```http
GET /api/health
```

### 2. Process Audio to Notes (Main Endpoint)
```http
POST /api/upload
Content-Type: multipart/form-data

Parameters:
- file: [audio file] (required)
- category: [category name] (optional, default: "General")

Supported formats: .wav, .mp3, .m4a, .ogg, .flac
Categories: Mathematics, Physics, Chemistry, Biology, History, Literature, Programming, General

Response:
{
  "file_id": "uuid-string",
  "status": "completed",
  "transcript": "Full transcript text...",
  "note_title": "AI-generated title",
  "note_summary": "Brief summary...",
  "note_content": "Detailed notes...",
  "category": "Mathematics",
  "pdf_path": "/uploads/filename.pdf",
  "cleaned_audio_path": "/uploads/uuid_clean.wav",
  "duration_seconds": 123.45,
  "language": "en",
  "created_at": "2024-03-24T15:30:45"
}
```

### 3. Generate Notes from Transcript (Reprocessing)
```http
POST /api/notes/generate-from-transcript
Content-Type: application/json

Body:
{
  "transcript": "Text of existing transcript...",
  "title": "Optional custom title",
  "category": "Mathematics"
}

Response:
{
  "title": "Generated or provided title",
  "summary": "Brief summary...",
  "content": "Detailed notes...",
  "category": "Mathematics",
  "pdf_path": "/uploads/filename.pdf",
  "created_at": "2024-03-24T15:30:45"
}
```

### 4. Get All Recordings
```http
GET /api/recordings?limit=50&offset=0

Response:
{
  "recordings": [
    {
      "id": 1,
      "file_id": "uuid",
      "filename": "audio_name",
      "language": "en",
      "duration_seconds": 123.45,
      "note_title": "Title",
      "note_summary": "Summary",
      "category": "Mathematics",
      "status": "completed",
      "created_at": "2024-03-24T15:30:45"
    }
  ],
  "total": 10,
  "limit": 50,
  "offset": 0
}
```

### 5. Get Recording by ID
```http
GET /api/recordings/{file_id}

Response: Complete recording object with all details
```

### 6. Get Recordings by Category
```http
GET /api/recordings/category/{category}?limit=50&offset=0
```

### 7. Download PDF
```http
GET /api/download/pdf/{file_id}
```

### 8. Download Cleaned Audio
```http
GET /api/download/audio/{file_id}
```

### 9. Delete Recording
```http
DELETE /api/recordings/{file_id}
```

### 10. Get Available Categories
```http
GET /api/categories

Response:
{
  "categories": ["Mathematics", "Physics", "Chemistry", ...]
}
```

## 🔧 Configuration Details

### Audio Processing (`config.py`)

```python
WHISPER_MODEL_NAME = 'small'      # tiny, base, small, medium, large
WHISPER_DEVICE = 'cpu'            # cpu or cuda
WHISPER_COMPUTE_TYPE = 'int8'     # int8, int16, float16, float32
WHISPER_BEAM_SIZE = 5             # beam search size (5=default)
```

**Model Performance:**
- **tiny**: Fastest, least accurate (~50MB)
- **base**: Fast, decent accuracy (~140MB)
- **small**: Good balance (150-200MB) ← Recommended
- **medium**: Better accuracy, slower (405MB)
- **large**: Best accuracy, slowest (2.9GB)

### Note Categories
```python
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
```

## 📊 Database Schema

### `recordings_with_notes` Table

```sql
CREATE TABLE recordings_with_notes (
    id                  INTEGER PRIMARY KEY,
    file_id             TEXT UNIQUE,          -- UUID of recording
    filename            TEXT,                 -- Shortened filename
    original_filename   TEXT,                 -- Original upload filename
    
    -- Audio Processing
    language            TEXT,                 -- Detected language (en, fr, etc)
    duration_seconds    REAL,                 -- Audio duration
    cleaned_audio_path  TEXT,                 -- Path to processed audio
    
    -- Transcription
    transcript          TEXT,                 -- Full transcript text
    
    -- Note Generation
    note_title          TEXT,                 -- AI-generated title
    note_summary        TEXT,                 -- Brief summary
    note_content        TEXT,                 -- Full detailed notes
    category            TEXT,                 -- User-selected category
    pdf_path            TEXT,                 -- Path to generated PDF
    
    -- Status Tracking
    created_at          TEXT,                 -- ISO timestamp
    updated_at          TEXT,                 -- Last update timestamp
    status              TEXT,                 -- processing, completed, failed
    error_message       TEXT                  -- Error details if failed
)
```

## 🔄 Data Flow

### Complete Processing Pipeline

```
1. RECEIVE UPLOAD
   └─> Validate format
   └─> Save temporarily

2. PROCESS AUDIO
   └─> Load audio file
   └─> Convert stereo → mono if needed
   └─> Noise reduction (noisereduce)
   └─> Peak normalization
   └─> Save cleaned audio

3. TRANSCRIBE
   └─> Load Faster Whisper model
   └─> Transcribe cleaned audio
   └─> Return transcript + language + duration

4. GENERATE NOTES
   └─> Call Gemini API with category context
   └─> Parse JSON response
   └─> Extract title, summary, content, key points

5. GENERATE PDF
   └─> Format content with styling
   └─> Create document structure
   └─> Add metadata and footer
   └─> Save to disk

6. DATABASE
   └─> Insert/Update recording_with_notes
   └─> Set status to "completed"
   └─> Store all paths and content

7. RESPOND
   └─> Return complete result with file_id
   └─> Client receives transcript, notes, PDF path, etc.
```

### Error Handling

If any step fails:
1. Error is logged
2. Database status set to "failed"
3. Error message stored
4. Temporary files cleaned up
5. HTTP 500 error returned to client

## 🔌 Flutter Integration

### Update Flutter API Service

Modify your Flutter app's API service to call the integrated endpoint:

```dart
// OLD (Two separate calls)
// 1. Upload audio
//    POST /upload → get transcript
// 2. Generate notes
//    POST /api/notes/generate → get notes

// NEW (Single integrated call)
// POST /api/upload → complete pipeline result
```

### Example Flutter Code

```dart
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class ApiService {
  final String baseURL = 'http://192.168.x.x:8000';
  
  Future<Map<String, dynamic>> uploadAudioForProcessing(
    File audioFile,
    String category = 'General',
  ) async {
    try {
      final dio = Dio();
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'category': category,
      });
      
      // Single endpoint for complete processing
      final response = await dio.post(
        '$baseURL/api/upload',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }
  
  // Response structure:
  // {
  //   'file_id': 'uuid',
  //   'status': 'completed',
  //   'transcript': 'text...',
  //   'note_title': 'title...',
  //   'note_summary': 'summary...',
  //   'note_content': 'content...',
  //   'category': 'Mathematics',
  //   'pdf_path': '/uploads/file.pdf',
  //   'cleaned_audio_path': '/uploads/uuid_clean.wav',
  //   'duration_seconds': 123.45,
  //   'language': 'en',
  //   'created_at': '2024-03-24T...'
  // }
}
```

## 📝 Migration from Separate Backends

### What Changed

| Aspect | Old (Separate) | New (Integrated) |
|--------|---|---|
| Endpoints | 2 endpoints | 1 main endpoint |
| Processing | Sequential API calls | Single pipeline |
| Database | 2 databases | 1 unified database |
| Responses | Separate responses | Combined response |
| Time | 2 requests | 1 request |

### Migration Steps

1. **Update Flutter app** to use single `/api/upload` endpoint
2. **Update backend URL** in app config
3. **No database migration needed** - old databases can coexist
4. **Start using new integrated backend**
5. **(Optional) Delete old backends:**
   - `audio_processing_flutter_backend/`
   - `notes_generation_flutter_backend/`

## 🐛 Debugging

### Check Server Status
```bash
curl http://localhost:8000/api/health
```

### Enable Debug Logging
```python
# In config.py
DEBUG = True
```

### Common Issues

**Issue: Whisper model download fails**
```
Solution: Model will auto-download on first use (~150MB for 'small')
          Ensure internet connection and disk space
```

**Issue: Gemini API errors**
```
Solution: Check GEMINI_API_KEY in .env file
          Verify key is valid and has quota available
```

**Issue: Disk space issues**
```
Solution: Clean up uploads folder periodically
          Set up automated cleanup for old files
```

## 📈 Performance Optimization

### For Development
- **WHISPER_MODEL_NAME**: Use 'tiny' or 'base' for faster testing
- **DEBUG**: Set to True for hot reload

### For Production
- **WHISPER_MODEL_NAME**: Use 'small' for quality/speed balance
- **DEBUG**: Set to False
- **WHISPER_DEVICE**: Use 'cuda' if GPU available
- **Use Gunicorn**: `pip install gunicorn` then run with multiple workers

### Approximate Processing Times (on CPU)
- 5-min audio
  - Noise reduction: 2-3 seconds
  - Transcription: 10-20 seconds
  - Note generation: 5-10 seconds
  - PDF generation: 1-2 seconds
  - **Total: ~20-40 seconds**

## 🚨 Production Deployment

### Using Gunicorn

```bash
# Install
pip install gunicorn

# Run with 4 workers
gunicorn -w 4 -b 0.0.0.0:8000 --timeout 120 main:app
```

### Using Docker

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:
```bash
docker build -t visenotes-backend .
docker run -p 8000:8000 -e GEMINI_API_KEY=your_key visenotes-backend
```

## 📚 Further Reading

- **Faster Whisper**: https://github.com/SYSTRAN/faster-whisper
- **Google Gemini API**: https://ai.google.dev/
- **FastAPI**: https://fastapi.tiangolo.com/
- **ReportLab**: https://www.reportlab.com/

## 📄 License

Same as main ViseNotes project

## ❓ Support

For issues or questions, refer to:
1. This README
2. Inline code comments
3. FastAPI documentation
4. Error messages in server logs
