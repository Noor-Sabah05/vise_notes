from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib import colors
import os
from datetime import datetime
from config import UPLOADS_DIR

class PDFService:
    """Service for PDF document generation"""
    
    @staticmethod
    def create_pdf(title: str, content: str) -> str:
        """
        Create a PDF document with the given title and content
        
        Args:
            title: Title of the document
            content: Body content of the document
            
        Returns:
            str: Path to the created PDF file
        """
        try:
            # Generate safe filename
            safe_title = title.replace(' ', '_').replace('/', '_').replace('\\', '_')
            safe_title = ''.join(c for c in safe_title if c.isalnum() or c in '_-')
            
            # Create filename with timestamp
            timestamp = int(datetime.now().timestamp() * 1000)
            filename = f"{safe_title}_{timestamp}.pdf"
            filepath = os.path.join(UPLOADS_DIR, filename)
            
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=letter,
                rightMargin=0.75*inch,
                leftMargin=0.75*inch,
                topMargin=0.75*inch,
                bottomMargin=0.75*inch,
            )
            
            # Create styles
            styles = getSampleStyleSheet()
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=26,
                textColor=colors.HexColor('#000000'),
                spaceAfter=0.2*inch,
                fontName='Helvetica-Bold'
            )
            
            body_style = ParagraphStyle(
                'CustomBody',
                parent=styles['BodyText'],
                fontSize=11,
                leading=14,
                alignment=TA_LEFT,
                spaceAfter=0.1*inch,
            )
            
            # Build document content
            story = []
            
            # Title
            story.append(Paragraph(title, title_style))
            
            # Divider line
            story.append(Spacer(1, 0.1*inch))
            
            # Content - split by paragraphs
            paragraphs = content.split('\n\n')
            for para in paragraphs:
                if para.strip():
                    # Handle bullet points
                    if para.startswith('•') or para.startswith('-'):
                        lines = para.split('\n')
                        for line in lines:
                            if line.strip():
                                story.append(Paragraph(f"• {line.strip().lstrip('•-').strip()}", body_style))
                    else:
                        story.append(Paragraph(para.strip(), body_style))
                    story.append(Spacer(1, 0.05*inch))
            
            # Build PDF
            doc.build(story)
            
            return filepath
        
        except Exception as e:
            raise Exception(f"PDF Generation Error: {str(e)}")
    
    @staticmethod
    def delete_pdf(filepath: str) -> bool:
        """
        Delete a PDF file
        
        Args:
            filepath: Path to the PDF file
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            if os.path.exists(filepath):
                os.remove(filepath)
                return True
            return False
        except Exception as e:
            raise Exception(f"PDF Deletion Error: {str(e)}")
