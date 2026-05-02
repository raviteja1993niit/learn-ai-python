"""
builder/slides.py
──────────────────
One function per slide type.  Each receives:
  prs   — the Presentation object
  T     — theme dict from builder.theme
  cfg   — the slide's YAML dict (keys vary per type)
  meta  — the top-level meta dict (author, date, company …)

Supported types
───────────────
  title              Cover / title slide
  agenda             Two-column agenda (up to 2 sections)
  section_intro      Section divider with label pill + learn bullets
  two_column         Left/right comparison or problem/solution panel
  bullets            Standard header + multi-paragraph content
  pain_cards         Three pain cards + solution row
  comparison_table   Row/column comparison grid
  stats_banner       Key metrics banner above a before/after story
  key_takeaways      Numbered takeaway bullets
  closing            Thank-you / contact slide
"""

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN

from builder.theme import accent_color, accent_light, get_theme
from builder.primitives import (
    paint_bg, box, rbox, hline, vline,
    tb, ml, arrow_right, arrow_down,
    slide_header, slide_footer,
)

SW, SH = 13.33, 7.50   # slide dimensions in inches


# ── Internal helpers ──────────────────────────────────────────────────────────

def _blank(prs: Presentation, T: dict):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    paint_bg(s, T["BG"])
    return s


def _footer_text(meta: dict) -> str:
    parts = [
        meta.get("company", ""),
        meta.get("event", ""),
        meta.get("date", ""),
    ]
    return "  |  ".join(p for p in parts if p)


def _accent(cfg: dict, key: str = "color", fallback: str = "orange"):
    return accent_color(cfg.get(key, fallback))


def _accent_l(cfg: dict, key: str = "color", fallback: str = "orange"):
    return accent_light(cfg.get(key, fallback))


def _item_rows(items: list, T: dict, heading_color=None) -> list:
    """
    Convert YAML item list to ml() row tuples.
    Items can be:
      str                          → plain
      {text: …}                    → plain
      {bold: …}                    → bold intro line
      {heading: …, text: …}        → orange heading + indented text
    """
    heading_color = heading_color or T["ORANGE"]
    rows = []
    for item in items:
        if isinstance(item, str):
            rows.append((item, 11, False, T["DARK"]))
        elif "bold" in item:
            rows.append((item["bold"], 12, True, T["NAVY"]))
            rows.append(("", 4, False, T["NAVY"]))
        elif "heading" in item:
            rows.append((item["heading"], 12, True, heading_color))
            if "text" in item:
                rows.append(("  " + item["text"], 11, False, T["DARK"]))
            rows.append(("", 4, False, T["NAVY"]))
        elif "text" in item:
            rows.append((item["text"], 11, False, T["DARK"]))
        else:
            rows.append((str(item), 11, False, T["DARK"]))
    return rows


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: title
# ─────────────────────────────────────────────────────────────────────────────

