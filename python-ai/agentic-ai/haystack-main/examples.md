# Haystack 2.0 — Code Examples

This file contains 19 annotated Python code examples covering the full Haystack 2.0 API.
Each example is self-contained and includes a comment block explaining what it demonstrates.

---

## Example 1: InMemoryDocumentStore — Creation and Document Writing

```python
# Demonstrates: Creating an in-memory document store and writing Document objects to it.
# InMemoryDocumentStore requires no external services; ideal for prototyping and tests.

from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.dataclasses import Document

store = InMemoryDocumentStore()

docs = [
    Document(content="Haystack is an open-source LLM framework.", meta={"source": "intro.txt"}),
    Document(content="Pipelines connect components via typed edges.", meta={"source": "arch.txt"}),
    Document(content="Documents are the core data unit in Haystack.", meta={"source": "data.txt"}),
]

store.write_documents(docs)
print(f"Documents stored: {store.count_documents()}")  # → 3
```

---

## Example 2: Basic Indexing Pipeline (TextFileToDocument → Splitter → Embedder → Writer)

```python
# Demonstrates: A full text-file indexing pipeline.
# Files are read, split into chunks, embedded, then persisted in the document store.

from haystack import Pipeline
from haystack.components.converters import TextFileToDocument
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.embedders import SentenceTransformersDocumentEmbedder
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()

indexing = Pipeline()
indexing.add_component("converter",  TextFileToDocument())
indexing.add_component("splitter",   DocumentSplitter(split_by="word", split_length=200, split_overlap=20))
indexing.add_component("embedder",   SentenceTransformersDocumentEmbedder(model="sentence-transformers/all-MiniLM-L6-v2"))
indexing.add_component("writer",     DocumentWriter(document_store=store))

indexing.connect("converter.documents", "splitter.documents")
indexing.connect("splitter.documents",  "embedder.documents")
indexing.connect("embedder.documents",  "writer.documents")

result = indexing.run({"converter": {"sources": ["notes.txt", "report.txt"]}})
print(result)
```

---

## Example 3: PDF Ingestion Pipeline

```python
# Demonstrates: Ingesting PDF files into a document store.
# PDFToDocument extracts text page-by-page; each page becomes a Document.

from haystack import Pipeline
from haystack.components.converters import PyPDFToDocument
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.embedders import SentenceTransformersDocumentEmbedder
from haystack.components.writers import DocumentWriter
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()

pdf_pipeline = Pipeline()
pdf_pipeline.add_component("pdf_converter", PyPDFToDocument())
pdf_pipeline.add_component("splitter",      DocumentSplitter(split_by="sentence", split_length=5))
pdf_pipeline.add_component("embedder",      SentenceTransformersDocumentEmbedder())
pdf_pipeline.add_component("writer",        DocumentWriter(document_store=store))

pdf_pipeline.connect("pdf_converter.documents", "splitter.documents")
pdf_pipeline.connect("splitter.documents",       "embedder.documents")
pdf_pipeline.connect("embedder.documents",       "writer.documents")

pdf_pipeline.run({"pdf_converter": {"sources": ["knowledge_base.pdf"]}})
print(f"Indexed {store.count_documents()} chunks.")
```

---

## Example 4: DocumentSplitter Configuration

```python
# Demonstrates: Different splitting strategies and their effect on chunk granularity.

from haystack.components.preprocessors import DocumentSplitter
from haystack.dataclasses import Document

splitter = DocumentSplitter(
    split_by="word",       # split unit: "word", "sentence", "page", "passage"
    split_length=150,      # target chunk size (in split units)
    split_overlap=30,      # overlap between consecutive chunks
)

long_doc = Document(content="word " * 500)  # simulate a long document
result = splitter.run(documents=[long_doc])

for i, chunk in enumerate(result["documents"]):
    word_count = len(chunk.content.split())
    print(f"Chunk {i}: {word_count} words")
```

---

## Example 5: SentenceTransformersTextEmbedder

