# 🗄️ ChromaDB — Local Vector Database for AI Apps

## What is ChromaDB?
ChromaDB is an open-source, AI-native vector database designed for storing and querying embeddings locally or in the cloud. It supports metadata filtering, multiple embedding backends, and seamless LangChain integration. It is the go-to choice for building local RAG (Retrieval-Augmented Generation) pipelines without any external services.

## Why Learn It?
- Build fully local RAG apps with no API costs or data privacy concerns
- Integrate with LangChain, OpenAI, and sentence-transformers out of the box
- Fast similarity search with cosine, L2, and inner product distance metrics
- Foundation for understanding production vector databases like Pinecone or Weaviate

## Key Concepts
```python
import chromadb
from chromadb.utils import embedding_functions

# Ephemeral (in-memory) vs Persistent client
client = chromadb.Client()
client = chromadb.PersistentClient(path="./chroma_db")

# Create or get a collection with a custom embedding function
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="sk-...", model_name="text-embedding-3-small"
)
sentence_ef = embedding_functions.SentenceTransformerEmbeddingFunction(
    model_name="all-MiniLM-L6-v2"
)
collection = client.get_or_create_collection(
    name="my_docs",
    embedding_function=sentence_ef,
    metadata={"hnsw:space": "cosine"}   # distance metric: cosine | l2 | ip
)

# Add documents
collection.add(
    documents=["LangChain is a framework for LLM apps", "ChromaDB stores embeddings"],
    metadatas=[{"source": "docs"}, {"source": "wiki"}],
    ids=["doc1", "doc2"]
)

# Query — returns top-k nearest neighbours
results = collection.query(
    query_texts=["What stores embeddings?"],
    n_results=2,
    where={"source": "wiki"}   # metadata filter
)
print(results["documents"], results["distances"])

# Get / Delete
collection.get(ids=["doc1"])
collection.delete(ids=["doc1"])

# LangChain integration
from langchain_community.vectorstores import Chroma
vectorstore = Chroma(
    collection_name="langchain_store",
    embedding_function=embeddings,   # any LangChain embeddings object
    persist_directory="./chroma_db"
)
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})
```

## Learning Path
1. `pip install chromadb sentence-transformers langchain-community`
2. Build an in-memory collection and run similarity queries
3. Switch to `PersistentClient` and verify data survives restarts
4. Swap embedding functions: default → sentence-transformers → OpenAI
5. Add metadata and experiment with `where` filters in queries
6. Wire up a LangChain `RetrievalQA` chain using Chroma as the retriever
7. Benchmark distance metrics (cosine vs L2) on your own dataset

## What to Build
- [ ] Local document Q&A chatbot (PDF → chunks → ChromaDB → LLM)
- [ ] Semantic search over a personal notes library
- [ ] Duplicate-detection tool using embedding distance thresholds
- [ ] Multi-collection RAG app with metadata-based routing

## Related Folders
- `databases/pinecone-main/` — cloud-hosted alternative for production scale
- `rag/` — full RAG pipeline patterns using ChromaDB as the retriever
- `embeddings/` — embedding model comparisons and chunking strategies
