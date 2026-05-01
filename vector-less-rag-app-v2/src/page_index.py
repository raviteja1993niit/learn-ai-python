"""
page_index.py — PageIndex: BM25-based retrieval over document pages.

No chunking. No vectors. Each Page is a natural document unit
(PDF page, DOCX section, Excel sheet, text section, CSV batch).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Dict, List, Tuple

from rank_bm25 import BM25Okapi

from src.parser import Page


def _tokenize(text: str) -> List[str]:
    """Lowercase alphanumeric tokenizer."""
    return re.findall(r"[a-zA-Z0-9]+", text.lower())


@dataclass
class IndexStats:
    total_pages: int
    total_words: int
    avg_words_per_page: float
    source_types: List[str]
    longest_page: str
    shortest_page: str


class PageIndex:
    """
    Builds a BM25 search index over document pages.
    Retrieval returns full pages — no chunking, no embeddings.
    """

    def __init__(self, pages: List[Page]) -> None:
        if not pages:
            raise ValueError("Cannot build index from empty page list.")
        self.pages = pages
        self._tokenized = [_tokenize(p.content) for p in pages]
        self._bm25 = BM25Okapi(self._tokenized)

    # ── Search ────────────────────────────────────────────────────────────────

    def search(self, query: str, top_k: int = 5) -> List[Tuple[Page, float]]:
        """Return top-k (Page, score) pairs sorted by relevance descending."""
        tokens = _tokenize(query)
        scores = self._bm25.get_scores(tokens)
        ranked = sorted(
            zip(self.pages, scores), key=lambda x: x[1], reverse=True
        )
        results = [(p, float(s)) for p, s in ranked[:top_k] if s > 0]
        # If BM25 returns nothing (query terms not in corpus), return first top_k pages
        if not results:
            results = [(p, 0.0) for p in self.pages[:top_k]]
        return results

    def all_scores(self, query: str) -> List[Tuple[Page, float]]:
        """Return all pages with their BM25 scores (for visualisation)."""
        tokens = _tokenize(query)
        scores = self._bm25.get_scores(tokens)
        return [(p, float(s)) for p, s in zip(self.pages, scores)]

    # ── Context builder ───────────────────────────────────────────────────────

    def build_context(
        self,
        results: List[Tuple[Page, float]],
        max_chars: int = 24000,
    ) -> str:
        """
        Format retrieved pages into a LLM context string.
        Respects max_chars budget; lower-scored pages are truncated first.
        """
        parts: List[str] = []
        total = 0
        for page, score in results:
            header = f"{'='*60}\n📄 {page.title}  (page {page.page_num})\n{'='*60}"
            body = page.content
            block = f"{header}\n{body}\n"
            if total + len(block) > max_chars:
                remaining = max_chars - total - len(header) - 20
                if remaining > 300:
                    parts.append(f"{header}\n{body[:remaining]}\n[… truncated]\n")
                break
            parts.append(block)
            total += len(block)
        return "\n".join(parts)

    # ── Table of contents ─────────────────────────────────────────────────────

    def build_toc(self) -> str:
        lines = ["📋 Document Index\n" + "─" * 40]
        for p in self.pages:
            wc = f"{p.word_count:,}w" if p.word_count else ""
            lines.append(f"  {p.page_num:3d}.  {p.title[:55]:<56} {wc}")
        return "\n".join(lines)

    # ── Stats ─────────────────────────────────────────────────────────────────

    @property
    def stats(self) -> IndexStats:
        total_words = sum(p.word_count for p in self.pages)
        source_types = sorted(set(p.source_type for p in self.pages))
        by_words = sorted(self.pages, key=lambda p: p.word_count)
        return IndexStats(
            total_pages=len(self.pages),
            total_words=total_words,
            avg_words_per_page=round(total_words / len(self.pages), 1),
            source_types=source_types,
            longest_page=by_words[-1].title if by_words else "",
            shortest_page=by_words[0].title if by_words else "",
        )

    # ── Score heatmap data (for Altair chart) ─────────────────────────────────

    def score_chart_data(self, query: str) -> List[Dict]:
        """Return list of dicts suitable for an Altair bar chart."""
        all_scored = self.all_scores(query)
        max_score = max(s for _, s in all_scored) or 1.0
        return [
            {
                "page": f"p{p.page_num}",
                "title": p.title[:40],
                "score": round(s, 3),
                "pct": round(s / max_score * 100, 1),
            }
            for p, s in all_scored
        ]
