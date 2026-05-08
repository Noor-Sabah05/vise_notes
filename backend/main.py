import shutil
import uuid
import json
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware

from wispermodel import WhisperModelManager

from database import init_db, save_transcript
from services.audio_service import preprocess_audio
from services.notes_service import NotesService
from services.pdf_service import generate_pdf
from services.streaming_service import StreamingTranscriptionManager
from config import GEMINI_API_KEY
from models.notes_request_model import NotesRequest
from services.pdf_reader import extract_text_from_pdf
from services.quiz_pdf_service import generate_quiz_pdf


# ─────────────────────────────────────────────────────────────
# APP SETUP
# ─────────────────────────────────────────────────────────────
app = FastAPI(title="Audio AI Notes API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
PDF_DIR = Path("pdfs")

UPLOAD_DIR.mkdir(exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)


# ─────────────────────────────────────────────────────────────
# Load GEIMINI model & Initialize DB 
# ─────────────────────────────────────────────────────────────
print("Loading Gemini...")
notes_service = NotesService(GEMINI_API_KEY)

init_db()


# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────
@app.get("/")
def health():
    return {"status": "running"}


@app.post("/clean-audio")
async def clean_audio(file: UploadFile = File(...)):
    allowed = {".wav", ".mp3", ".m4a", ".ogg", ".flac"}
    ext = Path(file.filename).suffix.lower()

    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type")

    temp_id = str(uuid.uuid4())
    raw_path = UPLOAD_DIR / f"{temp_id}_raw{ext}"
    clean_path = UPLOAD_DIR / f"{temp_id}_clean.wav"

    with open(raw_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # process audio
    preprocess_audio(raw_path, clean_path)

    # IMPORTANT: only delete RAW file, NOT clean file
    raw_path.unlink(missing_ok=True)

    # return file (DO NOT DELETE CLEAN FILE HERE)
    return FileResponse(
        path=clean_path,
        media_type="audio/wav",
        filename="clean_audio.wav"
    )


# ─────────────────────────────────────────────────────────────
# 1️⃣ RAW AUDIO → TRANSCRIPT ONLY
# ─────────────────────────────────────────────────────────────
@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    allowed = {".wav", ".mp3", ".m4a", ".ogg", ".flac"}
    ext = Path(file.filename).suffix.lower()

    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type")

    file_id = str(uuid.uuid4())

    raw_path = UPLOAD_DIR / f"{file_id}_raw{ext}"
    clean_path = UPLOAD_DIR / f"{file_id}_clean.wav"

    with open(raw_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    preprocess_audio(raw_path, clean_path)

    whisper_model = WhisperModelManager.get_model()
    segments, info = whisper_model.transcribe(str(clean_path))
    transcript = " ".join(s.text.strip() for s in segments)

    raw_path.unlink(missing_ok=True)

    save_transcript(
        file_id,
        file.filename,
        info.language,
        round(info.duration, 2),
        transcript,
    )

    return {
        "file_id": file_id,
        "transcript": transcript,
        "language": info.language,
        "duration": round(info.duration, 2),
    }


# ─────────────────────────────────────────────────────────────
# 2️⃣ TRANSCRIPT → NOTES (JSON)
# ─────────────────────────────────────────────────────────────
@app.post("/generate-notes")
def generate_notes(req: NotesRequest):
    if not req.transcript.strip():
        raise HTTPException(status_code=400, detail="Empty transcript")

    return notes_service.generate_notes(req.transcript)


# ─────────────────────────────────────────────────────────────
# 3️⃣ TRANSCRIPT → PDF
# ─────────────────────────────────────────────────────────────
@app.post("/generate-pdf")
async def generate_pdf_endpoint(req: NotesRequest):
    if not req.transcript.strip():
        raise HTTPException(status_code=400, detail="Empty transcript")

    notes = notes_service.generate_notes(req.transcript)

    file_id = str(uuid.uuid4())
    pdf_path = PDF_DIR / f"{file_id}.pdf"

    generate_pdf(
        str(pdf_path),
        notes["title"],
        notes["summary"],
        notes["content"],
    )

    return FileResponse(
        path=pdf_path,
        media_type="application/pdf",
        filename="notes.pdf",
    )


# ─────────────────────────────────────────────────────────────
# 4️⃣ PROCESSED AUDIO → TRANSCRIPT → PDF (NEW REQUIRED ENDPOINT)
# ─────────────────────────────────────────────────────────────
@app.post("/audio-to-pdf")
async def audio_to_pdf(file: UploadFile = File(...)):
    """
    Frontend sends ALREADY processed/clean audio.
    Backend directly:
    transcription → notes → PDF
    """

    allowed = {".wav", ".mp3", ".m4a", ".ogg", ".flac"}
    ext = Path(file.filename).suffix.lower()

    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type")

    file_id = str(uuid.uuid4())

    audio_path = UPLOAD_DIR / f"{file_id}_audio{ext}"
    pdf_path = PDF_DIR / f"{file_id}.pdf"

    # Save incoming processed audio
    with open(audio_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # OPTIONAL preprocessing (safe even if already processed)
    clean_path = UPLOAD_DIR / f"{file_id}_clean.wav"
    preprocess_audio(audio_path, clean_path)

    # Transcription
    whisper_model = WhisperModelManager.get_model()
    segments, info = whisper_model.transcribe(str(clean_path))
    transcript = " ".join(s.text.strip() for s in segments)

    # Save transcript (optional tracking)
    save_transcript(
        file_id,
        file.filename,
        info.language,
        round(info.duration, 2),
        transcript,
    )

    # Generate notes
    notes = notes_service.generate_notes(transcript)

    # Generate PDF
    generate_pdf(
        str(pdf_path),
        notes["title"],
        notes["summary"],
        notes["content"],
    )

    # Cleanup
    audio_path.unlink(missing_ok=True)

    return FileResponse(
        path=pdf_path,
        media_type="application/pdf",
        filename="notes.pdf",
    )


# ─────────────────────────────────────────────────────────────
# 5️⃣ FULL PIPELINE (RAW AUDIO → PDF)
# ─────────────────────────────────────────────────────────────
@app.post("/process-audio")
async def process_audio(file: UploadFile = File(...)):
    """
    End-to-end pipeline for raw audio
    """

    allowed = {".wav", ".mp3", ".m4a", ".ogg", ".flac"}
    ext = Path(file.filename).suffix.lower()

    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type")

    file_id = str(uuid.uuid4())

    raw_path = UPLOAD_DIR / f"{file_id}_raw{ext}"
    clean_path = UPLOAD_DIR / f"{file_id}_clean.wav"
    pdf_path = PDF_DIR / f"{file_id}.pdf"

    with open(raw_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    preprocess_audio(raw_path, clean_path)

    whisper_model = WhisperModelManager.get_model()
    segments, info = whisper_model.transcribe(str(clean_path))
    transcript = " ".join(s.text.strip() for s in segments)

    save_transcript(
        file_id,
        file.filename,
        info.language,
        round(info.duration, 2),
        transcript,
    )

    notes = notes_service.generate_notes(transcript)

    generate_pdf(
        str(pdf_path),
        notes["title"],
        notes["summary"],
        notes["content"],
    )

    return FileResponse(
        path=pdf_path,
        media_type="application/pdf",
        filename="notes.pdf",
    )


@app.post("/generate-quiz-pdf")
async def generate_quiz_pdf_endpoint(file: UploadFile = File(...)):
    """
    PDF → Quiz → Quiz PDF
    """

    if not file.filename.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF allowed")

    file_id = str(uuid.uuid4())

    input_pdf_path = PDF_DIR / f"{file_id}_input.pdf"
    output_pdf_path = PDF_DIR / f"{file_id}_quiz.pdf"

    # Save uploaded PDF
    with open(input_pdf_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # Extract text
    text = extract_text_from_pdf(str(input_pdf_path))

    if not text.strip():
        raise HTTPException(status_code=400, detail="Empty PDF content")

    # Limit text for LLM
    text = text[:8000]

    # Generate quiz
    quiz_text = notes_service.generate_quiz(text)

    # Generate quiz PDF
    generate_quiz_pdf(str(output_pdf_path), quiz_text)

    # Cleanup input PDF (optional)
    input_pdf_path.unlink(missing_ok=True)

    return FileResponse(
        path=output_pdf_path,
        media_type="application/pdf",
        filename="quiz.pdf",
    )


# ─────────────────────────────────────────────────────────────
# 🔴 WEBSOCKET: LIVE STREAMING TRANSCRIPTION
# ─────────────────────────────────────────────────────────────
@app.websocket("/ws/transcribe-stream")
async def websocket_transcribe_stream(websocket: WebSocket):
    """
    WebSocket endpoint for live audio streaming transcription.
    
    Client flow:
    1. Connect to /ws/transcribe-stream
    2. Send binary audio chunks (PCM, mono, 16-bit, 16kHz)
    3. Receive JSON messages with partial transcriptions
    4. Close connection when done recording
    
    Server flow:
    1. Accept connection
    2. Receive audio chunks, buffer them (~2.5 seconds)
    3. Transcribe each buffer with Whisper
    4. Send partial transcriptions back
    5. On disconnect: accumulate full transcript, generate notes
    
    Message format (server → client):
    {
        "type": "partial" | "final" | "error",
        "partial_transcript": "text so far",
        "is_final": false,
        "language": "en",
        "duration": 2.5,
        ...
    }
    """
    await websocket.accept()
    
    # Initialize streaming transcription manager
    transcription_manager = StreamingTranscriptionManager(
        sample_rate=16000,
        buffer_duration=2.5
    )
    
    try:
        while True:
            # Receive binary audio data from client
            data = await websocket.receive_bytes()
            
            # Process audio chunk
            result = transcription_manager.add_audio_chunk(data)
            
            # Send response back to client
            await websocket.send_json({
                "type": "partial",
                **result
            })
            
    except WebSocketDisconnect:
        print("Client disconnected from streaming transcription")
        
    except Exception as e:
        print(f"WebSocket error: {str(e)}")
        try:
            await websocket.send_json({
                "type": "error",
                "error": str(e)
            })
        except:
            pass
        
    finally:
        # Finalize transcription
        final_result = transcription_manager.finalize_transcription()
        full_transcript = final_result["full_transcript"]
        
        if not full_transcript.strip():
            print("Empty transcript, closing WebSocket")
            try:
                await websocket.send_json({
                    "type": "error",
                    "error": "Empty recording"
                })
            except:
                pass
            return
        
        try:
            # Generate notes from accumulated transcript
            print(f"Generating notes from transcript ({len(full_transcript)} chars)...")
            notes = notes_service.generate_notes(full_transcript)
            
            # Save full audio to file for record
            file_id = str(uuid.uuid4())
            audio_path = UPLOAD_DIR / f"{file_id}_stream_audio.wav"
            transcription_manager.save_full_audio(str(audio_path))
            
            # Save transcript to database
            save_transcript(
                file_id=file_id,
                filename=f"stream_{file_id}.wav",
                language="en",
                duration=final_result["total_duration"],
                transcript=full_transcript
            )
            
            print(f"Saved recording {file_id}, generating final response...")
            
            # Send final result with notes
            await websocket.send_json({
                "type": "final",
                "file_id": file_id,
                "full_transcript": full_transcript,
                "duration": final_result["total_duration"],
                "notes": notes
            })
            
        except Exception as e:
            print(f"Error in finalization: {str(e)}")
            try:
                await websocket.send_json({
                    "type": "error",
                    "error": f"Failed to generate notes: {str(e)}"
                })
            except:
                pass