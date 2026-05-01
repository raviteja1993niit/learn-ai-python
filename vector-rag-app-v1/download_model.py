"""
download_model.py — Download all-MiniLM-L6-v2 to ./models/ for fully offline use.
Uses urllib directly (bypasses httpx/requests) with SSL verification disabled.
Run this ONCE: python download_model.py
"""
import os
import ssl
import urllib.request
from pathlib import Path

# ── Full SSL bypass (corporate proxy) ─────────────────────────────────────────
_ctx = ssl._create_unverified_context()
_ctx.set_ciphers("DEFAULT@SECLEVEL=1")
_opener = urllib.request.build_opener(urllib.request.HTTPSHandler(context=_ctx))
urllib.request.install_opener(_opener)

# ── Model files to download ───────────────────────────────────────────────────
BASE_URL  = "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main"
LOCAL_DIR = Path(__file__).parent / "models" / "all-MiniLM-L6-v2"

FILES = [
    "modules.json",
    "sentence_bert_config.json",
    "config.json",
    "tokenizer_config.json",
    "tokenizer.json",
    "vocab.txt",
    "special_tokens_map.json",
    "model.safetensors",           # ~87 MB — main weights
    "1_Pooling/config.json",
]

def download_file(relative_path: str):
    url      = f"{BASE_URL}/{relative_path}"
    dest     = LOCAL_DIR / relative_path
    dest.parent.mkdir(parents=True, exist_ok=True)

    if dest.exists():
        print(f"  ✓ already exists: {relative_path}")
        return

    print(f"  ↓ {relative_path} … ", end="", flush=True)

    def _progress(block_num, block_size, total_size):
        if total_size > 0:
            pct = min(block_num * block_size / total_size * 100, 100)
            mb  = total_size / 1_048_576
            print(f"\r  ↓ {relative_path} … {pct:5.1f}%  ({mb:.1f} MB)", end="", flush=True)

    urllib.request.urlretrieve(url, dest, reporthook=_progress)
    print(f"\r  ✅ {relative_path:<45} ({dest.stat().st_size / 1_048_576:.1f} MB)")

# ── Run ───────────────────────────────────────────────────────────────────────
print(f"\nDownloading all-MiniLM-L6-v2 → {LOCAL_DIR}\n")

for f in FILES:
    try:
        download_file(f)
    except Exception as e:
        print(f"\n  ❌ Failed: {f}  →  {e}")

print(f"\n✅ Done!  Model is at: {LOCAL_DIR}")
print("Run:  python server.py")
