"""
Step-by-step individual HTML doc builder.
Each topic = one self-contained HTML file with full styling + sidebar nav.
Run: python build_docs.py
"""

import re, markdown
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

BASE   = Path(__file__).parent.parent
DOCS   = BASE / "docs"
DOCS.mkdir(exist_ok=True)
MD_EXT = ["fenced_code", "tables", "toc", "attr_list", "def_list"]

# ── shared CSS ─────────────────────────────────────────────────────────────
CSS = """
:root{--bg:#fff;--text:#1a1a2e;--accent:#0070f3;--code:#f4f6f8;--border:#e1e4e8;--nav:#f6f8fa;}
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:Georgia,'Times New Roman',serif;font-size:17px;line-height:1.8;
     color:var(--text);background:var(--bg);display:flex;min-height:100vh;}
/* ---- NAV ---- */
nav{width:260px;min-width:220px;background:var(--nav);border-right:1px solid var(--border);
    position:sticky;top:0;height:100vh;overflow-y:auto;padding:20px 14px;flex-shrink:0;}
nav .back-link{display:block;font-family:sans-serif;font-size:12px;color:var(--accent);
               margin-bottom:14px;text-decoration:none;}
nav .back-link:hover{text-decoration:underline;}
nav h3{font-family:sans-serif;font-size:11px;text-transform:uppercase;letter-spacing:.08em;
       color:#888;margin-bottom:8px;}
nav ul{list-style:none;}
nav li{margin:3px 0;}
nav a{font-family:sans-serif;font-size:13px;color:#444;text-decoration:none;
      display:block;padding:4px 8px;border-radius:4px;line-height:1.4;}
nav a:hover{background:#e0e8ff;color:var(--accent);}
nav a.h3{padding-left:20px;font-size:12px;color:#666;}
nav a.h4{padding-left:34px;font-size:11px;color:#888;}
/* ---- MAIN ---- */
main{flex:1;padding:48px 60px;max-width:960px;}
.doc-header{margin-bottom:40px;padding-bottom:20px;border-bottom:3px solid var(--accent);}
.doc-header h1{font-size:2.1em;color:#0a192f;}
.doc-header .subtitle{font-family:sans-serif;color:#555;margin-top:6px;font-size:.95em;}
.doc-header .badges span{display:inline-block;font-family:sans-serif;font-size:12px;
  padding:3px 10px;border-radius:12px;margin:8px 4px 0 0;font-weight:600;}
.badge-free{background:#d4edda;color:#155724;}
.badge-paid{background:#fff3cd;color:#856404;}
.badge-local{background:#cce5ff;color:#004085;}
/* ---- CONTENT ---- */
section{margin-bottom:56px;}
h2{font-size:1.6em;color:#0a192f;margin:2em 0 .6em;padding-bottom:.3em;border-bottom:2px solid var(--border);}
h3{font-size:1.25em;color:#0a192f;margin:1.6em 0 .4em;}
h4{font-size:1.05em;color:#0a192f;margin:1.3em 0 .3em;}
p{margin:.6em 0;}
ul,ol{margin:.5em 0 .5em 1.5em;}li{margin:.25em 0;}
strong{color:#0a192f;}
code{font-family:'Fira Code',Consolas,monospace;background:var(--code);
     padding:2px 6px;border-radius:3px;font-size:.87em;}
pre{background:var(--code);border:1px solid var(--border);border-left:4px solid var(--accent);
    border-radius:6px;padding:18px;overflow-x:auto;margin:1em 0;}
pre code{background:none;padding:0;font-size:.84em;line-height:1.5;}
table{border-collapse:collapse;width:100%;margin:1em 0;font-family:sans-serif;font-size:.9em;}
th,td{border:1px solid var(--border);padding:9px 13px;text-align:left;vertical-align:top;}
th{background:#e8f0fe;font-weight:700;color:#0a192f;}
tr:nth-child(even) td{background:#f9f9f9;}
blockquote{border-left:4px solid var(--accent);padding:10px 18px;background:#f0f4ff;
           border-radius:0 6px 6px 0;color:#333;margin:1em 0;}
/* ---- Q&A ---- */
details{border:1px solid var(--border);border-radius:8px;margin:.8em 0;background:#fafafa;}
details[open]{background:#fff;box-shadow:0 2px 8px rgba(0,0,0,.06);}
summary.qa-q{cursor:pointer;padding:13px 16px;font-weight:700;color:#0a192f;
             list-style:none;display:flex;align-items:flex-start;gap:10px;line-height:1.5;}
summary.qa-q::before{content:"Q";background:var(--accent);color:#fff;padding:2px 8px;
                     border-radius:50%;font-size:.78em;font-family:sans-serif;flex-shrink:0;margin-top:2px;}
.qa-a{padding:14px 18px;border-top:1px solid #eee;}
/* ---- callout boxes ---- */
.tip{background:#e6f9f0;border-left:4px solid #28a745;padding:12px 16px;
     border-radius:0 6px 6px 0;margin:1em 0;}
.warn{background:#fff8e1;border-left:4px solid #ffc107;padding:12px 16px;
      border-radius:0 6px 6px 0;margin:1em 0;}
a{color:var(--accent);}
hr{border:none;border-top:1px solid var(--border);margin:2em 0;}
"""

