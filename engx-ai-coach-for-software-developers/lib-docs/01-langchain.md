# LangChain — Comprehensive Guide

> **Target audience:** Software developers learning AI engineering.
> **Every code block** is copy-paste runnable Python using GitHub Copilot free auth.

---

## Table of Contents

1. [What is LangChain?](#1-what-is-langchain)
2. [Installation & Setup](#2-installation--setup)
3. [Core Concepts](#3-core-concepts)
4. [LCEL — LangChain Expression Language](#4-lcel--langchain-expression-language)
5. [Document Loaders & Text Splitters](#5-document-loaders--text-splitters)
6. [Embeddings](#6-embeddings)
7. [Vector Stores](#7-vector-stores)
8. [Retrievers](#8-retrievers)
9. [RAG Patterns](#9-rag-patterns)
10. [Memory](#10-memory)
11. [Agents & Tools](#11-agents--tools)
12. [Callbacks & Streaming](#12-callbacks--streaming)
13. [LangSmith — Observability](#13-langsmith--observability)
14. [Interview Q&A](#14-interview-qa)
15. [Comparison with Alternatives](#15-comparison-with-alternatives)

---

## 1. What is LangChain?

LangChain is an **open-source framework** for building applications powered by language models. It provides:

- **Composable primitives** — chains, prompts, retrievers, tools
- **Integrations** — 100+ LLMs, 50+ vector stores, dozens of document loaders
- **Expression Language (LCEL)** — declarative pipe-based composition
- **Ecosystem** — LangSmith (observability), LangGraph (stateful agents), LangServe (deployment)

### When to use LangChain vs alternatives

| Use Case | Recommendation |
|---|---|
| Rapid RAG prototype | LangChain ✅ |
| Production RAG with complex indexing | LlamaIndex ✅ |
| Multi-agent stateful workflows | LangGraph ✅ |
| Simple one-shot LLM call | Raw SDK (OpenAI/Anthropic) ✅ |
| Fine-tuned model inference | Transformers / vLLM ✅ |

### Version History

| Version | Key Changes |
|---|---|
| **0.1** (Jan 2024) | Stabilized core API; introduced LCEL as the primary composition model |
| **0.2** (May 2024) | Deprecated legacy `Chain` classes; moved integrations to `langchain-community`; `langchain-core` split out |
| **0.3** (Sep 2024) | Full Pydantic v2 support; `langchain-openai`, `langchain-anthropic` as first-class packages; removed deprecated APIs |

**Package structure today:**

```
langchain-core        # Base abstractions (Runnable, BaseMessage, etc.)
langchain             # High-level chains, agents, retrievers
langchain-community   # Third-party integrations (community maintained)
langchain-openai      # Official OpenAI integration
langchain-anthropic   # Official Anthropic integration
langchain-google-*    # Official Google integrations
langgraph             # Stateful agent graphs
langsmith             # Observability SDK
```

---

## 2. Installation & Setup

### Install all sub-packages

```bash
pip install langchain langchain-core langchain-community langchain-openai
pip install langchain-anthropic langchain-google-genai
pip install langgraph langsmith
pip install faiss-cpu chromadb qdrant-client
pip install rank-bm25 sentence-transformers tiktoken
pip install pypdf unstructured bs4 GitPython
```

### Environment variables

```bash
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-..."

# Google
export GOOGLE_API_KEY="..."

# LangSmith (optional, for tracing)
export LANGCHAIN_TRACING_V2="true"
export LANGCHAIN_API_KEY="ls__..."
export LANGCHAIN_PROJECT="my-project"
```

### GitHub Copilot Free Auth (use this in all examples below)

GitHub Models gives you free access to GPT-4o, Claude 3.5, Llama, etc. via your GitHub Copilot subscription.

```python
import subprocess
from openai import OpenAI

# Get token from GitHub CLI (run `gh auth login` once first)
token = subprocess.run(
    ["gh", "auth", "token"], capture_output=True, text=True
).stdout.strip()

# Direct OpenAI client
client = OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=token
)

# Quick smoke test
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Say hello in one sentence."}]
)
print(response.choices[0].message.content)
```

### LangChain ChatOpenAI with GitHub Copilot auth

```python
import subprocess
from langchain_openai import ChatOpenAI

token = subprocess.run(
    ["gh", "auth", "token"], capture_output=True, text=True
).stdout.strip()

llm = ChatOpenAI(
    model="gpt-4o",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
    temperature=0.7,
)

# Test it
result = llm.invoke("What is LangChain in one sentence?")
print(result.content)
```

---

## 3. Core Concepts

### 3.1 LLMs vs ChatModels

| Type | Class | Input | Output |
|---|---|---|---|
| LLM | `OpenAI` (legacy) | plain string | plain string |
| ChatModel | `ChatOpenAI` | list of messages | AIMessage |

**ChatModels are the modern standard.** Always use ChatModels.

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

messages = [
    SystemMessage(content="You are a concise technical assistant."),
    HumanMessage(content="What is a transformer neural network?"),
]
response: AIMessage = llm.invoke(messages)
print(response.content)
print(f"Tokens used: {response.usage_metadata}")
```

### 3.2 Messages

```python
from langchain_core.messages import (
    HumanMessage,
    AIMessage,
    SystemMessage,
    ToolMessage,
    FunctionMessage,
)

# Build a conversation manually
history = [
    SystemMessage(content="You are a Python expert."),
    HumanMessage(content="What is a list comprehension?"),
    AIMessage(content="A list comprehension is a concise way to create lists."),
    HumanMessage(content="Give me an example."),
]
# Each message has: .content, .type, .additional_kwargs
for msg in history:
    print(f"[{msg.type}] {msg.content[:60]}")
```

### 3.3 Prompts & PromptTemplates

```python
import subprocess
from langchain_core.prompts import (
    ChatPromptTemplate,
    PromptTemplate,
    MessagesPlaceholder,
)
from langchain_openai import ChatOpenAI

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

# Simple chat prompt
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a {role}. Answer in {language}."),
    ("human", "{question}"),
])

# Inspect the formatted messages before invoking
formatted = prompt.invoke({"role": "chef", "language": "French", "question": "How to boil eggs?"})
print(formatted.messages)

# Chain prompt → llm
chain = prompt | llm
result = chain.invoke({"role": "chef", "language": "English", "question": "How to boil eggs?"})
print(result.content)

# Prompt with message history placeholder (for memory)
prompt_with_history = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    MessagesPlaceholder(variable_name="history"),
    ("human", "{input}"),
])
```

### 3.4 Output Parsers

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain_core.pydantic_v1 import BaseModel, Field
from langchain.output_parsers import PydanticOutputParser

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

# --- StrOutputParser: AIMessage → plain string ---
chain_str = ChatPromptTemplate.from_template("Tell me a joke about {topic}") | llm | StrOutputParser()
print(chain_str.invoke({"topic": "Python"}))

# --- JsonOutputParser: AIMessage → dict ---
json_prompt = ChatPromptTemplate.from_template(
    "Return a JSON object with keys 'name' and 'age' for a fictional person named {name}."
)
chain_json = json_prompt | llm | JsonOutputParser()
result = chain_json.invoke({"name": "Alice"})
print(result, type(result))  # dict

# --- PydanticOutputParser: AIMessage → Pydantic model ---
class Movie(BaseModel):
    title: str = Field(description="Movie title")
    year: int = Field(description="Release year")
    genre: str = Field(description="Primary genre")

parser = PydanticOutputParser(pydantic_object=Movie)
pydantic_prompt = ChatPromptTemplate.from_messages([
    ("system", "Extract movie information. {format_instructions}"),
    ("human", "{text}"),
]).partial(format_instructions=parser.get_format_instructions())

chain_pydantic = pydantic_prompt | llm | parser
movie = chain_pydantic.invoke({"text": "Inception came out in 2010 and is a sci-fi thriller."})
print(movie.title, movie.year, movie.genre)
```

### 3.5 Chains

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableParallel

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

# Simple chain
simple = ChatPromptTemplate.from_template("Summarize: {text}") | llm | StrOutputParser()

# Sequential chain: output of one feeds into the next
summarize = ChatPromptTemplate.from_template("Summarize this in 2 sentences: {text}") | llm | StrOutputParser()
translate = ChatPromptTemplate.from_template("Translate to Spanish: {text}") | llm | StrOutputParser()
sequential = summarize | (lambda s: {"text": s}) | translate

# Parallel chain: run two prompts simultaneously
parallel = RunnableParallel(
    summary=ChatPromptTemplate.from_template("Summarize: {text}") | llm | StrOutputParser(),
    keywords=ChatPromptTemplate.from_template("List 5 keywords from: {text}") | llm | StrOutputParser(),
)

text = "LangChain is a framework for building LLM-powered applications with composable primitives."
print("Sequential:", sequential.invoke({"text": text}))
print("Parallel:", parallel.invoke({"text": text}))
```

---

## 4. LCEL — LangChain Expression Language

LCEL was introduced in LangChain 0.1 to replace imperative `Chain` classes with **declarative, composable pipelines**. Every LCEL object is a `Runnable` with a consistent interface.

### 4.1 Pipe Operator `|`

```python
# chain = A | B | C  means: output of A → input of B → input of C
chain = prompt | llm | parser
result = chain.invoke({"key": "value"})
```

### 4.2 RunnablePassthrough, RunnableParallel, RunnableLambda

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import (
    RunnablePassthrough,
    RunnableParallel,
    RunnableLambda,
)

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

# RunnablePassthrough: pass input unchanged (useful to keep original data alongside)
chain = RunnableParallel(
    original=RunnablePassthrough(),
    upper=RunnableLambda(lambda x: x.upper()),
)
print(chain.invoke("hello world"))
# {'original': 'hello world', 'upper': 'HELLO WORLD'}

# RunnableLambda: wrap any function
def word_count(text: str) -> dict:
    return {"text": text, "word_count": len(text.split())}

analysis_chain = (
    RunnableLambda(word_count)
    | RunnableLambda(lambda d: f"The text has {d['word_count']} words: {d['text'][:50]}...")
    | ChatPromptTemplate.from_template("Rewrite this fact more poetically: {input}")
    | llm
    | StrOutputParser()
)
# Note: ChatPromptTemplate expects dict; adjust input key as needed
```

### 4.3 Branching and Routing

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableLambda, RunnableBranch

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
str_parser = StrOutputParser()

code_chain = ChatPromptTemplate.from_template("Answer this coding question: {question}") | llm | str_parser
general_chain = ChatPromptTemplate.from_template("Answer this general question: {question}") | llm | str_parser

def is_code_question(x):
    keywords = ["python", "code", "function", "bug", "error", "class", "loop"]
    return any(k in x["question"].lower() for k in keywords)

branch = RunnableBranch(
    (is_code_question, code_chain),
    general_chain,  # default
)

print(branch.invoke({"question": "How do I write a Python function?"}))
print(branch.invoke({"question": "What is the capital of France?"}))
```

### 4.4 Streaming

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com", streaming=True)

chain = ChatPromptTemplate.from_template("Write a haiku about {topic}") | llm | StrOutputParser()

print("Streaming output:")
for chunk in chain.stream({"topic": "machine learning"}):
    print(chunk, end="", flush=True)
print()
```

### 4.5 Async with `.ainvoke()`

```python
import asyncio
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
chain = ChatPromptTemplate.from_template("Explain {concept} briefly.") | llm | StrOutputParser()

async def main():
    # Single async call
    result = await chain.ainvoke({"concept": "gradient descent"})
    print(result)

    # Concurrent async calls
    results = await asyncio.gather(
        chain.ainvoke({"concept": "attention mechanism"}),
        chain.ainvoke({"concept": "tokenization"}),
        chain.ainvoke({"concept": "embeddings"}),
    )
    for r in results:
        print("-", r[:80])

asyncio.run(main())
```

### 4.6 Batch Processing

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
chain = ChatPromptTemplate.from_template("Capital of {country}?") | llm | StrOutputParser()

inputs = [{"country": c} for c in ["France", "Germany", "Japan", "Brazil"]]
results = chain.batch(inputs, config={"max_concurrency": 4})
for country, capital in zip(["France", "Germany", "Japan", "Brazil"], results):
    print(f"{country}: {capital.strip()}")
```

### 4.7 Full Example: Multi-Step Document Analysis Chain

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableParallel, RunnablePassthrough, RunnableLambda

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
str_parser = StrOutputParser()

# Step 1: Parallel analysis
parallel_analysis = RunnableParallel(
    document=RunnablePassthrough(),
    summary=ChatPromptTemplate.from_template("Summarize in 2 sentences: {document}") | llm | str_parser,
    sentiment=ChatPromptTemplate.from_template(
        "Classify sentiment as POSITIVE/NEGATIVE/NEUTRAL for: {document}. Reply with one word."
    ) | llm | str_parser,
    topics=ChatPromptTemplate.from_template(
        "List 3 main topics as a comma-separated list for: {document}"
    ) | llm | str_parser,
)

# Step 2: Combine results into a report
def format_report(data: dict) -> str:
    return (
        f"DOCUMENT ANALYSIS REPORT\n"
        f"{'='*40}\n"
        f"Summary: {data['summary']}\n"
        f"Sentiment: {data['sentiment']}\n"
        f"Topics: {data['topics']}\n"
    )

# Step 3: Generate actionable insights
insights_prompt = ChatPromptTemplate.from_template(
    "Based on this analysis report, suggest 2 actionable next steps:\n{report}"
)

full_chain = (
    parallel_analysis
    | RunnableLambda(format_report)
    | (lambda report: {"report": report})
    | insights_prompt
    | llm
    | str_parser
)

doc = """
The quarterly earnings report shows a 15% increase in revenue driven by cloud services.
However, operating costs rose by 22% due to infrastructure investments. Customer retention
improved by 8% while new customer acquisition declined by 3%.
"""

result = full_chain.invoke({"document": doc})
print(result)
```

---

## 5. Document Loaders & Text Splitters

### 5.1 Document Loaders

```python
# ---- TextLoader ----
from langchain_community.document_loaders import TextLoader

loader = TextLoader("README.md", encoding="utf-8")
docs = loader.load()
print(f"Loaded {len(docs)} doc(s), {len(docs[0].page_content)} chars")

# ---- PyPDFLoader ----
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("sample.pdf")
pages = loader.load()  # one Document per page
print(f"PDF has {len(pages)} pages")

# ---- WebBaseLoader ----
from langchain_community.document_loaders import WebBaseLoader

loader = WebBaseLoader("https://python.langchain.com/docs/introduction/")
web_docs = loader.load()
print(web_docs[0].page_content[:200])

# ---- GitLoader (load code from a repo) ----
from langchain_community.document_loaders import GitLoader

loader = GitLoader(
    repo_path="./my-repo",          # local path (cloned repo)
    branch="main",
    file_filter=lambda path: path.endswith(".py"),
)
code_docs = loader.load()
print(f"Loaded {len(code_docs)} Python files")

# ---- DirectoryLoader (bulk load) ----
from langchain_community.document_loaders import DirectoryLoader

loader = DirectoryLoader("./docs", glob="**/*.md", loader_cls=TextLoader)
all_docs = loader.load()
```

### 5.2 Text Splitters

```python
from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    MarkdownTextSplitter,
    TokenTextSplitter,
    CharacterTextSplitter,
)

sample_text = "LangChain is a framework. " * 200  # simulate long document

# RecursiveCharacterTextSplitter: tries paragraphs → sentences → words
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    separators=["\n\n", "\n", ". ", " ", ""],
)
chunks = splitter.split_text(sample_text)
print(f"RecursiveSplitter: {len(chunks)} chunks, first chunk: {len(chunks[0])} chars")

# MarkdownTextSplitter: respects markdown headers
md_splitter = MarkdownTextSplitter(chunk_size=1000, chunk_overlap=100)
md_text = "# Title\n\n## Section 1\n\nContent here.\n\n## Section 2\n\nMore content."
md_chunks = md_splitter.split_text(md_text)
print(f"MarkdownSplitter: {len(md_chunks)} chunks")

# TokenTextSplitter: split by token count (accurate for LLM context limits)
token_splitter = TokenTextSplitter(chunk_size=256, chunk_overlap=20)
token_chunks = token_splitter.split_text(sample_text)
print(f"TokenSplitter: {len(token_chunks)} chunks")
```

### 5.3 Full Example: Load PDF → Split → Embed

```python
import subprocess
import os
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

# For demo, create a text file instead of a real PDF
with open("demo_doc.txt", "w") as f:
    f.write("LangChain enables building LLM applications. " * 100)

from langchain_community.document_loaders import TextLoader

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

# 1. Load
loader = TextLoader("demo_doc.txt")
raw_docs = loader.load()

# 2. Split
splitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=20)
chunks = splitter.split_documents(raw_docs)
print(f"Split into {len(chunks)} chunks")

# 3. Embed & store
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
)
vectorstore = FAISS.from_documents(chunks, embeddings)
print("Vector store created!")

# 4. Query
results = vectorstore.similarity_search("LangChain applications", k=2)
for doc in results:
    print(doc.page_content[:100])

# Cleanup
os.remove("demo_doc.txt")
```

---

## 6. Embeddings

### 6.1 OpenAIEmbeddings (GitHub Copilot free auth)

```python
import subprocess
from langchain_openai import OpenAIEmbeddings

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small",   # or text-embedding-3-large
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
)

# Embed a single string
vector = embeddings.embed_query("What is machine learning?")
print(f"Embedding dimension: {len(vector)}")  # 1536 for 3-small

# Embed multiple documents
docs = ["LangChain is great", "Python is versatile", "AI is transforming software"]
vectors = embeddings.embed_documents(docs)
print(f"Embedded {len(vectors)} documents")
```

### 6.2 HuggingFaceEmbeddings (free, local, no API key)

```python
# pip install sentence-transformers
from langchain_community.embeddings import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(
    model_name="all-MiniLM-L6-v2",   # small, fast, 384-dim
    # model_name="BAAI/bge-large-en-v1.5"  # larger, better quality
    model_kwargs={"device": "cpu"},   # use "cuda" for GPU
    encode_kwargs={"normalize_embeddings": True},
)

vector = embeddings.embed_query("What is machine learning?")
print(f"HuggingFace embedding dim: {len(vector)}")  # 384
```

### 6.3 Embedding Comparison Table

| Model | Dimensions | Cost | Quality | Speed |
|---|---|---|---|---|
| `text-embedding-3-small` | 1536 | Low ($) | Good | Fast |
| `text-embedding-3-large` | 3072 | Medium ($$) | Excellent | Medium |
| `text-embedding-ada-002` | 1536 | Low ($) | Good (legacy) | Fast |
| `all-MiniLM-L6-v2` (HF) | 384 | Free | Decent | Very Fast |
| `BAAI/bge-large-en-v1.5` (HF) | 1024 | Free | Excellent | Medium |
| `nomic-embed-text` (Ollama) | 768 | Free | Good | Fast |

### 6.4 Caching with CacheBackedEmbeddings

```python
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain.embeddings import CacheBackedEmbeddings
from langchain.storage import LocalFileStore

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

underlying = OpenAIEmbeddings(
    model="text-embedding-3-small",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
)

# Cache to local filesystem (avoids re-computing same embeddings)
store = LocalFileStore("./.embedding_cache")
cached_embeddings = CacheBackedEmbeddings.from_bytes_store(
    underlying_embeddings=underlying,
    document_embedding_cache=store,
    namespace=underlying.model,
)

# First call: hits the API
v1 = cached_embeddings.embed_query("Hello world")
# Second call: returns from cache instantly
v2 = cached_embeddings.embed_query("Hello world")
print(f"Cached: {v1 == v2}")  # True
```

---

## 7. Vector Stores

### 7.1 FAISS (free, in-memory/local)

```python
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

# CREATE
docs = [
    Document(page_content="LangChain is a framework for LLM apps", metadata={"source": "intro"}),
    Document(page_content="FAISS is a fast similarity search library", metadata={"source": "faiss"}),
    Document(page_content="Vector databases store embeddings", metadata={"source": "vectors"}),
    Document(page_content="RAG combines retrieval with generation", metadata={"source": "rag"}),
]
db = FAISS.from_documents(docs, embeddings)

# READ (similarity search)
results = db.similarity_search("What is RAG?", k=2)
for doc in results:
    print(doc.page_content)

# READ with scores
results_scored = db.similarity_search_with_score("embedding storage", k=2)
for doc, score in results_scored:
    print(f"Score: {score:.4f} | {doc.page_content}")

# UPDATE (add new documents)
new_docs = [Document(page_content="LangGraph builds stateful agent workflows")]
db.add_documents(new_docs)

# SAVE and LOAD
db.save_local("faiss_index")
db2 = FAISS.load_local("faiss_index", embeddings, allow_dangerous_deserialization=True)

# DELETE (rebuild without doc — FAISS doesn't support delete; workaround below)
# Filter approach: use metadata to skip unwanted docs at query time
results_filtered = db.similarity_search(
    "LangChain", k=2, filter={"source": "intro"}
)
```

### 7.2 ChromaDB (free, embedded or server)

```python
# pip install chromadb
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [
    Document(page_content="ChromaDB is an open-source vector database", metadata={"id": "1"}),
    Document(page_content="It supports persistent storage", metadata={"id": "2"}),
]

# Persistent ChromaDB (saves to disk)
db = Chroma.from_documents(
    docs, embeddings,
    persist_directory="./chroma_db",
    collection_name="my_collection",
)

results = db.similarity_search("persistent storage", k=1)
print(results[0].page_content)
```

### 7.3 Qdrant (free self-hosted)

```python
# Run Qdrant: docker run -p 6333:6333 qdrant/qdrant
# pip install qdrant-client
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import Qdrant
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [Document(page_content="Qdrant is a production-grade vector store")]
db = Qdrant.from_documents(
    docs, embeddings,
    url="http://localhost:6333",
    collection_name="langchain_docs",
)
results = db.similarity_search("vector store", k=1)
print(results[0].page_content)
```

### 7.4 Pinecone (paid, managed)

```python
# pip install pinecone-client langchain-pinecone
import os
from langchain_pinecone import PineconeVectorStore
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
db = PineconeVectorStore.from_existing_index(
    index_name="my-index",
    embedding=embeddings,
    namespace="default",
)
results = db.similarity_search("query", k=3)
```

---

## 8. Retrievers

### 8.1 VectorStoreRetriever

```python
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)
docs = [
    Document(page_content="Python supports list comprehensions"),
    Document(page_content="JavaScript uses arrow functions"),
    Document(page_content="Rust ensures memory safety"),
]
db = FAISS.from_documents(docs, embeddings)

# Basic retriever
retriever = db.as_retriever(search_type="similarity", search_kwargs={"k": 2})
results = retriever.invoke("Python programming")
for doc in results:
    print(doc.page_content)

# MMR retriever (maximizes diversity)
mmr_retriever = db.as_retriever(
    search_type="mmr",
    search_kwargs={"k": 2, "fetch_k": 10, "lambda_mult": 0.5}
)
```

### 8.2 BM25Retriever (keyword-based)

```python
# pip install rank-bm25
from langchain_community.retrievers import BM25Retriever
from langchain_core.documents import Document

docs = [
    Document(page_content="LangChain is a framework for building LLM applications"),
    Document(page_content="FAISS enables fast approximate nearest neighbor search"),
    Document(page_content="RAG combines retrieval augmented generation"),
    Document(page_content="LangChain supports many vector store integrations"),
]

bm25_retriever = BM25Retriever.from_documents(docs, k=2)
results = bm25_retriever.invoke("LangChain vector store")
for doc in results:
    print(doc.page_content)
```

### 8.3 EnsembleRetriever (Hybrid BM25 + Vector)

```python
import subprocess
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.retrievers import BM25Retriever
from langchain.retrievers import EnsembleRetriever
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [
    Document(page_content="LangChain LCEL uses pipe operators for composition"),
    Document(page_content="Vector embeddings capture semantic meaning"),
    Document(page_content="BM25 is a keyword-based retrieval algorithm"),
    Document(page_content="Hybrid search combines BM25 and vector similarity"),
    Document(page_content="LangChain integrates with many LLM providers"),
]

bm25 = BM25Retriever.from_documents(docs, k=2)
faiss_db = FAISS.from_documents(docs, embeddings)
vector = faiss_db.as_retriever(search_kwargs={"k": 2})

# Reciprocal Rank Fusion with weighted combination
ensemble = EnsembleRetriever(
    retrievers=[bm25, vector],
    weights=[0.4, 0.6],   # weight vector search higher for semantic queries
)
results = ensemble.invoke("LangChain semantic pipe operator")
for doc in results:
    print(doc.page_content)
```

### 8.4 MultiQueryRetriever

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.retrievers import MultiQueryRetriever
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [Document(page_content=t) for t in [
    "RAG stands for Retrieval Augmented Generation",
    "RAG improves LLM accuracy by grounding responses in retrieved context",
    "Vector stores enable semantic document retrieval",
    "LangChain provides a complete RAG pipeline",
]]
db = FAISS.from_documents(docs, embeddings)

# MultiQueryRetriever generates 3 query variants, unions results
retriever = MultiQueryRetriever.from_llm(
    retriever=db.as_retriever(search_kwargs={"k": 2}),
    llm=llm
)
results = retriever.invoke("How does RAG work?")
print(f"Found {len(results)} unique documents")
for doc in results:
    print("-", doc.page_content[:80])
```

### 8.5 ContextualCompressionRetriever

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [Document(page_content=(
    "LangChain was created by Harrison Chase in 2022. "
    "It provides tools for building LLM applications. "
    "The framework supports Python and JavaScript. "
    "LangSmith is their observability platform."
))]
db = FAISS.from_documents(docs, embeddings)
base_retriever = db.as_retriever(search_kwargs={"k": 1})

# Compressor extracts only the relevant portion of each document
compressor = LLMChainExtractor.from_llm(llm)
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=base_retriever
)

compressed = compression_retriever.invoke("Who created LangChain?")
for doc in compressed:
    print(doc.page_content)  # Only the relevant sentence
```

### 8.6 Full Hybrid Retrieval Example

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.retrievers import BM25Retriever
from langchain.retrievers import EnsembleRetriever, ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

knowledge_base = [
    Document(page_content="LCEL uses pipe operators to compose runnables in LangChain"),
    Document(page_content="RunnableParallel executes multiple runnables simultaneously"),
    Document(page_content="LangSmith provides tracing and evaluation for LangChain apps"),
    Document(page_content="ChromaDB is a free open-source vector store"),
    Document(page_content="BM25 is a classical keyword relevance scoring algorithm"),
]

# Build hybrid retriever
bm25 = BM25Retriever.from_documents(knowledge_base, k=2)
faiss_db = FAISS.from_documents(knowledge_base, embeddings)
vector = faiss_db.as_retriever(search_kwargs={"k": 2})
ensemble = EnsembleRetriever(retrievers=[bm25, vector], weights=[0.3, 0.7])

# Add compression on top
compressor = LLMChainExtractor.from_llm(llm)
final_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=ensemble
)

query = "How does LangChain compose parallel operations?"
results = final_retriever.invoke(query)
print(f"Query: {query}")
for i, doc in enumerate(results, 1):
    print(f"[{i}] {doc.page_content}")
```

---

## 9. RAG Patterns

### 9.1 Basic RAG Chain

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

# Build knowledge base
docs = [
    Document(page_content="LangChain 0.3 requires Python 3.9+ and uses Pydantic v2"),
    Document(page_content="LCEL was introduced to replace legacy Chain classes"),
    Document(page_content="LangSmith is used for debugging and evaluating LLM applications"),
]
vectorstore = FAISS.from_documents(docs, embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 2})

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

rag_prompt = ChatPromptTemplate.from_template("""
Answer the question based only on the context below. If you don't know, say "I don't know."

Context:
{context}

Question: {question}
""")

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | rag_prompt
    | llm
    | StrOutputParser()
)

print(rag_chain.invoke("What Python version does LangChain 0.3 require?"))
```

### 9.2 Conversational RAG with History

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [
    Document(page_content="LangChain supports OpenAI, Anthropic, and many other LLM providers"),
    Document(page_content="You can use ChatOpenAI class for OpenAI chat models"),
    Document(page_content="ChatAnthropic class is used for Claude models"),
]
vectorstore = FAISS.from_documents(docs, embeddings)
retriever = vectorstore.as_retriever()

# Prompt to reformulate question with chat history context
contextualize_q_prompt = ChatPromptTemplate.from_messages([
    ("system", "Given the chat history and the latest question, "
               "reformulate a standalone question. Return only the question."),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])
history_aware_retriever = create_history_aware_retriever(llm, retriever, contextualize_q_prompt)

# QA prompt
qa_prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer using the context below:\n\n{context}"),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])
question_answer_chain = create_stuff_documents_chain(llm, qa_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)

# Simulate multi-turn conversation
chat_history = []

q1 = "What LLM providers does LangChain support?"
r1 = rag_chain.invoke({"input": q1, "chat_history": chat_history})
print("Q1:", r1["answer"])
chat_history += [HumanMessage(content=q1), AIMessage(content=r1["answer"])]

q2 = "Which class do I use for the second one you mentioned?"  # refers to Anthropic
r2 = rag_chain.invoke({"input": q2, "chat_history": chat_history})
print("Q2:", r2["answer"])
```

### 9.3 Full Conversational RAG with SqliteSaver

```python
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.chat_history import BaseChatMessageHistory
from langchain_community.chat_message_histories import SQLChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_core.documents import Document

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small", api_key=token,
    base_url="https://models.inference.ai.azure.com"
)

docs = [Document(page_content=t) for t in [
    "LangChain LCEL uses the pipe | operator",
    "RunnableWithMessageHistory adds persistent memory to any chain",
    "SqliteSaver persists chat history to a SQLite database file",
]]
db = FAISS.from_documents(docs, embeddings)
retriever = db.as_retriever()

contextualize_prompt = ChatPromptTemplate.from_messages([
    ("system", "Reformulate as standalone question given history."),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])
qa_prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer from context:\n\n{context}"),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])

history_aware_retriever = create_history_aware_retriever(llm, retriever, contextualize_prompt)
qa_chain = create_stuff_documents_chain(llm, qa_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, qa_chain)

def get_session_history(session_id: str) -> BaseChatMessageHistory:
    return SQLChatMessageHistory(session_id, "sqlite:///chat_history.db")

conversational_rag = RunnableWithMessageHistory(
    rag_chain,
    get_session_history,
    input_messages_key="input",
    history_messages_key="chat_history",
    output_messages_key="answer",
)

config = {"configurable": {"session_id": "user_123"}}
r = conversational_rag.invoke({"input": "What operator does LCEL use?"}, config=config)
print(r["answer"])
# History is persisted to SQLite — survives process restarts
```

---

## 10. Memory

### 10.1 ConversationBufferMemory

```python
# NOTE: ConversationBufferMemory is legacy — use RunnableWithMessageHistory for new code.
# Shown here for reference when working with legacy chains.
from langchain.memory import ConversationBufferMemory
from langchain_core.messages import HumanMessage, AIMessage

memory = ConversationBufferMemory(return_messages=True)
memory.chat_memory.add_user_message("Hi, I'm Alice")
memory.chat_memory.add_ai_message("Hello Alice! How can I help?")
memory.chat_memory.add_user_message("What's my name?")

# Load the memory variables
loaded = memory.load_memory_variables({})
for msg in loaded["history"]:
    print(f"[{msg.type}] {msg.content}")
```

### 10.2 ConversationSummaryMemory

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationSummaryMemory

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

# Summarizes conversation as it grows (cheaper for long conversations)
memory = ConversationSummaryMemory(llm=llm, return_messages=True)
memory.save_context({"input": "I am building a RAG pipeline for legal documents"},
                    {"output": "That's a great use case. What kind of queries?"})
memory.save_context({"input": "Contract review and compliance checking"},
                    {"output": "I recommend using ContextualCompressionRetriever for that."})

summary = memory.load_memory_variables({})
print("Summary:", summary)
```

### 10.3 RunnableWithMessageHistory (modern approach)

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_community.chat_message_histories import ChatMessageHistory

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant. Be concise."),
    MessagesPlaceholder(variable_name="history"),
    ("human", "{input}"),
])

chain = prompt | llm | StrOutputParser()

# In-memory store (replace with SQLChatMessageHistory for persistence)
store = {}
def get_session_history(session_id: str) -> ChatMessageHistory:
    if session_id not in store:
        store[session_id] = ChatMessageHistory()
    return store[session_id]

with_memory = RunnableWithMessageHistory(
    chain,
    get_session_history,
    input_messages_key="input",
    history_messages_key="history",
)

cfg = {"configurable": {"session_id": "demo_session"}}
print(with_memory.invoke({"input": "My name is Bob."}, config=cfg))
print(with_memory.invoke({"input": "What is my name?"}, config=cfg))
print(with_memory.invoke({"input": "What was my first message?"}, config=cfg))
```

---

## 11. Agents & Tools

### 11.1 Custom Tools with @tool decorator

```python
import subprocess
import math
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

@tool
def calculator(expression: str) -> str:
    """Evaluate a mathematical expression. Input: a valid Python math expression string."""
    try:
        result = eval(expression, {"__builtins__": {}}, {"math": math, **vars(math)})
        return str(result)
    except Exception as e:
        return f"Error: {e}"

@tool
def word_counter(text: str) -> str:
    """Count words and characters in the given text."""
    words = len(text.split())
    chars = len(text)
    return f"Words: {words}, Characters: {chars}"

@tool
def temperature_converter(celsius: float) -> str:
    """Convert a temperature from Celsius to Fahrenheit and Kelvin."""
    f = celsius * 9/5 + 32
    k = celsius + 273.15
    return f"{celsius}°C = {f:.1f}°F = {k:.2f}K"

tools = [calculator, word_counter, temperature_converter]

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant with access to tools. Use them when needed."),
    MessagesPlaceholder(variable_name="chat_history", optional=True),
    ("human", "{input}"),
    MessagesPlaceholder(variable_name="agent_scratchpad"),
])

agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

result = executor.invoke({"input": "What is the square root of 144, and what is 25°C in Fahrenheit?"})
print(result["output"])
```

### 11.2 Structured Tools with Pydantic

```python
import subprocess
from pydantic import BaseModel, Field
from langchain_core.tools import StructuredTool
from langchain_openai import ChatOpenAI
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

class SearchInput(BaseModel):
    query: str = Field(description="The search query")
    max_results: int = Field(default=3, description="Maximum number of results to return")

def mock_web_search(query: str, max_results: int = 3) -> str:
    """Simulate a web search (replace with real API in production)."""
    results = [
        f"Result {i+1} for '{query}': Example article about {query} - detail {i+1}"
        for i in range(max_results)
    ]
    return "\n".join(results)

search_tool = StructuredTool.from_function(
    func=mock_web_search,
    name="web_search",
    description="Search the web for information on a topic",
    args_schema=SearchInput,
)

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a research assistant. Use tools to find information."),
    ("human", "{input}"),
    MessagesPlaceholder(variable_name="agent_scratchpad"),
])

agent = create_tool_calling_agent(llm, [search_tool], prompt)
executor = AgentExecutor(agent=agent, tools=[search_tool], verbose=False)

result = executor.invoke({"input": "Search for information about LangChain LCEL and return 2 results"})
print(result["output"])
```

### 11.3 Full Agent: Web Search + Calculator + Code Executor

```python
import subprocess
import math
import ast
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com", temperature=0)

@tool
def web_search(query: str) -> str:
    """Search the web for up-to-date information about a topic."""
    # In production, use: from langchain_community.tools import DuckDuckGoSearchRun
    return f"[Simulated search results for: {query}]\n- Article 1: Overview of {query}\n- Article 2: Deep dive into {query}"

@tool
def calculator(expression: str) -> str:
    """Safely evaluate a mathematical expression (e.g., '2 ** 10', 'math.sqrt(256)')."""
    try:
        safe_globals = {k: getattr(math, k) for k in dir(math) if not k.startswith("_")}
        return str(eval(expression, {"__builtins__": {}}, safe_globals))
    except Exception as e:
        return f"Calculation error: {e}"

@tool
def python_executor(code: str) -> str:
    """Execute simple Python code and return the output. Only safe operations allowed."""
    try:
        tree = ast.parse(code, mode="exec")
        # Block imports for safety
        for node in ast.walk(tree):
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                return "Error: imports not allowed"
        local_vars = {}
        exec(compile(tree, "<string>", "exec"), {"__builtins__": {"print": print, "len": len, "range": range}}, local_vars)
        return str(local_vars.get("result", "Code executed (no 'result' variable set)"))
    except Exception as e:
        return f"Execution error: {e}"

tools = [web_search, calculator, python_executor]

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a capable assistant. Use your tools to answer accurately. "
               "Show your reasoning and tool usage clearly."),
    ("human", "{input}"),
    MessagesPlaceholder(variable_name="agent_scratchpad"),
])

agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True, max_iterations=5)

result = executor.invoke({
    "input": "What is 2^20? Then search for information about the Python language."
})
print("\nFinal Answer:", result["output"])
```

---

## 12. Callbacks & Streaming

### 12.1 StreamingStdOutCallbackHandler

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.callbacks import StreamingStdOutCallbackHandler
from langchain_core.prompts import ChatPromptTemplate

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

llm = ChatOpenAI(
    model="gpt-4o",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
    streaming=True,
    callbacks=[StreamingStdOutCallbackHandler()],
)

chain = ChatPromptTemplate.from_template("Write 3 tips for {topic}") | llm
# Output streams to stdout automatically via the callback
result = chain.invoke({"topic": "writing clean Python code"})
```

### 12.2 Custom Callback Handler

```python
import subprocess
import time
from langchain_openai import ChatOpenAI
from langchain_core.callbacks import BaseCallbackHandler
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.outputs import LLMResult
from typing import Any, Dict, List, Union

class TokenCounterCallback(BaseCallbackHandler):
    """Callback that counts tokens and measures latency."""

    def __init__(self):
        self.token_count = 0
        self.start_time = None
        self.chunks = []

    def on_llm_start(self, serialized: Dict[str, Any], prompts: List[str], **kwargs):
        self.start_time = time.time()
        print(f"[Callback] LLM started | Prompt length: {len(prompts[0])} chars")

    def on_llm_new_token(self, token: str, **kwargs):
        self.token_count += 1
        self.chunks.append(token)

    def on_llm_end(self, response: LLMResult, **kwargs):
        elapsed = time.time() - self.start_time
        print(f"\n[Callback] Done | Tokens: {self.token_count} | Latency: {elapsed:.2f}s")

    def on_llm_error(self, error: Union[Exception, KeyboardInterrupt], **kwargs):
        print(f"[Callback] Error: {error}")

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
callback = TokenCounterCallback()

llm = ChatOpenAI(
    model="gpt-4o",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
    streaming=True,
    callbacks=[callback],
)

result = llm.invoke("List 3 Python best practices.")
print(f"Total tokens streamed: {callback.token_count}")
```

