"""
summarize.py — Generate a one-paragraph summary for every section in a converted
               document JSON (produced by convert.py) using the GitHub Copilot LLM.

Usage:
    python summarize.py <doc.json> [summary.json] [--model gpt-4o-mini]

If the output path is omitted, writes <doc_stem>.summary.json next to the input file
(same directory — mirrors the convert.py output convention).

Output schema:
{
  "filename": "...",
  "file_type": "...",
  "model": "...",
  "summaries": [
    {
      "section_id": 0,
      "heading": "Introduction",
      "page": 1,
      "summary": "..."
    }
  ]
}
"""

import sys
import json
import argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

from ask import get_token_or_raise, AVAILABLE_MODELS, GITHUB_MODELS_ENDPOINT

SUMMARY_BATCH_SIZE = 5  # number of sections summarized concurrently


SUMMARY_SYSTEM_PROMPT = (
    "You are a precise document analyst. "
    "Summarize the provided section content in 1–3 concise sentences. "
    "Capture the key facts, decisions, or findings only. "
    "Do NOT add outside knowledge. "
    "Respond with plain text — no bullet points, no markdown."
)


def _summarize_section(client, section: dict, model: str) -> str:
    """Call the LLM and return a plain-text summary for one section."""
    heading = section.get("heading") or "Section"
    content = (section.get("content") or "").strip()

    if not content:
        return "(no content)"

    # Truncate very long sections to avoid token limits (~6 000 chars ≈ ~1 500 tokens)
    if len(content) > 6000:
        content = content[:6000] + "\n[…truncated]"

    user_msg = f"Section heading: {heading}\n\nSection content:\n{content}"

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SUMMARY_SYSTEM_PROMPT},
            {"role": "user", "content": user_msg},
        ],
        temperature=0.2,
        max_tokens=256,
    )
    return response.choices[0].message.content.strip()


def summarize(json_path: str, output_path: str | None = None, model: str = "gpt-4o-mini") -> str:
    """
    Summarize every section in *json_path* using the Copilot LLM.
    Writes a summary JSON next to the source file and returns the output path.
    """
    from openai import OpenAI

    src = Path(json_path)
    if not src.exists():
        raise FileNotFoundError(f"File not found: {json_path}")

    doc = json.loads(src.read_text(encoding="utf-8"))
    sections = doc.get("sections", [])

    if not sections:
        raise ValueError("No sections found in the JSON — nothing to summarize.")

    token = get_token_or_raise()
    client = OpenAI(base_url=GITHUB_MODELS_ENDPOINT, api_key=token)

    # Process sections concurrently in batches of SUMMARY_BATCH_SIZE
    summaries = [None] * len(sections)

    def _summarize_indexed(idx: int, sec: dict):
        print(f"  Summarizing section {idx + 1}/{len(sections)}: {sec.get('heading', '')[:60]}…")
        return idx, {
            "section_id": sec.get("id", idx),
            "heading": sec.get("heading") or "Section",
            "page": sec.get("page"),
            "summary": _summarize_section(client, sec, model),
        }

    for batch_start in range(0, len(sections), SUMMARY_BATCH_SIZE):
        batch = list(enumerate(sections[batch_start:batch_start + SUMMARY_BATCH_SIZE], start=batch_start))
        with ThreadPoolExecutor(max_workers=SUMMARY_BATCH_SIZE) as executor:
            futures = {executor.submit(_summarize_indexed, idx, sec): idx for idx, sec in batch}
            for future in as_completed(futures):
                idx, entry = future.result()
                summaries[idx] = entry

    result = {
        "filename": doc.get("filename", src.name),
        "file_type": doc.get("file_type", "?"),
        "model": model,
        "summaries": summaries,
    }

    # Default output: same directory as the source JSON, <stem>.summary.json
    out = output_path or str(src.with_name(src.stem + ".summary.json"))
    Path(out).write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"✓ Summaries written → '{out}'  ({len(summaries)} sections)")
    return out


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Summarize each section of a converted document JSON using GitHub Copilot LLM."
    )
    parser.add_argument("json_file", help="Path to the JSON tree produced by convert.py")
    parser.add_argument("output", nargs="?", default=None, help="Output path (default: <json_stem>.summary.json)")
    parser.add_argument("--model", default="gpt-4o-mini", choices=AVAILABLE_MODELS, help="LLM model to use")
    args = parser.parse_args()

    try:
        summarize(args.json_file, args.output, model=args.model)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
