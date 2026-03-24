import sqlite3
from pathlib import Path
from datetime import datetime

DB_PATH = Path("transcripts.db")


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # lets us access columns by name
    return conn


def init_db():
    """Create tables if they don't exist. Called once at app startup."""
    conn = get_connection()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS transcripts (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id     TEXT NOT NULL,
            filename    TEXT,
            language    TEXT,
            duration    REAL,
            transcript  TEXT,
            created_at  TEXT DEFAULT (datetime('now'))
        )
    """
    )
    conn.commit()
    conn.close()
    print("Database ready.")


def save_transcript(file_id, filename, language, duration, transcript):
    """Insert a new transcript record."""
    conn = get_connection()
    conn.execute(
        """
        INSERT INTO transcripts (file_id, filename, language, duration, transcript, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """,
        (file_id, filename, language, duration, transcript, datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()


def get_all_transcripts():
    """Fetch all saved transcripts, newest first."""
    conn = get_connection()
    rows = conn.execute(
        """
        SELECT id, file_id, filename, language, duration, transcript, created_at
        FROM transcripts
        ORDER BY created_at DESC
    """
    ).fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_transcript_by_id(transcript_id: int):
    """Fetch a single transcript by its id."""
    conn = get_connection()
    row = conn.execute(
        """
        SELECT * FROM transcripts WHERE id = ?
    """,
        (transcript_id,),
    ).fetchone()
    conn.close()
    return dict(row) if row else None
