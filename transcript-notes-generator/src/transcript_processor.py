"""
transcript_processor.py — Convert plain text transcript to structured Markdown.

Pipeline:
  1. Normalise (strip timestamps, collapse whitespace)
  2. For short transcripts (< 8 000 chars): single-pass LLM synthesis
     For long transcripts: chunk → per-chunk note extraction (cached + paced)
                           → Python dedup → compression if needed → final synthesis
  3. Return final Markdown string

Caching:
  Each chunk extraction result is cached to disk (output/cache/).
  Cache key = SHA-256(chunk_text + model + temperature + PIPELINE_VERSION).
  Re-running the same transcript with the same settings hits cache and skips LLM calls.
  Use process(..., use_cache=False) or clear the cache dir to force a full re-run.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import time
from pathlib import Path
from typing import Generator

from src import llm

# ── Pipeline version — bump when prompt/logic changes to auto-invalidate cache ─
_PIPELINE_VERSION = "2"

_CACHE_DIR     = Path(__file__).resolve().parent.parent / "output" / "cache"

# Run-state checkpoints — one JSON per in-progress pipeline run
_RUN_STATE_DIR    = Path(__file__).resolve().parent.parent / "output" / "cache" / "runs"
_RUN_STATE_SCHEMA = 1   # bump if the state dict structure changes

# Transcripts below this char count are processed in a single LLM call
_SINGLE_PASS_THRESHOLD = 8_000
# Each chunk for long transcripts — 15k = ~15 chunks for a 1-hr transcript (was 8k = ~29 chunks)
# Larger chunks = fewer API calls = less 403 rate-limit exposure. Still well within 128k context.
_CHUNK_SIZE = 15_000

# Max combined notes chars before triggering compression
_MAX_SYNTHESIS_CHARS = 20_000    # raised proportionally for larger chunks
# Compress every N chunk-notes into one summary block
_COMPRESS_BATCH = 5
# Adaptive delay: starts low, jumps to 60s after any 403 retry, resets on 3-call success streak
_INTER_CHUNK_DELAY_BASE  = 2.0   # start fast
_INTER_CHUNK_DELAY_MAX   = 10.0  # normal ceiling
_INTER_CHUNK_DELAY_403   = 65.0  # jump to this after a 403-recovered call (matches API recovery)

_SYNTHESIS_SYSTEM = """\
You are an expert technical writer. Convert the raw transcript (or structured notes) provided \
by the user into a clean, well-structured Markdown document following these rules:

