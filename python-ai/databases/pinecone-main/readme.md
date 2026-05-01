# 🌲 Pinecone Vector Database — Production-Scale Similarity Search

## What is Pinecone?
Pinecone is a fully managed, cloud-native vector database purpose-built for production AI workloads. It handles billions of vectors with low-latency queries, supports namespaces for multi-tenancy, and offers both serverless and pod-based deployment tiers. It is the standard choice when ChromaDB's local setup is no longer sufficient.

## Why Learn It?
- Production-ready vector search with SLAs, auto-scaling, and managed infrastructure
- Native support for hybrid search combining dense embeddings and sparse BM25 keywords
- Namespaces enable cost-efficient multi-tenant architectures in a single index
- Deep LangChain / LlamaIndex ecosystem integration for enterprise RAG pipelines

## Key Concepts
```python
from pinecone import Pinecone, ServerlessSpec, PodSpec

# Connect
pc = Pinecone(api_key="your-api-key")

# Create a serverless index (pay-per-use)
pc.create_index(
    name="my-index",
    dimension=1536,            # must match your embedding model output
    metric="cosine",           # cosine | euclidean | dotproduct
    spec=ServerlessSpec(cloud="aws", region="us-east-1")
)

# Pod-based index (dedicated resources)
pc.create_index(
    name="prod-index",
    dimension=1536,
    metric="cosine",
    spec=PodSpec(environment="gcp-starter")
)

index = pc.Index("my-index")

# Upsert vectors (batch for efficiency)
vectors = [
    ("id1", [0.1, 0.2, ...], {"source": "docs", "category": "ai"}),
    ("id2", [0.3, 0.4, ...], {"source": "wiki", "category": "ml"}),
]
index.upsert(vectors=[(id, vec, meta) for id, vec, meta in vectors], namespace="prod")

# Query with metadata filter
results = index.query(
    vector=[0.1, 0.2, ...],
    top_k=5,
    filter={"category": {"$eq": "ai"}},
    namespace="prod",
    include_metadata=True
)

# Delete and describe
index.delete(ids=["id1"], namespace="prod")
print(index.describe_index_stats())

# LangChain PineconeVectorStore
from langchain_pinecone import PineconeVectorStore
vectorstore = PineconeVectorStore(
    index=index,
    embedding=embeddings,   # any LangChain embeddings object
    namespace="prod"
)
retriever = vectorstore.as_retriever(search_kwargs={"k": 6})
docs = retriever.invoke("What is RAG?")
```

## Learning Path
1. `pip install pinecone langchain-pinecone`
2. Create a free Pinecone account and generate an API key
3. Create a serverless index and upsert 100 sample vectors
4. Run similarity queries with and without metadata filters
5. Experiment with namespaces to simulate multi-tenant isolation
6. Integrate with LangChain and build a RetrievalQA chain
7. Profile latency and cost; compare serverless vs pod tiers

## What to Build
- [ ] Production RAG API (FastAPI + Pinecone + OpenAI) with namespace-per-user
- [ ] Semantic product search engine for an e-commerce catalogue
- [ ] Hybrid search pipeline combining Pinecone dense + BM25 sparse scores
- [ ] Cost-monitoring dashboard tracking Pinecone read/write units

## Related Folders
- `databases/chromadb-main/` — free local alternative, great for prototyping
- `rag/` — end-to-end RAG patterns that plug into Pinecone
- `embeddings/` — choosing the right embedding dimension and model
