# LlamaIndex Code Examples
> 18 annotated Python examples covering every major LlamaIndex feature

---

## Prerequisites

```bash
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai
pip install llama-parse llama-index-vector-stores-chroma
```

```python
import os
os.environ["OPENAI_API_KEY"] = "sk-..."
```

---

## Example 1 — SimpleDirectoryReader: Loading Documents

```python
from llama_index.core import SimpleDirectoryReader

# Load all supported files from a directory (recursive)
documents = SimpleDirectoryReader(
    input_dir="./data",
    recursive=True,
    filename_as_id=True,       # use filename as document ID for deduplication
    required_exts=[".pdf", ".txt", ".md"]  # only these extensions
).load_data()

print(f"Loaded {len(documents)} documents")
for doc in documents[:3]:
    print(f"  - {doc.metadata.get('file_name')}: {len(doc.text)} chars")
```

**Key points**: `filename_as_id=True` enables smart re-indexing — documents that haven't changed
won't be re-embedded on subsequent runs. `required_exts` filters file types.

---

## Example 2 — VectorStoreIndex: Building a Basic Index

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core import Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

# Configure global LLM and embedding model
Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

# Load and index documents
documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(
    documents,
    show_progress=True   # progress bar during embedding
)

print("Index built successfully")
print(f"Number of nodes indexed: {len(index.docstore.docs)}")
```

**Key points**: `Settings` is the global configuration object introduced in LlamaIndex v0.10.
Always configure `llm` and `embed_model` before building indexes.

---

## Example 3 — Basic Q&A with QueryEngine

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)

# Create query engine
query_engine = index.as_query_engine(
    similarity_top_k=5,          # retrieve top 5 most relevant nodes
    response_mode="compact",     # efficient multi-node synthesis
    streaming=False
)

# Run a query
response = query_engine.query("What are the main conclusions of the document?")

print("Answer:", response)
print("
--- Source Nodes ---")
for node in response.source_nodes:
    print(f"  Score: {node.score:.3f} | File: {node.metadata.get('file_name', 'N/A')}")
    print(f"  Preview: {node.text[:120]}...")
```

**Key points**: `response.source_nodes` gives full transparency into what was retrieved. Always
inspect these when debugging poor response quality.

---

## Example 4 — Chat Engine: Multi-Turn Conversation

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)

# Create a chat engine with context-aware mode
chat_engine = index.as_chat_engine(
    chat_mode="condense_plus_context",  # condense question + retrieve context
    verbose=True,                        # show reasoning steps
    similarity_top_k=3
)

# Multi-turn conversation
print("=== Turn 1 ===")
r1 = chat_engine.chat("What is the document about?")
print(r1)

