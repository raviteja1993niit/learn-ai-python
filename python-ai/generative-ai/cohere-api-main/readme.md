# 🔍 Cohere API — Embeddings, Rerank & RAG

## What is this?
Cohere provides enterprise-grade NLP APIs built around three pillars: high-quality multilingual embeddings (`embed-english-v3.0`, `embed-multilingual-v3.0`), a powerful reranker that re-scores retrieved documents by relevance, and Command R+ — a model optimized for RAG and tool use. Together they enable a two-stage retrieval pipeline that beats naive vector search in accuracy.

## Why Learn It?
- Cohere's reranker is one of the best available and dramatically improves RAG answer quality without changing your vector DB
- `embed-v3` embeddings include an `input_type` parameter that separately optimizes document vs query vectors
- Command R+ supports grounded generation with inline citations — reducing hallucination in RAG
- Multilingual embeddings cover 100+ languages from a single model, simplifying global deployments

## Key Concepts
```python
# pip install cohere langchain-cohere

import cohere
import os

co = cohere.Client(api_key=os.environ["COHERE_API_KEY"])

# ── 1. Embeddings: separate input_type for queries vs documents ────────────────
docs = [
    "Transformers use self-attention to process sequences in parallel.",
    "Gradient descent minimizes loss by following the negative gradient.",
    "Docker containers package code with all its dependencies.",
]

# Embed documents at index time
doc_embeddings = co.embed(
    texts=docs,
    model="embed-english-v3.0",
    input_type="search_document",   # optimized for storage
).embeddings

# Embed query at search time
query_embedding = co.embed(
    texts=["How does the attention mechanism work?"],
    model="embed-english-v3.0",
    input_type="search_query",      # optimized for retrieval
).embeddings[0]

# Cosine similarity search
import numpy as np

def cosine_sim(a, b): return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

scores = [cosine_sim(query_embedding, d) for d in doc_embeddings]
ranked_idx = np.argsort(scores)[::-1]
print("Top match:", docs[ranked_idx[0]])

# ── 2. Reranker: re-score vector search results ────────────────────────────────
query = "How does the attention mechanism work?"
candidates = [docs[i] for i in ranked_idx]   # top-k from vector search

rerank_results = co.rerank(
    query=query,
    documents=candidates,
    model="rerank-english-v3.0",
    top_n=2,                         # return top 2 after reranking
)

for r in rerank_results.results:
    print(f"[{r.relevance_score:.4f}] {r.document['text']}")

# ── 3. Two-stage RAG pipeline ──────────────────────────────────────────────────
# Stage 1: vector search retrieves top-50 candidates (fast, approximate)
# Stage 2: reranker scores all 50 and returns top-3 (precise, slower)
# Only top-3 go into the LLM context → higher quality, lower token cost

def two_stage_rag(query: str, all_docs: list[str], top_k: int = 3) -> str:
    # Stage 1 — embed & retrieve
    q_emb = co.embed(texts=[query], model="embed-english-v3.0",
                     input_type="search_query").embeddings[0]
    d_embs = co.embed(texts=all_docs, model="embed-english-v3.0",
                      input_type="search_document").embeddings
    sims = [cosine_sim(q_emb, d) for d in d_embs]
    top_50 = sorted(range(len(sims)), key=lambda i: sims[i], reverse=True)[:50]
    candidates = [all_docs[i] for i in top_50]

    # Stage 2 — rerank
    reranked = co.rerank(query=query, documents=candidates,
                         model="rerank-english-v3.0", top_n=top_k)
    context = "\n".join(r.document["text"] for r in reranked.results)

    # Generate with Command R+
    response = co.chat(
        model="command-r-plus",
        message=query,
        documents=[{"text": r.document["text"]} for r in reranked.results],
    )
    return response.text

# ── 4. Chat with Command R+ ────────────────────────────────────────────────────
chat_resp = co.chat(
    model="command-r-plus",
    message="What is the difference between precision and recall?",
    preamble="You are a concise ML tutor. Answer in 3 bullet points.",
)
print(chat_resp.text)

# ── 5. Classification ─────────────────────────────────────────────────────────
classify_resp = co.classify(
    model="embed-english-v3.0",
    inputs=["I love this product!", "This is terrible.", "It was okay."],
    examples=[
        cohere.ClassifyExample(text="Amazing quality!", label="positive"),
        cohere.ClassifyExample(text="Worst purchase ever.", label="negative"),
        cohere.ClassifyExample(text="Not bad, not great.", label="neutral"),
        cohere.ClassifyExample(text="Highly recommend!", label="positive"),
        cohere.ClassifyExample(text="Total waste of money.", label="negative"),
    ],
)
for pred in classify_resp.classifications:
    print(f"{pred.input!r:30s} → {pred.prediction} ({pred.confidence:.2f})")

# ── 6. LangChain Integration ──────────────────────────────────────────────────
from langchain_cohere import CohereEmbeddings, CohereRerank
from langchain.retrievers import ContextualCompressionRetriever
from langchain_community.vectorstores import FAISS

embeddings = CohereEmbeddings(model="embed-english-v3.0", cohere_api_key="...")
# vectorstore = FAISS.from_texts(docs, embeddings)
# base_retriever = vectorstore.as_retriever(search_kwargs={"k": 20})
# reranker = CohereRerank(model="rerank-english-v3.0", top_n=3)
# retriever = ContextualCompressionRetriever(base_compressor=reranker, base_retriever=base_retriever)
# results = retriever.invoke("How does attention work?")
```

## Learning Path
1. `pip install cohere langchain-cohere faiss-cpu`
2. Get a free API key at dashboard.cohere.com
3. Embed 20 documents and implement cosine-similarity search from scratch
4. Add the reranker on top and compare rankings before vs after reranking
5. Build the two-stage RAG pipeline with `command-r-plus` generating cited answers
6. Swap in `embed-multilingual-v3.0` and test with non-English queries

## What to Build
- [ ] Two-stage RAG chatbot over a set of PDF documents with citation output
- [ ] Semantic search over a product catalog using `embed-english-v3.0`
- [ ] Compare `rerank-english-v3.0` vs BM25 on an information retrieval benchmark
- [ ] Few-shot text classifier using `co.classify` with 5 examples per class
- [ ] Multilingual FAQ bot: embed questions in multiple languages, retrieve in English

## Related Folders
- `generative-ai\rag-main\` — full RAG pipeline where Cohere reranker plugs in as Stage 2
- `generative-ai\openai-api-main\` — compare embedding quality and retrieval accuracy
- `generative-ai\langchain-main\` — `CohereRerank` as a LangChain compression retriever
