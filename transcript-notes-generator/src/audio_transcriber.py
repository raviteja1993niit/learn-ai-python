"""
audio_transcriber.py — Free local audio transcription using faster-whisper.

faster-whisper uses CTranslate2 (no PyTorch required) and runs on CPU.
Models are downloaded once and cached in ~/.cache/huggingface/hub/.

Available model sizes (quality vs speed trade-off):
  tiny   ~75 MB  — fastest, lower accuracy
  base   ~145 MB — good balance (default)
  small  ~465 MB — better accuracy
  medium ~1.5 GB — high accuracy, slower
"""
from __future__ import annotations

import io
import os
import tempfile
from pathlib import Path

WHISPER_MODELS = ["tiny", "base", "small", "medium"]
DEFAULT_WHISPER_MODEL = "base"

# Cached model instance (module-level, reused across Streamlit reruns)
_model_cache: dict[str, object] = {}


def _get_model(model_size: str):
    """Load and cache the WhisperModel. Downloads on first use."""
    if model_size not in _model_cache:
        try:
            from faster_whisper import WhisperModel
        except ImportError as exc:
            raise ImportError(
                "faster-whisper is not installed. Run: pip install faster-whisper"
            ) from exc

        _model_cache[model_size] = WhisperModel(
            model_size,
            device="cpu",
            compute_type="int8",   # quantised — fastest on CPU
        )
    return _model_cache[model_size]


def transcribe_bytes(
    audio_bytes: bytes,
    model_size: str = DEFAULT_WHISPER_MODEL,
    language: str | None = None,
) -> str:
    """
    Transcribe audio bytes (WAV/MP3/M4A/OGG etc.) to plain text.

    Args:
        audio_bytes: Raw audio file bytes (from st.audio_input or file upload)
        model_size:  Whisper model size (tiny/base/small/medium)
        language:    Optional ISO language code (e.g. "en"). None = auto-detect.

    Returns:
        Transcribed text string.

    Raises:
        ImportError: If faster-whisper is not installed.
        RuntimeError: If transcription produces empty output.
    """
    model = _get_model(model_size)

    # Write to temp file — faster-whisper expects a file path
    suffix = ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        segments, info = model.transcribe(
            tmp_path,
            language=language,
            beam_size=5,
            vad_filter=True,          # skip silent gaps
            vad_parameters={"min_silence_duration_ms": 500},
        )
        text = " ".join(seg.text.strip() for seg in segments).strip()
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass

    if not text:
        raise RuntimeError(
            "Transcription returned empty text. "
            "The audio may be silent or contain only noise."
        )
    return text


def transcribe_file(
    file_path: str | Path,
    model_size: str = DEFAULT_WHISPER_MODEL,
    language: str | None = None,
) -> str:
    """Transcribe an audio file from disk path."""
    audio_bytes = Path(file_path).read_bytes()
    return transcribe_bytes(audio_bytes, model_size=model_size, language=language)
