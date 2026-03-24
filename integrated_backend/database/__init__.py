"""
ViseNotes Integrated Backend Database
"""

from .integrated_db import (
    db_connection,
    DatabaseConnection,
    insert_recording_with_notes,
    update_recording_status,
    get_recording_by_file_id,
    get_all_recordings,
    get_recordings_by_category,
    delete_recording,
    init_db
)

__all__ = [
    'db_connection',
    'DatabaseConnection',
    'insert_recording_with_notes',
    'update_recording_status',
    'get_recording_by_file_id',
    'get_all_recordings',
    'get_recordings_by_category',
    'delete_recording',
    'init_db'
]
