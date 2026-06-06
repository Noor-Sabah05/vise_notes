# ViseNotes

**AI-powered Audio-to-Structured Notes System for Students, Educators, and Professionals**

ViseNotes transforms raw audio lectures and meetings into structured knowledge assets — including transcripts, summarized notes, categorized storage, quizzes, and exportable PDFs. It enables users to focus on understanding rather than manual note-taking.

---

## 🚀 Overview

ViseNotes is an AI-driven mobile application that converts audio input (live recording or uploaded files) into:

- Clean transcriptions
- Structured notes
- Key points extraction
- AI-generated quizzes
- Exportable PDF documents
- Categorized note storage

It acts as a full **audio-to-knowledge pipeline**, turning spoken content into usable academic or professional insights.

---

## 🧠 Core Features

### 🎙 Audio Processing
- Upload audio files or record live lectures
- Whisper-based speech-to-text transcription
- Handles long lectures efficiently

### ✍ AI Notes Generation
- Gemini API converts transcript into structured notes
- Generates:
  - Headings
  - Bullet points
  - Summaries
  - Key concepts

### 📄 PDF Export
- Generate downloadable PDFs from notes
- Includes:
  - Key points
  - Structured summaries

### 🧪 Quiz Generation
- AI-generated MCQs and short questions
- Helps in revision and learning reinforcement

### 📚 Smart Organization
- Categorize notes (e.g., CS, Business, Meetings, Lectures)
- Easy retrieval and structured storage

---

## 🏗 System Architecture

```
Flutter Mobile App
        ↓
FastAPI Backend
        ↓
AI Processing Layer
   ├── Whisper (Audio → Transcript)
   ├── Gemini API (Transcript → Notes + Quiz)
        ↓
Storage & Export Layer
   ├── Categorized Notes Storage
   ├── PDF Generator
```

---

## ⚙ Tech Stack

**Frontend**
- Flutter (Android Application)

**Backend**
- FastAPI (Python)

**AI Services**
- Whisper (Speech-to-Text)
- Google Gemini API (Notes + Quiz Generation)

**Utilities**
- PDF generation (reportlab / similar)
- Audio processing tools

---

## 📱 Use Cases

### 🎓 Students
- Convert lectures into structured notes
- Focus on understanding instead of writing notes
- Auto-generate quizzes for revision

### 👨‍🏫 Teachers
- Generate quizzes from lecture content
- Organize teaching materials efficiently

### 🏢 Business Professionals
- Record and summarize meetings
- Maintain structured meeting records

---

## 🔌 API Example

### Generate Notes

```
POST /generate-notes
Content-Type: application/json
```

### Request

```json
{
  "transcript": "Your lecture transcript here..."
}
```

### Response

```json
{
  "notes": "Structured notes...",
  "key_points": ["Point 1", "Point 2"],
  "quiz": [
    {
      "question": "What is ...?",
      "options": ["A", "B", "C", "D"],
      "answer": "B"
    }
  ]
}
```

---

## 📂 Project Structure

```
vise_notes/
│
├── backend/ (FastAPI)
│   ├── main.py
│   ├── routes/
│   ├── services/
│   ├── ai_modules/
│   └── utils/
│
├── frontend/ (Flutter)
│   ├── lib/
│   ├── screens/
│   ├── widgets/
│   └── services/
│
└── README.md
```

---

## 🧪 Running the Project

### Backend (FastAPI)

```
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

Server runs at:

```
http://127.0.0.1:8000
```

---

### Frontend (Flutter)

```
cd frontend
flutter pub get
flutter run
```

---

## 🔮 Future Improvements

- Real-time live transcription mode
- Multi-language support
- Cloud sync across devices
- AI flashcards generation
- Voice-based revision summaries
- Semantic search across notes

---

## 💡 Vision

ViseNotes aims to become a **personal AI learning assistant**, converting every spoken lecture or meeting into structured, searchable knowledge.

The goal is to eliminate manual note-taking and replace it with intelligent, automated learning workflows.

---

## 👨‍💻 Author

Built by 2 Computer Science student focused on AI systems, NLP, and applied machine learning in productivity tools.

---

## 📌 Status

MVP Stage — Local Development (Flutter Emulator + FastAPI Backend)