### 12.3 Token-by-Token Streaming via .stream()

```python
import subprocess
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com", streaming=True)

chain = (
    ChatPromptTemplate.from_template("Explain {topic} step by step.")
    | llm
    | StrOutputParser()
)

print("--- Streaming Response ---")
full_response = ""
for chunk in chain.stream({"topic": "how a neural network learns"}):
    print(chunk, end="", flush=True)
    full_response += chunk
print(f"\n--- Done ({len(full_response)} chars) ---")
```

---

## 13. LangSmith — Observability

### 13.1 Setup and Configuration

```bash
pip install langsmith

export LANGCHAIN_TRACING_V2="true"
export LANGCHAIN_API_KEY="ls__your_key_here"
export LANGCHAIN_PROJECT="my-rag-project"   # optional, defaults to "default"
```

```python
# Once env vars are set, ALL LangChain calls are automatically traced
import subprocess
import os
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate

os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__your_key_here"  # replace with real key

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token,
                 base_url="https://models.inference.ai.azure.com")

chain = ChatPromptTemplate.from_template("Answer: {q}") | llm
result = chain.invoke({"q": "What is LangSmith?"})
# This run is now visible at https://smith.langchain.com
```

### 13.2 Manual Tracing with @traceable

```python
from langsmith import traceable

@traceable(name="my_rag_retrieval", run_type="retriever")
def retrieve_docs(query: str) -> list:
    # Your retrieval logic here
    return [{"content": f"Result for: {query}"}]

@traceable(name="my_rag_generation", run_type="llm")
def generate_answer(query: str, context: list) -> str:
    return f"Based on context, here is the answer to: {query}"

@traceable(name="full_rag_pipeline")
def rag_pipeline(query: str) -> str:
    docs = retrieve_docs(query)
    return generate_answer(query, docs)

result = rag_pipeline("What is RAG?")
```

