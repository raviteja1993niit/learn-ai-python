# Haystack 2.0 — Theory & Architecture

## 1. Overview

Haystack 2.0, developed by deepset, is a production-ready open-source framework for building
LLM-powered applications, specifically document retrieval and question-answering (RAG) systems.
It is a ground-up redesign of Haystack 1.x, introducing a fully component-based, composable
architecture that is declarative, testable, and serializable.

---

## 2. Architecture: Component-Based Pipeline System

Everything in Haystack 2.0 is a **Component**. Pipelines are simply graphs where components
are nodes and data flows along directed edges between them.

### Key principles
- **Composability**: Any component can be swapped out without changing the rest of the pipeline.
- **Declarativeness**: Pipelines are described structurally — what connects to what — rather
  than imperatively step by step.
- **Serializability**: Pipelines can be exported to YAML/JSON and re-loaded, enabling
  reproducibility, versioning, and sharing.
- **Type safety**: Connections between components are type-checked at graph construction time,
  catching mismatches before runtime.

### Pipeline as a directed acyclic graph (DAG)
```
FileToDocument → DocumentSplitter → Embedder → DocumentWriter
```
Each arrow represents an explicit `.connect()` call. The pipeline engine resolves execution
order topologically, ensuring dependencies are satisfied before each component runs.

---

## 3. Core Design: The @component Decorator

Components are plain Python classes decorated with `@component`. This decorator registers the
class in Haystack's component registry, making it discoverable for serialization and pipeline
validation.

### Rules for a valid component
1. The class must be decorated with `@component`.
2. It must implement a `run()` method.
3. The `run()` method's return type must be annotated with `@component.output_types(...)`.
4. Input parameters are declared as typed parameters of `run()`.
5. The `run()` method must return a dictionary whose keys match the declared output names.

### Example skeleton
```python
from haystack import component

@component
class MyComponent:
    @component.output_types(result=str)
    def run(self, text: str) -> dict:
        return {"result": text.upper()}
```

The `@component` decorator also wires up `__init__` parameters as component-level
configuration, separating *configuration* (set at init time) from *data* (passed at run time).

---

## 4. Component Inputs and Outputs

### Inputs
Inputs are the typed parameters of the `run()` method. They may be:
- **Required**: no default value; must be provided either by a connected component or via
  pipeline `run()` input.
- **Optional**: have a default value; can be omitted.

Haystack validates that the type of data flowing along an edge matches the declared type of the
receiving input parameter.

### Outputs: @component.output_types
The `@component.output_types` decorator declares the output schema:
```python
@component.output_types(documents=List[Document], count=int)
def run(self, query: str) -> dict:
    ...
    return {"documents": docs, "count": len(docs)}
```
Each declared output becomes a named socket that can be connected to another component's input.

---

## 5. Document: Haystack's Core Data Unit

`Document` is the central data model used throughout indexing and retrieval pipelines.

### Fields
| Field       | Type             | Description                                    |
|-------------|------------------|------------------------------------------------|
| `id`        | `str`            | Unique identifier (auto-generated SHA-256 hash)|
| `content`   | `str`            | Text content of the document                   |
| `meta`      | `dict`           | Arbitrary metadata (filename, source, date...) |
| `embedding` | `List[float]`    | Dense vector representation                    |
| `score`     | `float`          | Retrieval relevance score                      |
| `dataframe` | `pd.DataFrame`   | Optional tabular content                       |
| `blob`      | `ByteStream`     | Optional binary content                        |

### Usage
Documents are created by file converters, enriched by splitters, embedded by embedders,
stored in document stores, and retrieved by retrievers.

---

## 6. DocumentStore Types

### InMemoryDocumentStore
- Stores documents in Python memory (a dict).
- No persistence; data is lost when the process exits.
- Ideal for prototyping, unit tests, and tutorials.
- Supports both BM25 (keyword) and embedding (vector) retrieval.

### ChromaDocumentStore
- Integration with ChromaDB, an open-source embedded vector database.
- Persists to disk or connects to a remote Chroma server.
- Suitable for small-to-medium production deployments.
- Native support for cosine, L2, and inner product similarity.

### WeaviateDocumentStore
- Integrates with Weaviate, a cloud-native vector search engine.
- Supports hybrid search (BM25 + vector) natively.
- Highly scalable, designed for production workloads.
- Supports multi-tenancy and schema management.

### ElasticsearchDocumentStore
- Integrates with Elasticsearch / OpenSearch.
- Supports full-text BM25 search, vector kNN search, and hybrid queries.
- Best choice when you already have an Elasticsearch cluster.
- Supports complex filtering via Elasticsearch DSL.

---

## 7. Pipeline: The Orchestration Layer

### Construction API
```python
from haystack import Pipeline

pipeline = Pipeline()
pipeline.add_component("embedder", SentenceTransformersTextEmbedder())
pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store))
pipeline.connect("embedder.embedding", "retriever.query_embedding")
```

