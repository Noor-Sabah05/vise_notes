#just take this as reference as i will need to integrate this project with that for complete pipeline

## Executive Summary

ViseNotes is a mobile-first audio recording and transcription platform that captures user voice recordings, processes them through AI-powered noise reduction and speech-to-text conversion, and provides both playback and downloadable cleaned audio files with complete transcripts.

**Stack:**
- **Frontend:** Flutter (Dart) - Cross-platform mobile application
- **Backend:** Python FastAPI - Audio processing and API server
- **AI Model:** Faster Whisper (OpenAI's Whisper) - Speech-to-text transcription
- **Database:** SQLite - Transcript and metadata storage
- **Audio Processing:** noisereduce, soundfile, numpy - Audio manipulation libraries

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VSENOTES ECOSYSTEM                          │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────┐      ┌─────────────────────────────┐
│    FLUTTER MOBILE APP        │      │      PYTHON BACKEND API     │
│   (Android/iOS Client)       │      │     (FastAPI Server)        │
│                              │      │                             │
│ • Record Screen              │      │ • Audio Upload Endpoint     │
│ • Save Screen                │◄────►│ • Processing Pipeline       │
│ • Recordings Screen          │ HTTP │ • Database Management       │
│ • Transcripts Screen         │      │ • File Storage              │
│ • Events/Profile             │      │                             │
└──────────────────────────────┘      └─────────────────────────────┘
         │                                        │
         │                                        │
         └────────────────────┬───────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  WHISPER AI MODEL  │
                    │  (Transcription)   │
                    └────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │   SQLite Database  │
                    │  (transcripts.db)  │
                    └────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  File Storage      │
                    │  (uploads/)        │
                    └────────────────────┘
```

---

## 1. Core Data Models

### Recording Object (Frontend)
```
Recording {
  id              : String          // Unique identifier
  title           : String          // User-provided name
  category        : String          // Classification (e.g., "Meeting", "Note")
  date            : DateTime        // Timestamp of recording
  duration        : Duration        // Audio length
  filePath        : String          // Local file path on device
  transcript      : String?         // AI-generated text
  cleanedAudio    : String?         // Path to noise-reduced audio file
}
```

### Transcript Record (Database/Backend)
```
Transcript {
  id              : INTEGER PRIMARY KEY   // Auto-increment ID
  file_id         : TEXT UNIQUE          // UUID from backend processing
  filename        : TEXT                 // Original filename
  language        : TEXT                 // Detected language (or "en" default)
  duration        : REAL                 // Audio duration in seconds
  transcript      : TEXT                 // Full transcribed text
  created_at      : TEXT ISO8601         // Creation timestamp
}
```

### API Response Format (Backend)
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "meeting_2024.m4a",
  "cleaned_audio_path": "/uploads/550e8400-e29b-41d4-a716-446655440000_clean.wav",
  "transcript": "Hello everyone, welcome to today's meeting...",
  "language": "en",
  "duration": 234.5,
  "created_at": "2024-03-24T15:30:45.123456"
}
```

---

## 2. Complete User Workflow

### Phase 1: Recording Audio

```
┌─────────────────────────────────────────────────────────────────┐
│ USER → RECORD SCREEN (lib/screens/record_screen.dart)          │
└─────────────────────────────────────────────────────────────────┘
           │
           ├─► User taps "Start Recording" button
           │
           └─► Audio Recording Service Initiated
                   ├─ Microphone permission requested
                   ├─ Audio stream captures raw microphone input
                   ├─ File written to device storage
                   └─ Duration tracked in real-time
           
           User may:
           ├─► PAUSE/RESUME recording (pauses counter, resumes capture)
           ├─► CANCEL (discards file, returns to home)
           └─► STOP (finalizes audio, proceeds to save screen)

           ┌─────────────────────────────────────────────────────┐
           │ SAVE SCREEN (lib/screens/save_screen.dart)          │
           └─────────────────────────────────────────────────────┘
                   │
                   ├─ User prompted to enter:
                   │  ├─ Title: "Meeting with Client"
                   │  └─ Category: Dropdown (Meeting/Note/Lecture/etc)
                   │
                   ├─ Audio file loaded into memory
                   │
                   └─ User taps "Save & Upload"
                          │
                          └─► Recording Service.uploadAudio(audioFile)
```

**Key Files Involved:**
- `lib/screens/record_screen.dart` - UI for recording
- `lib/screens/save_screen.dart` - Metadata collection
- `lib/services/recording_service.dart` - Audio recording logic

---

### Phase 2: Server-Side Audio Processing Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│ FastAPI BACKEND - POST /upload (backend/main.py)                │
└──────────────────────────────────────────────────────────────────┘

STEP 1: VALIDATE INPUT
┌────────────────────────────────────────────────────────────────┐
│ Check file extension against whitelist:                        │
│ Allowed: .wav, .mp3, .m4a, .ogg, .flac                        │
│ Action: Reject with 400 error if invalid                      │
└────────────────────────────────────────────────────────────────┘
           │
           ├─ PASS ──► Continue to Step 2
           └─ FAIL ──► Return HTTPException(400, "Unsupported format")

STEP 2: FILE STORAGE & SETUP
┌────────────────────────────────────────────────────────────────┐
│ Generate unique file_id: UUID4()                               │
│ Create paths:                                                  │
│  - Raw path:   uploads/{file_id}_raw.{ext}                   │
│  - Clean path: uploads/{file_id}_clean.wav                   │
│ Write uploaded file to raw_path                               │
│ Result: File persisted on server disk                         │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 3

STEP 3: AUDIO LOADING & CONVERSION
┌────────────────────────────────────────────────────────────────┐
│ Library: soundfile (sf.read)                                   │
│ Operation:                                                     │
│  - Read raw audio file into NumPy array                       │
│  - Extract sample rate (sr) from file metadata                │
│  - Check dimensions: if stereo (ndim > 1) → convert to mono  │
│    • Mono: mean(axis=1) - average both channels              │
│ Output: audio[array], sr[int]                                 │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 4

STEP 4: NOISE REDUCTION
┌────────────────────────────────────────────────────────────────┐
│ Library: noisereduce                                           │
│ Function: nr.reduce_noise(y=audio, sr=sr)                     │
│ Algorithm:                                                     │
│  - Spectral gating technique                                  │
│  - Estimates noise profile from quiet sections                │
│  - Removes consistent background noise (hum, fan, etc)       │
│  - Preserves speech intelligibility                           │
│ Output: reduced[array] - same shape, noise-reduced audio      │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 5

STEP 5: AUDIO NORMALIZATION
┌────────────────────────────────────────────────────────────────┐
│ Type: Peak Normalization                                       │
│ Process:                                                       │
│  - Find maximum absolute amplitude value: peak = max(|audio|) │
│  - If peak > 0: normalized = reduced / peak                   │
│  - Else: normalized = reduced (silent audio)                  │
│ Effect:                                                        │
│  - Scales audio so loudest point = ±1.0 (max digital value)  │
│  - Ensures consistent volume levels across recordings         │
│ Output: normalized[array]                                     │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 6

STEP 6: SAVE CLEANED AUDIO
┌────────────────────────────────────────────────────────────────┐
│ Library: soundfile (sf.write)                                  │
│ Action: Write normalized audio to clean_path as WAV           │
│ File: uploads/{file_id}_clean.wav                             │
│ Quality: 16-bit PCM, preserves original sample rate           │
│ Result: Clean audio file saved on disk, ready for playback    │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 7

STEP 7: TRANSCRIPTION (Faster Whisper)
┌────────────────────────────────────────────────────────────────┐
│ Model: Faster Whisper "small"                                  │
│ Device: CPU (int8 quantization for efficiency)                │
│ Loaded at startup, cached in memory                           │
│ Processing:                                                    │
│  - transcribe(clean_path)                                     │
│  - Beam search: 5 (balance speed vs accuracy)                │
│  - VAD Filter: ON (skip silent sections automatically)       │
│ Output: List of segments with text                            │
│ Post-processing: Join all segments into one string            │
│ Result: transcript = "Full transcribed text..."               │
│ Time: ~10-30 seconds for 5min audio (varies with hardware)   │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 8

STEP 8: CLEANUP RAW FILE
┌────────────────────────────────────────────────────────────────┐
│ Action: Delete raw uploaded file                               │
│ File deleted: uploads/{file_id}_raw.{ext}                    │
│ Reason: Contains raw, unprocessed audio; clean version exists│
│ Result: Saves disk space                                      │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 9

STEP 9: DATABASE STORAGE
┌────────────────────────────────────────────────────────────────┐
│ Function: save_transcript() (backend/database.py)             │
│ SQL: INSERT INTO transcripts (...)                            │
│ Data stored:                                                   │
│  - file_id: UUID                                              │
│  - filename: Original filename from upload                    │
│  - language: "en" (default, from UI)                         │
│  - duration: seconds (calculated from audio)                  │
│  - transcript: Full text                                      │
│  - created_at: Current timestamp (ISO8601)                    │
│ Database: transcripts.db (SQLite)                             │
│ Result: Record persisted in database                          │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Continue to Step 10

STEP 10: RESPONSE & CLIENT NOTIFICATION
┌────────────────────────────────────────────────────────────────┐
│ Return to Mobile Client:                                       │
│                                                                │
│ {                                                              │
│   "file_id": "550e8400-e29b-41d4-a716-446655440000",        │
│   "filename": "meeting_2024.m4a",                             │
│   "cleaned_audio_path": "/uploads/{file_id}_clean.wav",     │
│   "transcript": "Full transcribed text...",                   │
│   "language": "en",                                           │
│   "duration": 234.5,                                          │
│   "created_at": "2024-03-24T15:30:45.123456"                 │
│ }                                                              │
│                                                                │
│ Status: 200 OK                                                │
└────────────────────────────────────────────────────────────────┘
           │
           └─► Mobile app receives response, updates UI

ERROR HANDLING AT ANY STEP:
┌────────────────────────────────────────────────────────────────┐
│ If error occurs:                                               │
│  - Log error details to console/monitoring                    │
│  - Return HTTP 400/422/500 with error detail                  │
│  - Mobile client catches exception, shows user-friendly msg   │
│  - Transaction rolled back (raw file may be deleted)          │
└────────────────────────────────────────────────────────────────┘
```

**Key Files Involved:**
- `backend/main.py` - Routes and orchestration
- `backend/models/wispermodel.py` - Whisper model loader
- `backend/database.py` - Database operations

---

### Phase 3: Mobile Client Receives & Stores Data

```
┌──────────────────────────────────────────────────────────────────┐
│ MOBILE APP - Handle Upload Response                            │
└──────────────────────────────────────────────────────────────────┘

STEP 1: PARSE RESPONSE
┌────────────────────────────────────────────────────────────────┐
│ API Response received by ApiService.uploadAudio()             │
│ JSON parsed:                                                   │
│  - Extract: transcript, cleaned_audio_path, file_id, etc     │
│ Status check: 200 = success, else throw exception             │
└────────────────────────────────────────────────────────────────┘

STEP 2: UPDATE RECORDING OBJECT
┌────────────────────────────────────────────────────────────────┐
│ Create Recording object with:                                  │
│  - title: From save screen input                              │
│  - category: From save screen input                           │
│  - transcript: From API response                              │
│  - cleanedAudio: Path from API response                       │
│  - Other fields: Preserved from creation                      │
└────────────────────────────────────────────────────────────────┘

STEP 3: STORE LOCALLY (In-Memory)
┌────────────────────────────────────────────────────────────────┐
│ Recording added to app state                                   │
│ Made available in Recordings Screen                           │
│ NOTE: Current implementation stores in memory                 │
│ Future: Could use local database (Hive/sqlflite)             │
└────────────────────────────────────────────────────────────────┘

STEP 4: USER FEEDBACK
┌────────────────────────────────────────────────────────────────┐
│ Show SnackBar: "Upload successful! Transcript ready."         │
│ Navigate back to Home or Recordings screen                    │
└────────────────────────────────────────────────────────────────┘
```

**Key Files Involved:**
- `lib/services/api_service.dart` - HTTP communication
- `lib/services/recording_service.dart` - Recording management
- `lib/screens/save_screen.dart` - Handles response

---

## 3. Playback & Interaction Flow

### Audio Playback Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│ RECORDINGS SCREEN - Play Audio (lib/screens/recordings_screen.dart)
└──────────────────────────────────────────────────────────────────┘

STEP 1: USER TAPS PLAY BUTTON
┌────────────────────────────────────────────────────────────────┐
│ Recording object identified by ID                              │
│ Check: cleanedAudio path is not null/empty                    │
│ Button visual state updated: Play → Pause icon                │
└────────────────────────────────────────────────────────────────┘

STEP 2: AUDIO FILE LOADING
┌────────────────────────────────────────────────────────────────┐
│ Library: just_audio (AudioPlayer)                              │
│ Operation: _audioPlayer.setFilePath(audio.cleanedAudio!)      │
│ This:                                                          │
│  - Resolves file path on device                               │
│  - Loads audio into memory                                    │
│  - Prepares decoder                                           │
│  - Status: "loaded" when ready to play                        │
└────────────────────────────────────────────────────────────────┘

STEP 3: PLAYBACK START
┌────────────────────────────────────────────────────────────────┐
│ Operation: await _audioPlayer.play()                           │
│ This:                                                          │
│  - Starts audio output to device speakers/headphones          │
│  - Updates player state → playing = true                      │
│ UI updates:                                                    │
│  - Button shows pause icon                                    │
│  - Recording tile shows shadow/highlight effect               │
│  - Button becomes interactive for pause                       │
└────────────────────────────────────────────────────────────────┘

STEP 4: PLAYBACK STATE LISTENING
┌────────────────────────────────────────────────────────────────┐
│ StreamListener: _audioPlayer.playerStateStream                │
│ Triggers on every state change:                               │
│  - When user pauses: playing = false → UI updates            │
│  - When user resumes: playing = true → UI updates            │
│  - When file completes: processingState = completed         │
│    • Sets _currentlyPlayingId = null                          │
│    • Button reverts to play icon                              │
│    • Shadow effect removed                                    │
└────────────────────────────────────────────────────────────────┘

STEP 5: PAUSE/RESUME HANDLING
┌────────────────────────────────────────────────────────────────┐
│ User taps pause button (visible during playback):             │
│  - Operation: await _audioPlayer.pause()                      │
│  - Updates state: playing = false                             │
│  - UI: Button changes to play icon                            │
│                                                                │
│ User taps play again (button shows play icon):                │
│  - Operation: await _audioPlayer.play()                       │
│  - Resumes from current position (not from start)             │
│  - UI: Button changes to pause icon                           │
└────────────────────────────────────────────────────────────────┘

STEP 6: STOP/CLEANUP
┌────────────────────────────────────────────────────────────────┐
│ User selects different recording:                             │
│  - Operation: await _audioPlayer.stop()                       │
│  - Previous audio playback halted                             │
│  - Playback position reset to start                           │
│  - New recording loads and plays                              │
│                                                                │
│ Screen disposed:                                              │
│  - Operation: dispose() method called                         │
│  - _audioPlayer resource released                            │
│  - Listeners unsubscribed                                     │
│  - Memory cleaned up                                          │
└────────────────────────────────────────────────────────────────┘

ERROR SCENARIOS:
┌────────────────────────────────────────────────────────────────┐
│ File not found (cleanedAudio = null):                          │
│  - SnackBar: "No cleaned audio available"                      │
│  - Button remains unclickable                                  │
│                                                                │
│ File deleted from server:                                      │
│  - Exception caught in try/catch                              │
│  - SnackBar: "Error playing audio: [error message]"          │
│  - State reset (_currentlyPlayingId = null)                   │
│                                                                │
│ Device has no speakers/audio output:                          │
│  - just_audio handles gracefully (no exception)               │
│  - Audio plays to default output device                       │
└────────────────────────────────────────────────────────────────┘
```

**State Variables:**
- `late AudioPlayer _audioPlayer` - Player instance (initialized in initState)
- `String? _currentlyPlayingId` - Tracks which recording is playing
- `bool _isPlaying` - True when audio is currently playing
- `playerStateStream.listen()` - Subscribes to playback state changes

**Key Methods:**
- `_playAudio(Recording audio)` - Initiates playback
- `_pauseAudio()` - Pauses current playback
- `dispose()` - Cleanup on widget destruction

---

### Download Audio Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│ USER TAPS DOWNLOAD BUTTON (recordings_screen.dart)             │
└──────────────────────────────────────────────────────────────────┘
           │
           └─► RecordingService.downloadCleanedAudio(recording)
                   │
                   ├─ File Picker opened (FilePickerDelegate)
                   │  └─ User selects destination directory
                   │
                   ├─ Source: cleanedAudio path on device
                   │
                   ├─ Destination: User-selected folder
                   │  (e.g., /Download/, /Documents/, etc)
                   │
                   ├─ File copied via native file operations
                   │
                   └─ Completion: SnackBar confirms download
                      File saved as: {title}_{date}.wav
```

---

## 4. Data Flow Diagram (End-to-End)

```
┌───────────────────────────────────────────────────────────────────┐
│                      USER INTERACTION LAYER                       │
│                                                                   │
│  Record Screen → Save Screen → Main Shell → Recordings Screen  │
│                                                ↓                 │
│                                    [Play/Download/Delete]        │
└───────────────────────────────────────────────────────────────────┘
                                ↓
┌───────────────────────────────────────────────────────────────────┐
│                      SERVICES & API LAYER                         │
│                      (lib/services/)                              │
│                                                                   │
│  RecordingService ←───→ ApiService ←───────┐                    │
│  • Record audio        • HTTP requests      │                    │
│  • Manage playback     • JSON encode/decode │                    │
│  • Download files                          │                    │
└───────────────────────────────────────────────────────────────────┘
                                ↓
                    HTTP/REST (port 8000)
                   Multipart form-data (audio)
                                ↓
┌───────────────────────────────────────────────────────────────────┐
│                  FASTAPI BACKEND LAYER                            │
│                  (backend/main.py)                                │
│                                                                   │
│  POST /upload:                                                    │
│    ├─ Validate format                                             │
│    ├─ Store raw file                                              │
│    ├─ Load audio (soundfile)                                      │
│    ├─ Reduce noise (noisereduce)                                  │
│    ├─ Normalize volume                                            │
│    ├─ Save cleaned audio                                          │
│    ├─ Transcribe (Whisper)                                        │
│    ├─ Delete raw file                                             │
│    └─ Save to database                                            │
└───────────────────────────────────────────────────────────────────┘
                ↓                           ↓
  ┌─────────────▼──────────┐   ┌──────────▼──────────┐
  │    SQLite Database     │   │   File Storage      │
  │   transcripts.db       │   │   /uploads/         │
  │                        │   │                     │
  │ ┌────────────────────┐ │   │ {uuid}_clean.wav    │
  │ │ id                 │ │   │                     │
  │ │ file_id (UUID)     │ │   │ (Cleaned audio      │
  │ │ filename           │ │   │  for download &     │
  │ │ language           │ │   │  playback)          │
  │ │ duration           │ │   │                     │
  │ │ transcript (text)  │ │   └─────────────────────┘
  │ │ created_at         │ │
  │ └────────────────────┘ │
  └────────────────────────┘
                ↓
        JSON Response to API
                ↓
┌───────────────────────────────────────────────────────────────────┐
│                   MOBILE APP STATE                                │
│                                                                   │
│  Recording object updated:                                        │
│    • transcript ← API response                                    │
│    • cleanedAudio ← API response path                             │
│    • Stored in-memory                                             │
└───────────────────────────────────────────────────────────────────┘
                ↓
┌───────────────────────────────────────────────────────────────────┐
│                   UI DISPLAY LAYER                                │
│                                                                   │
│  Recordings Screen:                                               │
│    • Display recording list                                       │
│    • Show transcript                                              │
│    • Play button (uses just_audio)                                │
│    • Download button                                              │
│    • Metadata (title, category, date, duration)                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 5. Technology Stack Details

| Layer | Technology | Purpose | Version |
|-------|-----------|---------|---------|
| **Frontend** | Flutter | Cross-platform mobile UI | Dart 3.11.3+ |
| **Frontend** | just_audio | Audio playback with state tracking | ^0.9.36 |
| **Frontend** | http | HTTP client for API calls | ^1.2.0 |
| **Frontend** | file_picker | Device file selection dialog | ^8.0.3 |
| **Backend** | FastAPI | REST API framework | Latest |
| **Backend** | CORS Middleware | Cross-origin requests support | Built-in |
| **Audio Processing** | noisereduce | Spectral noise removal | Latest |
| **Audio Processing** | soundfile | WAV/audio file I/O | Latest |
| **Audio Processing** | NumPy | Numerical array operations | Latest |
| **AI/ML** | faster-whisper | OpenAI Whisper (optimized) | Latest |
| **Database** | SQLite3 | Embedded relational database | 3.x |
| **Networking** | HTTP/Multipart | File upload protocol | RFC 7578 |

---

## 6. API Specification

### Endpoint: POST /upload

**Purpose:** Upload raw audio file for processing (cleaning + transcription)

**Request:**
```
POST http://192.168.100.204:8000/upload
Content-Type: multipart/form-data

Body: 
  file: [binary audio data]
  filename: recording_name.m4a (or .wav, .mp3, .flac, .ogg)
```

**Supported Formats:** `.wav`, `.mp3`, `.m4a`, `.ogg`, `.flac`

**Processing Time:** 
- 5 min audio → ~10-30 seconds (CPU dependent)
- Includes: noise reduction, normalization, Whisper transcription

**Timeout:** 15 minutes (configured for long processing)

**Response (200 OK):**
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "recording.m4a",
  "cleaned_audio_path": "/uploads/550e8400-e29b-41d4-a716-446655440000_clean.wav",
  "transcript": "Full transcribed text from the audio file...",
  "language": "en",
  "duration": 234.5,
  "created_at": "2024-03-24T15:30:45.123456"
}
```

**Error Responses:**

| Status | Scenario | Response |
|--------|----------|----------|
| 400 | Unsupported file type | `{"detail": "Unsupported file type '.xyz'. Allowed: ..."}` |
| 422 | Cannot read audio file | `{"detail": "Could not read audio: [error]"}` |
| 500 | Transcription failed | `{"detail": "Transcription failed: [error]"}` |

---

## 7. Audio Processing Pipeline (Technical Details)

### Noise Reduction Algorithm
- **Library:** noisereduce
- **Method:** Spectral gating
- **Process:**
  1. Extract noise profile from silent sections
  2. Create spectral mask from noise characteristics
  3. Apply gate to suppress matching frequency components
  4. Preserve speech/signal in non-masked frequencies

### Normalization Strategy
- **Type:** Peak Normalization
- **Formula:** `normalized = audio / max(|audio|)`
- **Result:** Maximum amplitude = ±1.0 (digital peak)
- **Advantage:** Consistent volume across all recordings

### Whisper Configuration
```python
WhisperModel(
  "small",              # Model size (small = 244M params)
  device="cpu",         # CPU inference (not GPU)
  compute_type="int8"   # 8-bit quantization (faster, lower memory)
)

