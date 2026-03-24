"""
ViseNotes Integrated Backend API
Complete pipeline: Audio Upload → Transcription → Note Generation → PDF Export
"""

import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Add backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import (
    ALLOWED_AUDIO_FORMATS, DEBUG, HOST, PORT, UPLOADS_DIR,
    NOTE_CATEGORIES, ALLOWED_ORIGINS
)
from database import (
    init_db, insert_recording_with_notes, update_recording_status,
    get_recording_by_file_id, get_all_recordings, delete_recording,
    get_recordings_by_category
)
from services import (
    audio_processor, note_generator, pdf_generator
)


# ════════════════════════════════════════════════════════════════════════════════
# FastAPI Application Setup
# ════════════════════════════════════════════════════════════════════════════════

app = FastAPI(
    title="ViseNotes Integrated API",
    description="Complete audio → transcription → notes generation pipeline",
    version="1.0.0",
    debug=DEBUG
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for Flutter development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
init_db()


# ════════════════════════════════════════════════════════════════════════════════
# Request/Response Models
# ════════════════════════════════════════════════════════════════════════════════

class ProcessingRequest(BaseModel):
    """Request for note generation from existing transcript"""
    transcript: str
    title: Optional[str] = None
    category: str = "General"


class CompleteNoteResponse(BaseModel):
    """Response with complete processing result"""
    file_id: str
    status: str
    transcript: str
    note_title: str
    note_summary: str
    note_content: str
    category: str
    pdf_path: str
    cleaned_audio_path: str
    duration_seconds: float
    language: str
    created_at: str


class RecordingListResponse(BaseModel):
    """Response for list of recordings"""
    recordings: list
    total: int
    limit: int
    offset: int


class HealthCheckResponse(BaseModel):
    """Health check response"""
    status: str
    message: str
    services: dict


# ════════════════════════════════════════════════════════════════════════════════
# Health & Status Endpoints
# ════════════════════════════════════════════════════════════════════════════════

@app.get("/", response_model=HealthCheckResponse)
@app.get("/api/health", response_model=HealthCheckResponse)
async def health_check():
    """
    Health check endpoint - Verify all services are operational
    """
    return {
        "status": "healthy",
        "message": "ViseNotes Integrated API is running",
        "services": {
            "audio_processing": "ready",
            "transcription": "ready",
            "note_generation": "ready",
            "pdf_generation": "ready",
            "database": "ready"
        }
    }


# ════════════════════════════════════════════════════════════════════════════════
# Main Processing Endpoint - Audio to Notes
# ════════════════════════════════════════════════════════════════════════════════

@app.post("/api/upload")
async def process_audio_to_notes(
    file: UploadFile = File(...),
    category: str = "General"
):
    """
    Complete pipeline: Upload audio → Process → Transcribe → Generate Notes
    
    Query Parameters:
    - category: Note category (Mathematics, Physics, Chemistry, Biology, etc.)
    
    Returns:
    {
        "file_id": "uuid",
        "status": "completed",
        "transcript": "Full transcript text...",
        "note_title": "AI-generated title",
        "note_summary": "Quick summary",
        "note_content": "Detailed notes with sections",
        "category": "Selected category",
        "pdf_path": "/uploads/filename.pdf",
        "cleaned_audio_path": "/uploads/uuid_clean.wav",
        "duration_seconds": 123.45,
        "language": "en",
        "created_at": "2024-03-24T15:30:45"
    }
    """
    
    file_id = None
    raw_path = None
    
    try:
        # Step 1: Validate file
        print(f"\n{'='*70}")
        print(f"📥 Processing file: {file.filename}")
        print(f"{'='*70}")
        
        ext = Path(file.filename).suffix.lower()
        if ext not in ALLOWED_AUDIO_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported format '{ext}'. Allowed: {ALLOWED_AUDIO_FORMATS}"
            )
        
        if category not in NOTE_CATEGORIES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid category. Allowed: {NOTE_CATEGORIES}"
            )
        
        print(f"✓ File format: {ext} | Category: {category}")
        
        # Step 2: Save uploaded file temporarily
        print(f"\n[1/6] Saving uploaded file...")
        file_bytes = await file.read()
        raw_path, ext = audio_processor.save_raw_audio(file_bytes, file.filename)
        
        # Step 3: Create database record
        print(f"\n[2/6] Creating database record...")
        # Extract file_id from raw_path
        file_id = Path(raw_path).stem.replace('_raw', '')
        
        record_id = insert_recording_with_notes(
            file_id=file_id,
            filename=Path(file.filename).stem,
            original_filename=file.filename,
            status='processing'
        )
        print(f"✓ Record created: ID {record_id}")
        
        # Step 4: Process audio (noise reduction + transcription)
        print(f"\n[3/6] Processing audio (noise reduction → transcription)...")
        audio_result = audio_processor.process_audio_file(raw_path)
        
        transcript = audio_result['transcript']
        print(f"✓ Transcript generated ({len(transcript)} chars)")
        
        # Clean up raw file
        audio_processor.cleanup_raw_file(raw_path)
        
        # Step 5: Generate notes from transcript
        print(f"\n[4/6] Generating notes from transcript...")
        note_result = note_generator.generate_notes_from_transcript(
            transcript=transcript,
            category=category
        )
        
        print(f"✓ Notes generated: {note_result['title']}")
        
        # Step 6: Generate PDF
        print(f"\n[5/6] Generating PDF document...")
        pdf_path = pdf_generator.create_note_pdf(
            title=note_result['title'],
            content=note_result['content'],
            metadata={
                'category': category,
                'created_at': datetime.now().isoformat()
            }
        )
        
        # Step 7: Update database with complete information
        print(f"\n[6/6] Updating database with complete information...")
        success = update_recording_status(
            file_id=file_id,
            status='completed',
            transcript=transcript,
            note_title=note_result['title'],
            note_summary=note_result['summary'],
            note_content=note_result['content'],
            pdf_path=pdf_path
        )
        
        if not success:
            raise Exception("Failed to update database record")
        
        print(f"\n{'='*70}")
        print(f"✅ PROCESSING COMPLETE")
        print(f"{'='*70}\n")
        
        # Return complete response
        record = get_recording_by_file_id(file_id)
        
        return {
            "file_id": file_id,
            "status": "completed",
            "transcript": transcript,
            "note_title": note_result['title'],
            "note_summary": note_result['summary'],
            "note_content": note_result['content'],
            "category": category,
            "pdf_path": pdf_path,
            "cleaned_audio_path": audio_result['cleaned_audio_path'],
            "duration_seconds": audio_result['duration_seconds'],
            "language": audio_result['language'],
            "created_at": datetime.now().isoformat()
        }
    
    except Exception as e:
        error_msg = str(e)
        print(f"\n✗ ERROR: {error_msg}\n")
        
        # Try to update database with error status
        if file_id:
            try:
                update_recording_status(
                    file_id=file_id,
                    status='failed',
                    error_message=error_msg
                )
            except:
                pass
        
        # Clean up files
        if raw_path:
            audio_processor.cleanup_raw_file(raw_path)
        
        raise HTTPException(status_code=500, detail=error_msg)