def slide_title(prs, T, cfg, meta):
    """
    cfg keys:
      title_line1, title_line2   — two headline lines
      pills                      — list of {label, color}
      sidebar                    — {heading, lines: [...]}
    """
    s = _blank(prs, T)

    # Left accent stripe + white body
    box(s, 0,    0, 0.22, SH, T["ORANGE"])
    box(s, 0.22, 0, SW - 0.22, SH, T["WHITE"])

    # Title block
    hline(s, 0.55, 0.70, 8.0, T["ORANGE"], 0.06)
    tb(s, 0.55, 0.92, 11.5, 0.72,
       cfg.get("title_line1", meta.get("title", "")),
       sz=30, bold=True, color=T["NAVY"])
    tb(s, 0.55, 1.70, 11.5, 0.72,
       cfg.get("title_line2", ""),
       sz=30, bold=True, color=T["ORANGE"])
    hline(s, 0.55, 2.55, 8.0, T["LINE"], 0.06)

    # Author info
    tb(s, 0.55, 2.78, 10.0, 0.42,
       f"{meta.get('author','')}  |  {meta.get('role','')}  |  {meta.get('company','')}",
       sz=14, color=T["NAVY"])
    tb(s, 0.55, 3.24, 10.0, 0.36,
       f"{meta.get('event','')}  |  {meta.get('date','')}",
       sz=12, color=T["GRAY"])

    # Use-case pills
    pills = cfg.get("pills", [])
    pill_y = 3.90
    for pill in pills:
        ac   = accent_color(pill.get("color", "orange"))
        ac_l = accent_light(pill.get("color", "orange"))
        box(s, 0.55, pill_y, 3.40, 0.52, ac_l)
        hline(s, 0.55, pill_y, 3.40, ac, 0.05)
        tb(s, 0.72, pill_y + 0.08, 3.18, 0.36,
           pill.get("label", ""), sz=11, bold=True, color=ac)
        pill_y += 0.68

    # Sidebar card
    sidebar = cfg.get("sidebar", {})
    if sidebar:
        box(s, 9.20, 0.60, 3.90, 6.10, T["CARD"])
        tb(s, 9.45, 1.10, 3.50, 0.55,
           sidebar.get("heading", ""), sz=16, bold=True,
           color=T["ORANGE"], align=PP_ALIGN.CENTER)
        hline(s, 9.45, 1.72, 3.30, T["ORANGE"], 0.04)
        lines = sidebar.get("lines", [])
        rows = []
        for line in lines:
            if isinstance(line, dict):
                rows.append((line.get("text", ""), line.get("size", 11),
                             line.get("bold", False), T["NAVY"]))
            elif line == "":
                rows.append(("", 5, False, T["NAVY"]))
            else:
                rows.append((line, 11, False, T["NAVY"]))
        ml(s, 9.45, 1.88, 3.45, 4.50, rows, default_sz=11, default_color=T["NAVY"])

    # Confidential footer
    tb(s, 0.55, 7.18, 9.0, 0.25,
       f"EPAM Proprietary & Confidential.", sz=9, color=T["LGRAY"])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: agenda
# ─────────────────────────────────────────────────────────────────────────────

def slide_agenda(prs, T, cfg, meta):
    """
    cfg keys:
      sections      — list of {label, title, color, items: [...str]}
      footer_note   — optional extra line below columns
    """
    s = _blank(prs, T)
    slide_header(s, T, "Agenda")
    slide_footer(s, T, _footer_text(meta))

    sections = cfg.get("sections", [])
    col_w  = (SW - 1.00) / max(len(sections), 1)
    col_x0 = 0.35

    for i, sec in enumerate(sections):
        cx = col_x0 + i * (col_w + 0.28)
        ac   = accent_color(sec.get("color", "orange"))
        ac_l = accent_light(sec.get("color", "orange"))

        # Column background
        box(s, cx, 1.05, col_w, 5.90, ac_l)
        hline(s, cx, 1.05, col_w, ac, 0.06)

        # Label pill
        box(s, cx, 1.05, 2.50, 0.50, ac)
        tb(s, cx + 0.02, 1.07, 2.46, 0.46,
           sec.get("label", f"Section {i+1}"),
           sz=12, bold=True, color=T["WHITE"], align=PP_ALIGN.CENTER)

        # Section title
        tb(s, cx + 2.62, 1.10, col_w - 2.68, 0.38,
           sec.get("title", ""), sz=12, bold=True, color=ac)

        # Items
        items = sec.get("items", [])
        for j, item in enumerate(items):
            item_color = ac if j == 0 else T["NAVY"]
            bold_item  = (j == 0)
            tb(s, cx + 0.20, 1.70 + j * 1.00, col_w - 0.26, 0.80,
               item, sz=13, color=item_color, bold=bold_item)

    if i < len(sections) - 1:
        vline(s, cx - 0.20, 1.05, 5.90, T["LGRAY"], 0.04)

    footer_note = cfg.get("footer_note", "")
    if footer_note:
        tb(s, 0.35, 7.00, 12.60, 0.28, footer_note, sz=10, color=T["GRAY"])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: section_intro
# ─────────────────────────────────────────────────────────────────────────────

