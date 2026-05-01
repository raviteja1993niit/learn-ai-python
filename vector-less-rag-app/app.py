"""
app.py — VectorLess RAG · ChatGPT-style UI
PageIndex · BM25 · No VectorDB · No Chunking · GitHub Copilot LLMs
"""
from __future__ import annotations

import os
import time
import altair as alt
import pandas as pd
import streamlit as st

from src.llm import MODELS_BY_PROVIDER, get_gh_cli_token
from src.rag import RAGPipeline

# ── Page config ───────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="DocChat — VectorLess RAG",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ══════════════════════════════════════════════════════════════════════════════
#  GLOBAL CSS  — ChatGPT-style dark theme
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("""
<style>
/* ── Base ── */
html, body, [data-testid="stAppViewContainer"] {
    background-color: #212121 !important;
    color: #ececec !important;
    font-family: "Söhne", ui-sans-serif, system-ui, -apple-system, sans-serif;
}
[data-testid="stSidebar"] {
    background-color: #171717 !important;
    border-right: 1px solid #2a2a2a;
}
[data-testid="stSidebar"] * { color: #ececec !important; }

/* ── Hide default Streamlit chrome ── */
#MainMenu, footer, header { visibility: hidden; }
[data-testid="stToolbar"] { display: none; }

/* ── Top bar ── */
.topbar {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 20px 10px;
    border-bottom: 1px solid #2a2a2a;
    margin-bottom: 0;
    background: #212121;
}
.topbar-title {
    font-size: 1.05rem;
    font-weight: 600;
    color: #ececec;
}
.topbar-badge {
    background: #2a2a2a;
    color: #9a9a9a;
    border-radius: 20px;
    padding: 2px 10px;
    font-size: 0.72rem;
    font-weight: 500;
    border: 1px solid #383838;
}
.model-pill {
    background: #10a37f22;
    color: #10a37f;
    border: 1px solid #10a37f44;
    border-radius: 20px;
    padding: 2px 10px;
    font-size: 0.72rem;
    font-weight: 600;
}

/* ── Chat messages ── */
.msg-row { display: flex; margin: 6px 0; padding: 0 20px; }
.msg-row.user  { justify-content: flex-end; }
.msg-row.assistant { justify-content: flex-start; }

.bubble {
    max-width: 72%;
    padding: 12px 16px;
    border-radius: 18px;
    font-size: 0.93rem;
    line-height: 1.6;
    word-wrap: break-word;
}
.bubble.user {
    background: #2f2f2f;
    color: #ececec;
    border-bottom-right-radius: 4px;
}
.bubble.assistant {
    background: #212121;
    color: #ececec;
    border-bottom-left-radius: 4px;
    border: 1px solid #2a2a2a;
}

/* ── Avatar ── */
.avatar {
    width: 32px; height: 32px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 0.85rem; font-weight: 700;
    flex-shrink: 0;
    margin-top: 4px;
}
.avatar.user { background: #5436DA; color: #fff; margin-left: 10px; }
.avatar.assistant { background: #10a37f; color: #fff; margin-right: 10px; }

/* ── Typing indicator ── */
.typing { display:flex; gap:5px; padding:14px 16px; }
.typing span {
    width:8px; height:8px; background:#9a9a9a;
    border-radius:50%; animation: bounce 1.2s infinite;
}
.typing span:nth-child(2){ animation-delay:.2s; }
.typing span:nth-child(3){ animation-delay:.4s; }
@keyframes bounce { 0%,80%,100%{transform:translateY(0)} 40%{transform:translateY(-8px)} }

/* ── Source footnotes ── */
.source-footnote {
    background: #2a2a2a;
    border-left: 3px solid #10a37f;
    border-radius: 0 8px 8px 0;
    padding: 8px 12px;
    font-size: 0.78rem;
    color: #9a9a9a;
    margin-top: 4px;
}

/* ── Welcome screen ── */
.welcome-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    margin-top: 24px;
}
.welcome-card {
    background: #2a2a2a;
    border: 1px solid #383838;
    border-radius: 12px;
    padding: 16px;
    cursor: pointer;
    transition: border-color .2s;
}
.welcome-card:hover { border-color: #10a37f; }
.welcome-card h4 { margin:0 0 4px; font-size:0.88rem; color:#ececec; }
.welcome-card p  { margin:0; font-size:0.78rem; color:#9a9a9a; }

/* ── Upload zone ── */
.upload-zone {
    border: 2px dashed #383838;
    border-radius: 16px;
    padding: 32px;
    text-align: center;
    margin: 24px auto;
    max-width: 480px;
    transition: border-color .2s;
}
.upload-zone:hover { border-color: #10a37f; }

/* ── Progress steps ── */
.step-row { display:flex; align-items:center; gap:10px; padding:6px 0; }
.step-icon { font-size:1.1rem; width:24px; text-align:center; }
.step-done   { color: #10a37f; }
.step-active { color: #ececec; }
.step-wait   { color: #505050; }

/* ── Stat chips ── */
.chip {
    display:inline-flex; align-items:center; gap:6px;
    background:#2a2a2a; border:1px solid #383838;
    border-radius:20px; padding:4px 12px;
    font-size:0.78rem; color:#ececec; margin:3px;
}

/* ── Sidebar nav item ── */
.nav-item {
    display:flex; align-items:center; gap:10px;
    padding:8px 12px; border-radius:8px;
    font-size:0.87rem; cursor:pointer;
    transition:background .15s; margin:2px 0;
}
.nav-item:hover { background:#2a2a2a; }
.nav-item.active { background:#2a2a2a; color:#10a37f !important; }

/* ── Inputs ── */
[data-testid="stTextInput"] input,
[data-testid="stTextArea"] textarea,
[data-testid="stSelectbox"] > div > div {
    background:#2a2a2a !important;
    border:1px solid #383838 !important;
    color:#ececec !important;
    border-radius:8px !important;
}

/* ── Fixed chat input at viewport bottom ── */
[data-testid="stBottom"] {
    position: fixed !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    background: #212121 !important;
    border-top: 1px solid #2a2a2a !important;
    z-index: 999 !important;
    padding: 10px 24px 14px !important;
}
[data-testid="stChatInput"] {
    background:#2f2f2f !important;
    border:1px solid #383838 !important;
    border-radius:16px !important;
    max-width: 860px !important;
    margin: 0 auto !important;
}
[data-testid="stChatInput"] textarea { background:transparent !important; color:#ececec !important; }

/* ── Scrollable chat message area ── */
.chat-scroll-area {
    overflow-y: auto;
    padding-bottom: 16px;
}

/* ── Extra bottom padding so last message isn't hidden ── */
[data-testid="stMain"] > div:first-child {
    padding-bottom: 90px !important;
}

/* ── Buttons ── */
.stButton > button {
    background:#2a2a2a !important;
    border:1px solid #383838 !important;
    color:#ececec !important;
    border-radius:8px !important;
    transition:background .15s, border-color .15s !important;
}
.stButton > button:hover {
    background:#383838 !important;
    border-color:#10a37f !important;
    color:#10a37f !important;
}
.btn-primary > button {
    background:#10a37f !important;
    border-color:#10a37f !important;
    color:#fff !important;
}
.btn-primary > button:hover { background:#0d8a6b !important; }

/* ── Expander ── */
[data-testid="stExpander"] {
    background:#1a1a1a !important;
    border:1px solid #2a2a2a !important;
    border-radius:10px !important;
}
/* ── Metrics ── */
[data-testid="stMetricValue"] { color:#10a37f !important; font-weight:700; }
[data-testid="stMetricLabel"] { color:#9a9a9a !important; }
/* ── Tabs ── */
[data-testid="stTabs"] [role="tablist"] { border-bottom:1px solid #2a2a2a; }
button[role="tab"] { color:#9a9a9a !important; background:transparent !important; }
button[role="tab"][aria-selected="true"] { color:#ececec !important; border-bottom:2px solid #10a37f !important; }
/* ── Scrollbar ── */
::-webkit-scrollbar { width:5px; }
::-webkit-scrollbar-track { background:#171717; }
::-webkit-scrollbar-thumb { background:#383838; border-radius:4px; }
/* ── Progress bar ── */
[data-testid="stProgress"] > div > div { background:#10a37f !important; }
/* ── Altair chart bg ── */
.vega-embed { background: transparent !important; }
</style>
""", unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════════════════
def user_bubble(text: str):
    st.markdown(f"""
<div class="msg-row user">
  <div class="bubble user">{text}</div>
  <div class="avatar user">U</div>
</div>""", unsafe_allow_html=True)


def assistant_bubble(text: str):
    # Use st.markdown for proper markdown rendering inside the chat
    with st.container():
        st.markdown(f"""
<div class="msg-row assistant">
  <div class="avatar assistant">AI</div>
  <div class="bubble assistant">
""", unsafe_allow_html=True)
        st.markdown(text)
        st.markdown("</div></div>", unsafe_allow_html=True)


def typing_indicator():
    return st.markdown("""
<div class="msg-row assistant">
  <div class="avatar assistant">AI</div>
  <div class="bubble assistant">
    <div class="typing"><span></span><span></span><span></span></div>
  </div>
</div>""", unsafe_allow_html=True)


def chip(icon: str, label: str):
    return f'<span class="chip">{icon} {label}</span>'


# ══════════════════════════════════════════════════════════════════════════════
#  SIDEBAR
# ══════════════════════════════════════════════════════════════════════════════
with st.sidebar:
    # Logo + title
    st.markdown("""
<div style="display:flex;align-items:center;gap:10px;padding:8px 4px 16px;">
  <div style="background:#10a37f;width:32px;height:32px;border-radius:8px;
              display:flex;align-items:center;justify-content:center;font-size:1rem;">🤖</div>
  <div>
    <div style="font-weight:700;font-size:0.95rem;">DocChat</div>
    <div style="font-size:0.72rem;color:#9a9a9a;">VectorLess RAG</div>
  </div>
</div>
""", unsafe_allow_html=True)

    # New chat button
    with st.container():
        st.markdown('<div class="btn-primary">', unsafe_allow_html=True)
        if st.button("＋  New Chat", use_container_width=True):
            for k in ["pipeline","file_key","chat_history","last_results","last_query"]:
                st.session_state.pop(k, None)
            st.rerun()
        st.markdown('</div>', unsafe_allow_html=True)

    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    # Active doc chip
    if "pipeline" in st.session_state:
        p = st.session_state["pipeline"]
        stats = p.stats
        st.markdown(f"""
<div style="background:#1a3a2f;border:1px solid #10a37f44;border-radius:10px;padding:10px 12px;margin-bottom:8px;">
  <div style="font-size:0.82rem;font-weight:600;color:#10a37f;margin-bottom:6px;">📄 {p.filename[:30]}</div>
  <div>
    {chip("📑", f"{stats.total_pages} pages")}
    {chip("📝", f"{stats.total_words:,} words")}
  </div>
  <div style="margin-top:4px;">
    {chip("⚡", f"Avg {stats.avg_words_per_page}w/page")}
    {chip("🗂️", ', '.join(stats.source_types))}
  </div>
</div>""", unsafe_allow_html=True)
        if st.button("🗑️ Clear Chat", use_container_width=True):
            st.session_state["pipeline"].clear_history()
            st.session_state["chat_history"] = []
            st.session_state["last_results"] = []
            st.session_state["last_query"] = ""
            st.toast("✅ Chat history cleared", icon="🗑️")
            st.rerun()

    st.divider()

    # Settings
    st.markdown("<div style='font-size:0.75rem;color:#9a9a9a;font-weight:600;letter-spacing:.08em;margin-bottom:6px;'>SETTINGS</div>", unsafe_allow_html=True)

    _auto_token = os.environ.get("GITHUB_TOKEN", "") or get_gh_cli_token()
    github_token = st.text_input("GitHub Token", value=_auto_token, type="password", label_visibility="collapsed",
                                  placeholder="GitHub Token (auto-detected)")
    if _auto_token and github_token == _auto_token:
        st.markdown("<div style='font-size:0.75rem;color:#10a37f;margin:-6px 0 6px;'>🔑 Token auto-detected</div>", unsafe_allow_html=True)
    elif not github_token:
        st.markdown("<div style='font-size:0.75rem;color:#e5534b;margin:-6px 0 6px;'>⚠️ Run: gh auth login</div>", unsafe_allow_html=True)

    provider = st.selectbox("Provider", list(MODELS_BY_PROVIDER.keys()),
                             index=list(MODELS_BY_PROVIDER.keys()).index("GitHub Copilot"),
                             label_visibility="collapsed")
    available_models = MODELS_BY_PROVIDER[provider]
    default_model = "claude-haiku-4.5" if "claude-haiku-4.5" in available_models else available_models[0]
    model = st.selectbox("Model", available_models,
                          index=available_models.index(default_model),
                          label_visibility="collapsed")
    top_k = st.slider("Pages to retrieve", 1, 10, 4, label_visibility="collapsed",
                       help="Top-K pages retrieved per query")
    st.caption(f"Top-K: {top_k} pages · {model}")

    st.divider()
    st.markdown("""
<div style="font-size:0.72rem;color:#505050;line-height:1.7;">
<b style="color:#9a9a9a">How it works</b><br>
1. Document → natural pages<br>
2. BM25 scores every page<br>
3. Top-K pages → LLM context<br>
4. Answer with page citations<br><br>
No VectorDB · No chunking · No GPU
</div>""", unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
#  FILE UPLOAD — with progress steps
# ══════════════════════════════════════════════════════════════════════════════
uploaded_file = st.file_uploader(
    "upload", type=["pdf","docx","xlsx","xls","csv","txt","md"],
    label_visibility="collapsed",
)

# Reset on file removal
if uploaded_file is None and "pipeline" in st.session_state:
    for k in ["pipeline","file_key","chat_history","last_results","last_query"]:
        st.session_state.pop(k, None)
    st.toast("📂 Document removed — ready for a new file", icon="ℹ️")
    st.rerun()

if uploaded_file:
    file_key = f"{uploaded_file.name}_{model}_{provider}"
    if st.session_state.get("file_key") != file_key:
        # ── Animated progress UI ────────────────────────────────────────────
        prog_container = st.container()
        with prog_container:
            st.markdown(f"""
<div style="background:#1a1a1a;border:1px solid #2a2a2a;border-radius:14px;padding:20px 24px;max-width:560px;margin:16px auto;">
  <div style="font-weight:600;font-size:0.92rem;margin-bottom:14px;">
    📂 Processing <span style="color:#10a37f">{uploaded_file.name}</span>
  </div>
</div>""", unsafe_allow_html=True)
            progress_bar = st.progress(0, text="Starting…")

            STEPS = [
                (0.15, "🔍", "Reading file…"),
                (0.40, "📑", "Parsing pages…"),
                (0.70, "🗂️", "Building PageIndex…"),
                (0.90, "⚡", "Optimising BM25…"),
                (1.00, "✅", "Ready!"),
            ]
            step_placeholder = st.empty()

            try:
                for pct, icon, msg in STEPS[:-1]:
                    progress_bar.progress(pct, text=msg)
                    step_placeholder.markdown(f"<div style='font-size:0.83rem;color:#9a9a9a;text-align:center;'>{icon} {msg}</div>", unsafe_allow_html=True)
                    time.sleep(0.25)

                pipeline = RAGPipeline(
                    filename=uploaded_file.name,
                    file_bytes=uploaded_file.getvalue(),
                    top_k=top_k, model=model,
                    github_token=github_token, provider=provider,
                )
                progress_bar.progress(1.0, text="✅ Ready!")
                step_placeholder.empty()
                prog_container.empty()  # remove progress UI

                st.session_state.update({
                    "pipeline": pipeline,
                    "file_key": file_key,
                    "chat_history": [],
                    "last_results": [],
                    "last_query": "",
                })
                stats = pipeline.stats
                st.toast(
                    f"✅ {stats.total_pages} pages · {stats.total_words:,} words indexed",
                    icon="📄",
                )

            except Exception as e:
                progress_bar.empty()
                step_placeholder.empty()
                st.toast(f"❌ Failed: {e}", icon="🚨")
                st.error(f"**Could not process document.**\n\n{e}")
                st.stop()
    else:
        pipeline = st.session_state["pipeline"]
        pipeline.top_k = top_k
        pipeline.model = model
        pipeline.github_token = github_token
        pipeline.provider = provider


# ══════════════════════════════════════════════════════════════════════════════
#  WELCOME / LANDING — no document loaded
# ══════════════════════════════════════════════════════════════════════════════
if "pipeline" not in st.session_state:
    st.markdown("""
<div style="max-width:640px;margin:48px auto 0;text-align:center;padding:0 20px;">
  <div style="font-size:2.8rem;">🤖</div>
  <h1 style="font-size:1.8rem;font-weight:700;margin:12px 0 6px;color:#ececec;">DocChat</h1>
  <p style="color:#9a9a9a;font-size:0.95rem;margin-bottom:28px;">
    Upload a document and chat with it — no VectorDB, no chunking, just PageIndex + BM25
  </p>
</div>""", unsafe_allow_html=True)

    # Upload prompt card
    st.markdown("""
<div class="upload-zone" style="max-width:480px;margin:0 auto 28px;">
  <div style="font-size:2rem;margin-bottom:10px;">📂</div>
  <div style="font-size:0.92rem;font-weight:600;color:#ececec;margin-bottom:6px;">Drop your document here</div>
  <div style="font-size:0.78rem;color:#9a9a9a;">PDF · Word · Excel · CSV · Text · Markdown</div>
</div>""", unsafe_allow_html=True)

    # Feature cards
    st.markdown("""
<div style="max-width:640px;margin:0 auto;">
<div class="welcome-grid">
  <div class="welcome-card">
    <h4>📑 PageIndex — No Chunking</h4>
    <p>Documents indexed as whole pages & sections. Zero context lost at arbitrary boundaries.</p>
  </div>
  <div class="welcome-card">
    <h4>⚡ BM25 Retrieval — No VectorDB</h4>
    <p>Instant lexical search over all pages. No embeddings, no GPU, no external service.</p>
  </div>
  <div class="welcome-card">
    <h4>💬 Multi-turn Chat</h4>
    <p>Follow-up questions use conversation history. Ask naturally, like ChatGPT.</p>
  </div>
  <div class="welcome-card">
    <h4>🤖 18 GitHub Copilot Models</h4>
    <p>GPT-5, Claude Opus/Sonnet, Grok — switch models anytime from the sidebar.</p>
  </div>
</div>
</div>""", unsafe_allow_html=True)
    st.stop()


# ══════════════════════════════════════════════════════════════════════════════
#  MAIN — document loaded
# ══════════════════════════════════════════════════════════════════════════════
pipeline: RAGPipeline = st.session_state["pipeline"]

# Top bar
st.markdown(f"""
<div class="topbar">
  <span style="font-size:1.3rem;">📄</span>
  <span class="topbar-title">{pipeline.filename}</span>
  <span class="topbar-badge">{pipeline.stats.total_pages} pages · {pipeline.stats.total_words:,} words</span>
  <span class="model-pill">🤖 {model}</span>
</div>
""", unsafe_allow_html=True)

tab_chat, tab_browser, tab_how = st.tabs(["💬 Chat", "📖 Document Browser", "ℹ️ How It Works"])

# ══════════════════════════════════════════════════════════════════════════════
#  TAB 1 — CHAT
# ══════════════════════════════════════════════════════════════════════════════
with tab_chat:
    chat_col, src_col = st.columns([3, 2])

    with chat_col:
        # ── Welcome hint if no messages ───────────────────────────────────────
        if not st.session_state.get("chat_history"):
            st.markdown(f"""
<div style="text-align:center;padding:40px 20px;color:#505050;">
  <div style="font-size:2rem;margin-bottom:10px;">💬</div>
  <div style="font-size:0.92rem;color:#9a9a9a;">Ask anything about <b style="color:#ececec">{pipeline.filename}</b></div>
  <div style="font-size:0.78rem;margin-top:6px;">Multi-turn supported — follow up freely</div>
</div>""", unsafe_allow_html=True)

        # ── Render conversation ───────────────────────────────────────────────
        for entry in st.session_state.get("chat_history", []):
            user_bubble(entry["question"])
            assistant_bubble(entry["answer"])
            # Source footnote
            if entry.get("sources"):
                pages_cited = ", ".join(
                    f"p.{p.page_num} — {p.title[:30]}"
                    for p, _ in entry["sources"][:3]
                )
                st.markdown(f'<div class="source-footnote">📎 Retrieved: {pages_cited}</div>',
                            unsafe_allow_html=True)
            st.markdown("<div style='height:4px'></div>", unsafe_allow_html=True)

        # ── Chat input ────────────────────────────────────────────────────────
        question = st.chat_input(
            f"Ask about {pipeline.filename}…",
            disabled=not github_token,
        )

        if question:
            user_bubble(question)
            typing_ph = st.empty()
            typing_ph.markdown("""
<div class="msg-row assistant">
  <div class="avatar assistant">AI</div>
  <div class="bubble assistant">
    <div class="typing"><span></span><span></span><span></span></div>
  </div>
</div>""", unsafe_allow_html=True)

            try:
                result = pipeline.ask(question)
                typing_ph.empty()
                assistant_bubble(result.answer)

                if result.source_pages:
                    pages_cited = ", ".join(
                        f"p.{p.page_num} — {p.title[:30]}"
                        for p, _ in result.source_pages[:3]
                    )
                    st.markdown(
                        f'<div class="source-footnote">📎 Retrieved: {pages_cited}</div>',
                        unsafe_allow_html=True,
                    )

                st.session_state["chat_history"].append({
                    "question": question,
                    "answer":   result.answer,
                    "sources":  result.source_pages,
                })
                st.session_state["last_results"] = result.source_pages
                st.session_state["last_query"]   = question
                st.toast("✅ Answer generated", icon="🤖")

            except Exception as e:
                typing_ph.empty()
                st.toast(f"❌ {str(e)[:80]}", icon="🚨")
                st.error(f"**Error:** {e}")

        # ── Download chat ─────────────────────────────────────────────────────
        if st.session_state.get("chat_history"):
            st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)
            lines = [f"# Chat — {pipeline.filename}\n\n"]
            for e in st.session_state["chat_history"]:
                lines.append(f"**Q:** {e['question']}\n\n**A:** {e['answer']}\n\n---\n\n")
            st.download_button(
                "⬇️ Export Chat",
                data="".join(lines),
                file_name="docchat_export.md",
                mime="text/markdown",
                use_container_width=True,
            )

    # ── Sources panel ─────────────────────────────────────────────────────────
    with src_col:
        st.markdown("""
<div style="font-size:0.82rem;font-weight:600;color:#9a9a9a;
            letter-spacing:.08em;padding:12px 0 8px;">RETRIEVED PAGES</div>""",
                    unsafe_allow_html=True)

        last_results = st.session_state.get("last_results", [])
        last_query   = st.session_state.get("last_query",   "")

        if not last_results:
            st.markdown("""
<div style="text-align:center;padding:32px 16px;color:#505050;font-size:0.82rem;">
  Ask a question to see<br>which pages were retrieved
</div>""", unsafe_allow_html=True)
        else:
            # Relevance chart
            all_scores = pipeline.index.score_chart_data(last_query)
            df = pd.DataFrame(all_scores)
            if df["score"].max() > 0:
                chart = (
                    alt.Chart(df)
                    .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3)
                    .encode(
                        x=alt.X("page:N", sort="-y", title=None,
                                axis=alt.Axis(labelAngle=-45, labelColor="#9a9a9a",
                                              domainColor="#2a2a2a", tickColor="#2a2a2a")),
                        y=alt.Y("score:Q", title="BM25",
                                axis=alt.Axis(labelColor="#9a9a9a", gridColor="#2a2a2a",
                                              domainColor="#2a2a2a")),
                        color=alt.condition(
                            alt.datum.score > 0,
                            alt.value("#10a37f"),
                            alt.value("#2a2a2a"),
                        ),
                        tooltip=[alt.Tooltip("title:N", title="Page"),
                                 alt.Tooltip("score:Q", title="Score", format=".3f")],
                    )
                    .properties(height=160, background="transparent",
                                title=alt.TitleParams("Page Relevance", color="#9a9a9a",
                                                      fontSize=11))
                    .configure_view(strokeWidth=0)
                )
                st.altair_chart(chart, use_container_width=True)

            # Page cards
            for rank, (page, score) in enumerate(last_results, 1):
                pct = int(score / (last_results[0][1] or 1) * 100)
                with st.expander(
                    f"#{rank}  {page.title[:38]}  ·  {pct}%",
                    expanded=(rank == 1),
                ):
                    st.markdown(f"""
<div style="display:flex;gap:8px;margin-bottom:6px;flex-wrap:wrap;">
  {chip("📄", f"page {page.page_num}")}
  {chip("📝", f"{page.word_count}w")}
  {chip("🏷️", page.source_type)}
  {chip("📊", f"BM25: {score:.2f}")}
</div>""", unsafe_allow_html=True)
                    if page.source_type in ("xlsx_sheet", "csv_batch"):
                        st.markdown(page.content[:1200])
                    else:
                        st.code(page.content[:1200] + ("…" if len(page.content) > 1200 else ""), language=None)