# ── helpers ────────────────────────────────────────────────────────────────
def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")

def wrap_qa(text: str) -> str:
    lines, out = text.splitlines(), []
    in_q, in_a, q_buf, a_buf = False, False, [], []
    def flush():
        nonlocal in_q, in_a
        if q_buf:
            q_md = " ".join(q_buf)
            a_md = "\n".join(a_buf)
            q_plain = re.sub(r"\*\*Q\d*[:.)] ?","",q_md).strip("* ")
            a_html  = markdown.markdown(a_md, extensions=MD_EXT) if a_md else ""
            out.append(
                f'<details open><summary class="qa-q">{q_plain}</summary>'
                f'<div class="qa-a">{a_html}</div></details>')
        q_buf.clear(); a_buf.clear()
        in_q = in_a = False
    for ln in lines:
        if re.match(r"\*\*Q\d*[:.)]", ln):
            flush(); in_q=True; in_a=False
            q_buf.append(re.sub(r"\*\*Q\d*[:.)] ?","",ln).strip("* "))
        elif re.match(r"\*\*A\d*[:.)]", ln):
            in_q=False; in_a=True
            a_buf.append(re.sub(r"\*\*A\d*[:.)] ?","",ln).strip("* "))
        elif in_a: a_buf.append(ln)
        elif in_q: q_buf.append(ln)
        else: flush(); out.append(ln)
    flush()
    return "\n".join(out)

def to_html(md_text: str) -> str:
    return markdown.markdown(wrap_qa(md_text), extensions=MD_EXT)

def build_sidebar(sections: list[tuple[str,str,str]]) -> str:
    items = ""
    for level, sid, title in sections:
        cls = "h3" if level == 3 else ("h4" if level == 4 else "")
        items += f'<li><a href="#{sid}" class="{cls}">{title}</a></li>\n'
    return items

def build_html(title: str, subtitle: str, badges: list[str], body: str,
               sections: list, prev_link: str = "", next_link: str = "") -> str:
    badge_html = "".join(
        f'<span class="badge-{"free" if "free" in b.lower() else "paid" if "paid" in b.lower() else "local"}">{b}</span>'
        for b in badges)
    nav_items = build_sidebar(sections)
    nav_links  = ""
    if prev_link: nav_links += f'<a class="back-link" href="{prev_link[0]}">← {prev_link[1]}</a>'
    if next_link: nav_links += f'<a class="back-link" href="{next_link[0]}">{next_link[1]} →</a>'
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} – AI Libraries Guide</title>
<style>{CSS}</style>
</head>
<body>
<nav>
  <a class="back-link" href="index.html">⬅ All Guides</a>
  {nav_links}
  <h3>Contents</h3>
  <ul>{nav_items}</ul>
</nav>
<main>
  <div class="doc-header">
    <h1>{title}</h1>
    <p class="subtitle">{subtitle}</p>
    <div class="badges">{badge_html}</div>
  </div>
  {body}
</main>
</body>
</html>"""

# ── extract section from markdown file ─────────────────────────────────────
def extract_section(path: Path, start_heading: str, stop_headings: list[str] = None) -> str:
    """Extract markdown from one heading to the next same-level heading."""
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    capturing, out, start_lvl = False, [], 0
    start_pat = re.compile(r"^(#{1,4})\s+" + re.escape(start_heading) + r"\s*$")
    for ln in lines:
        if not capturing:
            m = start_pat.match(ln)
            if m:
                capturing = True
                start_lvl = len(m.group(1))
                out.append(ln)
        else:
            m = re.match(r"^(#{1,4})\s+", ln)
            if m:
                lvl = len(m.group(1))
                if lvl <= start_lvl:
                    # check if it's a stop signal
                    heading_text = ln.lstrip("#").strip()
                    if stop_headings and any(s in heading_text for s in stop_headings):
                        break
                    if lvl < start_lvl:
                        break
                    if lvl == start_lvl and not ln.strip().startswith("#"*start_lvl + " " + start_heading):
                        break
            out.append(ln)
    return "\n".join(out)

def extract_between(path: Path, start_heading: str, end_heading: str) -> str:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    capturing, out = False, []
    for ln in lines:
        if not capturing:
            if re.match(r"^#{1,4}\s+" + re.escape(start_heading), ln):
                capturing = True
                out.append(ln)
        else:
            if end_heading and re.match(r"^#{1,4}\s+" + re.escape(end_heading), ln):
                break
            out.append(ln)
    return "\n".join(out)

def full_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def parse_toc(html_body: str) -> list[tuple[str,str,str]]:
    """Build sidebar TOC from h2/h3/h4 tags in rendered HTML."""
    toc = []
    for m in re.finditer(r"<h([234])[^>]*id=\"([^\"]+)\"[^>]*>(.*?)</h\1>", html_body, re.S):
        lvl, sid, raw_title = int(m.group(1)), m.group(2), m.group(3)
        title = re.sub(r"<[^>]+>", "", raw_title).strip()
        toc.append((lvl, sid, title))
    return toc

def add_ids(html_body: str) -> str:
    """Add id= to h2/h3/h4 that don't have one."""
    def replacer(m):
        tag, attrs, content = m.group(1), m.group(2), m.group(3)
        plain = re.sub(r"<[^>]+>", "", content).strip()
        sid = slug(plain)
        if 'id=' in attrs:
            return m.group(0)
        new_attrs = f' id="{sid}"' + (f" {attrs.strip()}" if attrs.strip() else "")
        return f'<{tag}{new_attrs}>{content}</{tag}>'
    return re.sub(r"<(h[234])((?:\s[^>]*)?)?>(.*?)</h[234]>", replacer, html_body, flags=re.S)

