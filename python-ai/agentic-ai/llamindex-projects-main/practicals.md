# LlamaIndex Practical Projects
> 8 hands-on projects with setup instructions, implementation steps, and hints

---

## Prerequisites

```bash
# Core dependencies
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai

# Optional — install as needed per project
pip install llama-parse                              # Project 8
pip install llama-index-vector-stores-chroma         # Project 5
pip install llama-index-graph-stores-neo4j           # Project 4
pip install langchain langchain-openai               # Project 7
```

```python
import os
os.environ["OPENAI_API_KEY"] = "sk-..."
```

---

## Project 1 — Research Paper Q&A System

**Goal**: Build an interactive Q&A system over a collection of research papers (PDFs).
Users can ask questions and receive answers with source citations.

**Difficulty**: ⭐⭐ Beginner-Intermediate

### Setup
```bash
mkdir research_qa && cd research_qa
mkdir papers  # Drop your PDFs here
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai
```

### Implementation Steps

**Step 1 — Load and parse PDFs**
```python
from llama_index.core import SimpleDirectoryReader
from llama_index.core.node_parser import SentenceSplitter

documents = SimpleDirectoryReader(
    input_dir="./papers",
    required_exts=[".pdf"],
    filename_as_id=True
).load_data()
print(f"Loaded {len(documents)} documents")
```

**Step 2 — Build the index**
```python
from llama_index.core import VectorStoreIndex, Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

splitter = SentenceSplitter(chunk_size=512, chunk_overlap=50)
index = VectorStoreIndex.from_documents(documents, transformations=[splitter])
```

**Step 3 — Create query engine with citations**
```python
engine = index.as_query_engine(
    similarity_top_k=5,
    response_mode="compact"
)

def ask(question):
    response = engine.query(question)
    print(f"Answer: {response}
")
    print("Sources:")
    for node in response.source_nodes:
        print(f"  [{node.score:.3f}] {node.metadata.get('file_name')}")
        print(f"  {node.text[:150]}...
")
```

**Step 4 — Interactive loop**
```python
while True:
    q = input("Question (or 'quit'): ").strip()
    if q.lower() == "quit":
        break
    ask(q)
```

**Hints**:
- Use `chunk_size=256` for precise retrieval, `chunk_size=1024` for more context
- For scanned PDFs, swap SimpleDirectoryReader for LlamaParse (Project 8)
- Persist the index to disk (Project 5) to avoid re-embedding on each run

---

## Project 2 — Codebase Documentation Search

**Goal**: Index a software repository's source code and documentation so developers can
ask questions like "How does the authentication module work?" or "Where is X implemented?"

**Difficulty**: ⭐⭐ Beginner-Intermediate

### Setup
```bash
pip install llama-index tree-sitter tree-sitter-python
```

### Implementation Steps

**Step 1 — Load code files**
```python
from llama_index.core import SimpleDirectoryReader

documents = SimpleDirectoryReader(
    input_dir="./src",
    recursive=True,
    required_exts=[".py", ".ts", ".js", ".md", ".rst"],
    filename_as_id=True
).load_data()
```

**Step 2 — Use CodeSplitter for structure-aware chunking**
```python
from llama_index.core.node_parser import CodeSplitter
from llama_index.core import VectorStoreIndex

# CodeSplitter respects function/class boundaries
code_splitter = CodeSplitter(
    language="python",
    chunk_lines=40,          # target lines per chunk
    chunk_lines_overlap=5,   # overlap for context
    max_chars=1500
)
index = VectorStoreIndex.from_documents(documents, transformations=[code_splitter])
```

**Step 3 — Tag files with metadata**
```python
# Add file type metadata for filtering
for doc in documents:
    ext = doc.metadata.get("file_name", "").split(".")[-1]
    doc.metadata["file_type"] = ext
    doc.metadata["is_test"] = "test" in doc.metadata.get("file_path", "")
```

