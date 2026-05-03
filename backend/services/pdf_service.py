from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.units import inch


def generate_pdf(file_path: str, title: str, summary: str, content: str, key_points: str = ""):
    doc = SimpleDocTemplate(
        file_path,
        rightMargin=36,
        leftMargin=36,
        topMargin=40,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # ========================
    # STYLES (DESIGN SYSTEM)
    # ========================

    title_style = ParagraphStyle(
        "title",
        parent=styles["Title"],
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#111827"),
        spaceAfter=14
    )

    section_style = ParagraphStyle(
        "section",
        parent=styles["Heading2"],
        fontSize=18,
        leading=22,
        textColor=colors.HexColor("#111827"),
        spaceBefore=16,
        spaceAfter=12,
        fontName="Helvetica-Bold",
    )

    section_header_style = ParagraphStyle(
        "section_header",
        parent=styles["Heading2"],
        fontSize=16,
        leading=20,
        textColor=colors.white,
        fontName="Helvetica-Bold",
        alignment=0,
    )

    normal_style = ParagraphStyle(
        "normal",
        parent=styles["BodyText"],
        fontSize=12,
        leading=18,
        textColor=colors.HexColor("#374151"),
    )

    meta_style = ParagraphStyle(
        "meta",
        parent=styles["BodyText"],
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#6B7280"),
        spaceAfter=14,
    )

    bullet_style = ParagraphStyle(
        "bullet",
        parent=styles["BodyText"],
        fontSize=12,
        leading=18,
        leftIndent=14,
        bulletIndent=8,
        textColor=colors.HexColor("#374151"),
    )

    # ========================
    # BUILD PDF
    # ========================
    story = []

    # Title
    story.append(Paragraph(title, title_style))
    story.append(Paragraph("AI-generated study notes", meta_style))
    story.append(Spacer(1, 10))

    # ========================
    # SUMMARY CARD (DESIGN)
    # ========================
    summary_table = Table(
        [
            [Paragraph("SUMMARY", section_header_style)],
            [Paragraph(summary, normal_style)],
        ],
        colWidths=[500],
    )

    summary_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, 0), colors.HexColor("#7C3AED")),
        ("TEXTCOLOR", (0, 0), (0, 0), colors.white),
        ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#EFF6FF")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#A78BFA")),
        ("INNERPADDING", (0, 0), (-1, -1), 14),
        ("LEFTPADDING", (0, 0), (-1, -1), 16),
        ("RIGHTPADDING", (0, 0), (-1, -1), 16),
        ("TOPPADDING", (0, 0), (-1, -1), 14),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 14),
    ]))

    story.append(summary_table)
    story.append(Spacer(1, 18))

    # ========================
    # KEY POINTS BOX
    # ========================
    if key_points:
        bullets = [item.strip() for item in key_points.replace("•", "-").split("\n") if item.strip()]
        bullet_rows = [[Paragraph("KEY POINTS", section_header_style)]]
        for item in bullets:
            text = item.lstrip("-*").strip()
            if text:
                bullet_rows.append([Paragraph(f"• {text}", bullet_style)])

        kp_table = Table(bullet_rows, colWidths=[500], splitByRow=1)
        kp_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (0, 0), colors.HexColor("#059669")),
            ("TEXTCOLOR", (0, 0), (0, 0), colors.white),
            ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#ECFDF5")),
            ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#34D399")),
            ("INNERPADDING", (0, 0), (-1, -1), 12),
            ("LEFTPADDING", (0, 0), (-1, -1), 16),
            ("RIGHTPADDING", (0, 0), (-1, -1), 16),
            ("TOPPADDING", (0, 0), (-1, -1), 12),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
        ]))

        story.append(kp_table)
        story.append(Spacer(1, 16))

    # ========================
    # CONTENT SECTION
    # ========================
    raw_lines = [line.rstrip() for line in content.split("\n")]
    content_rows = [[Paragraph("DETAILED NOTES", section_header_style)]]
    paragraph_buffer = []

    def flush_paragraph():
        nonlocal paragraph_buffer
        if paragraph_buffer:
            content_rows.append([Paragraph(" ".join(paragraph_buffer), normal_style)])
            paragraph_buffer = []

    for line in raw_lines:
        stripped_line = line.strip()
        if not stripped_line:
            flush_paragraph()
            continue

        if stripped_line.startswith("- ") or stripped_line.startswith("* "):
            flush_paragraph()
            content_rows.append([Paragraph(f"• {stripped_line[2:].strip()}", bullet_style)])
        else:
            paragraph_buffer.append(stripped_line)

    flush_paragraph()

    if len(content_rows) == 1:
        content_rows.append([Paragraph("No detailed notes available.", normal_style)])

    content_table = Table(content_rows, colWidths=[500], splitByRow=1)
    content_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, 0), colors.HexColor("#F59E0B")),
        ("TEXTCOLOR", (0, 0), (0, 0), colors.white),
        ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#FEF3C7")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#F59E0B")),
        ("INNERPADDING", (0, 0), (-1, -1), 14),
        ("LEFTPADDING", (0, 0), (-1, -1), 16),
        ("RIGHTPADDING", (0, 0), (-1, -1), 16),
        ("TOPPADDING", (0, 0), (-1, -1), 14),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 14),
    ]))

    story.append(content_table)

    doc.build(story)

    return file_path