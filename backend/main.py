import shutil
import uuid
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

import noisereduce as nr
import soundfile as sf
import numpy as np
from faster_whisper import WhisperModel

from database import init_db, save_transcript


# ── App setup ────────────────────────────────────────────────────────────────
app = FastAPI(title="Audio Processing API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow Flutter app to call this
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# ── Load Whisper once at startup (not per request) ────────────────────────────
print("Loading Whisper model...")
model = WhisperModel("small", device="cpu", compute_type="int8")
print("Model ready.")
init_db()

# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/")
def health_check():
    return {"status": "running"}


@app.post("/upload")
async def upload_audio(file: UploadFile = File(...)):
    print(f">>> Request received: {file.filename}")

    # 1. Validate file type
    allowed = {".wav", ".mp3", ".m4a", ".ogg", ".flac"}
    ext = Path(file.filename).suffix.lower()
    if ext not in allowed:
        raise HTTPException(
            status_code=400, detail=f"Unsupported file type '{ext}'. Allowed: {allowed}"
        )

    # 2. Save raw uploaded file to disk
    file_id = str(uuid.uuid4())
    raw_path = UPLOAD_DIR / f"{file_id}_raw{ext}"
    clean_path = UPLOAD_DIR / f"{file_id}_clean.wav"

    with open(raw_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # 3. Load audio
    try:
        audio, sr = sf.read(str(raw_path))
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Could not read audio: {e}")

    # 4. Convert stereo to mono if needed
    if audio.ndim > 1:
        audio = audio.mean(axis=1)

    # 5. Noise reduction
    reduced = nr.reduce_noise(y=audio, sr=sr)

    # 6. Normalize volume (peak normalization)
    peak = np.max(np.abs(reduced))
    if peak > 0:
        normalized = reduced / peak
    else:
        normalized = reduced

    # 7. Save clean audio
    sf.write(str(clean_path), normalized, sr)

    # 8. Transcribe with Whisper
    try:
        segments, info = model.transcribe(
            str(clean_path),
            beam_size=5,
            vad_filter=True,  # skip silent parts automatically
        )
        transcript = " ".join(seg.text.strip() for seg in segments)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {e}")

    # 9. Clean up raw file (keep clean audio)
    raw_path.unlink(missing_ok=True)

    # 10. Save to database
    save_transcript(
        file_id=file_id,
        filename=file.filename,
        language=info.language,
        duration=round(info.duration, 2),
        transcript=transcript,
    )

    return JSONResponse(
        {
            "file_id": file_id,
            "transcript": transcript,
            "language": info.language,
            "duration_seconds": round(info.duration, 2),
            "clean_audio": str(clean_path),
        }
    )
