import json
from google import genai
from google.genai import types


class NotesService:
    def __init__(self, api_key: str):
        self.client = genai.Client(api_key=api_key)

    def generate_notes(self, transcript: str):
        prompt = f"""
        You are an expert academic note-taker.

        Convert the following transcript into HIGH-QUALITY structured notes.

        REQUIREMENTS:
        - Use clear headings and subheadings
        - Use bullet points where appropriate
        - Expand concepts
        - Add explanations for important ideas
        - Make it suitable for exam revision

        IMPORTANT RULES:
        - Return ONLY valid JSON
        - No markdown, no backticks
        - Escape newlines using \\n

        Transcript:
        {transcript}

        JSON FORMAT:
        {{
          "title": "Clear topic title",
          "summary": "Well-written paragraph summary",
          "content": "Detailed structured notes with structure",
          "key_points": "Important bullet points"
        }}
        """

        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json"
            ),
        )

        # -------------------------
        # SAFE PARSING
        # -------------------------
        data = response.parsed

        if not data:
            raw_text = response.text.strip()

            # remove markdown if exists
            if raw_text.startswith("```"):
                parts = raw_text.split("```")
                if len(parts) >= 2:
                    raw_text = parts[1]

            try:
                data = json.loads(raw_text)
            except Exception:
                print("⚠️ RAW GEMINI RESPONSE:\n", raw_text)

                return {
                    "title": "Notes",
                    "summary": "Failed to generate structured summary.",
                    "content": raw_text,
                    "key_points": ""
                }

        return {
            "title": data.get("title", "Notes"),
            "summary": data.get("summary", ""),
            "content": data.get("content", ""),
            "key_points": data.get("key_points", ""),
        }