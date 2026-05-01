# 🔍 Weaviate — Vector Database for AI

## What is Weaviate?
Weaviate is an open-source **vector database** built for storing and searching embeddings.
Essential for RAG (Retrieval-Augmented Generation) pipelines.

## Vector DB Comparison
| DB | Best For | Hosting |
|----|----------|---------|
| **Weaviate** | Full-featured, GraphQL API | Self-host + Cloud |
| **ChromaDB** | Local dev, simple | Local + Cloud |
| **FAISS** | Research, speed | Local only |
| **Pinecone** | Managed, production | Cloud only |
| **Qdrant** | Performance, filtering | Self-host + Cloud |

## Key Concepts
```python
import weaviate

client = weaviate.Client("http://localhost:8080")

# Create a class (like a table)
client.schema.create_class({
    "class": "Document",
    "vectorizer": "text2vec-openai"
})

# Insert objects (auto-vectorized)
client.data_object.create({"content": "Python is great"}, "Document")

# Semantic search (vector similarity)
result = client.query.get("Document", ["content"]).with_near_text(
    {"concepts": ["programming language"]}
).with_limit(5).do()

# Hybrid search (vector + keyword BM25)
result = client.query.get("Document", ["content"]).with_hybrid(
    query="machine learning"
).with_limit(5).do()
```

## Use Cases
- RAG knowledge base for LLM chatbots
- Semantic document search
- Recommendation systems
- Image similarity search

## Learning Path
1. `pip install weaviate-client` + run Weaviate via Docker
2. Create schema and insert documents
3. Semantic search with near_text
4. Hybrid search
5. Integrate with LangChain as a retriever

## What to Build
- [ ] Document Q&A system (LangChain + Weaviate)
- [ ] Semantic search engine for your study notes
- [ ] Image similarity search

## Related Folders
- `agentic-ai/RAG-Tutorials/` — RAG with other vector DBs
- `databases/MongoDb-with-Python-master/` — NoSQL comparison