"""
PDF Generation Service
Generates PDF documents from notes
"""

import os
from datetime import datetime
from pathlib import Path
import uuid

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib import colors

from config import UPLOADS_DIR


class PDFGenerator:
    """Service for generating professional PDF documents from notes"""
    
    @staticmethod
    def create_note_pdf(title: str, content: str, metadata: dict = None) -> str:
        """
        Create a professional PDF document from notes
        
        Args:
            title: Title of the document
            content: Body content of the document
            metadata: Optional dict with 'author', 'category', 'created_at'
            
        Returns:
            str: Path to created PDF file
        """
        try:
            print(f"📄 Generating PDF: {title}...")
            
            # Generate safe filename
            safe_title = title.replace(' ', '_').replace('/', '_').replace('\\', '_')
            safe_title = ''.join(c for c in safe_title if c.isalnum() or c in '_-')
            
            # Create filename with UUID and timestamp
            file_id = str(uuid.uuid4())[:8]
            timestamp = int(datetime.now().timestamp() * 1000)
            filename = f"{safe_title}_{file_id}_{timestamp}.pdf"
            filepath = os.path.join(UPLOADS_DIR, filename)
            
            # Create PDF document
            doc = SimpleDocTemplate(
                filepath,
                pagesize=letter,
                rightMargin=0.75*inch,
                leftMargin=0.75*inch,
                topMargin=0.75*inch,
                bottomMargin=0.75*inch,
                title=title
            )
            
            # Create custom styles
            styles = getSampleStyleSheet()
            
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=26,
                textColor=colors.HexColor('#1f2937'),
                spaceAfter=0.3*inch,
                fontName='Helvetica-Bold',
                alignment=TA_CENTER
            )
            
            subtitle_style = ParagraphStyle(
                'CustomSubtitle',
                parent=styles['Heading3'],
                fontSize=12,
                textColor=colors.HexColor('#6b7280'),
                spaceAfter=0.2*inch,
                fontName='Helvetica-Oblique',
                alignment=TA_CENTER
            )
            
            body_style = ParagraphStyle(
                'CustomBody',
                parent=styles['BodyText'],
                fontSize=11,
                leading=14,
                alignment=TA_LEFT,
                spaceAfter=0.1*inch,
                textColor=colors.HexColor('#111827')
            )
            
            bullet_style = ParagraphStyle(
                'CustomBullet',
                parent=styles['BodyText'],
                fontSize=10,
                leading=13,
                leftIndent=0.25*inch,
                spaceAfter=0.05*inch,
                textColor=colors.HexColor('#374151')
            )
            
            section_style = ParagraphStyle(
                'CustomSection',
                parent=styles['Heading2'],
                fontSize=14,
                textColor=colors.HexColor('#1f2937'),
                spaceAfter=0.15*inch,
                spaceBefore=0.2*inch,
                fontName='Helvetica-Bold'
            )
            
            # Build document story
            story = []
            
            # Add title
            story.append(Paragraph(title, title_style))
            
            # Add metadata if provided
            if metadata:
                metadata_text = []
                if metadata.get('category'):
                    metadata_text.append(f"Category: {metadata['category']}")
                if metadata.get('created_at'):
                    created_date = datetime.fromisoformat(metadata['created_at']).strftime('%B %d, %Y')
                    metadata_text.append(f"Date: {created_date}")
                if metadata_text:
                    story.append(Paragraph(' | '.join(metadata_text), subtitle_style))
            
            # Add divider line
            story.append(Spacer(1, 0.15*inch))
            
            # Parse and add content
            sections = content.split('\n\n')
            for section in sections:
                if not section.strip():
                    continue
                
                section_text = section.strip()
                
                # Check if it's a section header (contains emoji or all caps)
                if any(emoji in section_text for emoji in ['📌', '🔑', '📍', '⚡', '✓', '•']) or \
                   (section_text.startswith(('Key Points:', 'Summary:', 'Overview:', 'Important:')) and 
                    section_text.isupper() is False):
                    # It's a header or special section
                    if '📌' in section_text or section_text.startswith('Key Points:'):
                        story.append(Paragraph('Key Points', section_style))
                    elif '🔑' in section_text or section_text.startswith('Summary:'):
                        story.append(Paragraph('Summary', section_style))
                    else:
                        # Extract header text
                        header = section_text.replace('📌', '').replace('🔑', '').replace('✓', '').strip()
                        if header and not header.startswith('•'):
                            story.append(Paragraph(header, section_style))
                    
                    # Add remaining content
                    remaining = section_text.replace('📌', '').replace('🔑', '').replace('✓', '')
                    remaining_lines = remaining.split('\n')
                    
                    for line in remaining_lines:
                        line = line.strip()
                        if line:
                            if line.startswith('•') or line.startswith('-'):
                                clean_line = line.lstrip('•-').strip()
                                story.append(Paragraph(f"• {clean_line}", bullet_style))
                            else:
                                story.append(Paragraph(line, body_style))
                
                # Regular paragraph
                elif section_text.startswith('•') or section_text.startswith('-'):
                    # Bullet points
                    lines = section_text.split('\n')
                    for line in lines:
                        line = line.strip()
                        if line:
                            clean_line = line.lstrip('•-').strip()
                            story.append(Paragraph(f"• {clean_line}", bullet_style))
                
                else:
                    # Regular body text
                    story.append(Paragraph(section_text, body_style))
                
                story.append(Spacer(1, 0.05*inch))
            
            # Add footer with generation info
            story.append(Spacer(1, 0.3*inch))
            footer_text = f"Generated by ViseNotes on {datetime.now().strftime('%B %d, %Y at %I:%M %p')}"
            story.append(Paragraph(footer_text, ParagraphStyle(
                'Footer',
                parent=styles['Normal'],
                fontSize=9,
                textColor=colors.HexColor('#9ca3af'),
                alignment=TA_CENTER
            )))
            
            # Build PDF
            doc.build(story)
            
            print(f"✓ PDF created: {filepath}")
            return filepath
        
        except Exception as e:
            print(f"✗ Error generating PDF: {str(e)}")
            raise Exception(f"PDF Generation Error: {str(e)}")
    
    @staticmethod
    def delete_pdf(filepath: str) -> bool:
        """Delete a PDF file"""
        try:
            path = Path(filepath)
            if path.exists():
                path.unlink()
                print(f"✓ Deleted PDF: {filepath}")
                return True
            return False
        except Exception as e:
            print(f"⚠ Warning: Could not delete PDF: {str(e)}")
            return False


# Global instance
pdf_generator = PDFGenerator()