```python
# Demonstrates: Encoding a single query string into a dense vector using a local model.
# The resulting embedding is used as input to an EmbeddingRetriever.

from haystack.components.embedders import SentenceTransformersTextEmbedder

embedder = SentenceTransformersTextEmbedder(
    model="sentence-transformers/all-MiniLM-L6-v2"
)
embedder.warm_up()  # loads the model; call once before run()

result = embedder.run(text="What is Haystack 2.0?")
embedding = result["embedding"]
print(f"Embedding dim: {len(embedding)}")   # → 384
print(f"First 5 values: {embedding[:5]}")
```

---

## Example 6: OpenAITextEmbedder

```python
# Demonstrates: Encoding a query string using OpenAI's embedding API.
# Requires OPENAI_API_KEY set in environment. Uses text-embedding-ada-002 by default.

import os
from haystack.components.embedders import OpenAITextEmbedder

os.environ["OPENAI_API_KEY"] = "sk-..."  # replace with actual key or use env

embedder = OpenAITextEmbedder(model="text-embedding-ada-002")
result = embedder.run(text="Explain Haystack pipelines.")

print(f"Embedding dim: {len(result['embedding'])}")  # → 1536
print(f"Usage metadata: {result['meta']}")
```

---

## Example 7: InMemoryEmbeddingRetriever

```python
# Demonstrates: Vector similarity retrieval from an InMemoryDocumentStore.
# Retrieves the top-k most semantically similar documents to a query embedding.

from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.dataclasses import Document
import numpy as np

store = InMemoryDocumentStore()

# Pre-embed documents (normally done by indexing pipeline)
store.write_documents([
    Document(content="Haystack RAG pipeline.", embedding=[0.1, 0.9, 0.3]),
    Document(content="Python web framework.",  embedding=[0.8, 0.1, 0.6]),
])

retriever = InMemoryEmbeddingRetriever(document_store=store, top_k=1)
result = retriever.run(query_embedding=[0.1, 0.85, 0.3])

for doc in result["documents"]:
    print(f"Retrieved: {doc.content}  (score={doc.score:.4f})")
```

---

## Example 8: PromptBuilder with Jinja2 Template

```python
# Demonstrates: Building a structured LLM prompt by injecting retrieved documents
# and the user query into a Jinja2 template.

from haystack.components.builders import PromptBuilder
from haystack.dataclasses import Document

template = """
You are a helpful assistant. Use the following documents to answer the question.

{% for doc in documents %}
Document {{ loop.index }}: {{ doc.content }}
{% endfor %}

Question: {{ query }}
Answer:
"""

builder = PromptBuilder(template=template)
docs = [Document(content="Haystack 2.0 uses a component-based pipeline.")]
result = builder.run(documents=docs, query="What is Haystack?")
print(result["prompt"])
```

---

## Example 9: OpenAIGenerator

```python
# Demonstrates: Calling OpenAI's chat completion API to generate a text answer.
# generation_kwargs control temperature, max tokens, and other sampler settings.

import os
from haystack.components.generators import OpenAIGenerator

os.environ["OPENAI_API_KEY"] = "sk-..."

generator = OpenAIGenerator(
    model="gpt-3.5-turbo",
    generation_kwargs={"temperature": 0.2, "max_tokens": 256}
)

result = generator.run(prompt="Explain what a Haystack Pipeline is in two sentences.")
print(result["replies"][0])
print("Usage:", result["meta"][0]["usage"])
```

---

## Example 10: Full RAG Query Pipeline (Embedder → Retriever → PromptBuilder → Generator)

```python
# Demonstrates: A complete Retrieval-Augmented Generation pipeline.
# User query is embedded, matched against stored docs, injected into a prompt, and answered.

import os
from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.document_stores.in_memory import InMemoryDocumentStore

os.environ["OPENAI_API_KEY"] = "sk-..."

store = InMemoryDocumentStore()
# (assume store is already populated by an indexing pipeline)

template = """
Use the documents below to answer the question.
{% for doc in documents %}{{ doc.content }}{% endfor %}
Question: {{ query }}
Answer:
"""

rag = Pipeline()
rag.add_component("embedder",   SentenceTransformersTextEmbedder())
rag.add_component("retriever",  InMemoryEmbeddingRetriever(document_store=store, top_k=3))
rag.add_component("builder",    PromptBuilder(template=template))
rag.add_component("generator",  OpenAIGenerator(model="gpt-3.5-turbo"))

rag.connect("embedder.embedding",    "retriever.query_embedding")
rag.connect("retriever.documents",   "builder.documents")
rag.connect("builder.prompt",        "generator.prompt")

result = rag.run({
    "embedder":  {"text": "What is Haystack?"},
    "builder":   {"query": "What is Haystack?"},
})
print(result["generator"]["replies"][0])
```

