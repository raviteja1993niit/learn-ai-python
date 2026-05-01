# 🔤 Sentence Transformers — Dense Semantic Embeddings

## What is Sentence Transformers?
Sentence Transformers (SBERT) is a framework that fine-tunes BERT-style models using siamese and triplet networks to produce semantically meaningful fixed-size sentence embeddings. Unlike raw BERT, SBERT's `encode()` produces vectors where cosine similarity directly reflects semantic relatedness — making it fast and practical for semantic search, clustering, and retrieval.

## Why Learn It?
- Backbone of modern RAG pipelines — converts text chunks into searchable vectors
- `encode()` is 1000x faster than comparing all sentence pairs with raw BERT
- Supports semantic search, paraphrase mining, clustering, and zero-shot classification
- Fine-tunable on custom domain pairs with just a few hundred examples

## Key Concepts
```python
from sentence_transformers import SentenceTransformer, util
import torch

# Load a pretrained model
model = SentenceTransformer("all-MiniLM-L6-v2")   # fast, 384-dim
# model = SentenceTransformer("all-mpnet-base-v2") # slower, higher quality, 768-dim

# Encode sentences into dense vectors
sentences = [
    "How do I reset my password?",
    "Steps to change account credentials",
    "What is the capital of France?",
]
embeddings = model.encode(sentences, convert_to_tensor=True)
print(embeddings.shape)   # torch.Size([3, 384])

# Semantic similarity
sim = util.cos_sim(embeddings[0], embeddings[1])
print(f"Similarity: {sim.item():.4f}")  # ~0.85 — very similar

# Semantic search: find top-k most relevant docs
query = "forgot my login"
query_emb = model.encode(query, convert_to_tensor=True)
hits = util.semantic_search(query_emb, embeddings, top_k=2)
print(hits)  # ranked results with scores

# Paraphrase mining
from sentence_transformers import util as st_util
paraphrases = st_util.paraphrase_mining(model, sentences)
for score, i, j in paraphrases:
    print(f"{score:.4f}: '{sentences[i]}' ↔ '{sentences[j]}'")

# Cross-encoder reranking (more accurate, slower)
from sentence_transformers import CrossEncoder
reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")
pairs = [["forgot my login", s] for s in sentences]
scores = reranker.predict(pairs)
```

## Learning Path
1. `pip install sentence-transformers faiss-cpu`
2. Explore the [SBERT model hub](https://www.sbert.net/docs/pretrained_models.html) — compare `all-MiniLM-L6-v2` vs `all-mpnet-base-v2`
3. Build a semantic search engine: encode a corpus, store vectors, query with cosine similarity
4. Add FAISS index for million-scale nearest-neighbor search
5. Fine-tune on custom pairs using `InputExample` + `CosineSimilarityLoss` or `TripletLoss`

## What to Build
- [ ] FAQ semantic search: match user questions to a knowledge base
- [ ] Document deduplication tool using paraphrase mining
- [ ] Custom domain embedder fine-tuned on company-specific sentence pairs

## Related Folders
- `generative-ai/rag-advanced-patterns-main/` — sentence transformers are the retrieval backbone
- `nlp/transformers-main/` — BERT/RoBERTa base models that SBERT fine-tunes
- `generative-ai/llm-evaluation-ragas-main/` — evaluation uses embeddings for relevancy scoring
