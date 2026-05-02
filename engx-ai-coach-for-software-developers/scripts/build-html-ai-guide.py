"""
Map-Reduce HTML builder for AI-LIBRARIES-GUIDE.md
MAP:  split by H1 section → convert each to HTML in parallel (ThreadPoolExecutor)
REDUCE: combine all HTML sections + nav into one file
"""

import re
import markdown
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SRC  = Path(__file__).parent.parent / "content" / "ai-libraries-guide.md"
DEST = Path(__file__).parent.parent / "docs" / "ai-libraries-guide.html"

MD_EXTS = ["fenced_code", "tables", "toc", "attr_list", "def_list", "admonition"]

# ── helpers ────────────────────────────────────────────────────────────────
def wrap_qa(text: str) -> str:
    """Wrap **Q:** / **A:** blocks into <details open> accordions."""
    lines, out, in_q, in_a, q_buf, a_buf = text.splitlines(), [], False, False, [], []

    def flush():
        nonlocal in_q, in_a
        if q_buf:
            q_html = markdown.markdown(" ".join(q_buf), extensions=MD_EXTS)
            a_html = markdown.markdown("\n".join(a_buf), extensions=MD_EXTS) if a_buf else ""
            q_text = re.sub(r"<[^>]+>", "", q_html).strip()
            out.append(
                f'<details open><summary class="qa-q">{q_text}</summary>'
                f'<div class="qa-a">{a_html}</div></details>'
            )
        q_buf.clear(); a_buf.clear()
        in_q = in_a = False

    for line in lines:
        if re.match(r"\*\*Q\d*[:.)]", line) or re.match(r"\*\*Q:", line):
            flush()
            in_q, in_a = True, False
            q_buf.append(re.sub(r"\*\*Q\d*[:.)] ?", "", line).strip("* "))
        elif re.match(r"\*\*A\d*[:.)]", line) or re.match(r"\*\*A:", line):
            in_q, in_a = False, True
            a_buf.append(re.sub(r"\*\*A\d*[:.)] ?", "", line).strip("* "))
        elif in_a:
            a_buf.append(line)
        elif in_q:
            q_buf.append(line)
        else:
            flush()
            out.append(line)
    flush()
    return "\n".join(out)


def md_to_html(section_text: str) -> str:
    """Convert one section of markdown to HTML (runs in worker thread)."""
    processed = wrap_qa(section_text)
    return markdown.markdown(processed, extensions=MD_EXTS)


# ── MAP: split into sections ───────────────────────────────────────────────
def split_sections(raw: str) -> list[tuple[str, str]]:
    """Return list of (anchor_id, full_section_text) split on # H1 headings."""
    parts = re.split(r"(?=^# )", raw, flags=re.MULTILINE)
    sections = []
    for part in parts:
        if not part.strip():
            continue
        first_line = part.splitlines()[0]
        title = re.sub(r"^#+\s*", "", first_line)
        anchor = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
        sections.append((anchor, title, part))
    return sections


# ── REDUCE: combine HTML fragments ────────────────────────────────────────
def build_nav(sections: list) -> str:
    items = "\n".join(
        f'  <li><a href="#{a}">{t}</a></li>' for a, t, _ in sections
    )
    return f"<nav><ul>\n{items}\n</ul></nav>"


