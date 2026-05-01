"""
rag.py — VectorRAGPipeline using ChromaDB + sentence-transformers.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Tuple

from src.parser import Page, parse_file
from src.vector_index import VectorIndex
from src.llm import generate_answer


@dataclass
class RAGResult:
    answer: str
    source_pages: List[Tuple[Page, float]] = field(default_factory=list)
    context_used: str = ""


class VectorRAGPipeline:
    def __init__(
        self,
        filename: str,
        file_bytes: bytes,
        session_id: str,
        top_k: int = 4,
        model: str = "claude-haiku-4.5",
        github_token: str = "",
        provider: str = "GitHub Copilot",
    ):
        self.model = model
        self.top_k = top_k
        self.github_token = github_token
        self.provider = provider
        self.filename = filename
        self.chat_history = []

        pages = parse_file(filename, file_bytes)
        self.index = VectorIndex(pages, session_id)

    @property
    def pages(self):
        return self.index.pages

    @property
    def stats(self):
        return self.index.stats

    def ask(self, question: str) -> RAGResult:
        results = self.index.search(question, top_k=self.top_k)
        context = self._build_context(results)
        answer = generate_answer(
            question=question,
            context=context,
            model=self.model,
            github_token=self.github_token,
            provider=self.provider,
            chat_history=self.chat_history,
        )
        self.chat_history.append({"role": "user", "content": question})
        self.chat_history.append({"role": "assistant", "content": answer})
        return RAGResult(answer=answer, source_pages=results, context_used=context)

    def _build_context(self, results: List[Tuple[Page, float]], max_chars: int = 24000) -> str:
        parts = []
        total = 0
        for page, score in results:
            header = f"{'='*60}\n📄 {page.title}  (page {page.page_num})\n{'='*60}"
            block = f"{header}\n{page.content}\n"
            if total + len(block) > max_chars:
                remaining = max_chars - total - len(header) - 20
                if remaining > 300:
                    parts.append(f"{header}\n{page.content[:remaining]}\n[… truncated]\n")
                break
            parts.append(block)
            total += len(block)
        return "\n".join(parts)

    def clear_history(self) -> None:
        self.chat_history = []