model.transcribe(
  audio_file,
  beam_size=5,          # Balance speed vs accuracy
  vad_filter=True       # Voice Activity Detection - skip silence
)
```

---

## 8. Database Schema

```sql
CREATE TABLE transcripts (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  file_id     TEXT NOT NULL,              -- UUID from processing
  filename    TEXT,                       -- Original upload name
  language    TEXT,                       -- Language code (e.g., "en")
  duration    REAL,                       -- Audio length in seconds
  transcript  TEXT,                       -- Full transcribed text
  created_at  TEXT DEFAULT (datetime('now'))  -- ISO8601 timestamp
);
```

**Queries:**
- **Get all:** `SELECT * FROM transcripts ORDER BY created_at DESC`
- **Get by ID:** `SELECT * FROM transcripts WHERE id = ?`
- **Insert:** `INSERT INTO transcripts (...) VALUES (...)`

---

## 9. File Storage Structure

```
Backend Root/
├── uploads/                          # Audio files directory
│   ├── {uuid}_clean.wav             # Processed, clean audio
│   ├── {uuid}_clean.wav             # Another recording...
│   └── ...
│
├── transcripts.db                    # SQLite database
├── main.py                          # FastAPI app & routes
├── database.py                      # DB operations
└── models/
    └── wispermodel.py               # Whisper model loader
