import json
import google.generativeai as genai
from config import GEMINI_API_KEY, GEMINI_MODEL

class AIService:
    """Service for AI-powered note generation using Gemini API"""
    
    def __init__(self):
        genai.configure(api_key=GEMINI_API_KEY)
        self.model = genai.GenerativeModel(GEMINI_MODEL)
    
    def generate_notes_from_transcript(self, transcript: str) -> dict:
        """
        Generate structured notes from a transcript using Gemini AI
        
        Args:
            transcript: The text transcript to analyze
            
        Returns:
            dict with keys: title, summary, content, key_points
        """
        try:
            # Create prompt for AI
            prompt = f"""Analyze the following transcript and provide academic notes in JSON format.
            
Transcript:
{transcript}

Please provide the response as valid JSON with these fields:
{{
    "title": "A concise title for this lecture/content",
    "summary": "A brief 2-3 sentence overview",
    "content": "Detailed notes with proper formatting",
    "key_points": "Bullet points of important facts and concepts"
}}

Ensure the JSON is valid and can be parsed. Do not include markdown code blocks."""

            # Call Gemini API
            response = self.model.generate_content(prompt)
            
            # Extract and clean the response
            response_text = response.text.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith('```json'):
                response_text = response_text[7:]
            if response_text.startswith('```'):
                response_text = response_text[3:]
            if response_text.endswith('```'):
                response_text = response_text[:-3]
            
            response_text = response_text.strip()
            
            # Parse JSON
            try:
                data = json.loads(response_text)
            except json.JSONDecodeError:
                # If parsing fails, try to extract JSON manually
                start = response_text.find('{')
                end = response_text.rfind('}') + 1
                if start != -1 and end > start:
                    data = json.loads(response_text[start:end])
                else:
                    raise ValueError("Could not extract valid JSON from AI response")
            
            # Merge content and key_points
            merged_content = data.get('content', '')
            key_points = data.get('key_points', '')
            
            if key_points:
                merged_content += f"\n\nKey Points:\n{key_points}"
            
            return {
                "title": data.get('title', 'Untitled Note'),
                "summary": data.get('summary', ''),
                "content": merged_content,
            }
        
        except Exception as e:
            raise Exception(f"AI Service Error: {str(e)}")
    
    def generate_notes_from_audio(self, audio_bytes: bytes, audio_mimetype: str = 'audio/mpeg') -> dict:
        """
        Generate notes directly from audio file (requires Gemini multimodal)
        
        Args:
            audio_bytes: Raw audio file bytes
            audio_mimetype: MIME type of audio (e.g., 'audio/mpeg')
            
        Returns:
            dict with keys: title, summary, content
        """
        try:
            from google.generative_ai import generative_ai
            
            # Create content with audio
            prompt_text = """Analyze this audio and provide academic notes in JSON format.

Please provide the response as valid JSON with these fields:
{
    "title": "A concise title for this lecture",
    "summary": "A brief 2-3 sentence overview",
    "content": "Detailed notes",
    "key_points": "Important facts"
}"""
            
            # Generate content with multimodal input
            response = self.model.generate_content([
                generative_ai.types.content_types.DataPart(
                    mime_type=audio_mimetype,
                    data=audio_bytes
                ),
                prompt_text
            ])
            
            response_text = response.text.strip()
            
            # Clean and parse response
            if response_text.startswith('```json'):
                response_text = response_text[7:]
            if response_text.startswith('```'):
                response_text = response_text[3:]
            if response_text.endswith('```'):
                response_text = response_text[:-3]
            
            response_text = response_text.strip()
            data = json.loads(response_text)
            
            merged_content = data.get('content', '')
            key_points = data.get('key_points', '')
            
            if key_points:
                merged_content += f"\n\nKey Points:\n{key_points}"
            
            return {
                "title": data.get('title', 'Untitled Note'),
                "summary": data.get('summary', ''),
                "content": merged_content,
            }
        
        except Exception as e:
            raise Exception(f"AI Service (Audio) Error: {str(e)}")