def slide_section_intro(prs, T, cfg, meta):
    """
    cfg keys:
      label           — pill text e.g. "Use Case 1"
      label_color     — accent name
      title           — large heading
      subtitle        — italic subtitle
      learn_heading   — defaults to "What you will learn:"
      learn_items     — list of str bullet items
    """
    s = _blank(prs, T)
    ac   = accent_color(cfg.get("label_color", "orange"))
    ac_l = accent_light(cfg.get("label_color", "orange"))

    # Full-width background tint + white panel
    box(s, 0, 0, SW, SH, ac)
    box(s, 0.28, 0, SW - 0.28, SH, T["WHITE"])
    box(s, 0.28, 0, 0.10, SH, ac)   # coloured left bar on white
    hline(s, 0.50, 2.90, SW - 0.50, ac, 0.06)

    # Label pill
    box(s, 0.55, 1.00, 2.80, 0.62, ac)
    tb(s, 0.60, 1.04, 2.70, 0.54,
       cfg.get("label", ""), sz=16, bold=True,
       color=T["WHITE"], align=PP_ALIGN.CENTER)

    # Title / subtitle
    tb(s, 0.55, 1.82, 12.20, 1.10,
       cfg.get("title", ""), sz=38, bold=True, color=T["NAVY"])
    subtitle = cfg.get("subtitle", "")
    if subtitle:
        tb(s, 0.55, 2.98, 12.20, 0.45,
           subtitle, sz=14, color=T["GRAY"], italic=True)

    # Learn bullets
    hline(s, 0.55, 3.56, 4.0, ac, 0.04)
    heading = cfg.get("learn_heading", "What you will learn:")
    items   = cfg.get("learn_items", [])
    rows = [(heading, 13, True, T["NAVY"])]
    for item in items:
        rows.append(("  " + item, 12, False, T["DARK"]))
    ml(s, 0.55, 3.78, 12.0, 2.80, rows)

    tb(s, 0.55, 7.18, 9.0, 0.25,
       "EPAM Proprietary & Confidential.", sz=9, color=T["LGRAY"])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: two_column
# ─────────────────────────────────────────────────────────────────────────────

def slide_two_column(prs, T, cfg, meta):
    """
    cfg keys:
      title, subtitle
      divider        — badge text between panels ("VS", "→", ":")
      left / right   — each has {heading, bg (red|green|blue…), items: [...]}
    """
    s = _blank(prs, T)
    slide_header(s, T, cfg.get("title", ""), cfg.get("subtitle", ""))
    slide_footer(s, T, _footer_text(meta))

    panel_w = 5.90
    left_x  = 0.35
    right_x = 7.40

    def _panel(panel_cfg, px, bg_key):
        col_name = panel_cfg.get("bg", "orange")
        ac    = accent_color(col_name)
        ac_l  = accent_light(col_name)
        bg    = ac_l if T["name"] == "light" else T["CARD"]
        box(s, px, 1.05, panel_w, 5.95, bg)
        hline(s, px, 1.05, panel_w, ac, 0.05)
        tb(s, px + 0.17, 1.14, panel_w - 0.22, 0.44,
           panel_cfg.get("heading", ""), sz=14, bold=True, color=ac)
        rows = _item_rows(panel_cfg.get("items", []), T, heading_color=ac)
        if rows:
            ml(s, px + 0.17, 1.66, panel_w - 0.22, 5.10, rows)

    _panel(cfg.get("left", {}), left_x, "left")
    _panel(cfg.get("right", {}), right_x, "right")

    # Divider badge
    divider = cfg.get("divider", "→")
    rbox(s, 6.04, 3.76, 1.22, 0.62, T["WHITE"], border=T["ORANGE"])
    tb(s, 6.06, 3.80, 1.18, 0.54, divider,
       sz=20, bold=True, color=T["ORANGE"], align=PP_ALIGN.CENTER)


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: bullets
# ─────────────────────────────────────────────────────────────────────────────

def slide_bullets(prs, T, cfg, meta):
    """
    cfg keys:
      title, subtitle
      items    — list (str | {heading, text} | {bold})
      columns  — optional int (1 or 2) to split items into two columns
    """
    s = _blank(prs, T)
    slide_header(s, T, cfg.get("title", ""), cfg.get("subtitle", ""))
    slide_footer(s, T, _footer_text(meta))

    items   = cfg.get("items", [])
    columns = cfg.get("columns", 1)

    if columns == 2:
        mid = len(items) // 2
        left_items, right_items = items[:mid], items[mid:]
        rows_l = _item_rows(left_items, T)
        rows_r = _item_rows(right_items, T)
        ml(s, 0.35, 1.05, 6.10, 6.10, rows_l, default_color=T["DARK"])
        vline(s, 6.65, 1.05, 6.10, T["LINE"], 0.03)
        ml(s, 6.85, 1.05, 6.10, 6.10, rows_r, default_color=T["DARK"])
    else:
        rows = _item_rows(items, T)
        ml(s, 0.35, 1.05, 12.60, 6.10, rows, default_color=T["DARK"])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: pain_cards
