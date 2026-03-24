from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class GenerateNoteRequest(BaseModel):
    """Request model for generating notes from transcript"""
    transcript: str
    title: Optional[str] = None
    category: str = "General"

class NoteResponse(BaseModel):
    """Response model for note"""
    note_id: int
    title: str
    summary: str
    content: str
    category: str
    pdf_path: str
    date: str
    created_at: str

class NotesListResponse(BaseModel):
    """Response model for list of notes"""
    notes: list
    total: int

class DeleteNoteResponse(BaseModel):
    """Response model for note deletion"""
    message: str
    note_id: int

class HealthCheckResponse(BaseModel):
    """Response model for health check"""
    status: str
    message: str

class ErrorResponse(BaseModel):
    """Response model for errors"""
    error: str
    detail: str
