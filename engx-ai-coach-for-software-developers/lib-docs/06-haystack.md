# Haystack (deepset) — Comprehensive Guide

> **Target audience:** Software engineers preparing for AI/LLM engineering roles  
> **Haystack version:** 2.x (component-based architecture)  
> **Lines:** ~1000 | All code examples are standalone and runnable

---

## Table of Contents

1. [What is Haystack?](#1-what-is-haystack)
2. [Installation & Setup](#2-installation--setup)
3. [Core Architecture (Haystack 2.x)](#3-core-architecture-haystack-2x)
4. [Components Deep Dive](#4-components-deep-dive)
5. [Building Pipelines](#5-building-pipelines)
6. [Document Stores](#6-document-stores)
7. [Hybrid Retrieval](#7-hybrid-retrieval)
8. [Evaluation](#8-evaluation)
9. [Custom Components](#9-custom-components)
10. [Haystack Agent (2.x)](#10-haystack-agent-2x)
11. [Serialization & Deployment](#11-serialization--deployment)
12. [Real-World Patterns](#12-real-world-patterns)
13. [Interview Q&A](#13-interview-qa-15-questions)
14. [Complete End-to-End Example](#14-complete-end-to-end-example)

---

## 1. What is Haystack?

**Haystack** is an open-source, end-to-end NLP/LLM pipeline framework built by [deepset](https://www.deepset.ai/). It provides production-grade building blocks for retrieval-augmented generation (RAG), document search, question answering, and agentic systems.

### Haystack 1.x vs 2.x

| Aspect | Haystack 1.x | Haystack 2.x |
|--------|-------------|-------------|
| Architecture | Node-based graph | Declarative component system |
| Component interface | `run(query, ...)` varies | Strict `run(**kwargs) -> dict` |
| Type safety | Minimal | Full input/output socket typing |
| Composability | Limited branching | Arbitrary DAG, loops supported |
| Serialization | YAML (partial) | Full YAML round-trip |
| Evaluation | External | Built-in evaluators |

### Key Differentiators

- **Evaluation-first**: Faithfulness, ContextRelevance, SAS, RAGAS built-in
- **Production-grade**: YAML serialization, deepset Cloud deployment, Docker-ready
- **Component marketplace**: Hundreds of community + official components
- **Strict typing**: Every component declares typed `InputSocket`/`OutputSocket`

### When to Use Haystack vs Alternatives

| Use Case | Best Choice |
|----------|-------------|
| RAG + evaluation + production ops | **Haystack** |
| Rapid prototyping, chains, agents | LangChain |
| Complex document indexing + graph RAG | LlamaIndex |
| Simple one-off LLM calls | Direct SDK |

---

## 2. Installation & Setup

```bash
# Core install
pip install haystack-ai

# Optional: sentence-transformers for local embeddings
pip install sentence-transformers

# Optional: PDF support
pip install pypdf

# Optional: Qdrant support
pip install qdrant-haystack

# Optional: Elasticsearch support
pip install elasticsearch-haystack
```

### GitHub Copilot Free Auth (Azure Inference Endpoint)

```python
import subprocess
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.dataclasses import ChatMessage

# Grab token from the GitHub CLI (gh must be authenticated)
token = subprocess.run(
    ["gh", "auth", "token"],
    capture_output=True,
    text=True
).stdout.strip()

generator = OpenAIChatGenerator(
    model="gpt-4o-mini",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com"
)

result = generator.run(messages=[ChatMessage.from_user("Say hello in one sentence.")])
print(result["replies"][0].text)
```

### Standard Environment Setup

```python
import os

# OpenAI
os.environ["OPENAI_API_KEY"] = "sk-..."

# HuggingFace (for local models)
os.environ["HF_API_TOKEN"] = "hf_..."

# Verify Haystack version
import haystack
print(haystack.__version__)  # Should be 2.x
```

---

## 3. Core Architecture (Haystack 2.x)

### The Component Contract

Every Haystack 2.x component follows a strict contract:

```python
from haystack import component

@component
class MyComponent:
    """A minimal valid Haystack 2.x component."""

    @component.output_types(result=str, count=int)
    def run(self, text: str, multiplier: int = 1) -> dict:
        """
        Inputs  : text (str), multiplier (int)
        Outputs : result (str), count (int)
        """
        result = text * multiplier
        return {"result": result, "count": len(result)}

# Use standalone
comp = MyComponent()
output = comp.run(text="hello", multiplier=3)
print(output)  # {'result': 'hellohellohello', 'count': 15}
```

### The Document Dataclass

```python
from haystack import Document

doc = Document(
    id="doc-001",                        # auto-generated if omitted
    content="Haystack is a great framework.",
    meta={"source": "docs.txt", "page": 1},
    embedding=[0.1, 0.2, 0.3],          # set by embedder
    score=0.92                           # set by retriever
)

print(doc.id)
print(doc.content)
print(doc.meta)
```

### Pipeline Basics

```python
from haystack import Pipeline
from haystack import component

@component
class Greeter:
    @component.output_types(greeting=str)
    def run(self, name: str) -> dict:
        return {"greeting": f"Hello, {name}!"}

@component
class Shout:
    @component.output_types(loud=str)
    def run(self, text: str) -> dict:
        return {"loud": text.upper()}

# Build pipeline
pipe = Pipeline()
pipe.add_component("greeter", Greeter())
pipe.add_component("shout", Shout())

# Connect: greeter.greeting -> shout.text
pipe.connect("greeter.greeting", "shout.text")

result = pipe.run({"greeter": {"name": "Haystack"}})
print(result["shout"]["loud"])  # HELLO, HAYSTACK!
```

---

## 4. Components Deep Dive

### 4.1 Converters

```python
from haystack.components.converters import (
    PyPDFToDocument,
    MarkdownToDocument,
    HTMLToDocument,
    TextFileToDocument,
)
from pathlib import Path

# PDF → Document
pdf_converter = PyPDFToDocument()
docs = pdf_converter.run(sources=[Path("report.pdf")])["documents"]

# Markdown → Document
md_converter = MarkdownToDocument()
docs = md_converter.run(sources=[Path("README.md")])["documents"]

# HTML → Document (strips tags)
html_converter = HTMLToDocument()
docs = html_converter.run(sources=[Path("page.html")])["documents"]

# Plain text
txt_converter = TextFileToDocument()
docs = txt_converter.run(sources=[Path("data.txt")])["documents"]

for d in docs:
    print(d.content[:120])
```

### 4.2 Preprocessors

```python
from haystack.components.preprocessors import DocumentCleaner, DocumentSplitter
from haystack import Document

raw_docs = [
    Document(content="  Hello   world.\n\nThis is   a test.  "),
    Document(content="Another document with lots of   whitespace."),
]

# Clean: remove extra whitespace, empty lines
cleaner = DocumentCleaner(
    remove_empty_lines=True,
    remove_extra_whitespaces=True,
    remove_substrings=None,
)
cleaned = cleaner.run(documents=raw_docs)["documents"]

# Split into chunks (by word count)
splitter = DocumentSplitter(
    split_by="word",       # "word" | "sentence" | "passage" | "page"
    split_length=100,      # max words per chunk
    split_overlap=10,      # overlap between chunks
)
chunks = splitter.run(documents=cleaned)["documents"]
print(f"Split into {len(chunks)} chunks")
for c in chunks[:2]:
    print(" •", c.content[:80])
```

### 4.3 Embedders

```python
import os
from haystack.components.embedders import (
    OpenAIDocumentEmbedder,
    OpenAITextEmbedder,
)
from haystack import Document

# --- OpenAI embedders (requires OPENAI_API_KEY) ---
doc_embedder = OpenAIDocumentEmbedder(model="text-embedding-3-small")
text_embedder = OpenAITextEmbedder(model="text-embedding-3-small")

docs = [Document(content="Haystack makes RAG easy.")]
embedded_docs = doc_embedder.run(documents=docs)["documents"]
print("Doc embedding dim:", len(embedded_docs[0].embedding))

query_result = text_embedder.run(text="What makes RAG easy?")
print("Query embedding dim:", len(query_result["embedding"]))

# --- Free local embeddings with SentenceTransformers ---
from haystack.components.embedders import (
    SentenceTransformersDocumentEmbedder,
    SentenceTransformersTextEmbedder,
)

local_doc_embedder = SentenceTransformersDocumentEmbedder(
    model="sentence-transformers/all-MiniLM-L6-v2"
)
local_doc_embedder.warm_up()  # downloads model once

embedded = local_doc_embedder.run(documents=docs)["documents"]
print("Local embedding dim:", len(embedded[0].embedding))
```

### 4.4 Retrievers

```python
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import (
    InMemoryBM25Retriever,
    InMemoryEmbeddingRetriever,
)
from haystack import Document

store = InMemoryDocumentStore()
store.write_documents([
    Document(content="Paris is the capital of France."),
    Document(content="Berlin is the capital of Germany."),
    Document(content="Tokyo is the capital of Japan."),
])

# BM25 keyword retrieval
bm25 = InMemoryBM25Retriever(document_store=store, top_k=2)
results = bm25.run(query="capital France")["documents"]
for r in results:
    print(f"  [{r.score:.3f}] {r.content}")

# Embedding retrieval (docs must have embeddings first)
# store.write_documents(embedded_docs)
# emb_retriever = InMemoryEmbeddingRetriever(document_store=store, top_k=2)
# results = emb_retriever.run(query_embedding=[0.1, 0.2, ...])["documents"]
```

### 4.5 Rankers

```python
from haystack.components.rankers import TransformersSimilarityRanker
from haystack import Document

ranker = TransformersSimilarityRanker(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2",
    top_k=3,
)
ranker.warm_up()

docs = [
    Document(content="The Eiffel Tower is in Paris."),
    Document(content="France is known for wine and cheese."),
    Document(content="Paris is the capital and largest city of France."),
    Document(content="Berlin is the capital of Germany."),
]

ranked = ranker.run(query="What city is the Eiffel Tower in?", documents=docs)
for d in ranked["documents"]:
    print(f"  [{d.score:.4f}] {d.content}")
```

### 4.6 Generators

```python
import subprocess
from haystack.components.generators import OpenAIGenerator
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.dataclasses import ChatMessage

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

# Text generator (completion style)
gen = OpenAIGenerator(
    model="gpt-4o-mini",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
)
out = gen.run(prompt="Explain RAG in one sentence.")
print(out["replies"][0])

# Chat generator (messages style)
chat_gen = OpenAIChatGenerator(
    model="gpt-4o-mini",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
)
messages = [
    ChatMessage.from_system("You are a helpful AI assistant."),
    ChatMessage.from_user("What is Haystack?"),
]
out = chat_gen.run(messages=messages)
print(out["replies"][0].text)

# --- Fully local with HuggingFace ---
# from haystack.components.generators import HuggingFaceLocalGenerator
# local_gen = HuggingFaceLocalGenerator(model="google/flan-t5-base", task="text2text-generation")
# local_gen.warm_up()
# out = local_gen.run(prompt="What is 2+2?")
# print(out["replies"][0])
```

---

## 5. Building Pipelines

### 5.1 Indexing Pipeline

```python
import subprocess
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.preprocessors import DocumentCleaner, DocumentSplitter
from haystack.components.embedders import OpenAIDocumentEmbedder
from haystack.components.writers import DocumentWriter

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

store = InMemoryDocumentStore()

indexing = Pipeline()
indexing.add_component("cleaner",  DocumentCleaner())
indexing.add_component("splitter", DocumentSplitter(split_by="sentence", split_length=3))
indexing.add_component("embedder", OpenAIDocumentEmbedder(
    model="text-embedding-3-small",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
))
indexing.add_component("writer",   DocumentWriter(document_store=store))

indexing.connect("cleaner.documents",  "splitter.documents")
indexing.connect("splitter.documents", "embedder.documents")
indexing.connect("embedder.documents", "writer.documents")

raw_docs = [
    Document(content="Haystack is a framework for building NLP pipelines. It is made by deepset. It supports RAG."),
    Document(content="Retrieval-Augmented Generation combines search with LLM generation. It grounds answers in facts."),
]
indexing.run({"cleaner": {"documents": raw_docs}})
print(f"Indexed {store.count_documents()} documents")
```

### 5.2 RAG Query Pipeline

```python
import subprocess
from haystack import Pipeline
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.embedders import OpenAITextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

# Reuse store from indexing pipeline above (store must have embedded docs)
store = InMemoryDocumentStore()  # placeholder; inject your populated store

PROMPT_TEMPLATE = """
Answer the question based only on the provided context.
If unsure, say "I don't know."

Context:
{% for doc in documents %}
  - {{ doc.content }}
{% endfor %}

Question: {{ question }}
Answer:
"""

rag = Pipeline()
rag.add_component("embedder",   OpenAITextEmbedder(
    model="text-embedding-3-small",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
))
rag.add_component("retriever",  InMemoryEmbeddingRetriever(document_store=store, top_k=3))
rag.add_component("prompt",     PromptBuilder(template=PROMPT_TEMPLATE))
rag.add_component("generator",  OpenAIGenerator(
    model="gpt-4o-mini",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
))

rag.connect("embedder.embedding",    "retriever.query_embedding")
rag.connect("retriever.documents",   "prompt.documents")
rag.connect("prompt.prompt",         "generator.prompt")

question = "What is Haystack and who made it?"
result = rag.run({
    "embedder":  {"text": question},
    "prompt":    {"question": question},
})
print(result["generator"]["replies"][0])
```

---

## 6. Document Stores

### 6.1 InMemoryDocumentStore (dev/testing)

```python
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack import Document
import json, pathlib

store = InMemoryDocumentStore(embedding_similarity_function="cosine")

# Write documents
store.write_documents([
    Document(content="Alpha document", meta={"tag": "a"}),
    Document(content="Beta document",  meta={"tag": "b"}),
])

# Filter retrieval
results = store.filter_documents(filters={"field": "meta.tag", "operator": "==", "value": "a"})
print([r.content for r in results])

# Persist to disk (manual serialization)
data = [{"id": d.id, "content": d.content, "meta": d.meta} for d in store.filter_documents()]
pathlib.Path("store_backup.json").write_text(json.dumps(data, indent=2))
print("Saved", len(data), "docs to store_backup.json")

# Reload
loaded = json.loads(pathlib.Path("store_backup.json").read_text())
restored_docs = [Document(**d) for d in loaded]
store2 = InMemoryDocumentStore()
store2.write_documents(restored_docs)
print("Restored", store2.count_documents(), "docs")
```

### 6.2 Elasticsearch (production)

```python
# pip install elasticsearch-haystack
# Requires running Elasticsearch instance
from haystack_integrations.document_stores.elasticsearch import ElasticsearchDocumentStore

es_store = ElasticsearchDocumentStore(
    hosts="http://localhost:9200",
    index="my-haystack-index",
    embedding_dim=1536,            # match your embedder output
    similarity="cosine",
)
print(es_store.count_documents())
```

### 6.3 Qdrant (free self-hosted, production)

```python
# pip install qdrant-haystack
# docker run -p 6333:6333 qdrant/qdrant
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore

qdrant_store = QdrantDocumentStore(
    url="http://localhost:6333",
    index="haystack_docs",
    embedding_dim=384,             # all-MiniLM-L6-v2 output dim
    recreate_index=False,
)
print(qdrant_store.count_documents())
```

### 6.4 Chroma (lightweight local vector store)

```python
# pip install chroma-haystack
from haystack_integrations.document_stores.chroma import ChromaDocumentStore

chroma_store = ChromaDocumentStore(
    collection_name="haystack_collection",
    persist_path="./chroma_db",   # persists to disk automatically
    embedding_function=None,      # managed externally by Haystack embedder
)
```

---

## 7. Hybrid Retrieval

Hybrid retrieval combines **BM25 (keyword)** and **embedding (semantic)** retrieval, merges results with `DocumentJoiner`, then reranks with `TransformersSimilarityRanker`.

```python
import subprocess
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import (
    InMemoryBM25Retriever,
    InMemoryEmbeddingRetriever,
)
from haystack.components.joiners import DocumentJoiner
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.components.embedders import (
    OpenAIDocumentEmbedder,
    OpenAITextEmbedder,
)

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

# ── 1. Build and populate store ───────────────────────────────────────────────
store = InMemoryDocumentStore()
raw_docs = [
    Document(content="Haystack is built by deepset for production NLP."),
    Document(content="RAG grounds language model outputs in retrieved facts."),
    Document(content="BM25 is a classic keyword-based ranking function."),
    Document(content="Dense embeddings capture semantic similarity."),
    Document(content="Hybrid search combines BM25 and dense retrieval."),
]

embed_pipe = Pipeline()
embed_pipe.add_component("embedder", OpenAIDocumentEmbedder(
    model="text-embedding-3-small", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))
embed_pipe.add_component("writer",
    __import__("haystack.components.writers", fromlist=["DocumentWriter"]).DocumentWriter(
        document_store=store))
embed_pipe.connect("embedder.documents", "writer.documents")
embed_pipe.run({"embedder": {"documents": raw_docs}})

# ── 2. Hybrid query pipeline ──────────────────────────────────────────────────
hybrid = Pipeline()
hybrid.add_component("text_embedder", OpenAITextEmbedder(
    model="text-embedding-3-small", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))
hybrid.add_component("bm25",     InMemoryBM25Retriever(document_store=store, top_k=5))
hybrid.add_component("dense",    InMemoryEmbeddingRetriever(document_store=store, top_k=5))
hybrid.add_component("joiner",   DocumentJoiner(join_mode="reciprocal_rank_fusion"))
hybrid.add_component("ranker",   TransformersSimilarityRanker(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2", top_k=3))

# Connections
hybrid.connect("text_embedder.embedding", "dense.query_embedding")
hybrid.connect("bm25.documents",          "joiner.documents")
hybrid.connect("dense.documents",         "joiner.documents")
hybrid.connect("joiner.documents",        "ranker.documents")

query = "How does hybrid search work?"
result = hybrid.run({
    "text_embedder": {"text": query},
    "bm25":          {"query": query},
    "ranker":        {"query": query},
})

print(f"\nTop results for: '{query}'")
for doc in result["ranker"]["documents"]:
    print(f"  [{doc.score:.4f}] {doc.content}")
```

---

## 8. Evaluation

### 8.1 Built-in Evaluators

```python
import subprocess
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.evaluators import (
    FaithfulnessEvaluator,
    ContextRelevanceEvaluator,
    DocumentMAPEvaluator,
    SASEvaluator,
)
from haystack.components.generators.chat import OpenAIChatGenerator

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

llm = OpenAIChatGenerator(
    model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"
)

# ── Faithfulness: is the answer grounded in the contexts? ────────────────────
faithfulness = FaithfulnessEvaluator(llm=llm)
faith_result = faithfulness.run(
    questions=["What is Haystack?"],
    contexts=[["Haystack is an NLP framework by deepset."]],
    responses=["Haystack is a framework by deepset for building NLP pipelines."],
)
print("Faithfulness score:", faith_result["score"])  # 0.0 – 1.0

# ── Context Relevance: are retrieved docs relevant to the question? ──────────
ctx_rel = ContextRelevanceEvaluator(llm=llm)
ctx_result = ctx_rel.run(
    questions=["What is RAG?"],
    contexts=[["RAG stands for Retrieval-Augmented Generation.",
               "Paris is the capital of France."]],
)
print("Context relevance:", ctx_result["score"])

# ── SAS (Semantic Answer Similarity) — fully local, no LLM needed ────────────
sas = SASEvaluator(model="cross-encoder/stsb-roberta-base")
sas.warm_up()
sas_result = sas.run(
    predicted_answers=["Haystack is an NLP framework."],
    ground_truth_answers=["Haystack is a framework for NLP pipelines."],
)
print("SAS score:", sas_result["score"])  # semantic similarity 0–1
```

### 8.2 Evaluation Run Result

```python
from haystack.evaluation import EvaluationRunResult

# Aggregate multiple metric results
result = EvaluationRunResult(
    run_name="rag-eval-v1",
    inputs={
        "questions": ["What is Haystack?", "Who made Haystack?"],
        "contexts":  [["Haystack is by deepset."], ["deepset built Haystack."]],
        "responses": ["Haystack is a framework.", "deepset made it."],
    },
    results={
        "faithfulness":       {"score": 0.95, "individual_scores": [1.0, 0.9]},
        "context_relevance":  {"score": 0.88, "individual_scores": [0.9, 0.86]},
        "sas":                {"score": 0.91, "individual_scores": [0.93, 0.89]},
    },
)

print(result.score_report())
df = result.to_pandas()
print(df)
```

---

## 9. Custom Components

### 9.1 Minimal Custom Component

```python
from haystack import component, Document
from typing import List

@component
class KeywordFilter:
    """Filters documents that contain a specific keyword."""

    def __init__(self, keyword: str):
        self.keyword = keyword.lower()

    @component.output_types(documents=List[Document], filtered_count=int)
    def run(self, documents: List[Document]) -> dict:
        kept = [d for d in documents if self.keyword in (d.content or "").lower()]
        return {"documents": kept, "filtered_count": len(documents) - len(kept)}

# Test standalone
filt = KeywordFilter(keyword="haystack")
docs = [
    Document(content="Haystack is great for RAG."),
    Document(content="LangChain is another option."),
    Document(content="deepset built Haystack."),
]
out = filt.run(documents=docs)
print(f"Kept: {len(out['documents'])}, Filtered: {out['filtered_count']}")
```

### 9.2 Custom Web Scraper Component

```python
from haystack import component, Document
from typing import List, Optional
import urllib.request, html, re

@component
class SimpleWebScraper:
    """
    Fetches one or more URLs and returns them as Haystack Documents.
    No external dependencies — uses stdlib urllib only.
    """

    def __init__(self, timeout: int = 10):
        self.timeout = timeout

    @component.output_types(documents=List[Document])
    def run(self, urls: List[str]) -> dict:
        documents = []
        for url in urls:
            try:
                with urllib.request.urlopen(url, timeout=self.timeout) as resp:
                    raw_html = resp.read().decode("utf-8", errors="ignore")
                # Strip HTML tags
                text = re.sub(r"<[^>]+>", " ", raw_html)
                text = html.unescape(text)
                text = re.sub(r"\s+", " ", text).strip()
                documents.append(Document(
                    content=text[:5000],   # cap at 5k chars
                    meta={"url": url, "status": "ok"},
                ))
            except Exception as exc:
                documents.append(Document(
                    content="",
                    meta={"url": url, "status": "error", "error": str(exc)},
                ))
        return {"documents": documents}

# Test
scraper = SimpleWebScraper(timeout=8)
result = scraper.run(urls=["https://example.com"])
for doc in result["documents"]:
    print(f"[{doc.meta['status']}] {doc.meta['url']}: {doc.content[:100]}")
```

### 9.3 Streaming Component

```python
import subprocess
from haystack import component
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.dataclasses import ChatMessage, StreamingChunk
from typing import Callable, Optional, List

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

@component
class StreamingChatResponder:
    """Wraps OpenAIChatGenerator with a streaming callback."""

    def __init__(self, model: str = "gpt-4o-mini"):
        self.generator = OpenAIChatGenerator(
            model=model,
            api_key=token,
            api_base_url="https://models.inference.ai.azure.com",
            streaming_callback=self._print_chunk,
        )
        self._chunks: List[str] = []

    def _print_chunk(self, chunk: StreamingChunk) -> None:
        print(chunk.content, end="", flush=True)
        self._chunks.append(chunk.content)

    @component.output_types(full_response=str)
    def run(self, messages: List[ChatMessage]) -> dict:
        self._chunks = []
        self.generator.run(messages=messages)
        print()  # newline after stream
        return {"full_response": "".join(self._chunks)}

# Use it
responder = StreamingChatResponder()
msgs = [ChatMessage.from_user("Count from 1 to 5, one number per token.")]
out = responder.run(messages=msgs)
print("\nFull:", out["full_response"])
```

---

## 10. Haystack Agent (2.x)

```python
import subprocess, json
from haystack import Pipeline, component
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.dataclasses import ChatMessage, ToolCall
from haystack.tools import Tool
from typing import List

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

# ── Define tools ──────────────────────────────────────────────────────────────
def get_weather(city: str) -> str:
    """Returns mock weather for a city."""
    mock = {"London": "12°C, cloudy", "Paris": "18°C, sunny", "Tokyo": "22°C, clear"}
    return mock.get(city, f"No data for {city}")

def calculate(expression: str) -> str:
    """Evaluates a safe math expression."""
    try:
        allowed = set("0123456789+-*/(). ")
        if not all(c in allowed for c in expression):
            return "Error: unsafe expression"
        return str(eval(expression))  # noqa: S307 — demo only
    except Exception as e:
        return f"Error: {e}"

weather_tool = Tool(
    name="get_weather",
    description="Get current weather for a city. Input: city name (string).",
    parameters={"type": "object", "properties": {"city": {"type": "string"}}, "required": ["city"]},
    function=get_weather,
)

calc_tool = Tool(
    name="calculate",
    description="Evaluate a mathematical expression. Input: expression string.",
    parameters={"type": "object", "properties": {"expression": {"type": "string"}}, "required": ["expression"]},
    function=calculate,
)

# ── ReAct-style agent loop ────────────────────────────────────────────────────
from haystack.components.routers import MetadataRouter

llm = OpenAIChatGenerator(
    model="gpt-4o-mini",
    api_key=token,
    api_base_url="https://models.inference.ai.azure.com",
    tools=[weather_tool, calc_tool],
)

def run_agent(user_query: str, max_steps: int = 5) -> str:
    messages: List[ChatMessage] = [
        ChatMessage.from_system("You are a helpful assistant. Use tools when needed."),
        ChatMessage.from_user(user_query),
    ]
    for step in range(max_steps):
        result = llm.run(messages=messages)
        reply = result["replies"][0]
        messages.append(reply)

        # No tool calls → final answer
        if not reply.tool_calls:
            return reply.text

        # Execute tool calls
        for tc in reply.tool_calls:
            tool_map = {"get_weather": get_weather, "calculate": calculate}
            fn = tool_map.get(tc.tool_name)
            if fn:
                args = json.loads(tc.arguments) if isinstance(tc.arguments, str) else tc.arguments
                tool_output = fn(**args)
                messages.append(ChatMessage.from_tool(
                    tool_result=tool_output,
                    origin=tc,
                ))
    return "Max steps reached."

answer = run_agent("What is the weather in Paris and what is 17 * 23?")
print(answer)
```

---

## 11. Serialization & Deployment

### 11.1 YAML Serialization

```python
from haystack import Pipeline
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
import pathlib

pipe = Pipeline()
pipe.add_component("prompt", PromptBuilder(template="Answer: {{ question }}"))
pipe.add_component("llm",   OpenAIGenerator(model="gpt-4o-mini"))
pipe.connect("prompt.prompt", "llm.prompt")

# Save to YAML
yaml_str = pipe.dumps()                          # YAML string
pathlib.Path("my_pipeline.yaml").write_text(yaml_str)
print("Saved pipeline.yaml")
print(yaml_str[:300])

# Reload from YAML
loaded_pipe = Pipeline.loads(yaml_str)
# or: loaded_pipe = Pipeline.load(open("my_pipeline.yaml"))
print("Reloaded pipeline:", type(loaded_pipe))
```

### 11.2 FastAPI Deployment

```python
# save as app.py → uvicorn app:app
import subprocess
from fastapi import FastAPI
from pydantic import BaseModel
from haystack import Pipeline
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator

app = FastAPI(title="Haystack RAG API")

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

pipe = Pipeline()
pipe.add_component("prompt", PromptBuilder(template="Answer briefly: {{ question }}"))
pipe.add_component("llm",   OpenAIGenerator(
    model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))
pipe.connect("prompt.prompt", "llm.prompt")

class QueryRequest(BaseModel):
    question: str

class QueryResponse(BaseModel):
    answer: str

@app.post("/query", response_model=QueryResponse)
async def query(req: QueryRequest):
    result = pipe.run({"prompt": {"question": req.question}})
    return QueryResponse(answer=result["llm"]["replies"][0])

@app.get("/health")
async def health():
    return {"status": "ok"}

# Run: uvicorn app:app --host 0.0.0.0 --port 8000
```

### 11.3 Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY my_pipeline.yaml .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

```text
# requirements.txt
haystack-ai==2.9.0
fastapi==0.115.0
uvicorn==0.30.0
```

### 11.4 deepset Cloud

```python
# pip install deepset-cloud-sdk
# Set env: DEEPSET_CLOUD_API_KEY, DEEPSET_CLOUD_WORKSPACE

from haystack import Pipeline
# After designing your pipeline locally:
# 1. pipeline.to_yaml("my_pipeline.yaml")
# 2. Upload via deepset Cloud SDK or web UI
# 3. Deploy with one click — handles scaling, monitoring, versioning

# Query deployed pipeline via REST:
import requests, os
resp = requests.post(
    "https://api.cloud.deepset.ai/api/v1/workspaces/MY_WORKSPACE/pipelines/MY_PIPELINE/search",
    headers={"Authorization": f"Bearer {os.environ['DEEPSET_CLOUD_API_KEY']}"},
    json={"queries": ["What is Haystack?"]},
)
print(resp.json())
```

---

## 12. Real-World Patterns

### 12.1 Multi-Hop QA Pipeline

```python
import subprocess
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
store = InMemoryDocumentStore()
store.write_documents([
    Document(content="Alice is the CEO of Acme Corp. Acme Corp was founded in 2010."),
    Document(content="Acme Corp is headquartered in San Francisco, California."),
    Document(content="San Francisco is known for its Golden Gate Bridge and tech industry."),
])

HOP1_TEMPLATE = "Extract the main entity from this question for a follow-up search.\nQuestion: {{ question }}\nEntity:"
HOP2_TEMPLATE = """Using these documents, answer the original question.
Documents: {% for d in documents %}{{ d.content }} {% endfor %}
Original question: {{ question }}
Answer:"""

pipe = Pipeline()
pipe.add_component("hop1_prompt", PromptBuilder(template=HOP1_TEMPLATE))
pipe.add_component("hop1_llm",    OpenAIGenerator(model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))
pipe.add_component("retriever",   InMemoryBM25Retriever(document_store=store, top_k=3))
pipe.add_component("hop2_prompt", PromptBuilder(template=HOP2_TEMPLATE))
pipe.add_component("hop2_llm",    OpenAIGenerator(model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))

pipe.connect("hop1_prompt.prompt",   "hop1_llm.prompt")
pipe.connect("hop1_llm.replies",     "retriever.query")   # first reply used as query
pipe.connect("retriever.documents",  "hop2_prompt.documents")
pipe.connect("hop2_prompt.prompt",   "hop2_llm.prompt")

question = "Where is the headquarters of the company whose CEO is Alice?"
result = pipe.run({"hop1_prompt": {"question": question}, "hop2_prompt": {"question": question}})
print(result["hop2_llm"]["replies"][0])
```

### 12.2 Fallback Pipeline (Router)

```python
import subprocess
from haystack import Pipeline, Document, component
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from typing import List

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

@component
class FallbackRouter:
    """Routes to 'rag' branch if docs found, else 'fallback' branch."""
    @component.output_types(rag_documents=List[Document], fallback_query=str)
    def run(self, documents: List[Document], query: str) -> dict:
        if documents:
            return {"rag_documents": documents, "fallback_query": None}
        return {"rag_documents": None, "fallback_query": query}

store = InMemoryDocumentStore()
store.write_documents([Document(content="Haystack is an NLP framework by deepset.")])

FALLBACK_TEMPLATE = "Answer from general knowledge (no context available): {{ query }}"
RAG_TEMPLATE = """Context: {% for d in documents %}{{ d.content }} {% endfor %}
Question: {{ question }}  Answer:"""

pipe = Pipeline()
pipe.add_component("retriever", InMemoryBM25Retriever(document_store=store, top_k=3))
pipe.add_component("router",    FallbackRouter())
pipe.add_component("rag_prompt",      PromptBuilder(template=RAG_TEMPLATE))
pipe.add_component("fallback_prompt", PromptBuilder(template=FALLBACK_TEMPLATE))
pipe.add_component("rag_llm",         OpenAIGenerator(model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))
pipe.add_component("fallback_llm",    OpenAIGenerator(model="gpt-4o-mini", api_key=token,
    api_base_url="https://models.inference.ai.azure.com"))

pipe.connect("retriever.documents",          "router.documents")
pipe.connect("router.rag_documents",         "rag_prompt.documents")
pipe.connect("router.fallback_query",        "fallback_prompt.query")
pipe.connect("rag_prompt.prompt",            "rag_llm.prompt")
pipe.connect("fallback_prompt.prompt",       "fallback_llm.prompt")

q = "What is Haystack?"
res = pipe.run({"retriever": {"query": q}, "router": {"query": q}, "rag_prompt": {"question": q}})
rag_out      = res.get("rag_llm", {}).get("replies", [None])[0]
fallback_out = res.get("fallback_llm", {}).get("replies", [None])[0]
print("Answer:", rag_out or fallback_out)
```

---

## 13. Interview Q&A (15 Questions)

---

**Q1: What is the key architectural difference between Haystack 1.x and 2.x?**

> **A:** Haystack 1.x used a loosely typed node graph where each node had its own arbitrary API. Haystack 2.x introduces a strict **component contract**: every component declares typed `InputSocket`/`OutputSocket` pairs and implements `run(**kwargs) -> dict`. This enables full YAML serialization, type checking at pipeline build time, and support for arbitrary DAGs including loops.

---

**Q2: How do you connect two components in a Haystack pipeline?**

> **A:** Use `pipeline.connect("component_a.output_name", "component_b.input_name")`. For example: `pipe.connect("embedder.embedding", "retriever.query_embedding")`. The dot notation specifies the component name and the exact socket name declared in `@component.output_types`.

---

**Q3: What is a DocumentStore and which ones are available?**

> **A:** A `DocumentStore` is the persistence layer for `Document` objects — it handles write, filter, and retrieval operations. Available stores include:
> - `InMemoryDocumentStore` — dev/testing, no dependencies
> - `ElasticsearchDocumentStore` — BM25 + kNN, production
> - `OpenSearchDocumentStore` — AWS-managed option
> - `QdrantDocumentStore` — vector-native, self-hosted or cloud
> - `WeaviateDocumentStore` — vector + BM25 hybrid
> - `ChromaDocumentStore` — lightweight local vector store
> - `PgvectorDocumentStore` — PostgreSQL + pgvector

---

**Q4: How do you implement hybrid retrieval in Haystack?**

> **A:** Run both `InMemoryBM25Retriever` and `InMemoryEmbeddingRetriever` in parallel within a single pipeline. Connect both to a `DocumentJoiner` component (using `join_mode="reciprocal_rank_fusion"` or `"concatenate"`). Optionally follow with `TransformersSimilarityRanker` for cross-encoder reranking. Both retrievers share the same `DocumentStore`.

---

**Q5: What is the DocumentJoiner component?**

> **A:** `DocumentJoiner` merges `List[Document]` from multiple upstream retrievers into a single deduplicated list. It supports three join modes:
> - `"concatenate"` — simple union, keeps order
> - `"merge"` — averages scores across retrievers
> - `"reciprocal_rank_fusion"` — RRF formula, robust to score scale differences (recommended for hybrid retrieval)

---

**Q6: How does Haystack handle evaluation built-in?**

> **A:** Haystack 2.x ships `FaithfulnessEvaluator`, `ContextRelevanceEvaluator`, `DocumentMAPEvaluator`, `SASEvaluator` (local), and `RAGASEvaluator` as first-class components. They plug directly into evaluation pipelines. Results are collected in `EvaluationRunResult`, which provides `.score_report()` and `.to_pandas()` for analysis.

---

**Q7: How do you create a custom component in Haystack 2.x?**

> **A:** Decorate a class with `@component` and implement a `run()` method decorated with `@component.output_types(key=Type, ...)`. The `run()` method's parameters become input sockets; `output_types` declares output sockets. The method must return a `dict` whose keys match the declared output types.

---

**Q8: What is TransformersSimilarityRanker and why use it?**

> **A:** `TransformersSimilarityRanker` is a **cross-encoder** reranker. Unlike bi-encoders (which embed query and doc separately), a cross-encoder sees the query and document together, enabling much finer relevance scoring. It is used *after* an initial cheap retrieval (BM25 or embedding) to rerank the top-k results with higher accuracy. It runs locally with no API cost.

---

**Q9: How do you serialize and reload a Haystack pipeline?**

> **A:**
> ```python
> # Save
> yaml_str = pipeline.dumps()
> # Reload
> pipeline = Pipeline.loads(yaml_str)
> ```
> All standard components serialize their constructor arguments to YAML automatically. Custom components must also be importable at load time.

---

**Q10: How does Haystack compare to LangChain for production RAG?**

> **A:**
> | Aspect | Haystack | LangChain |
> |--------|----------|-----------|
> | Architecture | Strict typed DAG | Flexible chains/graphs |
> | Serialization | Full YAML round-trip | Partial |
> | Evaluation | First-class built-in | Via LangSmith (external) |
> | Production ops | deepset Cloud + Docker | LangServe |
> | Learning curve | Steeper, more structured | Gentler |
> 
> Haystack is preferred when **evaluation**, **reproducibility**, and **production deployment** are priorities.

---

**Q11: How do you implement streaming responses in Haystack?**

> **A:** Pass a `streaming_callback: Callable[[StreamingChunk], None]` to `OpenAIChatGenerator` or `OpenAIGenerator`. Each token is delivered to the callback as it arrives. The component's `run()` still returns the full assembled response when streaming completes.

---

**Q12: What is the ToolInvoker component?**

> **A:** `ToolInvoker` is a built-in component that inspects `ChatMessage` objects for `ToolCall` objects, executes the referenced `Tool` functions, and returns `ChatMessage.from_tool(...)` result messages. It enables LLM tool-use (function calling) within a declarative pipeline without manual dispatch logic.

---

**Q13: How do you use Haystack with fully local models?**

> **A:**
> - **Embeddings:** `SentenceTransformersDocumentEmbedder` / `SentenceTransformersTextEmbedder` (HuggingFace models, no API)
> - **Generation:** `HuggingFaceLocalGenerator` with any causal LM (e.g., `mistralai/Mistral-7B-Instruct-v0.1`)
> - **Reranking:** `TransformersSimilarityRanker` (cross-encoder, runs locally)
> - **Store:** `InMemoryDocumentStore` or `QdrantDocumentStore` (self-hosted)
> 
> All can be combined for a fully air-gapped, zero-API-cost pipeline.

---

**Q14: What is deepset Cloud?**

> **A:** deepset Cloud is a managed platform for deploying, versioning, and monitoring Haystack pipelines. It provides a REST API, web UI for pipeline management, A/B testing, analytics dashboards, and enterprise-grade security. Pipelines created locally can be uploaded via `deepset-cloud-sdk` and deployed with one click.

---

**Q15: How do you handle multi-lingual documents in Haystack?**

> **A:**
> 1. **Detection:** Use a custom component wrapping `langdetect` or `lingua` to detect language and store it in `doc.meta["language"]`.
> 2. **Routing:** Use `MetadataRouter` to route documents to language-specific processing branches.
> 3. **Multilingual embeddings:** Use `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` which supports 50+ languages natively.
> 4. **Translation fallback:** Add an `OpenAIChatGenerator`-based translator component before embedding if needed.

---

## 14. Complete End-to-End Example

Production RAG: ingest docs → hybrid retrieval → reranking → answer → auto-evaluate

```python
"""
production_rag.py
─────────────────────────────────────────────────────────────────────────────
End-to-end Haystack 2.x production RAG pipeline with evaluation.
Covers: indexing, hybrid retrieval, cross-encoder reranking, generation,
        faithfulness + SAS evaluation — ~100 lines.
─────────────────────────────────────────────────────────────────────────────
"""
import subprocess
from haystack import Document, Pipeline
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.preprocessors import DocumentCleaner, DocumentSplitter
from haystack.components.embedders import (
    OpenAIDocumentEmbedder, OpenAITextEmbedder,
)
from haystack.components.writers import DocumentWriter
from haystack.components.retrievers.in_memory import (
    InMemoryBM25Retriever, InMemoryEmbeddingRetriever,
)
from haystack.components.joiners import DocumentJoiner
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.components.evaluators import FaithfulnessEvaluator, SASEvaluator

# ── Auth ──────────────────────────────────────────────────────────────────────
TOKEN = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
BASE  = "https://models.inference.ai.azure.com"
MODEL = "gpt-4o-mini"

def make_gen(**kw):
    return OpenAIGenerator(model=MODEL, api_key=TOKEN, api_base_url=BASE, **kw)

def make_chat_gen(**kw):
    return OpenAIChatGenerator(model=MODEL, api_key=TOKEN, api_base_url=BASE, **kw)

# ── Corpus ────────────────────────────────────────────────────────────────────
CORPUS = [
    Document(content="Haystack is an open-source NLP framework by deepset. "
             "It supports RAG, document search, and agentic systems."),
    Document(content="Retrieval-Augmented Generation (RAG) combines a retriever "
             "with a language model to ground answers in retrieved evidence."),
    Document(content="Hybrid retrieval merges BM25 keyword search with dense "
             "embedding search, then reranks using a cross-encoder model."),
    Document(content="deepset Cloud is a managed platform for deploying Haystack "
             "pipelines with REST APIs, monitoring, and A/B testing."),
    Document(content="TransformersSimilarityRanker uses a cross-encoder to rerank "
             "retrieved documents, improving answer quality significantly."),
]

# ── 1. Indexing Pipeline ──────────────────────────────────────────────────────
store = InMemoryDocumentStore()

idx = Pipeline()
idx.add_component("cleaner",  DocumentCleaner())
idx.add_component("splitter", DocumentSplitter(split_by="sentence", split_length=2, split_overlap=0))
idx.add_component("embedder", OpenAIDocumentEmbedder(
    model="text-embedding-3-small", api_key=TOKEN, api_base_url=BASE))
idx.add_component("writer",   DocumentWriter(document_store=store))
idx.connect("cleaner.documents",  "splitter.documents")
idx.connect("splitter.documents", "embedder.documents")
idx.connect("embedder.documents", "writer.documents")
idx.run({"cleaner": {"documents": CORPUS}})
print(f"[Indexing] Stored {store.count_documents()} chunks\n")

# ── 2. Hybrid RAG Query Pipeline ──────────────────────────────────────────────
TEMPLATE = """Answer the question using ONLY the provided context. Be concise.

Context:
{% for doc in documents %}
  • {{ doc.content }}
{% endfor %}

Question: {{ question }}
Answer:"""

rag = Pipeline()
rag.add_component("text_embedder", OpenAITextEmbedder(
    model="text-embedding-3-small", api_key=TOKEN, api_base_url=BASE))
rag.add_component("bm25",     InMemoryBM25Retriever(document_store=store, top_k=5))
rag.add_component("dense",    InMemoryEmbeddingRetriever(document_store=store, top_k=5))
rag.add_component("joiner",   DocumentJoiner(join_mode="reciprocal_rank_fusion"))
rag.add_component("ranker",   TransformersSimilarityRanker(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2", top_k=3))
rag.add_component("prompt",   PromptBuilder(template=TEMPLATE))
rag.add_component("llm",      make_gen())

rag.connect("text_embedder.embedding", "dense.query_embedding")
rag.connect("bm25.documents",          "joiner.documents")
rag.connect("dense.documents",         "joiner.documents")
rag.connect("joiner.documents",        "ranker.documents")
rag.connect("ranker.documents",        "prompt.documents")
rag.connect("prompt.prompt",           "llm.prompt")

# ── 3. Run Q&A ────────────────────────────────────────────────────────────────
test_pairs = [
    ("What is Haystack and who built it?",
     "Haystack is an NLP framework built by deepset."),
    ("What is hybrid retrieval?",
     "Hybrid retrieval combines BM25 and dense embedding search."),
    ("What is deepset Cloud used for?",
     "deepset Cloud is used for deploying Haystack pipelines."),
]

questions, ground_truths, answers, contexts = [], [], [], []

for q, gt in test_pairs:
    res = rag.run({
        "text_embedder": {"text": q},
        "bm25":          {"query": q},
        "ranker":        {"query": q},
        "prompt":        {"question": q},
    })
    answer = res["llm"]["replies"][0]
    docs   = res["ranker"]["documents"]
    questions.append(q)
    ground_truths.append(gt)
    answers.append(answer)
    contexts.append([d.content for d in docs])
    print(f"Q: {q}\nA: {answer}\n")

# ── 4. Evaluation ─────────────────────────────────────────────────────────────
print("=" * 60)
print("EVALUATION")
print("=" * 60)

# Faithfulness (LLM-based)
faithfulness = FaithfulnessEvaluator(llm=make_chat_gen())
f_result = faithfulness.run(
    questions=questions, contexts=contexts, responses=answers)
print(f"Faithfulness score : {f_result['score']:.3f}")

# SAS (local, no API cost)
sas = SASEvaluator(model="cross-encoder/stsb-roberta-base")
sas.warm_up()
sas_result = sas.run(predicted_answers=answers, ground_truth_answers=ground_truths)
print(f"SAS score          : {sas_result['score']:.3f}")

# Per-question breakdown
print("\nPer-question SAS scores:")
for q, score in zip(questions, sas_result["individual_scores"]):
    print(f"  [{score:.3f}] {q[:60]}")

# ── 5. Serialize pipeline ─────────────────────────────────────────────────────
yaml_path = "production_rag_pipeline.yaml"
with open(yaml_path, "w") as f:
    rag.dump(f)
print(f"\nPipeline serialized → {yaml_path}")

# Reload proof
reloaded = Pipeline.load(open(yaml_path))
print(f"Reloaded pipeline components: {list(reloaded.graph.nodes)}")
```

---

## Quick Reference Cheat Sheet

```python
# Install
# pip install haystack-ai sentence-transformers

# Core imports
from haystack import Pipeline, Document, component
from haystack.document_stores.in_memory import InMemoryDocumentStore

# Indexing pipeline skeleton
store = InMemoryDocumentStore()
idx = Pipeline()
idx.add_component("cleaner",  DocumentCleaner())
idx.add_component("splitter", DocumentSplitter(split_by="word", split_length=150))
idx.add_component("embedder", SentenceTransformersDocumentEmbedder("all-MiniLM-L6-v2"))
idx.add_component("writer",   DocumentWriter(document_store=store))
idx.connect("cleaner.documents",  "splitter.documents")
idx.connect("splitter.documents", "embedder.documents")
idx.connect("embedder.documents", "writer.documents")

# Query pipeline skeleton
rag = Pipeline()
rag.add_component("embedder",  SentenceTransformersTextEmbedder("all-MiniLM-L6-v2"))
rag.add_component("retriever", InMemoryEmbeddingRetriever(document_store=store, top_k=3))
rag.add_component("prompt",    PromptBuilder(template="Context: {% for d in documents %}{{d.content}}{% endfor %}\nQ: {{question}}\nA:"))
rag.add_component("llm",       HuggingFaceLocalGenerator("google/flan-t5-base"))
rag.connect("embedder.embedding",  "retriever.query_embedding")
rag.connect("retriever.documents", "prompt.documents")
rag.connect("prompt.prompt",       "llm.prompt")

# Serialize / reload
yaml_str = rag.dumps()
rag2 = Pipeline.loads(yaml_str)
```

---

*Guide generated for the EngX AI Coach curriculum — Haystack 2.x (deepset)*