```

---

## 10. Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   MOBILE DEVICE (Android)               │
│                                                         │
│  IP: Dynamic (192.168.x.x on local network)            │
│  Port: Ephemeral (client-side, assigned by OS)         │
└─────────────────────────────────────────────────────────┘
                     HTTP/HTTPS
                          │
                    TCP Port 8000
                          │
┌─────────────────────────────────────────────────────────┐
│              BACKEND SERVER (Python)                    │
│                                                         │
│  IP: 192.168.100.204 (hardcoded in mobile app)         │
│  Protocol: HTTP (development; should use HTTPS in prod)│
│  Framework: FastAPI                                    │
│  Worker: Uvicorn                                       │
│  Port: 8000                                            │
└─────────────────────────────────────────────────────────┘
```

**Network Configuration:**
- Both devices on same local network (192.168.100.x/24)
- Firebase/Cloud deployment: Would require public IP + HTTPS
- Current setup: Development/LAN only

---

## 11. State Management Flow

### Frontend State (In-Memory)
```
App State
├── List<Recording> recordings     ← Populated after upload
│   └── Recording {
│       id, title, category, date, duration,
│       filePath, transcript, cleanedAudio
│     }
│
├── Current Screen Index           ← Navigation state
│
└── AudioPlayer Instance           ← Playback state
    ├── _currentlyPlayingId        ← Which recording playing
    ├── _isPlaying                 ← Boolean play state
    └── playerStateStream listener ← Auto-updating
```