# ── document definitions ────────────────────────────────────────────────────
LIB_DOCS   = BASE / "lib-docs"
PART1_EXP  = BASE / "content" / "part1-expanded.md"
PART2_EXP  = BASE / "content" / "part2-expanded.md"

DOCS_DEF = [
    # (filename, title, subtitle, badges, source_file_in_lib-docs)
    ("01-langchain.html",       "LangChain",               "The most popular LLM application framework — chains, agents, RAG, memory",     ["Free Tier","Paid","LangSmith Tracing"],       "01-langchain.md"),
    ("02-langgraph.html",       "LangGraph",               "Stateful multi-actor graph framework — cycles, checkpoints, human-in-loop",    ["Free","Checkpointing","Human-in-Loop"],       "02-langgraph.md"),
    ("03-crewai.html",          "CrewAI",                  "Role-based multi-agent framework with crews, tasks, and tools",                ["Free","Paid Enterprise"],                     "03-crewai.md"),
    ("04-autogen.html",         "AutoGen",                 "Microsoft's multi-agent conversational framework with code execution",          ["Free (MIT)","Local Models"],                  "04-autogen.md"),
    ("05-llamaindex.html",      "LlamaIndex",              "Data framework for connecting LLMs to external data sources",                  ["Free","Paid LlamaCloud"],                     "05-llamaindex.md"),
    ("06-haystack.html",        "Haystack",                "deepset's end-to-end NLP pipeline framework for production RAG",               ["Free (Apache 2.0)","deepset Cloud"],          "06-haystack.md"),
    ("07-semantic-kernel.html", "Semantic Kernel",         "Microsoft's SDK for integrating LLMs into .NET, Python, and Java apps",        ["Free (MIT)","Azure OpenAI"],                  "07-semantic-kernel.md"),
    ("08-dspy.html",            "DSPy",                    "Declarative Self-improving Language Programs — compile, not prompt",           ["Free (MIT)","Local Models"],                  "08-dspy.md"),
    ("09-mcp-acp.html",         "MCP & ACP",               "Model Context Protocol + Agent Communication Protocol — full reference",       ["Free (Open Standard)"],                       "09-mcp-acp.md"),
    ("10-other-libs.html",      "Other Libraries",         "Pydantic AI · Smolagents · Instructor · Agno · Marvin · Guidance · LangSmith", ["Mixed Free/Paid"],                            "10-other-libs.md"),
    ("11-app-improvements.html","App-by-App Improvements", "LangGraph · CrewAI · AutoGen patterns applied to all 6 real projects",         ["Runnable Code","All 6 Apps"],                 None),
    ("12-sdlc-apps.html",       "SDLC Automation Apps",    "20 AI-powered app blueprints for the software development lifecycle",          ["Runnable Skeletons","MCP · ACP · LangGraph"], None),
    ("13-resources.html",       "Resources",               "Free & paid courses, APIs, vector DBs, monitoring tools, communities",         ["Free Resources","Paid Resources"],            "13-resources.md"),
    ("14-code-recipes.html",    "Code Recipes",            "15 complete runnable Python recipes — copy, paste, run",                       ["Copy-Paste Ready","GitHub Copilot Free"],     "14-recipes.md"),
    ("15-llms-guide.html",      "Free & Paid LLMs",        "Complete LLM catalog · setup guides · fine-tuning · RAG vs fine-tune · 20 Q&As", ["Free Tier","Paid","Local Models","Fine-Tuning"], "15-llms-guide.md"),
]

