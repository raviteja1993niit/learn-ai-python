"""
builder/md_builder.py
──────────────────────
Converts the same YAML structure into a well-structured Markdown document.
Each slide type maps to a Markdown section.
"""

from typing import List


# ── Helpers ───────────────────────────────────────────────────────────────────

def _h(level: int, text: str) -> str:
    return f"{'#' * level} {text}\n"


def _bold(text: str) -> str:
    return f"**{text}**"


def _italic(text: str) -> str:
    return f"*{text}*"


def _hr() -> str:
    return "\n---\n"


def _items_to_md(items: list, indent: int = 0) -> str:
    pad = "  " * indent
    lines = []
    for item in items:
        if isinstance(item, str):
            lines.append(f"{pad}- {item}")
        elif "bold" in item:
            lines.append(f"\n{pad}**{item['bold']}**")
        elif "heading" in item:
            lines.append(f"\n{pad}**{item['heading']}**")
            if "text" in item:
                lines.append(f"{pad}  {item['text']}")
        elif "text" in item:
            lines.append(f"{pad}- {item['text']}")
    return "\n".join(lines)


# ── Slide-type renderers ───────────────────────────────────────────────────────

def md_title(cfg: dict, meta: dict) -> str:
    lines = [
        _h(1, f"{cfg.get('title_line1','')} {cfg.get('title_line2','')}".strip()),
        f"\n{_bold(meta.get('author',''))}  |  {meta.get('role','')}  |  {meta.get('company','')}\n",
        f"{meta.get('event','')}  |  {meta.get('date','')}\n",
    ]
    for pill in cfg.get("pills", []):
        lines.append(f"- {pill.get('label','')}")
    return "\n".join(lines) + "\n"


def md_agenda(cfg: dict, meta: dict) -> str:
    out = [_h(2, "Agenda")]
    for sec in cfg.get("sections", []):
        out.append(f"\n### {sec.get('label','')} — {sec.get('title','')}")
        for item in sec.get("items", []):
            out.append(f"- {item}")
    note = cfg.get("footer_note", "")
    if note:
        out.append(f"\n{_italic(note)}")
    return "\n".join(out) + "\n"


def md_section_intro(cfg: dict, meta: dict) -> str:
    out = [
        _hr(),
        _h(2, f"{cfg.get('label','')} — {cfg.get('title','')}"),
    ]
    subtitle = cfg.get("subtitle", "")
    if subtitle:
        out.append(f"{_italic(subtitle)}\n")
    heading = cfg.get("learn_heading", "What you will learn:")
    out.append(f"\n**{heading}**")
    for item in cfg.get("learn_items", []):
        out.append(f"- {item}")
    return "\n".join(out) + "\n"


def md_two_column(cfg: dict, meta: dict) -> str:
    out = [
        _h(3, cfg.get("title", "")),
        _italic(cfg.get("subtitle", "")) + "\n",
    ]
    left  = cfg.get("left", {})
    right = cfg.get("right", {})
    divider = cfg.get("divider", "→")

    out.append(f"#### {left.get('heading','Left')}  {divider}  {right.get('heading','Right')}\n")
    out.append("| Left | Right |")
    out.append("|------|-------|")

    left_items  = left.get("items", [])
    right_items = right.get("items", [])
    max_len = max(len(left_items), len(right_items))

    def _cell(item):
        if isinstance(item, str):
            return item
        if "bold" in item:
            return f"**{item['bold']}**"
        if "heading" in item:
            h = f"**{item['heading']}**"
            return f"{h}<br>{item.get('text','')}"
        return item.get("text", "")

    for i in range(max_len):
        lc = _cell(left_items[i])  if i < len(left_items)  else ""
        rc = _cell(right_items[i]) if i < len(right_items) else ""
        out.append(f"| {lc} | {rc} |")

    return "\n".join(out) + "\n"


def md_bullets(cfg: dict, meta: dict) -> str:
    out = [
        _h(3, cfg.get("title", "")),
        _italic(cfg.get("subtitle", "")) + "\n" if cfg.get("subtitle") else "",
        _items_to_md(cfg.get("items", [])),
    ]
    return "\n".join(out) + "\n"


