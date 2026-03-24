# ViseNotes

## 📌 Overview
**ViseNotes** is a professional AI-powered mobile application designed to bridge the gap between spoken lectures and structured study materials. Developed as part of the Software Engineering curriculum at FAST-NUCES, the app enables users to record live lectures or upload audio files and convert them into clean, structured, and study-ready notes.

By leveraging **Faster-Whisper** for high-accuracy speech-to-text and advanced NLP pipelines for summarization, ViseNotes transforms raw audio into:
- 📄 Organized notes  
- 🧠 Concise summaries  
- 📑 Exportable PDF documents  

---

## 🚀 Features
- 🎙️ Real-time lecture recording  
- 📤 Audio file upload support  
- 🧹 Noise reduction & preprocessing  
- 📝 Accurate transcription using Faster-Whisper  
- 📚 AI-generated summaries  
- 📄 PDF export  
- 📱 Cross-platform mobile app (Flutter)

---

## 👥 Team Members
- **Iqra Afzal (23L-0887)**  
  *AI/NLP Engineer, Mobile Developer, Requirement Engineer*

- **Noor Ul Sabah (23L-0915)**  
  *AI/NLP Engineer, Requirement Engineer*

---

## Tech Stack

### Frontend
- **Flutter** (Dart) – Cross-platform mobile development  
- **Material UI** – UI components  

### Backend
- **FastAPI** – High-performance API framework  
- **Uvicorn** – ASGI server  

### AI / Machine Learning
- **Faster-Whisper** – Speech-to-text  

---

## ⚙️ Complete Setup Guide

---

## System Requirements
- **Python:** `>= 3.9`
- **Flutter SDK:** `>= 3.19.x`
- **pip:** Latest version
- **FFmpeg (REQUIRED)**

### Install FFmpeg
- **Windows**
```bash
choco install ffmpeg
```

- **Mac**
```bash
brew install ffmpeg
```

- **Linux**
```bash
sudo apt install ffmpeg
```

---

## Backend Setup (FastAPI + AI)

### Navigate to backend
```bash
cd backend
```

### Create Virtual Environment (Recommended)
```bash
python -m venv venv
```

#### Activate venv
- Windows:
```bash
venv\Scripts\activate
```
- Mac/Linux:
```bash
source venv/bin/activate
```

---

### Install Dependencies (Using requirements.txt)

Create a `requirements.txt` file inside `backend/` with:

```
fastapi
uvicorn
python-multipart
faster-whisper
ctranslate2
noisereduce
pydub
numpy
soundfile
librosa
pydantic
```

Then install:

```bash
pip install -r requirements.txt
```

---

### Run Backend Server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Backend URL
```
http://127.0.0.1:8000
```

---

## 3️⃣ Frontend Setup (Flutter)

### Navigate to frontend
```bash
cd frontend
```

### Install dependencies
```bash
flutter pub get
```

### Run App
```bash
flutter run
```

---

## 🔌 API Endpoints (Sample)

| Method | Endpoint | Description |
|------|--------|------------|
| POST | /upload-audio | Upload audio |
| GET | /transcription/{id} | Get transcription |
| GET | /summary/{id} | Get summary |

---