### Backend State (Database)
```
SQLite Database (transcripts.db)
└── transcripts table
    └── Each row = Completed audio processing
        ├── file_id (UUID)
        ├── filename, transcript, language
        ├── duration, created_at
        └── Persisted when upload completes
```

---

## 12. Error Handling & Resilience

| Scenario | Handling | Result |
|----------|----------|--------|
| Network timeout | 15min max wait | Retry or timeout exception |
| Invalid audio format | Format validation | 400 Bad Request |
| Corrupted audio file | soundfile try/catch | 422 Unprocessable Entity |
| Whisper model error | Exception catch | 500 Internal Server Error |
| Database write fail | Transaction rollback | Log error, retry notify user |
| File permission denied | OS-level exception | 500 Server Error |
| Playback file missing | null check before play | SnackBar: "File not found" |
| Audio device unavailable | just_audio graceful | Output to default device |

---

## 13. Performance Characteristics

| Operation | Time | Bottleneck |
|-----------|------|-----------|
| Record 5 min audio | 5 min | Real-time mic input |
| Upload 5 min file (WiFi) | ~30 sec | Network bandwidth |
| Noise reduction 5 min | ~2-3 sec | CPU (single-threaded) |
| Whisper transcription 5 min | ~15-25 sec | CPU (model inference) |
| **Total end-to-end** | **~50-60 sec** | Whisper model |
| Play audio | Real-time | System audio output |
| Download cleaned audio | ~2-5 sec | Network + file I/O |

