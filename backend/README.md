# Vise Notes FastAPI Backend

Complete FastAPI backend for the Vise Notes audio-to-notes application.

## Features

- 🤖 AI-powered note generation using Google Gemini 2.5 Flash
- 📝 Automatic note structuring (title, summary, content, key points)
- 📄 PDF generation and management
- 💾 SQLite database for persistent storage
- 🔍 Note search and filtering
- 📊 Category-based organization
- 🚀 RESTful API endpoints

## Project Structure

```
backend/
├── main.py                    # FastAPI app & routes
├── config.py                  # Configuration management
├── requirements.txt           # Python dependencies
├── .env                      # Environment variables
├── database/
│   ├── connection.py         # SQLite connection & schema
│   └── notes.db             # SQLite database file
├── services/
│   ├── ai_service.py        # Gemini AI integration
│   ├── pdf_service.py       # PDF generation
│   └── db_service.py        # Database operations
├── models/
│   └── schemas.py           # Pydantic data models
└── uploads/                 # Generated PDF files storage
```

## Installation

### 1. Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

### 2. Setup

Navigate to the backend directory:
```bash
cd backend
```

Create a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Install dependencies:
```bash
pip install -r requirements.txt
```

### 3. Configuration

Update `.env` file with your configuration:
```env
GEMINI_API_KEY=your_api_key_here
HOST=0.0.0.0
PORT=8000
DEBUG=True
```

Get your Gemini API key from: https://aistudio.google.com/

## Running the Server

```bash
python main.py
```

The API will be available at: `http://localhost:8000`

Interactive API documentation: `http://localhost:8000/docs` (Swagger UI)
Alternative documentation: `http://localhost:8000/redoc` (ReDoc)

## API Endpoints

### Health Check
```
GET /api/health
```

### Generate Notes from Transcript
```
POST /api/notes/generate

Body:
{
  "transcript": "Full transcript text...",
  "title": "Optional custom title",
  "category": "Mathematics"
}

Response:
{
  "note_id": 1,
  "title": "Generated Title",
  "summary": "Brief summary",
  "content": "Full detailed notes...",
  "category": "Mathematics",
  "pdf_path": "/api/notes/1/pdf",
  "date": "2025-03-24",
  "created_at": "2025-03-24T15:30:45Z"
}
```

### Get All Notes
```
GET /api/notes?category=Mathematics&limit=50&offset=0

Response:
{
  "notes": [...],
  "total": 45
}
```

### Get Single Note
```
GET /api/notes/{note_id}

Response:
{
  "note_id": 1,
  "title": "...",
  "summary": "...",
  "content": "...",
  "category": "...",
  "pdf_path": "...",
  "date": "...",
  "created_at": "..."
}
```

### Download PDF
```
GET /api/notes/{note_id}/pdf

Returns: Binary PDF file
```

### Delete Note
```
DELETE /api/notes/{note_id}

Response:
{
  "message": "Note deleted successfully",
  "note_id": 1
}
```

### Search Notes
```
GET /api/notes/search?q=keyword&category=Mathematics

Response:
{
  "results": [...],
  "count": 5,
  "query": "keyword"
}
```

## Database Schema

### notes table
```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  summary TEXT,
  content TEXT,
  category TEXT,
  pdf_path TEXT,
  date TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```

## Integration with Flutter Frontend

The Flutter app communicates with this API via HTTP requests:

1. **Generate Notes Endpoint**
   - Receives transcript from audio preprocessing
   - Returns generated note content
   - Triggers PDF generation

2. **Retrieve Notes Endpoint**
   - Fetches all notes for display
   - Supports filtering by category
   - Implements pagination

3. **Download PDF Endpoint**
   - Serves PDF files for download/sharing
   - Maintains file management

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Google Gemini API key | `AIzaSy...` |
| `HOST` | Server host address | `0.0.0.0` |
| `PORT` | Server port | `8000` |
| `DEBUG` | Debug mode | `True` or `False` |

## Security Notes

⚠️ **Important:**

1. **API Keys**: Never commit `.env` file to version control
2. **CORS**: Update `ALLOWED_ORIGINS` in main.py for production
3. **HTTPS**: Use HTTPS in production environments
4. **Rate Limiting**: Consider adding rate limiting for production
5. **Authentication**: Add authentication for multi-user scenarios

## Troubleshooting

### Port Already in Use
```bash
# Change PORT in .env or use:
python main.py --port 8001
```

### Import Errors
```bash
# Reinstall dependencies
pip install --upgrade -r requirements.txt
```

### API Key Issues
- Verify API key is set in `.env`
- Check key hasn't reached quota on Google Cloud
- Test key at: https://aistudio.google.com/

## Future Enhancements

- [ ] User authentication & authorization
- [ ] Cloud storage integration (Google Drive, AWS S3)
- [ ] Advanced search with full-text indexing
- [ ] Rate limiting and throttling
- [ ] Batch note generation
- [ ] WebSocket support for real-time updates
- [ ] Backup and restore functionality
- [ ] Analytics and usage tracking

## Support

For issues or questions, check:
- API documentation at `/docs` endpoint
- Error messages in server logs
- GitHub issues (if applicable)

## License

[Your License Here]