### Key methods
| Method                          | Description                                         |
|---------------------------------|-----------------------------------------------------|
| `add_component(name, instance)` | Register a component with a unique name             |
| `connect("a.out", "b.in")`      | Create a directed edge from output socket to input  |
| `run({name: {param: value}})`   | Execute pipeline with provided input values         |
| `to_dict()`                     | Serialize pipeline to a Python dictionary           |
| `Pipeline.from_dict(d)`         | Deserialize from a dictionary                       |
| `dump(fp)`                      | Write serialized pipeline to file (YAML/JSON)       |
| `load(fp)`                      | Load pipeline from file                             |
| `run_async(...)`                | Async (non-blocking) pipeline execution             |

---

## 8. Indexing Pipeline Flow

```
Raw Files
   │
   ▼
FileToDocument        ← reads raw bytes; produces Document with content
   │
   ▼
DocumentSplitter      ← splits large docs into overlapping chunks
   │
   ▼
DocumentEmbedder      ← encodes each chunk into a dense vector
   │
   ▼
DocumentWriter        ← persists documents + embeddings to a DocumentStore
```

Each component in this pipeline is completely swappable. For example, you can replace
`SentenceTransformersDocumentEmbedder` with `OpenAIDocumentEmbedder` without changing any
other component.

---

## 9. Query Pipeline Flow

```
User Query
   │
   ▼
TextEmbedder          ← encodes query string into a dense vector
   │
   ▼
EmbeddingRetriever    ← finds top-k documents by vector similarity
   │
   ▼
Ranker (optional)     ← re-ranks results by cross-encoder similarity
   │
   ▼
PromptBuilder         ← injects query + docs into a Jinja2 template
   │
   ▼
Generator             ← sends prompt to LLM; returns generated answer
   │
   ▼
Answer (str)
```

---

## 10. File Converters

### PDFToDocument
- Extracts text from PDF files using `pypdf` or `pdfminer.six`.
- Each page can be a separate document or all pages merged.
- Handles multi-column layouts with reasonable accuracy.

### TextFileToDocument
- Reads `.txt` files; wraps content in a `Document`.
- Supports encoding specification.

### HTMLToDocument
- Parses HTML using Beautiful Soup.
- Strips scripts, styles, and navigation elements.
- Useful for web-scraped content.

### Other converters
- `MarkdownToDocument`, `JSONConverter`, `AzureOCRDocumentConverter`,
  `TikaDocumentConverter` (via Apache Tika), `PPTXToDocument`, `DOCXToDocument`.

---

## 11. DocumentSplitter

The `DocumentSplitter` breaks large documents into smaller, overlapping chunks suitable
for embedding and retrieval.

### Parameters
| Parameter        | Values                          | Description                           |
|------------------|---------------------------------|---------------------------------------|
| `split_by`       | `"word"`, `"sentence"`, `"page"`, `"passage"` | Unit of splitting         |
| `split_length`   | `int`                           | Target chunk size in split units      |
| `split_overlap`  | `int`                           | Overlap between consecutive chunks    |
| `split_threshold`| `int`                           | Min size; smaller chunks are merged   |

### Why overlap matters
When a chunk boundary falls inside a relevant passage, overlap ensures the context is
preserved in at least one of the adjacent chunks, improving retrieval recall.

---

## 12. Embedders

### SentenceTransformersTextEmbedder
- Encodes a single query string using a local SentenceTransformers model.
- Default model: `sentence-transformers/all-MiniLM-L6-v2`.
- Returns `{"embedding": List[float]}`.

### SentenceTransformersDocumentEmbedder
- Batch-encodes a list of `Document` objects.
- Adds `embedding` field to each document in-place.
- Returns `{"documents": List[Document]}`.

### OpenAITextEmbedder
- Calls OpenAI's Embeddings API (`text-embedding-ada-002` by default).
- Returns `{"embedding": List[float], "meta": dict}`.
- Requires `OPENAI_API_KEY` environment variable.

### OpenAIDocumentEmbedder
- Batch-embeds documents using OpenAI Embeddings API.
- Supports batching to stay within API rate limits.

---

## 13. Retrievers

### InMemoryEmbeddingRetriever
- Performs cosine similarity search over documents in `InMemoryDocumentStore`.
- Parameter `top_k`: number of results to return (default 10).

### InMemoryBM25Retriever
- Performs BM25 keyword search over `InMemoryDocumentStore`.
- Useful when dense vector retrieval is not needed.

### ChromaEmbeddingRetriever
- Delegates vector search to a connected `ChromaDocumentStore`.
- Supports `filters` parameter for metadata pre-filtering.

### top_k and filters
All retrievers accept `top_k` (int) and `filters` (dict) parameters. Filters allow
narrowing the search space by metadata fields before similarity scoring.

---

## 14. Ranker

### SentenceTransformersSimilarityRanker
- Uses a cross-encoder model to re-score retrieved documents against the query.
- Cross-encoders consider the full (query, document) pair, giving higher accuracy than
  bi-encoder retrieval.
- Accepts `documents` and `query` as inputs; returns re-ordered `documents`.
- Default model: `cross-encoder/ms-marco-MiniLM-L-6-v2`.

