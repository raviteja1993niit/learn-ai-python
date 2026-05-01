# LlamaIndex Theory & Concepts
> A comprehensive deep-dive into LlamaIndex architecture, abstractions, and design philosophy

---

## Table of Contents
1. [LlamaIndex vs LangChain](#1-llamaindex-vs-langchain)
2. [Core Abstractions](#2-core-abstractions)
3. [Data Connectors (Readers)](#3-data-connectors-readers)
4. [Node Parsers](#4-node-parsers)
5. [Index Types](#5-index-types)
6. [Query Engines](#6-query-engines)
7. [Storage Layer](#7-storage-layer)
8. [Response Modes](#8-response-modes)
9. [Sub-Question Query Engine](#9-sub-question-query-engine)
10. [Metadata Filtering](#10-metadata-filtering)
11. [LlamaIndex Agents](#11-llamaindex-agents)
12. [LlamaParse](#12-llamaparse)
13. [Observability](#13-observability)

---

## 1. LlamaIndex vs LangChain

### Philosophy

**LlamaIndex** was purpose-built for **data indexing and retrieval**. Its core philosophy is:
> "Connect your private data to LLMs in the most efficient and structured way possible."

LlamaIndex treats your data as a first-class citizen. It provides a rich pipeline from raw documents
to structured nodes to indexed storage to intelligent retrieval. Every design decision revolves
around making RAG (Retrieval-Augmented Generation) pipelines robust, observable, and
production-ready.

**LangChain**, by contrast, is a **general-purpose LLM orchestration framework**. Its philosophy is:
> "Chain together LLM calls, tools, and data sources to build any LLM-powered application."

LangChain is broader — it covers agents, memory, chains, tools, and integrations with dozens of
services. But this breadth comes at the cost of depth in the data/retrieval domain.

### Key Differences

| Aspect                  | LlamaIndex                              | LangChain                          |
|-------------------------|-----------------------------------------|------------------------------------|
| Primary Focus           | Data indexing + RAG                     | General LLM orchestration          |
| Data Ingestion          | Rich, structured pipeline               | Basic document loaders             |
| Index Types             | VectorStore, Summary, KnowledgeGraph    | Primarily vector stores            |
| Node/Chunk Handling     | First-class concept (Nodes + metadata)  | Documents split into chunks        |
| Query Sophistication    | Sub-question, multi-doc, router engines | Chains, agent-based retrieval      |
| Agents                  | FunctionAgent, ReActAgent (data-aware)  | Full agent ecosystem (broader)     |
| Learning Curve          | Moderate (data-focused)                 | Higher (broader surface area)      |
| Best For                | Document Q&A, knowledge bases, RAG      | Complex pipelines, multi-step agents |

### When to Choose LlamaIndex
- You need a production-grade RAG pipeline
- Your use case is heavily document/data focused
- You want fine-grained control over chunking, indexing, and retrieval
- You need multi-document reasoning or knowledge graph construction
- You want built-in observability and tracing for retrieval pipelines

### When to Choose LangChain
- You need a flexible, general-purpose agent framework
- Your app involves complex multi-step tool use beyond retrieval
- You want extensive third-party integrations out of the box
- You are building conversational agents with complex memory requirements

### Using Both Together
LlamaIndex and LangChain are **not mutually exclusive**. LlamaIndex can serve as the retrieval
backbone while LangChain orchestrates the broader application logic. LlamaIndex provides a
LangChain integration layer (`llama_index.langchain_helpers`) for this purpose.

---

## 2. Core Abstractions

### 2.1 Documents
A **Document** is the top-level ingestion unit. It wraps raw text (or binary content) with metadata.

```
Document {
  text: str                  # raw content
  metadata: dict             # filename, page, source URL, author, etc.
  doc_id: str                # unique identifier
  embedding: List[float]     # optional pre-computed embedding
}
```

Documents are created by **Readers/Connectors** and then transformed into **Nodes** for indexing.
Metadata attached at the Document level propagates to all child Nodes.

### 2.2 Nodes
**Nodes** are the atomic units that LlamaIndex actually indexes and retrieves. A Document is split
into one or more Nodes by a **NodeParser**.

```
TextNode {
  text: str                   # chunk of text
  metadata: dict              # inherited + added metadata
  node_id: str                # unique ID
  relationships: dict         # PREVIOUS, NEXT, SOURCE links
  embedding: List[float]      # vector representation
  start_char_idx: int         # position in original doc
  end_char_idx: int
}
```

The **relationships** field is powerful — it lets LlamaIndex maintain document structure context
during retrieval (e.g., knowing which node comes before/after a retrieved chunk).

### 2.3 Index
An **Index** is a data structure built from Nodes that enables efficient retrieval. LlamaIndex
offers multiple index types (detailed in Section 5), each with different trade-offs.

The index lifecycle:
1. Ingest documents → parse into nodes → embed → store in index
2. At query time → embed query → retrieve relevant nodes → synthesize response

### 2.4 QueryEngine
A **QueryEngine** provides a high-level interface for question answering over an index.
It encapsulates:
- A **Retriever** (finds relevant nodes)
- A **ResponseSynthesizer** (generates the final answer from nodes + query)

```python
query_engine = index.as_query_engine()
response = query_engine.query("What is LlamaIndex?")
```

### 2.5 ChatEngine
A **ChatEngine** wraps a QueryEngine with **conversation memory**, enabling multi-turn dialogue.
It maintains a chat history and uses it to reformulate queries and provide contextual responses.

```python
chat_engine = index.as_chat_engine(chat_mode="condense_plus_context")
response = chat_engine.chat("Tell me about RAG")
response2 = chat_engine.chat("How does it compare to fine-tuning?")  # uses history
```

Chat modes:
- `simple` — No query condensing; passes history directly
- `condense_question` — Condenses follow-up questions using history
- `context` — Retrieves context for every message
- `condense_plus_context` — Combines both approaches (recommended)
- `react` — Uses a ReAct agent loop with retrieval tool

---

## 3. Data Connectors (Readers)

LlamaIndex provides a rich ecosystem of **data connectors** (also called Readers or Loaders)
through the `llama_hub` library and built-in modules.

### 3.1 SimpleDirectoryReader
The most commonly used reader. Recursively loads all files from a directory, auto-detecting
file types.

```python
from llama_index.core import SimpleDirectoryReader
documents = SimpleDirectoryReader("./data").load_data()
```

Supports: `.txt`, `.pdf`, `.docx`, `.md`, `.csv`, `.html`, `.epub`, images (with vision), and
more. Uses specialised sub-readers per file type internally.

### 3.2 PDFReader
Dedicated PDF parsing with page-level metadata. Each page becomes a separate Document.

```python
from llama_index.readers.file import PDFReader
reader = PDFReader()
documents = reader.load_data(file=Path("paper.pdf"))
```

For complex PDFs (tables, figures, multi-column), use **LlamaParse** instead (Section 12).

### 3.3 YouTubeTranscriptReader
Fetches YouTube video transcripts and creates Documents from them.

```python
from llama_hub.youtube_transcript import YoutubeTranscriptReader
loader = YoutubeTranscriptReader()
documents = loader.load_data(ytlinks=["https://www.youtube.com/watch?v=..."])
```

### 3.4 Web-Based Readers
- **SimpleWebPageReader** — Fetches and parses HTML pages
- **BeautifulSoupWebReader** — More sophisticated HTML parsing
- **TrafilaturaWebReader** — Content-focused extraction (removes nav/ads)
- **RssReader** — Loads articles from RSS feeds

### 3.5 Database Readers
- **DatabaseReader** — Executes SQL queries and creates Documents from rows
- **MongodbReader** — Reads from MongoDB collections
- **NotionPageReader** — Reads Notion pages and databases

### 3.6 Cloud Storage Readers
- **S3Reader** — AWS S3 buckets
- **GCSReader** — Google Cloud Storage
- **AzureBlobStorageReader** — Azure Blob Storage

### 3.7 LlamaHub
LlamaHub (https://llamahub.ai) is the community registry for 300+ data loaders. Install with:

```bash
pip install llama-hub
```

---

## 4. Node Parsers

**Node Parsers** transform Documents into Nodes (chunks). The chunking strategy significantly
impacts retrieval quality.

### 4.1 SentenceSplitter
The default and most commonly used parser. Splits text by sentences while respecting a token limit.

```python
from llama_index.core.node_parser import SentenceSplitter
parser = SentenceSplitter(chunk_size=512, chunk_overlap=50)
nodes = parser.get_nodes_from_documents(documents)
```

Key parameters:
- `chunk_size` — Maximum tokens per node (default: 1024)
- `chunk_overlap` — Overlap between consecutive nodes for context continuity
- `separator` — Primary split character (default: space)
- `paragraph_separator` — High-priority split point (default: double newline)

Priority hierarchy: paragraph breaks > sentence breaks > word breaks > character breaks.
This preserves semantic coherence as much as possible.

### 4.2 SemanticSplitter
Uses **embedding similarity** to determine split points. Groups sentences that are semantically
related rather than using fixed chunk sizes.

```python
from llama_index.core.node_parser import SemanticSplitter
from llama_index.embeddings.openai import OpenAIEmbedding

splitter = SemanticSplitter(
    buffer_size=1,
    breakpoint_percentile_threshold=95,
    embed_model=OpenAIEmbedding()
)
nodes = splitter.get_nodes_from_documents(documents)
```

How it works:
1. Split text into individual sentences
2. Compute embeddings for each sentence
3. Calculate cosine similarity between consecutive sentences
4. Split where similarity drops below the percentile threshold
5. Group related sentences into nodes

**Advantages**: More coherent chunks, better retrieval relevance  
**Disadvantages**: Requires embedding calls during ingestion (slower, higher cost)

### 4.3 Other Node Parsers
- **TokenTextSplitter** — Splits strictly by token count
- **CodeSplitter** — Respects code structure (functions, classes) using tree-sitter
- **MarkdownNodeParser** — Respects Markdown headers as split boundaries
- **HTMLNodeParser** — Splits by HTML tags
- **JSONNodeParser** — Handles JSON documents
- **LangchainNodeParser** — Wraps LangChain text splitters

---

## 5. Index Types

### 5.1 VectorStoreIndex
The most widely used index. Embeds all nodes and stores them in a vector database.
Retrieval is done via approximate nearest neighbor (ANN) search.

**Storage backends**: In-memory (default), Pinecone, Weaviate, Chroma, Qdrant, Milvus,
Elasticsearch, pgvector, and 30+ others.

**Best for**: General Q&A, semantic search, large document collections.

**Retrieval enhancements**:
- **MMR (Maximal Marginal Relevance)** — Reduces redundancy in retrieved nodes
- **Hybrid search** — Combines vector + keyword (BM25) search
- **Reranking** — Post-retrieval reranking with cross-encoders

### 5.2 SummaryIndex (formerly ListIndex)
Stores all nodes in a sequential list. At query time, **iterates through all nodes** to synthesize
a response. No vector search involved.

**Best for**: Summarisation tasks, small document sets, when all content must be processed.  
**Trade-off**: Slower but more thorough than vector retrieval.

### 5.3 KnowledgeGraphIndex
Builds a **knowledge graph** from documents by extracting (subject, predicate, object) triples
using an LLM. Stores them as graph edges.

**Best for**: Entity relationship queries, "how are X and Y related?", structured knowledge
extraction.

**Query modes**:
- `keyword` — Extracts entities from query, traverses graph
- `embedding` — Uses embeddings to find relevant graph nodes
- `hybrid` — Combines both

### 5.4 DocumentSummaryIndex
Creates a **summary for each document** and builds an index over those summaries. At query time:
1. Retrieves relevant document summaries
2. Fetches the full nodes from those documents
3. Synthesises response from the complete document content

**Best for**: Multi-document Q&A where document-level retrieval is needed.  
**Advantage over VectorStoreIndex**: Better handles queries requiring understanding of a whole
document's theme rather than specific passages.

### 5.5 TreeIndex
Builds a hierarchical tree of summaries. Bottom nodes are text chunks; upper nodes summarise
their children. Queries traverse the tree top-down.

**Best for**: Long documents, hierarchical summarisation.

---

## 6. Query Engines

### 6.1 as_query_engine()
Creates a standard single-turn query engine. The primary interface for Q&A.

```python
engine = index.as_query_engine(
    similarity_top_k=5,
    response_mode="compact",
    streaming=True
)
response = engine.query("What are the main findings?")
```

Internally: query → embed query → retrieve top-k nodes → synthesise response.

### 6.2 as_retriever()
Returns just the **retriever component** without response synthesis. Useful for custom pipelines
or evaluation.

```python
retriever = index.as_retriever(similarity_top_k=10)
nodes = retriever.retrieve("transformer architecture")
for node in nodes:
    print(node.score, node.text[:100])
```

### 6.3 as_chat_engine()
Wraps the query engine with conversation memory (see Section 2.5).

### 6.4 RouterQueryEngine
Routes queries to different query engines based on content. Uses an LLM to select the best engine.

```python
from llama_index.core.query_engine import RouterQueryEngine
from llama_index.core.selectors import LLMSingleSelector

engine = RouterQueryEngine(
    selector=LLMSingleSelector.from_defaults(),
    query_engine_tools=[tool1, tool2, tool3]
)
```

### 6.5 RetrieverQueryEngine
Combines a custom retriever with a response synthesiser for full control over the pipeline.

---

## 7. Storage Layer

LlamaIndex uses a **StorageContext** to manage four distinct storage components.

### 7.1 DocStore (Document Store)
Stores original Document and Node objects (not embeddings). Used for:
- Deduplication (do not re-index unchanged documents)
- Fetching full node text during retrieval
- Maintaining document-to-node relationships

Default: In-memory (`SimpleDocumentStore`)  
Persistent options: `RedisDocumentStore`, `MongoDocumentStore`, `DynamoDBDocumentStore`

### 7.2 IndexStore
Stores **index metadata** — structural information about the index (e.g., which nodes belong to
which index, tree structure). Small but critical.

### 7.3 Vector Store
Stores **node embeddings** for similarity search. Typically the largest component.

Default: In-memory (`SimpleVectorStore`)  
Production options: Pinecone, Chroma, Weaviate, Qdrant, Milvus, pgvector, etc.

### 7.4 Graph Store
Used specifically by **KnowledgeGraphIndex**. Stores the (subject, predicate, object) triples.

Default: In-memory (`SimpleGraphStore`)  
Production options: Neo4j, Nebula Graph

### 7.5 StorageContext
The unified interface to configure all storage components:

```python
from llama_index.core import StorageContext

storage_context = StorageContext.from_defaults(
    docstore=docstore,
    vector_store=vector_store,
    persist_dir="./storage"
)
```

For persistence: `storage_context.persist()`  
To reload: `StorageContext.from_defaults(persist_dir="./storage")`

---

## 8. Response Modes

Response modes control how LlamaIndex synthesises a final answer from multiple retrieved nodes.

### 8.1 refine
Iterates through each retrieved node sequentially. Starts with an initial answer and **refines**
it with each new node. Makes N LLM calls. Most thorough and highest quality, but most expensive.

**Best for**: Detailed Q&A requiring synthesis across many passages.

### 8.2 compact
Packs as many nodes as possible into each LLM context window, then refines across windows.
Fewer LLM calls than `refine`. Good balance of quality and cost. **Default recommended mode**.

### 8.3 tree_summarize
Builds a tree of summaries bottom-up. Groups nodes, summarises groups, then summarises summaries.
Parallelisable. **Best for**: Long document summarisation, many retrieved nodes.

### 8.4 simple_summarize
Truncates all nodes to fit in one context window, makes a single LLM call. Fastest and cheapest,
but risks losing information via truncation.

### 8.5 accumulate
Generates a response for **each node independently**, then concatenates all responses. N LLM calls.
**Best for**: Comparing perspectives across documents, fact aggregation.

### 8.6 compact_accumulate
Like `accumulate` but packs nodes before generating per-group answers.

---

## 9. Sub-Question Query Engine

The **SubQuestionQueryEngine** handles complex multi-part questions by:

1. Decomposing the original question into simpler sub-questions (via LLM)
2. Routing each sub-question to the most appropriate query engine
3. Answering each sub-question independently (can be parallelised)
4. Combining all sub-answers into a final synthesised response

This is powerful for questions like:
*"Compare the revenue growth of Apple and Microsoft over the last 5 years"*
→ Decomposed into separate Apple and Microsoft sub-queries routed to their respective engines.

```python
from llama_index.core.query_engine import SubQuestionQueryEngine
from llama_index.core.tools import QueryEngineTool

tools = [
    QueryEngineTool.from_defaults(
        query_engine=apple_engine, name="apple_docs",
        description="Apple financial documents and reports"
    ),
    QueryEngineTool.from_defaults(
        query_engine=msft_engine, name="msft_docs",
        description="Microsoft financial documents and reports"
    ),
]
engine = SubQuestionQueryEngine.from_defaults(query_engine_tools=tools)
response = engine.query("Compare Apple and Microsoft revenue growth over 5 years")
```

---

## 10. Metadata Filtering

Metadata filters enable **pre-filtering** of nodes before vector similarity search, allowing
precise scoping of retrieval to specific document subsets.

### Filter Operators
- `==` (equals), `!=` (not equals)
- `>`, `>=`, `<`, `<=` (numeric comparisons)
- `in`, `nin` (value in / not in a list)
- `contains`, `any`, `all` (for array fields)

### Filter Combinations
- `MetadataFilter` — Single condition
- `MetadataFilters` — Multiple conditions combined with AND / OR logic

```python
from llama_index.core.vector_stores import (
    MetadataFilter, MetadataFilters, FilterOperator, FilterCondition
)

filters = MetadataFilters(
    filters=[
        MetadataFilter(key="category", value="finance", operator=FilterOperator.EQ),
        MetadataFilter(key="year", value=2023, operator=FilterOperator.GTE),
    ],
    condition=FilterCondition.AND
)
engine = index.as_query_engine(filters=filters)
```

### Use Cases
- Filter by document source/filename
- Filter by date range
- Filter by document category or type
- Filter by author or department
- Combine with vector search for precision retrieval in large corpora

---

## 11. LlamaIndex Agents

### 11.1 FunctionAgent (FunctionCallingAgent)
Uses structured tool definitions via function-calling APIs. Powered by LLMs with native
function-calling support (GPT-4, Claude 3, Gemini).

The agent loop:
1. Receives a user query
2. Decides which tool(s) to call and with what arguments
3. Executes the tool
4. Observes the result
5. Decides the next action or returns a final answer

```python
from llama_index.core.agent import FunctionCallingAgent
from llama_index.core.tools import FunctionTool

def multiply(a: int, b: int) -> int:
    '''Multiplies two integers and returns the result.'''
    return a * b

tool = FunctionTool.from_defaults(fn=multiply)
agent = FunctionCallingAgent.from_tools([tool], llm=llm, verbose=True)
response = agent.chat("What is 7 times 8?")
```

### 11.2 ReActAgent
Implements the **ReAct (Reasoning + Acting)** pattern. The agent alternates between:
- **Thought** — Reasoning about what to do next
- **Action** — Calling a tool
- **Observation** — Reading the tool's result

Works with any LLM (no native function-calling required). Produces a transparent reasoning trace.

```python
from llama_index.core.agent import ReActAgent

agent = ReActAgent.from_tools(
    [search_tool, calculator_tool],
    llm=llm,
    verbose=True
)
response = agent.chat("Research the latest AI papers and summarize key themes")
```

### 11.3 Query Engine as Agent Tool
Entire query engines can be wrapped as agent tools, giving agents access to document knowledge:

```python
from llama_index.core.tools import QueryEngineTool

tool = QueryEngineTool.from_defaults(
    query_engine=index.as_query_engine(),
    name="company_knowledge_base",
    description="Searches the internal company knowledge base for policies and procedures"
)
```

---

## 12. LlamaParse

**LlamaParse** is LlamaIndex's premium document parsing service, purpose-built for complex
document types that generic PDF parsers struggle with.

### What LlamaParse Handles
- **Complex tables** — Preserves table structure as markdown
- **Multi-column layouts** — Correctly reconstructs column reading order
- **Figures and charts** — Generates textual descriptions of visuals
- **Mathematical formulas** — Renders as LaTeX
- **Mixed content** — PDFs combining text, images, and tables
- **Scanned documents** — Full OCR capability

### How It Works
LlamaParse uses a multimodal LLM pipeline that processes document pages as images combined
with text extraction, producing clean structured Markdown that LlamaIndex ingests accurately.

### Basic Usage
```python
from llama_parse import LlamaParse

parser = LlamaParse(result_type="markdown", api_key="llx-...")
documents = parser.load_data("complex_annual_report.pdf")
```

### Integration with SimpleDirectoryReader
```python
from llama_index.core import SimpleDirectoryReader
from llama_parse import LlamaParse

parser = LlamaParse(result_type="markdown")
file_extractor = {".pdf": parser}  # Use LlamaParse for PDFs only
documents = SimpleDirectoryReader("./docs", file_extractor=file_extractor).load_data()
```

**Pricing**: Free tier (1000 pages/day). Paid tiers for higher volume.  
**API Key**: Available at https://cloud.llamaindex.ai

---

## 13. Observability

### 13.1 Arize Phoenix
**Arize Phoenix** is an open-source LLM observability platform with native LlamaIndex integration.

Features:
- Traces every LLM call, retrieval operation, and embedding computation
- Visual UI for inspecting complete query traces
- Latency and token cost tracking
- Retrieval quality metrics: hit rate, MRR (Mean Reciprocal Rank), NDCG
- Dataset management for evaluation workflows

```python
import phoenix as px
from llama_index.core import set_global_handler

px.launch_app()                       # Start local Phoenix UI
set_global_handler("arize_phoenix")   # Hook into LlamaIndex's callback system
# All subsequent LlamaIndex operations are automatically traced
```

### 13.2 LlamaTrace / LlamaCloud
LlamaIndex's own cloud-based tracing and evaluation platform.

Features:
- End-to-end trace visualisation
- Automatic RAG evaluation (faithfulness, answer relevancy, context precision)
- Dataset curation from production traces for fine-tuning
- A/B testing of pipeline configurations

```python
import llama_index.core
llama_index.core.set_global_handler("llama_cloud", token="llx-...")
```

### 13.3 Other Integrations
- **Langfuse** — Open-source LLM engineering platform with prompt management
- **Weights & Biases (W&B) Weave** — ML experiment tracking and evaluation
- **OpenTelemetry** — Standard distributed tracing protocol
- **Literal AI** — LLM monitoring and evaluation platform

### 13.4 Low-Level Callbacks
For custom observability, LlamaIndex exposes a callback system at every pipeline stage:

```python
from llama_index.core.callbacks import CallbackManager, LlamaDebugHandler

debug_handler = LlamaDebugHandler(print_trace_on_end=True)
callback_manager = CallbackManager([debug_handler])

# Attach to Settings (global) or per-index
from llama_index.core import Settings
Settings.callback_manager = callback_manager
```

---

## Summary

LlamaIndex provides a complete, production-ready stack for building data-aware LLM applications:

```
Raw Data ──► Readers ──► Documents ──► NodeParsers ──► Nodes ──► Index ──► Storage
                                                                               │
                                                                               ▼
         Query ──► QueryEngine ──► Retriever + ResponseSynthesizer ──► Response
                        │
                   Agents orchestrate multiple QueryEngines + external Tools
```

The framework's layered design allows simple high-level APIs for rapid prototyping:

```python
# 5-line RAG pipeline
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
documents = SimpleDirectoryReader("data").load_data()
index = VectorStoreIndex.from_documents(documents)
response = index.as_query_engine().query("What is the main topic?")
print(response)
```

While providing deep customisation hooks at every layer — from custom node parsers and embeddings
to custom retrievers and response synthesisers — for production-grade systems.
