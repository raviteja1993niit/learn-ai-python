# 🔍 Elasticsearch for ML — Hybrid Search & Production RAG

## What is Elasticsearch for ML?
Elasticsearch is a distributed search and analytics engine that combines traditional BM25 full-text search with kNN dense vector search in a single query, making it ideal for production RAG systems. It supports ELSER (Elastic Learned Sparse EncodeR) for sparse semantic embeddings without needing an external model, and the `semantic_text` field type (8.11+) automates embedding generation inline. LangChain's `ElasticsearchStore` turns it into a plug-and-play vector store.

## Why Learn It?
- Best-in-class hybrid search: BM25 keyword relevance + kNN semantic similarity in one query
- Production-proven at scale — billions of documents, low-latency retrieval
- ELSER provides sparse embeddings without managing a separate embedding service
- Native Kibana dashboards for monitoring search quality and index health
- Index lifecycle management (ILM) automates hot → warm → cold → delete tier transitions

## Key Concepts
```python
from elasticsearch import Elasticsearch
import numpy as np

es = Elasticsearch("http://localhost:9200")

# --- Index mapping with dense_vector field ---
mapping = {
    "mappings": {
        "properties": {
            "text":      {"type": "text"},
            "embedding": {"type": "dense_vector", "dims": 384, "index": True,
                          "similarity": "cosine"},
            "category":  {"type": "keyword"}
        }
    }
}
es.indices.create(index="docs", body=mapping, ignore=400)

# --- Index a document ---
es.index(index="docs", id=1, document={
    "text": "Transformers revolutionized NLP with self-attention.",
    "embedding": np.random.rand(384).tolist(),
    "category": "nlp"
})
es.indices.refresh(index="docs")

# --- BM25 full-text search ---
resp = es.search(index="docs", query={"match": {"text": "transformer attention"}})
for hit in resp["hits"]["hits"]:
    print(hit["_score"], hit["_source"]["text"])

# --- kNN vector search ---
query_vec = np.random.rand(384).tolist()
resp = es.search(index="docs", knn={
    "field": "embedding",
    "query_vector": query_vec,
    "k": 10,
    "num_candidates": 100
})

# --- Hybrid search: BM25 + kNN with Reciprocal Rank Fusion (RRF) ---
resp = es.search(index="docs", retriever={
    "rrf": {
        "retrievers": [
            {"standard": {"query": {"match": {"text": "transformer attention"}}}},
            {"knn": {"field": "embedding", "query_vector": query_vec,
                     "num_candidates": 100}}
        ],
        "rank_window_size": 50,
        "rank_constant": 20
    }
})

# --- semantic_text field (ES 8.11+, auto-embedding) ---
semantic_mapping = {
    "mappings": {
        "properties": {
            "content": {
                "type": "semantic_text",
                "inference_id": ".elser-2-elasticsearch"  # built-in ELSER model
            }
        }
    }
}
es.indices.create(index="semantic-docs", body=semantic_mapping, ignore=400)
es.index(index="semantic-docs", document={"content": "RAG pipelines improve LLM accuracy."})

# --- LangChain ElasticsearchStore ---
from langchain_elasticsearch import ElasticsearchStore
from langchain_huggingface import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
store = ElasticsearchStore(
    index_name="langchain-rag",
    embedding=embeddings,
    es_url="http://localhost:9200"
)
store.add_texts(["Deep learning scales with data.", "BERT uses masked language modeling."])
docs = store.similarity_search("what is BERT?", k=3)

# --- Index Lifecycle Management (ILM) policy ---
ilm_policy = {
    "policy": {
        "phases": {
            "hot":  {"actions": {"rollover": {"max_size": "10gb", "max_age": "7d"}}},
            "warm": {"min_age": "7d",  "actions": {"shrink": {"number_of_shards": 1}}},
            "cold": {"min_age": "30d", "actions": {"freeze": {}}},
            "delete": {"min_age": "90d", "actions": {"delete": {}}}
        }
    }
}
es.ilm.put_lifecycle(name="docs-policy", body=ilm_policy)
```

## Learning Path
1. Stand up Elasticsearch locally with Docker (`docker run -p 9200:9200 elasticsearch:8.12.0`)
2. Create an index with `dense_vector` mapping and index sample documents
3. Run BM25 `match` queries and compare to kNN vector search results
4. Implement hybrid search using RRF to blend BM25 + kNN scores
5. Use `semantic_text` + ELSER for zero-config sparse semantic search
6. Build a production RAG retriever using LangChain `ElasticsearchStore`
7. Set up an ILM policy and monitor index health in Kibana

## What to Build
- [ ] Hybrid semantic search over a PDF document corpus (chunk → embed → index → query)
- [ ] RAG chatbot with Elasticsearch as the retriever and an LLM as the generator
- [ ] Search quality dashboard in Kibana comparing BM25 vs kNN vs hybrid recall
- [ ] ELSER vs dense embedding comparison on a domain-specific dataset
- [ ] Multi-tenant document store with per-user index routing and ILM cleanup

## Related Folders
- `rag\rag-pipeline-main\` — wire Elasticsearch retriever into a full RAG chain
- `databases\vector-databases-main\` — compare Elasticsearch kNN vs Pinecone vs Chroma vs Weaviate
- `nlp\text-embeddings-main\` — generate embeddings to feed into dense_vector fields