### 13.3 Evaluating RAG Quality

```python
from langsmith import Client
from langsmith.evaluation import evaluate

client = Client()

# 1. Create a dataset
dataset = client.create_dataset("rag-eval-dataset", description="RAG Q&A evaluation")
examples = [
    {"inputs": {"question": "What is LangChain?"}, "outputs": {"answer": "A framework for LLM apps"}},
    {"inputs": {"question": "What is LCEL?"}, "outputs": {"answer": "LangChain Expression Language using pipe operators"}},
]
for ex in examples:
    client.create_example(inputs=ex["inputs"], outputs=ex["outputs"], dataset_id=dataset.id)

# 2. Define your RAG chain (replace with real chain)
def rag_chain(inputs: dict) -> dict:
    return {"answer": f"LangChain answer for: {inputs['question']}"}

# 3. Define evaluators
from langsmith.evaluation import LangChainStringEvaluator
correctness_evaluator = LangChainStringEvaluator("qa")

# 4. Run evaluation
results = evaluate(
    rag_chain,
    data="rag-eval-dataset",
    evaluators=[correctness_evaluator],
    experiment_prefix="rag-v1",
)
print(results.to_pandas())
```

### 13.4 Free Tier Limits

| Feature | Free Tier |
|---|---|
| Traces / month | 5,000 |
| Datasets | Unlimited |
| Evaluations | Unlimited (use own LLM) |
| Team members | 1 |
| Retention | 14 days |

