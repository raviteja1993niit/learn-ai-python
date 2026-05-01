# Haystack 2.0 — Hands-On Projects

This file contains 8 practical projects you can build with Haystack 2.0.
Each project includes an overview, setup steps, key components, a code skeleton,
and an expected outcome.

---

## Project 1: PDF Knowledge Base with Haystack (RAG over PDFs)

### Overview
Build a system that ingests a collection of PDF documents, indexes them with vector
embeddings, and allows natural-language question answering over the content.
This is the canonical RAG use case: upload PDFs once, query forever.

### Setup Steps
1. `pip install haystack-ai pypdf sentence-transformers openai`
2. Place your PDF files in a `./docs/` directory.
3. Set `OPENAI_API_KEY` in your environment.
4. Run the indexing pipeline once to populate the store.
5. Run the query pipeline interactively.

### Key Components
- `PyPDFToDocument` — convert PDFs to Documents
- `DocumentSplitter` — chunk by sentence, length=5, overlap=1
- `SentenceTransformersDocumentEmbedder` — embed chunks
- `InMemoryDocumentStore` — store embeddings (swap for Chroma in production)
- `InMemoryEmbeddingRetriever` — top_k=5 vector search
- `PromptBuilder` — Jinja2 RAG prompt
- `OpenAIGenerator` — GPT-3.5-turbo answer generation

### Sample Code Skeleton
```python
import glob
from haystack import Pipeline
from haystack.components.converters import PyPDFToDocument
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.embedders import (
    SentenceTransformersDocumentEmbedder,
    SentenceTransformersTextEmbedder,
)
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()

# --- Indexing ---
idx = Pipeline()
idx.add_component("converter", PyPDFToDocument())
idx.add_component("splitter",  DocumentSplitter(split_by="sentence", split_length=5, split_overlap=1))
idx.add_component("embedder",  SentenceTransformersDocumentEmbedder())
idx.add_component("writer",    DocumentWriter(document_store=store))
idx.connect("converter.documents", "splitter.documents")
idx.connect("splitter.documents",  "embedder.documents")
idx.connect("embedder.documents",  "writer.documents")
idx.run({"converter": {"sources": glob.glob("./docs/*.pdf")}})

# --- Query ---
TEMPLATE = """
{% for doc in documents %}{{ doc.content }}{% endfor %}
Question: {{ query }}
Answer:
"""
qry = Pipeline()
qry.add_component("embedder",   SentenceTransformersTextEmbedder())
qry.add_component("retriever",  InMemoryEmbeddingRetriever(document_store=store, top_k=5))
qry.add_component("builder",    PromptBuilder(template=TEMPLATE))
qry.add_component("generator",  OpenAIGenerator(model="gpt-3.5-turbo"))
qry.connect("embedder.embedding",  "retriever.query_embedding")
qry.connect("retriever.documents", "builder.documents")
qry.connect("builder.prompt",      "generator.prompt")

answer = qry.run({"embedder": {"text": "What are the main findings?"}, "builder": {"query": "What are the main findings?"}})
print(answer["generator"]["replies"][0])
```

### Expected Outcome
A CLI tool that accepts natural-language questions and returns answers grounded in your
PDF library, with no hallucinations beyond what the retrieved chunks contain.

---

## Project 2: Web Scraping + Indexing Pipeline

### Overview
Scrape a list of URLs, convert the HTML to clean text, split and embed the content,
and persist it in a searchable document store. Useful for indexing documentation sites.

### Setup Steps
1. `pip install haystack-ai trafilatura requests`
2. Prepare a list of URLs to scrape.
3. Implement a custom `URLToDocument` component using `trafilatura`.

### Key Components
- Custom `URLScraper` component using `trafilatura.fetch_url` + `trafilatura.extract`
- `DocumentSplitter` — split_by="word", split_length=300
- `SentenceTransformersDocumentEmbedder`
- `InMemoryDocumentStore` or `ChromaDocumentStore`

