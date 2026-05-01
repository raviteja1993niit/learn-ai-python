"""
app.py — Streamlit UI for the agentic vector-less RAG app.

Architecture:
  Upload Doc → convert.py converts to JSON tree → ask.py sends full JSON to Copilot LLM
  No BM25, no embeddings, no retrieval code. The LLM is the agent that reads & retrieves.

Authentication: auto-detected from `gh auth login` (GitHub CLI) or GITHUB_TOKEN env var.
No manual token input required.
"""

import streamlit as st
import json
import os
import tempfile
from pathlib import Path

from convert import convert
from ask import ask, AVAILABLE_MODELS, build_context, _resolve_github_token
from summarize import summarize

# ── Page config ────────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Agentic RAG — Copilot LLM",
    page_icon="🤖",
    layout="wide",
)

st.title("🤖 Agentic Vector-less RAG")
st.caption("Upload a document → JSON tree → GitHub Copilot LLM reads & answers — no token input needed")

# ── Auth detection ─────────────────────────────────────────────────────────────
@st.cache_resource
def _check_auth():
    token = _resolve_github_token()
    if token:
        src = "GitHub CLI (`gh auth login`)" if not os.environ.get("GITHUB_TOKEN") else "GITHUB_TOKEN env var"
        return token, src
    return None, None

github_token, auth_source = _check_auth()

# ── Sidebar ────────────────────────────────────────────────────────────────────
with st.sidebar:
    st.header("⚙️ Settings")

    # Auth status badge
    if github_token:
        st.success(f"✅ Authenticated via {auth_source}")
    else:
        st.error("❌ Not authenticated")
        st.markdown("""
**To authenticate, run once:**
```
gh auth login
```
Or set an environment variable:
```
set GITHUB_TOKEN=ghp_your_token
```
Get a free token at [github.com/settings/tokens/new](https://github.com/settings/tokens/new) (no scopes needed)
""")

    model = st.selectbox("Model", AVAILABLE_MODELS, index=0)

    st.divider()
    st.markdown("**How it works:**")
    st.markdown("""
1. 📄 Upload PDF / DOCX / XLSX
2. 🔄 Script converts it to a **JSON tree**
   - With TOC → uses existing structure
   - Without TOC → auto-generates headings
3. 🤖 GitHub Copilot LLM reads **full JSON** and answers
4. No BM25, no embeddings — LLM is the retrieval agent
""")

# ── File upload ────────────────────────────────────────────────────────────────
uploaded_file = st.file_uploader(
    "Upload document",
    type=["pdf", "docx", "doc", "xlsx", "xls"],
    help="Supported: PDF, Word (.docx/.doc), Excel (.xlsx/.xls)",
)

if uploaded_file:
    cache_key = f"{uploaded_file.name}_{uploaded_file.size}"
    if st.session_state.get("doc_cache_key") != cache_key:
        with st.spinner(f"Converting '{uploaded_file.name}' to JSON tree…"):
            try:
                suffix = Path(uploaded_file.name).suffix
                with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp_in:
                    tmp_in.write(uploaded_file.read())
                    tmp_in_path = tmp_in.name

                tmp_out_path = tmp_in_path + ".json"
                convert(tmp_in_path, tmp_out_path)

                doc_json = json.loads(Path(tmp_out_path).read_text(encoding="utf-8"))
                st.session_state["doc_cache_key"] = cache_key
                st.session_state["doc_json"] = doc_json
                st.session_state["doc_json_path"] = tmp_out_path
                st.session_state["chat_history"] = []

                os.unlink(tmp_in_path)

            except Exception as e:
                st.error(f"Failed to convert document: {e}")
                st.stop()

    doc_json = st.session_state.get("doc_json", {})
    doc_json_path = st.session_state.get("doc_json_path", "")

    # ── Document summary ───────────────────────────────────────────────────────
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Sections", len(doc_json.get("sections", [])))
    col2.metric("Tables", len(doc_json.get("tables", [])))
    col3.metric("File type", doc_json.get("file_type", "?").upper())
    col4.metric("Structure", "TOC ✓" if doc_json.get("has_toc") else "Auto-headings")

    with st.expander("📋 View JSON tree (raw)", expanded=False):
        st.json(doc_json)

    with st.expander("📝 View LLM context (formatted)", expanded=False):
        st.text(build_context(doc_json))

    # ── Section summaries ──────────────────────────────────────────────────────
    st.subheader("📑 Section Summaries")

    summary_json_path = doc_json_path.replace(".json", ".summary.json")
    existing_summary = None
    if Path(summary_json_path).exists():
        existing_summary = json.loads(Path(summary_json_path).read_text(encoding="utf-8"))

    if existing_summary:
        st.success(f"✅ Summaries loaded from `{summary_json_path}` (model: {existing_summary.get('model', '?')})")
        with st.expander("📋 View all section summaries", expanded=True):
            for s in existing_summary.get("summaries", []):
                page_label = f"  _(p. {s['page']})_" if s.get("page") else ""
                st.markdown(f"**{s['heading']}**{page_label}")
                st.write(s["summary"])
                st.divider()
    else:
        st.info("No summaries generated yet.")

    if github_token:
        if st.button("✨ Generate Section Summaries via Copilot LLM"):
            with st.spinner(f"Summarizing {len(doc_json.get('sections', []))} sections…"):
                try:
                    out_path = summarize(doc_json_path, summary_json_path, model=model)
                    st.success(f"✅ Summaries saved → `{out_path}`")
                    st.rerun()
                except Exception as e:
                    st.error(f"❌ Summarization failed: {e}")

    st.divider()

    # ── Chat interface ─────────────────────────────────────────────────────────
    st.subheader("💬 Ask questions")

    if not github_token:
        st.warning("⚠️ Authentication required. See sidebar for setup instructions.")
    else:
        for msg in st.session_state.get("chat_history", []):
            with st.chat_message(msg["role"]):
                st.markdown(msg["content"])

        if question := st.chat_input("Ask anything about the document…"):
            st.session_state.setdefault("chat_history", []).append(
                {"role": "user", "content": question}
            )
            with st.chat_message("user"):
                st.markdown(question)

            with st.chat_message("assistant"):
                with st.spinner("Thinking…"):
                    try:
                        answer = ask(doc_json_path, question, model=model)
                        st.markdown(answer)
                        st.session_state["chat_history"].append(
                            {"role": "assistant", "content": answer}
                        )
                    except Exception as e:
                        err = f"❌ Error: {e}"
                        st.error(err)
                        st.session_state["chat_history"].append(
                            {"role": "assistant", "content": err}
                        )
else:
    st.info("👆 Upload a PDF, Word, or Excel file to get started.")