---

## 14. Interview Q&A

**Q1: What is LCEL and why was it introduced?**

LCEL (LangChain Expression Language) is a declarative composition system using the pipe operator `|`. It was introduced in LangChain 0.1 to replace imperative Chain classes. Benefits: built-in streaming, async, batch processing, automatic tracing, and consistent `.invoke()/.stream()/.batch()/.ainvoke()` interface across all components.

---

**Q2: Difference between a Chain and LCEL?**

| Legacy Chain | LCEL |
|---|---|
| Class-based (e.g., `LLMChain`) | Pipe-based (`prompt \| llm \| parser`) |
| Limited streaming support | First-class streaming |
| Hard to compose | Composable by design |
| Deprecated in 0.2+ | Current standard |

---

**Q3: How do you add memory to a RAG chain?**

Use `RunnableWithMessageHistory` wrapping the RAG chain, with a `get_session_history` function that returns a `BaseChatMessageHistory` (e.g., `SQLChatMessageHistory` for persistence). The chain must have `input_messages_key` and `history_messages_key` configured. Also use `create_history_aware_retriever` to reformulate queries with chat history context.

---

**Q4: What is the difference between a Retriever and a VectorStore?**

| VectorStore | Retriever |
|---|---|
| Storage layer (CRUD operations) | Query interface only |
| `db.similarity_search(query, k=3)` | `retriever.invoke(query)` |
| Provider-specific API | Unified `Runnable` interface |
| `FAISS`, `Chroma`, `Qdrant` | Any class implementing `BaseRetriever` |

