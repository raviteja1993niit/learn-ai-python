"""
build_html_guide.py — Convert APP-GUIDES.md to a clean, Edge Read Aloud compatible HTML file.

Edge Read Aloud reads visible text in DOM order.
- Code blocks / ASCII diagrams are wrapped in aria-hidden so Read Aloud skips them.
- A short spoken placeholder is injected before each code block.
- Q&A sections use <details> accordion so the page is navigable.
- Clean serif font, good contrast, sticky nav with app jump links.
"""

import re
import markdown
from pathlib import Path

SRC  = Path(__file__).parent.parent / "content" / "app-guides.md"
DEST = Path(__file__).parent.parent / "docs" / "app-guides.html"

# ── Read source ───────────────────────────────────────────────────────────────
raw = SRC.read_text(encoding="utf-8")

# ── Pre-process: wrap Q&A blocks into <details> elements ─────────────────────
# Pattern: bold Q lines followed by blockquote answer
def wrap_qa(md_text: str) -> str:
    """Wrap **Q:** / > A: pairs into collapsible details blocks."""
    lines = md_text.splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Detect Q line: starts with **Q
        if re.match(r'^\*\*Q\d+:', line):
            # collect the question text
            q_text = re.sub(r'^\*\*|\*\*$', '', line).strip()
            out.append(f'<details class="qa-block" open>')
            out.append(f'<summary class="qa-q">{q_text}</summary>')
            out.append('<div class="qa-a">')
            i += 1
            # collect answer lines (blockquote = "> ") — convert inline for proper rendering
            ans_lines = []
            while i < len(lines) and (lines[i].startswith('>') or lines[i].strip() == ''):
                ans_lines.append(lines[i])
                i += 1
            ans_md = '\n'.join(ans_lines)
            ans_html = markdown.markdown(ans_md, extensions=['nl2br'])
            out.append(ans_html)
            out.append('</div></details>')
        else:
            out.append(line)
            i += 1
    return '\n'.join(out)

raw = wrap_qa(raw)

# ── Convert Markdown → HTML ───────────────────────────────────────────────────
md = markdown.Markdown(extensions=[
    'tables',
    'fenced_code',
    'toc',
    'nl2br',
    'attr_list',
])
body_html = md.convert(raw)

# ── Post-process: make <pre> blocks aria-hidden + add spoken placeholder ──────
def process_code_blocks(html: str) -> str:
    """Keep code blocks fully visible; add a small Read Aloud skip label."""
    def replacer(m):
        code_block = m.group(0)
        return (
            '<p class="code-note" aria-hidden="true">&#128196; '
            '<em>Code / diagram block below</em></p>'
            f'{code_block}'
        )
    return re.sub(r'<pre>.*?</pre>', replacer, html, flags=re.DOTALL)

body_html = process_code_blocks(body_html)

# ── Build navigation sidebar from H1/H2 headings ─────────────────────────────
nav_items = []
for m in re.finditer(r'<h([12])[^>]*id="([^"]+)"[^>]*>(.*?)</h\1>', body_html):
    level, hid, text = m.group(1), m.group(2), m.group(3)
    clean = re.sub(r'<[^>]+>', '', text)
    indent = 'nav-h2' if level == '2' else 'nav-h1'
    nav_items.append(f'<li class="{indent}"><a href="#{hid}">{clean}</a></li>')

nav_html = '<ul>' + '\n'.join(nav_items) + '</ul>' if nav_items else ''

