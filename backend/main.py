from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
from datetime import datetime

# Add backend to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import ALLOWED_ORIGINS, DEBUG, HOST, PORT, UPLOADS_DIR
from models.schemas import (
    GenerateNoteRequest, NoteResponse, NotesListResponse,
    DeleteNoteResponse, HealthCheckResponse, ErrorResponse
)
from services.ai_service import AIService
from services.pdf_service import PDFService
from services.db_service import DBService

# Initialize FastAPI app
app = FastAPI(
    title="Vise Notes API",
    description="API for AI-powered note generation from transcripts",
    version="1.0.0",
    debug=DEBUG
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
ai_service = AIService()
pdf_service = PDFService()
db_service = DBService()


# ==================== HEALTH CHECK ====================

@app.get("/api/health", response_model=HealthCheckResponse)
async def health_check():
    """Health check endpoint to verify API is running"""
    return {
        "status": "healthy",
        "message": "Vise Notes API is running successfully"
    }


# ==================== NOTE GENERATION ====================

@app.post("/api/notes/generate", response_model=NoteResponse)
async def generate_notes(request: GenerateNoteRequest):
    """
    Generate AI-powered notes from a transcript
    
    Request body:
    - transcript: str (required) - The transcript text to analyze
    - title: str (optional) - Title for the note
    - category: str (required) - Category (Mathematics, Physics, etc.)
    
    Returns:
    - note_id: int - Unique identifier for the generated note
    - title: str - AI-generated or provided title
    - summary: str - Brief summary of the content
    - content: str - Full detailed notes
    - category: str - Category specified
    - pdf_path: str - Path to generated PDF file
    - date: str - Date of creation (YYYY-MM-DD)
    - created_at: str - ISO timestamp of creation
    """
    try:
        # Validate transcript
        if not request.transcript or len(request.transcript.strip()) == 0:
            raise HTTPException(status_code=400, detail="Transcript cannot be empty")
        
        # Generate notes using AI
        ai_response = ai_service.generate_notes_from_transcript(request.transcript)
        
        # Use provided title or AI-generated one
        final_title = request.title if request.title else ai_response['title']
        
        # Create PDF document
        pdf_path = pdf_service.create_pdf(
            title=final_title,
            content=ai_response['content']
        )
        
        # Get current date
        current_date = datetime.now().strftime('%Y-%m-%d')
        
        # Save to database
        note_id = db_service.insert_note(
            title=final_title,
            summary=ai_response['summary'],
            content=ai_response['content'],
            category=request.category,
            pdf_path=pdf_path,
            date=current_date
        )
        
        return {
            "note_id": note_id,
            "title": final_title,
            "summary": ai_response['summary'],
            "content": ai_response['content'],
            "category": request.category,
            "pdf_path": f"/api/notes/{note_id}/pdf",
            "date": current_date,
            "created_at": datetime.now().isoformat()
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating notes: {str(e)}"
        )


# ==================== RETRIEVE NOTES ====================

@app.get("/api/notes", response_model=NotesListResponse)
async def get_notes(category: str = None, limit: int = 50, offset: int = 0):
    """
    Get all notes with optional filtering
    
    Query parameters:
    - category: str (optional) - Filter by category
    - limit: int (default: 50) - Maximum number of results
    - offset: int (default: 0) - Number of results to skip for pagination
    
    Returns:
    - notes: list - List of note objects
    - total: int - Total number of notes
    """
    try:
        # Validate parameters
        if limit < 1 or limit > 100:
            limit = 50
        if offset < 0:
            offset = 0
        
        # Get notes from database
        notes = db_service.get_notes(category=category, limit=limit, offset=offset)
        total = db_service.get_notes_count(category=category)
        
        return {
            "notes": notes,
            "total": total
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving notes: {str(e)}"
        )


@app.get("/api/notes/{note_id}", response_model=NoteResponse)
async def get_note(note_id: int):
    """
    Get a single note by ID
    
    Path parameters:
    - note_id: int - The note ID
    
    Returns:
    - Full note object with all fields
    """
    try:
        note = db_service.get_note_by_id(note_id)
        
        if not note:
            raise HTTPException(status_code=404, detail="Note not found")
        
        return {
            "note_id": note['id'],
            "title": note['title'],
            "summary": note['summary'],
            "content": note['content'],
            "category": note['category'],
            "pdf_path": f"/api/notes/{note_id}/pdf",
            "date": note['date'],
            "created_at": note['created_at']
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving note: {str(e)}"
        )


# ==================== PDF DOWNLOAD ====================

@app.get("/api/notes/{note_id}/pdf")
async def download_pdf(note_id: int):
    """
    Download PDF file for a note
    
    Path parameters:
    - note_id: int - The note ID
    
    Returns:
    - Binary PDF file
    """
    try:
        note = db_service.get_note_by_id(note_id)
        
        if not note:
            raise HTTPException(status_code=404, detail="Note not found")
        
        pdf_path = note['pdf_path']
        
        # Check if file exists
        if not os.path.exists(pdf_path):
            raise HTTPException(status_code=404, detail="PDF file not found on server")
        
        # Return file for download
        return FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename=f"note_{note_id}_{note['title'][:30]}.pdf"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error downloading PDF: {str(e)}"
        )


# ==================== DELETE NOTE ====================

@app.delete("/api/notes/{note_id}", response_model=DeleteNoteResponse)
async def delete_note(note_id: int):
    """
    Delete a note and its associated PDF file
    
    Path parameters:
    - note_id: int - The note ID to delete
    
    Returns:
    - message: str - Confirmation message
    - note_id: int - ID of deleted note
    """
    try:
        note = db_service.get_note_by_id(note_id)
        
        if not note:
            raise HTTPException(status_code=404, detail="Note not found")
        
        # Delete PDF file
        pdf_path = note['pdf_path']
        if os.path.exists(pdf_path):
            pdf_service.delete_pdf(pdf_path)
        
        # Delete from database
        db_service.delete_note(note_id)
        
        return {
            "message": "Note deleted successfully",
            "note_id": note_id
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error deleting note: {str(e)}"
        )


# ==================== SEARCH NOTES (Future Enhancement) ====================

@app.get("/api/notes/search")
async def search_notes(q: str, category: str = None):
    """
    Search notes by title, summary, or content
    
    Query parameters:
    - q: str (required) - Search query
    - category: str (optional) - Filter by category
    
    Returns:
    - List of matching notes
    """
    try:
        # This is a placeholder for full-text search implementation
        # Current implementation can be enhanced with proper search logic
        
        all_notes = db_service.get_notes(category=category, limit=1000)
        
        query_lower = q.lower()
        results = [
            note for note in all_notes
            if (query_lower in note['title'].lower() or 
                (note.get('summary') and query_lower in note['summary'].lower()))
        ]
        
        return {
            "results": results,
            "count": len(results),
            "query": q
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error searching notes: {str(e)}"
        )


# ==================== ERROR HANDLERS ====================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Handle HTTP exceptions"""
    return {
        "error": str(exc.status_code),
        "detail": exc.detail
    }


if __name__ == "__main__":
    import uvicorn
    print(f"Starting Vise Notes API on {HOST}:{PORT}")
    uvicorn.run(
        app,
        host=HOST,
        port=PORT,
        reload=DEBUG,
        log_level="info"
    )