STRUCTURE RULES:
- Exactly ONE H1 heading: "# <Detected Topic> — A Complete Guide"
- Use H2 (##) for major sections, H3 (###) for sub-sections, H4 (####) sparingly for details
- Never skip heading levels (H4 must be inside H3, H3 inside H2)
- Place "---" between every H2 section, never between H3 sections
- End with a "## 🎯 Key Takeaways" section (bullet list, narrator's voice)

CONDITIONAL FORMATTING (only add if the source actually supports it):
- Tables: ONLY when the transcript explicitly compares 2+ items side-by-side or lists properties. \
  Minimum 3 data rows. Always include a header row.
- ASCII diagrams: ONLY when the transcript describes a flow, pipeline, or architecture. \
  Use simple box-and-arrow ASCII art.
- Code blocks: ONLY when actual code, commands, or config is present in the transcript. \
  Always tag with the language (```python, ```bash, ```json, etc.)
- Blockquotes: For direct quotes from the narrator — use "> 💬 *\"...\""*

QUALITY RULES:
- Preserve the narrator's own phrasing and analogies — do not flatten into generic docs
- Every concept the narrator touched must appear, even if mentioned briefly
- No placeholder text like "[To be filled]" or "<TODO>"
- No invented examples, analogies, or code not present in the transcript
- Output ONLY the Markdown — no preamble, no explanation, no wrapper text
"""

_NOTES_SYSTEM = """\
You are a transcript analyst. Extract key information from this transcript chunk.
Output ONLY compact bullet points — maximum 12 words per bullet. No full sentences.

Cover:
- Key concepts (name + 1-line definition)
- Code / commands / config (exact text)
- Warnings or gotchas (mark with ⚠️)
- Direct quotes worth keeping (use "quotes")
- Comparisons or list-able items

Be selective: only include facts the narrator clearly stated. Skip filler and repetition.
"""

_COMPRESS_SYSTEM = """\
You are a technical editor. Condense the following chunk notes into a shorter summary
that preserves ALL unique concepts, quotes, analogies, code, warnings, and comparisons.
Remove redundancy but keep every distinct idea. Output as compact bullet points.
"""

# Synthesis context limit — gpt-5-mini has 128k token context; 80k chars ≈ 20k tokens, safe margin
_MAX_SYNTHESIS_CHARS = 80_000
# Local compressor target (used before considering LLM compression)
_LOCAL_COMPRESS_TARGET = 70_000
# Compress every N chunk-notes into one summary block (LLM fallback only)
_COMPRESS_BATCH = 5
# Adaptive delay base / max (seconds between chunk LLM calls)
_INTER_CHUNK_DELAY_BASE = 2.0
_INTER_CHUNK_DELAY_MAX  = 10.0


# ── Public API ────────────────────────────────────────────────────────────────

def process(
    raw_text: str,
    model: str = llm.DEFAULT_MODEL,
    temperature: float = 0.3,
    on_progress: "callable[[str], None] | None" = None,
    use_cache: bool = True,
    synthesis_model: str | None = None,
) -> str:
    """
    Convert a raw transcript to structured Markdown.

    Args:
        raw_text:        Raw transcript text (with or without timestamps)
        model:           Copilot model for extraction + compression
        temperature:     LLM temperature for extraction
        on_progress:     Optional callback(message: str) for progress updates
        use_cache:       If True, enables both chunk cache AND run-state checkpoints.
                         Run-state checkpoints let a failed run resume from the last
                         completed stage (extraction chunk / compression batch / synthesis).
        synthesis_model: If set, use a different model for the final synthesis step only.

    Returns:
        Structured Markdown string.

    Resume behaviour (when use_cache=True):
        Stage "extracting"  → resumes from last successfully extracted chunk.
        Stage "compressing" → skips extraction entirely, resumes from last compression batch.
        Stage "synthesising"→ skips straight to the final synthesis call.
    """
    def progress(msg: str) -> None:
        if on_progress:
            on_progress(msg)

    synth_model = synthesis_model or model
    clean = _normalise(raw_text)

    if not clean.strip():
        raise ValueError("Transcript is empty after cleaning.")

    if len(clean) <= _SINGLE_PASS_THRESHOLD:
        progress("📝 Single-pass processing (short transcript)…")
        return _single_pass(clean, synth_model, temperature)

    # Long transcript — chunk → extract (cached+checkpointed) → dedup → compress → synthesise
    chunks = list(_split_chunks(clean, _CHUNK_SIZE))
    total  = len(chunks)
    all_chunk_keys = [_cache_key(c, model, temperature) for c in chunks]

    # ── Run-state savepoint ───────────────────────────────────────────────────
    run_key = _run_state_key(clean, model, temperature) if use_cache else None
    saved   = _run_state_load(run_key) if run_key else None

    # Discard saved state if chunk count doesn't match (transcript or pipeline changed)
    if saved and saved.get("total_chunks") != total:
        progress("⚠️  Saved snapshot has a different chunk count — discarding, starting fresh.")
        saved = None
        if run_key:
            _run_state_clear(run_key)

    # ── FAST RESUME: synthesis stage ──────────────────────────────────────────
    if saved and saved.get("stage") == "synthesising":
        final_notes = saved.get("final_notes", "")
        if final_notes:
            progress(
                f"♻️  Run snapshot found — all {total} chunks + compression already done. "
                f"Resuming at final synthesis…"
            )
            progress(f"✍️  Synthesising final guide with {synth_model}… (~20s)")
            try:
                result = _synthesise_from_notes(final_notes, synth_model, temperature, on_wait=progress)
            except RuntimeError as exc:
                exc_msg = str(exc)
                if "403" in exc_msg or "rate limit" in exc_msg.lower():
                    progress(
                        "⚠️  Rate limited during synthesis. "
                        "💾 Snapshot saved. Wait ~60s, then click ▶ Process to retry synthesis."
                    )
                raise
            if run_key:
                _run_state_clear(run_key)
            return result
        saved = None  # corrupt state — fall through

    # ── MEDIUM RESUME: compression stage ─────────────────────────────────────
    if saved and saved.get("stage") == "compressing":
        saved_notes  = saved.get("all_notes", [])
        last_batch   = saved.get("last_completed_batch", -1)
        done_batches = saved.get("completed_batches", [])
        if saved_notes:
            n_batches = -(-len(saved_notes) // _COMPRESS_BATCH)
            raw_combined = _dedup_notes("\n\n".join(saved_notes))
            if len(raw_combined) > _MAX_SYNTHESIS_CHARS:
                progress(
                    f"♻️  Run snapshot found — all {total} chunks extracted. "
                    f"Running local compression, then synthesis…"
                )
                combined_notes = _local_compress_notes(saved_notes, _LOCAL_COMPRESS_TARGET)
                progress(f"  ✅ Local compression: {len(raw_combined):,} → {len(combined_notes):,} chars")
                if len(combined_notes) > _MAX_SYNTHESIS_CHARS:
                    progress(
                        f"♻️  Still large — falling back to LLM compression "
                        f"from batch {last_batch + 2}/{n_batches}…"
                    )
                    combined_notes = _compress_notes_batched(
                        saved_notes, model, temperature, on_progress,
                        start_batch=last_batch + 1,
                        existing_compressed=done_batches,
                        run_key=run_key,
                        total_chunks=total,
                    )
            else:
                progress(
                    f"♻️  Run snapshot found — all {total} chunks extracted. "
                    f"Notes fit in context — skipping compression, going to synthesis…"
                )
                combined_notes = raw_combined
            if run_key:
                _run_state_save(run_key, {
                    "stage": "synthesising",
                    "total_chunks": total,
                    "final_notes": combined_notes,
                })
            progress(f"✍️  Synthesising final guide with {synth_model}… (~20s, almost done!)")
            try:
                result = _synthesise_from_notes(combined_notes, synth_model, temperature, on_wait=progress)
            except RuntimeError as exc:
                exc_msg = str(exc)
                if "403" in exc_msg or "rate limit" in exc_msg.lower():
                    progress(
                        "⚠️  Rate limited during synthesis. "
                        "💾 Snapshot saved. Wait ~60s, then click ▶ Process to retry synthesis."
                    )
                raise
            if run_key:
                _run_state_clear(run_key)
            return result
        saved = None  # corrupt state — fall through

    # ── PARTIAL RESUME: extraction stage ─────────────────────────────────────
    # Check how many leading chunks were extracted in a previous run (verified via cache)
    resume_from = 0
    if saved and saved.get("stage") == "extracting":
        last_done  = saved.get("last_completed_chunk", 0)
        saved_keys = saved.get("chunk_keys", [])
        verified   = 0
        for idx in range(min(last_done, len(saved_keys))):
            if _cache_load(saved_keys[idx]) is not None:
                verified = idx + 1
            else:
                break  # stop at first cache miss — don't skip past a gap
        if verified > 0:
            progress(
                f"♻️  Run snapshot found — {verified}/{total} chunks already extracted. "
                f"Resuming from chunk {verified + 1}…"
            )
            resume_from = verified
        else:
            saved = None  # nothing usable

    # ── Extraction loop ───────────────────────────────────────────────────────
    cached_after_resume = (
        sum(1 for i in range(resume_from, total) if _cache_load(all_chunk_keys[i]) is not None)
        if use_cache else 0
    )
    uncached   = (total - resume_from) - cached_after_resume
    skip_count = resume_from + cached_after_resume

    n_compress_batches     = max(0, -(-total // _COMPRESS_BATCH))
    needs_compress_estimate = (total * 800) > _MAX_SYNTHESIS_CHARS
    est_seconds = (
        uncached * 10
        + max(0, uncached - 1) * int(_INTER_CHUNK_DELAY_BASE)
        + (n_compress_batches * 10 if needs_compress_estimate else 0)
        + 20
    )
    est_min = est_seconds // 60
    est_sec = est_seconds % 60
    est_str = f"{est_min}m {est_sec}s" if est_min else f"{est_sec}s"

    resume_note = f" · ♻️ resuming from chunk {resume_from + 1}" if resume_from > 0 else ""
    cache_note  = f" · ✅ {skip_count} chunks cached/resumed" if skip_count > 0 else ""
    progress(
        f"📄 Long transcript — {total} chunks ({uncached} to fetch{resume_note}{cache_note}).\n"
        f"⏱️  Estimated time: ~{est_str}  "
        f"(each new chunk ≈ ~10s LLM + {int(_INTER_CHUNK_DELAY_BASE)}s adaptive pause)\n"
        f"{'☕ Grab a coffee!' if est_min >= 5 else '⚡ Should be quick!'}"
    )

    t_start         = time.monotonic()
    all_notes:  list[str] = []
    keys_done:  list[str] = []
    delay           = _INTER_CHUNK_DELAY_BASE
    fast_streak     = 0
    api_calls_made  = 0

    for i, chunk in enumerate(chunks, 1):
        ck = all_chunk_keys[i - 1]

        # Load already-verified resumed chunks directly from cache
        if i <= resume_from:
            notes = _cache_load(ck)
            if notes:
                all_notes.append(f"=== CHUNK {i} NOTES ===\n{notes}")
            keys_done.append(ck)
            continue

        cached_notes = _cache_load(ck) if use_cache else None

        if cached_notes is not None:
            progress(f"  ⚡ Chunk {i}/{total} — loaded from cache (no API call)")
            all_notes.append(f"=== CHUNK {i} NOTES ===\n{cached_notes}")
            keys_done.append(ck)
            if run_key:
                _run_state_save(run_key, {
                    "stage": "extracting",
                    "total_chunks": total,
                    "last_completed_chunk": i,
                    "chunk_keys": keys_done[:],
                })
            continue

        elapsed        = int(time.monotonic() - t_start)
        remaining_api  = uncached - api_calls_made
        eta            = remaining_api * (10 + int(delay))
        progress(
            f"🔍 Extracting chunk {i}/{total}… "
            f"(elapsed {elapsed}s · ~{eta}s remaining · delay={delay:.0f}s)"
        )

        call_start = time.monotonic()
        try:
            notes = _extract_notes(chunk, model, temperature, on_wait=progress)
        except RuntimeError as exc:
            exc_msg = str(exc)
            if "403" in exc_msg or "rate limit" in exc_msg.lower():
                saved_count = i - 1
                progress(
                    f"⚠️  Rate limited at chunk {i}/{total}. "
                    f"💾 Snapshot saved ({saved_count} chunk{'s' if saved_count != 1 else ''} done). "
                    f"Wait ~60s, then click ▶ Process — it will resume from chunk {i} automatically."
                )
            raise
        call_elapsed = time.monotonic() - call_start
        api_calls_made += 1

        if use_cache:
            _cache_save(ck, notes)

        all_notes.append(f"=== CHUNK {i} NOTES ===\n{notes}")
        keys_done.append(ck)

        # ── Savepoint after every successful API extraction ──────────────────
        if run_key:
            _run_state_save(run_key, {
                "stage": "extracting",
                "total_chunks": total,
                "last_completed_chunk": i,
                "chunk_keys": keys_done[:],
            })

        # Adaptive delay:
        # • call_elapsed ≥ 65s → a 403 retry happened → jump to 65s inter-chunk pause
        #   (API needs a full minute to recover; smaller pauses don't help)
        # • call_elapsed > 30s (but < 65s) → mildly slow → back off gently
        # • 3 consecutive fast calls → relax back toward base delay
        if call_elapsed >= 65:
            delay = _INTER_CHUNK_DELAY_403   # hard jump — API was rate-limited
            fast_streak = 0
        elif call_elapsed > 30:
            delay = min(delay * 1.5, _INTER_CHUNK_DELAY_MAX)
            fast_streak = 0
        else:
            fast_streak += 1
            if fast_streak >= 3 and delay > _INTER_CHUNK_DELAY_BASE:
                delay = max(delay * 0.75, _INTER_CHUNK_DELAY_BASE)
                fast_streak = 0

        if i < total:
            if delay >= _INTER_CHUNK_DELAY_403:
                progress(
                    f"  ⏸️  Pausing {delay:.0f}s — API needs to cool down after rate limit "
                    f"(chunk {i + 1}/{total} up next)"
                )
            else:
                progress(
                    f"  ⏸️  Pausing {delay:.1f}s"
                    + (" (rate-limit backoff)" if delay > _INTER_CHUNK_DELAY_BASE else "")
                    + f" · chunk {i + 1}/{total} up next"
                )
            time.sleep(delay)

    # ── Post-extraction: dedup + compression ─────────────────────────────────
    combined_notes = _dedup_notes("\n\n".join(all_notes))

    if len(combined_notes) > _MAX_SYNTHESIS_CHARS:
        raw_size = len(combined_notes)
        # Step 1: local Python compression — zero API calls
        progress(
            f"📦 Notes are {raw_size:,} chars — running local compression (no API call)…"
        )
        combined_notes = _local_compress_notes(all_notes, _LOCAL_COMPRESS_TARGET)
        progress(
            f"  ✅ Local compression: {raw_size:,} → {len(combined_notes):,} chars"
        )

        # Step 2: if still too large, fall back to LLM compression
        if len(combined_notes) > _MAX_SYNTHESIS_CHARS:
            n_batches = -(-len(all_notes) // _COMPRESS_BATCH)
            progress(
                f"📦 Still {len(combined_notes):,} chars after local compression — "
                f"falling back to LLM compression in {n_batches} batches… (~{n_batches * 10}s)"
            )
            # Savepoint: entering LLM compression
            if run_key:
                _run_state_save(run_key, {
                    "stage": "compressing",
                    "total_chunks": total,
                    "all_notes": all_notes,
                    "last_completed_batch": -1,
                    "completed_batches": [],
                })
            combined_notes = _compress_notes_batched(
                all_notes, model, temperature, on_progress,
                run_key=run_key, total_chunks=total,
            )

    # Savepoint: compression done (or not needed), entering synthesis
    if run_key:
        _run_state_save(run_key, {
            "stage": "synthesising",
            "total_chunks": total,
            "final_notes": combined_notes,
        })

    progress(f"✍️  Synthesising final Markdown guide using {synth_model}… (~20s, almost done!)")
    try:
        result = _synthesise_from_notes(combined_notes, synth_model, temperature, on_wait=progress)
    except RuntimeError as exc:
        exc_msg = str(exc)
        if "403" in exc_msg or "rate limit" in exc_msg.lower():
            progress(
                "⚠️  Rate limited during final synthesis. "
                "💾 Snapshot saved (all chunks + compression done). "
                "Wait ~60s, then click ▶ Process — it will skip straight to synthesis."
            )
        raise

    # Clear savepoint on success
    if run_key:
        _run_state_clear(run_key)

    return result


# ── Internal helpers ──────────────────────────────────────────────────────────

def _normalise(text: str) -> str:
    """Remove timestamps, clean whitespace."""
    # YouTube-style timestamps: "0:00", "1:23:45"
    text = re.sub(r'\b\d{1,2}:\d{2}(?::\d{2})?\b', '', text)
    # Speaker labels: "[Speaker 1]:" or "John:"
    text = re.sub(r'^\[?[A-Za-z][A-Za-z0-9 ]{0,30}\]?\s*:\s*', '', text, flags=re.MULTILINE)
    # Collapse whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def _split_chunks(text: str, size: int) -> Generator[str, None, None]:
    """Split text at sentence boundaries into ~size char chunks."""
    sentences = re.split(r'(?<=[.!?])\s+', text)
    current: list[str] = []
    current_len = 0

    for sentence in sentences:
        if current_len + len(sentence) > size and current:
            yield ' '.join(current)
            current = [sentence]
            current_len = len(sentence)
        else:
            current.append(sentence)
            current_len += len(sentence)

    if current:
        yield ' '.join(current)


def _local_compress_notes(all_notes: list[str], target_chars: int) -> str:
    """
    Reduce combined chunk notes to <= target_chars using Python only — no API call.

    Strategy (in order):
      1. Deduplicate near-identical bullet lines across all chunks.
      2. Prioritise important lines (code, warnings, quotes, headers).
      3. Truncate verbose lines (> 200 chars) to 200 chars.
      4. If still over target, proportionally drop lower-priority lines from each chunk.

    Returns the compressed text ready for synthesis.
    """
    # Split into per-chunk blocks
    blocks: list[tuple[str, list[str]]] = []  # (header, lines)
    for note in all_notes:
        lines = note.splitlines()
        header = lines[0] if lines and lines[0].startswith("===") else ""
        body   = lines[1:] if header else lines
        blocks.append((header, body))

    # Deduplicate: normalise each line and track seen fingerprints
    seen_fps: set[str] = set()

    def _fp(line: str) -> str:
        """Rough fingerprint: lowercase, strip punctuation/spaces."""
        return re.sub(r'[^a-z0-9]', '', line.lower())[:80]

    def _priority(line: str) -> int:
        """Higher = more important. Keep highest-priority lines when trimming."""
        l = line.lower()
        if '`' in line or '```' in line:         return 4  # code
        if '⚠' in line or 'warning' in l:        return 3  # warning
        if '"' in line or "'" in line:            return 2  # quote/analogy
        if line.strip().startswith(('-', '*', '•')): return 1  # regular bullet
        return 0

    deduped: list[tuple[str, list[str]]] = []
    for header, lines in blocks:
        unique: list[str] = []
        for line in lines:
            stripped = line.strip()
            if not stripped:
                continue
            fp = _fp(stripped)
            if fp and fp not in seen_fps:
                seen_fps.add(fp)
                unique.append(stripped)
        deduped.append((header, unique))

    # Truncate verbose lines
    def _trunc(line: str, max_len: int = 200) -> str:
        return line[:max_len] + "…" if len(line) > max_len else line

    truncated = [(h, [_trunc(l) for l in lines]) for h, lines in deduped]

    # Check if already within target
    combined = "\n\n".join(
        (h + "\n" if h else "") + "\n".join(ls)
        for h, ls in truncated
    )
    if len(combined) <= target_chars:
        return combined

    # Proportional trim: give each chunk a budget proportional to target
    n_blocks = len(truncated)
    budget_per_block = max(200, target_chars // max(n_blocks, 1))

    trimmed: list[tuple[str, list[str]]] = []
    for header, lines in truncated:
        # Sort by priority descending; keep as many as fit in budget
        sorted_lines = sorted(lines, key=_priority, reverse=True)
        kept: list[str] = []
        remaining = budget_per_block - len(header)
        for line in sorted_lines:
            if remaining <= 0:
                break
            kept.append(line)
            remaining -= len(line) + 1
        # Restore original order for readability
        original_order = {l: i for i, l in enumerate(lines)}
        kept.sort(key=lambda l: original_order.get(l, 999))
        trimmed.append((header, kept))

    return "\n\n".join(
        (h + "\n" if h else "") + "\n".join(ls)
        for h, ls in trimmed
    )


def _compress_notes_batched(
    all_notes: list[str],
    model: str,
    temperature: float,
    on_progress: "callable[[str], None] | None" = None,
    start_batch: int = 0,
    existing_compressed: "list[str] | None" = None,
    run_key: "str | None" = None,
    total_chunks: int = 0,
) -> str:
    """
    Compress chunk notes into smaller batches using LLM.

    Supports checkpoint/resume:
        start_batch:         0-based index of first batch to process (0 = fresh run).
        existing_compressed: Already-completed batch summaries to prepend (from saved state).
        run_key:             If set, saves progress to run-state after every batch.
        total_chunks:        Stored in run-state for display purposes.
    """
    def progress(msg: str) -> None:
        if on_progress:
            on_progress(msg)

    batches = [
        all_notes[i : i + _COMPRESS_BATCH]
        for i in range(0, len(all_notes), _COMPRESS_BATCH)
    ]
    n_total    = len(batches)
    compressed = list(existing_compressed or [])

    for idx in range(start_batch, n_total):
        batch = batches[idx]
        progress(
            f"  🗜️ Compressing batch {idx + 1}/{n_total}… "
            f"(~{(n_total - idx - 1) * 10}s left in compression)"
        )
        messages = [
            {"role": "system", "content": _COMPRESS_SYSTEM},
            {"role": "user",   "content": "\n\n".join(batch)},
        ]
        try:
            summary = llm.chat(messages, model=model, temperature=temperature, on_wait=progress)
        except RuntimeError as exc:
            exc_msg = str(exc)
            if "403" in exc_msg or "rate limit" in exc_msg.lower():
                progress(
                    f"⚠️  Rate limited during compression batch {idx + 1}/{n_total}. "
                    f"💾 Snapshot saved ({idx} batch{'es' if idx != 1 else ''} done). "
                    f"Wait ~60s, then click ▶ Process — it will resume compression from batch {idx + 1}."
                )
            raise
        compressed.append(f"=== COMPRESSED BATCH {idx + 1} ===\n{summary}")

        # Savepoint after each batch — enables per-batch resume on next run
        if run_key:
            _run_state_save(run_key, {
                "stage": "compressing",
                "total_chunks": total_chunks,
                "all_notes": all_notes,
                "last_completed_batch": idx,
                "completed_batches": compressed[:],
            })

    return "\n\n".join(compressed)


def _extract_notes(
    chunk: str,
    model: str,
    temperature: float,
    on_wait: "callable[[str], None] | None" = None,
) -> str:
    messages = [
        {"role": "system", "content": _NOTES_SYSTEM},
        {"role": "user", "content": chunk},
    ]
    return llm.chat(messages, model=model, temperature=temperature, on_wait=on_wait)


def _single_pass(text: str, model: str, temperature: float) -> str:
    messages = [
        {"role": "system", "content": _SYNTHESIS_SYSTEM},
        {"role": "user", "content": f"Convert this transcript to a structured Markdown guide:\n\n{text}"},
    ]
    return llm.chat(messages, model=model, temperature=temperature)


def _synthesise_from_notes(
    notes: str,
    model: str,
    temperature: float,
    on_wait: "callable[[str], None] | None" = None,
) -> str:
    messages = [
        {"role": "system", "content": _SYNTHESIS_SYSTEM},
        {
            "role": "user",
            "content": (
                "Using the following structured notes extracted from a transcript, "
                "produce a complete well-structured Markdown guide. "
                "Synthesise all chunks into one coherent document — deduplicate, "
                "merge related concepts, and ensure logical flow.\n\n"
                f"{notes}"
            ),
        },
    ]
    return llm.chat(messages, model=model, temperature=temperature, on_wait=on_wait)


# ── Cache helpers ─────────────────────────────────────────────────────────────

def _cache_key(chunk: str, model: str, temperature: float) -> str:
    """
    Stable cache key: SHA-256 of (chunk text + model + temperature + pipeline version).
    Changing any extraction-affecting parameter auto-invalidates old entries.
    """
    raw = f"{chunk}|{model}|{temperature:.4f}|{_NOTES_SYSTEM[:64]}|v{_PIPELINE_VERSION}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _cache_load(key: str) -> str | None:
    """Return cached notes string, or None if not found / expired."""
    path = _CACHE_DIR / f"{key}.json"
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data.get("notes")
    except Exception:
        return None


def _cache_save(key: str, notes: str) -> None:
    """Persist chunk notes to disk cache."""
    _CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = _CACHE_DIR / f"{key}.json"
    path.write_text(
        json.dumps({"notes": notes, "pipeline_version": _PIPELINE_VERSION}, ensure_ascii=False),
        encoding="utf-8",
    )


def clear_cache() -> int:
    """Delete all cached chunk note files. Returns number of files deleted."""
    if not _CACHE_DIR.exists():
        return 0
    count = 0
    for f in _CACHE_DIR.glob("*.json"):
        f.unlink()
        count += 1
    return count


def cache_stats() -> dict:
    """Return cache directory stats: file count and total size in bytes."""
    if not _CACHE_DIR.exists():
        return {"count": 0, "size_bytes": 0}
    files = list(_CACHE_DIR.glob("*.json"))
    return {"count": len(files), "size_bytes": sum(f.stat().st_size for f in files)}


# ── Dedup helper ──────────────────────────────────────────────────────────────

def _dedup_notes(combined: str) -> str:
    """
    Remove exact-duplicate bullet point lines from combined notes.
    Preserves order and keeps section headers. Typically reduces notes by 15-30%.
    """
    seen: set[str] = set()
    out: list[str] = []
    for line in combined.splitlines():
        stripped = line.strip()
        # Keep section headers and blank lines always
        if not stripped or stripped.startswith("==="):
            out.append(line)
            continue
        if stripped not in seen:
            seen.add(stripped)
            out.append(line)
    return "\n".join(out)


# ── Run-state savepoint helpers ───────────────────────────────────────────────

def _run_state_key(clean_text: str, model: str, temperature: float) -> str:
    """
    Stable key for a full pipeline run.
    SHA-256 of the COMPLETE normalised transcript + model + temperature + pipeline version.
    Any change to transcript or settings produces a different key → fresh run.
    """
    raw = f"{clean_text}|{model}|{temperature:.4f}|v{_PIPELINE_VERSION}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _run_state_load(key: str) -> dict | None:
    """
    Load and validate a saved run state.
    Returns None on missing file, invalid JSON, schema mismatch, or version mismatch.
    All errors are silently discarded so a corrupt snapshot never blocks a fresh run.
    """
    path = _RUN_STATE_DIR / f"{key}.json"
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("schema") != _RUN_STATE_SCHEMA:
            return None
        if data.get("pipeline_version") != _PIPELINE_VERSION:
            return None
        return data
    except Exception:
        return None


def _run_state_save(key: str, state: dict) -> None:
    """
    Write run state atomically: temp file → rename.
    On Windows rename is best-effort but still far safer than direct overwrite
    because the original file stays intact if the process is killed mid-write.
    """
    _RUN_STATE_DIR.mkdir(parents=True, exist_ok=True)
    path = _RUN_STATE_DIR / f"{key}.json"
    full = {"schema": _RUN_STATE_SCHEMA, "pipeline_version": _PIPELINE_VERSION, **state}
    tmp  = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(full, ensure_ascii=False), encoding="utf-8")
    tmp.replace(path)


def _run_state_clear(key: str) -> None:
    """Delete the run-state file for a completed or abandoned run."""
    for suffix in (".json", ".tmp"):
        try:
            (_RUN_STATE_DIR / f"{key}{suffix}").unlink(missing_ok=True)
        except Exception:
            pass


def clear_run_states() -> int:
    """Delete all run-state checkpoint files. Returns the number of files deleted."""
    if not _RUN_STATE_DIR.exists():
        return 0
    count = 0
    for f in _RUN_STATE_DIR.glob("*.json"):
        try:
            f.unlink()
            count += 1
        except Exception:
            pass
    return count


def run_state_stats() -> dict:
    """Return stats about saved run states: count and total size in bytes."""
    if not _RUN_STATE_DIR.exists():
        return {"count": 0, "size_bytes": 0}
    files = list(_RUN_STATE_DIR.glob("*.json"))
    return {"count": len(files), "size_bytes": sum(f.stat().st_size for f in files)}