# ─────────────────────────────────────────────────────────────────────────────

def slide_pain_cards(prs, T, cfg, meta):
    """
    cfg keys:
      title, subtitle
      pains       — list of {number, heading, text}   (exactly 3)
      solutions_heading
      solutions   — list of {label, text}             (exactly 3)
    """
    s = _blank(prs, T)
    slide_header(s, T, cfg.get("title", ""), cfg.get("subtitle", ""))
    slide_footer(s, T, _footer_text(meta))

    pains = cfg.get("pains", [])
    card_w  = (SW - 0.90) / max(len(pains), 1)
    card_x0 = 0.35
    card_y  = 1.08
    card_h  = 3.20

    for i, pain in enumerate(pains):
        cx = card_x0 + i * (card_w + 0.15)
        box(s, cx, card_y, card_w, card_h, T["CARD"])
        hline(s, cx, card_y, card_w, T["ORANGE"], 0.05)
        # Number badge
        rbox(s, cx + 0.10, card_y + 0.08, 0.72, 0.36,
             T["ORANGE"], border=None)
        tb(s, cx + 0.10, card_y + 0.09, 0.72, 0.34,
           pain.get("number", f"Pain {i+1}"),
           sz=10, bold=True, color=T["WHITE"], align=PP_ALIGN.CENTER)
        # Heading
        tb(s, cx + 0.92, card_y + 0.08, card_w - 1.02, 0.38,
           pain.get("heading", ""), sz=13, bold=True, color=T["NAVY"])
        # Body text
        text_lines = pain.get("text", "")
        if isinstance(text_lines, str):
            text_lines = text_lines.split("\n")
        rows = [(ln, 10, False, T["DARK"]) for ln in text_lines]
        ml(s, cx + 0.10, card_y + 0.52, card_w - 0.20, card_h - 0.60, rows)

    # Solutions row
    solutions = cfg.get("solutions", [])
    if solutions:
        sol_y = card_y + card_h + 0.22
        sol_heading = cfg.get("solutions_heading", "How each generation solved these pains:")
        tb(s, 0.35, sol_y, 12.60, 0.28,
           sol_heading, sz=11, bold=True, color=T["NAVY"])
        sol_y += 0.32

        sol_w = (SW - 0.90) / max(len(solutions), 1)
        for i, sol in enumerate(solutions):
            sx = 0.35 + i * (sol_w + 0.15)
            box(s, sx, sol_y, sol_w, 1.55, T["CARD"])
            hline(s, sx, sol_y, sol_w, T["ORANGE"], 0.04)
            tb(s, sx + 0.10, sol_y + 0.06, sol_w - 0.20, 0.30,
               sol.get("label", ""), sz=11, bold=True, color=T["ORANGE"])
            ml(s, sx + 0.10, sol_y + 0.40, sol_w - 0.20, 1.10,
               [(ln, 9, False, T["DARK"])
                for ln in sol.get("text", "").split("\n")])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: comparison_table
# ─────────────────────────────────────────────────────────────────────────────

