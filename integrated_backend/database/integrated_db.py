"""
Integrated Database Module
Combines audio transcripts and generated notes in a unified schema
"""

import sqlite3
from pathlib import Path
import os
from datetime import datetime
from config import DATABASE_PATH


class DatabaseConnection:
    """Initialize and manage the unified database"""
    
    def __init__(self, db_path=DATABASE_PATH):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._init_db()
    
    def _init_db(self):
        """Initialize database with unified schema"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create unified recordings_with_notes table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS recordings_with_notes(
                id                  INTEGER PRIMARY KEY AUTOINCREMENT,
                file_id             TEXT UNIQUE NOT NULL,
                filename            TEXT NOT NULL,
                original_filename   TEXT,
                
                -- Audio Processing
                language            TEXT,
                duration_seconds    REAL,
                cleaned_audio_path  TEXT,
                
                -- Transcription
                transcript          TEXT,
                
                -- Note Generation
                note_title          TEXT,
                note_summary        TEXT,
                note_content        TEXT,
                category            TEXT DEFAULT 'General',
                pdf_path            TEXT,
                
                -- Timestamps
                created_at          TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at          TEXT DEFAULT CURRENT_TIMESTAMP,
                
                -- Status tracking
                status              TEXT DEFAULT 'processing',  -- 'processing', 'completed', 'failed'
                error_message       TEXT
            )
        ''')
        
        # Create indexes for faster queries
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_file_id ON recordings_with_notes(file_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_category ON recordings_with_notes(category)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON recordings_with_notes(created_at DESC)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_status ON recordings_with_notes(status)')
        
        # Create legacy compatibility tables for migration if needed
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS transcripts_legacy(
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                file_id     TEXT NOT NULL,
                filename    TEXT,
                language    TEXT,
                duration    REAL,
                transcript  TEXT,
                created_at  TEXT DEFAULT (datetime('now'))
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS notes_legacy(
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                file_id     TEXT,
                title       TEXT NOT NULL,
                summary     TEXT,
                content     TEXT,
                category    TEXT,
                pdf_path    TEXT,
                date        TEXT,
                created_at  TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at  TEXT DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        print(f"✓ Database initialized: {self.db_path}")
    
    def get_connection(self):
        """Get database connection with row factory"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Return rows as dictionaries
        return conn


# Global database instance
db_connection = DatabaseConnection()


# ===================== DATABASE OPERATIONS =====================

def insert_recording_with_notes(
    file_id: str,
    filename: str,
    original_filename: str = None,
    language: str = None,
    duration_seconds: float = None,
    cleaned_audio_path: str = None,
    transcript: str = None,
    note_title: str = None,
    note_summary: str = None,
    note_content: str = None,
    category: str = 'General',
    pdf_path: str = None,
    status: str = 'processing',
    error_message: str = None
) -> int:
    """
    Insert a complete record with audio, transcript, and notes
    
    Returns:
        int: ID of inserted record
    """
    try:
        conn = db_connection.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO recordings_with_notes (
                file_id, filename, original_filename,
                language, duration_seconds, cleaned_audio_path,
                transcript, note_title, note_summary, note_content,
                category, pdf_path, status, error_message, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            file_id, filename, original_filename,
            language, duration_seconds, cleaned_audio_path,
            transcript, note_title, note_summary, note_content,
            category, pdf_path, status, error_message,
            datetime.now().isoformat(), datetime.now().isoformat()
        ))
        
        conn.commit()
        record_id = cursor.lastrowid
        conn.close()
        
        return record_id
    
    except sqlite3.IntegrityError as e:
        raise Exception(f"Database Integrity Error (file_id may already exist): {str(e)}")
    except Exception as e:
        raise Exception(f"Database Insert Error: {str(e)}")