def build_page(nav_html: str, body_parts: list[tuple[str, str, str]]) -> str:
    sections_html = ""
    for anchor, title, html in body_parts:
        sections_html += f'<section id="{anchor}">\n{html}\n</section>\n'

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AI Libraries Guide</title>
<style>
  :root {{
    --bg: #fff; --text: #1a1a2e; --accent: #0070f3;
    --code-bg: #f4f4f4; --nav-bg: #f8f9fa;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: Georgia, 'Times New Roman', serif;
    font-size: 17px; line-height: 1.75;
    color: var(--text); background: var(--bg);
    display: flex; min-height: 100vh;
  }}
  nav {{
    width: 270px; min-width: 220px; max-width: 300px;
    background: var(--nav-bg); padding: 24px 16px;
    position: sticky; top: 0; height: 100vh;
    overflow-y: auto; border-right: 1px solid #e0e0e0;
    flex-shrink: 0;
  }}
  nav ul {{ list-style: none; }}
  nav li {{ margin: 6px 0; }}
  nav a {{
    text-decoration: none; color: #444;
    font-family: sans-serif; font-size: 13px;
    line-height: 1.4; display: block;
    padding: 3px 6px; border-radius: 4px;
    transition: background .15s;
  }}
  nav a:hover {{ background: #e0e8ff; color: var(--accent); }}
  main {{
    flex: 1; padding: 48px 56px;
    max-width: 900px;
  }}
  section {{ margin-bottom: 60px; }}
  h1 {{ font-size: 2em; color: #0a192f; margin: 0 0 .5em; border-bottom: 3px solid var(--accent); padding-bottom: .3em; }}
  h2 {{ font-size: 1.5em; color: #0a192f; margin: 1.8em 0 .5em; border-bottom: 1px solid #ddd; padding-bottom: .2em; }}
  h3 {{ font-size: 1.2em; color: #0a192f; margin: 1.4em 0 .4em; }}
  h4 {{ font-size: 1.05em; margin: 1.2em 0 .3em; }}
  p {{ margin: .6em 0; }}
  ul, ol {{ margin: .5em 0 .5em 1.5em; }}
  li {{ margin: .2em 0; }}
  code {{
    font-family: 'Fira Code', Consolas, monospace;
    background: var(--code-bg); padding: 2px 6px;
    border-radius: 3px; font-size: .88em;
  }}
  pre {{
    background: var(--code-bg); padding: 18px;
    border-radius: 6px; overflow-x: auto;
    margin: 1em 0; border-left: 4px solid var(--accent);
  }}
  pre code {{ background: none; padding: 0; font-size: .85em; }}
  table {{ border-collapse: collapse; width: 100%; margin: 1em 0; font-size: .9em; }}
  th, td {{ border: 1px solid #ddd; padding: 8px 12px; text-align: left; }}
  th {{ background: #e8f0fe; font-weight: bold; }}
  tr:nth-child(even) td {{ background: #f9f9f9; }}
  blockquote {{
    border-left: 4px solid var(--accent);
    padding: 8px 16px; color: #555; margin: 1em 0;
    background: #f0f4ff; border-radius: 0 4px 4px 0;
  }}
  details {{
    border: 1px solid #ddd; border-radius: 6px;
    margin: .8em 0; padding: 0;
    background: #fafafa;
  }}
  details[open] {{ background: #fff; }}
  summary.qa-q {{
    cursor: pointer; padding: 12px 16px;
    font-weight: bold; color: #0a192f;
    list-style: none; display: flex; align-items: center; gap: 8px;
  }}
  summary.qa-q::before {{ content: "Q"; background: var(--accent); color: #fff; padding: 1px 7px; border-radius: 50%; font-size: .8em; font-family: sans-serif; flex-shrink: 0; }}
  .qa-a {{ padding: 12px 16px; border-top: 1px solid #eee; }}
  a {{ color: var(--accent); }}
</style>
</head>
<body>
{nav_html}
<main>
{sections_html}
</main>
</body>
</html>"""


# ── main ──────────────────────────────────────────────────────────────────
def main():
    raw = SRC.read_text(encoding="utf-8")
    sections = split_sections(raw)
    print(f"[MAP]    Split into {len(sections)} sections")

    # MAP: parallel conversion
    results: dict[int, str] = {}
    with ThreadPoolExecutor(max_workers=min(8, len(sections))) as pool:
        futures = {pool.submit(md_to_html, text): (i, anchor, title)
                   for i, (anchor, title, text) in enumerate(sections)}
        for fut in as_completed(futures):
            i, anchor, title = futures[fut]
            results[i] = (anchor, title, fut.result())
            print(f"[MAP]    Done: {title[:60]}")

    # REDUCE: assemble in original order
    ordered = [results[i] for i in range(len(sections))]
    nav_html = build_nav(sections)
    html = build_page(nav_html, ordered)
    DEST.write_text(html, encoding="utf-8")

    kb = DEST.stat().st_size // 1024
    print(f"[REDUCE] Written: {DEST.name} ({kb} KB, {len(sections)} sections)")


if __name__ == "__main__":
    main()