A VectorStore can create a Retriever via `.as_retriever()`. Retrievers are composable in LCEL chains; VectorStores are not directly.

---

**Q5: How does MultiQueryRetriever improve retrieval quality?**

It uses an LLM to generate 3–5 paraphrased versions of the user query, retrieves documents for each, then takes the union (deduped). This overcomes the limitation of single-query vector search missing relevant documents due to phrasing mismatch. The trade-off is more LLM calls per retrieval.

---

**Q6: What is ContextualCompressionRetriever?**

It wraps a base retriever and passes each retrieved document through a compressor (e.g., `LLMChainExtractor`) that extracts only the portions relevant to the query. This reduces noise in the context window, improves answer quality, and saves tokens. Useful when documents are long and only partially relevant.

---

**Q7: How do you implement streaming in LangChain?**

Three approaches:
1. **LCEL `.stream()`** — iterate over chunks: `for chunk in chain.stream(input): print(chunk, end="")`
2. **Callbacks** — pass `StreamingStdOutCallbackHandler()` or custom handler to the LLM
3. **Async streaming** — `async for chunk in chain.astream(input): ...`

The LLM must have `streaming=True` set for token-level streaming.

---

**Q8: What are Tools in LangChain agents?**

Tools are functions exposed to an agent with a name, description, and schema. The agent's LLM reads the description to decide when to call each tool. Defined via `@tool` decorator, `StructuredTool.from_function()`, or pre-built integrations (DuckDuckGo, Wikipedia, Python REPL, etc.). The agent uses the tool's output to form its final response.

