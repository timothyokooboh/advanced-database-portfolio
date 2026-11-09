import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "final-documentation" / "Okooboh_Timothy_301915902_Portfolio_Summary.md"
OUTPUT = ROOT / "output" / "pdf" / "Okooboh_Timothy_301915902_Portfolio_Documentation.pdf"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)


def parse_markdown(path):
    metadata = {}
    sections = {}
    current = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("**") and ":**" in line:
            key, value = line.split(":**", 1)
            metadata[key.strip("* ").lower()] = value.strip()
        elif line.startswith("## "):
            current = line[3:]
            sections[current] = []
        elif line.startswith("### "):
            current = line[4:]
            sections[current] = []
        elif current and line:
            sections[current].append(line)
    return metadata, sections


def inline_markup(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<b>\1</b>", text)
    text = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", text)
    return text


def prose(section):
    return [inline_markup(line) for line in MARKDOWN_SECTIONS[section] if not line.startswith(("- ", "1. ", "2. ", "3. ", "4. "))]


MARKDOWN_METADATA, MARKDOWN_SECTIONS = parse_markdown(SOURCE)

FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
if Path(FONT_REGULAR).exists() and Path(FONT_BOLD).exists():
    pdfmetrics.registerFont(TTFont("PortfolioSans", FONT_REGULAR))
    pdfmetrics.registerFont(TTFont("PortfolioSans-Bold", FONT_BOLD))
    regular_font = "PortfolioSans"
    bold_font = "PortfolioSans-Bold"
else:
    regular_font = "Helvetica"
    bold_font = "Helvetica-Bold"

NAVY = colors.HexColor("#183153")
TEAL = colors.HexColor("#008A8A")
PALE = colors.HexColor("#EAF5F5")
TEXT = colors.HexColor("#243447")
MUTED = colors.HexColor("#5F6B76")
LINE = colors.HexColor("#D7E0E8")

styles = getSampleStyleSheet()
title = ParagraphStyle(
    "Title",
    parent=styles["Title"],
    fontName=bold_font,
    fontSize=20,
    leading=23,
    textColor=NAVY,
    alignment=TA_LEFT,
    spaceAfter=5 * mm,
)
subtitle = ParagraphStyle(
    "Subtitle",
    fontName=regular_font,
    fontSize=9,
    leading=13,
    textColor=MUTED,
    spaceAfter=3 * mm,
)
h1 = ParagraphStyle(
    "H1",
    fontName=bold_font,
    fontSize=13,
    leading=16,
    textColor=NAVY,
    spaceBefore=2.5 * mm,
    spaceAfter=1.5 * mm,
)
h2 = ParagraphStyle(
    "H2",
    fontName=bold_font,
    fontSize=10.2,
    leading=13,
    textColor=TEAL,
    spaceBefore=1.8 * mm,
    spaceAfter=0.8 * mm,
)
body = ParagraphStyle(
    "Body",
    fontName=regular_font,
    fontSize=8.55,
    leading=12.1,
    textColor=TEXT,
    alignment=TA_LEFT,
    spaceAfter=1.5 * mm,
)
small = ParagraphStyle(
    "Small",
    fontName=regular_font,
    fontSize=7.5,
    leading=10,
    textColor=MUTED,
)
bullet = ParagraphStyle(
    "Bullet",
    parent=body,
    leftIndent=4 * mm,
    firstLineIndent=-2.8 * mm,
    bulletIndent=0,
    spaceAfter=0.8 * mm,
)


def p(text, style=body):
    return Paragraph(text, style)


def page_chrome(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, height - 10 * mm, width, 10 * mm, fill=1, stroke=0)
    canvas.setFont(bold_font, 7.5)
    canvas.setFillColor(colors.white)
    canvas.drawString(15 * mm, height - 6.3 * mm, "MIT 8103  |  ADVANCED DATABASE SYSTEMS")
    canvas.setStrokeColor(LINE)
    canvas.line(15 * mm, 13 * mm, width - 15 * mm, 13 * mm)
    canvas.setFont(regular_font, 7.2)
    canvas.setFillColor(MUTED)
    canvas.drawString(15 * mm, 8.5 * mm, "Timothy Okooboh  |  301915902  |  AsterMart Portfolio")
    canvas.drawRightString(width - 15 * mm, 8.5 * mm, f"Page {doc.page}")
    canvas.restoreState()


doc = BaseDocTemplate(
    str(OUTPUT),
    pagesize=A4,
    leftMargin=15 * mm,
    rightMargin=15 * mm,
    topMargin=16 * mm,
    bottomMargin=17 * mm,
    title="MIT 8103 Advanced Database Systems Portfolio Documentation",
    author="Timothy Okooboh",
    subject="AsterMart Advanced Database Systems Portfolio",
)
frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="main")
doc.addPageTemplates([PageTemplate(id="portfolio", frames=[frame], onPage=page_chrome)])

story = []

# Page 1
story.append(Spacer(1, 4 * mm))
story.append(p("Advanced Database Systems<br/>Portfolio Documentation", title))
story.append(p("MIT 8103  |  2026/2027 First Semester Continuous Assessment", subtitle))

