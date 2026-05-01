"""
ask.py — CLI helper script: load a JSON tree document and ask a question via GitHub Copilot LLM.

Usage:
    python ask.py <json_file> "<your question>" [--model gpt-4o-mini]

Authentication (no token needed manually):
  1. Uses your already-logged-in GitHub CLI (`gh auth login`)  ← preferred
  2. Falls back to the GITHUB_TOKEN environment variable

The full document JSON tree is sent as context — the LLM acts as the retrieval agent.
No BM25, no chunking, no vector search. The model reads the structured JSON and answers.
"""

import sys
import json
import os
import argparse
import subprocess
from pathlib import Path


GITHUB_MODELS_ENDPOINT = "https://models.inference.ai.azure.com"

AVAILABLE_MODELS = [
    "gpt-4o-mini",
    "gpt-4o",
    "Meta-Llama-3.1-70B-Instruct",
    "Meta-Llama-3.1-8B-Instruct",
    "Phi-3.5-mini-instruct",
    "mistral-large",
    "mistral-small",
]

SYSTEM_PROMPT = """You are a helpful assistant that answers questions based ONLY on the provided document.
The document is given as a structured JSON tree with sections and tables.

Rules:
- Answer using only information from the document JSON. Do NOT use outside knowledge.
- If the answer is not in the document, say "I could not find this information in the document."
- When referencing specific data, mention the section heading or table it came from.
- Be concise and clear.
"""


def _resolve_github_token() -> str | None:
    """
    Resolve a GitHub token without requiring manual input:
      1. Try `gh auth token` (GitHub CLI — already authenticated)
      2. Fall back to GITHUB_TOKEN environment variable
    Returns the token string or None if unavailable.
    """
    # Try GitHub CLI
    try:
        result = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True, text=True, timeout=5
        )
        token = result.stdout.strip()
        if token and result.returncode == 0:
            return token
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Fall back to env var
    return os.environ.get("GITHUB_TOKEN") or None


def get_token_or_raise() -> str:
    """Return the resolved GitHub token or raise a clear error."""
    token = _resolve_github_token()
    if not token:
        raise RuntimeError(
            "No GitHub authentication found.\n\n"
            "Option 1 (recommended): Install GitHub CLI and run:\n"
            "  gh auth login\n\n"
            "Option 2: Set an environment variable:\n"
            "  set GITHUB_TOKEN=ghp_your_token   (Windows)\n"
            "  export GITHUB_TOKEN=ghp_your_token (Mac/Linux)\n\n"
            "Get a free token at: https://github.com/settings/tokens/new (no scopes needed)"
        )
    return token


def build_context(doc: dict) -> str:
    """Convert the JSON tree into a readable text block for the LLM prompt."""
    parts = [f"Document: {doc.get('filename', 'unknown')} (type: {doc.get('file_type', '?')})\n"]

    for sec in doc.get("sections", []):
        heading = sec.get("heading") or "Section"
        content = sec.get("content", "").strip()
        if content:
            parts.append(f"## {heading}\n{content}\n")

    for tbl in doc.get("tables", []):
        sec_id = tbl.get("section_id", -1)
        # Find corresponding section heading
        sec_heading = "Table"
        for sec in doc.get("sections", []):
            if sec.get("id") == sec_id:
                sec_heading = sec.get("heading") or "Table"
                break

        headers = tbl.get("headers", [])
        rows = tbl.get("rows", [])
        if headers or rows:
            parts.append(f"### Table in '{sec_heading}'")
            if headers:
                parts.append("| " + " | ".join(str(h) for h in headers) + " |")
                parts.append("|" + "|".join("---" for _ in headers) + "|")
            for row in rows[:100]:  # limit table rows in context to avoid token overflow
                parts.append("| " + " | ".join(str(c) for c in row) + " |")
            if len(rows) > 100:
                parts.append(f"_...{len(rows) - 100} more rows not shown_")
            parts.append("")

    return "\n".join(parts)


def ask(json_path: str, question: str, model: str = "gpt-4o-mini") -> str:
    """Send the full document JSON tree + question to the GitHub Models LLM and return the answer."""
    from openai import OpenAI

    token = get_token_or_raise()
    doc = json.loads(Path(json_path).read_text(encoding="utf-8"))
    context = build_context(doc)

    client = OpenAI(base_url=GITHUB_MODELS_ENDPOINT, api_key=token)

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": f"Here is the document:\n\n{context}\n\n---\n\nQuestion: {question}"
            }
        ],
        temperature=0.2,
        max_tokens=1024,
    )

    return response.choices[0].message.content.strip()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ask a question about a converted document JSON tree.")
    parser.add_argument("json_file", help="Path to the JSON tree file produced by convert.py")
    parser.add_argument("question", help="The question to ask about the document")
    parser.add_argument("--model", default="gpt-4o-mini", choices=AVAILABLE_MODELS, help="Model to use")
    args = parser.parse_args()

    try:
        answer = ask(args.json_file, args.question, model=args.model)
        print("\n" + "=" * 60)
        print("Answer:")
        print("=" * 60)
        print(answer)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