---

**Q9: How do you evaluate a RAG system with LangSmith?**

1. Create a labeled dataset with `(question, expected_answer)` pairs in LangSmith
2. Define evaluators: `LangChainStringEvaluator("qa")` for correctness, custom evaluators for faithfulness/relevance
3. Run `evaluate(rag_chain, data="dataset-name", evaluators=[...])` 
4. View results in the LangSmith UI, compare across experiment runs

---

**Q10: How do you use LangChain with local models (Ollama)?**

```python
# pip install langchain-ollama  (run: ollama pull llama3.2)
from langchain_ollama import ChatOllama, OllamaEmbeddings

llm = ChatOllama(model="llama3.2", temperature=0.7)
embeddings = OllamaEmbeddings(model="nomic-embed-text")

result = llm.invoke("What is LangChain?")
print(result.content)
```

Ollama runs models locally — no API key, no cost, works offline.

---

**Q11: What is RunnableParallel and when to use it?**

`RunnableParallel` executes multiple runnables **simultaneously** on the same input, returning a dict of results. Use when you need to run independent LLM calls in parallel (e.g., summarize + classify + extract keywords from the same document). Reduces total latency from `sum(latencies)` to `max(latency)`.

```python
parallel = RunnableParallel(summary=chain_a, keywords=chain_b, sentiment=chain_c)
result = parallel.invoke({"text": document})  # all three run concurrently
```

