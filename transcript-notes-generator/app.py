"""
app.py — Transcript Notes Generator
A Streamlit app that converts transcripts and audio into structured Markdown guides.

Tab 1 — 📝 Transcript → Markdown
  • Upload a .txt file or paste transcript text
  • Choose a GitHub Copilot model (free via gh auth token)
  • Generate a well-structured Markdown guide
  • Preview and download

Tab 2 — 🎙️ Audio → Markdown
  • Record audio in the browser (st.audio_input) or upload a file
  • Transcribe locally using faster-whisper (free, no API key)
  • Review and edit the transcript
  • Convert to structured Markdown
  • Download

Prerequisites:
  pip install -r requirements.txt
  gh auth login
"""
from __future__ import annotations

import datetime
import io
import os
from pathlib import Path

import streamlit as st

from src import llm as copilot_llm
from src.transcript_processor import (
    process as generate_markdown,
    clear_cache, cache_stats,
    clear_run_states, run_state_stats,
)
from src.audio_transcriber import (
    WHISPER_MODELS,
    DEFAULT_WHISPER_MODEL,
    transcribe_bytes,
)
from src import system_audio_recorder as sys_rec

# ── Constants ─────────────────────────────────────────────────────────────────

OUTPUT_DIR = Path(__file__).parent / "output" / "md-files"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ── Page config ───────────────────────────────────────────────────────────────