def slide_comparison_table(prs, T, cfg, meta):
    """
    cfg keys:
      title, subtitle
      headers   — list of str (first col is the row-label column)
      rows      — list of lists (same length as headers)
      highlights — optional list of {row, col, color} to tint cells
    """
    s = _blank(prs, T)
    slide_header(s, T, cfg.get("title", ""), cfg.get("subtitle", ""))
    slide_footer(s, T, _footer_text(meta))

    headers = cfg.get("headers", [])
    rows    = cfg.get("rows", [])
    if not headers:
        return

    n_cols  = len(headers)
    col_w   = (SW - 0.70) / n_cols
    tbl_x   = 0.35
    tbl_y   = 1.10
    row_h   = (6.10) / (len(rows) + 1)   # +1 for header row

    # Header row
    for ci, hdr in enumerate(headers):
        cx = tbl_x + ci * col_w
        bg = T["NAVY"] if T["name"] == "dark" else T["ORANGE"] if ci == 0 else T["CARD"]
        box(s, cx, tbl_y, col_w - 0.04, row_h - 0.04, bg)
        col = T["WHITE"] if (ci == 0 or T["name"] == "dark") else T["NAVY"]
        tb(s, cx + 0.08, tbl_y + 0.06, col_w - 0.20, row_h - 0.10,
           hdr, sz=11, bold=True, color=col)

    # Data rows
    highlights = {(h["row"], h["col"]): h.get("color", "orange")
                  for h in cfg.get("highlights", [])}

    for ri, row in enumerate(rows):
        ry = tbl_y + (ri + 1) * row_h
        row_bg = T["CARD"] if ri % 2 == 0 else T["WHITE"]
        for ci, cell in enumerate(row):
            cx = tbl_x + ci * col_w
            cell_bg = row_bg
            if (ri, ci) in highlights:
                cell_bg = accent_light(highlights[(ri, ci)])
            box(s, cx, ry, col_w - 0.04, row_h - 0.04, cell_bg)
            col = T["NAVY"] if ci == 0 else T["DARK"]
            tb(s, cx + 0.08, ry + 0.04, col_w - 0.20, row_h - 0.08,
               str(cell), sz=10, bold=(ci == 0), color=col)


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: stats_banner
# ─────────────────────────────────────────────────────────────────────────────

def slide_stats_banner(prs, T, cfg, meta):
    """
    cfg keys:
      title, subtitle
      stats    — list of {value, label}   (displayed as large number + caption)
      before   — list of str (before state bullets)
      after    — list of str (after state bullets)
    """
    s = _blank(prs, T)
    slide_header(s, T, cfg.get("title", ""), cfg.get("subtitle", ""))
    slide_footer(s, T, _footer_text(meta))

    # Stats banner
    stats = cfg.get("stats", [])
    stat_w = (SW - 0.70) / max(len(stats), 1)
    for i, stat in enumerate(stats):
        sx = 0.35 + i * stat_w
        box(s, sx, 1.08, stat_w - 0.10, 1.10, T["CARD"])
        hline(s, sx, 1.08, stat_w - 0.10, T["ORANGE"], 0.05)
        tb(s, sx, 1.16, stat_w - 0.10, 0.58,
           str(stat.get("value", "")), sz=28, bold=True,
           color=T["ORANGE"], align=PP_ALIGN.CENTER)
        tb(s, sx, 1.76, stat_w - 0.10, 0.30,
           stat.get("label", ""), sz=9, color=T["GRAY"],
           align=PP_ALIGN.CENTER)

    # Before / After columns
    before = cfg.get("before", [])
    after  = cfg.get("after",  [])
    mid_y  = 2.35

    box(s, 0.35, mid_y, 6.00, 4.65, T["LRED"] if T["name"] == "light" else T["CARD"])
    hline(s, 0.35, mid_y, 6.00, T["RED"], 0.04)
    tb(s, 0.50, mid_y + 0.08, 5.70, 0.36,
       "Before  (Manual)", sz=13, bold=True, color=T["RED"])
    ml(s, 0.50, mid_y + 0.52, 5.70, 4.00,
       [(ln, 11, False, T["DARK"]) for ln in before])

    box(s, 7.00, mid_y, 6.00, 4.65, T["LGREEN"] if T["name"] == "light" else T["CARD"])
    hline(s, 7.00, mid_y, 6.00, T["GREEN"], 0.04)
    tb(s, 7.15, mid_y + 0.08, 5.70, 0.36,
       "After  (Multi-Agent System)", sz=13, bold=True, color=T["GREEN"])
    ml(s, 7.15, mid_y + 0.52, 5.70, 4.00,
       [(ln, 11, False, T["DARK"]) for ln in after])

    rbox(s, 6.15, mid_y + 1.88, 0.82, 0.46,
         T["WHITE"], border=T["ORANGE"])
    tb(s, 6.17, mid_y + 1.92, 0.78, 0.38, "▶",
       sz=14, bold=True, color=T["ORANGE"], align=PP_ALIGN.CENTER)


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: key_takeaways
# ─────────────────────────────────────────────────────────────────────────────