### When to use a ranker
Initial retrieval (especially ANN vector search) optimizes for speed and recall. A ranker
is a precision step: it re-orders the top-k candidates to surface the most relevant ones.

---

## 15. PromptBuilder

`PromptBuilder` converts structured data (documents, query, metadata) into a formatted
prompt string ready for an LLM.

### Jinja2 templating
```jinja2
Given these documents:
{% for doc in documents %}
  - {{ doc.content }}
{% endfor %}

Answer the question: {{ query }}
```

### How it works
- The `template` parameter is a Jinja2 string.
- Any variable in the template becomes a required input to `PromptBuilder.run()`.
- Returns `{"prompt": str}`.
- Template variables are type-checked against provided inputs.

---

## 16. Generators

### OpenAIGenerator
- Wraps OpenAI's `/v1/chat/completions` endpoint.
- Model configurable (default: `gpt-3.5-turbo`).
- Supports `generation_kwargs` for temperature, max_tokens, etc.
- Returns `{"replies": List[str], "meta": List[dict]}`.

### HuggingFaceLocalGenerator
- Runs a HuggingFace `transformers` model locally using a `text-generation` pipeline.
- Suitable for air-gapped environments.
- `huggingface_pipeline_kwargs` controls device, dtype, etc.

### OllamaGenerator
- Integrates with a locally running [Ollama](https://ollama.ai) server.
- Supports any model available in Ollama (Llama 3, Mistral, Gemma, etc.).
- Zero API cost; ideal for development and privacy-sensitive use cases.

### HuggingFaceAPIGenerator
- Calls HuggingFace Inference API (serverless or dedicated endpoints).
- Supports `text-generation-inference` (TGI) compatible endpoints.

---

## 17. Evaluation Components

### SASEvaluator (Semantic Answer Similarity)
- Computes semantic similarity between predicted and ground-truth answers.
- Uses a SentenceTransformers model for encoding.
- Returns a score between 0 and 1.

### ContextRelevanceEvaluator
- Checks whether retrieved context documents are relevant to the input query.
- Uses an LLM-as-judge approach.

### FaithfulnessEvaluator
- Verifies that the generated answer is grounded in the provided context.
- Detects hallucinations by checking claim-by-claim against the documents.

### DeepEvalFaithfulnessEvaluator
- Integrates with the [DeepEval](https://github.com/confident-ai/deepeval) framework.
- Provides faithfulness scoring with detailed metric breakdowns.

---

## 18. Custom Components

Building a custom component requires:

1. Decorate the class with `@component`.
2. Implement `__init__` for configuration parameters.
3. Decorate `run()` with `@component.output_types(key=Type, ...)`.
4. Implement `run()` with typed input parameters.
5. Return a dict matching declared output keys.

### Warm-up pattern
For components that load heavy resources (models, DB connections), implement
`warm_up()`. Haystack calls this before the first pipeline run.

### ComponentError
Raise `haystack.core.errors.ComponentError` for component-level failures to get
proper error propagation through the pipeline.

---

## 19. Serialization

Haystack pipelines are fully serializable to YAML or JSON, enabling:
- Version-controlled pipeline definitions.
- Sharing pipelines across environments.
- Loading pipelines without knowing their exact Python structure.

### Methods
```python
# To dict
d = pipeline.to_dict()

# From dict
pipeline = Pipeline.from_dict(d)

# To YAML file
with open("pipeline.yaml", "w") as f:
    pipeline.dump(f)

# From YAML file
with open("pipeline.yaml") as f:
    pipeline = Pipeline.load(f)
```

Serialization captures component class names, init parameters, and connection graph.
The deserializer imports the class by dotted path, so custom components must be
importable from the environment where the pipeline is loaded.

---

## 20. Async Pipelines

For high-throughput applications, Haystack supports async execution:

```python
import asyncio

async def main():
    result = await pipeline.run_async({"embedder": {"text": query}})
    print(result)

asyncio.run(main())
```

Async pipelines allow multiple pipeline runs to be in-flight concurrently, sharing
underlying resources (e.g., model inference batching, connection pools).

---

## 21. Pipeline Branching and Merging

Haystack 2.0 supports non-linear pipeline topologies:

### Branching (one output → multiple inputs)
A single output socket can be connected to multiple downstream components. Both branches
receive the same data and execute in parallel where possible.

### Merging (multiple outputs → one input)
Multiple upstream outputs can feed into the same downstream input. The component waits
for all upstream components to produce their output before executing.

### Conditional routing
A component can declare multiple output sockets and selectively populate only one per
run, effectively routing data along different pipeline branches depending on runtime
conditions. The pipeline engine handles the case where an optional output is absent.

---

## 22. Summary

Haystack 2.0 represents a mature, production-oriented framework for RAG and LLM pipelines.
Its component-based architecture enables:
- Clean separation of concerns
- Easy swapping of embedding models, vector stores, and LLMs
- Full reproducibility through serialization
- Extensibility through custom components
- Evaluation-driven iteration through built-in evaluators

The framework is actively maintained by deepset and has a growing ecosystem of integrations
covering virtually every major vector database, embedding provider, and LLM API.