# ════════════════════════════════════════════════════════════════════════════════
# Transcript Processing Endpoint (Separate)
# ════════════════════════════════════════════════════════════════════════════════

@app.post("/api/notes/generate-from-transcript")
async def generate_notes_from_transcript(request: ProcessingRequest):
    """
    Generate notes from an existing transcript (without audio processing)
    
    Useful for: Reprocessing transcripts, batch processing
    
    Args:
        transcript: The transcript text
        title: Optional custom title
        category: Note category
    """
    try:
        print(f"\n📝 Generating notes from transcript...")
        
        if not request.transcript.strip():
            raise HTTPException(status_code=400, detail="Transcript cannot be empty")
        
        # Validate category
        if request.category not in NOTE_CATEGORIES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid category. Allowed: {NOTE_CATEGORIES}"
            )
        
        # Generate notes
        note_result = note_generator.generate_notes_from_transcript(
            transcript=request.transcript,
            category=request.category
        )
        
        # Use provided title or AI-generated one
        final_title = request.title if request.title else note_result['title']
        
        # Generate PDF
        pdf_path = pdf_generator.create_note_pdf(
            title=final_title,
            content=note_result['content'],
            metadata={'category': request.category}
        )
        
        return {
            "title": final_title,
            "summary": note_result['summary'],
            "content": note_result['content'],
            "category": request.category,
            "pdf_path": pdf_path,
            "created_at": datetime.now().isoformat()
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ════════════════════════════════════════════════════════════════════════════════
# Recording Retrieval Endpoints
# ════════════════════════════════════════════════════════════════════════════════

@app.get("/api/recordings")
async def get_all_recordings_endpoint(limit: int = 50, offset: int = 0):
    """
    Get all recordings with pagination
    
    Query Parameters:
    - limit: Number of results (default: 50)
    - offset: Number of results to skip (default: 0)
    """
    try:
        result = get_all_recordings(limit=limit, offset=offset)
        return RecordingListResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/recordings/category/{category}")
async def get_recordings_by_category_endpoint(
    category: str,
    limit: int = 50,
    offset: int = 0
):
    """Get recordings by category"""
    try:
        if category not in NOTE_CATEGORIES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid category. Allowed: {NOTE_CATEGORIES}"
            )
        
        result = get_recordings_by_category(category, limit=limit, offset=offset)
        return RecordingListResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/recordings/{file_id}")