# ══════════════════════════════════════════════════════════════════════════════
#  TAB 2 — DOCUMENT BROWSER
# ══════════════════════════════════════════════════════════════════════════════
with tab_browser:
    stats = pipeline.stats
    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    # Stat row
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("📄 Pages",       stats.total_pages)
    c2.metric("📝 Words",       f"{stats.total_words:,}")
    c3.metric("⚡ Avg Words",   stats.avg_words_per_page)
    c4.metric("🗂️ Types",       len(stats.source_types))

    st.markdown(f"""
<div style="margin:8px 0 16px;">
  {''.join(chip('🗂️', t) for t in stats.source_types)}
  {chip('📑', f'Longest: {stats.longest_page[:30]}')}
</div>""", unsafe_allow_html=True)

    search_q = st.text_input("🔍 Search pages", placeholder="Type to filter by relevance…",
                              label_visibility="visible", key="browser_search")

    if search_q.strip():
        display = [(p, s) for p, s in pipeline.index.search(search_q, top_k=len(pipeline.pages)) if s > 0]
        if not display:
            st.toast("No pages matched your search", icon="🔍")
            display = [(p, 0.0) for p in pipeline.pages]
    else:
        display = [(p, 0.0) for p in pipeline.pages]

    st.markdown(f"<div style='font-size:0.78rem;color:#9a9a9a;margin-bottom:8px;'>{len(display)} pages shown</div>",
                unsafe_allow_html=True)

    for page, score in display:
        score_label = f"  ·  BM25 {score:.2f}" if score > 0 else ""
        with st.expander(f"**{page.page_num}.** {page.title[:65]}{score_label}"):
            st.markdown(f"""
<div style="display:flex;gap:6px;margin-bottom:10px;flex-wrap:wrap;">
  {chip('📝', f'{page.word_count} words')}
  {chip('🏷️', page.source_type)}
  {chip('📄', f'page {page.page_num}')}
</div>""", unsafe_allow_html=True)
            # Use st.code for reliable rendering in dark theme
            # For markdown-formatted content (xlsx/csv tables), use st.markdown
            if page.source_type in ("xlsx_sheet", "csv_batch"):
                st.markdown(page.content)
            else:
                st.code(page.content, language=None)