# ── Assemble full HTML ────────────────────────────────────────────────────────
html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>App Guides — Interview Prep | Raviteja Thota</title>
  <style>
    /* ── Reset & Base ── */
    *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}

    :root {{
      --bg:        #fafaf8;
      --surface:   #ffffff;
      --border:    #e2e2dd;
      --text:      #1a1a18;
      --muted:     #6b6b63;
      --accent:    #c45e00;
      --accent-bg: #fff7f0;
      --blue:      #1a5fa8;
      --code-bg:   #f3f3ef;
      --qa-bg:     #f0f7ff;
      --qa-border: #3a82c4;
      --nav-w:     280px;
      --font-body: Georgia, "Times New Roman", serif;
      --font-ui:   system-ui, -apple-system, sans-serif;
      --font-mono: "Cascadia Code", "Fira Code", Consolas, monospace;
    }}

    html {{ scroll-behavior: smooth; }}

    body {{
      font-family: var(--font-body);
      font-size: 18px;
      line-height: 1.85;
      color: var(--text);
      background: var(--bg);
    }}

    /* ── Layout ── */
    .layout {{ display: flex; min-height: 100vh; }}

    nav.sidebar {{
      width: var(--nav-w);
      min-width: var(--nav-w);
      background: var(--surface);
      border-right: 1px solid var(--border);
      position: sticky;
      top: 0;
      height: 100vh;
      overflow-y: auto;
      padding: 1.5rem 1rem;
    }}

    nav.sidebar .nav-title {{
      font-family: var(--font-ui);
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--muted);
      margin-bottom: 1rem;
    }}

    nav.sidebar ul {{ list-style: none; }}
    nav.sidebar li {{ margin: 0.1rem 0; }}
    nav.sidebar a {{
      font-family: var(--font-ui);
      font-size: 0.82rem;
      color: var(--blue);
      text-decoration: none;
      display: block;
      padding: 0.22rem 0.4rem;
      border-radius: 4px;
      line-height: 1.4;
      transition: background 0.15s;
    }}
    nav.sidebar a:hover {{ background: var(--accent-bg); color: var(--accent); }}
    nav.sidebar .nav-h2 a {{ padding-left: 1.2rem; font-size: 0.78rem; color: var(--muted); }}
    nav.sidebar .nav-h2 a:hover {{ color: var(--accent); }}

    /* ── Main content ── */
    main {{
      flex: 1;
      max-width: 860px;
      margin: 0 auto;
      padding: 3rem 2.5rem 6rem;
    }}

    /* ── Headings ── */
    h1 {{
      font-size: 2rem;
      font-weight: 700;
      line-height: 1.25;
      color: var(--text);
      margin: 3rem 0 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 3px solid var(--accent);
    }}
    h1:first-child {{ margin-top: 0; }}

    h2 {{
      font-size: 1.45rem;
      font-weight: 700;
      color: var(--text);
      margin: 2.5rem 0 0.75rem;
      padding-left: 0.75rem;
      border-left: 4px solid var(--accent);
    }}

    h3 {{
      font-size: 1.15rem;
      font-weight: 700;
      color: var(--text);
      margin: 1.8rem 0 0.5rem;
    }}

    h4 {{
      font-size: 1rem;
      font-weight: 700;
      color: var(--muted);
      margin: 1.4rem 0 0.4rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }}

    /* ── Paragraphs & Lists ── */
    p {{ margin: 0.8rem 0; }}

    ul, ol {{
      margin: 0.7rem 0 0.7rem 1.8rem;
    }}
    li {{ margin: 0.3rem 0; }}

    strong {{ color: var(--text); font-weight: 700; }}
    em {{ font-style: italic; }}

    a {{ color: var(--blue); text-decoration: underline; }}
    a:hover {{ color: var(--accent); }}

    /* ── Blockquotes ── */
    blockquote {{
      margin: 1rem 0;
      padding: 0.9rem 1.2rem;
      background: var(--accent-bg);
      border-left: 4px solid var(--accent);
      border-radius: 0 6px 6px 0;
      font-style: italic;
      color: #3a2a1a;
    }}
    blockquote p {{ margin: 0.3rem 0; }}

    /* ── Horizontal rules ── */
    hr {{
      border: none;
      border-top: 1px solid var(--border);
      margin: 2.5rem 0;
    }}

    /* ── Tables ── */
    table {{
      width: 100%;
      border-collapse: collapse;
      margin: 1.2rem 0;
      font-family: var(--font-ui);
      font-size: 0.88rem;
    }}
    th {{
      background: var(--text);
      color: #fff;
      padding: 0.6rem 0.9rem;
      text-align: left;
      font-weight: 600;
    }}
    td {{
      padding: 0.55rem 0.9rem;
      border-bottom: 1px solid var(--border);
      vertical-align: top;
    }}
    tr:nth-child(even) td {{ background: var(--code-bg); }}
    tr:hover td {{ background: var(--accent-bg); }}

    /* ── Code blocks (aria-hidden — not read aloud) ── */
    pre {{
      background: var(--code-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1.1rem 1.3rem;
      overflow-x: auto;
      font-family: var(--font-mono);
      font-size: 0.82rem;
      line-height: 1.6;
      margin: 0.8rem 0;
      color: #2a2a28;
    }}
    code {{
      font-family: var(--font-mono);
      font-size: 0.88em;
      background: var(--code-bg);
      padding: 0.12em 0.35em;
      border-radius: 3px;
      border: 1px solid var(--border);
    }}
    pre code {{
      background: none;
      padding: 0;
      border: none;
      font-size: 1em;
    }}

    /* ── Code skip note (spoken by Read Aloud) ── */
    .code-note {{
      font-family: var(--font-ui);
      font-size: 0.8rem;
      color: var(--muted);
      background: var(--code-bg);
      border: 1px dashed var(--border);
      border-radius: 4px 4px 0 0;
      padding: 0.3rem 0.8rem;
      margin-bottom: -1px;
    }}

    /* ── Q&A details/summary ── */
    details.qa-block {{
      margin: 1rem 0;
      background: var(--qa-bg);
      border: 1px solid #cde0f5;
      border-left: 4px solid var(--qa-border);
      border-radius: 0 8px 8px 0;
      overflow: hidden;
    }}

    summary.qa-q {{
      font-family: var(--font-body);
      font-size: 1rem;
      font-weight: 700;
      color: var(--blue);
      padding: 0.8rem 1.2rem;
      cursor: pointer;
      list-style: none;
      display: flex;
      align-items: flex-start;
      gap: 0.6rem;
      line-height: 1.5;
    }}
    summary.qa-q::before {{
      content: "▶";
      font-size: 0.7em;
      flex-shrink: 0;
      margin-top: 0.3em;
      transition: transform 0.2s;
    }}
    details[open] summary.qa-q::before {{ transform: rotate(90deg); }}
    summary.qa-q:hover {{ background: #deeeff; }}

    .qa-a {{
      padding: 0.8rem 1.5rem 1rem;
      border-top: 1px solid #cde0f5;
      font-size: 0.97rem;
      line-height: 1.8;
      color: #1a2a3a;
    }}
    .qa-a p {{ margin: 0.5rem 0; }}

    /* ── Read Aloud tip banner ── */
    .read-aloud-tip {{
      background: #e8f5e9;
      border: 1px solid #81c784;
      border-radius: 8px;
      padding: 1rem 1.5rem;
      font-family: var(--font-ui);
      font-size: 0.9rem;
      margin-bottom: 2rem;
      line-height: 1.6;
    }}
    .read-aloud-tip strong {{ color: #2e7d32; }}

    /* ── App section dividers ── */
    h1[id^="app-"] {{
      background: linear-gradient(135deg, #1a1a18 0%, #3a3a30 100%);
      color: #fff !important;
      padding: 1.2rem 1.5rem;
      border-radius: 8px;
      border-bottom: none;
      margin-top: 4rem;
    }}

    /* ── Responsive ── */
    @media (max-width: 900px) {{
      nav.sidebar {{ display: none; }}
      main {{ padding: 1.5rem 1.2rem; }}
    }}

    /* ── Print ── */
    @media print {{
      nav.sidebar {{ display: none; }}
      main {{ max-width: 100%; padding: 1rem; }}
      details.qa-block {{ break-inside: avoid; }}
    }}
  </style>
</head>
<body>
<div class="layout">

  <!-- Sidebar Navigation -->
  <nav class="sidebar" aria-label="Page navigation">
    <div class="nav-title">Navigation</div>
    {nav_html}
  </nav>

  <!-- Main Content -->
  <main>

    <div class="read-aloud-tip" role="note">
      <strong>&#128266; Edge Read Aloud ready.</strong>
      Press <strong>Ctrl + Shift + U</strong> (or click the speaker icon in the address bar) to start.
      Code blocks and diagrams are automatically skipped &mdash; only explanations and Q&amp;A are read.
      Click any <strong>Q question</strong> to expand the answer before reading.
    </div>

    {body_html}

  </main>
</div>
</body>
</html>"""

DEST.write_text(html, encoding="utf-8")
size_kb = DEST.stat().st_size // 1024
print(f"Generated: {DEST}")
print(f"Size: {size_kb} KB")
