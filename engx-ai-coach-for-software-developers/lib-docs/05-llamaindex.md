# LlamaIndex — Comprehensive Guide

> **Target audience:** Python developers building LLM-powered applications.
> Every code block is self-contained and runnable (given correct API keys / packages).

---

## Table of Contents

1. [What is LlamaIndex?](#1-what-is-llamaindex)
2. [Installation & Setup](#2-installation--setup)
3. [Core Concepts](#3-core-concepts)
4. [Document Loading](#4-document-loading)
5. [Index Types](#5-index-types)
6. [Query Engines](#6-query-engines)
7. [Chat Engine](#7-chat-engine)
8. [Advanced Retrieval](#8-advanced-retrieval)
9. [Agents](#9-agents)
10. [Node Postprocessors](#10-node-postprocessors)
11. [Evaluation](#11-evaluation)
12. [LlamaIndex Workflows (0.10+)](#12-llamaindex-workflows-010)
13. [Production Patterns](#13-production-patterns)
14. [Interview Q&A](#14-interview-qa)
15. [Complete End-to-End Example](#15-complete-end-to-end-example)

---

## 1. What is LlamaIndex?

LlamaIndex (formerly GPT Index) is a **data framework for LLM applications**. It provides the
infrastructure to ingest, structure, and query arbitrary data sources using large language models.

### Core Abstraction Pipeline

```
Raw Data → Documents → Nodes → Index → Query Engine → Response
```

| Layer | Role |
|---|---|
| **Document** | Wrapper around raw text/data with metadata |
| **Node** | Chunked piece of a Document; unit of retrieval |
| **Index** | Data structure over Nodes (vector, keyword, graph…) |
| **Query Engine** | Retrieves Nodes + synthesises an LLM response |
| **Response** | Final answer + source nodes + metadata |

### LlamaIndex vs LangChain

| Concern | LlamaIndex | LangChain |
|---|---|---|
| Primary focus | Data indexing & retrieval | Generic LLM chain composition |
| RAG ergonomics | First-class, opinionated | Flexible but verbose |
| Agent support | ReAct, OpenAI, multi-agent | Large chain/agent ecosystem |
| Best when… | Your bottleneck is *data* | Your bottleneck is *chain logic* |

**Rule of thumb:** start with LlamaIndex when the core problem is "how do I query my documents
well?"; reach for LangChain when you need complex conditional chains, tools, or memory systems.

### LlamaIndex Ecosystem

- **LlamaHub** — community-contributed loaders, tools, and packs (`llama-index-readers-*`)
- **LlamaParse** — cloud PDF / DOCX parser with table/image understanding
- **LlamaCloud** — managed index hosting + retrieval API
- **llama-index-core** — open-source core library (MIT)

---

## 2. Installation & Setup

### Install

```bash
pip install llama-index \
            llama-index-llms-openai \
            llama-index-embeddings-huggingface \
            llama-index-embeddings-openai \
            llama-index-readers-web \
            llama-index-postprocessor-sentence-transformer-rerank
```

### GitHub Copilot Free Auth (no paid key required)

```python
import subprocess
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

# Reuse the token issued by `gh auth login`
token = subprocess.run(
    ["gh", "auth", "token"], capture_output=True, text=True
).stdout.strip()

llm = OpenAI(
    model="gpt-4o-mini",
    api_key=token,
    api_base="https://models.inference.ai.azure.com",
)

embed_model = OpenAIEmbedding(
    model="text-embedding-3-small",
    api_key=token,
    api_base="https://models.inference.ai.azure.com",
)
```

### Global Settings (apply once at startup)

```python
from llama_index.core import Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
import subprocess

token = subprocess.run(
    ["gh", "auth", "token"], capture_output=True, text=True
).stdout.strip()

Settings.llm = OpenAI(
    model="gpt-4o-mini",
    api_key=token,
    api_base="https://models.inference.ai.azure.com",
)

# Free local embeddings — no API key needed
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
Settings.chunk_size = 512
Settings.chunk_overlap = 50
```

---

## 3. Core Concepts

### Documents and Nodes

```python
from llama_index.core import Document
from llama_index.core.node_parser import SentenceSplitter

# A Document wraps raw text + optional metadata
doc = Document(
    text="LlamaIndex is a data framework for LLM applications.",
    metadata={"source": "intro.txt", "author": "LlamaIndex team"},
)

# A NodeParser splits Documents into Nodes
parser = SentenceSplitter(chunk_size=256, chunk_overlap=20)
nodes = parser.get_nodes_from_documents([doc])

for node in nodes:
    print(f"Node ID : {node.node_id}")
    print(f"Text    : {node.text[:80]}")
    print(f"Metadata: {node.metadata}")
```

### Index types (at a glance)

| Index | Best for |
|---|---|
| `VectorStoreIndex` | Semantic similarity search |
| `SummaryIndex` | Sequential summarisation |
| `KeywordTableIndex` | Exact keyword lookup |
| `KnowledgeGraphIndex` | Relationship / entity queries |

### Query Engine vs Chat Engine

```
QueryEngine   — one-shot question → answer
ChatEngine    — multi-turn conversation with memory
```

### Response Synthesizers

```python
from llama_index.core.response_synthesizers import get_response_synthesizer

# "compact" — fewer LLM calls; "refine" — iterative; "tree_summarize" — hierarchical
synth = get_response_synthesizer(response_mode="tree_summarize")
```

### Node Postprocessors (filter / rerank *before* synthesis)

```python
from llama_index.core.postprocessor import SimilarityPostprocessor

postproc = SimilarityPostprocessor(similarity_cutoff=0.75)
# Pass to query engine via node_postprocessors=[postproc]
```

---

## 4. Document Loading

### SimpleDirectoryReader

```python
from llama_index.core import SimpleDirectoryReader

# Reads PDF, DOCX, TXT, HTML, CSV automatically
reader = SimpleDirectoryReader(input_dir="./docs", recursive=True)
documents = reader.load_data()
print(f"Loaded {len(documents)} documents")
```

### WebPageReader

```python
from llama_index.readers.web import SimpleWebPageReader

loader = SimpleWebPageReader(html_to_text=True)
docs = loader.load_data(urls=["https://docs.llamaindex.ai/en/stable/"])
print(docs[0].text[:200])
```

### JSONReader

```python
from llama_index.readers.json import JSONReader
import json, pathlib

data = [{"title": "RAG", "body": "Retrieval Augmented Generation..."}]
pathlib.Path("sample.json").write_text(json.dumps(data))

reader = JSONReader(levels_back=0)
docs = reader.load_data(input_file="sample.json")
print(docs[0].text[:100])
```

### DatabaseReader

```python
from llama_index.readers.database import DatabaseReader

reader = DatabaseReader(
    scheme="postgresql",
    host="localhost",
    port="5432",
    user="postgres",
    password="secret",
    dbname="mydb",
)
docs = reader.load_data(query="SELECT title, body FROM articles LIMIT 50")
```

### LlamaParse (cloud — best for PDFs with tables)

```python
# pip install llama-parse
from llama_parse import LlamaParse

parser = LlamaParse(
    api_key="llx-...",   # get free key at cloud.llamaindex.ai
    result_type="markdown",
)
docs = parser.load_data("report.pdf")
print(docs[0].text[:300])
```

### Metadata Extraction

```python
from llama_index.core import SimpleDirectoryReader
from llama_index.core.extractors import TitleExtractor, QuestionsAnsweredExtractor
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.ingestion import IngestionPipeline

pipeline = IngestionPipeline(
    transformations=[
        SentenceSplitter(chunk_size=512),
        TitleExtractor(nodes=5),
        QuestionsAnsweredExtractor(questions=3),
    ]
)
docs = SimpleDirectoryReader("./docs").load_data()
nodes = pipeline.run(documents=docs)
print(nodes[0].metadata)
```

---

## 5. Index Types

### VectorStoreIndex — build, persist, load

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, StorageContext
from llama_index.core import load_index_from_storage

# --- Build ---
docs = SimpleDirectoryReader("./docs").load_data()
index = VectorStoreIndex.from_documents(docs, show_progress=True)

# --- Persist to disk ---
index.storage_context.persist(persist_dir="./storage")

# --- Reload from disk (skips re-embedding) ---
storage_ctx = StorageContext.from_defaults(persist_dir="./storage")
index = load_index_from_storage(storage_ctx)

# --- Query ---
query_engine = index.as_query_engine(similarity_top_k=3)
response = query_engine.query("What is RAG?")
print(response)
```

### VectorStoreIndex — CRUD operations

```python
from llama_index.core import Document

# INSERT a new document
new_doc = Document(text="LlamaIndex 0.10 introduced Workflows.")
index.insert(new_doc)

# UPDATE — delete old node then insert updated document
index.delete_ref_doc("old_doc_id", delete_from_docstore=True)
updated_doc = Document(text="Updated content here.", id_="old_doc_id")
index.insert(updated_doc)

# DELETE by document id
index.delete_ref_doc("some_doc_id", delete_from_docstore=True)
```

### SummaryIndex (ListIndex)

```python
from llama_index.core import SummaryIndex, SimpleDirectoryReader

docs = SimpleDirectoryReader("./docs").load_data()
index = SummaryIndex.from_documents(docs)

# Best for summarisation tasks — iterates over ALL nodes
engine = index.as_query_engine(response_mode="tree_summarize")
print(engine.query("Summarise all documents in 3 bullet points."))
```

### KeywordTableIndex

```python
from llama_index.core import KeywordTableIndex, SimpleDirectoryReader

docs = SimpleDirectoryReader("./docs").load_data()
index = KeywordTableIndex.from_documents(docs)

engine = index.as_query_engine(retriever_mode="simple")
print(engine.query("What does the document say about embeddings?"))
```

### KnowledgeGraphIndex

```python
from llama_index.core import KnowledgeGraphIndex, SimpleDirectoryReader
from llama_index.core.graph_stores import SimpleGraphStore
from llama_index.core import StorageContext

docs = SimpleDirectoryReader("./docs").load_data()
graph_store = SimpleGraphStore()
storage_ctx = StorageContext.from_defaults(graph_store=graph_store)

kg_index = KnowledgeGraphIndex.from_documents(
    docs,
    storage_context=storage_ctx,
    max_triplets_per_chunk=5,
    include_embeddings=True,
)

# Keyword + graph traversal
engine = kg_index.as_query_engine(
    include_text=True,
    retriever_mode="keyword",
    response_mode="tree_summarize",
)
print(engine.query("What entities are related to RAG?"))
```

---

## 6. Query Engines

### Basic Query Engine

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

index = VectorStoreIndex.from_documents(SimpleDirectoryReader("./docs").load_data())
engine = index.as_query_engine(similarity_top_k=4)
response = engine.query("Explain vector embeddings.")
print(response.response)
print("\nSources:")
for node in response.source_nodes:
    print(f"  [{node.score:.3f}] {node.metadata.get('file_name','?')}")
```

### Streaming Query Engine

```python
engine = index.as_query_engine(streaming=True)
stream = engine.query("What is retrieval-augmented generation?")
for token in stream.response_gen:
    print(token, end="", flush=True)
print()
```

### Citation Query Engine

```python
from llama_index.core.query_engine import CitationQueryEngine

citation_engine = CitationQueryEngine.from_args(
    index,
    similarity_top_k=3,
    citation_chunk_size=512,
)
response = citation_engine.query("How does LlamaIndex handle metadata?")
print(response.response)
print("\nCitations:")
for i, node in enumerate(response.source_nodes, 1):
    print(f"  [{i}] {node.node.get_text()[:80]}...")
```

### SQL Query Engine (Natural Language → SQL)

```python
from sqlalchemy import create_engine, text
from llama_index.core import SQLDatabase
from llama_index.core.query_engine import NLSQLTableQueryEngine

sql_engine = create_engine("sqlite:///sample.db")
with sql_engine.connect() as conn:
    conn.execute(text("CREATE TABLE IF NOT EXISTS products (id INT, name TEXT, price REAL)"))
    conn.execute(text("INSERT OR IGNORE INTO products VALUES (1,'Widget',9.99)"))
    conn.commit()

db = SQLDatabase(sql_engine, include_tables=["products"])
nl_engine = NLSQLTableQueryEngine(sql_database=db)
response = nl_engine.query("What products cost less than $15?")
print(response)
```

### Pandas Query Engine (Natural Language → Pandas)

```python
import pandas as pd
from llama_index.experimental.query_engine import PandasQueryEngine

df = pd.DataFrame({
    "name": ["Alice", "Bob", "Carol"],
    "score": [92, 85, 78],
    "dept": ["Eng", "Sales", "Eng"],
})
engine = PandasQueryEngine(df=df, verbose=True)
response = engine.query("What is the average score for the Eng department?")
print(response)
```

---

## 7. Chat Engine

### SimpleChatEngine (no retrieval — direct LLM chat)

```python
from llama_index.core.chat_engine import SimpleChatEngine

engine = SimpleChatEngine.from_defaults()
print(engine.chat("Hello! What is LlamaIndex?"))
print(engine.chat("Can you give me a code example?"))
```

### CondenseQuestionChatEngine

```python
index = VectorStoreIndex.from_documents(SimpleDirectoryReader("./docs").load_data())
engine = index.as_chat_engine(chat_mode="condense_question", verbose=True)
print(engine.chat("What is RAG?"))
print(engine.chat("How does it use embeddings?"))  # condensed into a standalone question
```

### ContextChatEngine

```python
engine = index.as_chat_engine(chat_mode="context", verbose=True)
print(engine.chat("Describe the main topics in the documents."))
print(engine.chat("Focus only on the technical details."))
```

### OpenAIAgentChatEngine (function-calling + chat)

```python
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.agent.openai import OpenAIAgent

query_tool = QueryEngineTool(
    query_engine=index.as_query_engine(),
    metadata=ToolMetadata(name="docs_search", description="Search the document index"),
)
agent = OpenAIAgent.from_tools([query_tool], verbose=True)
response = agent.chat("What does the document say about embeddings? Summarise briefly.")
print(response)
```

### Multi-turn Conversational RAG (full example)

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.memory import ChatMemoryBuffer

docs = SimpleDirectoryReader("./docs").load_data()
index = VectorStoreIndex.from_documents(docs)
memory = ChatMemoryBuffer.from_defaults(token_limit=3000)

engine = index.as_chat_engine(
    chat_mode="context",
    memory=memory,
    system_prompt=(
        "You are a helpful research assistant. "
        "Answer based only on the provided documents."
    ),
)

questions = [
    "What is the main topic of these documents?",
    "Can you elaborate on the first point?",
    "Give me a one-line summary of everything we discussed.",
]
for q in questions:
    print(f"\nUser: {q}")
    print(f"Assistant: {engine.chat(q)}")
```

---

## 8. Advanced Retrieval

### SubQuestionQueryEngine

```python
from llama_index.core.query_engine import SubQuestionQueryEngine
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.core import VectorStoreIndex, Document

# Two specialised indices
docs_a = [Document(text="Python was created by Guido van Rossum in 1991.")]
docs_b = [Document(text="JavaScript was created by Brendan Eich in 1995.")]
idx_a = VectorStoreIndex.from_documents(docs_a)
idx_b = VectorStoreIndex.from_documents(docs_b)

tools = [
    QueryEngineTool(
        query_engine=idx_a.as_query_engine(),
        metadata=ToolMetadata(name="python_facts", description="Facts about Python"),
    ),
    QueryEngineTool(
        query_engine=idx_b.as_query_engine(),
        metadata=ToolMetadata(name="js_facts", description="Facts about JavaScript"),
    ),
]

engine = SubQuestionQueryEngine.from_defaults(query_engine_tools=tools, verbose=True)
response = engine.query("Who created Python and JavaScript, and in which years?")
print(response)
```

### RouterQueryEngine

```python
from llama_index.core.query_engine import RouterQueryEngine
from llama_index.core.selectors import LLMSingleSelector

router_engine = RouterQueryEngine(
    selector=LLMSingleSelector.from_defaults(),
    query_engine_tools=tools,  # same tools from above
    verbose=True,
)
print(router_engine.query("Tell me about JavaScript's creator."))
```

### HyDE (Hypothetical Document Embeddings)

```python
from llama_index.core.indices.query.query_transform import HyDEQueryTransform
from llama_index.core.query_engine import TransformQueryEngine

base_engine = index.as_query_engine(similarity_top_k=5)
hyde = HyDEQueryTransform(include_original=True)
hyde_engine = TransformQueryEngine(base_engine, query_transform=hyde)
print(hyde_engine.query("What are the benefits of semantic search?"))
```

### RecursiveRetriever (hierarchical)

```python
from llama_index.core.retrievers import RecursiveRetriever
from llama_index.core.query_engine import RetrieverQueryEngine

# Build a parent index that references child chunk nodes
parent_retriever = RecursiveRetriever(
    "vector",
    retriever_dict={"vector": index.as_retriever(similarity_top_k=2)},
    verbose=True,
)
engine = RetrieverQueryEngine.from_args(parent_retriever)
print(engine.query("Explain chunking strategies."))
```

### Ensemble Retriever (BM25 + Vector)

```python
# pip install llama-index-retrievers-bm25
from llama_index.retrievers.bm25 import BM25Retriever
from llama_index.core.retrievers import QueryFusionRetriever

vector_retriever = index.as_retriever(similarity_top_k=3)
bm25_retriever = BM25Retriever.from_defaults(index=index, similarity_top_k=3)

fusion_retriever = QueryFusionRetriever(
    retrievers=[vector_retriever, bm25_retriever],
    similarity_top_k=4,
    num_queries=4,
    mode="reciprocal_rerank",
    verbose=True,
)
nodes = fusion_retriever.retrieve("What is an embedding model?")
for n in nodes:
    print(f"[{n.score:.3f}] {n.text[:80]}")
```

---

## 9. Agents

### ReActAgent with Tools

```python
from llama_index.core.agent import ReActAgent
from llama_index.core.tools import FunctionTool

def multiply(a: float, b: float) -> float:
    """Multiply two numbers and return the product."""
    return a * b

def add(a: float, b: float) -> float:
    """Add two numbers and return their sum."""
    return a + b

tools = [
    FunctionTool.from_defaults(fn=multiply),
    FunctionTool.from_defaults(fn=add),
]
agent = ReActAgent.from_tools(tools, verbose=True)
print(agent.chat("What is (3 + 7) multiplied by 4?"))
```

### OpenAIAgent (function calling)

```python
from llama_index.agent.openai import OpenAIAgent

agent = OpenAIAgent.from_tools(tools, verbose=True)
print(agent.chat("Calculate 15 * 6 then add 10."))
```

### QueryEngineTool + FunctionTool in one agent

```python
from llama_index.core.tools import QueryEngineTool, FunctionTool, ToolMetadata
from llama_index.agent.openai import OpenAIAgent
import datetime

def get_current_date() -> str:
    """Return today's date as a string."""
    return datetime.date.today().isoformat()

doc_tool = QueryEngineTool(
    query_engine=index.as_query_engine(),
    metadata=ToolMetadata(
        name="knowledge_base",
        description="Search the knowledge base for document content",
    ),
)
date_tool = FunctionTool.from_defaults(fn=get_current_date)

agent = OpenAIAgent.from_tools([doc_tool, date_tool], verbose=True)
print(agent.chat("What date is it and what is the main topic of my documents?"))
```

### Full Research Agent — 3 specialised tools

```python
import subprocess
from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.core.tools import QueryEngineTool, FunctionTool, ToolMetadata
from llama_index.agent.openai import OpenAIAgent
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

# Setup
token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
Settings.llm = OpenAI(model="gpt-4o-mini", api_key=token,
                      api_base="https://models.inference.ai.azure.com")
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")

# Three mini-indices simulating different data sources
ai_docs   = [Document(text="Transformers use self-attention. GPT is autoregressive.")]
db_docs   = [Document(text="PostgreSQL supports JSONB. Indexes speed up SELECT queries.")]
code_docs = [Document(text="Python list comprehensions are faster than for-loops in CPython.")]

ai_idx   = VectorStoreIndex.from_documents(ai_docs)
db_idx   = VectorStoreIndex.from_documents(db_docs)
code_idx = VectorStoreIndex.from_documents(code_docs)

tools = [
    QueryEngineTool(query_engine=ai_idx.as_query_engine(),
        metadata=ToolMetadata(name="ai_research", description="AI/ML research knowledge")),
    QueryEngineTool(query_engine=db_idx.as_query_engine(),
        metadata=ToolMetadata(name="database_facts", description="Database engineering facts")),
    QueryEngineTool(query_engine=code_idx.as_query_engine(),
        metadata=ToolMetadata(name="coding_tips", description="Python coding best practices")),
]

agent = OpenAIAgent.from_tools(tools, verbose=True,
    system_prompt="You are a senior software engineer. Cite which tool you used.")

queries = [
    "How do Transformers process sequences?",
    "What PostgreSQL feature stores nested data?",
    "Are list comprehensions faster than loops?",
]
for q in queries:
    print(f"\n>>> {q}")
    print(agent.chat(q))
```

---

## 10. Node Postprocessors

### SimilarityPostprocessor (threshold filter)

```python
from llama_index.core.postprocessor import SimilarityPostprocessor
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

index = VectorStoreIndex.from_documents(SimpleDirectoryReader("./docs").load_data())
engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[SimilarityPostprocessor(similarity_cutoff=0.75)],
)
print(engine.query("What is semantic search?"))
```

### MetadataReplacementPostprocessor

```python
from llama_index.core.postprocessor import MetadataReplacementPostprocessor

# Replaces node text with a metadata field value before synthesis
pp = MetadataReplacementPostprocessor(target_metadata_key="window")
engine = index.as_query_engine(node_postprocessors=[pp])
```

### LLMRerank

```python
from llama_index.core.postprocessor import LLMRerank

reranker = LLMRerank(choice_batch_size=5, top_n=3)
engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[reranker],
)
print(engine.query("Explain the architecture of transformer models."))
```

### SentenceTransformerRerank (local, no API cost)

```python
from llama_index.postprocessor.sentence_transformer_rerank import SentenceTransformerRerank

reranker = SentenceTransformerRerank(
    model="cross-encoder/ms-marco-MiniLM-L-2-v2",
    top_n=3,
)
engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[reranker],
)
print(engine.query("How does BERT handle bidirectional context?"))
```

### Full Pipeline: retrieval → filter → rerank → synthesise

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.postprocessor import SimilarityPostprocessor, LLMRerank
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.retrievers import VectorIndexRetriever

docs  = SimpleDirectoryReader("./docs").load_data()
index = VectorStoreIndex.from_documents(docs)

retriever = VectorIndexRetriever(index=index, similarity_top_k=10)
engine = RetrieverQueryEngine.from_args(
    retriever=retriever,
    node_postprocessors=[
        SimilarityPostprocessor(similarity_cutoff=0.6),
        LLMRerank(top_n=3),
    ],
    response_mode="compact",
)
response = engine.query("What is the most important concept in the documents?")
print(response)
```

---

## 11. Evaluation

### Faithfulness & Relevancy Evaluators

```python
from llama_index.core.evaluation import FaithfulnessEvaluator, RelevancyEvaluator

faith_eval    = FaithfulnessEvaluator()
relevancy_eval = RelevancyEvaluator()

response = index.as_query_engine().query("What is RAG?")

faith_result    = faith_eval.evaluate_response(response=response)
relevancy_result = relevancy_eval.evaluate_response(query="What is RAG?", response=response)

print(f"Faithful : {faith_result.passing} (score={faith_result.score})")
print(f"Relevant : {relevancy_result.passing} (score={relevancy_result.score})")
```

### CorrectnessEvaluator (requires reference answer)

```python
from llama_index.core.evaluation import CorrectnessEvaluator

evaluator = CorrectnessEvaluator()
result = evaluator.evaluate(
    query="What year was Python created?",
    response="Python was created in 1991.",
    reference="Python was first released in 1991 by Guido van Rossum.",
)
print(f"Correct: {result.passing}, Score: {result.score}, Feedback: {result.feedback}")
```

### BatchEvalRunner — full pipeline

```python
import asyncio
from llama_index.core.evaluation import BatchEvalRunner, FaithfulnessEvaluator, RelevancyEvaluator

queries = [
    "What is a vector database?",
    "How does chunking affect retrieval quality?",
    "What is the difference between BM25 and dense retrieval?",
]

runner = BatchEvalRunner(
    evaluators={"faithfulness": FaithfulnessEvaluator(),
                "relevancy": RelevancyEvaluator()},
    show_progress=True,
)

async def run_eval():
    engine = index.as_query_engine()
    results = await runner.aevaluate_queries(engine, queries=queries)
    for metric, evals in results.items():
        scores = [e.score for e in evals if e.score is not None]
        avg = sum(scores) / len(scores) if scores else 0
        print(f"{metric}: avg={avg:.2f}, pass_rate={sum(1 for e in evals if e.passing)/len(evals):.0%}")

asyncio.run(run_eval())
```

---

## 12. LlamaIndex Workflows (0.10+)

Workflows provide an **event-driven, step-based** execution model — much cleaner than
chaining functions manually.

```python
from llama_index.core.workflow import (
    Workflow, StartEvent, StopEvent, step, Event
)
from llama_index.core import VectorStoreIndex, Document
from dataclasses import dataclass

# Custom intermediate events
@dataclass
class RetrievalEvent(Event):
    nodes: list

@dataclass
class SynthesisEvent(Event):
    query: str
    context: str

class RAGWorkflow(Workflow):

    @step
    async def preprocess(self, ev: StartEvent) -> RetrievalEvent:
        """Clean and route the incoming query."""
        query = ev.get("query", "")
        query = query.strip().rstrip("?") + "?"  # normalise punctuation
        index: VectorStoreIndex = ev.get("index")
        retriever = index.as_retriever(similarity_top_k=3)
        nodes = retriever.retrieve(query)
        return RetrievalEvent(nodes=nodes)

    @step
    async def build_context(self, ev: RetrievalEvent) -> SynthesisEvent:
        """Merge retrieved node text into a single context block."""
        context = "\n\n".join(n.text for n in ev.nodes)
        return SynthesisEvent(query="", context=context)

    @step
    async def synthesise(self, ev: SynthesisEvent) -> StopEvent:
        """Produce the final answer."""
        from llama_index.core import Settings
        prompt = f"Context:\n{ev.context}\n\nAnswer briefly: {ev.query}"
        answer = await Settings.llm.acomplete(prompt)
        return StopEvent(result=str(answer))


async def run_rag_workflow():
    docs  = [Document(text="The Eiffel Tower is in Paris, France.")]
    index = VectorStoreIndex.from_documents(docs)
    workflow = RAGWorkflow(timeout=60)
    result = await workflow.run(query="Where is the Eiffel Tower?", index=index)
    print(result)

import asyncio
asyncio.run(run_rag_workflow())
```

---

## 13. Production Patterns

### Async Query Execution

```python
import asyncio
from llama_index.core import VectorStoreIndex, Document

async def batch_query(engine, questions: list[str]):
    tasks = [engine.aquery(q) for q in questions]
    responses = await asyncio.gather(*tasks)
    return responses

async def main():
    docs   = [Document(text="LlamaIndex supports async natively via asyncio.")]
    index  = VectorStoreIndex.from_documents(docs)
    engine = index.as_query_engine()
    qs     = ["What is LlamaIndex?", "Does it support async?"]
    for q, r in zip(qs, await batch_query(engine, qs)):
        print(f"Q: {q}\nA: {r}\n")

asyncio.run(main())
```

### Streaming Response

```python
engine = index.as_query_engine(streaming=True)
stream = engine.query("Explain LlamaIndex in detail.")
print("Streaming: ", end="")
for chunk in stream.response_gen:
    print(chunk, end="", flush=True)
print()
```

### Caching (IngestionCache + LLM Response Cache)

```python
from llama_index.core.ingestion import IngestionPipeline, IngestionCache
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.storage.kvstore import SimpleKVStore

# Ingestion cache — avoids re-embedding unchanged documents
cache = IngestionCache(cache=SimpleKVStore(), collection="my_cache")
pipeline = IngestionPipeline(
    transformations=[SentenceSplitter(chunk_size=512)],
    cache=cache,
)
docs  = [Document(text="Caching avoids redundant embedding calls.")]
nodes = pipeline.run(documents=docs)  # first run: embeds; re-runs: uses cache
print(f"Nodes: {len(nodes)}")
```

### Index Persistence with ChromaDB

```python
# pip install chromadb llama-index-vector-stores-chroma
import chromadb
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import VectorStoreIndex, StorageContext, SimpleDirectoryReader

chroma_client     = chromadb.PersistentClient(path="./chroma_db")
chroma_collection = chroma_client.get_or_create_collection("my_index")
vector_store      = ChromaVectorStore(chroma_collection=chroma_collection)
storage_ctx       = StorageContext.from_defaults(vector_store=vector_store)

docs  = SimpleDirectoryReader("./docs").load_data()
index = VectorStoreIndex.from_documents(docs, storage_context=storage_ctx)
# Data automatically persisted in ./chroma_db — reload by reusing same client
```

### FastAPI Service

```python
# pip install fastapi uvicorn
from fastapi import FastAPI
from pydantic import BaseModel
from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
import subprocess, uvicorn

app = FastAPI(title="LlamaIndex RAG API")

# Initialise once at startup
token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
Settings.llm = OpenAI(model="gpt-4o-mini", api_key=token,
                      api_base="https://models.inference.ai.azure.com")
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")

DOCS  = [Document(text="LlamaIndex makes RAG easy.")]
INDEX = VectorStoreIndex.from_documents(DOCS)

class QueryRequest(BaseModel):
    question: str
    top_k: int = 3

class QueryResponse(BaseModel):
    answer: str
    sources: list[str]

@app.post("/query", response_model=QueryResponse)
async def query(req: QueryRequest):
    engine   = INDEX.as_query_engine(similarity_top_k=req.top_k)
    response = await engine.aquery(req.question)
    sources  = [n.metadata.get("file_name", "unknown") for n in response.source_nodes]
    return QueryResponse(answer=str(response), sources=sources)

@app.get("/health")
def health():
    return {"status": "ok"}

# Run with: uvicorn this_file:app --reload
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## 14. Interview Q&A

**Q1: What is the difference between LlamaIndex and LangChain?**
LlamaIndex specialises in **data ingestion, indexing, and retrieval** — its primary abstraction is
the Index/QueryEngine pipeline optimised for RAG. LangChain is a **general-purpose chain
composition** framework with a broader set of abstractions (chains, agents, memory, tools).
Use LlamaIndex when your bottleneck is data quality/retrieval; use LangChain when you need
complex conditional chain logic. They can also be combined.

---

**Q2: What is a Node in LlamaIndex?**
A Node is a **chunk of text** derived from a Document. It is the atomic unit of retrieval.
Each Node stores: `text`, `metadata` (inherited + extracted), `embedding`, `relationships`
(prev/next/parent), and a unique `node_id`. The chunking strategy (size, overlap, splitter type)
directly impacts retrieval quality.

---

**Q3: How does VectorStoreIndex work internally?**
1. Documents are split into Nodes via a `NodeParser`.
2. Each Node's text is passed to an `EmbedModel` → float vector.
3. Vectors + metadata are stored in a `VectorStore` (in-memory by default; ChromaDB, Pinecone, etc. externally).
4. At query time the query text is embedded, a nearest-neighbour search retrieves top-k Nodes, and a `ResponseSynthesizer` generates the final answer.

---

**Q4: What is SubQuestionQueryEngine and when would you use it?**
It **decomposes a complex multi-part query** into sub-questions, routes each sub-question to the
most appropriate index/tool, collects the answers, then synthesises a final combined response.
Use it when users ask compound questions spanning multiple data sources (e.g., "Compare Python and
JavaScript performance benchmarks and memory usage").

---

**Q5: How do you persist and reload an index?**
```python
# Persist
index.storage_context.persist(persist_dir="./storage")

# Reload
from llama_index.core import StorageContext, load_index_from_storage
sc    = StorageContext.from_defaults(persist_dir="./storage")
index = load_index_from_storage(sc)
```
For production use a persistent vector store (ChromaDB, Pinecone) so embeddings survive restarts.

---

**Q6: What is KnowledgeGraphIndex and what problems does it solve?**
It extracts **(subject, predicate, object) triplets** from documents and stores them as a graph.
This enables **relationship-aware queries** that vector search misses — e.g., "Who manages which
team?" or "Which component depends on which service?" It excels at multi-hop reasoning tasks
where the answer requires traversing several entity relationships.

---

**Q7: How do you add metadata filtering to a query?**
```python
from llama_index.core.vector_stores import MetadataFilter, MetadataFilters

filters = MetadataFilters(filters=[
    MetadataFilter(key="source", value="annual_report_2024.pdf"),
])
engine = index.as_query_engine(filters=filters)
```
Only Nodes whose metadata matches the filter are considered during retrieval.

---

**Q8: What is HyDE and how does it improve retrieval?**
**Hypothetical Document Embeddings**: the LLM first generates a *hypothetical ideal answer* to
the query, then that synthetic answer is embedded and used for similarity search instead of the
raw query. This bridges the vocabulary gap between short queries and long document passages,
improving recall especially for factual or domain-specific questions.

---

**Q9: How do you implement multi-turn conversation with LlamaIndex?**
Use a **ChatEngine** with a `ChatMemoryBuffer`:
```python
from llama_index.core.memory import ChatMemoryBuffer
memory = ChatMemoryBuffer.from_defaults(token_limit=3000)
engine = index.as_chat_engine(chat_mode="context", memory=memory)
engine.chat("First question")
engine.chat("Follow-up using prior context")  # memory is preserved
```

---

**Q10: What is the RouterQueryEngine?**
A meta-engine that uses an **LLM selector** (or embedding selector) to pick the *best*
sub-engine for each query at runtime. You register multiple engines (each with a description)
and the router decides which to invoke. Useful when different document collections require
different retrieval strategies.

---

**Q11: How do you evaluate RAG quality in LlamaIndex?**
Use the built-in evaluators:
- **FaithfulnessEvaluator** — checks the answer is grounded in retrieved context (no hallucination).
- **RelevancyEvaluator** — checks the context retrieved was relevant to the query.
- **CorrectnessEvaluator** — checks the answer matches a ground-truth reference.
- **BatchEvalRunner** — runs all evaluators across a list of queries asynchronously.

---

**Q12: What are LlamaIndex Workflows?**
Introduced in 0.10, Workflows offer an **event-driven execution model** using `@step`-decorated
async methods. Each step receives a typed `Event`, does work, and emits the next `Event`. This
replaces brittle callback chains with a clean, testable, inspectable DAG of steps — ideal for
complex multi-stage RAG pipelines (preprocess → retrieve → rerank → synthesise).

---

**Q13: How do you use LlamaIndex with local models?**
```python
# pip install llama-index-llms-ollama llama-index-embeddings-huggingface
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.core import Settings

Settings.llm        = Ollama(model="llama3", request_timeout=120.0)
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
```
Everything else (indices, engines, agents) works identically — no code changes needed.

---

**Q14: What is LlamaParse and when should you use it?**
LlamaParse is a **cloud document parser** (at cloud.llamaindex.ai) that handles complex PDFs:
tables, multi-column layouts, embedded images, and scanned text via OCR. Use it when
`SimpleDirectoryReader` produces garbled output for PDFs — e.g., financial reports,
research papers, slide decks exported as PDF.

---

**Q15: How does LlamaIndex handle very large document collections?**
Several strategies:
1. **Persistent vector stores** (ChromaDB, Pinecone, Weaviate) — out-of-memory storage.
2. **IngestionPipeline with caching** — skips re-processing unchanged documents.
3. **Async ingestion** — `pipeline.arun(documents=docs)` with concurrency control.
4. **Incremental indexing** — insert/delete individual documents via `index.insert()` / `index.delete_ref_doc()`.
5. **RouterQueryEngine** — shard data into topic-specific indices, route at query time.

---

## 15. Complete End-to-End Example

Multi-document research assistant: load 3 docs → build combined index →
SubQuestion engine → interactive chat interface.

```python
"""
end_to_end_research_assistant.py
Multi-document research assistant using LlamaIndex SubQuestionQueryEngine.
Run: python end_to_end_research_assistant.py
"""
import subprocess
import asyncio
from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.core.query_engine import SubQuestionQueryEngine
from llama_index.core.memory import ChatMemoryBuffer
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

# ── 1. Configure LLM + embeddings ─────────────────────────────────────────────
token = subprocess.run(
    ["gh", "auth", "token"], capture_output=True, text=True
).stdout.strip()

Settings.llm = OpenAI(
    model="gpt-4o-mini",
    api_key=token,
    api_base="https://models.inference.ai.azure.com",
)
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
Settings.chunk_size = 256

# ── 2. Load three document "collections" ──────────────────────────────────────
python_doc = Document(
    text=(
        "Python is a high-level, interpreted programming language created by Guido van Rossum "
        "and first released in 1991. It emphasises readability and supports multiple paradigms: "
        "procedural, object-oriented, and functional. Python 3.12 introduced inline type aliases "
        "and improved error messages. The GIL limits CPU-bound threading but asyncio enables "
        "efficient I/O concurrency. Popular frameworks include Django, FastAPI, and PyTorch."
    ),
    metadata={"source": "python_overview.txt"},
)

rust_doc = Document(
    text=(
        "Rust is a systems programming language focused on safety, speed, and concurrency. "
        "It was created by Mozilla Research and first appeared in 2010. Rust eliminates null "
        "pointer dereferences and data races at compile time via its ownership and borrow-checker "
        "system. Rust 1.75 stabilised async fn in traits. It is widely used in WebAssembly, "
        "embedded systems, and performance-critical services."
    ),
    metadata={"source": "rust_overview.txt"},
)

llm_doc = Document(
    text=(
        "Large Language Models (LLMs) are neural networks trained on massive text corpora to "
        "predict the next token. GPT-4 and Claude 3 use transformer architectures with billions "
        "of parameters. Retrieval-Augmented Generation (RAG) extends LLMs by injecting relevant "
        "context from a vector database at inference time, reducing hallucinations. Fine-tuning "
        "adapts a pre-trained LLM to a specific domain using supervised learning on labelled data."
    ),
    metadata={"source": "llm_overview.txt"},
)

# ── 3. Build per-topic indices ─────────────────────────────────────────────────
python_index = VectorStoreIndex.from_documents([python_doc])
rust_index   = VectorStoreIndex.from_documents([rust_doc])
llm_index    = VectorStoreIndex.from_documents([llm_doc])

print("✓ All three indices built.")

# ── 4. Wrap indices as QueryEngineTools ───────────────────────────────────────
tools = [
    QueryEngineTool(
        query_engine=python_index.as_query_engine(similarity_top_k=2),
        metadata=ToolMetadata(
            name="python_knowledge",
            description="Facts and details about the Python programming language",
        ),
    ),
    QueryEngineTool(
        query_engine=rust_index.as_query_engine(similarity_top_k=2),
        metadata=ToolMetadata(
            name="rust_knowledge",
            description="Facts and details about the Rust programming language",
        ),
    ),
    QueryEngineTool(
        query_engine=llm_index.as_query_engine(similarity_top_k=2),
        metadata=ToolMetadata(
            name="llm_knowledge",
            description="Information about Large Language Models and RAG",
        ),
    ),
]

# ── 5. Build SubQuestionQueryEngine ───────────────────────────────────────────
research_engine = SubQuestionQueryEngine.from_defaults(
    query_engine_tools=tools,
    verbose=True,
)
print("✓ SubQuestionQueryEngine ready.\n")

# ── 6. Run example queries ────────────────────────────────────────────────────
sample_questions = [
    "Who created Python and Rust, and in what years were they released?",
    "How does RAG reduce hallucinations in LLMs?",
    "Compare Python and Rust in terms of memory safety.",
]

for question in sample_questions:
    print(f"{'─'*60}")
    print(f"Question: {question}")
    response = research_engine.query(question)
    print(f"Answer  : {response}\n")

# ── 7. Interactive REPL ───────────────────────────────────────────────────────
print("='*60")
print("Interactive Research Assistant — type 'exit' to quit")
print("="*60)
while True:
    try:
        user_input = input("\nYou: ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\nGoodbye!")
        break
    if not user_input or user_input.lower() in ("exit", "quit", "q"):
        print("Goodbye!")
        break
    response = research_engine.query(user_input)
    print(f"\nAssistant: {response}")
```

---

*End of LlamaIndex Comprehensive Guide — ~950 lines*