### Sample Code Skeleton
```python
import trafilatura
from haystack import component, Pipeline
from haystack.dataclasses import Document
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.embedders import SentenceTransformersDocumentEmbedder
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore
from typing import List

@component
class URLScraper:
    @component.output_types(documents=List[Document])
    def run(self, urls: List[str]) -> dict:
        docs = []
        for url in urls:
            raw = trafilatura.fetch_url(url)
            text = trafilatura.extract(raw) or ""
            if text:
                docs.append(Document(content=text, meta={"url": url}))
        return {"documents": docs}

store = InMemoryDocumentStore()
pipe = Pipeline()
pipe.add_component("scraper",  URLScraper())
pipe.add_component("splitter", DocumentSplitter(split_by="word", split_length=300, split_overlap=30))
pipe.add_component("embedder", SentenceTransformersDocumentEmbedder())
pipe.add_component("writer",   DocumentWriter(document_store=store))
pipe.connect("scraper.documents",  "splitter.documents")
pipe.connect("splitter.documents", "embedder.documents")
pipe.connect("embedder.documents", "writer.documents")

pipe.run({"scraper": {"urls": ["https://docs.haystack.deepset.ai/docs/intro"]}})
print(f"Indexed {store.count_documents()} chunks from the web.")
```

### Expected Outcome
A searchable index of web pages that can be queried with the standard RAG query pipeline.

---

## Project 3: Multi-Format Document RAG (PDF + HTML + TXT)

### Overview
Build a single indexing pipeline that handles PDF, HTML, and plain-text files
simultaneously using Haystack's file-type routing.

### Setup Steps
1. `pip install haystack-ai pypdf beautifulsoup4 sentence-transformers`
2. Collect documents of all three formats.
3. Use a `FileTypeRouter` to dispatch files to the correct converter.

### Key Components
- `FileTypeRouter` — routes by MIME type to appropriate converter
- `PyPDFToDocument`, `HTMLToDocument`, `TextFileToDocument`
- `DocumentJoiner` — merges outputs from all converters
- `DocumentSplitter`, `SentenceTransformersDocumentEmbedder`, `DocumentWriter`

### Sample Code Skeleton
```python
from haystack import Pipeline
from haystack.components.routers import FileTypeRouter
from haystack.components.converters import PyPDFToDocument, HTMLToDocument, TextFileToDocument
from haystack.components.joiners import DocumentJoiner
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.embedders import SentenceTransformersDocumentEmbedder
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()
pipe = Pipeline()
pipe.add_component("router",    FileTypeRouter(mime_types=["application/pdf", "text/html", "text/plain"]))
pipe.add_component("pdf",       PyPDFToDocument())
pipe.add_component("html",      HTMLToDocument())
pipe.add_component("txt",       TextFileToDocument())
pipe.add_component("joiner",    DocumentJoiner())
pipe.add_component("splitter",  DocumentSplitter(split_by="word", split_length=200))
pipe.add_component("embedder",  SentenceTransformersDocumentEmbedder())
pipe.add_component("writer",    DocumentWriter(document_store=store))

pipe.connect("router.application/pdf",  "pdf.sources")
pipe.connect("router.text/html",        "html.sources")
pipe.connect("router.text/plain",       "txt.sources")
pipe.connect("pdf.documents",  "joiner.documents")
pipe.connect("html.documents", "joiner.documents")
pipe.connect("txt.documents",  "joiner.documents")
pipe.connect("joiner.documents",   "splitter.documents")
pipe.connect("splitter.documents", "embedder.documents")
pipe.connect("embedder.documents", "writer.documents")

pipe.run({"router": {"sources": ["report.pdf", "page.html", "notes.txt"]}})
```

### Expected Outcome
A unified index spanning all three file types, queryable with one RAG pipeline.

---

## Project 4: Custom Component Development

### Overview
Implement a production-grade custom component: a `KeywordFilter` that removes documents
containing specified banned keywords before they are stored or returned to the user.

### Setup Steps
1. `pip install haystack-ai`
2. Implement the component with `@component`.
3. Unit-test it in isolation before wiring into a pipeline.

### Key Components
- `@component` decorator
- `@component.output_types`
- `warm_up()` for any init-time resource loading

