"""
retriever.py — BM25-based retrieval over text chunks.
"""
import re
from typing import List, Tuple

from rank_bm25 import BM25Okapi


def tokenize(text: str) -> List[str]:
    """Lowercase and split on non-alphanumeric characters."""
    return re.findall(r"[a-zA-Z0-9]+", text.lower())


class BM25Retriever:
    def __init__(self, chunks: List[str]):
        self.chunks = chunks
        tokenized = [tokenize(chunk) for chunk in chunks]
        self.bm25 = BM25Okapi(tokenized)

    def retrieve(self, query: str, top_k: int = 5) -> List[Tuple[int, str, float]]:
        """
        Returns list of (index, chunk_text, score) sorted by relevance descending.
        """
        query_tokens = tokenize(query)
        scores = self.bm25.get_scores(query_tokens)
        ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
        results = []
        for idx, score in ranked[:top_k]:
            if score > 0:
                results.append((idx, self.chunks[idx], score))
        return results