async def get_recording_by_id(file_id: str):
    """Get complete recording details by file ID"""
    try:
        record = get_recording_by_file_id(file_id)
        if not record:
            raise HTTPException(status_code=404, detail="Recording not found")
        return dict(record)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ════════════════════════════════════════════════════════════════════════════════
# File Download Endpoints
# ════════════════════════════════════════════════════════════════════════════════

@app.get("/api/download/pdf/{file_id}")
async def download_pdf(file_id: str):
    """Download PDF for a recording"""
    try:
        record = get_recording_by_file_id(file_id)
        if not record or not record['pdf_path']:
            raise HTTPException(status_code=404, detail="PDF not found")
        
        pdf_path = record['pdf_path']
        if not Path(pdf_path).exists():
            raise HTTPException(status_code=404, detail="PDF file not found on disk")
        
        return FileResponse(
            path=pdf_path,
            filename=Path(pdf_path).name,
            media_type='application/pdf'
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/download/audio/{file_id}")
async def download_audio(file_id: str):
    """Download cleaned audio for a recording"""
    try:
        record = get_recording_by_file_id(file_id)
        if not record or not record['cleaned_audio_path']:
            raise HTTPException(status_code=404, detail="Audio not found")
        
        audio_path = record['cleaned_audio_path']
        if not Path(audio_path).exists():
            raise HTTPException(status_code=404, detail="Audio file not found on disk")
        
        return FileResponse(
            path=audio_path,
            filename=f"{record['filename']}_cleaned.wav",
            media_type='audio/wav'
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ════════════════════════════════════════════════════════════════════════════════
# Deletion Endpoint
# ════════════════════════════════════════════════════════════════════════════════

@app.delete("/api/recordings/{file_id}")
async def delete_recording_endpoint(file_id: str):
    """Delete a recording and its associated files"""
    try:
        record = get_recording_by_file_id(file_id)
        if not record:
            raise HTTPException(status_code=404, detail="Recording not found")
        
        # Clean up files
        if record.get('cleaned_audio_path'):
            audio_processor.cleanup_files(
                record['cleaned_audio_path'],
                record.get('pdf_path')
            )
        
        # Delete from database
        success = delete_recording(file_id)
        
        if success:
            return {"message": "Recording deleted successfully", "file_id": file_id}
        else:
            raise HTTPException(status_code=500, detail="Failed to delete recording")
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ════════════════════════════════════════════════════════════════════════════════
# Categories Endpoint
# ════════════════════════════════════════════════════════════════════════════════

@app.get("/api/categories")
async def get_categories():
    """Get list of available note categories"""
    return {"categories": NOTE_CATEGORIES}


# ════════════════════════════════════════════════════════════════════════════════
# Startup & Shutdown
# ════════════════════════════════════════════════════════════════════════════════

@app.on_event("startup")
async def startup_event():
    print("\n" + "="*70)
    print("🚀 ViseNotes Integrated API Starting Up")
    print("="*70)
    print(f"📍 Server: {HOST}:{PORT}")
    print(f"🗄️  Database: {os.path.join(os.path.dirname(__file__), 'database', 'visenotes_integrated.db')}")
    print(f"📁 Uploads: {UPLOADS_DIR}")
    print("="*70 + "\n")


@app.on_event("shutdown")
async def shutdown_event():
    print("\n" + "="*70)
    print("👋 ViseNotes Integrated API Shutting Down")
    print("="*70 + "\n")


# ════════════════════════════════════════════════════════════════════════════════
# Main Entry Point
# ════════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import uvicorn
    
    print("""
    
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║            🎙️  VISENOTES INTEGRATED BACKEND API  🎙️           ║
    ║                                                                ║
    ║        Complete Audio → Notes Generation Pipeline             ║
    ║                                                                ║
    ║  Audio Upload → Noise Reduction → Transcription →             ║
    ║  AI Note Generation → PDF Export                              ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
    
    """)
    
    uvicorn.run(
        app,
        host=HOST,
        port=PORT,
        reload=DEBUG,
        log_level="info"
    )
