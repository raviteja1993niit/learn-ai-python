# 🐘 PostgreSQL with pgvector — Vector Search Inside Your SQL Database

## What is pgvector?
pgvector is a PostgreSQL extension that adds a native `vector` column type and similarity search operators, turning your existing Postgres database into a vector store. It supports L2, cosine, and inner product distances with `ivfflat` and `hnsw` indexes, enabling production RAG without a separate vector database.

## Why Learn It?
- Add vector search to an existing Postgres stack with zero new infrastructure
- Combine semantic search with SQL JOINs, filters, and transactions
- Use ACID guarantees and familiar SQL tooling for RAG applications
- Scale with `pgvectorscale` (TimescaleDB) for higher-performance workloads
- Integrate with SQLAlchemy, psycopg2, and LangChain out of the box

## Key Concepts
```python
import psycopg2
import numpy as np
from pgvector.psycopg2 import register_vector
from sentence_transformers import SentenceTransformer

# --- Setup: connect and register pgvector type ---
conn = psycopg2.connect("postgresql://user:password@localhost/mydb")
register_vector(conn)
cur  = conn.cursor()

# --- Create extension and table ---
cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
cur.execute("""
    CREATE TABLE IF NOT EXISTS documents (
        id      SERIAL PRIMARY KEY,
        content TEXT,
        source  TEXT,
        embedding vector(384)
    );
""")
conn.commit()

# --- Insert embeddings ---
encoder = SentenceTransformer("all-MiniLM-L6-v2")
texts   = ["Vector databases are fast", "PostgreSQL supports extensions",
           "RAG improves LLM accuracy with retrieval"]
for text in texts:
    vec = encoder.encode(text).tolist()
    cur.execute(
        "INSERT INTO documents (content, source, embedding) VALUES (%s, %s, %s)",
        (text, "manual", vec)
    )
conn.commit()

# --- L2 distance search (<->) ---
query_vec = encoder.encode("how do vector databases work?").tolist()
cur.execute("""
    SELECT content, source, embedding <-> %s AS distance
    FROM documents
    ORDER BY distance
    LIMIT 5;
""", (query_vec,))
for row in cur.fetchall():
    print(f"[dist={row[2]:.4f}] {row[0]}")

# --- Cosine distance (<=>) and inner product (<#>) ---
cur.execute("SELECT content, 1 - (embedding <=> %s) AS cosine_sim FROM documents ORDER BY cosine_sim DESC LIMIT 3;", (query_vec,))

# --- Create HNSW index (better recall, faster queries) ---
cur.execute("CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);")
# Or IVFFlat (less memory, lower build time):
cur.execute("CREATE INDEX ON documents USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);")
conn.commit()

# --- SQLAlchemy + pgvector ---
from sqlalchemy import create_engine, Column, Integer, Text
from sqlalchemy.orm import DeclarativeBase, Session
from pgvector.sqlalchemy import Vector

engine = create_engine("postgresql+psycopg2://user:password@localhost/mydb")

class Base(DeclarativeBase): pass

class Document(Base):
    __tablename__ = "documents_orm"
    id        = Column(Integer, primary_key=True)
    content   = Column(Text)
    embedding = Column(Vector(384))

Base.metadata.create_all(engine)

with Session(engine) as session:
    doc = Document(content="pgvector with SQLAlchemy", embedding=encoder.encode("pgvector with SQLAlchemy").tolist())
    session.add(doc)
    session.commit()
    results = session.query(Document).order_by(Document.embedding.cosine_distance(query_vec)).limit(5).all()

# --- LangChain PGVector ---
from langchain_postgres import PGVector
from langchain_openai import OpenAIEmbeddings

CONNECTION = "postgresql+psycopg://user:password@localhost/mydb"
store = PGVector(
    embeddings=OpenAIEmbeddings(),
    collection_name="rag_docs",
    connection=CONNECTION,
    use_jsonb=True
)
store.add_texts(texts=texts, metadatas=[{"source": "wiki"}] * len(texts))
results = store.similarity_search_with_score("retrieval augmented generation", k=3)
```

## Learning Path
1. Install pgvector: `CREATE EXTENSION vector;` in your Postgres database
2. Understand the `vector(n)` column type and how to insert float arrays
3. Learn the three distance operators: `<->` (L2), `<=>` (cosine), `<#>` (inner product)
4. Build and query with `ivfflat` index (fast builds, good recall for medium datasets)
5. Switch to `hnsw` index for lower-latency queries at higher memory cost
6. Use `psycopg2` + `pgvector` library for raw SQL vector operations
7. Model vector columns with SQLAlchemy's `Vector` type for ORM queries
8. Integrate LangChain `PGVector` for drop-in RAG vector store support
9. Compare pgvector vs Qdrant/Weaviate on latency, throughput, and ops complexity
10. Explore `pgvectorscale` (TimescaleDB) for streaming inserts and higher QPS

## What to Build
- [ ] RAG system using Postgres as the sole backend (vectors + metadata in one DB)
- [ ] Document search API with cosine similarity and SQL metadata filtering
- [ ] Benchmark comparing ivfflat vs hnsw on recall@10 and query latency
- [ ] SQLAlchemy ORM model with vector field for a knowledge base application
- [ ] LangChain PGVector RAG chain with source attribution from Postgres metadata
- [ ] Multi-tenant vector store using Postgres row-level security (RLS)

## Related Folders
- `databases/qdrant-main/` — dedicated vector DB for higher-scale vector workloads
- `databases/neo4j-graph-database-main/` — graph + vector for knowledge graph RAG
- `rag-advanced/rag-pipeline-main/` — full RAG pipeline wiring vector store to LLM
