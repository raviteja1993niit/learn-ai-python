# 🛠️ Prerequisites & Setup Guide

Complete step-by-step setup for all projects in this repository — including account creation, website links, installation, and configuration for every tool and API key required.

---

## 📋 Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Python Setup](#2-python-setup)
3. [Package Managers](#3-package-managers)
4. [LLM & AI API Keys](#4-llm--ai-api-keys)
5. [Search & Agent Tools](#5-search--agent-tools)
6. [LangChain Ecosystem](#6-langchain-ecosystem)
7. [Vector Databases](#7-vector-databases)
8. [Traditional Databases](#8-traditional-databases)
9. [Local AI Tools](#9-local-ai-tools)
10. [Cloud Platforms](#10-cloud-platforms)
11. [ML Tracking & MLOps](#11-ml-tracking--mlops)
12. [GPU & CUDA Setup](#12-gpu--cuda-setup)
13. [Per-Folder Setup](#13-per-folder-setup)
14. [Master `.env` Template](#14-master-env-template)
15. [Quick Start Checklist](#15-quick-start-checklist)

---

## 1. System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | Windows 10 / macOS 12 / Ubuntu 20.04 | Windows 11 / macOS 14 / Ubuntu 22.04 |
| RAM | 8 GB | 16–32 GB |
| Disk Space | 20 GB free | 50+ GB free |
| GPU | Optional | NVIDIA GPU (CUDA 11.8+) for deep learning / CV |
| Internet | Required | Broadband (model downloads can be several GB) |

---

## 2. Python Setup

### 2.1 Install Python

> 🌐 **Website:** https://www.python.org/downloads/
> Most projects require **Python 3.10+**. `agentic-ai` requires **Python 3.13**.

#### Option A — Direct Installer (Simplest)

```
1. Go to https://www.python.org/downloads/
2. Click "Download Python 3.11.x" (recommended for broadest compatibility)
3. Run the installer
4. ✅ CHECK "Add Python to PATH" before clicking Install
5. Verify in terminal:
```
```bash
python --version    # should print Python 3.11.x
pip --version
```

#### Option B — pyenv (Recommended — manage multiple Python versions)

> 🌐 **Website:** https://github.com/pyenv/pyenv

```bash
# ── Windows ──
winget install pyenv-win.pyenv-win
# Restart terminal, then:
pyenv install 3.11.9
pyenv global 3.11.9

# ── macOS ──
brew install pyenv
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ~/.zshrc
pyenv install 3.11.9
pyenv global 3.11.9

# ── Linux ──
curl https://pyenv.run | bash
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
pyenv install 3.11.9
pyenv global 3.11.9

# Verify
python --version
```

### 2.2 Python Version by Folder

| Folder | Minimum | Recommended | Notes |
|--------|---------|-------------|-------|
| agentic-ai | 3.13 | 3.13 | Uses `uv`, pyproject.toml |
| generative-ai | 3.8 | 3.11 | Streamlit / FastAPI apps |
| deep-learning | 3.7 | 3.10 | PyTorch, TensorFlow |
| computer-vision | 3.7 | 3.10 | OpenCV, YOLO, MediaPipe |
| data-science | 3.7 | 3.11 | Jupyter, Pandas, Scikit-learn |
| nlp | 3.8 | 3.11 | Transformers, spaCy |
| machine-learning | 3.7 | 3.10 | Scikit-learn, XGBoost |
| python-flask | 3.7 | 3.11 | Flask, FastAPI, Streamlit |
| python-basics | 3.8 | 3.11 | Core Python |
| blockchain | 3.7 | 3.10 | SHA, demos |
| ml-projects | 3.7 | 3.10 | End-to-end ML apps |
| cloud-deployment | 3.8 | 3.11 | AWS, GCP, Azure |
| databases | 3.8 | 3.11 | All DB drivers |
| big-data | 3.9 | 3.11 | PySpark, Dask, Kafka |

---

## 3. Package Managers

### 3.1 pip (Built-in — universal)

> 🌐 **Docs:** https://pip.pypa.io/

```bash
# Always upgrade pip first
python -m pip install --upgrade pip

# Install all dependencies for a project
pip install -r requirements.txt

# Install a specific package
pip install langchain openai

# Create a virtual environment (recommended per-project)
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS / Linux:
source venv/bin/activate

# Deactivate
deactivate
```

### 3.2 uv (Modern fast package manager — required for agentic-ai)

> 🌐 **Website:** https://docs.astral.sh/uv/
> 🌐 **GitHub:** https://github.com/astral-sh/uv
> ⚡ 10–100× faster than pip, built in Rust

#### Install uv

```bash
# ── Windows (PowerShell) ──
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# ── macOS / Linux ──
curl -LsSf https://astral.sh/uv/install.sh | sh

# Verify
uv --version
```

#### Use uv

```bash
# Navigate to a project with pyproject.toml
cd agentic-ai/some-project

# Install all dependencies (reads pyproject.toml / uv.lock)
uv sync

# Run a Python script inside the managed environment
uv run python main.py
uv run streamlit run app.py

# Add a new dependency
uv add langchain

# Create a new project
uv init my-project

# Use like pip (for requirements.txt projects)
uv pip install -r requirements.txt
```

### 3.3 Conda / Miniconda (used in deep-learning/pytorch-tutorial)

> 🌐 **Website:** https://docs.conda.io/en/latest/miniconda.html
> 🌐 **Download:** https://www.anaconda.com/download/

#### Install Miniconda (lighter than full Anaconda)

```
1. Go to https://docs.conda.io/en/latest/miniconda.html
2. Download the installer for your OS
3. Run installer, check "Add Miniconda to PATH"
4. Verify:
```
```bash
conda --version

# Create environment from a .yml file
conda env create -f pytorch_env.yml

# Activate
conda activate envpytorch

# List all environments
conda env list

# Deactivate
conda deactivate
```

---

## 4. LLM & AI API Keys

> ⚠️ Store all keys in a `.env` file. **Never commit `.env` to git.**
> Install python-dotenv: `pip install python-dotenv`

---

### 4.1 OpenAI (GPT-4, DALL-E, Whisper, Embeddings)

> 🌐 **Website:** https://openai.com/
> 🌐 **API Console:** https://platform.openai.com/
> 💰 **Pricing:** https://openai.com/pricing
> 📖 **Docs:** https://platform.openai.com/docs
> 💳 **Free Tier:** No free tier — requires billing ($5 minimum)
> 🔑 **Key format:** `sk-proj-...` or `sk-...`
> **Used in:** agentic-ai, generative-ai, data-science, nlp

#### Step-by-Step Setup

```
1. Go to https://platform.openai.com/
2. Click "Sign up" → create account (email or Google/Microsoft)
3. Verify your email
4. Go to https://platform.openai.com/api-keys
5. Click "+ Create new secret key"
6. Give it a name (e.g., "python-ai-projects")
7. Copy the key immediately — it is shown only once
8. Add billing: https://platform.openai.com/settings/organization/billing
   → Add credit card → buy $10–$20 credits to start
9. Set usage limits (optional): https://platform.openai.com/settings/organization/limits
```

```dotenv
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxx
```

```python
# Test in Python
from openai import OpenAI
client = OpenAI()  # reads OPENAI_API_KEY from env
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

---

### 4.2 Groq (Free, Ultra-Fast LLM Inference)

> 🌐 **Website:** https://groq.com/
> 🌐 **Console:** https://console.groq.com/
> 💰 **Pricing:** https://groq.com/pricing — FREE tier available
> 📖 **Docs:** https://console.groq.com/docs
> 💳 **Free Tier:** ✅ Yes — generous free tier (6000 tokens/min on Llama 3)
> 🔑 **Key format:** `gsk_...`
> **Models:** Llama 3.3 70B, Llama 3.1 8B, Mixtral 8x7B, Gemma 2 9B
> **Used in:** agentic-ai, generative-ai

#### Step-by-Step Setup

```
1. Go to https://console.groq.com/
2. Click "Start Building" → sign up with GitHub or Google
3. In the left sidebar, click "API Keys"
4. Click "Create API Key"
5. Give it a name (e.g., "python-ai")
6. Copy the key — starts with gsk_...
```

```dotenv
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
# Test in Python
from groq import Groq
client = Groq()  # reads GROQ_API_KEY from env
response = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

---

### 4.3 Google Gemini (Free + Generous Limits)

> 🌐 **Website:** https://ai.google.dev/
> 🌐 **API Console:** https://aistudio.google.com/
> 🌐 **Google Cloud:** https://console.cloud.google.com/
> 💰 **Pricing:** https://ai.google.dev/pricing
> 💳 **Free Tier:** ✅ Yes — Gemini 1.5 Flash free up to 15 req/min
> 🔑 **Key format:** `AIzaSy...`
> **Used in:** agentic-ai, generative-ai

#### Step-by-Step Setup

```
1. Go to https://aistudio.google.com/
2. Sign in with your Google account
3. Click "Get API key" (top-left area)
4. Click "Create API key in new project"
   (or select an existing Google Cloud project)
5. Copy the generated key starting with AIzaSy...
6. Optional — enable Vertex AI for enterprise:
   https://console.cloud.google.com/vertex-ai
```

```dotenv
GOOGLE_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
# Test in Python
import google.generativeai as genai
import os
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
model = genai.GenerativeModel("gemini-1.5-flash")
print(model.generate_content("Hello!").text)
```

---

### 4.4 Anthropic Claude

> 🌐 **Website:** https://www.anthropic.com/
> 🌐 **Console:** https://console.anthropic.com/
> 💰 **Pricing:** https://www.anthropic.com/pricing
> 📖 **Docs:** https://docs.anthropic.com/
> 💳 **Free Tier:** No — requires billing (credits expire after 1 year)
> 🔑 **Key format:** `sk-ant-...`
> **Models:** Claude 3.5 Sonnet, Claude 3 Opus, Claude 3 Haiku
> **Used in:** agentic-ai, generative-ai

#### Step-by-Step Setup

```
1. Go to https://console.anthropic.com/
2. Click "Sign up" → create account
3. Verify email
4. Go to "API Keys" in left sidebar
5. Click "Create Key"
6. Name the key and click "Create Key"
7. Copy the key — starts with sk-ant-api03-...
8. Add billing: https://console.anthropic.com/settings/billing
```

```dotenv
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
# Test in Python
import anthropic
client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env
message = client.messages.create(
    model="claude-3-5-haiku-20241022",
    max_tokens=100,
    messages=[{"role": "user", "content": "Hello!"}]
)
print(message.content[0].text)
```

---

### 4.5 Cohere

> 🌐 **Website:** https://cohere.com/
> 🌐 **Dashboard:** https://dashboard.cohere.com/
> 💰 **Pricing:** https://cohere.com/pricing
> 📖 **Docs:** https://docs.cohere.com/
> 💳 **Free Tier:** ✅ Yes — trial key with rate limits (no credit card)
> 🔑 **Key format:** random alphanumeric string
> **Used in:** generative-ai

#### Step-by-Step Setup

```
1. Go to https://dashboard.cohere.com/
2. Click "Sign up" → register with email or Google
3. Verify email
4. Dashboard → "API Keys" in left sidebar
5. A trial key is already generated for you — copy it
6. For production: click "+ New Trial Key" or upgrade plan
```

```dotenv
COHERE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 4.6 Mistral AI

> 🌐 **Website:** https://mistral.ai/
> 🌐 **Console:** https://console.mistral.ai/
> 💰 **Pricing:** https://mistral.ai/technology/#pricing
> 📖 **Docs:** https://docs.mistral.ai/
> 💳 **Free Tier:** ✅ Limited free tier for experimentation
> 🔑 **Key format:** alphanumeric
> **Used in:** generative-ai

#### Step-by-Step Setup

```
1. Go to https://console.mistral.ai/
2. Click "Sign up" → create account
3. Verify email
4. Go to "API Keys" in left navigation
5. Click "Create new key"
6. Name it and click "Create"
7. Copy the key shown — only visible once
8. Add billing if needed: https://console.mistral.ai/billing
```

```dotenv
MISTRAL_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 4.7 Hugging Face

> 🌐 **Website:** https://huggingface.co/
> 🌐 **Token Settings:** https://huggingface.co/settings/tokens
> 🌐 **Model Hub:** https://huggingface.co/models
> 💰 **Pricing:** https://huggingface.co/pricing
> 💳 **Free Tier:** ✅ Yes — free account, most models free to download
> 🔑 **Key format:** `hf_...`
> **Used in:** deep-learning, nlp, generative-ai

#### Step-by-Step Setup

```
1. Go to https://huggingface.co/
2. Click "Sign Up" → create account (email or GitHub/Google)
3. Verify email
4. Click your profile picture (top right) → "Settings"
5. In left sidebar → "Access Tokens"
6. Click "New token"
7. Name it (e.g., "python-ai") and select:
   - "Read" — for downloading models (sufficient for most projects)
   - "Write" — for uploading models to Hub
8. Click "Generate a token"
9. Copy the token — starts with hf_...
```

```dotenv
HUGGINGFACEHUB_API_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
# Login in Python (alternative to env var)
from huggingface_hub import login
login(token="hf_...")

# Or set via CLI
huggingface-cli login
```

---

### 4.8 DeepSeek

> 🌐 **Website:** https://www.deepseek.com/
> 🌐 **API Platform:** https://platform.deepseek.com/
> 💰 **Pricing:** https://platform.deepseek.com/api-docs/pricing
> 💳 **Free Tier:** ✅ $5 free credits on signup
> 🔑 **Key format:** `sk-...`
> **Used in:** generative-ai (gen-ai-with-deep-seek-r1)

#### Step-by-Step Setup

```
1. Go to https://platform.deepseek.com/
2. Click "Sign Up" → create account
3. Verify email
4. Click "API Keys" in left sidebar
5. Click "Create API Key"
6. Copy the key starting with sk-...
```

```dotenv
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 4.9 DeepInfra

> 🌐 **Website:** https://deepinfra.com/
> 🌐 **Dashboard:** https://deepinfra.com/dash
> 💳 **Free Tier:** ✅ $1.80 free credits on signup
> **Used in:** generative-ai (various models)

```
1. Go to https://deepinfra.com/
2. Click "Sign in" → use GitHub or Google
3. Go to https://deepinfra.com/dash/api_keys
4. Click "Create API Key"
5. Copy the key
```

```dotenv
DEEPINFRA_API_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 5. Search & Agent Tools

### 5.1 Tavily Search API

> 🌐 **Website:** https://tavily.com/
> 🌐 **Dashboard:** https://app.tavily.com/
> 💰 **Pricing:** https://tavily.com/#pricing
> 💳 **Free Tier:** ✅ 1,000 API calls/month free
> 🔑 **Key format:** `tvly-...`
> **Used in:** agentic-ai (LangChain/LangGraph agents for web search)

#### Step-by-Step Setup

```
1. Go to https://app.tavily.com/
2. Click "Sign Up" → register with email or Google
3. Verify email
4. Dashboard shows your API key immediately
   — key starts with tvly-...
5. Copy the key
6. Free plan: 1,000 searches/month
   Paid plans start at $35/month for 10,000 searches
```

```dotenv
TAVILY_API_KEY=tvly-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
from tavily import TavilyClient
client = TavilyClient(api_key=os.getenv("TAVILY_API_KEY"))
results = client.search("Latest AI news 2025")
```

---

### 5.2 SerpAPI (Google Search Results)

> 🌐 **Website:** https://serpapi.com/
> 🌐 **Dashboard:** https://serpapi.com/manage-api-key
> 💳 **Free Tier:** ✅ 100 searches/month free
> **Used in:** agentic-ai (Google search tool)

```
1. Go to https://serpapi.com/
2. Click "Register" → create account
3. Verify email
4. Go to Dashboard → "API Key" shown on main page
5. Copy the key
```

```dotenv
SERPAPI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 5.3 DuckDuckGo Search (No API Key Needed)

> 🌐 **Package:** https://pypi.org/project/duckduckgo-search/
> 💳 **Free:** ✅ Completely free, no key required
> **Used in:** agentic-ai (LangChain DuckDuckGo tool)

```bash
pip install duckduckgo-search

# No API key needed — works out of the box
```

---

## 6. LangChain Ecosystem

### 6.1 LangSmith (LLM Monitoring & Tracing)

> 🌐 **Website:** https://www.langchain.com/langsmith
> 🌐 **App:** https://smith.langchain.com/
> 💰 **Pricing:** https://www.langchain.com/pricing
> 💳 **Free Tier:** ✅ Free Developer plan (unlimited traces)
> 🔑 **Key format:** `ls__...`
> **Used in:** agentic-ai (trace LangChain / LangGraph runs)

#### Step-by-Step Setup

```
1. Go to https://smith.langchain.com/
2. Click "Sign Up" → register with email or Google
3. Verify email
4. In left sidebar → "Settings" (gear icon)
5. Click "API Keys" tab
6. Click "Create API Key"
7. Name it and click "Create API Key"
8. Copy the key — starts with ls__...
9. Create a project (optional):
   Left sidebar → "Projects" → "+ New Project"
```

```dotenv
LANGCHAIN_API_KEY=ls__xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
LANGCHAIN_TRACING_V2=true
LANGCHAIN_PROJECT=my-project-name
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com
```

```python
# Enable tracing — just set env vars, tracing is automatic
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
# Now all LangChain/LangGraph calls are traced in LangSmith
```

---

## 7. Vector Databases

### 7.1 ChromaDB (Local — No Account Needed)

> 🌐 **Website:** https://www.trychroma.com/
> 📖 **Docs:** https://docs.trychroma.com/
> 💳 **Free:** ✅ Fully local, open-source
> **Used in:** generative-ai, agentic-ai (RAG pipelines)

```bash
pip install chromadb

# No server needed — runs in-process
```

```python
import chromadb
client = chromadb.Client()                          # in-memory
# or
client = chromadb.PersistentClient(path="./chroma") # persists to disk
collection = client.get_or_create_collection("docs")
collection.add(documents=["Hello world"], ids=["1"])
results = collection.query(query_texts=["hello"], n_results=1)
```

---

### 7.2 Qdrant

> 🌐 **Website:** https://qdrant.tech/
> 🌐 **Cloud Console:** https://cloud.qdrant.io/
> 📖 **Docs:** https://qdrant.tech/documentation/
> 💳 **Free Tier:** ✅ Free cloud cluster (1 GB RAM, 0.5 CPU)
> **Used in:** databases, generative-ai, data-science

#### Option A — Local with Docker

```bash
# Install Docker Desktop first: https://www.docker.com/products/docker-desktop/
docker pull qdrant/qdrant
docker run -d -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/qdrant_storage:/qdrant/storage:z \
  qdrant/qdrant

# Verify
curl http://localhost:6333  # should return JSON
# UI: http://localhost:6333/dashboard
```

#### Option B — Qdrant Cloud (Free)

```
1. Go to https://cloud.qdrant.io/
2. Click "Sign Up" → create account
3. Click "Create Cluster"
4. Select "Free" tier → pick a region → click "Create"
5. After creation, click on the cluster → "API Keys"
6. Click "Create" → copy the API key
7. Also copy the cluster URL (format: https://xxx.aws.cloud.qdrant.io)
```

```dotenv
QDRANT_URL=https://xxxxxxxx.aws.cloud.qdrant.io
QDRANT_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
from qdrant_client import QdrantClient
client = QdrantClient(url=os.getenv("QDRANT_URL"), api_key=os.getenv("QDRANT_API_KEY"))
# Local:
# client = QdrantClient(host="localhost", port=6333)
```

---

### 7.3 Pinecone

> 🌐 **Website:** https://www.pinecone.io/
> 🌐 **Console:** https://app.pinecone.io/
> 📖 **Docs:** https://docs.pinecone.io/
> 💰 **Pricing:** https://www.pinecone.io/pricing/
> 💳 **Free Tier:** ✅ 1 free serverless index (2 GB storage)
> **Used in:** databases, generative-ai

#### Step-by-Step Setup

```
1. Go to https://app.pinecone.io/
2. Click "Sign Up Free" → register with email or Google
3. Verify email
4. In left sidebar → "API Keys"
5. Click "Create API key" (or use the default key)
6. Copy the key
7. Create an index:
   - Left sidebar → "Indexes" → "Create Index"
   - Name: "my-index"
   - Dimensions: 1536 (for OpenAI embeddings) or 768 (for HuggingFace)
   - Metric: Cosine
   - Cloud: AWS (free tier)
```

```dotenv
PINECONE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
from pinecone import Pinecone
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("my-index")
```

---

### 7.4 Weaviate

> 🌐 **Website:** https://weaviate.io/
> 🌐 **Cloud Console:** https://console.weaviate.cloud/
> 📖 **Docs:** https://weaviate.io/developers/weaviate
> 💳 **Free Tier:** ✅ Free 14-day sandbox (no credit card)
> **Used in:** databases

#### Step-by-Step Setup

```
1. Go to https://console.weaviate.cloud/
2. Click "Register" → create account
3. Verify email
4. Click "Create cluster"
5. Select "Free sandbox" → enter a name → click "Create"
6. Once created, click on the cluster
7. Copy the "Cluster URL" (e.g., https://xxx.weaviate.network)
8. Click "API keys" → copy the Admin key
```

```dotenv
WEAVIATE_URL=https://xxxxxxxx.weaviate.network
WEAVIATE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 7.5 Milvus (Local Docker)

> 🌐 **Website:** https://milvus.io/
> 📖 **Docs:** https://milvus.io/docs
> 💳 **Free:** ✅ Open-source

```bash
# Quickstart with Docker Compose
wget https://github.com/milvus-io/milvus/releases/download/v2.4.0/milvus-standalone-docker-compose.yml -O docker-compose.yml
docker-compose up -d

# UI: http://localhost:9091/webui/
# Port: 19530
```

---

## 8. Traditional Databases

### 8.1 Docker Desktop (Required for most DB setups)

> 🌐 **Website:** https://www.docker.com/products/docker-desktop/
> 📖 **Docs:** https://docs.docker.com/
> 💳 **Free:** ✅ Free for personal use

#### Install Docker Desktop

```
1. Go to https://www.docker.com/products/docker-desktop/
2. Click "Download Docker Desktop" for your OS
3. Run installer → follow prompts
4. Start Docker Desktop from Start Menu
5. Wait for the whale icon in taskbar to show "Docker Desktop is running"
```

```bash
# Verify
docker --version
docker run hello-world   # should print "Hello from Docker!"
```

---

### 8.2 PostgreSQL + pgvector

> 🌐 **Website:** https://www.postgresql.org/
> 🌐 **pgvector:** https://github.com/pgvector/pgvector
> 💳 **Free:** ✅ Open-source

#### Option A — Docker (Recommended)

```bash
# Run PostgreSQL with pgvector pre-installed
docker run -d \
  --name pgvector \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  pgvector/pgvector:pg16

# Connect with psql
docker exec -it pgvector psql -U postgres -d mydb

# Enable extension
CREATE EXTENSION IF NOT EXISTS vector;
```

#### Option B — Native Install on Windows

```
1. Go to https://www.postgresql.org/download/windows/
2. Click "Download the installer" (EDB installer)
3. Run installer — note the password you set for "postgres" user
4. After install, open pgAdmin (included) or psql
5. Install pgvector: https://github.com/pgvector/pgvector#installation
```

```dotenv
DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb
```

---

### 8.3 MongoDB

> 🌐 **Website:** https://www.mongodb.com/
> 🌐 **Atlas (Cloud):** https://www.mongodb.com/atlas
> 🌐 **Community Download:** https://www.mongodb.com/try/download/community
> 💳 **Free Tier:** ✅ Atlas M0 free cluster (512 MB)

#### Option A — Docker (Local)

```bash
docker run -d \
  --name mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -p 27017:27017 \
  mongo:latest
```

#### Option B — MongoDB Atlas (Cloud Free)

```
1. Go to https://www.mongodb.com/atlas
2. Click "Try Free" → create account
3. Choose "M0 Free" cluster → select cloud provider & region
4. Click "Create Cluster" (takes ~3 minutes)
5. Go to "Database Access" → "Add New Database User"
6. Go to "Network Access" → "Add IP Address" → "Allow from Anywhere"
7. Click "Connect" → "Connect your application"
8. Copy the connection string
```

```dotenv
MONGO_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/mydb
# or local:
MONGO_URI=mongodb://admin:password@localhost:27017/
```

---

### 8.4 MySQL

> 🌐 **Website:** https://www.mysql.com/
> 🌐 **Download:** https://dev.mysql.com/downloads/mysql/
> 💳 **Free:** ✅ Open-source Community Edition

```bash
# Docker
docker run -d \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=mydb \
  -p 3306:3306 \
  mysql:8

# Connect
docker exec -it mysql mysql -uroot -ppassword
```

```dotenv
MYSQL_URL=mysql+pymysql://root:password@localhost:3306/mydb
```

---

### 8.5 Redis

> 🌐 **Website:** https://redis.io/
> 🌐 **Cloud:** https://redis.io/try-free/
> 💳 **Free:** ✅ Open-source; Redis Cloud free tier 30 MB

```bash
# Docker
docker run -d --name redis -p 6379:6379 redis:latest

# Test
docker exec -it redis redis-cli ping  # → PONG
```

```dotenv
REDIS_URL=redis://localhost:6379
```

---

### 8.6 Neo4j (Graph Database)

> 🌐 **Website:** https://neo4j.com/
> 🌐 **AuraDB Free:** https://neo4j.com/cloud/platform/aura-graph-database/
> 💳 **Free Tier:** ✅ AuraDB Free — 1 free instance

```bash
# Docker
docker run -d \
  --name neo4j \
  -e NEO4J_AUTH=neo4j/password \
  -p 7474:7474 -p 7687:7687 \
  neo4j:latest

# Browser UI: http://localhost:7474
```

```dotenv
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password
```

---

### 8.7 Elasticsearch

> 🌐 **Website:** https://www.elastic.co/
> 🌐 **Cloud:** https://www.elastic.co/cloud
> 💳 **Free Tier:** ✅ 14-day free trial on Elastic Cloud

```bash
# Docker (single node for dev)
docker run -d \
  --name elasticsearch \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  -p 9200:9200 \
  docker.elastic.co/elasticsearch/elasticsearch:8.11.0

# Verify
curl http://localhost:9200
```

---

## 9. Local AI Tools

### 9.1 Ollama (Run LLMs Locally — No API Key Needed)

> 🌐 **Website:** https://ollama.com/
> 🌐 **Model Library:** https://ollama.com/library
> 📖 **Docs:** https://github.com/ollama/ollama
> 💳 **Free:** ✅ 100% free and local
> **Used in:** generative-ai/ollama-local-llms

#### Install Ollama

```
1. Go to https://ollama.com/download
2. Download for your OS:
   - Windows: OllamaSetup.exe
   - macOS: Ollama-darwin.zip (drag to Applications)
   - Linux: curl -fsSL https://ollama.com/install.sh | sh
3. Run Ollama — it starts a server at http://localhost:11434
```

```bash
# Pull models (downloads from Ollama library)
ollama pull llama3.2          # Meta Llama 3.2 3B (2 GB)
ollama pull llama3.1:8b       # Meta Llama 3.1 8B (4.7 GB)
ollama pull mistral            # Mistral 7B (4.1 GB)
ollama pull gemma2:9b          # Google Gemma 2 9B (5.5 GB)
ollama pull nomic-embed-text   # Embeddings model (274 MB)
ollama pull phi3               # Microsoft Phi-3 (2.3 GB)

# List downloaded models
ollama list

# Run a model in terminal
ollama run llama3.2

# Check server is running
curl http://localhost:11434/api/tags
```

```python
# Use with LangChain
from langchain_ollama import ChatOllama
llm = ChatOllama(model="llama3.2")
response = llm.invoke("Hello!")
```

---

### 9.2 Stable Diffusion (Image Generation)

> 🌐 **AUTOMATIC1111:** https://github.com/AUTOMATIC1111/stable-diffusion-webui
> 🌐 **Models:** https://civitai.com/ or https://huggingface.co/models
> 💳 **Free:** ✅ Fully local (needs GPU for reasonable speed)
> **Used in:** generative-ai/stable-diffusion

```bash
# Via diffusers (Python)
pip install diffusers transformers accelerate torch
```

```python
from diffusers import StableDiffusionPipeline
import torch
pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")  # use "cpu" if no GPU (slow)
image = pipe("a photo of a cat").images[0]
image.save("cat.png")
```

---

## 10. Cloud Platforms

### 10.1 AWS (Amazon Web Services)

> 🌐 **Website:** https://aws.amazon.com/
> 🌐 **Console:** https://console.aws.amazon.com/
> 🌐 **Free Tier:** https://aws.amazon.com/free/
> 💳 **Free Tier:** ✅ 12 months free for many services + always-free tier
> **Used in:** cloud-deployment (Bedrock, Lambda, SageMaker, S3, Beanstalk)

#### Step-by-Step: Create AWS Account & Configure CLI

```
Account Setup:
1. Go to https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Enter email, account name → click "Continue"
4. Fill in contact information
5. Add credit/debit card (won't be charged within free tier)
6. Verify phone number
7. Select "Basic support - Free"
8. Sign in to Console: https://console.aws.amazon.com/

Create IAM User (for programmatic access — DO NOT use root):
1. In AWS Console → search "IAM" → open IAM
2. Left sidebar → "Users" → "Create user"
3. Enter username (e.g., "python-ai-user")
4. Check "Provide user access to the AWS Management Console" if needed
5. Click "Next" → "Attach policies directly"
6. Search and add: "AdministratorAccess" (for learning; restrict in production)
7. Click "Create user"
8. Click on the user → "Security credentials" tab
9. "Access keys" → "Create access key" → "CLI" → "Create"
10. Download the .csv or copy both keys
```

```bash
# Install AWS CLI
# Windows:
winget install -e --id Amazon.AWSCLI
# macOS:
brew install awscli
# Linux:
sudo apt install awscli  # or download from https://aws.amazon.com/cli/

# Configure
aws configure
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/...
# Default region name: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity

# Install Python SDK
pip install boto3
```

```dotenv
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-east-1
```

---

### 10.2 Google Cloud Platform (GCP)

> 🌐 **Website:** https://cloud.google.com/
> 🌐 **Console:** https://console.cloud.google.com/
> 🌐 **Free Tier:** https://cloud.google.com/free
> 💳 **Free Tier:** ✅ $300 free credits for 90 days + always-free products
> **Used in:** cloud-deployment, generative-ai (Vertex AI)

#### Step-by-Step: Create GCP Account & Configure CLI

```
1. Go to https://cloud.google.com/
2. Click "Get started for free"
3. Sign in with Google account
4. Fill in billing information (won't be charged until you upgrade)
5. Complete setup → you get $300 free credits

Create a Project:
1. Console → click "Select a project" (top nav) → "New Project"
2. Enter project name → click "Create"
3. Note your Project ID

Install gcloud CLI:
1. Go to https://cloud.google.com/sdk/docs/install
2. Download installer for your OS and run it
3. Run: gcloud init
4. Follow prompts to log in and select project

Enable APIs needed:
- Vertex AI API: https://console.cloud.google.com/apis/library/aiplatform.googleapis.com
- Generative Language API (Gemini): https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
```

```bash
# Install
# Windows: https://cloud.google.com/sdk/docs/install-sdk#windows
# macOS:
brew install --cask google-cloud-sdk
# Linux:
curl https://sdk.cloud.google.com | bash

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Application Default Credentials (used by Python SDKs)
gcloud auth application-default login

# Install Python SDK
pip install google-cloud-aiplatform google-generativeai
```

```dotenv
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

---

### 10.3 Microsoft Azure

> 🌐 **Website:** https://azure.microsoft.com/
> 🌐 **Portal:** https://portal.azure.com/
> 🌐 **Free Account:** https://azure.microsoft.com/free/
> 💳 **Free Tier:** ✅ $200 credits for 30 days + 12 months free services
> **Used in:** cloud-deployment (Azure ML)

#### Step-by-Step: Create Azure Account & Configure CLI

```
1. Go to https://azure.microsoft.com/free/
2. Click "Start free" → sign in with Microsoft account (or create one)
3. Complete identity verification
4. Credit card required (for verification — won't charge within free tier)
5. Go to https://portal.azure.com/

Install Azure CLI:
1. Go to https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
2. Windows: winget install -e --id Microsoft.AzureCLI
3. macOS: brew install azure-cli
4. Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

```bash
# Login
az login

# Set subscription
az account set --subscription "Your Subscription Name"

# Install Python SDK
pip install azure-ai-ml azure-identity azure-cognitiveservices-vision-computervision

# Verify
az account show
```

---

## 11. ML Tracking & MLOps

### 11.1 Weights & Biases (W&B)

> 🌐 **Website:** https://wandb.ai/
> 🌐 **Dashboard:** https://wandb.ai/home
> 💰 **Pricing:** https://wandb.ai/pricing
> 💳 **Free Tier:** ✅ Free for individuals (unlimited public projects)
> **Used in:** cloud-deployment/weights-and-biases

#### Step-by-Step Setup

```
1. Go to https://wandb.ai/
2. Click "Sign up" → register with GitHub, Google, or email
3. Verify email
4. Dashboard → click your profile (top right) → "User Settings"
5. Scroll to "API keys" section
6. Click "New key" → copy the key shown
```

```bash
pip install wandb

# Login (stores key locally)
wandb login
# paste your API key when prompted

# Or use env var
export WANDB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

```python
import wandb
wandb.init(project="my-ml-project")
wandb.log({"accuracy": 0.95, "loss": 0.12})
wandb.finish()
```

```dotenv
WANDB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 11.2 MLflow (Local or Hosted)

> 🌐 **Website:** https://mlflow.org/
> 🌐 **Docs:** https://mlflow.org/docs/latest/index.html
> 💳 **Free:** ✅ Open-source, runs locally
> **Used in:** cloud-deployment/testmlflow

```bash
pip install mlflow

# Start local tracking server
mlflow server --host 0.0.0.0 --port 5000
# UI available at: http://localhost:5000

# Or use without a server (logs to ./mlruns)
mlflow ui   # view at http://localhost:5000
```

```python
import mlflow
mlflow.set_tracking_uri("http://localhost:5000")  # or omit for local
with mlflow.start_run():
    mlflow.log_param("lr", 0.01)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.sklearn.log_model(model, "model")
```

```dotenv
MLFLOW_TRACKING_URI=http://localhost:5000
```

---

### 11.3 Prefect (Workflow Orchestration)

> 🌐 **Website:** https://www.prefect.io/
> 🌐 **Cloud:** https://app.prefect.cloud/
> 💳 **Free Tier:** ✅ Prefect Cloud free tier (3 users, unlimited runs)
> **Used in:** cloud-deployment/prefect-workflow-orchestration

```bash
pip install prefect

# Option A — Local server
prefect server start   # UI at http://localhost:4200

# Option B — Prefect Cloud (free)
# 1. Go to https://app.prefect.cloud/ → sign up
# 2. Create a workspace
# 3. Copy API key from Settings → API Keys
prefect cloud login --key pnu_xxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 12. GPU & CUDA Setup

> **Required for:** deep-learning, computer-vision, generative-ai (large models)
> 🌐 **CUDA Downloads:** https://developer.nvidia.com/cuda-downloads
> 🌐 **cuDNN:** https://developer.nvidia.com/cudnn

### 12.1 Check GPU

```bash
# Check if NVIDIA GPU is present
nvidia-smi

# Expected output shows GPU name, CUDA version, driver version
```

### 12.2 Install CUDA Toolkit

```
1. Go to https://developer.nvidia.com/cuda-downloads
2. Select: Operating System → Architecture → Version → Installer Type
3. Download and run the installer
4. Restart computer after installation
5. Verify:
```

```bash
nvcc --version   # shows CUDA compiler version
nvidia-smi       # shows GPU info and driver
```

### 12.3 Install PyTorch with CUDA

> 🌐 **PyTorch Install Selector:** https://pytorch.org/get-started/locally/

```bash
# CUDA 11.8
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# CPU only (no GPU)
pip install torch torchvision torchaudio

# Verify GPU is available
python -c "import torch; print('CUDA:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
```

### 12.4 Install TensorFlow with GPU

> 🌐 **TF GPU Guide:** https://www.tensorflow.org/install/pip

```bash
# TensorFlow 2.13+ (GPU support built-in via tensorflow[and-cuda])
pip install tensorflow[and-cuda]

# Verify
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

---

## 13. Per-Folder Setup

### 🤖 agentic-ai

**Requires:** uv, Python 3.13, OPENAI_API_KEY or GROQ_API_KEY, TAVILY_API_KEY, LANGCHAIN_API_KEY

```bash
# Install uv (see Section 3.2)
cd agentic-ai/<project-folder>   # e.g., agentic-langgraph-crash-course

# Install dependencies
uv sync

# Create .env file
cat > .env << 'EOF'
OPENAI_API_KEY=sk-...
GROQ_API_KEY=gsk_...
GOOGLE_API_KEY=AIzaSy...
ANTHROPIC_API_KEY=sk-ant-...
TAVILY_API_KEY=tvly-...
LANGCHAIN_API_KEY=ls__...
LANGCHAIN_TRACING_V2=true
LANGCHAIN_PROJECT=agentic-ai
EOF

# Run a script
uv run python main.py

# Run a Streamlit app
uv run streamlit run app.py

# Run a FastAPI app
uv run uvicorn app:app --reload
```

---

### 📊 data-science

**Requires:** Python 3.11, Jupyter, pandas, numpy, scikit-learn. Some sub-projects need OPENAI_API_KEY.

```bash
cd data-science/<project-folder>

# Create and activate venv
python -m venv venv && venv\Scripts\activate   # Windows
# source venv/bin/activate                      # macOS/Linux

pip install -r requirements.txt

# Launch Jupyter
pip install jupyter
jupyter notebook

# For LLMOps backend
OPENAI_API_KEY=sk-...
DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb
QDRANT_URL=http://localhost:6333

uvicorn main:app --reload
```

---

### 🧠 generative-ai

**Requires:** Python 3.11, LLM API keys (at least one), python-dotenv, streamlit or fastapi

```bash
cd generative-ai/<project-folder>
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt

# .env (keep only keys for the provider the project uses)
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=AIzaSy...
ANTHROPIC_API_KEY=sk-ant-...
COHERE_API_KEY=...
GROQ_API_KEY=gsk_...
MISTRAL_API_KEY=...
HUGGINGFACEHUB_API_TOKEN=hf_...

# Streamlit UI apps
streamlit run app.py        # opens http://localhost:8501

# FastAPI apps
uvicorn main:app --reload   # opens http://localhost:8000

# For Ollama projects — start Ollama first:
ollama serve &
ollama pull llama3.2
python main.py
```

---

### 👁️ computer-vision

**Requires:** Python 3.10, OpenCV, PyTorch (GPU recommended for YOLO/detection)

```bash
cd computer-vision/<project-folder>
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt

# Core packages if no requirements.txt
pip install opencv-python mediapipe torch torchvision Pillow

# For YOLO (object detection)
pip install ultralytics
yolo predict model=yolov8n.pt source="image.jpg"

# For SAM (Segment Anything)
pip install segment-anything
# Download checkpoint: https://github.com/facebookresearch/segment-anything#model-checkpoints

# Check GPU
python -c "import torch; print(torch.cuda.is_available())"

# Run a webcam demo (common pattern)
python main.py --source 0   # 0 = webcam
```

---

### 🔬 deep-learning

**Requires:** Python 3.10, PyTorch or TensorFlow, Hugging Face Token (for gated models)

```bash
cd deep-learning/<project-folder>

# PyTorch projects
pip install torch torchvision torchaudio transformers datasets accelerate

# TensorFlow projects
pip install tensorflow keras

# Hugging Face fine-tuning
pip install transformers datasets peft trl bitsandbytes accelerate
HUGGINGFACEHUB_API_TOKEN=hf_...

# Conda-based project (pytorch-tutorial-master)
conda env create -f pytorch_env.yml
conda activate envpytorch
jupyter notebook

# Verify
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
python -c "import tensorflow as tf; print(tf.__version__)"
```

---

### 📝 nlp

**Requires:** Python 3.11, transformers, spaCy, NLTK, Hugging Face Token

```bash
cd nlp/<project-folder>
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt

# Common NLP stack
pip install transformers datasets spacy nltk sentence-transformers torch

# Download spaCy English model
python -m spacy download en_core_web_sm
python -m spacy download en_core_web_lg   # larger, more accurate

# Download NLTK data (interactive)
python -c "import nltk; nltk.download('popular')"

# For Whisper (speech-to-text)
pip install openai-whisper
# Also install ffmpeg: https://ffmpeg.org/download.html
winget install ffmpeg  # Windows

HUGGINGFACEHUB_API_TOKEN=hf_...

# For NLP deployment
uvicorn app:app --host 0.0.0.0 --port 8080
```

---

### ⚙️ machine-learning

**Requires:** Python 3.10, scikit-learn, pandas, numpy, Jupyter

```bash
cd machine-learning/<project-folder>
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt

# Common ML stack
pip install scikit-learn xgboost lightgbm catboost optuna \
            pandas numpy matplotlib seaborn plotly \
            lime shap evidently mlflow

# Jupyter
pip install jupyterlab
jupyter lab   # opens http://localhost:8888

# MLflow tracking
mlflow server --port 5000 &
MLFLOW_TRACKING_URI=http://localhost:5000
```

---

### 🚀 python-flask

**Requires:** Python 3.11, Flask/FastAPI/Streamlit/Gradio (varies by sub-project)

```bash
cd python-flask/<project-folder>
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt

# Flask app
set FLASK_APP=app.py          # Windows
export FLASK_APP=app.py        # macOS/Linux
flask run --port 5000

# FastAPI app
uvicorn main:app --reload --host 0.0.0.0 --port 8000
# Swagger UI: http://localhost:8000/docs

# Django app
python manage.py migrate
python manage.py runserver

# Streamlit app
streamlit run app.py          # http://localhost:8501

# Gradio app
python app.py                 # auto-opens browser

# Apps with Redis session/caching — start Redis first:
docker run -d -p 6379:6379 redis
```

---

### ☁️ cloud-deployment

**Requires:** AWS/GCP/Azure account + CLI, Docker, pip

```bash
# AWS Bedrock
cd cloud-deployment/aws-bedrock-main
pip install boto3
aws configure   # enter your Access Key, Secret Key, region
python main.py

# MLflow
cd cloud-deployment/testmlflow-main
pip install mlflow scikit-learn
mlflow server --host 0.0.0.0 --port 5000 &
python train.py

# Weights & Biases
cd cloud-deployment/weights-and-biases-main
pip install wandb
wandb login    # paste W&B API key
python train.py

# Docker-based deployment
cd cloud-deployment/docker-tutorial-main
docker build -t my-app .
docker run -p 8080:8080 my-app

# Prefect orchestration
cd cloud-deployment/prefect-workflow-orchestration-main
pip install prefect
prefect server start &
python flows.py
```

---

### 🔗 blockchain

**Requires:** Python 3.10, minimal dependencies

```bash
cd blockchain/<project-folder>
python -m venv venv && venv\Scripts\activate

# Install if requirements.txt exists
pip install -r requirements.txt   # if present

# Run
python main.py
```

---

### 🐍 python-basics

**Requires:** Python 3.11, minimal dependencies

```bash
cd python-basics/<project-folder>
python -m venv venv && venv\Scripts\activate

# Common tools used across subfolders
pip install pydantic mypy pytest black isort asyncio aiohttp

# Run pytest tests
pytest -v

# Type checking with mypy
mypy .

# Pydantic v2 projects
pip install pydantic

# Async projects
python asyncio_example.py

# Profiling
pip install memory-profiler line-profiler
python -m cProfile script.py
```

---

### 🗄️ databases

**Requires:** Docker (for running database servers), per-DB Python driver

```bash
# ── Start all databases with Docker ──
docker run -d --name chroma    -p 8000:8000 chromadb/chroma
docker run -d --name qdrant    -p 6333:6333 qdrant/qdrant
docker run -d --name postgres  -e POSTGRES_PASSWORD=password -p 5432:5432 pgvector/pgvector:pg16
docker run -d --name mongodb   -p 27017:27017 mongo
docker run -d --name redis     -p 6379:6379 redis
docker run -d --name neo4j     -e NEO4J_AUTH=neo4j/password -p 7474:7474 -p 7687:7687 neo4j
docker run -d --name es        -e "discovery.type=single-node" -p 9200:9200 elasticsearch:8.11.0

# ── Install Python drivers ──
pip install chromadb
pip install qdrant-client
pip install psycopg2-binary pgvector sqlalchemy
pip install pymongo motor            # MongoDB (motor = async)
pip install redis
pip install neo4j
pip install elasticsearch
pip install pinecone-client          # Pinecone cloud
pip install weaviate-client          # Weaviate cloud

# ── API keys for cloud vector DBs ──
PINECONE_API_KEY=...
QDRANT_URL=https://...cloud.qdrant.io
QDRANT_API_KEY=...
WEAVIATE_URL=https://...weaviate.network
WEAVIATE_API_KEY=...
```

---

### 📦 big-data

**Requires:** Java 11+ (for Spark/Kafka), Docker, Python 3.11

```bash
# ── Java (required for Spark and Kafka) ──
# Windows:
winget install Microsoft.OpenJDK.11
# macOS:
brew install openjdk@11
# Verify:
java -version

# ── Apache Spark / PySpark ──
pip install pyspark
# or with Conda:
conda install pyspark

# ── Apache Kafka ──
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ADVERTISED_HOST_NAME=localhost \
  wurstmeister/kafka

pip install kafka-python

# ── Apache Airflow ──
pip install apache-airflow
airflow db init
airflow webserver --port 8080 &
airflow scheduler &
# UI: http://localhost:8080

# ── Dask ──
pip install dask[distributed]
from dask.distributed import Client
client = Client()  # local cluster

# ── Polars ──
pip install polars

# ── Delta Lake ──
pip install delta-spark

# ── Databricks ──
# Sign up at https://databricks.com/try-databricks (free community edition)
pip install databricks-sdk
```

---

## 14. Master `.env` Template

Create a `.env` file in each project folder. Only fill in the keys that project needs.

```dotenv
# ═══════════════════════════════════════════════
#  LLM & AI APIs
# ═══════════════════════════════════════════════
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxx
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GOOGLE_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxx
COHERE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MISTRAL_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DEEPINFRA_API_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ═══════════════════════════════════════════════
#  Hugging Face
# ═══════════════════════════════════════════════
HUGGINGFACEHUB_API_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   # alias used by some libs

# ═══════════════════════════════════════════════
#  Search & Agent Tools
# ═══════════════════════════════════════════════
TAVILY_API_KEY=tvly-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SERPAPI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ═══════════════════════════════════════════════
#  LangChain / LangSmith
# ═══════════════════════════════════════════════
LANGCHAIN_API_KEY=ls__xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
LANGCHAIN_TRACING_V2=true
LANGCHAIN_PROJECT=my-project
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com

# ═══════════════════════════════════════════════
#  Vector Databases
# ═══════════════════════════════════════════════
PINECONE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WEAVIATE_URL=https://xxxxxxxx.weaviate.network
WEAVIATE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ═══════════════════════════════════════════════
#  Traditional Databases
# ═══════════════════════════════════════════════
DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb
MONGO_URI=mongodb://localhost:27017/mydb
REDIS_URL=redis://localhost:6379
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password

# ═══════════════════════════════════════════════
#  AWS
# ═══════════════════════════════════════════════
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-east-1

# ═══════════════════════════════════════════════
#  Google Cloud
# ═══════════════════════════════════════════════
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# ═══════════════════════════════════════════════
#  Azure
# ═══════════════════════════════════════════════
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ═══════════════════════════════════════════════
#  ML Tracking
# ═══════════════════════════════════════════════
WANDB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MLFLOW_TRACKING_URI=http://localhost:5000
```

### Load `.env` in Python

```python
from dotenv import load_dotenv
import os

load_dotenv()  # reads .env file in current directory

# Access keys
openai_key   = os.getenv("OPENAI_API_KEY")
groq_key     = os.getenv("GROQ_API_KEY")
google_key   = os.getenv("GOOGLE_API_KEY")
```

> ⚠️ **Security Rules:**
> - Never commit `.env` to git
> - Add `.env` to `.gitignore` immediately
> - Never print API keys in logs
> - Use separate keys per project in production

---

## 15. Quick Start Checklist

### Absolute Minimum (to run any project)

- [ ] **Python 3.11+** installed — https://www.python.org/downloads/
- [ ] **pip upgraded** — `python -m pip install --upgrade pip`
- [ ] **python-dotenv installed** — `pip install python-dotenv`
- [ ] **Virtual env created** — `python -m venv venv && venv\Scripts\activate`
- [ ] **requirements.txt installed** — `pip install -r requirements.txt`
- [ ] **.env file created** with relevant keys

### For agentic-ai Projects

- [ ] **Python 3.13** installed
- [ ] **uv installed** — https://docs.astral.sh/uv/
- [ ] `uv sync` run in project folder
- [ ] At least one LLM key: **Groq** (free) or OpenAI
- [ ] **Tavily API key** for search agents
- [ ] **LangSmith key** for tracing (optional but recommended)

### For generative-ai / LLM Projects

- [ ] **Groq API key** (free, fastest to get) — https://console.groq.com/
- [ ] **Google Gemini key** (free) — https://aistudio.google.com/
- [ ] Optional: OpenAI, Anthropic, Cohere, Mistral keys

### For Computer Vision / Deep Learning

- [ ] **CUDA** installed if using NVIDIA GPU
- [ ] **PyTorch with CUDA** — https://pytorch.org/get-started/locally/
- [ ] `nvidia-smi` shows your GPU

### For Database Projects

- [ ] **Docker Desktop** installed — https://www.docker.com/products/docker-desktop/
- [ ] Relevant DB running in Docker
- [ ] **Pinecone / Qdrant / Weaviate** cloud account for cloud vector DBs

### For Cloud Deployment

- [ ] **AWS CLI** configured — `aws configure`
- [ ] **Docker** installed and running
- [ ] **W&B account** — https://wandb.ai/ (for monitoring projects)

---

## 📊 Service Summary Table

| Service | Website | Free? | Key Env Var | Used By |
|---------|---------|-------|-------------|---------|
| OpenAI | https://platform.openai.com | ❌ Paid | OPENAI_API_KEY | agentic-ai, gen-ai, data-science |
| Groq | https://console.groq.com | ✅ Free | GROQ_API_KEY | agentic-ai, gen-ai |
| Google Gemini | https://aistudio.google.com | ✅ Free | GOOGLE_API_KEY | agentic-ai, gen-ai |
| Anthropic | https://console.anthropic.com | ❌ Paid | ANTHROPIC_API_KEY | agentic-ai, gen-ai |
| Cohere | https://dashboard.cohere.com | ✅ Free | COHERE_API_KEY | gen-ai |
| Mistral | https://console.mistral.ai | ✅ Limited | MISTRAL_API_KEY | gen-ai |
| DeepSeek | https://platform.deepseek.com | ✅ $5 credit | DEEPSEEK_API_KEY | gen-ai |
| Hugging Face | https://huggingface.co | ✅ Free | HUGGINGFACEHUB_API_TOKEN | nlp, deep-learning |
| Tavily | https://app.tavily.com | ✅ Free | TAVILY_API_KEY | agentic-ai |
| LangSmith | https://smith.langchain.com | ✅ Free | LANGCHAIN_API_KEY | agentic-ai |
| Pinecone | https://app.pinecone.io | ✅ 1 index | PINECONE_API_KEY | databases, gen-ai |
| Qdrant Cloud | https://cloud.qdrant.io | ✅ Free | QDRANT_API_KEY | databases, gen-ai |
| Weaviate | https://console.weaviate.cloud | ✅ Sandbox | WEAVIATE_API_KEY | databases |
| Ollama | https://ollama.com | ✅ Free | (none needed) | gen-ai |
| W&B | https://wandb.ai | ✅ Free | WANDB_API_KEY | cloud-deploy |
| AWS | https://aws.amazon.com | ✅ 12mo | AWS_ACCESS_KEY_ID | cloud-deploy |
| GCP | https://cloud.google.com | ✅ $300 | (gcloud auth) | cloud-deploy |
| Azure | https://azure.microsoft.com | ✅ $200 | AZURE_* | cloud-deploy |
| MongoDB Atlas | https://mongodb.com/atlas | ✅ Free | MONGO_URI | databases |

---

*Generated for: `python-ai` monorepo — 15 topic folders, 116 `requirements.txt` files, ~7,700 Python files.*
