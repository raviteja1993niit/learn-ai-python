# 🎯 Qdrant Vector Database — High-Performance Vector Search & Filtering

## What is Qdrant?
Qdrant is an open-source, production-ready vector database optimized for similarity search with rich payload filtering. It supports HNSW indexing, sparse vectors for hybrid search, named multi-vectors, and scales from in-memory prototyping to distributed cloud deployments — making it a top choice for RAG and semantic search applications.

## Why Learn It?
- Store and search millions of embeddings with millisecond latency
- Combine semantic vector search with structured payload filters
- Support hybrid search using dense + sparse vectors simultaneously
- Integrate seamlessly with LangChain, LlamaIndex, and custom RAG pipelines
- Deploy anywhere: in-memory, Docker, or Qdrant Cloud

## Key Concepts
```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance, VectorParams, PointStruct,
    Filter, FieldCondition, MatchValue, Range,
    SparseVector, SparseVectorParams, NamedVector,
    HnswConfigDiff
)
from sentence_transformers import SentenceTransformer

# --- Connect: in-memory (dev), Docker (local), or Cloud ---
client_mem    = QdrantClient(":memory:")
client_docker = QdrantClient(host="localhost", port=6333)
client_cloud  = QdrantClient(url="https://<cluster>.cloud.qdrant.io", api_key="YOUR_KEY")
client        = client_mem   # use in-memory for this example

# --- Create Collection ---
client.create_collection(
    collection_name="docs",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    hnsw_config=HnswConfigDiff(m=16, ef_construct=200)   # HNSW tuning
)

# --- Upsert Embeddings ---
encoder = SentenceTransformer("all-MiniLM-L6-v2")
texts   = ["LLMs are large language models", "Vector databases store embeddings",
           "RAG combines retrieval with generation"]
vectors = encoder.encode(texts).tolist()

client.upsert(
    collection_name="docs",
    points=[
        PointStruct(id=i, vector=vec, payload={"text": text, "category": "ai", "year": 2024})
        for i, (vec, text) in enumerate(zip(vectors, texts))
    ]
)

# --- Semantic Search ---
query_vec = encoder.encode("how do embeddings work?").tolist()
results   = client.search(
    collection_name="docs",
    query_vector=query_vec,
    limit=3,
    score_threshold=0.5
)
for r in results:
    print(f"[{r.score:.3f}] {r.payload['text']}")

# --- Filtered Search (payload conditions) ---
results_filtered = client.search(
    collection_name="docs",
    query_vector=query_vec,
    query_filter=Filter(must=[
        FieldCondition(key="category", match=MatchValue(value="ai")),
        FieldCondition(key="year",     range=Range(gte=2023))
    ]),
    limit=5
)

# --- Named Vectors (multi-vector per point) ---
client.create_collection(
    collection_name="multi_vec",
    vectors_config={
        "title":   VectorParams(size=384, distance=Distance.COSINE),
        "content": VectorParams(size=384, distance=Distance.COSINE),
    }
)
client.upsert("multi_vec", points=[
    PointStruct(id=0, vector={
        "title":   encoder.encode("RAG overview").tolist(),
        "content": encoder.encode("Retrieval augmented generation...").tolist()
    }, payload={"source": "docs"})
])

# --- LangChain Integration ---
from langchain_qdrant import QdrantVectorStore
from langchain_openai import OpenAIEmbeddings

vectorstore = QdrantVectorStore.from_texts(
    texts=texts,
    embedding=OpenAIEmbeddings(),
    url="http://localhost:6333",
    collection_name="langchain_docs"
)
docs = vectorstore.similarity_search("what is RAG?", k=3)
```

## Learning Path
1. Install Qdrant with Docker: `docker run -p 6333:6333 qdrant/qdrant`
2. Learn collection creation with `VectorParams` (size, distance metrics)
3. Practice upsert with `PointStruct` including rich payload metadata
4. Perform basic similarity search with `client.search` and `score_threshold`
5. Add payload filtering with `Filter`, `FieldCondition`, and `MatchValue`
6. Explore HNSW tuning parameters (`m`, `ef_construct`, `ef`) for speed/recall tradeoff
7. Implement hybrid search with sparse vectors (BM25 + dense)
8. Use named vectors for multi-representation points (title + body)
9. Integrate with LangChain `QdrantVectorStore` for RAG pipelines
10. Deploy to Qdrant Cloud and enable on-disk indexing for large collections

## What to Build
- [ ] Semantic document search engine with category and date payload filters
- [ ] RAG pipeline using Qdrant + LangChain + OpenAI with source attribution
- [ ] Hybrid search system combining dense (sentence-transformers) + sparse (BM25)
- [ ] Multi-vector product search with separate title and description vectors
- [ ] Collection benchmark comparing HNSW configurations on recall vs latency
- [ ] Qdrant-backed chat memory that retrieves relevant conversation history

## Related Folders
- `databases/postgresql-pgvector-main/` — SQL-native vector search alternative
- `databases/redis-vector-store-main/` — in-memory vector search with Redis Stack
- `rag-advanced/rag-pipeline-main/` — full RAG implementation using vector stores
