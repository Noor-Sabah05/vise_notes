from datetime import datetime
from database.connection import db_connection

class DBService:
    """Service for database operations"""
    
    @staticmethod
    def insert_note(title: str, summary: str, content: str, category: str, pdf_path: str, date: str = None) -> int:
        """
        Insert a new note into the database
        
        Args:
            title: Note title
            summary: Note summary
            content: Full note content
            category: Note category
            pdf_path: Path to PDF file
            date: Note date (optional, defaults to today)
            
        Returns:
            int: ID of inserted note
        """
        try:
            if date is None:
                date = datetime.now().strftime('%Y-%m-%d')
            
            conn = db_connection.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO notes (title, summary, content, category, pdf_path, date, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                title,
                summary,
                content,
                category,
                pdf_path,
                date,
                datetime.now().isoformat(),
                datetime.now().isoformat()
            ))
            
            conn.commit()
            note_id = cursor.lastrowid
            conn.close()
            
            return note_id
        
        except Exception as e:
            raise Exception(f"Database Insert Error: {str(e)}")
    
    @staticmethod
    def get_notes(category: str = None, limit: int = 50, offset: int = 0) -> list:
        """
        Get all notes with optional filtering
        
        Args:
            category: Filter by category (optional)
            limit: Maximum number of results
            offset: Number of results to skip
            
        Returns:
            list: List of note dictionaries
        """
        try:
            conn = db_connection.get_connection()
            cursor = conn.cursor()
            
            if category:
                cursor.execute('''
                    SELECT id, title, summary, category, date, created_at
                    FROM notes
                    WHERE category = ?
                    ORDER BY date DESC
                    LIMIT ? OFFSET ?
                ''', (category, limit, offset))
            else:
                cursor.execute('''
                    SELECT id, title, summary, category, date, created_at
                    FROM notes
                    ORDER BY date DESC
                    LIMIT ? OFFSET ?
                ''', (limit, offset))
            
            rows = cursor.fetchall()
            conn.close()
            
            return [dict(row) for row in rows]
        
        except Exception as e:
            raise Exception(f"Database Query Error: {str(e)}")
    
    @staticmethod
    def get_note_by_id(note_id: int) -> dict:
        """
        Get a single note by ID
        
        Args:
            note_id: Note ID
            
        Returns:
            dict: Note data or None
        """
        try:
            conn = db_connection.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT id, title, summary, content, category, pdf_path, date, created_at
                FROM notes
                WHERE id = ?
            ''', (note_id,))
            
            row = cursor.fetchone()
            conn.close()
            
            return dict(row) if row else None
        
        except Exception as e:
            raise Exception(f"Database Query Error: {str(e)}")
    
    @staticmethod
    def delete_note(note_id: int) -> bool:
        """
        Delete a note by ID
        
        Args:
            note_id: Note ID
            
        Returns:
            bool: True if successful
        """
        try:
            conn = db_connection.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('DELETE FROM notes WHERE id = ?', (note_id,))
            
            conn.commit()
            conn.close()
            
            return True
        
        except Exception as e:
            raise Exception(f"Database Delete Error: {str(e)}")
    
    @staticmethod
    def get_notes_count(category: str = None) -> int:
        """
        Get count of notes
        
        Args:
            category: Filter by category (optional)
            
        Returns:
            int: Number of notes
        """
        try:
            conn = db_connection.get_connection()
            cursor = conn.cursor()
            
            if category:
                cursor.execute('SELECT COUNT(*) as count FROM notes WHERE category = ?', (category,))
            else:
                cursor.execute('SELECT COUNT(*) as count FROM notes')
            
            result = cursor.fetchone()
            conn.close()
            
            return result['count'] if result else 0
        
        except Exception as e:
            raise Exception(f"Database Count Error: {str(e)}")
