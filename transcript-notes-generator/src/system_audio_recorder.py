"""
system_audio_recorder.py — Capture system/desktop audio (WASAPI loopback) on Windows.

Uses `pyaudiowpatch` — a PyAudio fork with native WASAPI loopback support.
Captures whatever is playing through the speakers (YouTube, video, music, any app).

Usage:
    list_loopback_devices()  → list of (index, name) tuples
    start_recording(index)   → starts background thread
    stop_recording()         → stops thread, returns WAV bytes
    is_recording()           → bool
"""
from __future__ import annotations

import io
import struct
import threading
import time
from typing import Optional

# Module-level state — survives Streamlit reruns within the same process
_stop_event: threading.Event    = threading.Event()
_audio_frames: list[bytes]      = []
_record_thread: Optional[threading.Thread] = None
_record_meta: dict              = {}   # stores samplerate / channels of active recording
_lock = threading.Lock()

_CHUNK_SIZE  = 1024   # frames per read call
_TARGET_RATE = 16_000  # Whisper optimal sample rate


def list_loopback_devices() -> list[tuple[int, str]]:
    """
    Return list of (device_index, device_name) for all WASAPI loopback devices.
    These represent system audio outputs (speakers, headphones).
    Raises RuntimeError with a helpful message if pyaudiowpatch is unavailable.
    """
    import pyaudiowpatch as pyaudio
    p = pyaudio.PyAudio()
    try:
        devices = []
        for i in range(p.get_device_count()):
            info = p.get_device_info_by_index(i)
            if info.get("isLoopbackDevice"):
                devices.append((info["index"], info["name"]))
        return devices
    finally:
        p.terminate()


def default_loopback_device() -> Optional[tuple[int, str]]:
    """
    Return the best default loopback device — tries WASAPI default output first,
    then falls back to first loopback device in the list.
    Returns None if no loopback device found.
    """
    import pyaudiowpatch as pyaudio
    p = pyaudio.PyAudio()
    try:
        # Try the WASAPI default output device → get its loopback counterpart
        try:
            wasapi_info = p.get_host_api_info_by_type(pyaudio.paWASAPI)
            default_out = p.get_device_info_by_index(wasapi_info["defaultOutputDevice"])
            loopback = p.get_loopback_device_info_by_speakers_info(default_out)
            return (loopback["index"], loopback["name"])
        except Exception:
            pass
        # Fallback — first loopback device
        for i in range(p.get_device_count()):
            info = p.get_device_info_by_index(i)
            if info.get("isLoopbackDevice"):
                return (info["index"], info["name"])
        return None
    finally:
        p.terminate()


def is_recording() -> bool:
    """True if a recording is currently in progress."""
    return _record_thread is not None and _record_thread.is_alive()


def start_recording(device_index: Optional[int] = None) -> None:
    """
    Start capturing system audio in a background thread.

    Args:
        device_index: pyaudio device index from list_loopback_devices().
                      Defaults to default_loopback_device() index.
    """
    global _record_thread, _audio_frames, _record_meta

    if is_recording():
        return

    # Resolve device
    if device_index is None:
        dev = default_loopback_device()
        if dev is None:
            raise RuntimeError(
                "No WASAPI loopback device found. "
                "Make sure audio is playing and try selecting a device manually."
            )
        device_index = dev[0]

    with _lock:
        _audio_frames = []
        _record_meta  = {}
        _stop_event.clear()

    _record_thread = threading.Thread(
        target=_record_loop,
        args=(device_index,),
        daemon=True,
    )
    _record_thread.start()
    # Brief wait to let thread initialise and populate _record_meta
    time.sleep(0.3)


def stop_recording() -> bytes:
    """
    Stop the recording thread and return captured audio as WAV bytes (16-bit PCM, 16 kHz mono).

    Raises:
        RuntimeError: If no audio was captured.
    """
    global _record_thread

    _stop_event.set()
    if _record_thread and _record_thread.is_alive():
        _record_thread.join(timeout=5.0)
    _record_thread = None

    with _lock:
        frames = list(_audio_frames)
        meta   = dict(_record_meta)

    if not frames:
        raise RuntimeError("No audio was captured. Was anything playing through the speakers?")

    raw_audio = b"".join(frames)
    src_rate    = int(meta.get("samplerate", 44100))
    src_channels = int(meta.get("channels", 2))

    return _to_wav_bytes(raw_audio, src_rate, src_channels)


# ── Internal ──────────────────────────────────────────────────────────────────

def _record_loop(device_index: int) -> None:
    """Background thread: open WASAPI loopback stream and accumulate frames."""
    import pyaudiowpatch as pyaudio

    p = pyaudio.PyAudio()
    try:
        info      = p.get_device_info_by_index(device_index)
        rate      = int(info["defaultSampleRate"])
        channels  = int(info["maxInputChannels"]) or 2

        with _lock:
            _record_meta["samplerate"] = rate
            _record_meta["channels"]   = channels

        stream = p.open(
            format=pyaudio.paInt16,
            channels=channels,
            rate=rate,
            input=True,
            input_device_index=device_index,
            frames_per_buffer=_CHUNK_SIZE,
        )
        try:
            while not _stop_event.is_set():
                chunk = stream.read(_CHUNK_SIZE, exception_on_overflow=False)
                with _lock:
                    _audio_frames.append(chunk)
        finally:
            stream.stop_stream()
            stream.close()
    except Exception:
        pass
    finally:
        p.terminate()


def _to_wav_bytes(raw_pcm: bytes, src_rate: int, src_channels: int) -> bytes:
    """
    Convert raw int16 PCM bytes to a WAV file in memory.
    Downmixes to mono and resamples to 16 kHz for Whisper compatibility.
    """
    import numpy as np

    # Parse int16 samples
    n_samples = len(raw_pcm) // (2 * src_channels)
    audio = np.frombuffer(raw_pcm, dtype=np.int16)
    audio = audio[: n_samples * src_channels].reshape(-1, src_channels)

    # Downmix to mono
    mono = audio.mean(axis=1).astype(np.int16)

    # Resample to 16 kHz using simple linear interpolation if needed
    if src_rate != _TARGET_RATE:
        import scipy.signal as signal
        mono_f32 = mono.astype(np.float32) / 32768.0
        resampled = signal.resample_poly(
            mono_f32,
            _TARGET_RATE,
            src_rate,
            padtype="line",
        )
        mono = (np.clip(resampled, -1.0, 1.0) * 32767).astype(np.int16)

    # Write WAV
    buf = io.BytesIO()
    _write_wav_header(buf, len(mono) * 2, _TARGET_RATE, 1)
    buf.write(mono.tobytes())
    buf.seek(0)
    return buf.read()


def _write_wav_header(buf: io.BytesIO, data_size: int, rate: int, channels: int) -> None:
    """Write a minimal 44-byte RIFF/WAV header."""
    bits = 16
    block_align = channels * bits // 8
    byte_rate   = rate * block_align
    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + data_size))
    buf.write(b"WAVE")
    buf.write(b"fmt ")
    buf.write(struct.pack("<IHHIIHH", 16, 1, channels, rate, byte_rate, block_align, bits))
    buf.write(b"data")
    buf.write(struct.pack("<I", data_size))
