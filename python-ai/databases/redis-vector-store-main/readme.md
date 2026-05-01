# ⚡ Redis as Vector Store & Cache — Sub-Millisecond AI Memory & Search

## What is Redis for AI?
Redis Stack extends Redis with RedisSearch (full-text + vector search), RedisJSON (document storage), and RedisAI (model serving). For AI workloads it provides ultra-fast semantic caching to cut LLM API costs by 60%+, session memory for agents, real-time ML feature stores via Redis Streams, and a production-grade vector store with HNSW and FLAT indexes.

## Why Learn It?
- Reduce LLM API costs dramatically with semantic caching of near-duplicate queries
- Store agent conversation memory with fast key-based and semantic retrieval
- Build high-throughput vector search (HNSW) with structured field filtering
- Process real-time ML features and events via Redis Streams
- Integrate with LangChain for drop-in vector store and cache replacement

## Key Concepts
```python
import numpy as np
from redisvl.index import SearchIndex
from redisvl.schema import IndexSchema
from redisvl.query import VectorQuery, FilterQuery
from redisvl.extensions.llmcache import SemanticCache
from sentence_transformers import SentenceTransformer

# --- Define schema with TagField, TextField, VectorField ---
schema = IndexSchema.from_dict({
    "index": {"name": "docs", "prefix": "doc"},
    "fields": [
        {"name": "id",       "type": "tag"},
        {"name": "source",   "type": "tag"},
        {"name": "content",  "type": "text"},
        {"name": "year",     "type": "numeric"},
        {"name": "embedding","type": "vector",
         "attrs": {"dims": 384, "distance_metric": "cosine",
                   "algorithm": "hnsw", "datatype": "float32"}}
    ]
})

# --- Create index and connect ---
index = SearchIndex(schema, redis_url="redis://localhost:6379")
index.create(overwrite=True)

# --- Upsert documents with embeddings ---
encoder  = SentenceTransformer("all-MiniLM-L6-v2")
texts    = ["Redis is fast", "Semantic caching reduces API costs", "HNSW enables ANN search"]
vectors  = encoder.encode(texts)

data = [
    {"id": str(i), "source": "docs", "content": t, "year": 2024,
     "embedding": v.astype(np.float32).tobytes()}
    for i, (t, v) in enumerate(zip(texts, vectors))
]
index.load(data)

# --- Vector search query ---
query_vec = encoder.encode("how does caching work?").astype(np.float32).tobytes()
query     = VectorQuery(
    vector=query_vec,
    vector_field_name="embedding",
    return_fields=["content", "source", "year", "vector_distance"],
    num_results=3
)
results = index.query(query)
for r in results:
    print(f"[{float(r['vector_distance']):.4f}] {r['content']}")

# --- Filtered search (tag + numeric) ---
filter_query = FilterQuery(
    filter_expression='@source:{docs} @year:[2024 +inf]',
    return_fields=["content", "year"]
)
filtered = index.query(filter_query)

# --- SemanticCache: cut LLM API costs with similarity-based caching ---
cache = SemanticCache(
    name="llm_cache",
    redis_url="redis://localhost:6379",
    distance_threshold=0.15      # queries within 0.15 cosine dist return cached response
)

# Check cache before calling LLM
response = cache.check(prompt="What is retrieval augmented generation?")
if not response:
    llm_response = "RAG combines a retriever with an LLM to ground responses in documents."
    cache.store(prompt="What is retrieval augmented generation?", response=llm_response)
    print("Cache MISS — stored response")
else:
    print(f"Cache HIT — {response[0]['response']}")

# --- LangChain RedisVectorStore ---
from langchain_community.vectorstores import Redis as RedisVectorStore
from langchain_openai import OpenAIEmbeddings

vectorstore = RedisVectorStore.from_texts(
    texts=texts,
    embedding=OpenAIEmbeddings(),
    redis_url="redis://localhost:6379",
    index_name="langchain_docs"
)
docs = vectorstore.similarity_search("semantic caching for LLMs", k=3)

# --- Agent Session Memory with Redis ---
import redis, json
r = redis.Redis(host="localhost", port=6379, decode_responses=True)

def save_turn(session_id: str, role: str, content: str):
    r.rpush(f"memory:{session_id}", json.dumps({"role": role, "content": content}))
    r.expire(f"memory:{session_id}", 3600)   # TTL: 1 hour

def load_history(session_id: str) -> list:
    return [json.loads(m) for m in r.lrange(f"memory:{session_id}", 0, -1)]

# --- Redis Streams for real-time ML feature ingestion ---
r.xadd("features", {"user_id": "u42", "event": "click", "item_id": "p99", "ts": "1714000000"})
events = r.xread({"features": "0-0"}, count=100, block=1000)
```

## Learning Path
1. Run Redis Stack: `docker run -p 6379:6379 redis/redis-stack:latest`
2. Learn RedisSearch index types: HASH vs JSON, TAG/TEXT/NUMERIC/VECTOR fields
3. Build a vector index with `redisvl` using HNSW (recall) or FLAT (exact) algorithm
4. Perform `VectorQuery` searches and combine with `FilterQuery` for hybrid results
5. Implement `SemanticCache` to cache LLM responses and measure cost savings
6. Use Redis Lists/Hashes for agent conversation session memory with TTLs
7. Integrate LangChain `RedisVectorStore` as a drop-in vector store
8. Stream real-time events with Redis Streams and consume with a ML feature pipeline
9. Explore RedisAI for serving PyTorch/TF models directly inside Redis
10. Monitor performance with `redis-cli info` and `FT.INFO` commands

## What to Build
- [ ] Semantic cache layer that wraps any OpenAI call and reports hit/miss rate
- [ ] Agent with Redis session memory that recalls conversation across multiple turns
- [ ] High-throughput document search index benchmarking HNSW vs FLAT recall & latency
- [ ] Real-time recommendation engine consuming Redis Streams for user events
- [ ] LangChain RAG pipeline using Redis as both vector store and LLM response cache
- [ ] Cost dashboard showing API savings from semantic cache over 1,000 test queries

## Related Folders
- `databases/qdrant-main/` — persistent dedicated vector DB for larger collections
- `databases/postgresql-pgvector-main/` — SQL-native vector search with ACID guarantees
- `rag-advanced/rag-pipeline-main/` — RAG pipeline that integrates vector store + cache