def md_pain_cards(cfg: dict, meta: dict) -> str:
    out = [
        _h(3, cfg.get("title", "")),
        _italic(cfg.get("subtitle", "")) + "\n",
    ]
    for pain in cfg.get("pains", []):
        out.append(f"\n**{pain.get('number','')} — {pain.get('heading','')}**")
        text = pain.get("text", "")
        if isinstance(text, list):
            for line in text:
                out.append(f"  {line}")
        else:
            for line in text.split("\n"):
                out.append(f"  {line}")

    solutions_heading = cfg.get("solutions_heading", "Solutions:")
    out.append(f"\n**{solutions_heading}**\n")
    out.append("| Version | What Changed |")
    out.append("|---------|-------------|")
    for sol in cfg.get("solutions", []):
        label = sol.get("label", "")
        text  = sol.get("text", "").replace("\n", " ")
        out.append(f"| {label} | {text} |")
    return "\n".join(out) + "\n"


def md_comparison_table(cfg: dict, meta: dict) -> str:
    out = [
        _h(3, cfg.get("title", "")),
        _italic(cfg.get("subtitle", "")) + "\n" if cfg.get("subtitle") else "",
    ]
    headers = cfg.get("headers", [])
    rows    = cfg.get("rows", [])
    if headers:
        out.append("| " + " | ".join(headers) + " |")
        out.append("|" + "|".join(["---"] * len(headers)) + "|")
        for row in rows:
            out.append("| " + " | ".join(str(c) for c in row) + " |")
    return "\n".join(out) + "\n"


def md_stats_banner(cfg: dict, meta: dict) -> str:
    out = [
        _h(3, cfg.get("title", "")),
        _italic(cfg.get("subtitle", "")) + "\n" if cfg.get("subtitle") else "",
    ]
    stats = cfg.get("stats", [])
    if stats:
        out.append("| " + " | ".join(s.get("value","") for s in stats) + " |")
        out.append("|" + "|".join(["---"] * len(stats)) + "|")
        out.append("| " + " | ".join(s.get("label","") for s in stats) + " |")
        out.append("")

    out.append("**Before (Manual)**")
    for line in cfg.get("before", []):
        out.append(f"- {line}")
    out.append("\n**After (Multi-Agent)**")
    for line in cfg.get("after", []):
        out.append(f"- {line}")
    return "\n".join(out) + "\n"


def md_key_takeaways(cfg: dict, meta: dict) -> str:
    out = [_h(2, "Key Takeaways")]
    for i, item in enumerate(cfg.get("items", []), 1):
        out.append(f"{i}. {item}")
    return "\n".join(out) + "\n"


def md_closing(cfg: dict, meta: dict) -> str:
    out = [
        _hr(),
        _h(2, cfg.get("title", "Thank You!")),
        f"\n{_italic(cfg.get('subtitle',''))}\n",
        f"{_bold(meta.get('author',''))}  |  {meta.get('role','')}  |  {meta.get('company','')}",
        f"\n{meta.get('event','')}  |  {meta.get('date','')}",
    ]
    for uc in cfg.get("use_cases", []):
        out.append(f"- {uc}")
    email = cfg.get("email", meta.get("email", ""))
    if email:
        out.append(f"\n📧 {email}")
    return "\n".join(out) + "\n"


# ── Dispatcher ────────────────────────────────────────────────────────────────

_MD_MAP = {
    "title":            md_title,
    "agenda":           md_agenda,
    "section_intro":    md_section_intro,
    "two_column":       md_two_column,
    "bullets":          md_bullets,
    "pain_cards":       md_pain_cards,
    "comparison_table": md_comparison_table,
    "stats_banner":     md_stats_banner,
    "key_takeaways":    md_key_takeaways,
    "closing":          md_closing,
}


def build_markdown(meta: dict, slides: list) -> str:
    """Return a full Markdown string from the presentation definition."""
    parts = [
        f"# {meta.get('title', 'Presentation')}\n",
        f"{meta.get('author','')}  |  {meta.get('role','')}  |  "
        f"{meta.get('company','')}  |  {meta.get('date','')}\n",
        "---\n",
    ]
    for slide_cfg in slides:
        slide_type = slide_cfg.get("type", "bullets")
        renderer   = _MD_MAP.get(slide_type)
        if renderer:
            parts.append(renderer(slide_cfg, meta))
        else:
            parts.append(f"<!-- slide type '{slide_type}' not rendered -->\n")
    return "\n".join(parts)