**Optimization Opportunities:**
- Model quantization (already using int8)
- GPU acceleration (would require GPU instance)
- Async processing queue (Celery/RabbitMQ)
- Client-side preprocessing (reduce bandwidth)

---

## 14. Deployment & Infrastructure

### Development Setup
```bash
# Backend startup
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Whisper model auto-downloads on first run
# Database auto-initializes

# Frontend startup
cd visenotes
flutter run -d <device_id>
```

### Production Considerations
1. **HTTPS/TLS** - Replace HTTP with HTTPS
2. **Public IP/Domain** - Configure reverse proxy (Nginx)
3. **Database** - Consider PostgreSQL for scaling
4. **Model Hosting** - Use cloud GPU (AWS, GCP, Azure)
5. **File Storage** - Move to cloud storage (S3, GCS)
6. **Monitoring** - Add logging, alerts (Sentry, DataDog)
7. **Rate Limiting** - Prevent abuse
8. **Authentication** - Add user accounts, API keys

---

## 15. User Journey Map

```
┌───────────────────────────────────────────────────────────────┐
│ USER JOURNEY                                                  │
└───────────────────────────────────────────────────────────────┘

1. DISCOVERY
   └─ Open ViseNotes app
      └─ See Home/Records/Transcripts tabs

2. RECORDING
   └─ Navigate to Record Screen
      └─ Tap "Start Recording"
         └─ Speak into microphone
            └─ Tap "Stop Recording"

3. METADATA
   └─ Navigate to Save Screen
      └─ Enter title: "Q4 Planning Meeting"
         └─ Select category: "Meeting"
            └─ Tap "Save & Upload"

4. PROCESSING (TRANSPARENT)
   └─ Backend processes:
      └─ Noise reduction
      └─ Transcription
      └─ Database storage
   └─ Progress: Loading indicator on Save Screen

5. RESULTS
   └─ Redirected to Recordings Screen
      └─ See recording in list
      └─ Transcript visible
      └─ Ready to:
         ├─ Play cleaned audio
         ├─ View full transcript
         ├─ Download audio file
         └─ Share/export

6. DISCOVERY (Later)
   └─ Open app again
      └─ All previous recordings visible
      └─ Can replay, download, review
```

