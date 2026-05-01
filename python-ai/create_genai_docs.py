import os

BASE = r"C:\Users\e135408\Downloads\personal-work\learn-ai\projects\python-ai\generative-ai"

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(content)
    lines = len(content.splitlines())
    size = os.path.getsize(path)
    print(f"  CREATED [{lines:>4} lines | {size:>7} bytes] {path}")

print("Writing all GenAI docs...")
