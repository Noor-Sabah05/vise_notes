from pydantic import BaseModel

# ─────────────────────────────────────────────────────────────
# MODELS
# ─────────────────────────────────────────────────────────────
class NotesRequest(BaseModel):
    transcript: str