print("
=== Turn 2 (follow-up) ===")
r2 = chat_engine.chat("Can you elaborate on the methodology section?")
print(r2)  # Uses chat history to understand "the methodology"

print("
=== Turn 3 ===")
r3 = chat_engine.chat("What are the key limitations mentioned?")
print(r3)

# Reset conversation for a fresh start
chat_engine.reset()
```

---

## Example 5 — SentenceSplitter: Custom Node Parsing

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.node_parser import SentenceSplitter

# Load documents
documents = SimpleDirectoryReader("./data").load_data()

# Configure custom splitter
splitter = SentenceSplitter(
    chunk_size=256,       # ~256 tokens per chunk (smaller = more precise retrieval)
    chunk_overlap=30,     # 30 token overlap between chunks
    paragraph_separator="

",
    secondary_chunking_regex="[.!?]\s+"
)

# Parse into nodes manually
nodes = splitter.get_nodes_from_documents(documents, show_progress=True)

print(f"Documents: {len(documents)} → Nodes: {len(nodes)}")
print(f"
Example node:")
print(f"  Text: {nodes[0].text[:200]}")
print(f"  Metadata: {nodes[0].metadata}")
print(f"  Relationships: {list(nodes[0].relationships.keys())}")

# Build index directly from nodes
index = VectorStoreIndex(nodes)
```

---

## Example 6 — SemanticSplitter: Embedding-Based Chunking

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.node_parser import SemanticSplitter
from llama_index.embeddings.openai import OpenAIEmbedding

documents = SimpleDirectoryReader("./data").load_data()
embed_model = OpenAIEmbedding(model="text-embedding-3-small")

# SemanticSplitter groups sentences by meaning
splitter = SemanticSplitter(
    buffer_size=1,                          # sentences of context on each side
    breakpoint_percentile_threshold=95,     # split at top 5% dissimilarity points
    embed_model=embed_model
)

nodes = splitter.get_nodes_from_documents(documents, show_progress=True)

# Compare chunk sizes
sizes = [len(n.text.split()) for n in nodes]
print(f"Node count: {len(nodes)}")
print(f"Average words per node: {sum(sizes)/len(sizes):.0f}")
print(f"Min: {min(sizes)} | Max: {max(sizes)} words")

index = VectorStoreIndex(nodes)
engine = index.as_query_engine()
print(engine.query("What is the central argument?"))
```

---

## Example 7 — SummaryIndex: Document Summarisation

```python
from llama_index.core import SummaryIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()

# SummaryIndex processes ALL nodes — ideal for summarisation
summary_index = SummaryIndex.from_documents(documents)

# Use tree_summarize for best results with many nodes
engine = summary_index.as_query_engine(
    response_mode="tree_summarize",
    use_async=True     # parallelise summarisation
)

summary = engine.query("Provide a comprehensive summary of all the documents.")
print(summary)
```

**Key points**: Unlike VectorStoreIndex, SummaryIndex iterates through all nodes. This is slower
but ensures no content is missed. Perfect for "summarise this document" tasks.

---

## Example 8 — DocumentSummaryIndex: Multi-Document Routing

```python
from llama_index.core import DocumentSummaryIndex, SimpleDirectoryReader
from llama_index.core.node_parser import SentenceSplitter

# Load multiple documents separately
docs_apple = SimpleDirectoryReader("./apple_docs").load_data()
docs_msft = SimpleDirectoryReader("./msft_docs").load_data()
all_docs = docs_apple + docs_msft

splitter = SentenceSplitter(chunk_size=1024)

# DocumentSummaryIndex creates per-document summaries for smart routing
doc_summary_index = DocumentSummaryIndex.from_documents(
    all_docs,
    transformations=[splitter],
    response_synthesizer_mode="tree_summarize",
    show_progress=True
)

# The index now knows which documents are about which topics
engine = doc_summary_index.as_query_engine(
    response_mode="tree_summarize"
)

# This query will be routed to Apple documents automatically
response = engine.query("What are Apple's latest revenue figures?")
print(response)
```

---

## Example 9 — KnowledgeGraphIndex: Building a Knowledge Graph

```python
from llama_index.core import KnowledgeGraphIndex, SimpleDirectoryReader
from llama_index.core.graph_stores import SimpleGraphStore
from llama_index.core import StorageContext

documents = SimpleDirectoryReader("./data").load_data()

# Build knowledge graph by extracting entity-relation triples
graph_store = SimpleGraphStore()
storage_context = StorageContext.from_defaults(graph_store=graph_store)

kg_index = KnowledgeGraphIndex.from_documents(
    documents,
    storage_context=storage_context,
    max_triplets_per_chunk=5,    # max triples extracted per node
    include_embeddings=True,     # also embed nodes for hybrid querying
    show_progress=True
)

# Query the knowledge graph
engine = kg_index.as_query_engine(
    include_text=True,
    retriever_mode="hybrid",   # keyword + embedding retrieval
    similarity_top_k=5
)

response = engine.query("What relationships exist between neural networks and transformers?")
print(response)

# Visualise the graph (optional — requires pyvis)
# kg_index.get_networkx_graph()
```

---

## Example 10 — Sub-Question Query Engine: Complex Multi-Document Queries

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.query_engine import SubQuestionQueryEngine
from llama_index.core.tools import QueryEngineTool
from llama_index.core import Settings
from llama_index.llms.openai import OpenAI

Settings.llm = OpenAI(model="gpt-4o")

# Build separate indexes per document collection
apple_docs = SimpleDirectoryReader("./apple").load_data()
google_docs = SimpleDirectoryReader("./google").load_data()
meta_docs = SimpleDirectoryReader("./meta").load_data()

apple_index = VectorStoreIndex.from_documents(apple_docs)
google_index = VectorStoreIndex.from_documents(google_docs)
meta_index = VectorStoreIndex.from_documents(meta_docs)

# Wrap each as a named tool
tools = [
    QueryEngineTool.from_defaults(
        query_engine=apple_index.as_query_engine(),
        name="apple_financials",
        description="Apple Inc. annual reports and financial statements 2020-2024"
    ),
    QueryEngineTool.from_defaults(
        query_engine=google_index.as_query_engine(),
        name="google_financials",
        description="Alphabet/Google annual reports and financial statements 2020-2024"
    ),
    QueryEngineTool.from_defaults(
        query_engine=meta_index.as_query_engine(),
        name="meta_financials",
        description="Meta Platforms annual reports and financial statements 2020-2024"
    ),
]

# SubQuestionQueryEngine decomposes complex queries automatically
engine = SubQuestionQueryEngine.from_defaults(
    query_engine_tools=tools,
    verbose=True   # shows sub-questions as they're generated
)

response = engine.query(
    "Compare the R&D spending trends of Apple, Google, and Meta from 2020 to 2024. "
    "Which company has increased its R&D investment the most?"
)
print(response)
```

---

## Example 11 — Metadata Filtering: Precise Scoped Retrieval

```python
from llama_index.core import VectorStoreIndex, Document
from llama_index.core.vector_stores import (
    MetadataFilter, MetadataFilters, FilterOperator, FilterCondition
)

# Create documents with rich metadata
docs = [
    Document(text="Q1 2024 revenue was $94.8B...", metadata={"quarter": "Q1", "year": 2024, "topic": "revenue"}),
    Document(text="Q2 2024 revenue was $98.1B...", metadata={"quarter": "Q2", "year": 2024, "topic": "revenue"}),
    Document(text="Q1 2023 revenue was $88.2B...", metadata={"quarter": "Q1", "year": 2023, "topic": "revenue"}),
    Document(text="R&D expenses in 2024 increased by 15%...", metadata={"year": 2024, "topic": "expenses"}),
]

index = VectorStoreIndex.from_documents(docs)

# Filter: only 2024 documents about revenue
filters = MetadataFilters(
    filters=[
        MetadataFilter(key="year", value=2024, operator=FilterOperator.EQ),
        MetadataFilter(key="topic", value="revenue", operator=FilterOperator.EQ),
    ],
    condition=FilterCondition.AND
)

engine = index.as_query_engine(filters=filters, similarity_top_k=5)
response = engine.query("What were the revenue figures?")
print(response)
# Only retrieves from Q1 and Q2 2024 revenue documents
```

---

## Example 12 — StorageContext: Persisting an Index

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, StorageContext
import os

PERSIST_DIR = "./index_storage"

if not os.path.exists(PERSIST_DIR):
    # First run: build and persist the index
    print("Building index...")
    documents = SimpleDirectoryReader("./data").load_data()
    
    storage_context = StorageContext.from_defaults()
    index = VectorStoreIndex.from_documents(
        documents,
        storage_context=storage_context,
        show_progress=True
    )
    
    # Persist all components (docstore, index store, vector store)
    storage_context.persist(persist_dir=PERSIST_DIR)
    print(f"Index persisted to {PERSIST_DIR}")
else:
    print("Index directory found, skipping rebuild")

print(f"Storage size: {sum(os.path.getsize(os.path.join(PERSIST_DIR, f)) for f in os.listdir(PERSIST_DIR))} bytes")
```

---

## Example 13 — Loading from Persisted Storage

```python
from llama_index.core import StorageContext, load_index_from_storage

PERSIST_DIR = "./index_storage"

# Reload without re-embedding (instant)
print("Loading persisted index...")
storage_context = StorageContext.from_defaults(persist_dir=PERSIST_DIR)
index = load_index_from_storage(storage_context)

engine = index.as_query_engine(similarity_top_k=5)
response = engine.query("What are the key findings?")
print(response)

# Check loaded stats
print(f"
Nodes in index: {len(index.docstore.docs)}")
```

---

## Example 14 — FunctionAgent with Tools

```python
from llama_index.core.agent import FunctionCallingAgent
from llama_index.core.tools import FunctionTool
from llama_index.llms.openai import OpenAI
from datetime import datetime
import requests

def get_stock_price(ticker: str) -> str:
    '''Retrieve the current stock price for a given ticker symbol.'''
    # Mock implementation — replace with real API call
    prices = {"AAPL": 189.50, "MSFT": 415.20, "GOOGL": 175.80}
    price = prices.get(ticker.upper(), "Unknown")
    return f"{ticker.upper()}: ${price}" if price != "Unknown" else f"Ticker {ticker} not found"

def calculate_pe_ratio(price: float, eps: float) -> str:
    '''Calculate the Price-to-Earnings ratio given stock price and EPS.'''
    if eps <= 0:
        return "Cannot calculate P/E ratio with non-positive EPS"
    pe = price / eps
    return f"P/E Ratio: {pe:.2f}"

def get_current_date() -> str:
    '''Returns the current date in ISO format.'''
    return datetime.now().strftime("%Y-%m-%d")

# Create tools
tools = [
    FunctionTool.from_defaults(fn=get_stock_price),
    FunctionTool.from_defaults(fn=calculate_pe_ratio),
    FunctionTool.from_defaults(fn=get_current_date),
]

llm = OpenAI(model="gpt-4o-mini")
agent = FunctionCallingAgent.from_tools(tools, llm=llm, verbose=True)

response = agent.chat(
    "What is Apple's current stock price and if their EPS is $6.57, what is the P/E ratio?"
)
print(response)
```

---

## Example 15 — ReActAgent with Query Engine Tool

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.agent import ReActAgent
from llama_index.core.tools import FunctionTool, QueryEngineTool
from llama_index.llms.openai import OpenAI
import math

# Build knowledge base tool
documents = SimpleDirectoryReader("./research_papers").load_data()
index = VectorStoreIndex.from_documents(documents)

kb_tool = QueryEngineTool.from_defaults(
    query_engine=index.as_query_engine(),
    name="research_knowledge_base",
    description="Search the research paper knowledge base for information about AI models, benchmarks, and findings"
)

# Calculator tool
def calculate(expression: str) -> str:
    '''Evaluate a mathematical expression safely.'''
    try:
        # Restrict to safe math operations
        allowed = {k: v for k, v in math.__dict__.items() if not k.startswith("_")}
        result = eval(expression, {"__builtins__": {}}, allowed)
        return str(result)
    except Exception as e:
        return f"Error: {e}"

calc_tool = FunctionTool.from_defaults(fn=calculate)

# ReActAgent works with any LLM
llm = OpenAI(model="gpt-4o")
agent = ReActAgent.from_tools(
    [kb_tool, calc_tool],
    llm=llm,
    verbose=True,
    max_iterations=10
)

response = agent.chat(
    "What accuracy did the best model achieve on the benchmark described in the papers? "
    "And what percentage improvement is that over a 75% baseline?"
)
print(response)
```

---

## Example 16 — Response Mode Comparison

```python
from llama_index.core import SummaryIndex, SimpleDirectoryReader
import time

documents = SimpleDirectoryReader("./data").load_data()
index = SummaryIndex.from_documents(documents)

query = "Summarize the main themes across all documents"
modes = ["refine", "compact", "tree_summarize", "simple_summarize", "accumulate"]

results = {}
for mode in modes:
    engine = index.as_query_engine(response_mode=mode)
    start = time.time()
    response = engine.query(query)
    elapsed = time.time() - start
    results[mode] = {"response": str(response)[:300], "time": elapsed}

for mode, data in results.items():
    print(f"
{'='*50}")
    print(f"Mode: {mode} | Time: {data['time']:.2f}s")
    print(f"Response: {data['response']}...")
```

---

## Example 17 — LlamaParse: Complex PDF Extraction

```python
from llama_parse import LlamaParse
from llama_index.core import VectorStoreIndex
from llama_index.core import SimpleDirectoryReader

# LlamaParse handles tables, multi-column, figures, formulas
parser = LlamaParse(
    api_key="llx-...",           # from https://cloud.llamaindex.ai
    result_type="markdown",      # or "text" for simpler output
    num_workers=4,               # parallel parsing
    verbose=True,
    language="en"
)

# Method 1: Direct file parsing
documents = parser.load_data("annual_report_2024.pdf")

# Method 2: Integrate with SimpleDirectoryReader
file_extractor = {".pdf": parser}
documents = SimpleDirectoryReader(
    "./financial_reports",
    file_extractor=file_extractor
).load_data()

# The markdown output preserves table structure
for doc in documents[:2]:
    print(f"File: {doc.metadata.get('file_name')}")
    print(f"Content preview:
{doc.text[:500]}
")

# Build index from parsed documents
index = VectorStoreIndex.from_documents(documents)
engine = index.as_query_engine()

# Now tables and complex layouts are queryable
response = engine.query("What was the total revenue breakdown by segment in Q4 2024?")
print(response)
```

---

## Example 18 — Multi-Document Query with DocumentSummaryIndex

```python
from llama_index.core import DocumentSummaryIndex, SimpleDirectoryReader
from llama_index.core.node_parser import SentenceSplitter
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings
import os

Settings.llm = OpenAI(model="gpt-4o")

# Load documents from multiple directories, tagging with metadata
all_docs = []
for company in ["apple", "microsoft", "amazon", "google"]:
    path = f"./reports/{company}"
    if os.path.exists(path):
        docs = SimpleDirectoryReader(path).load_data()
        for doc in docs:
            doc.metadata["company"] = company  # tag all docs with company name
        all_docs.extend(docs)

print(f"Total documents loaded: {len(all_docs)}")

# DocumentSummaryIndex routes queries to the right documents automatically
doc_index = DocumentSummaryIndex.from_documents(
    all_docs,
    transformations=[SentenceSplitter(chunk_size=1024, chunk_overlap=128)],
    show_progress=True
)

# Retrieve and print the auto-generated summary for each document
for doc_id in list(doc_index.ref_doc_info.keys())[:3]:
    summary = doc_index.get_document_summary(doc_id)
    print(f"
Doc {doc_id[:8]}... summary:
{summary[:300]}")

# Cross-document query — index routes to the right documents
engine = doc_index.as_query_engine(
    response_mode="tree_summarize",
    similarity_top_k=3
)
response = engine.query(
    "Which company has the strongest cloud revenue growth and what are the key drivers?"
)
print("
=== Final Answer ===")
print(response)
```

---

## Quick Reference — Common Patterns

```python
# Pattern 1: 5-line RAG
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
index = VectorStoreIndex.from_documents(SimpleDirectoryReader("data").load_data())
print(index.as_query_engine().query("Your question here"))

# Pattern 2: Streaming response
engine = index.as_query_engine(streaming=True)
for token in engine.query("What is the summary?").response_gen:
    print(token, end="", flush=True)

# Pattern 3: Async query
import asyncio
async def aquery():
    response = await engine.aquery("Async question?")
    return response
result = asyncio.run(aquery())

# Pattern 4: Retrieve without synthesis
retriever = index.as_retriever(similarity_top_k=10)
nodes = retriever.retrieve("search term")

# Pattern 5: Custom embedding model
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.core import Settings
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-large-en-v1.5")
```