---

**Q12: How do you debug a complex LCEL chain?**

Four methods:
1. **Intermediate inspection** — insert `RunnableLambda(lambda x: (print(x), x)[1])` to print at any step
2. **LangSmith tracing** — set `LANGCHAIN_TRACING_V2=true` to see every step in the UI
3. **`.invoke()` on sub-chains** — test each component independently before composing
4. **Verbose mode** — `AgentExecutor(verbose=True)` for agents

---

**Q13: Difference between ConversationBufferMemory and ConversationSummaryMemory?**

| ConversationBufferMemory | ConversationSummaryMemory |
|---|---|
| Stores full message history verbatim | Stores an LLM-generated summary |
| Grows linearly with turns | Stays bounded in token count |
| Good for short conversations | Good for long conversations |
| No LLM required for memory | Requires LLM to summarize |
| Can exceed context window | Context-window safe |

Both are legacy classes — use `RunnableWithMessageHistory` for new code.

---

**Q14: How do you handle large documents that exceed the context window?**

Multiple strategies:
1. **Chunking + RAG** — split into chunks, embed, retrieve only relevant chunks
2. **Map-Reduce** — process each chunk independently, then reduce (summarize) results
3. **Refine** — process chunks sequentially, refining the answer incrementally
4. **Parent Document Retriever** — index small chunks for retrieval, return the larger parent for context
5. **Contextual Compression** — retrieve chunks but compress them before sending to LLM

---

**Q15: When would you use LangChain vs LangGraph vs raw OpenAI SDK?**

| Scenario | Use |
|---|---|
| Simple one-shot completion | Raw OpenAI SDK |
| RAG pipeline, multi-step chain | LangChain |
| Multi-agent workflows, cycles, state machines | LangGraph |
| Complex document indexing (hierarchical) | LlamaIndex |
| Maximum control, no abstraction overhead | Raw SDK |
| Production observability needed | LangChain + LangSmith |

---

## 15. Comparison with Alternatives

### Framework Comparison Table

| Feature | LangChain | LlamaIndex | Raw OpenAI SDK | LangGraph |
|---|---|---|---|---|
| **Primary focus** | General LLM apps & RAG | Advanced document RAG | Direct API calls | Stateful agents |
| **Learning curve** | Medium | Medium | Low | High |
| **Abstraction level** | High | High | Low | Medium |
| **RAG capabilities** | Good | Excellent | Manual | Good (via LangChain) |
| **Agent support** | Good | Basic | Manual | Excellent |
| **Streaming** | Native (LCEL) | Supported | Native | Native |
| **Observability** | LangSmith | LlamaTrace | Manual | LangSmith |
| **Integrations** | 100+ | 50+ | OpenAI only | Via LangChain |
| **Vector stores** | 50+ | 40+ | Manual | Via LangChain |
| **Maintenance** | Active | Active | Stable | Active |
| **Community** | Very large | Large | Largest | Growing |
| **Production maturity** | High | High | Highest | Medium |

### When NOT to use LangChain

1. **Simple single LLM calls** — raw SDK is less overhead and easier to debug
2. **Performance-critical paths** — abstractions add latency; profile before using
3. **You need full control** — LangChain's abstractions can hide complexity that matters
4. **Heavily custom pipelines** — if your pipeline doesn't fit LangChain's primitives, fight against the framework
5. **Minimal dependency footprint** — LangChain has many transitive dependencies
6. **Complex state machines / multi-agent orchestration** — LangGraph is purpose-built for this
7. **Advanced document indexing (PDFs, tables, images)** — LlamaIndex has better support

### Decision Flowchart

```
Start
  │
  ├─ Single LLM call? ──────────────────────► Raw SDK
  │
  ├─ Multi-step chain with RAG? ────────────► LangChain
  │
  ├─ Complex document indexing? ────────────► LlamaIndex
  │
  ├─ Multi-agent / stateful loops? ─────────► LangGraph
  │
  └─ Unclear? Start with LangChain,
     refactor when you hit its limits.
```

---

## Quick Reference Card

```python
# === SETUP ===
import subprocess
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o", api_key=token, base_url="https://models.inference.ai.azure.com")
emb = OpenAIEmbeddings(model="text-embedding-3-small", api_key=token, base_url="https://models.inference.ai.azure.com")

# === BASIC CHAIN ===
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
chain = ChatPromptTemplate.from_template("Answer: {q}") | llm | StrOutputParser()
chain.invoke({"q": "What is 2+2?"})

# === RAG ===
from langchain_community.vectorstores import FAISS
from langchain_core.runnables import RunnablePassthrough
db = FAISS.from_texts(["LangChain is a framework"], emb)
retriever = db.as_retriever()
rag = ({"context": retriever | (lambda d: "\n".join(x.page_content for x in d)), "question": RunnablePassthrough()}
       | ChatPromptTemplate.from_template("Context: {context}\nQ: {question}") | llm | StrOutputParser())
rag.invoke("What is LangChain?")

# === STREAMING ===
for chunk in chain.stream({"q": "Tell me a story"}): print(chunk, end="")

# === PARALLEL ===
from langchain_core.runnables import RunnableParallel
RunnableParallel(a=chain, b=chain).invoke({"q": "hello"})

# === MEMORY ===
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_community.chat_message_histories import ChatMessageHistory
store = {}
with_mem = RunnableWithMessageHistory(chain, lambda sid: store.setdefault(sid, ChatMessageHistory()),
                                       input_messages_key="q", history_messages_key="history")
```

---

*Guide covers LangChain 0.3.x — verify specific APIs at [python.langchain.com/docs](https://python.langchain.com/docs)*
