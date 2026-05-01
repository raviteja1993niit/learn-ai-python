"""
vector_index.py — Semantic vector index using TF-IDF + LSA (sklearn).

No HuggingFace. No internet. No downloads.
Uses TfidfVectorizer + TruncatedSVD (Latent Semantic Analysis) to create
dense semantic vectors, then cosine similarity for retrieval.
"""
from __future__ import annotations

from types import SimpleNamespace
from typing import List, Tuple

import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

from src.parser import Page


class VectorIndex:
    def __init__(
        self,
        pages: List[Page],
        session_id: str,
        n_components: int = 128,
    ):
        self.pages = pages
        texts = [p.content for p in pages]

        # ── Build TF-IDF matrix ──────────────────────────────────────────────
        self.vectorizer = TfidfVectorizer(
            max_features=15000,
            stop_words="english",
            sublinear_tf=True,
            ngram_range=(1, 2),
        )
        tfidf = self.vectorizer.fit_transform(texts)

        # ── LSA: reduce to dense semantic vectors ────────────────────────────
        n = min(n_components, len(texts) - 1, tfidf.shape[1] - 1)
        self.svd = TruncatedSVD(n_components=max(n, 1), random_state=42)
        dense = self.svd.fit_transform(tfidf)

        # ── L2-normalise so dot product == cosine similarity ─────────────────
        self.embeddings = normalize(dense)           # shape: (n_pages, n)

    # ── Search ────────────────────────────────────────────────────────────────

    def search(self, query: str, top_k: int = 4) -> List[Tuple[Page, float]]:
        q_tfidf  = self.vectorizer.transform([query])
        q_vec    = normalize(self.svd.transform(q_tfidf))          # (1, n)
        scores   = (self.embeddings @ q_vec.T).flatten()           # (n_pages,)
        top_idx  = np.argsort(scores)[::-1][:min(top_k, len(self.pages))]
        return [(self.pages[i], float(scores[i])) for i in top_idx]

    # ── Stats ─────────────────────────────────────────────────────────────────

    @property
    def stats(self):
        total_pages = len(self.pages)
        total_words = sum(p.word_count for p in self.pages)
        avg_words   = round(total_words / total_pages) if total_pages else 0
        return SimpleNamespace(
            total_pages=total_pages,
            total_words=total_words,
            avg_words_per_page=avg_words,
            source_types=list({p.source_type for p in self.pages}),
            longest_page=max((p.word_count for p in self.pages), default=0),
        )