**Step 4 — Query with metadata filtering**
```python
from llama_index.core.vector_stores import MetadataFilter, MetadataFilters

# Search only in non-test Python files
filters = MetadataFilters(filters=[
    MetadataFilter(key="file_type", value="py"),
    MetadataFilter(key="is_test", value=False)
])
engine = index.as_query_engine(filters=filters, similarity_top_k=8)
print(engine.query("How does the JWT token validation work?"))
```

**Hints**:
- Add `doc.metadata["module"] = path.parts[1]` to enable module-level filtering
- Use chat engine for interactive exploration sessions
- Consider `similarity_top_k=10` for code search — more results often helps

---

## Project 3 — Multi-Document Comparison Query

**Goal**: Load reports from multiple companies/sources and answer comparative questions
like "Which company had the highest profit margin?" across all of them simultaneously.

**Difficulty**: ⭐⭐⭐ Intermediate

### Setup
```bash
mkdir comparison_project && cd comparison_project
mkdir -p reports/company_a reports/company_b reports/company_c
```

### Implementation Steps

**Step 1 — Build per-source indexes**
```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.tools import QueryEngineTool
import os

tools = []
for company in os.listdir("./reports"):
    path = f"./reports/{company}"
    docs = SimpleDirectoryReader(path).load_data()
    for d in docs:
        d.metadata["company"] = company
    idx = VectorStoreIndex.from_documents(docs)
    tools.append(QueryEngineTool.from_defaults(
        query_engine=idx.as_query_engine(),
        name=f"{company}_reports",
        description=f"Financial reports and documents for {company}"
    ))
```

**Step 2 — SubQuestionQueryEngine for decomposition**
```python
from llama_index.core.query_engine import SubQuestionQueryEngine

engine = SubQuestionQueryEngine.from_defaults(query_engine_tools=tools, verbose=True)
response = engine.query("Compare the operating margins and revenue growth across all companies")
print(response)
```

**Hints**:
- Write clear `description` strings for each tool — the LLM uses them for routing
- Enable `verbose=True` to see how queries are decomposed
- Use `DocumentSummaryIndex` for even smarter routing (Example 8 in EXAMPLES.md)

---

## Project 4 — Knowledge Graph from Text

**Goal**: Extract a knowledge graph from unstructured text documents and query entity
relationships in a graph-aware manner.

**Difficulty**: ⭐⭐⭐ Intermediate

### Setup
```bash
pip install llama-index pyvis networkx
```

### Implementation Steps

**Step 1 — Build the KnowledgeGraphIndex**
```python
from llama_index.core import KnowledgeGraphIndex, SimpleDirectoryReader, StorageContext
from llama_index.core.graph_stores import SimpleGraphStore

documents = SimpleDirectoryReader("./data").load_data()
graph_store = SimpleGraphStore()
storage_context = StorageContext.from_defaults(graph_store=graph_store)

kg_index = KnowledgeGraphIndex.from_documents(
    documents,
    storage_context=storage_context,
    max_triplets_per_chunk=8,
    include_embeddings=True,
    show_progress=True
)
```

**Step 2 — Query with hybrid mode**
```python
engine = kg_index.as_query_engine(
    include_text=True,
    retriever_mode="hybrid",
    similarity_top_k=5
)
print(engine.query("What is the relationship between BERT and transformers?"))
```

**Step 3 — Visualise the graph**
```python
from pyvis.network import Network
import networkx as nx

g = kg_index.get_networkx_graph()
net = Network(notebook=True, height="600px", width="100%")
net.from_nx(g)
net.show("knowledge_graph.html")
print("Graph saved to knowledge_graph.html")
```

**Hints**:
- Increase `max_triplets_per_chunk` for denser, richer graphs (but slower + costlier)
- For production, swap `SimpleGraphStore` for Neo4j
- Try `retriever_mode="keyword"` for exact entity lookups

---

## Project 5 — Persistent Index with StorageContext

**Goal**: Build a persistent RAG pipeline that only re-indexes new or changed documents,
storing the index on disk with Chroma for production-ready vector storage.

**Difficulty**: ⭐⭐⭐ Intermediate