# ── section extractors ──────────────────────────────────────────────────────
def get_content(source_file) -> str:
    # None = special cases using expanded files
    if source_file is None:
        return ""
    path = LIB_DOCS / source_file
    if path.exists():
        return path.read_text(encoding="utf-8")
    return f"# {source_file}\n\n> Content not found at {path}\n"

# ── build one doc ────────────────────────────────────────────────────────────
def build_doc(idx: int, fname: str, title: str, subtitle: str,
              badges: list, source_file) -> Path:
    print(f"[{idx:02d}] Building {fname} ...")
    # Special cases: app improvements and sdlc apps use PART expanded files
    if fname == "11-app-improvements.html":
        md_text = full_file(PART1_EXP) if PART1_EXP.exists() else f"# {title}\n\n> Content coming soon.\n"
    elif fname == "12-sdlc-apps.html":
        md_text = full_file(PART2_EXP) if PART2_EXP.exists() else f"# {title}\n\n> Content coming soon.\n"
    else:
        md_text = get_content(source_file)
    if not md_text.strip():
        md_text = f"# {title}\n\n> Content coming soon.\n"

    body_html = add_ids(to_html(md_text))
    toc       = parse_toc(body_html)

    # prev / next links
    prev_lnk = (DOCS_DEF[idx-2][0], DOCS_DEF[idx-2][1]) if idx > 1 else None
    next_lnk = (DOCS_DEF[idx][0],   DOCS_DEF[idx][1])   if idx < len(DOCS_DEF) else None

    html = build_html(title, subtitle, badges, body_html, toc, prev_lnk, next_lnk)
    out  = DOCS / fname
    out.write_text(html, encoding="utf-8")
    kb = out.stat().st_size // 1024
    print(f"[{idx:02d}] ✓ {fname} ({kb} KB, {len(toc)} sections in TOC)")
    return out

# ── build index page ─────────────────────────────────────────────────────────
def build_index():
    print("[00] Building index.html ...")
    cards = ""
    for i, (fname, title, subtitle, badges, _) in enumerate(DOCS_DEF, 1):
        badge_html = " ".join(
            f'<span class="badge-{"free" if "free" in b.lower() else "paid" if "paid" in b.lower() else "local"}">{b}</span>'
            for b in badges[:2])
        cards += f"""
        <a class="card" href="{fname}">
          <span class="card-num">{i:02d}</span>
          <div>
            <h3>{title}</h3>
            <p>{subtitle}</p>
            <div class="badges">{badge_html}</div>
          </div>
        </a>"""
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AI Libraries & Frameworks – Complete Guide</title>
<style>
{CSS}
body{{display:block;padding:48px 64px;max-width:1000px;margin:0 auto;}}
.hero{{margin-bottom:48px;border-bottom:3px solid var(--accent);padding-bottom:24px;}}
.hero h1{{font-size:2.4em;color:#0a192f;}}
.hero p{{color:#555;font-size:1.05em;margin-top:8px;}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:20px;}}
.card{{display:flex;gap:16px;padding:20px;border:1px solid var(--border);border-radius:10px;
       background:#fff;text-decoration:none;color:inherit;transition:box-shadow .2s,transform .15s;}}
.card:hover{{box-shadow:0 4px 16px rgba(0,112,243,.15);transform:translateY(-2px);}}
.card-num{{font-family:sans-serif;font-size:1.4em;font-weight:700;color:var(--accent);
           min-width:36px;padding-top:2px;}}
.card h3{{font-size:1.05em;color:#0a192f;margin-bottom:4px;}}
.card p{{font-size:.88em;color:#555;margin:0 0 6px;font-family:sans-serif;line-height:1.4;}}
.badges span{{display:inline-block;font-family:sans-serif;font-size:11px;padding:2px 8px;
              border-radius:10px;margin:2px 2px 0 0;font-weight:600;}}
.badge-free{{background:#d4edda;color:#155724;}}
.badge-paid{{background:#fff3cd;color:#856404;}}
.badge-local{{background:#cce5ff;color:#004085;}}
</style>
</head>
<body>
<div class="hero">
  <h1>AI Libraries &amp; Frameworks</h1>
  <p>Complete developer reference — {len(DOCS_DEF)} individual guides covering every library, app pattern, and runnable recipe.</p>
</div>
<div class="grid">{cards}</div>
</body>
</html>"""
    out = DOCS / "index.html"
    out.write_text(html, encoding="utf-8")
    print(f"[00] ✓ index.html")

# ── main ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    build_index()
    for i, (fname, title, subtitle, badges, source_file) in enumerate(DOCS_DEF, 1):
        build_doc(i, fname, title, subtitle, badges, source_file)
    print(f"\n✅ All {len(DOCS_DEF)+1} files written to docs/")