identity_data = [
    [p("STUDENT", small), p("Timothy Okooboh", body), p("STUDENT ID", small), p("301915902", body)],
    [p("CASE STUDY", small), p("AsterMart Retail & Fulfilment Ltd.", body), p("DATABASES", small), p("PostgreSQL 16 + MongoDB 7", body)],
]
identity = Table(identity_data, colWidths=[24 * mm, 61 * mm, 24 * mm, 61 * mm])
identity.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, -1), PALE),
    ("BOX", (0, 0), (-1, -1), 0.6, LINE),
    ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ("TOPPADDING", (0, 0), (-1, -1), 5),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
]))
story.append(identity)
story.append(Spacer(1, 2.5 * mm))
repository = MARKDOWN_METADATA["repository"]
story.append(p(f"Repository: <link href='{repository}' color='#008A8A'>{repository.removeprefix('https://')}</link>", small))

story.append(p("Organisation and technical approach", h1))
for paragraph in prose("Organisation and technical approach"):
    story.append(p(paragraph))

story.append(p("1. Database design and modelling", h2))
for paragraph in prose("1. Database design and modelling"):
    story.append(p(paragraph))

story.append(p("2. Query processing and optimisation", h2))
for paragraph in prose("2. Query processing and optimisation"):
    story.append(p(paragraph))

metrics = Table([
    [p("EVIDENCE", small), p("BASELINE", small), p("OPTIMISED", small), p("OBSERVATION", small)],
    [p("Branch workload", small), p("4.017 ms", small), p("0.034 ms", small), p("Index-only range scan", small)],
    [p("Product sales", small), p("8.029 ms", small), p("1.118 ms", small), p("Avoided 180,000-line scan", small)],
    [p("Payment window", small), p("3.205 ms", small), p("0.198 ms", small), p("Partial successful-payment index", small)],
], colWidths=[42 * mm, 28 * mm, 28 * mm, 72 * mm])
metrics.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("GRID", (0, 0), (-1, -1), 0.35, LINE),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("LEFTPADDING", (0, 0), (-1, -1), 5),
    ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ("TOPPADDING", (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
]))
story.append(metrics)
story.append(PageBreak())

# Page 2
story.append(p("Practical implementation and advanced models", title))
story.append(p("3. Transactions and concurrency", h2))
for paragraph in prose("3. Transactions and concurrency"):
    story.append(p(paragraph))

story.append(p("4. NoSQL and advanced data models", h2))
for paragraph in prose("4. NoSQL and advanced data models"):
    story.append(p(paragraph))

story.append(p("5. Distributed and cloud database exercise", h2))
for paragraph in prose("5. Distributed and cloud database exercise"):
    story.append(p(paragraph))

flow = Table([
    [p("ORDER / INVENTORY WRITES", small), p("LOGICAL REPLICATION", small), p("REPORTING READS", small)],
    [p("PostgreSQL publisher<br/>port 5441", body), p("Publication + WAL changes<br/>asynchronous", body), p("PostgreSQL subscriber<br/>port 5442", body)],
], colWidths=[53 * mm, 64 * mm, 53 * mm])
flow.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("BACKGROUND", (0, 1), (-1, 1), PALE),
    ("GRID", (0, 0), (-1, -1), 0.5, LINE),
    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 7),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
]))
story.append(flow)
story.append(Spacer(1, 2 * mm))

story.append(p("Verification highlights", h1))
for text in [line[2:] for line in MARKDOWN_SECTIONS["Verification highlights"] if line.startswith("- ")]:
    story.append(Paragraph(f"&bull; {text}", bullet))

story.append(p("Repository evidence map", h1))
evidence = Table([
    [p("PORTFOLIO", small), p("PRIMARY EVIDENCE", small)],
    [p("1 - Design", small), p("ERD, DDL, keys, constraints, normalisation", small)],
    [p("2 - Optimisation", small), p("SQL results, before/after plans, index analysis", small)],
    [p("3 - Transactions", small), p("Commit/rollback output, competing-session lock test", small)],
    [p("4 - NoSQL", small), p("MongoDB model, queries, explain and validation", small)],
    [p("5 - Distributed", small), p("Publisher/subscriber output and monitoring state", small)],
], colWidths=[42 * mm, 128 * mm])
evidence.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("GRID", (0, 0), (-1, -1), 0.35, LINE),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("LEFTPADDING", (0, 0), (-1, -1), 5),
    ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ("TOPPADDING", (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
]))
story.append(evidence)
story.append(PageBreak())

# Page 3
story.append(p("Reflection, declaration and references", title))
story.append(p("Individual technical reflection", h1))
for paragraph in prose("Technical reflection"):
    story.append(p(paragraph))

story.append(p("AI use declaration", h1))
for paragraph in prose("AI use declaration"):
    story.append(p(paragraph))

story.append(p("References", h1))
for ref in MARKDOWN_SECTIONS["References"]:
    match = re.match(r"(\d+)\.\s+(.*)", ref)
    if match:
        story.append(Paragraph(f"{match.group(1)}. {inline_markup(match.group(2))}", bullet))

doc.build(story)
print(OUTPUT)