### Setup
```bash
pip install llama-index-vector-stores-chroma chromadb
```

### Implementation Steps

**Step 1 — Set up Chroma vector store**
```python
import chromadb
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import StorageContext

chroma_client = chromadb.PersistentClient(path="./chroma_db")
collection = chroma_client.get_or_create_collection("documents")
vector_store = ChromaVectorStore(chroma_collection=collection)
storage_context = StorageContext.from_defaults(
    vector_store=vector_store,
    persist_dir="./index_storage"
)
```

**Step 2 — Smart incremental indexing**
```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
import os

documents = SimpleDirectoryReader("./data", filename_as_id=True).load_data()

if os.path.exists("./index_storage/docstore.json"):
    from llama_index.core import load_index_from_storage
    print("Loading existing index...")
    index = load_index_from_storage(storage_context)
    
    # Refresh — only re-embeds new/changed docs
    refreshed = index.refresh_ref_docs(documents)
    print(f"Refreshed docs: {sum(refreshed.values())} updated")
else:
    print("Building new index...")
    index = VectorStoreIndex.from_documents(documents, storage_context=storage_context)
    storage_context.persist()
    print("Index persisted")
```

**Step 3 — Query**
```python
engine = index.as_query_engine(similarity_top_k=5)
print(engine.query("What topics are covered in the latest documents?"))
```

**Hints**:
- `filename_as_id=True` is critical for `refresh_ref_docs()` to work correctly
- Chroma's `PersistentClient` auto-saves — no extra persist call needed for vectors
- For very large corpora, consider Pinecone or Qdrant instead of Chroma

---

## Project 6 — Sub-Question Decomposition for Complex Queries

**Goal**: Demonstrate how SubQuestionQueryEngine breaks down complex analytical questions
into parallel sub-queries for richer, more accurate answers.

**Difficulty**: ⭐⭐⭐ Intermediate

### Setup
```bash
mkdir -p data/climate data/economy data/health
# Populate directories with topic-specific documents
```

### Implementation Steps

**Step 1 — Build specialised indexes**
```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.tools import QueryEngineTool

domains = {
    "climate": "Scientific reports on climate change, emissions, and temperature trends",
    "economy": "Economic reports on GDP growth, inflation, and employment statistics",
    "health": "Public health reports on disease prevalence and healthcare access"
}

tools = []
for domain, description in domains.items():
    docs = SimpleDirectoryReader(f"./data/{domain}").load_data()
    idx = VectorStoreIndex.from_documents(docs)
    tools.append(QueryEngineTool.from_defaults(
        query_engine=idx.as_query_engine(similarity_top_k=4),
        name=f"{domain}_index",
        description=description
    ))
```

**Step 2 — Build engine and run complex query**
```python
from llama_index.core.query_engine import SubQuestionQueryEngine

engine = SubQuestionQueryEngine.from_defaults(query_engine_tools=tools, verbose=True)

complex_query = (
    "Analyse the relationship between economic development levels and both "
    "carbon emissions and public health outcomes. Which regions show the strongest "
    "correlation between GDP and emissions reduction?"
)

response = engine.query(complex_query)
print("
=== Final Synthesised Answer ===")
print(response)
```

**Hints**:
- The quality of sub-question decomposition improves significantly with GPT-4o vs GPT-3.5
- Set `verbose=True` to study how the LLM decomposes your questions
- Combine with observability (Arize Phoenix) to trace all sub-queries

---

## Project 7 — LlamaIndex vs LangChain RAG Comparison

**Goal**: Implement the same RAG pipeline in both LlamaIndex and LangChain, then compare
the approaches, code complexity, and response quality.

**Difficulty**: ⭐⭐⭐⭐ Advanced

### Setup
```bash
pip install llama-index langchain langchain-openai langchain-community faiss-cpu
```

### LlamaIndex Implementation
```python
# === LLAMAINDEX RAG ===
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core import Settings
from llama_index.llms.openai import OpenAI

Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)
li_engine = index.as_query_engine(similarity_top_k=5, response_mode="compact")
```