---

## 16. Future Roadmap & Extensions

**Phase 2:**
- [ ] User accounts & authentication
- [ ] Cloud storage (AWS S3/Google Cloud Storage)
- [ ] Multiple languages support
- [ ] Transcript editing & search
- [ ] Real-time transcription (WebSocket)

**Phase 3:**
- [ ] Speaker identification (diarization)
- [ ] Meeting summary generation (GPT integration)
- [ ] Export to PDF/document formats
- [ ] Sharing & collaboration
- [ ] Advanced analytics (word frequency, sentiment)

**Phase 4:**
- [ ] Mobile app offline mode
- [ ] Desktop web interface
- [ ] Video transcription
- [ ] Custom vocabulary/domain models
- [ ] API for third-party integrations

---

## 17. Technical Glossary

- **API:** Application Programming Interface - standardized way for apps to communicate
- **AudioPlayer:** just_audio library instance managing audio playback state
- **Beam Search:** Whisper configuration for transcription accuracy (beam_size=5)
- **Cleaned Audio:** Noise-reduced, normalized WAV file output by backend
- **CORS:** Cross-Origin Resource Sharing - allows mobile app to call backend
- **FastAPI:** Modern Python web framework for building APIs
- **File_ID:** UUID generated on backend for unique file identification
- **Multipart Data:** HTTP format for sending files mixed with metadata
- **Noise Reduction:** Spectral gating algorithm removing consistent background noise
- **Normalization:** Scaling audio amplitude to consistent peak level (±1.0)
- **SQLite:** Lightweight relational database stored as single file
- **State Listener:** Observable pattern - subscribes to AudioPlayer changes
- **SnackBar:** Brief toast notification at bottom of mobile screen
- **VAD Filter:** Voice Activity Detection - skips silent sections in transcription
- **WAV:** Uncompressed audio format used for cleaned output
- **Whisper:** OpenAI's open-source speech-to-text model

---

## 18. Contact & Support

For technical questions about this pipeline:
- Consult individual component documentation
- Review source code comments
- Check terminal logs during execution
- Verify network connectivity (ping backend IP)
- Ensure Whisper model downloaded properly

---

**Document Version:** 1.0  
**Last Updated:** March 24, 2024  
**Status:** Production Overview  
**Scope:** Complete technical pipeline for ViseNotes application