### Sample Code Skeleton
```python
from typing import List
from haystack import component
from haystack.dataclasses import Document

@component
class KeywordFilter:
    """Removes documents that contain any banned keyword (case-insensitive)."""

    def __init__(self, banned_keywords: List[str]):
        self.banned = [kw.lower() for kw in banned_keywords]

    @component.output_types(documents=List[Document], removed_count=int)
    def run(self, documents: List[Document]) -> dict:
        clean, removed = [], 0
        for doc in documents:
            lower = doc.content.lower()
            if any(kw in lower for kw in self.banned):
                removed += 1
            else:
                clean.append(doc)
        return {"documents": clean, "removed_count": removed}

# Test in isolation
f = KeywordFilter(banned_keywords=["confidential", "internal only"])
result = f.run(documents=[
    Document(content="This is a public document."),
    Document(content="CONFIDENTIAL: do not distribute."),
])
print(result["documents"])       # only the public document
print(result["removed_count"])   # 1
```

### Expected Outcome
A reusable, unit-tested component that integrates seamlessly into any indexing pipeline.

---

## Project 5: Pipeline Serialization and Versioning

### Overview
Implement a versioned pipeline registry: serialize pipelines to YAML files named by
version, load a specific version on demand, and compare pipeline structures.

### Setup Steps
1. `pip install haystack-ai pyyaml`
2. Build a reference pipeline.
3. Serialize with version tag in filename.
4. Demonstrate loading and running from YAML.

### Sample Code Skeleton
```python
from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore
import os

def save_pipeline(pipeline: Pipeline, name: str, version: str):
    os.makedirs("./pipelines", exist_ok=True)
    path = f"./pipelines/{name}_v{version}.yaml"
    with open(path, "w") as f:
        pipeline.dump(f)
    print(f"Saved: {path}")

def load_pipeline(name: str, version: str) -> Pipeline:
    path = f"./pipelines/{name}_v{version}.yaml"
    with open(path) as f:
        return Pipeline.load(f)

store = InMemoryDocumentStore()
p = Pipeline()
p.add_component("embedder",  SentenceTransformersTextEmbedder())
p.add_component("retriever", InMemoryEmbeddingRetriever(document_store=store))
p.connect("embedder.embedding", "retriever.query_embedding")

save_pipeline(p, "rag_query", "1.0")

loaded = load_pipeline("rag_query", "1.0")
print("Components:", list(loaded.graph.nodes))
```

### Expected Outcome
A `./pipelines/` directory with YAML files for each version, loadable without
re-implementing the pipeline in Python.

---

## Project 6: Evaluation Pipeline for RAG Quality

### Overview
Build an evaluation harness that scores a RAG pipeline on a test dataset of
(question, ground_truth_answer) pairs using multiple evaluators.

### Setup Steps
1. `pip install haystack-ai sentence-transformers`
2. Prepare a CSV of questions and ground-truth answers.
3. Run the RAG pipeline on each question.
4. Feed predictions to SASEvaluator and FaithfulnessEvaluator.

### Sample Code Skeleton
```python
from haystack.components.evaluators import SASEvaluator
import csv

# Assume rag_pipeline is already built and the store is populated
test_cases = [
    {"question": "What is Haystack?",       "answer": "Haystack is an LLM framework."},
    {"question": "What is a DocumentStore?","answer": "A DocumentStore persists documents."},
]

predictions, ground_truths = [], []
for tc in test_cases:
    result = rag_pipeline.run({
        "embedder": {"text": tc["question"]},
        "builder":  {"query": tc["question"]},
    })
    predictions.append(result["generator"]["replies"][0])
    ground_truths.append([tc["answer"]])

evaluator = SASEvaluator(model="sentence-transformers/all-MiniLM-L6-v2")
evaluator.warm_up()
scores = evaluator.run(predicted_answers=predictions, ground_truth_answers=ground_truths)

print(f"Mean SAS: {scores['score']:.4f}")
for i, s in enumerate(scores["individual_scores"]):
    print(f"  Q{i+1}: {s:.4f}")
```

### Expected Outcome
A per-question and aggregate SAS score table that quantifies retrieval and generation quality.

---

## Project 7: ChromaDB-Backed Production Pipeline

### Overview
Replace `InMemoryDocumentStore` with `ChromaDocumentStore` for persistent, disk-backed
vector search. Suitable for production deployments where data must survive restarts.