### LangChain Implementation
```python
# === LANGCHAIN RAG ===
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.document_loaders import DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain.chains import RetrievalQA

loader = DirectoryLoader("./data")
docs = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=50)
splits = splitter.split_documents(docs)
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_documents(splits, embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
lc_chain = RetrievalQA.from_chain_type(
    llm=ChatOpenAI(model="gpt-4o-mini", temperature=0),
    chain_type="stuff",
    retriever=retriever
)
```

### Comparison
```python
import time

questions = [
    "What is the main topic of the documents?",
    "What are the key conclusions?",
    "What methodology was used?"
]

for q in questions:
    print(f"
Q: {q}")
    
    t0 = time.time()
    li_resp = li_engine.query(q)
    print(f"LlamaIndex ({time.time()-t0:.2f}s): {str(li_resp)[:200]}")
    
    t0 = time.time()
    lc_resp = lc_chain.run(q)
    print(f"LangChain  ({time.time()-t0:.2f}s): {lc_resp[:200]}")
```

**Observations to note**:
- LlamaIndex provides `response.source_nodes` automatically; LangChain requires `return_source_documents=True`
- LlamaIndex has richer built-in response modes (refine, tree_summarize, etc.)
- LangChain has more flexibility for complex multi-step chains beyond RAG

---

## Project 8 — LlamaParse Advanced PDF Extraction

**Goal**: Use LlamaParse to accurately extract content from complex PDFs (annual reports,
scientific papers with tables/figures) that generic parsers mangle.

**Difficulty**: ⭐⭐⭐ Intermediate

### Setup
```bash
pip install llama-parse llama-index
# Get free API key at https://cloud.llamaindex.ai
```

### Implementation Steps

**Step 1 — Parse with LlamaParse**
```python
from llama_parse import LlamaParse
from llama_index.core import VectorStoreIndex

parser = LlamaParse(
    api_key="llx-...",
    result_type="markdown",      # Preserves tables as markdown
    num_workers=4,               # Parallel page processing
    verbose=True,
    language="en",
    parsing_instruction=(
        "This is a financial annual report. "
        "Please accurately extract all tables, figures, and financial data. "
        "Preserve table structure in markdown format."
    )
)

documents = parser.load_data("./reports/annual_report_2024.pdf")
```

**Step 2 — Inspect parsed output quality**
```python
for i, doc in enumerate(documents):
    print(f"
--- Page/Section {i+1} ---")
    # Check that tables are preserved
    if "|" in doc.text:
        print("  [TABLE DETECTED]")
    print(doc.text[:400])
```

**Step 3 — Index and query**
```python
from llama_index.core.node_parser import MarkdownNodeParser

# MarkdownNodeParser respects the structure LlamaParse creates
md_parser = MarkdownNodeParser()
nodes = md_parser.get_nodes_from_documents(documents)
index = VectorStoreIndex(nodes)
engine = index.as_query_engine(similarity_top_k=6)

# Now tables are accurately queryable
questions = [
    "What was the total revenue in Q4 2024?",
    "Show the breakdown of revenue by geographic segment",
    "What are the key risk factors mentioned in the report?",
]
for q in questions:
    print(f"
Q: {q}")
    print(f"A: {engine.query(q)}")
```

**Hints**:
- `parsing_instruction` is powerful — describe the document type for better parsing
- Compare LlamaParse vs standard PDFReader output side-by-side on a table-heavy page
- For batch processing large volumes, use `async_mode=True` in LlamaParse
- LlamaParse free tier: 1000 pages/day — sufficient for prototyping

---

## Next Steps

After completing these projects, explore:

1. **Evaluation** — Use `llama_index.evaluation` to measure retrieval quality (hit rate, MRR)
2. **Fine-tuning embeddings** — Fine-tune embedding models on your domain data
3. **Custom retrievers** — Build hybrid BM25 + vector retrievers
4. **Production deployment** — FastAPI + persisted Chroma/Pinecone index
5. **Observability** — Add Arize Phoenix tracing to any project above
