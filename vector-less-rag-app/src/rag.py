"""
rag.py — Vectorless RAG pipeline using PageIndex (no chunking, no VectorDB).

Flow: parse file → build PageIndex → BM25 search over pages
      → send full pages as context → LLM answer → multi-turn history
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Tuple

from src.parser import Page, parse_file
from src.page_index import PageIndex
from src.llm import generate_answer


@dataclass
class RAGResult:
    answer: str
    source_pages: List[Tuple[Page, float]] = field(default_factory=list)
    context_used: str = ""


class RAGPipeline:
    def __init__(
        self,
        filename: str,
        file_bytes: bytes,
        top_k: int = 5,
        model: str = "claude-haiku-4.5",
        github_token: str = "",
        provider: str = "GitHub Copilot",
    ):
        self.model = model
        self.top_k = top_k
        self.github_token = github_token
        self.provider = provider
        self.filename = filename
        self.chat_history: List[dict] = []  # multi-turn conversation

        pages = parse_file(filename, file_bytes)
        self.index = PageIndex(pages)

    # ── Properties ──────────────────────────────────────────────────────────

    @property
    def pages(self) -> List[Page]:
        return self.index.pages

    @property
    def stats(self):
        return self.index.stats

    # ── Ask ──────────────────────────────────────────────────────────────────

    def ask(self, question: str) -> RAGResult:
        """Retrieve relevant pages and generate an answer using chat history."""
        results = self.index.search(question, top_k=self.top_k)
        context = self.index.build_context(results)

        answer = generate_answer(
            question=question,
            context=context,
            model=self.model,
            github_token=self.github_token,
            provider=self.provider,
            chat_history=self.chat_history,
        )

        # Append this turn to history for follow-up questions
        self.chat_history.append({"role": "user",      "content": question})
        self.chat_history.append({"role": "assistant", "content": answer})

        return RAGResult(answer=answer, source_pages=results, context_used=context)

    def clear_history(self) -> None:
        self.chat_history = []

