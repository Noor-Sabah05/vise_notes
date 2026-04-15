from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors


def generate_quiz_pdf(file_path: str, quiz_text: str):
    doc = SimpleDocTemplate(file_path, rightMargin=36, leftMargin=36)

    styles = getSampleStyleSheet()

    # ========================
    # STYLES
    # ========================
    title_style = ParagraphStyle(
        "title",
        parent=styles["Title"],
        fontSize=22,
        textColor=colors.HexColor("#111827"),
        spaceAfter=12
    )

    section_style = ParagraphStyle(
        "section",
        parent=styles["Heading2"],
        fontSize=14,
        textColor=colors.HexColor("#2563eb"),
        spaceBefore=12,
        spaceAfter=8
    )

    question_style = ParagraphStyle(
        "question",
        parent=styles["BodyText"],
        fontSize=12,
        leading=16,
        spaceAfter=6,
        textColor=colors.black
    )

    option_style = ParagraphStyle(
        "option",
        parent=styles["BodyText"],
        fontSize=11,
        leftIndent=16,
        spaceAfter=4,
    )

    answer_style = ParagraphStyle(
        "answer",
        parent=styles["BodyText"],
        fontSize=10,
        textColor=colors.HexColor("#16a34a"),
        spaceAfter=10
    )

    story = []

    # ========================
    # TITLE
    # ========================
    story.append(Paragraph("Quiz Assessment", title_style))
    story.append(Spacer(1, 10))

    lines = quiz_text.split("\n")

    current_section = None

    # ========================
    # PARSING LOGIC
    # ========================
    for line in lines:
        line = line.strip()

        if not line:
            continue

        # Section Headers
        if "MCQS" in line.upper():
            story.append(Paragraph("Section A: Multiple Choice Questions", section_style))
            continue

        elif "SHORT" in line.upper():
            story.append(Paragraph("Section B: Short Questions", section_style))
            continue

        elif "LONG" in line.upper():
            story.append(Paragraph("Section C: Long Question", section_style))
            continue

        # Questions
        elif line[0].isdigit():
            story.append(Paragraph(f"<b>{line}</b>", question_style))

        # Options
        elif line.startswith(("A.", "B.", "C.", "D.")):
            story.append(Paragraph(line, option_style))

        # Answers (styled nicely)
        elif line.lower().startswith("answer"):
            answer_box = Table([[Paragraph(line, answer_style)]], colWidths=[450])
            answer_box.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#ECFDF5")),
                ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#22c55e")),
                ("INNERPADDING", (0, 0), (-1, -1), 6),
            ]))
            story.append(answer_box)
            story.append(Spacer(1, 6))

        else:
            story.append(Paragraph(line, question_style))

    doc.build(story)