---

## Example 11: Pipeline connect() Wiring Pattern

```python
# Demonstrates: The explicit socket-based connect() API.
# Format: "component_name.socket_name" — both output and input sockets are named.

from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()
pipeline = Pipeline()

pipeline.add_component("q_embedder",  SentenceTransformersTextEmbedder())
pipeline.add_component("retriever",   InMemoryEmbeddingRetriever(document_store=store))

# "q_embedder" outputs "embedding"; "retriever" expects "query_embedding"
pipeline.connect("q_embedder.embedding", "retriever.query_embedding")

# Inspect the graph
print(pipeline.graph.edges)
```

---

## Example 12: Pipeline run() with Inputs

```python
# Demonstrates: Providing input values to specific pipeline components via run().
# The input dict maps component names to their run() keyword arguments.

result = rag.run({
    "embedder": {
        "text": "How do I build a RAG pipeline in Haystack?"
    },
    "builder": {
        "query": "How do I build a RAG pipeline in Haystack?"
    }
})

answer = result["generator"]["replies"][0]
print("Answer:", answer)
```

---

## Example 13: Custom @component Class

```python
# Demonstrates: Building a fully custom Haystack component.
# This component filters documents by a minimum word count threshold.

from typing import List
from haystack import component
from haystack.dataclasses import Document

@component
class MinWordFilter:
    def __init__(self, min_words: int = 20):
        self.min_words = min_words

    @component.output_types(documents=List[Document], filtered_count=int)
    def run(self, documents: List[Document]) -> dict:
        kept = [d for d in documents if len(d.content.split()) >= self.min_words]
        removed = len(documents) - len(kept)
        return {"documents": kept, "filtered_count": removed}

# Use in a pipeline
from haystack import Pipeline
filter_pipe = Pipeline()
filter_pipe.add_component("filter", MinWordFilter(min_words=30))
```

---

## Example 14: Serialization to YAML (pipeline.dump())

```python
# Demonstrates: Serializing a pipeline to a YAML file for versioning and portability.
# The YAML captures component classes, init args, and the connection graph.

from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()
p = Pipeline()
p.add_component("embedder",  SentenceTransformersTextEmbedder())
p.add_component("retriever", InMemoryEmbeddingRetriever(document_store=store))
p.connect("embedder.embedding", "retriever.query_embedding")

with open("retrieval_pipeline.yaml", "w") as f:
    p.dump(f)

print("Pipeline serialized to retrieval_pipeline.yaml")
```

---

## Example 15: Loading Pipeline from YAML (Pipeline.load())

```python
# Demonstrates: Deserializing a pipeline from a YAML file.
# The pipeline is reconstructed with all components and connections intact.

from haystack import Pipeline

with open("retrieval_pipeline.yaml") as f:
    loaded_pipeline = Pipeline.load(f)

print("Loaded components:", list(loaded_pipeline.graph.nodes))
# Now run it just like any other pipeline
```

---

## Example 16: SentenceTransformersSimilarityRanker

```python
# Demonstrates: Re-ranking retrieved documents by cross-encoder similarity.
# A ranker improves precision by scoring (query, doc) pairs jointly.

from haystack.components.rankers import SentenceTransformersSimilarityRanker
from haystack.dataclasses import Document

ranker = SentenceTransformersSimilarityRanker(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2",
    top_k=3
)
ranker.warm_up()

docs = [
    Document(content="Haystack builds RAG pipelines."),
    Document(content="Python is a programming language."),
    Document(content="Component-based design enables modularity."),
    Document(content="Retrievers find relevant documents."),
]

result = ranker.run(query="What is Haystack?", documents=docs)
for doc in result["documents"]:
    print(f"[{doc.score:.4f}] {doc.content}")
```

---

## Example 17: Evaluation with SASEvaluator