def update_recording_status(
    file_id: str,
    status: str,
    transcript: str = None,
    note_title: str = None,
    note_summary: str = None,
    note_content: str = None,
    pdf_path: str = None,
    error_message: str = None
) -> bool:
    """Update recording status and optionally add transcript/notes"""
    try:
        conn = db_connection.get_connection()
        cursor = conn.cursor()
        
        update_fields = ['status = ?', 'updated_at = ?']
        params = [status, datetime.now().isoformat()]
        
        if transcript is not None:
            update_fields.append('transcript = ?')
            params.append(transcript)
        if note_title is not None:
            update_fields.append('note_title = ?')
            params.append(note_title)
        if note_summary is not None:
            update_fields.append('note_summary = ?')
            params.append(note_summary)
        if note_content is not None:
            update_fields.append('note_content = ?')
            params.append(note_content)
        if pdf_path is not None:
            update_fields.append('pdf_path = ?')
            params.append(pdf_path)
        if error_message is not None:
            update_fields.append('error_message = ?')
            params.append(error_message)
        
        params.append(file_id)
        
        query = f"UPDATE recordings_with_notes SET {', '.join(update_fields)} WHERE file_id = ?"
        cursor.execute(query, params)
        
        conn.commit()
        conn.close()
        
        return cursor.rowcount > 0
    
    except Exception as e:
        raise Exception(f"Database Update Error: {str(e)}")


def get_recording_by_file_id(file_id: str) -> dict:
    """Fetch a complete recording with all details"""
    try:
        conn = db_connection.get_connection()
        row = conn.execute(
            "SELECT * FROM recordings_with_notes WHERE file_id = ?",
            (file_id,)
        ).fetchone()
        conn.close()
        
        return dict(row) if row else None
    
    except Exception as e:
        raise Exception(f"Database Query Error: {str(e)}")


def get_all_recordings(limit: int = 50, offset: int = 0) -> dict:
    """Fetch all recordings with pagination"""
    try:
        conn = db_connection.get_connection()
        
        # Get total count
        total = conn.execute(
            "SELECT COUNT(*) as count FROM recordings_with_notes"
        ).fetchone()['count']
        
        # Get records
        rows = conn.execute(
            """
            SELECT id, file_id, filename, original_filename, language, 
                   duration_seconds, note_title, note_summary, category, 
                   status, created_at
            FROM recordings_with_notes
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
            """,
            (limit, offset)
        ).fetchall()
        
        conn.close()
        
        return {
            'recordings': [dict(row) for row in rows],
            'total': total,
            'limit': limit,
            'offset': offset
        }
    
    except Exception as e:
        raise Exception(f"Database Query Error: {str(e)}")


def get_recordings_by_category(category: str, limit: int = 50, offset: int = 0) -> dict:
    """Fetch recordings filtered by category"""
    try:
        conn = db_connection.get_connection()
        
        # Get total count
        total = conn.execute(
            "SELECT COUNT(*) as count FROM recordings_with_notes WHERE category = ?",
            (category,)
        ).fetchone()['count']
        
        # Get records
        rows = conn.execute(
            """
            SELECT id, file_id, filename, original_filename, language, 
                   duration_seconds, note_title, note_summary, category, 
                   status, created_at
            FROM recordings_with_notes
            WHERE category = ?
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
            """,
            (category, limit, offset)
        ).fetchall()
        
        conn.close()
        
        return {
            'recordings': [dict(row) for row in rows],
            'total': total,
            'limit': limit,
            'offset': offset
        }
    
    except Exception as e:
        raise Exception(f"Database Query Error: {str(e)}")


def delete_recording(file_id: str) -> bool:
    """Delete a recording and related files"""
    try:
        conn = db_connection.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM recordings_with_notes WHERE file_id = ?", (file_id,))
        conn.commit()
        conn.close()
        
        return cursor.rowcount > 0
    
    except Exception as e:
        raise Exception(f"Database Delete Error: {str(e)}")


def init_db():
    """Initialize database (called at startup)"""
    global db_connection
    if db_connection is None:
        db_connection = DatabaseConnection()
    print("✓ Database ready")