def slide_key_takeaways(prs, T, cfg, meta):
    """
    cfg keys:
      items   — list of str takeaway points
    """
    s = _blank(prs, T)
    slide_header(s, T, "Key Takeaways")
    slide_footer(s, T, _footer_text(meta))

    items = cfg.get("items", [])
    card_h = min(5.60 / max(len(items), 1), 1.10)
    for i, item in enumerate(items):
        iy = 1.10 + i * (card_h + 0.06)
        box(s, 0.35, iy, 12.60, card_h, T["CARD"])
        hline(s, 0.35, iy, 12.60, T["ORANGE"], 0.04)
        # Number circle
        rbox(s, 0.42, iy + 0.06, 0.55, card_h - 0.12,
             T["ORANGE"], border=None)
        tb(s, 0.42, iy + 0.06, 0.55, card_h - 0.12,
           str(i + 1), sz=14, bold=True,
           color=T["WHITE"], align=PP_ALIGN.CENTER)
        tb(s, 1.06, iy + (card_h - 0.36) / 2, 11.70, 0.36 + 0.20,
           item, sz=13, bold=False, color=T["NAVY"])


# ─────────────────────────────────────────────────────────────────────────────
# SLIDE TYPE: closing
# ─────────────────────────────────────────────────────────────────────────────

def slide_closing(prs, T, cfg, meta):
    """
    cfg keys:
      title         — e.g. "Thank You!"
      subtitle      — e.g. "Questions & Discussion Welcome"
      use_cases     — list of str summary lines
      email         — contact email
    """
    s = _blank(prs, T)
    box(s, 0, 0, 0.22, SH, T["ORANGE"])
    box(s, 0.22, 0, SW - 0.22, SH, T["WHITE"])

    hline(s, 0.55, 2.20, 8.0, T["ORANGE"], 0.06)
    tb(s, 0.55, 1.10, 10.0, 1.00,
       cfg.get("title", "Thank You!"), sz=42, bold=True, color=T["NAVY"])
    tb(s, 0.55, 2.36, 10.0, 0.52,
       cfg.get("subtitle", ""), sz=16, color=T["GRAY"], italic=True)

    tb(s, 0.55, 3.10, 10.0, 0.36,
       f"{meta.get('author','')}  |  {meta.get('role','')}  |  {meta.get('company','')}",
       sz=14, color=T["NAVY"])
    tb(s, 0.55, 3.56, 10.0, 0.30,
       f"{meta.get('event','')}  |  {meta.get('date','')}",
       sz=11, color=T["GRAY"])

    use_cases = cfg.get("use_cases", [])
    for i, uc in enumerate(use_cases):
        uy = 4.20 + i * 0.52
        box(s, 0.55, uy, 8.0, 0.44, T["CARD"])
        hline(s, 0.55, uy, 8.0, T["ORANGE"], 0.04)
        tb(s, 0.72, uy + 0.06, 7.70, 0.32, uc, sz=11, color=T["DARK"])

    email = cfg.get("email", meta.get("email", ""))
    if email:
        tb(s, 0.55, 5.50, 9.0, 0.30, email, sz=11, color=T["GRAY"])

    tb(s, 0.55, 7.18, 9.0, 0.25,
       "EPAM Proprietary & Confidential.", sz=9, color=T["LGRAY"])


# ─────────────────────────────────────────────────────────────────────────────
# DISPATCHER
# ─────────────────────────────────────────────────────────────────────────────

_SLIDE_MAP = {
    "title":            slide_title,
    "agenda":           slide_agenda,
    "section_intro":    slide_section_intro,
    "two_column":       slide_two_column,
    "bullets":          slide_bullets,
    "pain_cards":       slide_pain_cards,
    "comparison_table": slide_comparison_table,
    "stats_banner":     slide_stats_banner,
    "key_takeaways":    slide_key_takeaways,
    "closing":          slide_closing,
}


def render_slide(prs, T: dict, slide_cfg: dict, meta: dict):
    """Dispatch to the correct slide renderer based on 'type'."""
    slide_type = slide_cfg.get("type", "bullets")
    renderer   = _SLIDE_MAP.get(slide_type)
    if renderer is None:
        raise ValueError(
            f"Unknown slide type '{slide_type}'. "
            f"Available: {sorted(_SLIDE_MAP)}"
        )
    renderer(prs, T, slide_cfg, meta)