```python
# Demonstrates: Measuring semantic answer similarity between predictions and ground truth.
# SASEvaluator uses a SentenceTransformers model to compare answer strings.

from haystack.components.evaluators import SASEvaluator

evaluator = SASEvaluator(model="sentence-transformers/all-MiniLM-L6-v2")
evaluator.warm_up()

predicted = ["Haystack is a framework for building LLM pipelines."]
ground_truth = [["Haystack is an open-source LLM orchestration framework."]]

result = evaluator.run(predicted_answers=predicted, ground_truth_answers=ground_truth)
print(f"SAS score: {result['individual_scores'][0]:.4f}")
print(f"Mean SAS:  {result['score']:.4f}")
```

---

## Example 18: ChromaDocumentStore Integration

```python
# Demonstrates: Using ChromaDB as a persistent vector store in Haystack.
# Documents and embeddings are persisted to disk and survive process restarts.

from haystack_integrations.document_stores.chroma import ChromaDocumentStore
from haystack_integrations.components.retrievers.chroma import ChromaEmbeddingRetriever
from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder

# persist_path saves the DB to disk
chroma_store = ChromaDocumentStore(persist_path="./chroma_db")

query_pipeline = Pipeline()
query_pipeline.add_component("embedder",  SentenceTransformersTextEmbedder())
query_pipeline.add_component("retriever", ChromaEmbeddingRetriever(document_store=chroma_store, top_k=5))

query_pipeline.connect("embedder.embedding", "retriever.query_embedding")

result = query_pipeline.run({"embedder": {"text": "vector search with Chroma"}})
for doc in result["retriever"]["documents"]:
    print(doc.content[:80])
```

---

## Example 19: Async Pipeline Run

```python
# Demonstrates: Running a Haystack pipeline asynchronously with run_async().
# Enables concurrent pipeline executions in high-throughput applications.

import asyncio
from haystack import Pipeline
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()

pipeline = Pipeline()
pipeline.add_component("embedder",  SentenceTransformersTextEmbedder())
pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=store))
pipeline.connect("embedder.embedding", "retriever.query_embedding")

async def query(q: str):
    return await pipeline.run_async({"embedder": {"text": q}})

async def main():
    queries = ["What is RAG?", "How does Haystack work?", "What is a DocumentStore?"]
    # Run all queries concurrently
    results = await asyncio.gather(*[query(q) for q in queries])
    for q, r in zip(queries, results):
        docs = r["retriever"]["documents"]
        print(f"Query: {q!r}  → {len(docs)} results")

asyncio.run(main())
```

---

## Summary

| # | Example                              | Key API                                      |
|---|--------------------------------------|----------------------------------------------|
| 1 | InMemoryDocumentStore               | `store.write_documents()`                    |
| 2 | Text indexing pipeline              | `Pipeline.add_component`, `connect`, `run`   |
| 3 | PDF ingestion                       | `PyPDFToDocument`                            |
| 4 | DocumentSplitter config             | `split_by`, `split_length`, `split_overlap`  |
| 5 | SentenceTransformers embed (query)  | `SentenceTransformersTextEmbedder`           |
| 6 | OpenAI embed (query)                | `OpenAITextEmbedder`                         |
| 7 | In-memory vector retrieval          | `InMemoryEmbeddingRetriever`                 |
| 8 | PromptBuilder Jinja2                | `PromptBuilder(template=...)`                |
| 9 | OpenAI generate                     | `OpenAIGenerator`                            |
|10 | Full RAG pipeline                   | end-to-end compose                           |
|11 | connect() wiring                    | `"comp.output"` → `"comp.input"` syntax      |
|12 | run() with inputs                   | nested dict format                           |
|13 | Custom component                    | `@component`, `@component.output_types`      |
|14 | Serialize to YAML                   | `pipeline.dump(file)`                        |
|15 | Load from YAML                      | `Pipeline.load(file)`                        |
|16 | Ranker                              | `SentenceTransformersSimilarityRanker`       |
|17 | SAS evaluation                      | `SASEvaluator`                               |
|18 | ChromaDB integration                | `ChromaDocumentStore`                        |
|19 | Async execution                     | `pipeline.run_async()`                       |