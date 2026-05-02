# Comprehensive AI / LLM Resources & Learning Guide

> **Last updated:** 2025 | Target audience: Software developers building AI-powered applications
> **Goal:** One-stop reference for free APIs, tools, courses, communities, and quick-start code.

---

## Table of Contents

1. [Free LLM APIs](#1-free-llm-apis)
2. [Free Embedding Models](#2-free-embedding-models)
3. [Free Vector Databases](#3-free-vector-databases)
4. [Paid LLM APIs (with Pricing)](#4-paid-llm-apis-with-pricing)
5. [Free Courses & Tutorials](#5-free-courses--tutorials)
6. [Paid Courses & Certifications](#6-paid-courses--certifications)
7. [GitHub Repositories to Study](#7-github-repositories-to-study)
8. [Observability & Monitoring Tools](#8-observability--monitoring-tools)
9. [Dev Tools & Infrastructure](#9-dev-tools--infrastructure)
10. [Communities & Newsletters](#10-communities--newsletters)
11. [Quick Setup Cheatsheet](#11-quick-setup-cheatsheet)

---

## 1. Free LLM APIs

### 1.1 GitHub Models (Copilot / Azure AI Inference)

| Detail | Value |
|---|---|
| **URL** | https://github.com/marketplace/models |
| **Docs** | https://docs.github.com/en/github-models |
| **Models** | gpt-4o, gpt-4o-mini, Llama 3.3 70B, Mistral Large, Phi-4, Cohere Command R+ |
| **Free tier** | Free for all GitHub users (rate-limited per model) |
| **Auth** | GitHub Personal Access Token (PAT) |
| **Endpoint** | `https://models.inference.ai.azure.com` |

**How to get key:** Settings → Developer settings → Personal access tokens → Fine-grained token (no special scopes required for Models).

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key="YOUR_GITHUB_PAT",
)

response = client.chat.completions.create(
    model="gpt-4o-mini",          # or "Meta-Llama-3.3-70B-Instruct"
    messages=[{"role": "user", "content": "Explain RAG in 2 sentences."}],
    max_tokens=256,
)
print(response.choices[0].message.content)
```

---

### 1.2 Groq

| Detail | Value |
|---|---|
| **URL** | https://groq.com |
| **Console** | https://console.groq.com |
| **Docs** | https://console.groq.com/docs/openai |
| **Models** | llama-3.3-70b-versatile, llama-3.1-8b-instant, mixtral-8x7b-32768, gemma2-9b-it |
| **Free tier** | 14,400 req/day, 6,000 tokens/min per model |
| **Latency** | Fastest inference available (~500 tokens/sec on Llama 70B) |

**How to get key:** Sign up at https://console.groq.com → API Keys → Create API Key

```python
from groq import Groq

client = Groq(api_key="YOUR_GROQ_API_KEY")

response = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "What is LangGraph?"}],
    max_tokens=512,
)
print(response.choices[0].message.content)
```

---

### 1.3 Google Gemini API

| Detail | Value |
|---|---|
| **URL** | https://ai.google.dev |
| **Console** | https://aistudio.google.com |
| **Docs** | https://ai.google.dev/gemini-api/docs |
| **Models** | gemini-1.5-flash (free), gemini-1.5-pro (free with limits), gemini-2.0-flash |
| **Free tier** | 15 req/min, 1 million tokens/min, 1,500 req/day on Flash |

**How to get key:** https://aistudio.google.com/app/apikey → Create API Key

```python
import google.generativeai as genai

genai.configure(api_key="YOUR_GEMINI_API_KEY")
model = genai.GenerativeModel("gemini-1.5-flash")

response = model.generate_content("List 5 vector databases with pros and cons.")
print(response.text)
```

---

### 1.4 Mistral AI

| Detail | Value |
|---|---|
| **URL** | https://mistral.ai |
| **Console** | https://console.mistral.ai |
| **Docs** | https://docs.mistral.ai |
| **Models (free)** | mistral-small-latest, open-mistral-7b, open-mixtral-8x7b |
| **Free tier** | Free "Experiment" tier — generous rate limits for testing |

**How to get key:** https://console.mistral.ai/api-keys/

```python
from mistralai import Mistral

client = Mistral(api_key="YOUR_MISTRAL_API_KEY")

response = client.chat.complete(
    model="mistral-small-latest",
    messages=[{"role": "user", "content": "What is function calling in LLMs?"}],
)
print(response.choices[0].message.content)
```

---

### 1.5 Together AI

| Detail | Value |
|---|---|
| **URL** | https://www.together.ai |
| **Docs** | https://docs.together.ai |
| **Models** | 100+ open models: Llama, Mistral, Qwen, DBRX, Gemma, Yi |
| **Free tier** | $5 free credit on signup, OpenAI-compatible API |
| **Pricing after** | $0.10–$0.90 per 1M tokens depending on model |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.together.xyz/v1",
    api_key="YOUR_TOGETHER_API_KEY",
)

response = client.chat.completions.create(
    model="meta-llama/Llama-3.3-70B-Instruct-Turbo",
    messages=[{"role": "user", "content": "Explain embeddings simply."}],
)
print(response.choices[0].message.content)
```

---

### 1.6 Cohere

| Detail | Value |
|---|---|
| **URL** | https://cohere.com |
| **Console** | https://dashboard.cohere.com |
| **Docs** | https://docs.cohere.com |
| **Models** | command-r, command-r-plus, embed-v3 |
| **Free tier** | 1,000 API calls/month (Trial key), no credit card required |

```python
import cohere

co = cohere.Client(api_key="YOUR_COHERE_API_KEY")

response = co.chat(
    model="command-r",
    message="What makes a good RAG pipeline?",
)
print(response.text)
```

---

### 1.7 Fireworks AI

| Detail | Value |
|---|---|
| **URL** | https://fireworks.ai |
| **Docs** | https://docs.fireworks.ai |
| **Models** | Llama, Mixtral, Phi, Qwen, DeepSeek, FireFunction |
| **Free tier** | $1 free credit on signup; very competitive pricing |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.fireworks.ai/inference/v1",
    api_key="YOUR_FIREWORKS_API_KEY",
)

response = client.chat.completions.create(
    model="accounts/fireworks/models/llama-v3p3-70b-instruct",
    messages=[{"role": "user", "content": "Describe the MCP protocol."}],
)
print(response.choices[0].message.content)
```

---

### 1.8 OpenRouter

| Detail | Value |
|---|---|
| **URL** | https://openrouter.ai |
| **Docs** | https://openrouter.ai/docs |
| **Models** | 200+ models from all providers in one unified API |
| **Free tier** | Several models are permanently free (marked with `:free` suffix) |
| **Key feature** | Automatic fallback, routing, and cost management |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="YOUR_OPENROUTER_API_KEY",
)

response = client.chat.completions.create(
    model="meta-llama/llama-3.3-70b-instruct:free",  # free model
    messages=[{"role": "user", "content": "Summarize chain-of-thought prompting."}],
)
print(response.choices[0].message.content)
```

---

### 1.9 Ollama (100% Local)

| Detail | Value |
|---|---|
| **URL** | https://ollama.com |
| **Models** | https://ollama.com/library — 50+ models (Llama, Mistral, Phi, Gemma, DeepSeek…) |
| **Cost** | Completely free — runs on your machine |
| **Requirements** | 8GB RAM minimum; GPU optional but recommended |

**Install:**
```bash
# macOS / Linux
curl -fsSL https://ollama.com/install.sh | sh

# Windows: download installer from https://ollama.com/download
```

```python
# Pull and run a model
# Terminal: ollama pull llama3.2
# Terminal: ollama serve  (auto-starts)

from openai import OpenAI

client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")

response = client.chat.completions.create(
    model="llama3.2",
    messages=[{"role": "user", "content": "Write a Python function to chunk text."}],
)
print(response.choices[0].message.content)
```

---

## 2. Free Embedding Models

### 2.1 text-embedding-3-small via GitHub Models

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key="YOUR_GITHUB_PAT",
)

response = client.embeddings.create(
    model="text-embedding-3-small",
    input="Retrieval-augmented generation improves LLM accuracy.",
)
vector = response.data[0].embedding
print(f"Dimension: {len(vector)}")  # 1536
```

---

### 2.2 all-MiniLM-L6-v2 (Local, 22 MB)

```bash
pip install sentence-transformers
```

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
# https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2

texts = ["LangChain is a framework for building LLM apps.", "RAG retrieves context for generation."]
embeddings = model.encode(texts, normalize_embeddings=True)

print(f"Shape: {embeddings.shape}")  # (2, 384)
```

**Notes:** Best for semantic search, FAQ matching. 384 dimensions. Extremely fast on CPU.

---

### 2.3 all-mpnet-base-v2 (Local, 420 MB)

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("sentence-transformers/all-mpnet-base-v2")
# https://huggingface.co/sentence-transformers/all-mpnet-base-v2

embeddings = model.encode(["What is a vector database?"], normalize_embeddings=True)
print(f"Shape: {embeddings.shape}")  # (1, 768)
```

**Notes:** Higher quality than MiniLM. 768 dimensions. Good for document similarity and clustering.

---

### 2.4 nomic-embed-text via Ollama (Local)

```bash
ollama pull nomic-embed-text
```

```python
import requests

response = requests.post(
    "http://localhost:11434/api/embeddings",
    json={"model": "nomic-embed-text", "prompt": "Explain transformer architecture."},
)
vector = response.json()["embedding"]
print(f"Dimension: {len(vector)}")  # 768
```

---

### 2.5 mxbai-embed-large via Ollama (Local)

```bash
ollama pull mxbai-embed-large
```

```python
import requests

response = requests.post(
    "http://localhost:11434/api/embeddings",
    json={"model": "mxbai-embed-large", "prompt": "Vector similarity search techniques."},
)
vector = response.json()["embedding"]
print(f"Dimension: {len(vector)}")  # 1024 — higher quality embeddings
```

**Notes:** State-of-the-art open-source embedding model. Outperforms many commercial alternatives on MTEB benchmark.

---

## 3. Free Vector Databases

### 3.1 FAISS (Meta)

| Detail | Value |
|---|---|
| **URL** | https://github.com/facebookresearch/faiss |
| **Docs** | https://faiss.ai |
| **Type** | Fully embedded (in-process), no server |
| **Limits** | Unlimited — runs in RAM/disk |
| **Best for** | Fast prototyping, batch indexing, research |

```bash
pip install faiss-cpu  # or faiss-gpu for CUDA
```

```python
import faiss
import numpy as np

dimension = 384
index = faiss.IndexFlatL2(dimension)  # exact L2 search

vectors = np.random.rand(1000, dimension).astype("float32")
index.add(vectors)

query = np.random.rand(1, dimension).astype("float32")
distances, indices = index.search(query, k=5)
print(f"Nearest neighbors: {indices}")

# Save/load index
faiss.write_index(index, "my_index.faiss")
index = faiss.read_index("my_index.faiss")
```

---

### 3.2 ChromaDB

| Detail | Value |
|---|---|
| **URL** | https://www.trychroma.com |
| **Docs** | https://docs.trychroma.com |
| **GitHub** | https://github.com/chroma-core/chroma |
| **Type** | Embedded or server mode, open source |
| **Free tier** | Unlimited self-hosted; Chroma Cloud free tier available |

```bash
pip install chromadb
```

```python
import chromadb

client = chromadb.PersistentClient(path="./chroma_db")
collection = client.get_or_create_collection("my_docs")

collection.add(
    documents=["LangChain builds LLM apps.", "LlamaIndex is for data indexing."],
    ids=["doc1", "doc2"],
)

results = collection.query(query_texts=["How to build AI agents?"], n_results=2)
print(results["documents"])
```

---

### 3.3 Qdrant

| Detail | Value |
|---|---|
| **URL** | https://qdrant.tech |
| **Docs** | https://qdrant.tech/documentation |
| **Cloud** | https://cloud.qdrant.io — free tier 1 GB cluster |
| **Self-hosted** | Docker: `docker run -p 6333:6333 qdrant/qdrant` |
| **Features** | Filtering, payload indexing, multi-vector, quantization |

```bash
pip install qdrant-client
```

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

client = QdrantClient(":memory:")  # or QdrantClient(url="http://localhost:6333")

client.create_collection(
    collection_name="knowledge",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
)

client.upsert(
    collection_name="knowledge",
    points=[
        PointStruct(id=1, vector=[0.1]*384, payload={"text": "RAG tutorial"}),
        PointStruct(id=2, vector=[0.2]*384, payload={"text": "Agents overview"}),
    ],
)

results = client.search(collection_name="knowledge", query_vector=[0.15]*384, limit=2)
for r in results:
    print(r.payload["text"], r.score)
```

---

### 3.4 Weaviate

| Detail | Value |
|---|---|
| **URL** | https://weaviate.io |
| **Docs** | https://weaviate.io/developers/weaviate |
| **Cloud** | https://console.weaviate.cloud — free 14-day sandbox |
| **Self-hosted** | `docker run -p 8080:8080 semitechnologies/weaviate` |
| **Features** | GraphQL API, multi-modal, hybrid search, modules |

```bash
pip install weaviate-client
```

```python
import weaviate

client = weaviate.connect_to_local()  # or connect_to_weaviate_cloud(...)

collection = client.collections.create(
    name="Articles",
    vectorizer_config=weaviate.classes.config.Configure.Vectorizer.none(),
)

collection.data.insert({"title": "Intro to RAG"}, vector=[0.1] * 384)

results = collection.query.near_vector(near_vector=[0.1]*384, limit=3)
for obj in results.objects:
    print(obj.properties)

client.close()
```

---

### 3.5 Milvus Lite

| Detail | Value |
|---|---|
| **URL** | https://milvus.io |
| **Docs** | https://milvus.io/docs |
| **GitHub** | https://github.com/milvus-io/milvus |
| **Type** | Embedded (Lite) or distributed cluster |
| **Free tier** | Zilliz Cloud free tier; unlimited self-hosted |

```bash
pip install pymilvus
```

```python
from pymilvus import MilvusClient

client = MilvusClient("./milvus_lite.db")  # embedded, no server needed

client.create_collection(collection_name="docs", dimension=384)

client.insert(
    collection_name="docs",
    data=[{"id": 1, "vector": [0.1]*384, "text": "RAG overview"}],
)

results = client.search(
    collection_name="docs",
    data=[[0.1]*384],
    limit=3,
    output_fields=["text"],
)
print(results)
```

---

### 3.6 LanceDB

| Detail | Value |
|---|---|
| **URL** | https://lancedb.com |
| **Docs** | https://lancedb.github.io/lancedb |
| **GitHub** | https://github.com/lancedb/lancedb |
| **Type** | Serverless, columnar (Lance format), multimodal |
| **Free tier** | Open source, unlimited self-hosted; LanceDB Cloud free tier |

```bash
pip install lancedb
```

```python
import lancedb
import numpy as np

db = lancedb.connect("./lancedb_store")

data = [{"vector": np.random.rand(384).tolist(), "text": f"Document {i}"} for i in range(100)]
table = db.create_table("docs", data=data)

results = table.search(np.random.rand(384).tolist()).limit(5).to_pandas()
print(results[["text", "_distance"]])
```

---

## 4. Paid LLM APIs (with Pricing)

### 4.1 OpenAI

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context |
|---|---|---|---|
| gpt-4o | $5.00 | $15.00 | 128K |
| gpt-4o-mini | $0.15 | $0.60 | 128K |
| o1 | $15.00 | $60.00 | 200K |
| o3-mini | $1.10 | $4.40 | 200K |
| o1-mini | $3.00 | $12.00 | 128K |

**URL:** https://openai.com | **Pricing:** https://openai.com/api/pricing | **Docs:** https://platform.openai.com/docs

---

### 4.2 Anthropic

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context |
|---|---|---|---|
| Claude 3.5 Sonnet | $3.00 | $15.00 | 200K |
| Claude 3.5 Haiku | $0.80 | $4.00 | 200K |
| Claude 3 Haiku | $0.25 | $1.25 | 200K |
| Claude 3 Opus | $15.00 | $75.00 | 200K |

**URL:** https://anthropic.com | **Pricing:** https://www.anthropic.com/pricing | **Docs:** https://docs.anthropic.com

---

### 4.3 Google Gemini

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context |
|---|---|---|---|
| Gemini 1.5 Pro | $3.50 | $10.50 | 2M |
| Gemini 1.5 Flash | $0.075 | $0.30 | 1M |
| Gemini 2.0 Flash | $0.10 | $0.40 | 1M |

**URL:** https://ai.google.dev | **Pricing:** https://ai.google.dev/pricing

---

### 4.4 Azure OpenAI

| Feature | Details |
|---|---|
| **URL** | https://azure.microsoft.com/en-us/products/ai-services/openai-service |
| **Models** | All OpenAI models + fine-tuned versions |
| **Pricing** | Same per-token rates as OpenAI + possible Azure discounts |
| **PTU** | Provisioned Throughput Units for predictable latency |
| **Enterprise features** | Private endpoints, VNET, compliance, content filters |
| **Best for** | Enterprise, compliance-heavy workloads, Azure ecosystem |

---

### 4.5 AWS Bedrock

| Feature | Details |
|---|---|
| **URL** | https://aws.amazon.com/bedrock |
| **Pricing** | https://aws.amazon.com/bedrock/pricing |
| **Models** | 30+ models: Claude, Llama, Titan, Mistral, Cohere, Stable Diffusion |
| **Pricing model** | Pay-per-token, no commitment required |
| **Key feature** | Agents, Knowledge Bases (RAG), Guardrails all integrated |
| **Claude 3.5 Sonnet** | $3.00 / $15.00 per 1M in/out tokens |

---

### 4.6 Cost Comparison Table (Approximate Tokens per Dollar)

| Model | Tokens per $1 (input) | Best use case |
|---|---|---|
| GPT-4o-mini | ~6.7M | High-volume tasks, chat |
| Claude 3 Haiku | ~4M | Fast, cheap summarization |
| Gemini 1.5 Flash | ~13M | Cheapest capable model |
| Llama 3 (Groq free) | ∞ (free) | Development & testing |
| GPT-4o | ~200K | Complex reasoning |
| Claude 3.5 Sonnet | ~333K | Coding & analysis |
| Claude 3 Opus | ~67K | Most capable, most expensive |

---

## 5. Free Courses & Tutorials

### 5.1 DeepLearning.AI Short Courses (All Free)

**Platform:** https://learn.deeplearning.ai | All courses are free | 1–3 hours each

| Course | URL | Duration | What You Learn |
|---|---|---|---|
| LangChain for LLM Application Development | https://learn.deeplearning.ai/courses/langchain | 2h | Chains, memory, agents, tools |
| LangGraph: Build Agentic AI | https://learn.deeplearning.ai/courses/ai-agents-in-langgraph | 2h | Stateful agents, cycles, human-in-the-loop |
| Multi-AI-Agent Systems with CrewAI | https://learn.deeplearning.ai/courses/multi-ai-agent-systems-with-crewai | 2h | Role-based agents, tasks, crews |
| AI Agents in LangGraph | https://learn.deeplearning.ai/courses/ai-agents-in-langgraph | 2h | ReAct, tool calling, memory |
| DSPy: Build & Optimize LLM Apps | https://learn.deeplearning.ai/courses/building-toward-computer-use | 1.5h | Prompt optimization, DSPy modules |
| Building Agentic RAG with LlamaIndex | https://learn.deeplearning.ai/courses/building-agentic-rag-with-llamaindex | 2h | Query engines, multi-document agents |
| Vector Databases: from Embeddings to Applications | https://learn.deeplearning.ai/courses/vector-databases-embeddings-applications | 2h | FAISS, Weaviate, hybrid search |
| Building & Evaluating Advanced RAG | https://learn.deeplearning.ai/courses/building-evaluating-advanced-rag | 2h | RAG triad, TruLens evaluation |
| Pretraining LLMs | https://learn.deeplearning.ai/courses/pretraining-llms | 2h | From-scratch pretraining concepts |
| Function Calling & Data Extraction | https://learn.deeplearning.ai/courses/function-calling-and-data-extraction-with-llms | 1.5h | JSON mode, structured outputs |
| MCP: Build Agentic Apps | https://learn.deeplearning.ai/courses/mcp-build-agentic-apps | 1.5h | Model Context Protocol, tools, resources |

---

### 5.2 Hugging Face Courses

**Platform:** https://huggingface.co/learn | All free

| Course | URL | What You Learn |
|---|---|---|
| NLP Course | https://huggingface.co/learn/nlp-course | Transformers, fine-tuning, tokenization |
| Agents Course | https://huggingface.co/learn/agents-course | Tool use, code agents, smolagents |
| RAG Course | https://huggingface.co/learn/cookbook/rag | Advanced RAG recipes |
| Deep RL Course | https://huggingface.co/learn/deep-rl-course | Reinforcement learning fundamentals |

---

### 5.3 fast.ai

| Detail | Value |
|---|---|
| **URL** | https://course.fast.ai |
| **Duration** | ~20 hours |
| **Cost** | Free |
| **What you learn** | Practical deep learning, fine-tuning, diffusion models, NLP from scratch |
| **Notes** | Highly practical, top-down teaching approach |

---

### 5.4 LangChain Academy

| Detail | Value |
|---|---|
| **URL** | https://academy.langchain.com |
| **Course** | Introduction to LangGraph |
| **Duration** | ~6 hours |
| **Cost** | Free |
| **What you learn** | Graphs, state machines, checkpointing, human-in-the-loop patterns |

---

### 5.5 Microsoft Learn

| Course | URL | What You Learn |
|---|---|---|
| Develop AI agents with Azure OpenAI | https://learn.microsoft.com/en-us/training/paths/develop-ai-agents-azure-open-ai-semantic-kernel-sdk | Semantic Kernel, agents |
| Azure AI Fundamentals | https://learn.microsoft.com/en-us/training/paths/get-started-with-artificial-intelligence-on-azure | Azure AI services overview |
| Build Copilot with Azure | https://learn.microsoft.com/en-us/training/paths/build-copilots-with-azure-ai-foundry | Copilot Studio, Azure AI Foundry |

---

### 5.6 Google AI Courses

| Course | URL | What You Learn |
|---|---|---|
| Gemini API Developer Course | https://ai.google.dev/gemini-api/docs/get-started/python | Gemini API, function calling, embeddings |
| Google ML Crash Course | https://developers.google.com/machine-learning/crash-course | ML fundamentals |
| Prompt Engineering Guide (Google) | https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompting-best-practices | Prompting for Vertex AI |

---

### 5.7 Weights & Biases LLMOps

| Detail | Value |
|---|---|
| **URL** | https://www.wandb.courses/courses/building-llm-powered-apps |
| **Duration** | ~4 hours |
| **Cost** | Free |
| **What you learn** | LLMOps lifecycle, evaluation, fine-tuning, W&B integration |

---

## 6. Paid Courses & Certifications

### 6.1 Coursera — DeepLearning.AI Specializations

| Specialization | URL | Duration | Cost |
|---|---|---|---|
| Machine Learning Specialization | https://www.coursera.org/specializations/machine-learning-introduction | 3 months | ~$49/month |
| Deep Learning Specialization | https://www.coursera.org/specializations/deep-learning | 5 months | ~$49/month |
| MLOps Specialization | https://www.coursera.org/specializations/machine-learning-engineering-for-production-mlops | 4 months | ~$49/month |
| Natural Language Processing | https://www.coursera.org/specializations/natural-language-processing | 4 months | ~$49/month |
| LLMOps by Google Cloud | https://www.coursera.org/learn/llmops | 1 month | ~$49/month |

**Note:** Financial aid available. Certificates from top institutions (Stanford, Google, DeepMind).

---

### 6.2 Udemy

| Course | URL | Price (sale) | What You Learn |
|---|---|---|---|
| LangChain Masterclass | https://www.udemy.com/course/master-langchain-pinecone-openai-build-llm-applications | ~$15 | LangChain, Pinecone, OpenAI |
| ChatGPT & LangChain Bootcamp | https://www.udemy.com/course/chatgpt-and-langchain-the-complete-developers-masterclass | ~$15 | Full stack AI apps |
| AutoGen & Multi-Agent AI | https://www.udemy.com/course/autogen-multi-agent-systems | ~$20 | AutoGen framework |

**Tip:** Watch for Udemy sales — courses are 80–90% off regularly. Use https://www.udemy.com/courses/search/?q=langchain&price=price-paid&sort=highest-rated

---

### 6.3 LinkedIn Learning

| Course | URL | Cost |
|---|---|---|
| AI for Software Developers | https://www.linkedin.com/learning/topics/ai-for-developers | $29.99/month or free with Premium |
| Python for AI | https://www.linkedin.com/learning/python-for-data-science-and-machine-learning-essential-training | Included in LinkedIn Premium |

---

### 6.4 O'Reilly

| Resource | URL | Cost |
|---|---|---|
| O'Reilly Learning Platform | https://www.oreilly.com/online-learning | $49/month |
| "Building LLM Powered Applications" book | Available on O'Reilly | Included |
| "Designing Large Language Model Applications" | Available on O'Reilly | Included |
| Live AI courses | https://www.oreilly.com/live-events | Included in subscription |

---

### 6.5 DataCamp

| Track | URL | Cost |
|---|---|---|
| AI Engineer Track | https://www.datacamp.com/tracks/ai-engineer | $25/month |
| Associate AI Engineer Cert | https://www.datacamp.com/certification/associate-ai-engineer-for-developers | Included in track |
| LLM Concepts Course | https://www.datacamp.com/courses/large-language-models-llms-concepts | Included |

---

### 6.6 Cloud Provider AI Certifications

| Certification | URL | Cost | Validity |
|---|---|---|---|
| AWS Certified Machine Learning – Specialty | https://aws.amazon.com/certification/certified-machine-learning-specialty | $300 exam | 3 years |
| AWS AI Practitioner | https://aws.amazon.com/certification/certified-ai-practitioner | $100 exam | 3 years |
| Azure AI Engineer Associate (AI-102) | https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-engineer | $165 exam | 1 year |
| Google Professional ML Engineer | https://cloud.google.com/learn/certification/machine-learning-engineer | $200 exam | 2 years |
| Google Gemini for Google Cloud | https://cloud.google.com/learn/certification/cloud-digital-leader | $99 exam | 2 years |

---

## 7. GitHub Repositories to Study

| Repository | URL | Stars (approx.) | What to Learn |
|---|---|---|---|
| langchain-ai/langchain | https://github.com/langchain-ai/langchain | 90K+ | Core LLM framework: chains, agents, memory, tools |
| langchain-ai/langgraph | https://github.com/langchain-ai/langgraph | 10K+ | Stateful agent graphs, multi-agent orchestration |
| crewAIInc/crewAI | https://github.com/crewAIInc/crewAI | 25K+ | Role-based multi-agent systems, task delegation |
| microsoft/autogen | https://github.com/microsoft/autogen | 35K+ | Conversational multi-agent framework |
| run-llama/llama_index | https://github.com/run-llama/llama_index | 38K+ | Data indexing, query engines, RAG patterns |
| deepset-ai/haystack | https://github.com/deepset-ai/haystack | 18K+ | Production RAG pipelines, NLP components |
| microsoft/semantic-kernel | https://github.com/microsoft/semantic-kernel | 22K+ | Copilot patterns, plugins, planners |
| stanfordnlp/dspy | https://github.com/stanfordnlp/dspy | 20K+ | Prompt optimization, programmatic LM usage |
| modelcontextprotocol/python-sdk | https://github.com/modelcontextprotocol/python-sdk | 3K+ | MCP protocol, tools, resources, servers |
| BerriAI/litellm | https://github.com/BerriAI/litellm | 15K+ | Unified API for 100+ LLM providers |
| Significant-Gravitas/AutoGPT | https://github.com/Significant-Gravitas/AutoGPT | 170K+ | Autonomous agents, long-running tasks |
| openai/openai-python | https://github.com/openai/openai-python | 23K+ | Official OpenAI Python client patterns |
| huggingface/transformers | https://github.com/huggingface/transformers | 135K+ | Model loading, fine-tuning, inference |
| qdrant/qdrant | https://github.com/qdrant/qdrant | 20K+ | Vector DB internals, filtering, HNSW |
| chroma-core/chroma | https://github.com/chroma-core/chroma | 15K+ | Embedded vector DB, metadata filtering |
| ollama/ollama | https://github.com/ollama/ollama | 95K+ | Local model serving, Modelfile format |
| vllm-project/vllm | https://github.com/vllm-project/vllm | 38K+ | High-throughput LLM serving, PagedAttention |

**How to study repos effectively:**
1. Read the README and architecture docs first
2. Explore `/examples` and `/notebooks` directories
3. Study the `/tests` for real usage patterns
4. Trace from a high-level API call down to implementation

---

## 8. Observability & Monitoring Tools

### 8.1 Tool Comparison Table

| Tool | Free Tier | Self-Host | Open Source | Key Feature |
|---|---|---|---|---|
| LangSmith | 5K traces/month | No | No | Native LangChain integration |
| LangFuse | Unlimited (self-hosted) | Yes | Yes | Best open-source option |
| W&B Weave | Generous free tier | No | Partial | Weights & Biases ecosystem |
| Helicone | 100K logs/month | Yes | Yes | Proxy-based, zero code change |
| Arize Phoenix | Unlimited (local) | Yes | Yes | Offline-first, OTEL support |
| PromptLayer | 5K requests/month | No | No | Prompt versioning, A/B testing |

---

### 8.2 LangSmith

| Detail | Value |
|---|---|
| **URL** | https://smith.langchain.com |
| **Docs** | https://docs.smith.langchain.com |
| **Free tier** | 5,000 traces/month, full feature access |
| **Paid** | $39/month Developer, $299/month Team |

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "YOUR_LANGSMITH_API_KEY"
os.environ["LANGCHAIN_PROJECT"] = "my-rag-project"

# All LangChain calls are now automatically traced
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4o-mini")
result = llm.invoke("Hello!")  # Appears in LangSmith dashboard
```

---

### 8.3 LangFuse (Open Source)

| Detail | Value |
|---|---|
| **URL** | https://langfuse.com |
| **GitHub** | https://github.com/langfuse/langfuse |
| **Cloud** | https://cloud.langfuse.com — free tier |
| **Self-host** | Docker compose: `docker compose up` |

```python
from langfuse.openai import openai  # drop-in replacement

client = openai.OpenAI(api_key="YOUR_OPENAI_KEY")
# LangFuse automatically captures all calls — set env vars:
# LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY, LANGFUSE_HOST

response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Trace this call!"}],
)
print(response.choices[0].message.content)
```

---

### 8.4 Arize Phoenix (Local, Open Source)

| Detail | Value |
|---|---|
| **URL** | https://phoenix.arize.com |
| **GitHub** | https://github.com/Arize-ai/phoenix |
| **Type** | Runs entirely locally (no cloud) |
| **Features** | LLM tracing, RAG evaluation, span analysis, OTEL |

```bash
pip install arize-phoenix
python -m phoenix.server.main serve  # starts at http://localhost:6006
```

```python
import phoenix as px
from openinference.instrumentation.openai import OpenAIInstrumentor
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

px.launch_app()  # opens browser UI
```

---

### 8.5 Helicone

| Detail | Value |
|---|---|
| **URL** | https://helicone.ai |
| **GitHub** | https://github.com/Helicone/helicone |
| **Free tier** | 100,000 logs/month |
| **Key feature** | Proxy-based — change one line of code |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://oai.helicone.ai/v1",  # only change needed
    api_key="YOUR_OPENAI_KEY",
    default_headers={"Helicone-Auth": "Bearer YOUR_HELICONE_KEY"},
)
```

---

## 9. Dev Tools & Infrastructure

### 9.1 LiteLLM

| Detail | Value |
|---|---|
| **URL** | https://litellm.ai |
| **GitHub** | https://github.com/BerriAI/litellm |
| **Purpose** | Unified API for 100+ LLMs — one interface, any provider |
| **Cost** | Open source, free |

```bash
pip install litellm
```

```python
from litellm import completion

# Works with any provider — just change the model string
response = completion(
    model="groq/llama-3.3-70b-versatile",     # or "gpt-4o", "claude-3-5-sonnet", etc.
    messages=[{"role": "user", "content": "Hello!"}],
    api_key="YOUR_GROQ_KEY",
)
print(response.choices[0].message.content)
```

**As a proxy server:**
```bash
litellm --model groq/llama-3.3-70b-versatile
# Now use http://0.0.0.0:4000 as OpenAI-compatible endpoint
```

---

### 9.2 Portkey

| Detail | Value |
|---|---|
| **URL** | https://portkey.ai |
| **Docs** | https://portkey.ai/docs |
| **Features** | LLM gateway, caching, fallbacks, load balancing, monitoring |
| **Free tier** | 10,000 requests/month |

```python
from openai import OpenAI
from portkey_ai import PORTKEY_GATEWAY_URL, createHeaders

client = OpenAI(
    base_url=PORTKEY_GATEWAY_URL,
    api_key="YOUR_OPENAI_KEY",
    default_headers=createHeaders(api_key="YOUR_PORTKEY_KEY", provider="openai"),
)
```

---

### 9.3 LocalAI

| Detail | Value |
|---|---|
| **URL** | https://localai.io |
| **GitHub** | https://github.com/mudler/LocalAI |
| **Purpose** | Run models locally with OpenAI-compatible REST API |
| **Models** | GGUF models (llama.cpp backend), Whisper, Stable Diffusion |

```bash
docker run -p 8080:8080 -v $PWD/models:/build/models:cached \
  localai/localai:latest-aio-cpu
```

---

### 9.4 Text Generation WebUI (oobabooga)

| Detail | Value |
|---|---|
| **GitHub** | https://github.com/oobabooga/text-generation-webui |
| **Purpose** | Feature-rich UI for running local LLMs |
| **Features** | Chat, API, extensions, LoRA, character personas |
| **Install** | `git clone https://github.com/oobabooga/text-generation-webui && cd text-generation-webui && ./start_linux.sh` |

---

### 9.5 AnythingLLM

| Detail | Value |
|---|---|
| **URL** | https://anythingllm.com |
| **GitHub** | https://github.com/Mintplex-Labs/anything-llm |
| **Purpose** | Local RAG application with file upload, workspaces, agents |
| **Install** | Desktop app or Docker: `docker pull mintplexlabs/anythingllm` |

---

### 9.6 Open WebUI

| Detail | Value |
|---|---|
| **URL** | https://openwebui.com |
| **GitHub** | https://github.com/open-webui/open-webui |
| **Purpose** | ChatGPT-like UI for Ollama and OpenAI-compatible APIs |
| **Install** | `docker run -p 3000:8080 ghcr.io/open-webui/open-webui:ollama` |

---

## 10. Communities & Newsletters

### 10.1 Discord Servers

| Community | Invite / URL | Focus |
|---|---|---|
| LangChain | https://discord.gg/langchain | LangChain, LangGraph, LangSmith |
| LlamaIndex | https://discord.gg/eN6D2HQ4aX | LlamaIndex, RAG, agents |
| Hugging Face | https://discord.gg/huggingface | Open models, Transformers, Spaces |
| CrewAI | https://discord.gg/X4JWnZnxPb | Multi-agent systems |
| AutoGen | https://discord.gg/pAbnFJrkgZ | Microsoft AutoGen |
| Ollama | https://discord.gg/ollama | Local LLM running |
| LocalLLaMA | https://discord.gg/localllama | Local models community |
| OpenRouter | https://discord.gg/openrouter | Multi-provider routing |

---

### 10.2 Reddit Communities

| Subreddit | URL | Focus |
|---|---|---|
| r/LocalLLaMA | https://www.reddit.com/r/LocalLLaMA | Local models, hardware, benchmarks |
| r/MachineLearning | https://www.reddit.com/r/MachineLearning | Research papers, ML news |
| r/artificial | https://www.reddit.com/r/artificial | General AI news and discussion |
| r/ChatGPT | https://www.reddit.com/r/ChatGPT | ChatGPT tips and use cases |
| r/LangChain | https://www.reddit.com/r/LangChain | LangChain community |
| r/mlops | https://www.reddit.com/r/mlops | ML engineering and deployment |

---

### 10.3 Twitter / X Accounts to Follow

| Account | Handle | Why Follow |
|---|---|---|
| Andrej Karpathy | @karpathy | Deep learning insights, LLM internals |
| Yann LeCun | @ylecun | AI research, Meta AI |
| Sam Altman | @sama | OpenAI news |
| Demis Hassabis | @demishassabis | Google DeepMind |
| Harrison Chase | @hwchase17 | LangChain creator |
| Jerry Liu | @jerryjliu0 | LlamaIndex creator |
| Lilian Weng | @lilianweng | Deep technical AI blog posts |
| Simon Willison | @simonw | Practical AI tools and hacks |
| Swyx | @swyx | AI engineering community |
| Eugene Yan | @eugeneyan | Applied ML, RecSys, LLMs |

---

### 10.4 Newsletters

| Newsletter | URL | Frequency | Focus |
|---|---|---|---|
| The Batch (DeepLearning.AI) | https://www.deeplearning.ai/the-batch | Weekly | Curated AI news from Andrew Ng |
| AI Supremacy | https://www.aisupremacy.substack.com | Weekly | AI industry analysis |
| Import AI | https://importai.substack.com | Weekly | Jack Clark's AI research digest |
| The Rundown AI | https://www.therundown.ai | Daily | Quick AI news summary |
| Last Week in AI | https://lastweekin.ai | Weekly | Podcast + newsletter combo |
| Nathan's Substack | https://nathanbenaich.substack.com | Quarterly | State of AI report |
| TLDR AI | https://tldr.tech/ai | Daily | Short AI engineering briefs |

---

### 10.5 Podcasts

| Podcast | URL | Focus |
|---|---|---|
| Lex Fridman Podcast | https://lexfridman.com/podcast | Long-form AI/tech interviews |
| TWIML AI Podcast | https://twimlai.com | ML engineering and research |
| Practical AI | https://changelog.com/practicalai | Practical AI application |
| Gradient Dissent (W&B) | https://wandb.ai/fully-connected/podcast | ML research and practice |
| The MLST Podcast | https://mlst.io | Academic ML research |
| Latent Space | https://www.latent.space/podcast | AI engineering deep dives |

---

### 10.6 Technical Blogs

| Blog | URL | Why Read |
|---|---|---|
| Lilian Weng (OpenAI) | https://lilianweng.github.io | Deeply technical, rigorous ML explanations |
| Sebastian Ruder | https://ruder.io | NLP research, transfer learning |
| Eugene Yan | https://eugeneyan.com | Applied ML, system design |
| Jay Alammar | https://jalammar.github.io | Visual guides to transformers |
| The AI Summer | https://theaisummer.com | Implementation-focused tutorials |
| Fast.ai Blog | https://www.fast.ai/blog | Practical deep learning |
| Chip Huyen | https://huyenchip.com/blog | ML systems design |

---

## 11. Quick Setup Cheatsheet

### 11.1 .env Template

```bash
# ============================================================
# FREE LLM APIs
# ============================================================
GITHUB_TOKEN=ghp_your_github_pat_here
GROQ_API_KEY=gsk_your_groq_key_here
GOOGLE_API_KEY=AIza_your_gemini_key_here
MISTRAL_API_KEY=your_mistral_key_here
TOGETHER_API_KEY=your_together_key_here
COHERE_API_KEY=your_cohere_key_here
FIREWORKS_API_KEY=fw_your_fireworks_key_here
OPENROUTER_API_KEY=sk-or-your_openrouter_key_here

# ============================================================
# PAID LLM APIs
# ============================================================
OPENAI_API_KEY=sk-your_openai_key_here
ANTHROPIC_API_KEY=sk-ant-your_anthropic_key_here

# ============================================================
# OBSERVABILITY
# ============================================================
LANGCHAIN_API_KEY=ls__your_langsmith_key_here
LANGCHAIN_TRACING_V2=true
LANGCHAIN_PROJECT=my-ai-project
LANGFUSE_PUBLIC_KEY=pk-your_langfuse_public_key
LANGFUSE_SECRET_KEY=sk-your_langfuse_secret_key
LANGFUSE_HOST=https://cloud.langfuse.com

# ============================================================
# VECTOR DATABASES (cloud)
# ============================================================
QDRANT_URL=https://your-cluster.qdrant.io
QDRANT_API_KEY=your_qdrant_api_key
```

---

### 11.2 requirements.txt by Group

**Core LLM frameworks:**
```
# requirements-llm.txt
openai>=1.40.0
anthropic>=0.34.0
google-generativeai>=0.7.0
groq>=0.9.0
mistralai>=1.0.0
cohere>=5.0.0
litellm>=1.40.0
```

**LangChain ecosystem:**
```
# requirements-langchain.txt
langchain>=0.3.0
langchain-openai>=0.2.0
langchain-anthropic>=0.2.0
langchain-google-genai>=2.0.0
langchain-groq>=0.2.0
langchain-community>=0.3.0
langgraph>=0.2.0
langsmith>=0.1.0
```

**Embedding & vector stores:**
```
# requirements-vector.txt
sentence-transformers>=3.0.0
faiss-cpu>=1.8.0
chromadb>=0.5.0
qdrant-client>=1.11.0
lancedb>=0.10.0
pymilvus>=2.4.0
```

**Agent frameworks:**
```
# requirements-agents.txt
crewai>=0.65.0
pyautogen>=0.3.0
llama-index>=0.11.0
dspy-ai>=2.4.0
```

**Observability:**
```
# requirements-observability.txt
langsmith>=0.1.0
langfuse>=2.0.0
wandb>=0.17.0
arize-phoenix>=4.0.0
openinference-instrumentation-openai>=0.1.0
```

---

### 11.3 One-File Free LLM Setup Script

```python
"""
free_llm_setup.py — Test all free LLM APIs in one script.
Run: python free_llm_setup.py
"""
import os
from dotenv import load_dotenv

load_dotenv()

PROMPT = "Say 'API working!' in exactly 3 words."

def test_github_models():
    from openai import OpenAI
    client = OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=os.getenv("GITHUB_TOKEN"),
    )
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": PROMPT}],
        max_tokens=20,
    )
    print(f"GitHub Models: {r.choices[0].message.content.strip()}")

def test_groq():
    from groq import Groq
    client = Groq(api_key=os.getenv("GROQ_API_KEY"))
    r = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": PROMPT}],
        max_tokens=20,
    )
    print(f"Groq: {r.choices[0].message.content.strip()}")

def test_gemini():
    import google.generativeai as genai
    genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
    model = genai.GenerativeModel("gemini-1.5-flash")
    r = model.generate_content(PROMPT)
    print(f"Gemini: {r.text.strip()}")

def test_ollama():
    from openai import OpenAI
    client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")
    try:
        r = client.chat.completions.create(
            model="llama3.2",
            messages=[{"role": "user", "content": PROMPT}],
            max_tokens=20,
        )
        print(f"Ollama: {r.choices[0].message.content.strip()}")
    except Exception:
        print("Ollama: Not running — start with 'ollama serve'")

if __name__ == "__main__":
    print("=== Testing Free LLM APIs ===\n")
    if os.getenv("GITHUB_TOKEN"):     test_github_models()
    if os.getenv("GROQ_API_KEY"):     test_groq()
    if os.getenv("GOOGLE_API_KEY"):   test_gemini()
    test_ollama()
    print("\nDone!")
```

---

### 11.4 Docker Compose — Local AI Stack (Qdrant + Ollama + Open WebUI)

```yaml
# docker-compose.yml
# Usage: docker compose up -d
# Then visit: http://localhost:3000  (Open WebUI)
#             http://localhost:6333  (Qdrant Dashboard)
#             http://localhost:11434 (Ollama API)

version: "3.9"

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped
    # For GPU support, add:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    volumes:
      - open_webui_data:/app/backend/data
    ports:
      - "3000:8080"
    restart: unless-stopped

  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant
    volumes:
      - qdrant_data:/qdrant/storage
    ports:
      - "6333:6333"
      - "6334:6334"
    restart: unless-stopped

  langfuse:
    image: langfuse/langfuse:latest
    container_name: langfuse
    depends_on:
      - langfuse-db
    environment:
      - DATABASE_URL=postgresql://langfuse:langfuse@langfuse-db:5432/langfuse
      - NEXTAUTH_SECRET=your-secret-here
      - NEXTAUTH_URL=http://localhost:3100
      - SALT=your-salt-here
    ports:
      - "3100:3000"
    restart: unless-stopped

  langfuse-db:
    image: postgres:15
    container_name: langfuse-db
    environment:
      - POSTGRES_USER=langfuse
      - POSTGRES_PASSWORD=langfuse
      - POSTGRES_DB=langfuse
    volumes:
      - langfuse_db_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  ollama_data:
  open_webui_data:
  qdrant_data:
  langfuse_db_data:
```

**After starting the stack:**
```bash
# Pull your first model
docker exec ollama ollama pull llama3.2
docker exec ollama ollama pull nomic-embed-text

# Verify all services
curl http://localhost:11434/api/tags          # Ollama
curl http://localhost:6333/collections        # Qdrant
# Open WebUI: http://localhost:3000
# LangFuse: http://localhost:3100
```

---

### 11.5 Quick Token Cost Calculator

```python
"""
token_cost.py — Estimate cost before calling a paid LLM.
"""
PRICING = {
    "gpt-4o":               {"input": 5.00,  "output": 15.00},
    "gpt-4o-mini":          {"input": 0.15,  "output": 0.60},
    "claude-3-5-sonnet":    {"input": 3.00,  "output": 15.00},
    "claude-3-haiku":       {"input": 0.25,  "output": 1.25},
    "gemini-1.5-flash":     {"input": 0.075, "output": 0.30},
    "gemini-1.5-pro":       {"input": 3.50,  "output": 10.50},
}

def estimate_cost(model: str, input_tokens: int, output_tokens: int) -> float:
    if model not in PRICING:
        raise ValueError(f"Unknown model: {model}")
    p = PRICING[model]
    cost = (input_tokens / 1_000_000 * p["input"]) + (output_tokens / 1_000_000 * p["output"])
    return round(cost, 6)

if __name__ == "__main__":
    for model in PRICING:
        cost = estimate_cost(model, input_tokens=10_000, output_tokens=2_000)
        print(f"{model:<25} 10K in + 2K out = ${cost:.4f}")
```

---

*This guide is maintained as a living document. Pricing and free tier limits change frequently — always verify at the official URLs before production use.*