st.set_page_config(
    page_title="Transcript Notes Generator",
    page_icon="📝",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── Sidebar ───────────────────────────────────────────────────────────────────

with st.sidebar:
    st.title("⚙️ Settings")

    # Auth status
    token = copilot_llm.get_gh_token()
    if token:
        st.success("🔑 GitHub token detected via `gh auth token`")
    else:
        st.error("❌ No token found. Run `gh auth login` in your terminal.")
        st.stop()

    st.markdown("---")

    # Model selection — fetch live from Copilot /models API
    st.subheader("🤖 Copilot Model")

    with st.spinner("Fetching available models…"):
        available_models = copilot_llm.get_available_models(token)

    # Speed hint labels
    _SPEED_HINTS = {
        "mini": "⚡ fast",
        "haiku": "⚡ fast",
        "fast": "⚡ fast",
        "sonnet": "⚖️ balanced",
        "gpt-4.1": "⚖️ balanced",
        "gpt-5.2": "⚖️ balanced",
        "gpt-5.3": "⚖️ balanced",
        "opus": "🧠 powerful",
        "gpt-5.4": "🧠 powerful",
        "gpt-5.5": "🧠 powerful",
        "codex": "💻 code",
        "grok": "⚡ fast",
    }

    def _model_label(m: str) -> str:
        for key, hint in _SPEED_HINTS.items():
            if key in m:
                return f"{m}  [{hint}]"
        return m

    model_labels = [_model_label(m) for m in available_models]

    # Determine the index to show:
    # 1. If user previously chose a model this session, keep it
    # 2. Otherwise use DEFAULT_MODEL
    saved_model = st.session_state.get("selected_model", copilot_llm.DEFAULT_MODEL)
    if saved_model in available_models:
        default_idx = available_models.index(saved_model)
    elif copilot_llm.DEFAULT_MODEL in available_models:
        default_idx = available_models.index(copilot_llm.DEFAULT_MODEL)
    else:
        default_idx = 0

    selected_label = st.selectbox(
        "Model",
        model_labels,
        index=default_idx,
        key="model_selectbox",
        help="Live list from api.githubcopilot.com/models · All free via your Copilot subscription.",
    )
    model_choice = available_models[model_labels.index(selected_label)]
    # Persist choice so it survives button-click reruns
    st.session_state["selected_model"] = model_choice

    st.caption(
        f"ℹ️ {len(available_models)} models available · "
        "⚡ fast = fewer tokens/s · 🧠 powerful = higher quality, slower"
    )

    # Temperature
    temperature = st.slider(
        "Temperature",
        min_value=0.0,
        max_value=1.0,
        value=0.3,
        step=0.05,
        help="Lower = more focused; higher = more creative.",
    )

    st.markdown("---")

    # Cache & run-state controls
    st.subheader("💾 Cache & Snapshots")
    use_cache = st.checkbox(
        "Use cache & run snapshots",
        value=True,
        help=(
            "Chunk cache: saves extraction results to output/cache/ — repeated runs skip "
            "already-done API calls.\n\n"
            "Run snapshots: saves pipeline stage to output/cache/runs/ after every chunk and "
            "every compression batch — if processing fails, re-running resumes from exactly "
            "where it stopped (no API calls wasted)."
        ),
    )
    chunk_st = cache_stats()
    snap_st  = run_state_stats()
    if chunk_st["count"] > 0 or snap_st["count"] > 0:
        total_kb = (chunk_st["size_bytes"] + snap_st["size_bytes"]) / 1024
        parts = []
        if chunk_st["count"]:
            parts.append(f"📦 {chunk_st['count']} chunks")
        if snap_st["count"]:
            parts.append(f"♻️ {snap_st['count']} snapshot(s)")
        st.caption(f"{' · '.join(parts)} · {total_kb:.1f} KB total")
        col_c1, col_c2 = st.columns(2)
        with col_c1:
            if st.button("🗑️ Clear chunks", type="secondary", use_container_width=True):
                deleted = clear_cache()
                st.success(f"Deleted {deleted} chunk entries.")
                st.rerun()
        with col_c2:
            if st.button("🗑️ Clear snapshots", type="secondary", use_container_width=True):
                deleted = clear_run_states()
                st.success(f"Deleted {deleted} snapshot(s).")
                st.rerun()
    else:
        st.caption("Cache is empty — entries are created after first run.")

    # Synthesis model (optional override)
    with st.expander("🧪 Advanced: Synthesis model override"):
        st.caption(
            "By default the same model is used for extraction and final synthesis. "
            "Set a different model here to use a more powerful model for the final guide only."
        )
        synthesis_model_options = ["(same as above)"] + available_models
        synth_label = st.selectbox(
            "Synthesis model",
            synthesis_model_options,
            index=0,
            key="synth_model_selectbox",
        )
        synthesis_model_override = None if synth_label == "(same as above)" else synth_label

    st.markdown("---")

    # Whisper model selection
    st.subheader("🎙️ Whisper Model")
    whisper_model = st.selectbox(
        "Transcription model",
        WHISPER_MODELS,
        index=WHISPER_MODELS.index(DEFAULT_WHISPER_MODEL),
        help="base (145 MB) is a good balance of speed and accuracy. Downloaded once, cached locally.",
    )
    st.caption("ℹ️ First use downloads the model (~145 MB for 'base'). Runs fully offline after that.")

    st.markdown("---")
    st.caption("📌 **Free & local** — GitHub Copilot LLM + local Whisper transcription")
    st.caption("Repo: `transcript-notes-generator`")


# ── Helpers ───────────────────────────────────────────────────────────────────

def _save_and_download(md_content: str, slug: str) -> None:
    """Save MD to output/ and show Streamlit download button."""
    date_str = datetime.date.today().isoformat()
    filename = f"{slug}-guide-{date_str}.md"
    file_path = OUTPUT_DIR / filename
    file_path.write_text(md_content, encoding="utf-8")

    st.download_button(
        label="⬇️ Download Markdown",
        data=md_content.encode("utf-8"),
        file_name=filename,
        mime="text/markdown",
        use_container_width=True,
    )
    st.caption(f"Also saved to `output/md-files/{filename}`")


def _generate_and_show(transcript_text: str, slug: str) -> None:
    """Run the processor with progress updates and render output."""
    progress_placeholder = st.empty()
    status_lines: list[str] = []

    def on_progress(msg: str) -> None:
        status_lines.append(msg)
        progress_placeholder.info("\n\n".join(status_lines))

    try:
        md_output = generate_markdown(
            transcript_text,
            model=model_choice,
            temperature=temperature,
            on_progress=on_progress,
            use_cache=use_cache,
            synthesis_model=synthesis_model_override,
        )
        progress_placeholder.success("✅ Guide generated!")
    except ValueError as exc:
        st.error(f"❌ Input error: {exc}")
        return
    except RuntimeError as exc:
        st.error(f"❌ LLM error: {exc}")
        return
    except Exception as exc:
        st.error(f"❌ Unexpected error: {exc}")
        return

    st.markdown("---")
    col1, col2 = st.columns([2, 1])

    with col1:
        st.subheader("📄 Generated Guide (Preview)")
        st.markdown(md_output)

    with col2:
        st.subheader("📋 Raw Markdown")
        st.code(md_output, language="markdown")
        _save_and_download(md_output, slug)


# ══════════════════════════════════════════════════════════════════════════════
#  Main UI — Tabs
# ══════════════════════════════════════════════════════════════════════════════

st.title("📝 Transcript Notes Generator")
st.caption("Turn plain transcripts and audio recordings into structured Markdown guides.")

tab1, tab2 = st.tabs(["📝 Transcript → Markdown", "🎙️ Audio → Markdown"])


# ── Tab 1: Transcript → Markdown ──────────────────────────────────────────────

with tab1:
    st.header("📝 Transcript → Markdown")
    st.markdown(
        "Upload a `.txt` transcript file **or** paste the text below. "
        "The app will generate a well-structured Markdown guide using GitHub Copilot."
    )

    input_method = st.radio(
        "Input method",
        ["📂 Upload .txt file", "✏️ Paste text"],
        horizontal=True,
        key="t1_input_method",
    )

    transcript_text: str = ""
    slug: str = "guide"

    if input_method == "📂 Upload .txt file":
        uploaded_file = st.file_uploader(
            "Upload transcript (.txt)",
            type=["txt"],
            key="t1_uploader",
        )
        if uploaded_file:
            try:
                transcript_text = uploaded_file.read().decode("utf-8", errors="replace")
                slug = Path(uploaded_file.name).stem.replace(" ", "-").lower()
                st.success(f"✅ Loaded `{uploaded_file.name}` — {len(transcript_text):,} characters")
                with st.expander("Preview raw transcript"):
                    st.text(transcript_text[:2000] + ("…" if len(transcript_text) > 2000 else ""))
            except Exception as exc:
                st.error(f"❌ Could not read file: {exc}")

    else:  # Paste text
        transcript_text = st.text_area(
            "Paste transcript here",
            height=300,
            placeholder="Paste your transcript text here…",
            key="t1_textarea",
        )
        slug = st.text_input(
            "Topic slug (used in filename)",
            value="my-topic",
            key="t1_slug",
            help="kebab-case identifier, e.g. 'spring-boot' or 'ai-agents'",
        )

    if transcript_text.strip():
        st.info(f"📊 **{len(transcript_text):,}** characters · **{len(transcript_text.split()):,}** words")

        if st.button("🚀 Generate Markdown Guide", key="t1_generate", use_container_width=True, type="primary"):
            with st.spinner(f"Processing with **{model_choice}**…"):
                _generate_and_show(transcript_text, slug)
    else:
        st.info("⬆️ Upload a transcript file or paste text to get started.")


# ── Tab 2: Audio → Markdown ───────────────────────────────────────────────────

with tab2:
    st.header("🎙️ Audio → Markdown")
    st.markdown(
        "Three ways to get audio: **record your mic**, **upload a file**, or "
        "**capture system audio** (YouTube, videos, meetings playing on this laptop). "
        "Transcription runs **locally and free** using Whisper — no API key needed."
    )

    audio_method = st.radio(
        "Audio source",
        ["🖥️ System Audio (YouTube / any app)", "🎤 Record microphone", "📁 Upload audio file"],
        horizontal=True,
        key="t2_audio_method",
    )

    audio_bytes: bytes | None = None
    t2_slug = "audio-notes"

    # ── System Audio Loopback ──
    if audio_method == "🖥️ System Audio (YouTube / any app)":
        loopback_devices = sys_rec.list_loopback_devices()

        if not loopback_devices:
            st.error(
                "❌ No WASAPI loopback devices found. "
                "Make sure you have audio output devices (speakers/headphones) and "
                "`pyaudiowpatch` is installed: `python -m pip install pyaudiowpatch`"
            )
        else:
            st.info(
                "🖥️ This captures **whatever is playing through your speakers** — "
                "YouTube videos, meetings, music, any app. "
                "Start playing audio first, then click **Start**."
            )

            device_names = [name for _, name in loopback_devices]
            col_dev, col_hint = st.columns([2, 1])
            with col_dev:
                selected_name = st.selectbox(
                    "Loopback device",
                    device_names,
                    index=0,
                    help="Select the audio output device whose sound you want to capture.",
                    key="t2_loopback_device",
                )
            with col_hint:
                st.caption(f"ℹ️ {len(loopback_devices)} loopback device(s) found")

            # Get the device index matching the selected name
            selected_index = next(idx for idx, name in loopback_devices if name == selected_name)

            col_start, col_stop = st.columns(2)
            currently_recording = sys_rec.is_recording()

            with col_start:
                if st.button(
                    "🔴 Start Recording",
                    key="t2_sys_start",
                    use_container_width=True,
                    type="primary",
                    disabled=currently_recording,
                ):
                    try:
                        sys_rec.start_recording(selected_index)
                        st.session_state["t2_sys_started"] = True
                        st.rerun()
                    except RuntimeError as exc:
                        st.error(f"❌ {exc}")

            with col_stop:
                if st.button(
                    "⏹️ Stop & Transcribe",
                    key="t2_sys_stop",
                    use_container_width=True,
                    disabled=not currently_recording,
                ):
                    with st.spinner("Stopping recording and saving audio…"):
                        try:
                            audio_bytes = sys_rec.stop_recording()
                            st.session_state.pop("t2_sys_started", None)
                            st.success(f"✅ Captured {len(audio_bytes):,} bytes of system audio")
                        except RuntimeError as exc:
                            st.error(f"❌ {exc}")

            if currently_recording:
                st.warning(
                    "🔴 **Recording system audio…** Press ⏹️ Stop when done. "
                    "Make sure audio is playing on your laptop right now."
                )
                st.audio(b"", format="audio/wav")  # placeholder keeps layout stable

    # ── Microphone ──
    elif audio_method == "🎤 Record microphone":
        st.info(
            "🎤 Click the microphone below to start recording your voice. "
            "Click again (or the stop button) to finish. "
            "Works directly in your browser — no extra software needed."
        )
        recorded = st.audio_input("Record audio", key="t2_recorder")
        if recorded:
            audio_bytes = recorded.read()
            st.audio(recorded)
            st.success(f"✅ Recorded {len(audio_bytes):,} bytes")

    # ── Upload ──
    else:
        uploaded_audio = st.file_uploader(
            "Upload audio file",
            type=["wav", "mp3", "m4a", "ogg", "flac", "webm"],
            key="t2_uploader",
        )
        if uploaded_audio:
            audio_bytes = uploaded_audio.read()
            t2_slug = Path(uploaded_audio.name).stem.replace(" ", "-").lower()
            st.audio(uploaded_audio)
            st.success(f"✅ Loaded `{uploaded_audio.name}` — {len(audio_bytes):,} bytes")

    # ── Transcribe ──
    if audio_bytes:
        st.markdown("---")
        st.subheader("Step 1 — Transcribe Audio")

        lang_options = ["Auto-detect", "en", "es", "fr", "de", "hi", "zh", "ja", "pt", "ar"]
        lang_choice = st.selectbox(
            "Language",
            lang_options,
            help="Select audio language for better accuracy, or leave on Auto-detect.",
            key="t2_language",
        )
        language = None if lang_choice == "Auto-detect" else lang_choice

        if st.button("🔊 Transcribe Audio", key="t2_transcribe", use_container_width=True, type="primary"):
            with st.spinner(f"Transcribing with Whisper **{whisper_model}** (may take a moment)…"):
                try:
                    transcript = transcribe_bytes(
                        audio_bytes,
                        model_size=whisper_model,
                        language=language,
                    )
                    st.session_state["t2_transcript"] = transcript
                    st.success("✅ Transcription complete!")
                except ImportError as exc:
                    st.error(f"❌ {exc}")
                except RuntimeError as exc:
                    st.error(f"❌ {exc}")
                except Exception as exc:
                    st.error(f"❌ Unexpected transcription error: {exc}")

    # ── Show / edit transcript ──
    if "t2_transcript" in st.session_state and st.session_state["t2_transcript"]:
        st.markdown("---")
        st.subheader("Step 2 — Review Transcript")
        st.caption("You can edit the transcript before converting to Markdown.")

        edited_transcript = st.text_area(
            "Transcript (editable)",
            value=st.session_state["t2_transcript"],
            height=300,
            key="t2_transcript_editor",
        )

        st.info(
            f"📊 **{len(edited_transcript):,}** characters · "
            f"**{len(edited_transcript.split()):,}** words"
        )

        t2_slug_input = st.text_input(
            "Topic slug",
            value=t2_slug,
            key="t2_slug",
            help="kebab-case name for the output file",
        )

        st.markdown("---")
        st.subheader("Step 3 — Generate Markdown Guide")

        if st.button("📝 Convert to Markdown", key="t2_convert", use_container_width=True, type="primary"):
            if not edited_transcript.strip():
                st.warning("⚠️ Transcript is empty — nothing to convert.")
            else:
                with st.spinner(f"Generating guide with **{model_choice}**…"):
                    _generate_and_show(edited_transcript, t2_slug_input or "audio-notes")
    elif audio_bytes is None and not sys_rec.is_recording():
        st.info("⬆️ Choose an audio source above to get started.")