# ══════════════════════════════════════════════════════════════════════════════
#  TAB 3 — HOW IT WORKS
# ══════════════════════════════════════════════════════════════════════════════
with tab_how:
    st.markdown("""
<div style="max-width:680px;margin:0 auto;padding:8px 0;">

## 🏗️ Architecture

```
📂 Upload Document
        │
        ▼
┌─────────────────────────────────┐
│  PageIndex Parser               │
│  PDF  → 1 Page  per PDF page    │
│  DOCX → 1 Page  per heading     │
│  XLSX → 1 Page  per sheet       │
│  CSV  → 1 Page  per 50 rows     │
│  TXT  → 1 Page  per section     │
└──────────────┬──────────────────┘
               │  List[Page]
               ▼
┌─────────────────────────────────┐
│  PageIndex  ·  BM25Okapi        │
│  No embeddings · No GPU         │
│  No VectorDB · Instant index    │
└──────────────┬──────────────────┘
               │
    ┌──────────┴──────────┐
    │   User Question     │
    └──────────┬──────────┘
               ▼
┌─────────────────────────────────┐
│  BM25 Search                    │
│  Score all pages → Top-K        │
└──────────────┬──────────────────┘
               │  Top-K full pages
               ▼
┌─────────────────────────────────┐
│  GitHub Copilot LLM             │
│  System + History + Context     │
│  → Grounded answer              │
└─────────────────────────────────┘
```

## ⚖️ Why PageIndex beats chunking

| Chunking | PageIndex |
|---|---|
| Arbitrary character limits | Natural doc boundaries |
| Tables split across chunks | Tables intact per page |
| Tune chunk_size & overlap | Just set Top-K |
| BM25 over fragments | BM25 over complete units |
| Context lost at edges | Full semantic unit |

## 🔑 BM25 vs Vector Search

| | BM25 (this app) | Vector Search |
|---|---|---|
| Index speed | ⚡ Instant | 🐢 Slow (embed each page) |
| GPU needed | ❌ No | ✅ Yes |
| Exact keywords | ✅ Perfect | ⚠️ May miss |
| Semantic similarity | ⚠️ Limited | ✅ Strong |
| Deterministic | ✅ Yes | ❌ No |

**For business documents** (contracts, manuals, reports) BM25 over pages
performs as well or better than vector search — and needs zero infrastructure.

</div>
""")

