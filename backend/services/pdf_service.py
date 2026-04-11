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
        fontSize=14,
        leading=18,
        textColor=colors.HexColor("#2563eb"),
        spaceBefore=14,
        spaceAfter=8
    )

    normal_style = ParagraphStyle(
        "normal",
        parent=styles["BodyText"],
        fontSize=11,
        leading=16,
        textColor=colors.HexColor("#374151"),
    )

    bullet_style = ParagraphStyle(
        "bullet",
        parent=styles["BodyText"],
        fontSize=11,
        leading=16,
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
    story.append(Spacer(1, 10))

    # ========================
    # SUMMARY CARD (DESIGN)
    # ========================
    story.append(Paragraph("SUMMARY", section_style))

    summary_table = Table([[Paragraph(summary, normal_style)]],
                          colWidths=[500])

    summary_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#EFF6FF")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#93C5FD")),
        ("INNERPADDING", (0, 0), (-1, -1), 12),
    ]))

    story.append(summary_table)
    story.append(Spacer(1, 12))

    # ========================
    # KEY POINTS BOX
    # ========================
    if key_points:
        story.append(Paragraph("KEY POINTS", section_style))

        kp_table = Table([[Paragraph(key_points.replace("\n", "<br/>"), normal_style)]],
                         colWidths=[500])

        kp_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#ECFDF5")),
            ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#6EE7B7")),
            ("INNERPADDING", (0, 0), (-1, -1), 12),
        ]))

        story.append(kp_table)
        story.append(Spacer(1, 12))

    # ========================
    # CONTENT SECTION
    # ========================
    story.append(Paragraph("DETAILED NOTES", section_style))

    for line in content.split("\n"):
        line = line.strip()

        if not line:
            story.append(Spacer(1, 6))
            continue

        # Bullet handling
        if line.startswith("- ") or line.startswith("* "):
            line = "• " + line[2:]
            story.append(Paragraph(line, bullet_style))
        else:
            story.append(Paragraph(line, normal_style))

    doc.build(story)

    return file_path