"""
test_models.py — CLI script to test and compare all (or selected) models.

Usage:
    # Test all GitHub Copilot models with a built-in sample document
    python test_models.py

    # Test specific models only
    python test_models.py --models gpt-4o-mini gpt-4.1 claude-sonnet-4.5

    # Test with your own PDF/DOCX/XLSX file
    python test_models.py --file my_doc.pdf --question "What is the main topic?"

    # Test a single model quickly
    python test_models.py --models gpt-4o-mini --question "Summarize the document"

    # Test GitHub Models provider instead
    python test_models.py --provider "GitHub Models" --models gpt-4o gpt-4o-mini
"""
import argparse
import time
from src.llm import MODELS_BY_PROVIDER, generate_answer, get_gh_cli_token
from src.chunker import chunk_text
from src.retriever import BM25Retriever

# ── Built-in sample document (used when no --file is provided) ─────────────
SAMPLE_DOCUMENT = """
GitHub Copilot is an AI-powered coding assistant developed by GitHub and OpenAI.
It uses large language models trained on publicly available code to suggest
completions, generate functions, write tests, and explain code.

Copilot integrates directly into editors like Visual Studio Code, JetBrains IDEs,
and Neovim. It supports dozens of programming languages including Python,
JavaScript, TypeScript, Go, Ruby, and Rust.

The GitHub Models API provides access to a variety of AI models including GPT-4o,
Claude, Llama, Mistral, and Phi series models. Developers can experiment with
these models for free using a GitHub Personal Access Token.

BM25 is a ranking function used in information retrieval. It scores documents
based on term frequency and inverse document frequency without requiring vector
embeddings. This makes it fast and lightweight compared to semantic search.
"""

SAMPLE_QUESTIONS = [
    "What is GitHub Copilot?",
    "Which editors does Copilot support?",
    "What is BM25 and how does it work?",
    "What models are available on GitHub Models API?",
]


def load_document(file_path: str) -> str:
    """Load text from a PDF, DOCX, or XLSX file."""
    from src.parser import parse_file
    with open(file_path, "rb") as f:
        file_bytes = f.read()
    return parse_file(file_path, file_bytes)


def run_test(
    question: str,
    context_chunks: list[str],
    models: list[str],
    provider: str,
    token: str,
) -> dict[str, dict]:
    results = {}
    for model in models:
        print(f"  🤖 {model:<35}", end="", flush=True)
        start = time.time()
        try:
            answer = generate_answer(
                question,
                context_chunks,
                model=model,
                github_token=token,
                provider=provider,
            )
            elapsed = time.time() - start
            results[model] = {"status": "ok", "answer": answer, "time": elapsed}
            print(f"✅  {elapsed:.1f}s")
        except Exception as e:
            elapsed = time.time() - start
            results[model] = {"status": "error", "answer": str(e)[:120], "time": elapsed}
            print(f"❌  {elapsed:.1f}s  ({str(e)[:60]})")
    return results


def print_comparison(question: str, results: dict[str, dict]) -> None:
    print(f"\n{'─'*70}")
    print(f"Q: {question}")
    print(f"{'─'*70}")
    for model, r in results.items():
        status = "✅" if r["status"] == "ok" else "❌"
        print(f"\n{status} [{model}]  ({r['time']:.1f}s)")
        print(f"   {r['answer'][:300]}{'...' if len(r['answer']) > 300 else ''}")


def main():
    parser = argparse.ArgumentParser(description="Test RAG app with multiple LLM models")
    parser.add_argument("--provider", default="GitHub Copilot",
                        choices=list(MODELS_BY_PROVIDER.keys()),
                        help="API provider to use")
    parser.add_argument("--models", nargs="+",
                        help="Models to test (default: all models for the provider)")
    parser.add_argument("--file", help="Path to a PDF/DOCX/XLSX file to use as document")
    parser.add_argument("--question", help="Single question to test (default: runs all sample questions)")
    parser.add_argument("--top-k", type=int, default=3, help="Top-K chunks to retrieve (default: 3)")
    args = parser.parse_args()

    # ── Token ────────────────────────────────────────────────────────────────
    token = get_gh_cli_token()
    if not token:
        print("❌ No GitHub token found. Run: gh auth login")
        return
    print(f"🔑 Token: auto-detected from gh CLI")
    print(f"📡 Provider: {args.provider}")

    # ── Models ───────────────────────────────────────────────────────────────
    models = args.models or MODELS_BY_PROVIDER[args.provider]
    print(f"🧪 Models to test: {len(models)}")
    for m in models:
        print(f"   • {m}")

    # ── Document ─────────────────────────────────────────────────────────────
    if args.file:
        print(f"\n📄 Loading: {args.file}")
        text = load_document(args.file)
        print(f"   Extracted {len(text):,} characters")
    else:
        print(f"\n📄 Using built-in sample document ({len(SAMPLE_DOCUMENT):,} chars)")
        text = SAMPLE_DOCUMENT

    chunks = chunk_text(text, chunk_size=500, overlap=50)
    retriever = BM25Retriever(chunks)
    print(f"   Indexed {len(chunks)} chunks")

    # ── Questions ─────────────────────────────────────────────────────────────
    questions = [args.question] if args.question else SAMPLE_QUESTIONS
    all_results: dict[str, dict[str, dict]] = {}

    for i, question in enumerate(questions, 1):
        print(f"\n{'═'*70}")
        print(f"Question {i}/{len(questions)}: {question}")
        print(f"{'═'*70}")

        top_chunks = [chunk for _, chunk, _ in retriever.retrieve(question, top_k=args.top_k)]
        results = run_test(question, top_chunks, models, args.provider, token)
        all_results[question] = results
        print_comparison(question, results)

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"\n\n{'═'*70}")
    print("📊 SUMMARY")
    print(f"{'═'*70}")
    print(f"{'Model':<35} {'Pass':>5} {'Fail':>5} {'Avg Time':>10}")
    print(f"{'─'*35} {'─'*5} {'─'*5} {'─'*10}")
    for model in models:
        model_results = [all_results[q][model] for q in questions if model in all_results[q]]
        passed = sum(1 for r in model_results if r["status"] == "ok")
        failed = len(model_results) - passed
        avg_time = sum(r["time"] for r in model_results) / len(model_results) if model_results else 0
        print(f"{model:<35} {passed:>5} {failed:>5} {avg_time:>9.1f}s")


if __name__ == "__main__":
    main()