### Setup Steps
1. `pip install haystack-ai chroma-haystack chromadb sentence-transformers`
2. Choose a `persist_path` for ChromaDB storage.
3. Run the indexing pipeline once; re-use the store across restarts.

### Sample Code Skeleton
```python
from haystack_integrations.document_stores.chroma import ChromaDocumentStore
from haystack_integrations.components.retrievers.chroma import ChromaEmbeddingRetriever
from haystack.components.embedders import (
    SentenceTransformersDocumentEmbedder,
    SentenceTransformersTextEmbedder,
)
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack import Pipeline

PERSIST_PATH = "./chroma_production_db"
chroma_store = ChromaDocumentStore(persist_path=PERSIST_PATH)

# Query pipeline (indexing pipeline runs separately / once)
TEMPLATE = """
{% for doc in documents %}{{ doc.content }}\n{% endfor %}
Question: {{ query }}
Answer:
"""
qry = Pipeline()
qry.add_component("embedder",  SentenceTransformersTextEmbedder())
qry.add_component("retriever", ChromaEmbeddingRetriever(document_store=chroma_store, top_k=5))
qry.add_component("builder",   PromptBuilder(template=TEMPLATE))
qry.add_component("generator", OpenAIGenerator(model="gpt-3.5-turbo"))
qry.connect("embedder.embedding",  "retriever.query_embedding")
qry.connect("retriever.documents", "builder.documents")
qry.connect("builder.prompt",      "generator.prompt")

# Serialize for portability
with open("chroma_rag_pipeline.yaml", "w") as f:
    qry.dump(f)
```

### Expected Outcome
A production-ready query pipeline backed by ChromaDB that persists between runs and
can be deployed as a REST API (e.g., with FastAPI).

---

## Project 8: Async Pipeline for High Throughput

### Overview
Use `pipeline.run_async()` with `asyncio.gather()` to process hundreds of queries
concurrently, maximizing throughput on batched workloads such as document classification
or bulk summarization.

### Setup Steps
1. `pip install haystack-ai sentence-transformers`
2. Prepare a list of 100+ query strings.
3. Run all queries asynchronously and collect results.

### Sample Code Skeleton
```python
import asyncio
from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()  # pre-populated by indexing pipeline

pipeline = Pipeline()
pipeline.add_component("embedder",  SentenceTransformersTextEmbedder())
pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=store, top_k=3))
pipeline.connect("embedder.embedding", "retriever.query_embedding")

async def run_query(q: str) -> dict:
    return await pipeline.run_async({"embedder": {"text": q}})

async def batch_query(questions: list[str]) -> list[dict]:
    tasks = [run_query(q) for q in questions]
    return await asyncio.gather(*tasks)

if __name__ == "__main__":
    questions = [f"Question number {i}" for i in range(50)]
    results = asyncio.run(batch_query(questions))
    print(f"Processed {len(results)} queries concurrently.")
    for i, r in enumerate(results[:3]):
        docs = r["retriever"]["documents"]
        print(f"  Q{i}: {len(docs)} docs retrieved")
```

### Expected Outcome
Sub-linear latency scaling: 50 concurrent queries complete in roughly the same wall-clock
time as a single query, limited only by model inference throughput.

---

## Quick Reference: Project–Component Matrix

| Project | Store          | Converter          | Embedder                  | Generator        |
|---------|----------------|--------------------|---------------------------|------------------|
| 1       | InMemory       | PyPDFToDocument    | SentenceTransformers      | OpenAI GPT       |
| 2       | InMemory       | Custom URLScraper  | SentenceTransformers      | (retrieval only) |
| 3       | InMemory       | Router + 3 types   | SentenceTransformers      | (retrieval only) |
| 4       | InMemory       | TextFileToDocument | SentenceTransformers      | (custom filter)  |
| 5       | InMemory       | TextFileToDocument | SentenceTransformers      | (versioning)     |
| 6       | InMemory       | TextFileToDocument | SentenceTransformers      | OpenAI + eval    |
| 7       | ChromaDB       | PyPDFToDocument    | SentenceTransformers      | OpenAI GPT       |
| 8       | InMemory       | TextFileToDocument | SentenceTransformers      | (async batch)    |