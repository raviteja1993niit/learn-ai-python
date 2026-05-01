"""
chunker.py — Split text into overlapping chunks for BM25 indexing.
"""
from typing import List


def chunk_text(
    text: str,
    chunk_size: int = 500,
    overlap: int = 50,
) -> List[str]:
    """
    Split text into chunks of ~chunk_size characters with overlap.
    Tries to split on paragraph or sentence boundaries where possible.
    """
    if not text.strip():
        return []

    # Split on double newlines (paragraphs) first
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]

    chunks = []
    current_chunk = []
    current_len = 0

    for para in paragraphs:
        para_len = len(para)

        # If a single paragraph exceeds chunk_size, split it further by sentences
        if para_len > chunk_size:
            sentences = _split_sentences(para)
            for sentence in sentences:
                sentence_len = len(sentence)
                if current_len + sentence_len > chunk_size and current_chunk:
                    chunks.append(" ".join(current_chunk))
                    # Keep last few words for overlap
                    overlap_text = " ".join(current_chunk)[-overlap:]
                    current_chunk = [overlap_text, sentence] if overlap_text else [sentence]
                    current_len = len(" ".join(current_chunk))
                else:
                    current_chunk.append(sentence)
                    current_len += sentence_len + 1
        else:
            if current_len + para_len > chunk_size and current_chunk:
                chunks.append(" ".join(current_chunk))
                overlap_text = " ".join(current_chunk)[-overlap:]
                current_chunk = [overlap_text, para] if overlap_text else [para]
                current_len = len(" ".join(current_chunk))
            else:
                current_chunk.append(para)
                current_len += para_len + 1

    if current_chunk:
        chunks.append(" ".join(current_chunk))

    return [c.strip() for c in chunks if c.strip()]


def _split_sentences(text: str) -> List[str]:
    """Simple sentence splitter on '. ', '! ', '? '."""
    import re
    parts = re.split(r'(?<=[.!?])\s+', text)
    return [p.strip() for p in parts if p.strip()]
