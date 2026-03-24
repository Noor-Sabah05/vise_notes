"""
Note Generation Service
Generates structured notes from transcripts using Gemini AI
"""

import json
import google.generativeai as genai
from config import GEMINI_API_KEY, GEMINI_MODEL


class NoteGenerator:
    """Service for AI-powered note generation from transcripts"""
    
    def __init__(self):
        """Initialize Gemini API"""
        genai.configure(api_key=GEMINI_API_KEY)
        self.model = genai.GenerativeModel(GEMINI_MODEL)
        print(f"✓ Note Generator initialized with {GEMINI_MODEL}")
    
    def generate_notes_from_transcript(self, transcript: str, category: str = "General") -> dict:
        """
        Generate structured notes from a transcript using Gemini AI
        
        Args:
            transcript: The transcript text to analyze
            category: Category classification (Mathematics, Physics, etc.)
            
        Returns:
            dict: {
                'title': str,
                'summary': str,
                'content': str  (includes key points)
            }
        """
        try:
            print(f"🤖 Generating notes for {category}...")
            
            # Validate transcript
            if not transcript or len(transcript.strip()) == 0:
                raise ValueError("Transcript cannot be empty")
            
            # Create context-aware prompt based on category
            category_context = self._get_category_context(category)
            
            # Create prompt
            prompt = f"""You are an expert academic note-taker specializing in {category}.

Analyze the following transcript and generate comprehensive, well-structured academic notes.

{category_context}

Transcript:
{transcript}

Please provide the response as VALID JSON (no markdown code blocks) with these exact fields:
{{
    "title": "A concise, specific title reflecting the main topic",
    "summary": "A brief 2-3 sentence overview suitable for quick reference",
    "content": "Detailed, well-organized notes with proper formatting and structure",
    "key_points": "Important facts, concepts, and takeaways as bullet points"
}}

IMPORTANT:
1. Return ONLY valid JSON, no markdown blocks
2. Ensure all quotes inside strings are properly escaped
3. Keep content clear, organized, and academically sound
4. Include practical examples where applicable
5. Make the notes suitable for studying and revision"""

            # Call Gemini API
            print(f"  Calling Gemini API...")
            response = self.model.generate_content(prompt)
            
            # Extract and clean response
            response_text = response.text.strip()
            response_text = self._clean_json_response(response_text)
            
            # Parse JSON
            try:
                data = json.loads(response_text)
            except json.JSONDecodeError as e:
                print(f"⚠ JSON parse error: {e}")
                # Try to extract JSON manually
                start = response_text.find('{')
                end = response_text.rfind('}') + 1
                if start != -1 and end > start:
                    data = json.loads(response_text[start:end])
                else:
                    raise ValueError("Could not extract valid JSON from AI response")
            
            # Merge content with key points
            merged_content = data.get('content', '')
            key_points = data.get('key_points', '')
            
            if key_points:
                merged_content += f"\n\n📌 Key Points:\n{key_points}"
            
            result = {
                "title": data.get('title', 'Untitled Note'),
                "summary": data.get('summary', ''),
                "content": merged_content,
            }
            
            print(f"✓ Notes generated successfully")
            return result
        
        except Exception as e:
            print(f"✗ Error generating notes: {str(e)}")
            raise Exception(f"Note Generation Error: {str(e)}")
    
    def _get_category_context(self, category: str) -> str:
        """Get category-specific context for better note generation"""
        contexts = {
            "Mathematics": "Focus on problem-solving approaches, formulas, and mathematical logic.",
            "Physics": "Include relevant equations, physical principles, and real-world applications.",
            "Chemistry": "Focus on chemical reactions, molecular structures, and practical applications.",
            "Biology": "Include biological processes, classification, and life systems.",
            "History": "Focus on historical events, dates, causes, and significance.",
            "Literature": "Analyze themes, characters, writing style, and literary techniques.",
            "Programming": "Include code concepts, algorithms, and best practices.",
            "General": "Create comprehensive, well-structured notes suitable for general studying."
        }
        return contexts.get(category, contexts["General"])
    
    def _clean_json_response(self, text: str) -> str:
        """Clean JSON response from markdown formatting"""
        # Remove markdown code blocks
        if text.startswith('```json'):
            text = text[7:]
        if text.startswith('```'):
            text = text[3:]
        if text.endswith('```'):
            text = text[:-3]
        
        return text.strip()


# Global instance
note_generator = NoteGenerator()
