# LLMs — Comprehensive Study Guide for Senior Software Engineers

> A standalone reference covering free & paid LLMs, fine-tuning, RAG, deployment, evaluation, and interview prep.
> Last updated: 2025

---

## 1. Why LLM Choice Matters

Choosing the right LLM is an **engineering decision**, not a marketing one. The wrong model can cost 10× more, respond 5× slower, or simply fail at your task.

### 1.1 The Core Tradeoff Triangle

```
         Capability
            /\
           /  \
          /    \
    Cost ------  Speed
```

Every LLM sits somewhere in this triangle. Moving toward one corner pulls you away from the others.

### 1.2 Key Dimensions to Evaluate

| Dimension | What It Means | Why It Matters |
|-----------|---------------|----------------|
| **Latency** | Time-to-first-token (TTFT) + generation speed (tok/s) | Real-time chat UX, agentic loops |
| **Cost** | $/1M input tokens + $/1M output tokens | Batch jobs, high-volume APIs |
| **Context window** | Max tokens in prompt + response | Long documents, multi-turn memory |
| **Capability** | Reasoning, coding, vision, multilingual | Task-specific accuracy |
| **Reliability** | Uptime, rate limits, SLA | Production systems |
| **Privacy** | Data residency, retention policies | Enterprise, healthcare, legal |
| **Quantization** | Full vs int8 vs int4 | Local hardware constraints |

### 1.3 Latency Breakdown

```
Total Latency = Network Round Trip
              + Queue Wait (cloud inference)
              + Prefill Time (processing your prompt tokens)
              + Decode Time (generating output tokens)
```

**Prefill** scales with prompt length. **Decode** scales with output length. For long-context RAG, prefill dominates.

### 1.4 Cost Anatomy

```
Total Cost = (Input Tokens × Input Price)
           + (Output Tokens × Output Price)
           + (Embedding Calls × Embedding Price)  # if applicable
           + (Fine-tune Training × Training Price) # if applicable
```

Output tokens are typically **2–4× more expensive** than input tokens across providers.

### 1.5 Use-Case Fit Matrix

| Use Case | Priority | Best Fit Category |
|----------|----------|-------------------|
| Real-time chat | Low latency, moderate quality | Fast inference (Groq, Cerebras) |
| Code generation | High quality, moderate latency | Strong coders (GPT-4o, Claude Sonnet) |
| Document summarization | Cost efficiency, high throughput | Cheap & fast (Gemini Flash, GPT-4o-mini) |
| RAG Q&A | Instruction following, JSON output | Balanced (GPT-4o-mini, Llama-3-70B) |
| Agentic tasks | Tool use, multi-step reasoning | Frontier (GPT-4o, Claude 3.5 Sonnet, o3) |
| Batch processing | Lowest cost, async OK | Cheapest available (Batch API, Haiku) |
| Long documents (>100K tok) | Context length | Gemini 1.5 Pro, Claude 3 series |
| Vision/multimodal | Image understanding | GPT-4o, Gemini 1.5 Pro, LLaVA (local) |
| Edge/offline | No internet, privacy | Ollama local (phi3, qwen2) |
| Fine-tuning | Customization | HuggingFace + LoRA, Together AI |
| Structured output | JSON reliability | GPT-4o, Instructor library |
| Embeddings | Semantic search | text-embedding-3-small, all-MiniLM |

---

## 2. Free LLMs — Complete Catalog

### 2.1 GitHub Copilot Free (Azure AI Inference)

**Provider:** Microsoft / GitHub  
**Access:** GitHub account (free tier — 50 GPT-4o requests/day + 10 Claude requests/day)  
**Base URL:** `https://models.inference.ai.azure.com`  
**Auth:** `gh auth token`

| Model | Context Window | Strengths | Weaknesses | Best For |
|-------|---------------|-----------|------------|----------|
| `gpt-4o` | 128K tokens | Reasoning, vision, tool use | Rate limited on free | Agentic tasks, code review |
| `gpt-4o-mini` | 128K tokens | Fast, cheap (paid), instruction following | Less capable than 4o | RAG, summarization |
| `o3-mini` | 200K tokens | Deep reasoning, math, code | Very slow (thinking) | Complex reasoning, algorithms |
| `claude-3-5-sonnet` | 200K tokens | Code quality, long context, nuance | Slower than GPT-4o | Code gen, document analysis |
| `Llama-3.3-70B-Instruct` | 128K tokens | Open-weight quality | Rate limited | General tasks, local parity |
| `Phi-4` | 16K tokens | Tiny but smart, local parity | Short context | Quick tasks, education |

**API Access:**
```python
import subprocess
from openai import OpenAI

# Get GitHub token automatically
token = subprocess.run(
    ["gh", "auth", "token"],
    capture_output=True, text=True
).stdout.strip()

client = OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=token
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Explain transformer attention in 3 sentences."}],
    max_tokens=300
)
print(response.choices[0].message.content)
```

---

### 2.2 Groq — Ultra-Fast Free Inference

**Provider:** Groq  
**URL:** https://console.groq.com  
**Free Tier:** Generous rate limits (up to 14,400 requests/day on some models)  
**Killer Feature:** Custom LPU (Language Processing Unit) — fastest public inference (~500–800 tok/s)

| Model | Context Window | Strengths | Weaknesses | Best For |
|-------|---------------|-----------|------------|----------|
| `llama-3.3-70b-versatile` | 128K | High quality open-weight | Larger → slightly slower | Complex tasks |
| `llama-3.1-8b-instant` | 128K | Fastest, near-instant | Less capable | Real-time chat, streaming |
| `llama3-70b-8192` | 8K | Mature, stable | Short context | General tasks |
| `mixtral-8x7b-32768` | 32K | MoE architecture, efficient | Older model | Long context free tasks |
| `gemma2-9b-it` | 8K | Google-trained, concise | Smaller model | Short Q&A |
| `deepseek-r1-distill-llama-70b` | 128K | Reasoning traces | Very verbose | Math, code reasoning |

```bash
pip install groq
```

```python
from groq import Groq

client = Groq(api_key="your_groq_api_key")  # or set GROQ_API_KEY env var

chat = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "Write a Python binary search implementation."}],
    temperature=0.1,
    max_tokens=500
)
print(chat.choices[0].message.content)
```

---

### 2.3 Together AI (Free $5 Credit)

**Provider:** Together AI  
**URL:** https://api.together.xyz  
**Free Tier:** $5 credit on signup (no expiry claimed), then pay-per-use  
**Strength:** Hundreds of open models, fine-tuning support

| Model | Context Window | Strengths | Best For |
|-------|---------------|-----------|----------|
| `meta-llama/Llama-3.3-70B-Instruct-Turbo` | 128K | Best open-weight | General purpose |
| `mistralai/Mixtral-8x22B-Instruct-v0.1` | 65K | Large MoE model | Complex reasoning |
| `Qwen/Qwen2.5-72B-Instruct-Turbo` | 32K | Multilingual, code | Non-English tasks |
| `deepseek-ai/DeepSeek-R1` | 64K | Reasoning chain | Math, science |
| `NousResearch/Hermes-3-Llama-3.1-70B` | 128K | Tool use, structured | Agentic tasks |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.together.xyz/v1",
    api_key="your_together_api_key"
)

response = client.chat.completions.create(
    model="meta-llama/Llama-3.3-70B-Instruct-Turbo",
    messages=[{"role": "user", "content": "Summarize the transformer paper key ideas."}]
)
print(response.choices[0].message.content)
```

---

### 2.4 Hugging Face Inference API (Free Serverless)

**Provider:** Hugging Face  
**URL:** https://huggingface.co/inference-api  
**Free Tier:** Rate-limited serverless inference on thousands of models  
**Strength:** Access to every public model, embeddings, image generation

| Model | Context | Strengths | Best For |
|-------|---------|-----------|----------|
| `meta-llama/Meta-Llama-3.1-70B-Instruct` | 128K | High quality | General |
| `mistralai/Mistral-7B-Instruct-v0.3` | 32K | Efficient | Quick inference |
| `google/gemma-2-9b-it` | 8K | Google quality small | Chat |
| `HuggingFaceH4/zephyr-7b-beta` | 4K | Instruction-tuned | Q&A |
| `Qwen/Qwen2.5-Coder-32B-Instruct` | 32K | Coding specialist | Code gen |

```python
from huggingface_hub import InferenceClient

client = InferenceClient(
    model="meta-llama/Meta-Llama-3.1-70B-Instruct",
    token="your_hf_token"  # or HF_TOKEN env var
)

response = client.chat_completion(
    messages=[{"role": "user", "content": "What is attention mechanism?"}],
    max_tokens=500
)
print(response.choices[0].message.content)
```

---

### 2.5 Google AI Studio / Gemini API (Free Tier)

**Provider:** Google DeepMind  
**URL:** https://aistudio.google.com  
**Free Tier:** 15 RPM (requests per minute), 1M tokens/day for Gemini Flash  
**Killer Feature:** 2M context window, best-in-class vision + audio

| Model | Context Window | Strengths | Weaknesses | Best For |
|-------|---------------|-----------|------------|----------|
| `gemini-1.5-flash` | 1M tokens | Fast, multimodal, very generous free | Less accurate than Pro | Summarization, vision, large docs |
| `gemini-1.5-flash-8b` | 1M tokens | Smallest, fastest | Limited reasoning | Light tasks, high volume |
| `gemini-1.5-pro` | 2M tokens | Best accuracy, huge context | 2 RPM on free | Complex long-context tasks |
| `gemini-2.0-flash` | 1M tokens | Latest, multimodal live | Newer, less tested | Cutting edge tasks |
| `gemini-2.0-flash-thinking` | 32K | Reasoning model | Slow | Math, logic |

```bash
pip install google-generativeai
```

```python
import google.generativeai as genai

genai.configure(api_key="your_gemini_api_key")

model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content(
    "Explain the difference between GPT and BERT architectures."
)
print(response.text)
```

---

### 2.6 Ollama — Local Models (Completely Free)

**Provider:** Ollama.ai (open-source)  
**URL:** https://ollama.ai  
**Free Tier:** Unlimited — runs on your machine  
**Killer Feature:** One-command model download and serve, OpenAI-compatible API

| Model | Size | Context | Strengths | Best For |
|-------|------|---------|-----------|----------|
| `llama3.2` | 3B/1B | 128K | Small, fast, Apple Silicon optimized | Light tasks |
| `llama3.1:8b` | 8B | 128K | Best quality/size ratio | General tasks |
| `llama3.1:70b` | 70B | 128K | Near-frontier quality | Complex tasks (needs 48GB RAM) |
| `qwen2.5:7b` | 7B | 128K | Multilingual, coding | Code + non-English |
| `qwen2.5-coder:7b` | 7B | 32K | Coding specialist | Code generation |
| `phi4` | 14B | 16K | Tiny, smart (Microsoft) | Efficient tasks |
| `mistral:7b` | 7B | 32K | Solid baseline | General chat |
| `gemma2:9b` | 9B | 8K | Google quality | Chat |
| `deepseek-r1:8b` | 8B | 64K | Reasoning traces | Math, logic |
| `nomic-embed-text` | 137M | 8K | Embeddings | Vector search |
| `llava:7b` | 7B | 4K | Vision + language | Image understanding |

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh  # Linux/Mac
# Windows: download from https://ollama.ai/download

# Pull and run a model
ollama pull llama3.1:8b
ollama run llama3.1:8b "Write a merge sort in Python"

# Start API server (runs on localhost:11434)
ollama serve
```

```python
# Using the OpenAI-compatible Ollama API
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # required but ignored
)

response = client.chat.completions.create(
    model="llama3.1:8b",
    messages=[{"role": "user", "content": "Explain vector embeddings."}]
)
print(response.choices[0].message.content)
```

```python
# Using the native ollama Python library
import ollama

response = ollama.chat(
    model='llama3.1:8b',
    messages=[{'role': 'user', 'content': 'What is RAG?'}]
)
print(response['message']['content'])
```

---

### 2.7 LM Studio — Local GUI

**Provider:** LM Studio (open-source)  
**URL:** https://lmstudio.ai  
**Platform:** Windows, macOS, Linux  
**Free Tier:** Unlimited local inference  
**Strength:** GUI model browser, downloads GGUF models from HuggingFace, OpenAI-compatible server

Key features:
- Browse and download models from HuggingFace Hub directly in UI
- **GGUF format** — quantized models (Q4_K_M for best quality/size)
- Start local OpenAI-compatible server with one click (`http://localhost:1234/v1`)
- Supports GPU offloading (partial VRAM usage)

```python
# LM Studio exposes OpenAI-compatible API
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:1234/v1",
    api_key="lm-studio"
)

response = client.chat.completions.create(
    model="lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

---

### 2.8 Jan.ai — Local Alternative

**Provider:** Jan.ai (open-source)  
**URL:** https://jan.ai  
**Strength:** Fully offline, privacy-first, extensions ecosystem  
**Models:** GGUF from HuggingFace, models hub built-in  
**API:** OpenAI-compatible at `http://localhost:1337/v1`

---

### 2.9 OpenRouter — Free Model Aggregator

**Provider:** OpenRouter  
**URL:** https://openrouter.ai  
**Free Tier:** Models marked `:free` are completely free (rate limited)  
**Strength:** Single API key for 100+ models, OpenAI-compatible

| Free Model | Context | Notes |
|------------|---------|-------|
| `meta-llama/llama-3.1-8b-instruct:free` | 128K | Good baseline |
| `mistralai/mistral-7b-instruct:free` | 32K | Fast |
| `google/gemma-2-9b-it:free` | 8K | Quality |
| `microsoft/phi-3-mini-128k-instruct:free` | 128K | Tiny but capable |
| `qwen/qwen-2-7b-instruct:free` | 32K | Multilingual |
| `openchat/openchat-7b:free` | 8K | Chat optimized |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="your_openrouter_api_key",
    default_headers={
        "HTTP-Referer": "https://your-app.com",
        "X-Title": "My App"
    }
)

response = client.chat.completions.create(
    model="meta-llama/llama-3.1-8b-instruct:free",
    messages=[{"role": "user", "content": "Explain LoRA fine-tuning."}]
)
print(response.choices[0].message.content)
```

---

### 2.10 Cerebras — Fast Free Inference

**Provider:** Cerebras  
**URL:** https://cloud.cerebras.ai  
**Free Tier:** 1M tokens/day free  
**Killer Feature:** Wafer-scale chip — reportedly 70B model at ~2000 tok/s  

| Model | Context | Speed |
|-------|---------|-------|
| `llama3.1-8b` | 128K | ~3000 tok/s |
| `llama3.1-70b` | 128K | ~2000 tok/s |
| `llama3.3-70b` | 128K | ~1800 tok/s |

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.cerebras.ai/v1",
    api_key="your_cerebras_api_key"
)

response = client.chat.completions.create(
    model="llama3.1-70b",
    messages=[{"role": "user", "content": "Generate a REST API in FastAPI."}]
)
print(response.choices[0].message.content)
```

---

### 2.11 Fireworks AI (Free Tier)

**Provider:** Fireworks AI  
**URL:** https://fireworks.ai  
**Free Tier:** $1 free credit, then pay-per-use (very cheap)  
**Strength:** FireFunction models for tool use, fast inference

| Model | Context | Notes |
|-------|---------|-------|
| `accounts/fireworks/models/llama-v3p1-70b-instruct` | 128K | General |
| `accounts/fireworks/models/firefunction-v2` | 128K | Best tool use |
| `accounts/fireworks/models/deepseek-r1` | 64K | Reasoning |
| `accounts/fireworks/models/qwen2p5-72b-instruct` | 128K | Multilingual |

---

### 2.12 Cloudflare Workers AI (Free Tier)

**Provider:** Cloudflare  
**URL:** https://developers.cloudflare.com/workers-ai/  
**Free Tier:** 10,000 neurons/day free (≈ 10,000 tokens)  
**Strength:** Edge inference, no cold starts, global CDN  
**Best For:** Lightweight edge applications

```python
import requests

CLOUDFLARE_ACCOUNT_ID = "your_account_id"
CLOUDFLARE_API_TOKEN = "your_api_token"

response = requests.post(
    f"https://api.cloudflare.com/client/v4/accounts/{CLOUDFLARE_ACCOUNT_ID}/ai/run/@cf/meta/llama-3.1-8b-instruct",
    headers={"Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}"},
    json={"messages": [{"role": "user", "content": "Hello!"}]}
)
print(response.json()["result"]["response"])
```

---

## 3. Paid LLMs — Complete Catalog

### 3.1 OpenAI

**URL:** https://platform.openai.com  
**Billing:** Pay-per-token, no minimum  

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| `gpt-4o` | 128K | $2.50 | $10.00 | Best all-rounder, vision, tool use |
| `gpt-4o-mini` | 128K | $0.15 | $0.60 | Best value, fast, smart |
| `gpt-4o-audio-preview` | 128K | $2.50 | $10.00 | Audio I/O |
| `o1` | 200K | $15.00 | $60.00 | Deep reasoning (slower) |
| `o1-mini` | 128K | $1.10 | $4.40 | Reasoning, cheaper |
| `o3-mini` | 200K | $1.10 | $4.40 | Latest reasoning model |
| `gpt-4-turbo` | 128K | $10.00 | $30.00 | (Legacy, use 4o instead) |
| `gpt-3.5-turbo` | 16K | $0.50 | $1.50 | (Legacy, use 4o-mini) |

**Batch API:** 50% discount for async batch jobs (24hr window)

```python
from openai import OpenAI

client = OpenAI(api_key="your_openai_api_key")

response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": "You are a senior software engineer."},
        {"role": "user", "content": "Review this Python code for bugs: def div(a,b): return a/b"}
    ],
    temperature=0.1,
    max_tokens=500
)
print(response.choices[0].message.content)
print(f"Tokens used: {response.usage.total_tokens}")
```

---

### 3.2 Anthropic Claude

**URL:** https://console.anthropic.com  
**Strength:** Long context understanding, nuanced writing, safety-focused, excellent at code

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| `claude-3-5-sonnet-20241022` | 200K | $3.00 | $15.00 | Best code quality, reasoning |
| `claude-3-5-haiku-20241022` | 200K | $0.80 | $4.00 | Fastest Claude, great value |
| `claude-3-opus-20240229` | 200K | $15.00 | $75.00 | Most capable (expensive) |
| `claude-3-sonnet-20240229` | 200K | $3.00 | $15.00 | (Superseded by 3.5) |
| `claude-3-haiku-20240307` | 200K | $0.25 | $1.25 | Cheapest Claude |

```python
import anthropic

client = anthropic.Anthropic(api_key="your_anthropic_api_key")

message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Explain the RLHF training process for LLMs."}
    ]
)
print(message.content[0].text)
```

---

### 3.3 Google Gemini (Paid Tier)

**URL:** https://ai.google.dev  

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| `gemini-1.5-pro` | 2M | $1.25 (≤128K) | $5.00 | Huge context, multimodal |
| `gemini-1.5-flash` | 1M | $0.075 (≤128K) | $0.30 | Cheapest capable model |
| `gemini-1.5-flash-8b` | 1M | $0.0375 | $0.15 | Ultra cheap |
| `gemini-2.0-flash` | 1M | $0.10 | $0.40 | Latest, fast |
| `gemini-2.0-pro` | 2M | TBD | TBD | Frontier (preview) |

---

### 3.4 Cohere

**URL:** https://cohere.com  
**Strength:** Enterprise RAG, excellent embeddings, structured output

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| `command-r-plus-08-2024` | 128K | $2.50 | $10.00 | Best Cohere model, RAG-native |
| `command-r-08-2024` | 128K | $0.15 | $0.60 | Great for RAG at low cost |
| `command-light` | 4K | $0.30 | $0.60 | Legacy |
| `embed-english-v3.0` | 512 tokens | $0.10/1M | — | Best English embeddings |
| `embed-multilingual-v3.0` | 512 tokens | $0.10/1M | — | 100+ languages |

---

### 3.5 Mistral AI

**URL:** https://mistral.ai  
**Strength:** European provider, strong open-weight models, function calling, JSON mode

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| `mistral-large-2411` | 128K | $2.00 | $6.00 | Best Mistral, frontier |
| `mistral-small-2409` | 128K | $0.20 | $0.60 | Great value |
| `codestral-2405` | 32K | $0.20 | $0.60 | Code specialist, fill-in-middle |
| `open-mistral-nemo` | 128K | $0.15 | $0.15 | Open-weight, Apache 2.0 |
| `open-mixtral-8x22b` | 64K | $2.00 | $6.00 | Large MoE |

---

### 3.6 Amazon Bedrock

**URL:** https://aws.amazon.com/bedrock/  
**Strength:** AWS integration, enterprise compliance, many model providers  
**Models via Bedrock:** Anthropic Claude, Meta Llama, Cohere, Mistral, Amazon Titan, AI21

```python
import boto3
import json

client = boto3.client("bedrock-runtime", region_name="us-east-1")

response = client.invoke_model(
    modelId="anthropic.claude-3-5-sonnet-20241022-v2:0",
    body=json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role": "user", "content": "What is transformer attention?"}]
    })
)
result = json.loads(response["body"].read())
print(result["content"][0]["text"])
```

---

### 3.7 Azure OpenAI

**URL:** https://azure.microsoft.com/en-us/products/ai-services/openai-service  
**Strength:** Enterprise SLA, data residency, private deployments, SOC2/HIPAA  
**Models:** GPT-4o, GPT-4o-mini, o1, o3-mini (same as OpenAI but deployed to your Azure resource)

```python
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint="https://your-resource.openai.azure.com",
    api_key="your_azure_openai_key",
    api_version="2024-08-01-preview"
)

response = client.chat.completions.create(
    model="gpt-4o",  # your deployment name
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

---

### 3.8 IBM watsonx

**URL:** https://www.ibm.com/watsonx  
**Strength:** Enterprise, IBM Granite models, governance/explainability  
**Models:** `ibm/granite-13b-instruct-v2`, `ibm/granite-34b-code-instruct`, Llama, Mistral via watsonx

---

## 4. When To Use Which LLM

### 4.1 Decision Matrix

| Use Case | Recommended Free | Recommended Paid | Why |
|----------|-----------------|-----------------|-----|
| **RAG Q&A** | Groq Llama-3.3-70B | GPT-4o-mini, Claude Haiku | Instruction following, JSON |
| **Code generation** | GitHub Copilot (gpt-4o) | Claude 3.5 Sonnet, GPT-4o | Best code quality |
| **Code completion** | Ollama qwen2.5-coder | Codestral, GPT-4o | Specialized code models |
| **Summarization** | Gemini Flash (free) | Gemini 1.5 Flash | Long context, cheap |
| **Agentic tasks** | GitHub Copilot (gpt-4o) | GPT-4o, Claude 3.5 Sonnet | Tool use reliability |
| **Structured JSON** | Groq + Instructor | GPT-4o + json_mode | JSON schema adherence |
| **Long documents (>100K)** | Gemini Flash (1M ctx) | Gemini 1.5 Pro | Huge context window |
| **Vision/images** | LLaVA (Ollama, local) | GPT-4o, Gemini 1.5 Pro | Multimodal capability |
| **Embeddings** | all-MiniLM (HF, local) | text-embedding-3-small | MTEB score + speed |
| **Real-time chat** | Groq / Cerebras | GPT-4o-mini | Ultra-fast inference |
| **Batch processing** | Together AI | OpenAI Batch API | Cost at scale |
| **Fine-tuning** | HuggingFace + LoRA | OpenAI (GPT-4o-mini) | Customization |
| **Edge/offline** | Ollama phi3/qwen2 | (N/A — must be local) | Privacy, no internet |
| **Multilingual** | Qwen2.5 (Ollama/Together) | Gemini 1.5 Pro, Mistral | Language coverage |
| **Math/reasoning** | DeepSeek-R1 (Groq) | o3-mini, o1 | Chain-of-thought |
| **Complex reasoning** | GitHub Copilot (o3-mini) | o1, o3, Claude Opus | Deep thinking |

### 4.2 Cost-Optimization Strategy

```
If volume > 1M tokens/day:
    → Use Batch API (50% discount on OpenAI)
    → Consider Gemini Flash (cheapest capable)
    → Route simple queries to mini models

If latency < 200ms required:
    → Groq or Cerebras (fastest public)
    → Ollama local (no network latency)

If privacy required:
    → Ollama or LM Studio (fully local)
    → Azure OpenAI with private endpoint

If budget = $0:
    → Ollama local (unlimited)
    → GitHub Copilot free (50 req/day)
    → Groq free tier (14,400 req/day)
    → Gemini Flash free (1M tok/day)
```

---

## 5. Setup Guides

### 5.1 GitHub Copilot Free

```bash
# Prerequisites
gh auth login  # authenticate GitHub CLI
pip install openai
```

```python
import subprocess
from openai import OpenAI

def get_github_client():
    token = subprocess.run(
        ["gh", "auth", "token"],
        capture_output=True, text=True
    ).stdout.strip()
    
    return OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=token
    )

client = get_github_client()

# List available models
# curl -H "Authorization: Bearer $(gh auth token)" \
#   https://models.inference.ai.azure.com/models

def chat(model: str, prompt: str, system: str = "You are a helpful assistant.") -> str:
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=1000
    )
    return response.choices[0].message.content

# Test different models
print(chat("gpt-4o", "What is the CAP theorem?"))
print(chat("o3-mini", "Prove that sqrt(2) is irrational."))
print(chat("claude-3-5-sonnet", "Write a Python async web scraper."))
```

---

### 5.2 Groq Setup

```bash
pip install groq
export GROQ_API_KEY="your_groq_api_key"
```

```python
import os
from groq import Groq

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def stream_response(model: str, prompt: str):
    """Stream tokens as they arrive — great for real-time UX."""
    stream = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        stream=True,
        temperature=0.7,
        max_tokens=1000
    )
    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print()  # newline at end

# Ultra-fast streaming
stream_response("llama-3.1-8b-instant", "Explain async/await in Python with examples.")

# Higher quality
stream_response("llama-3.3-70b-versatile", "Design a microservices architecture for an e-commerce app.")
```

---

### 5.3 Google Gemini Free Tier

```bash
pip install google-generativeai
export GOOGLE_API_KEY="your_gemini_api_key"
```

```python
import google.generativeai as genai
import os

genai.configure(api_key=os.environ.get("GOOGLE_API_KEY"))

# Text generation
model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content("Explain RLHF in simple terms.")
print(response.text)

# Vision — analyze an image
import PIL.Image

def analyze_image(image_path: str, question: str) -> str:
    vision_model = genai.GenerativeModel("gemini-1.5-flash")
    image = PIL.Image.open(image_path)
    response = vision_model.generate_content([question, image])
    return response.text

# Multi-turn chat
chat = model.start_chat(history=[])
response1 = chat.send_message("My name is Alice. Remember that.")
response2 = chat.send_message("What's my name?")
print(response2.text)  # Should recall "Alice"

# Count tokens before sending
tokens = model.count_tokens("This is my very long document...")
print(f"Estimated cost: {tokens.total_tokens} tokens")
```

---

### 5.4 Ollama Local Setup

```bash
# Install Ollama
# macOS: brew install ollama
# Linux: curl -fsSL https://ollama.ai/install.sh | sh
# Windows: download from https://ollama.ai/download

# Pull models
ollama pull llama3.1:8b
ollama pull nomic-embed-text  # for embeddings

# Start server (auto-starts on macOS/Linux after install)
ollama serve &
```

```python
import ollama
import subprocess

def list_local_models():
    result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
    print(result.stdout)

def chat_local(model: str, messages: list) -> str:
    response = ollama.chat(model=model, messages=messages)
    return response['message']['content']

def embed_local(text: str, model: str = "nomic-embed-text") -> list:
    response = ollama.embeddings(model=model, prompt=text)
    return response['embedding']

# Generate
reply = chat_local("llama3.1:8b", [
    {"role": "system", "content": "You are a Python expert."},
    {"role": "user", "content": "Write a decorator that caches function results."}
])
print(reply)

# Embed
vector = embed_local("The transformer architecture uses self-attention.")
print(f"Embedding dimension: {len(vector)}")  # 768 for nomic-embed-text
```

---

### 5.5 OpenRouter Free Models

```bash
pip install openai
export OPENROUTER_API_KEY="your_openrouter_api_key"
```

```python
from openai import OpenAI
import os

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ.get("OPENROUTER_API_KEY"),
    default_headers={
        "HTTP-Referer": "https://localhost:3000",
        "X-Title": "LLM Study App"
    }
)

FREE_MODELS = [
    "meta-llama/llama-3.1-8b-instruct:free",
    "mistralai/mistral-7b-instruct:free",
    "google/gemma-2-9b-it:free",
    "qwen/qwen-2-7b-instruct:free"
]

def compare_free_models(prompt: str):
    for model in FREE_MODELS:
        try:
            resp = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=200
            )
            print(f"\n--- {model} ---")
            print(resp.choices[0].message.content)
        except Exception as e:
            print(f"\n--- {model} FAILED: {e} ---")

compare_free_models("What is the difference between supervised and unsupervised learning?")
```

---

### 5.6 Hugging Face InferenceClient

```bash
pip install huggingface_hub
export HF_TOKEN="your_hf_token"  # from huggingface.co/settings/tokens
```

```python
from huggingface_hub import InferenceClient
import os

client = InferenceClient(token=os.environ.get("HF_TOKEN"))

# Text generation
response = client.text_generation(
    "def fibonacci(n):",
    model="bigcode/starcoder2-15b",
    max_new_tokens=200,
    temperature=0.1
)
print(response)

# Chat completion (for instruction-tuned models)
chat_client = InferenceClient(
    model="meta-llama/Meta-Llama-3.1-70B-Instruct",
    token=os.environ.get("HF_TOKEN")
)

response = chat_client.chat_completion(
    messages=[{"role": "user", "content": "What is gradient descent?"}],
    max_tokens=300
)
print(response.choices[0].message.content)

# Embeddings
embedding = client.feature_extraction(
    "The cat sat on the mat",
    model="sentence-transformers/all-MiniLM-L6-v2"
)
print(f"Embedding shape: {len(embedding)}")
```

---

### 5.7 OpenAI Standard Setup

```bash
pip install openai
export OPENAI_API_KEY="your_openai_api_key"
```

```python
from openai import OpenAI
import json

client = OpenAI()  # uses OPENAI_API_KEY env var

# Structured JSON output
response = client.chat.completions.create(
    model="gpt-4o-mini",
    response_format={"type": "json_object"},
    messages=[
        {"role": "system", "content": "Output valid JSON only."},
        {"role": "user", "content": "Extract: name, age, skills from 'Alice, 30, Python/Go developer'"}
    ]
)
data = json.loads(response.choices[0].message.content)
print(data)  # {"name": "Alice", "age": 30, "skills": ["Python", "Go"]}

# Function/Tool calling
tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current weather for a city",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {"type": "string", "description": "City name"}
            },
            "required": ["city"]
        }
    }
}]

response = client.chat.completions.create(
    model="gpt-4o-mini",
    tools=tools,
    tool_choice="auto",
    messages=[{"role": "user", "content": "What's the weather in Paris?"}]
)

if response.choices[0].message.tool_calls:
    tool_call = response.choices[0].message.tool_calls[0]
    args = json.loads(tool_call.function.arguments)
    print(f"Tool called: {tool_call.function.name}, args: {args}")
```

---

### 5.8 Anthropic Claude Setup

```bash
pip install anthropic
export ANTHROPIC_API_KEY="your_anthropic_api_key"
```

```python
import anthropic
import os

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

# Basic chat
message = client.messages.create(
    model="claude-3-5-haiku-20241022",
    max_tokens=1024,
    system="You are an expert software architect.",
    messages=[
        {"role": "user", "content": "What are the SOLID principles? Give Python examples."}
    ]
)
print(message.content[0].text)

# Vision — analyze image from URL
message_with_image = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {
                "type": "image",
                "source": {
                    "type": "url",
                    "url": "https://example.com/architecture-diagram.png"
                }
            },
            {"type": "text", "text": "Describe this architecture diagram."}
        ]
    }]
)
print(message_with_image.content[0].text)

# Streaming
with client.messages.stream(
    model="claude-3-5-haiku-20241022",
    max_tokens=500,
    messages=[{"role": "user", "content": "Write a quick sort algorithm."}]
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

---

## 6. LLM Comparison Tables

### 6.1 Speed Comparison (Tokens/Second — Approximate)

| Provider/Model | Tokens/Sec (approx) | Notes |
|----------------|---------------------|-------|
| Cerebras (llama3.1-70b) | ~2000 | Wafer-scale chip |
| Groq (llama3.1-8b) | ~700–900 | LPU hardware |
| Groq (llama3.1-70b) | ~280–350 | LPU hardware |
| Ollama (phi3, Apple M3) | ~60–120 | Local Metal GPU |
| Ollama (llama3.1:8b, Apple M3) | ~40–80 | Local Metal GPU |
| OpenAI (gpt-4o-mini) | ~80–120 | Cloud |
| OpenAI (gpt-4o) | ~40–60 | Cloud |
| Anthropic (claude-haiku) | ~80–100 | Cloud |
| Anthropic (claude-sonnet) | ~60–80 | Cloud |
| Google (gemini-flash) | ~100–150 | Cloud |

### 6.2 Context Window Comparison

| Model | Context Window |
|-------|---------------|
| Gemini 1.5 Pro | 2,000,000 tokens |
| Gemini 1.5 Flash | 1,000,000 tokens |
| Claude 3.5 Sonnet | 200,000 tokens |
| o3-mini | 200,000 tokens |
| GPT-4o | 128,000 tokens |
| Llama 3.1 (all sizes) | 128,000 tokens |
| Mistral Large | 128,000 tokens |
| Qwen 2.5-72B | 128,000 tokens |
| Mixtral 8x7B | 32,768 tokens |
| Phi-4 (Microsoft) | 16,384 tokens |
| Gemma 2 (Google) | 8,192 tokens |

### 6.3 Pricing Comparison (per 1M tokens, 2025)

| Model | Input $/1M | Output $/1M | Free Tier |
|-------|-----------|------------|-----------|
| Gemini 1.5 Flash-8B | $0.037 | $0.15 | 1M tok/day |
| Gemini 1.5 Flash | $0.075 | $0.30 | 1M tok/day |
| GPT-4o-mini | $0.15 | $0.60 | None |
| Claude 3 Haiku | $0.25 | $1.25 | None |
| Claude 3.5 Haiku | $0.80 | $4.00 | None |
| GPT-4o | $2.50 | $10.00 | GitHub Copilot |
| Claude 3.5 Sonnet | $3.00 | $15.00 | GitHub Copilot |
| Mistral Large | $2.00 | $6.00 | None |
| o3-mini | $1.10 | $4.40 | GitHub Copilot |
| o1 | $15.00 | $60.00 | None |
| Groq (all) | ~$0.05–0.90 | ~$0.08–0.90 | 14.4K req/day |
| Ollama (all) | $0 | $0 | Unlimited local |

### 6.4 Capability Radar

| Model | Reasoning | Coding | Vision | Tool Use | Multilingual | Speed |
|-------|-----------|--------|--------|----------|-------------|-------|
| GPT-4o | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Claude 3.5 Sonnet | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| o3-mini | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| Gemini 1.5 Pro | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Llama 3.3-70B | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Mistral Large | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Gemma 2-9B | ⭐⭐⭐ | ⭐⭐⭐ | ❌ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| phi-4 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 7. Fine-Tuning Free LLMs

### 7.1 Fine-Tuning vs RAG vs Prompt Engineering

#### When to Use Each Approach

| Approach | Best When | Cost | Freshness | Expertise |
|----------|-----------|------|-----------|-----------|
| **Prompt Engineering** | Quick wins, existing model good enough | $0 | Realtime | Low |
| **RAG** | Factual Q&A, proprietary data, freshness needed | Low ($) | Realtime | Medium |
| **Fine-Tuning** | Style/tone transfer, new domain vocabulary, consistent behavior | High ($$$) | Frozen at train time | High |
| **Fine-Tune + RAG** | Domain-specific tone AND factual accuracy | High ($$$) | Realtime | High |

#### Decision Flowchart (ASCII)

```
START: Do you need custom behavior?
        |
        v
Is the base model already 80% there with good prompts?
        |YES                    |NO
        v                       v
Use prompt engineering     Do you need realtime data?
(system prompt + few-shot)       |YES            |NO
                                 v               v
                               Use RAG      Is it about style/tone/format?
                                                |YES            |NO
                                                v               v
                                          Fine-tune        Is it a new domain
                                                          with unique vocabulary?
                                                               |YES
                                                               v
                                                         Fine-tune + RAG
```

---

### 7.2 Fine-Tuning with Hugging Face

#### Installing Dependencies

```bash
pip install transformers datasets trl peft accelerate bitsandbytes
```

#### SFT (Supervised Fine-Tuning) with QLoRA — Full Working Example

```python
# Fine-tune Llama-3.1-8B on a custom instruction dataset
# GPU required: T4 (Google Colab free), A100 (best), or Apple M2 Pro (slow)

import torch
from datasets import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments
)
from peft import LoraConfig, get_peft_model
from trl import SFTTrainer

# ─── 1. Configuration ─────────────────────────────────────────────────────────
MODEL_NAME = "meta-llama/Meta-Llama-3.1-8B-Instruct"
OUTPUT_DIR = "./llama3-finetuned"
HF_TOKEN = "your_hf_token"  # needs access to llama3

# ─── 2. QLoRA Config (4-bit quantization = fits in 16GB VRAM) ─────────────────
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True
)

# ─── 3. Load Model & Tokenizer ────────────────────────────────────────────────
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_TOKEN)
tokenizer.pad_token = tokenizer.eos_token
tokenizer.padding_side = "right"

model = AutoModelForCausalLM.from_pretrained(
    MODEL_NAME,
    quantization_config=bnb_config,
    device_map="auto",
    token=HF_TOKEN
)
model.config.use_cache = False
model.config.pretraining_tp = 1

# ─── 4. LoRA Config ───────────────────────────────────────────────────────────
lora_config = LoraConfig(
    r=16,                    # rank — higher = more params, better quality
    lora_alpha=32,           # scaling factor
    target_modules=[         # which attention layers to adapt
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj"
    ],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# Output: trainable params: ~20M out of 8B (0.25%) — huge savings!

# ─── 5. Prepare Dataset ───────────────────────────────────────────────────────
# Format: Alpaca-style instruction dataset
raw_data = [
    {
        "instruction": "Write a Python function to reverse a string.",
        "output": "def reverse_string(s: str) -> str:\n    return s[::-1]"
    },
    {
        "instruction": "What is a Python decorator?",
        "output": "A decorator is a function that wraps another function to add behavior..."
    },
    # Add 1000+ examples for real fine-tuning
]

def format_example(example):
    return {
        "text": f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are a Python expert.<|eot_id|><|start_header_id|>user<|end_header_id|>
{example['instruction']}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
{example['output']}<|eot_id|>"""
    }

dataset = Dataset.from_list([format_example(d) for d in raw_data])

# ─── 6. Training Arguments ────────────────────────────────────────────────────
training_args = TrainingArguments(
    output_dir=OUTPUT_DIR,
    num_train_epochs=3,
    per_device_train_batch_size=2,
    gradient_accumulation_steps=4,    # effective batch = 8
    learning_rate=2e-4,
    lr_scheduler_type="cosine",
    warmup_ratio=0.03,
    weight_decay=0.001,
    fp16=False,
    bf16=True,                         # use on Ampere+ GPUs (A100, A10G)
    logging_steps=10,
    save_steps=100,
    evaluation_strategy="no",
    report_to="none"
)

# ─── 7. Train ─────────────────────────────────────────────────────────────────
trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    args=training_args,
    dataset_text_field="text",
    max_seq_length=2048,
    packing=False
)

trainer.train()
trainer.save_model(OUTPUT_DIR)
print(f"Model saved to {OUTPUT_DIR}")
```

#### Hardware Requirements

| Approach | VRAM Needed | Example Hardware |
|----------|-------------|-----------------|
| Full fine-tune 7B | 80GB+ | 2× A100 80GB |
| QLoRA 7B (4-bit) | 8–10GB | T4 (Colab free), RTX 3080 |
| QLoRA 13B (4-bit) | 12–14GB | T4 16GB, RTX 3090 |
| QLoRA 70B (4-bit) | 40–48GB | A100 40GB |
| Inference 7B (4-bit) | 4–6GB | M1 MacBook, RTX 3060 |

---

### 7.3 Fine-Tuning Tools

#### Axolotl (YAML Config-Based)

```bash
pip install axolotl
# or: docker pull winglian/axolotl
```

```yaml
# axolotl_config.yaml
base_model: meta-llama/Meta-Llama-3.1-8B-Instruct
model_type: LlamaForCausalLM
tokenizer_type: AutoTokenizer

load_in_4bit: true
strict: false

datasets:
  - path: my_dataset.jsonl
    type: alpaca

dataset_prepared_path: last_run_prepared
val_set_size: 0.05

adapter: qlora
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - k_proj
  - v_proj
  - o_proj

sequence_len: 2048
sample_packing: false

gradient_accumulation_steps: 4
micro_batch_size: 2
num_epochs: 3
optimizer: paged_adamw_32bit
lr_scheduler: cosine
learning_rate: 2e-4

output_dir: ./outputs/qlora-llama3
```

```bash
axolotl train axolotl_config.yaml
```

#### Unsloth (2× Faster Fine-Tuning)

```bash
pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
```

```python
from unsloth import FastLanguageModel
import torch

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Meta-Llama-3.1-8B-Instruct",
    max_seq_length=2048,
    load_in_4bit=True,
)

model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
    lora_dropout=0,
    bias="none",
    use_gradient_checkpointing="unsloth",
    use_rslora=False,
)

# Unsloth claims 2x speed with 80% less VRAM via custom CUDA kernels
```

#### OpenAI Fine-Tuning API

```python
from openai import OpenAI
import json

client = OpenAI()

# 1. Upload training file (JSONL format)
# Each line: {"messages": [{"role": "user", ...}, {"role": "assistant", ...}]}
with open("training_data.jsonl", "rb") as f:
    file_response = client.files.create(file=f, purpose="fine-tune")
file_id = file_response.id

# 2. Start fine-tuning job
job = client.fine_tuning.jobs.create(
    training_file=file_id,
    model="gpt-4o-mini-2024-07-18",  # cheapest to fine-tune
    hyperparameters={"n_epochs": 3}
)
print(f"Job ID: {job.id}")

# 3. Check status
status = client.fine_tuning.jobs.retrieve(job.id)
print(f"Status: {status.status}")

# 4. Use fine-tuned model
if status.fine_tuned_model:
    resp = client.chat.completions.create(
        model=status.fine_tuned_model,
        messages=[{"role": "user", "content": "Your custom query"}]
    )
    print(resp.choices[0].message.content)
```

---

### 7.4 Free Training Compute

| Platform | GPU | Free Quota | Notes |
|----------|-----|-----------|-------|
| Google Colab (free) | T4 (16GB) | ~12 hrs/session | Disconnects on idle |
| Google Colab Pro | A100 (40GB) | $10/month | Best value paid |
| Kaggle Notebooks | P100 (16GB) | 30 hrs/week | Stable, no disconnects |
| Lightning AI | A10G (24GB) | 22 hrs free/month | Studio IDE |
| Hugging Face Spaces | CPU only | Free | ZeroGPU experimental |
| Vast.ai | A100 80GB | ~$1–2/hr | Cheapest A100 rental |
| RunPod | RTX 4090, A100 | Pay-per-use | Good UI |
| Lambda Labs | A100 40GB | ~$1.10/hr | Reserved instances |
| Google Cloud | T4 | $300 free credit (new) | Use TPU v4 too |

---

### 7.5 Datasets for Fine-Tuning

#### Popular Open Datasets

| Dataset | Size | Domain | Format |
|---------|------|--------|--------|
| **Alpaca** (Stanford) | 52K | General instruction | JSON |
| **Dolly** (Databricks) | 15K | General, commercial-ok | JSON |
| **OpenHermes-2.5** | 1M | Diverse instruction | JSON |
| **ShareGPT** | 70K | Real ChatGPT convos | JSON |
| **LIMA** | 1K | High quality curation | JSON |
| **CodeAlpaca** | 20K | Code generation | JSON |
| **Evol-Instruct** | 70K | Code, evolved complexity | JSON |
| **WizardCoder** | 78K | Code instruction | JSON |
| **MetaMathQA** | 395K | Math reasoning | JSON |

#### Creating Custom JSONL Dataset

```python
import json

def create_training_example(instruction: str, output: str, system: str = "") -> dict:
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": instruction})
    messages.append({"role": "assistant", "content": output})
    return {"messages": messages}

examples = [
    create_training_example(
        instruction="What is the time complexity of quicksort?",
        output="Quicksort has average O(n log n) and worst-case O(n²) time complexity...",
        system="You are a computer science tutor."
    ),
    # ... add more examples
]

# Write JSONL file (one JSON object per line)
with open("training_data.jsonl", "w") as f:
    for example in examples:
        f.write(json.dumps(example) + "\n")

print(f"Created {len(examples)} training examples")
```

#### Data Quality Tips

1. **Quality over quantity** — 1K high-quality examples > 100K noisy ones (LIMA paper)
2. **Diversity** — cover all your use cases proportionally
3. **Response length** — train on responses similar in length to what you want
4. **Format consistency** — if you want JSON output, train on JSON responses
5. **Validation split** — hold out 5–10% to monitor overfitting
6. **Deduplication** — remove near-duplicate examples
7. **Toxic/wrong content removal** — clean your dataset before training

---

## 8. RAG vs Fine-Tuning vs Prompt Engineering

### 8.1 Full Comparison Table

| Dimension | Prompt Engineering | RAG | Fine-Tuning |
|-----------|-------------------|-----|-------------|
| **Implementation Cost** | $0 (time only) | Low–Medium | High (compute) |
| **Data Freshness** | Static (prompt) | Real-time | Frozen at training |
| **Knowledge Type** | General | Factual/Retrieval | Behavioral/Style |
| **Hallucination Risk** | High | Low (with good retrieval) | Medium |
| **Latency** | Baseline | +100–500ms retrieval | Baseline |
| **Expertise Required** | Low | Medium | High |
| **Scalability** | Context window limit | Scales with vector DB | Model size limit |
| **Customization** | Low | Medium | High |
| **Token Cost** | Low | Medium (long prompts) | Training cost |
| **Maintenance** | Low | Medium (keep docs updated) | High (retrain for updates) |

### 8.2 Decision Tree

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR LLM PROBLEM                     │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────▼──────────────┐
          │  Base model with good    │
          │  prompting ≥ 80% good?   │
          └───────┬──────────┬───────┘
                YES│          │NO
                  ▼           ▼
        ┌──────────────┐  ┌──────────────────────┐
        │    DONE!     │  │ Need factual accuracy │
        │ Use prompt   │  │ or custom knowledge?  │
        │ engineering  │  └──────┬────────────────┘
        └──────────────┘       YES│
                                  ▼
                     ┌────────────────────────┐
                     │ Data changes frequently?│
                     └──────┬────────┬─────────┘
                           YES│       │NO
                              ▼       ▼
                          ┌──────┐  ┌──────────────┐
                          │ RAG  │  │ Fine-tune OR  │
                          └──────┘  │ RAG (both ok) │
                                    └──────────────┘
```

### 8.3 When RAG Beats Fine-Tuning

- **Your data changes frequently** (news, docs, product catalog)
- **You need to cite sources** (legal, medical, support)
- **Budget is limited** (RAG needs no GPU)
- **Interpretability matters** (can show retrieved chunks)
- **Multiple knowledge bases** (switch without retraining)

### 8.4 Hybrid Approach: Fine-Tune + RAG

```python
# Pattern: Fine-tuned model for domain expertise + RAG for factual grounding
# Use case: Customer support bot that knows your domain language AND your product docs

# 1. Fine-tune for: tone, terminology, response format, behavior
# 2. Add RAG for: product-specific facts, current pricing, policies

# Fine-tuned model: knows HOW to respond (style, format)
# RAG context: knows WHAT to respond with (facts, specifics)

system_prompt = """You are a technical support engineer for AcmeCorp software.
Use the provided context to answer questions accurately.
Always cite relevant documentation sections."""

def hybrid_response(user_query: str, retrieved_context: str) -> str:
    # Fine-tuned model handles style; RAG context handles facts
    full_prompt = f"""Context from documentation:
{retrieved_context}

User question: {user_query}"""
    
    # Use your fine-tuned model here
    return call_finetuned_model(system_prompt, full_prompt)
```

---

## 9. Custom LLM Deployment

### 9.1 Serving Local Models

#### Ollama — Simplest Option

```bash
# Start server
ollama serve

# Test REST API directly
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:8b", "prompt": "Hello world", "stream": false}'

# OpenAI-compatible endpoint
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1:8b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

#### vLLM — Production Grade, OpenAI-Compatible

```bash
pip install vllm

# Start server (requires CUDA GPU)
python -m vllm.entrypoints.openai.api_server \
  --model meta-llama/Meta-Llama-3.1-8B-Instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 8192 \
  --quantization awq  # optional: use quantized model
```

```python
# Use vLLM server with OpenAI client
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="ignore")
response = client.chat.completions.create(
    model="meta-llama/Meta-Llama-3.1-8B-Instruct",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

**vLLM advantages over Ollama:**
- **PagedAttention** — 3–5× higher throughput via KV cache optimization
- **Continuous batching** — handles multiple concurrent requests efficiently
- **Quantization support** — AWQ, GPTQ, FP8
- Best for production with concurrent users

#### llama.cpp Server

```bash
# Build llama.cpp
git clone https://github.com/ggerganov/llama.cpp && cd llama.cpp
cmake -B build -DLLAMA_METAL=ON  # macOS GPU
cmake --build build --config Release

# Download GGUF model
huggingface-cli download bartowski/Meta-Llama-3.1-8B-Instruct-GGUF \
  Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf --local-dir ./models

# Start server
./build/bin/llama-server \
  -m ./models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
  --host 0.0.0.0 --port 8080 \
  -ngl 35  # GPU layers (higher = more VRAM used)
```

#### Text Generation Inference (TGI) by HuggingFace

```bash
# Docker — easiest way
docker run --gpus all --shm-size 1g \
  -p 8080:80 \
  -v $PWD/models:/data \
  ghcr.io/huggingface/text-generation-inference:latest \
  --model-id meta-llama/Meta-Llama-3.1-8B-Instruct \
  --quantize bitsandbytes-nf4
```

---

### 9.2 Cloud Deployment Options

#### Hugging Face Inference Endpoints

```python
from huggingface_hub import InferenceEndpoint

# Deploy via UI at huggingface.co/inference-endpoints
# Then use:
endpoint = InferenceEndpoint.from_inference_endpoint(
    endpoint_url="https://xyz.endpoints.huggingface.cloud",
    token="your_hf_token"
)

response = endpoint.client.chat_completion(
    messages=[{"role": "user", "content": "Hello!"}]
)
```

#### Modal.com — Serverless GPU

```python
import modal

app = modal.App("llm-inference")
image = modal.Image.debian_slim().pip_install("vllm")

@app.cls(
    gpu="A10G",
    image=image,
    container_idle_timeout=300
)
class Model:
    @modal.enter()
    def load(self):
        from vllm import LLM
        self.llm = LLM(model="meta-llama/Meta-Llama-3.1-8B-Instruct")
    
    @modal.method()
    def generate(self, prompt: str) -> str:
        from vllm import SamplingParams
        outputs = self.llm.generate([prompt], SamplingParams(max_tokens=500))
        return outputs[0].outputs[0].text

@app.local_entrypoint()
def main():
    model = Model()
    print(model.generate.remote("What is deep learning?"))
```

---

## 10. LLM Evaluation & Benchmarks

### 10.1 Standard Benchmarks

| Benchmark | What It Measures | Notes |
|-----------|-----------------|-------|
| **MMLU** | Knowledge across 57 subjects | General knowledge breadth |
| **HumanEval** | Python code generation pass@1 | Coding ability |
| **MBPP** | More Python programming problems | Coding (broader) |
| **MT-Bench** | Multi-turn chat quality (GPT-4 judge) | Conversational AI |
| **LMSYS Arena** | Human preference (ELO rating) | Most representative of real use |
| **GSM8K** | Grade school math word problems | Basic reasoning |
| **MATH** | Competition math | Advanced reasoning |
| **HellaSwag** | Common sense completion | Language understanding |
| **TruthfulQA** | Truthfulness / hallucination | Factual accuracy |
| **GPQA** | PhD-level science questions | Deep expertise |

### 10.2 Task-Specific Evaluation

```python
# Evaluate a model on YOUR specific use case
import subprocess
from openai import OpenAI

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

def evaluate_model(model: str, test_cases: list) -> dict:
    """
    test_cases: [{"input": str, "expected": str, "type": "exact"|"semantic"}]
    """
    results = {"correct": 0, "total": len(test_cases), "failures": []}
    
    for case in test_cases:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": case["input"]}],
            temperature=0,
            max_tokens=200
        )
        actual = response.choices[0].message.content.strip()
        
        if case["type"] == "exact":
            is_correct = actual.lower() == case["expected"].lower()
        elif case["type"] == "contains":
            is_correct = case["expected"].lower() in actual.lower()
        else:
            is_correct = case["expected"].lower() in actual.lower()
        
        if is_correct:
            results["correct"] += 1
        else:
            results["failures"].append({
                "input": case["input"],
                "expected": case["expected"],
                "actual": actual
            })
    
    results["accuracy"] = results["correct"] / results["total"]
    return results

# Example test suite
test_suite = [
    {"input": "What is 2+2?", "expected": "4", "type": "contains"},
    {"input": "Capital of France?", "expected": "Paris", "type": "contains"},
]

for model in ["gpt-4o-mini", "gpt-4o"]:
    results = evaluate_model(model, test_suite)
    print(f"{model}: {results['accuracy']:.0%} accuracy ({results['correct']}/{results['total']})")
```

### 10.3 RAG Evaluation with RAGAS

```bash
pip install ragas
```

```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_recall, context_precision
from datasets import Dataset

# RAGAS evaluates 4 dimensions:
# - Faithfulness: Is the answer grounded in the context?
# - Answer Relevancy: Is the answer relevant to the question?
# - Context Recall: Does context contain the ground truth?
# - Context Precision: Is retrieved context relevant?

eval_data = {
    "question": ["What is the refund policy?"],
    "answer": ["You can get a full refund within 30 days."],
    "contexts": [["Our refund policy allows full refunds within 30 days of purchase."]],
    "ground_truth": ["30-day full refund policy"]
}

dataset = Dataset.from_dict(eval_data)
results = evaluate(
    dataset,
    metrics=[faithfulness, answer_relevancy, context_recall, context_precision]
)
print(results)
```

---

## 11. Embeddings — Free & Paid

### 11.1 Embedding Models Comparison

| Model | Provider | Dimensions | MTEB Score | Cost | Notes |
|-------|----------|-----------|-----------|------|-------|
| `text-embedding-3-large` | OpenAI | 3072 | 64.6 | $0.13/1M | Best accuracy |
| `text-embedding-3-small` | OpenAI | 1536 | 62.3 | $0.02/1M | Best value paid |
| `text-embedding-ada-002` | OpenAI | 1536 | 61.0 | $0.10/1M | Legacy |
| `embed-english-v3.0` | Cohere | 1024 | 64.5 | $0.10/1M | Best for RAG |
| `embed-multilingual-v3.0` | Cohere | 1024 | 62.4 | $0.10/1M | 100+ languages |
| `nomic-embed-text` | Nomic (Ollama) | 768 | 62.4 | Free (local) | Best free local |
| `all-MiniLM-L6-v2` | SBERT (HF) | 384 | 56.3 | Free (local) | Ultra fast, tiny |
| `all-mpnet-base-v2` | SBERT (HF) | 768 | 57.8 | Free (local) | Better than MiniLM |
| `mxbai-embed-large` | MixedBread (Ollama) | 1024 | 64.7 | Free (local) | Best free overall |
| `bge-large-en-v1.5` | BAAI (HF) | 1024 | 64.2 | Free (local) | Strong English |
| `gte-large` | Alibaba (HF) | 1024 | 63.1 | Free (local) | Good multilingual |

### 11.2 Local Embeddings with sentence-transformers

```bash
pip install sentence-transformers
```

```python
from sentence_transformers import SentenceTransformer
import numpy as np

# Load model (downloads automatically, cached locally)
model = SentenceTransformer("all-MiniLM-L6-v2")  # 80MB, fast
# model = SentenceTransformer("BAAI/bge-large-en-v1.5")  # 1.3GB, better

sentences = [
    "The transformer architecture uses self-attention mechanisms.",
    "BERT is a bidirectional encoder representation from transformers.",
    "Python is a programming language.",
    "Neural networks learn representations from data."
]

# Encode (batched, uses GPU if available)
embeddings = model.encode(sentences, normalize_embeddings=True)
print(f"Shape: {embeddings.shape}")  # (4, 384)

# Cosine similarity (normalized embeddings → dot product = cosine sim)
similarities = np.dot(embeddings, embeddings.T)
print("Similarity matrix:")
for i, s1 in enumerate(sentences):
    for j, s2 in enumerate(sentences):
        if i < j:
            print(f"  [{i}]↔[{j}]: {similarities[i][j]:.3f}  |  '{s1[:30]}...' vs '{s2[:30]}...'")
```

### 11.3 OpenAI Embeddings

```python
from openai import OpenAI
import numpy as np

client = OpenAI()

def get_embedding(text: str, model: str = "text-embedding-3-small") -> list:
    text = text.replace("\n", " ")  # clean newlines
    return client.embeddings.create(input=[text], model=model).data[0].embedding

def cosine_similarity(a: list, b: list) -> float:
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

# Batch embedding (more efficient)
texts = ["Hello world", "Bonjour monde", "Hola mundo"]
response = client.embeddings.create(input=texts, model="text-embedding-3-small")
embeddings = [item.embedding for item in response.data]

# Compare
print(cosine_similarity(embeddings[0], embeddings[1]))  # ~0.95 (same meaning)
print(cosine_similarity(embeddings[0], embeddings[2]))  # ~0.94
```

---

## 12. Practical Use Cases with Code

### UC1: Local RAG with Ollama + ChromaDB (Fully Free, No API Key)

```python
# pip install chromadb ollama
import ollama
import chromadb
from chromadb.utils import embedding_functions

# ─── Setup ────────────────────────────────────────────────────────────────────
EMBED_MODEL = "nomic-embed-text"   # pull with: ollama pull nomic-embed-text
CHAT_MODEL = "llama3.1:8b"         # pull with: ollama pull llama3.1:8b

# Ollama embedding function for ChromaDB
class OllamaEmbeddingFunction(chromadb.EmbeddingFunction):
    def __call__(self, texts):
        embeddings = []
        for text in texts:
            response = ollama.embeddings(model=EMBED_MODEL, prompt=text)
            embeddings.append(response["embedding"])
        return embeddings

# ─── Initialize ChromaDB ──────────────────────────────────────────────────────
client = chromadb.Client()
collection = client.create_collection(
    name="knowledge_base",
    embedding_function=OllamaEmbeddingFunction()
)

# ─── Index Documents ──────────────────────────────────────────────────────────
documents = [
    "Python decorators are functions that modify other functions using the @syntax.",
    "RAG stands for Retrieval Augmented Generation. It combines search with LLMs.",
    "LoRA is Low-Rank Adaptation for fine-tuning large models efficiently.",
    "FAISS is Facebook's library for efficient similarity search in dense vectors.",
    "The transformer attention mechanism computes query-key-value weighted sums."
]

collection.add(
    documents=documents,
    ids=[f"doc_{i}" for i in range(len(documents))]
)

# ─── RAG Query ────────────────────────────────────────────────────────────────
def rag_query(question: str, n_results: int = 3) -> str:
    # Retrieve relevant chunks
    results = collection.query(query_texts=[question], n_results=n_results)
    context = "\n".join(results["documents"][0])
    
    # Generate answer with local LLM
    response = ollama.chat(
        model=CHAT_MODEL,
        messages=[{
            "role": "user",
            "content": f"""Answer the question based on the context below.
Context:
{context}

Question: {question}
Answer:"""
        }]
    )
    return response["message"]["content"]

print(rag_query("What is LoRA?"))
print(rag_query("How does RAG work?"))
```

---

### UC2: Production RAG with GitHub Copilot Free + FAISS

```python
# pip install faiss-cpu openai numpy
import subprocess
import numpy as np
import faiss
from openai import OpenAI

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

# ─── Embed with GitHub Copilot Free ───────────────────────────────────────────
def embed(texts: list) -> np.ndarray:
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=texts
    )
    return np.array([item.embedding for item in response.data], dtype="float32")

# ─── Build FAISS Index ────────────────────────────────────────────────────────
documents = [
    {"id": 0, "text": "Python's GIL prevents true parallelism in CPU-bound tasks."},
    {"id": 1, "text": "asyncio uses an event loop to handle concurrent I/O operations."},
    {"id": 2, "text": "multiprocessing bypasses the GIL for CPU-bound work."},
    {"id": 3, "text": "threading is useful for I/O-bound tasks despite the GIL."},
    {"id": 4, "text": "concurrent.futures provides a high-level API for parallelism."}
]

doc_texts = [d["text"] for d in documents]
doc_embeddings = embed(doc_texts)

dimension = doc_embeddings.shape[1]  # 1536 for text-embedding-3-small
index = faiss.IndexFlatIP(dimension)   # Inner product = cosine sim (normalized)

# Normalize for cosine similarity
faiss.normalize_L2(doc_embeddings)
index.add(doc_embeddings)

# ─── Retrieval ────────────────────────────────────────────────────────────────
def retrieve(query: str, top_k: int = 3) -> list:
    q_embed = embed([query])
    faiss.normalize_L2(q_embed)
    scores, indices = index.search(q_embed, top_k)
    return [(documents[i]["text"], scores[0][j]) for j, i in enumerate(indices[0])]

def answer(question: str) -> str:
    chunks = retrieve(question)
    context = "\n".join([f"- {text}" for text, _ in chunks])
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "Answer only from the provided context."},
            {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
        ],
        temperature=0
    )
    return response.choices[0].message.content

print(answer("How do I do concurrent I/O in Python?"))
```

---

### UC3: Structured Output Extraction with Groq + Pydantic

```python
# pip install groq pydantic instructor
import instructor
from groq import Groq
from pydantic import BaseModel, Field
from typing import List, Optional

client = instructor.from_groq(Groq(), mode=instructor.Mode.JSON)

class Skill(BaseModel):
    name: str
    level: str = Field(description="beginner|intermediate|expert")
    years_experience: Optional[int] = None

class ResumeExtract(BaseModel):
    full_name: str
    years_total_experience: int
    current_role: str
    skills: List[Skill]
    education_level: str = Field(description="high school|bachelor|master|phd")
    summary: str = Field(description="2-sentence professional summary", max_length=300)

resume_text = """
John Smith is a Senior Software Engineer with 8 years of experience.
He currently works at TechCorp as a Principal Engineer. John has expert-level 
Python skills (7 years), intermediate Rust experience (2 years), and beginner 
knowledge of Zig. He holds a Master's degree in Computer Science from MIT.
"""

result = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    response_model=ResumeExtract,
    messages=[
        {"role": "user", "content": f"Extract structured info from this resume:\n\n{resume_text}"}
    ]
)

print(f"Name: {result.full_name}")
print(f"Role: {result.current_role}")
print(f"Skills: {[(s.name, s.level) for s in result.skills]}")
print(f"Education: {result.education_level}")
print(f"Summary: {result.summary}")
```

---

### UC4: Multi-Model Comparison

```python
# Compare the same prompt across multiple models
import subprocess
import time
from openai import OpenAI
from groq import Groq

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

clients = {
    "gpt-4o-mini (GitHub)": OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=gh_token
    ),
    "gpt-4o (GitHub)": OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=gh_token
    ),
}

groq_client = Groq()  # uses GROQ_API_KEY env var

PROMPT = "Explain the CAP theorem with a practical example in 3 bullet points."

results = {}

# GitHub Copilot Free models
for label, c in clients.items():
    model = label.split(" ")[0].replace("mini", "mini")
    if "4o-mini" in label:
        model = "gpt-4o-mini"
    elif "4o" in label:
        model = "gpt-4o"
    
    start = time.time()
    resp = c.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": PROMPT}],
        max_tokens=300
    )
    elapsed = time.time() - start
    results[label] = {
        "response": resp.choices[0].message.content,
        "latency": elapsed,
        "tokens": resp.usage.total_tokens if resp.usage else "N/A"
    }

# Groq models
for groq_model in ["llama-3.1-8b-instant", "llama-3.3-70b-versatile"]:
    start = time.time()
    resp = groq_client.chat.completions.create(
        model=groq_model,
        messages=[{"role": "user", "content": PROMPT}],
        max_tokens=300
    )
    elapsed = time.time() - start
    results[f"groq/{groq_model}"] = {
        "response": resp.choices[0].message.content,
        "latency": elapsed,
        "tokens": resp.usage.total_tokens if resp.usage else "N/A"
    }

# Print comparison
for model, data in results.items():
    print(f"\n{'='*60}")
    print(f"Model: {model}")
    print(f"Latency: {data['latency']:.2f}s | Tokens: {data['tokens']}")
    print(f"Response:\n{data['response']}")
```

---

### UC5: Streaming Chat with Groq (Ultra-Fast)

```python
import os
import time
from groq import Groq

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def streaming_chat(history: list, user_message: str) -> str:
    history.append({"role": "user", "content": user_message})
    
    full_response = ""
    tokens_generated = 0
    start_time = time.time()
    
    print(f"\n🤖 Assistant: ", end="", flush=True)
    
    stream = client.chat.completions.create(
        model="llama-3.1-8b-instant",  # fastest model
        messages=history,
        stream=True,
        temperature=0.7,
        max_tokens=1000
    )
    
    for chunk in stream:
        content = chunk.choices[0].delta.content
        if content:
            print(content, end="", flush=True)
            full_response += content
            tokens_generated += 1
    
    elapsed = time.time() - start_time
    tok_per_sec = tokens_generated / elapsed if elapsed > 0 else 0
    print(f"\n⚡ {tok_per_sec:.0f} tok/s ({elapsed:.2f}s total)")
    
    history.append({"role": "assistant", "content": full_response})
    return full_response

# Interactive CLI chat loop
history = [{"role": "system", "content": "You are a helpful AI assistant."}]
print("Chat started (type 'quit' to exit)")

while True:
    user_input = input("\n👤 You: ").strip()
    if user_input.lower() in ("quit", "exit", "q"):
        break
    if user_input:
        streaming_chat(history, user_input)
```

---

### UC6: Fine-Tuned Model Inference with Hugging Face

```python
# Run inference on a fine-tuned LoRA model
# pip install transformers peft torch
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

BASE_MODEL = "meta-llama/Meta-Llama-3.1-8B-Instruct"
LORA_ADAPTER = "./llama3-finetuned"  # path from fine-tuning section

# Load base + adapter
tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
base_model = AutoModelForCausalLM.from_pretrained(
    BASE_MODEL,
    torch_dtype=torch.float16,
    device_map="auto"
)
model = PeftModel.from_pretrained(base_model, LORA_ADAPTER)
model.eval()

def generate(prompt: str, max_new_tokens: int = 500) -> str:
    formatted = f"""<|begin_of_text|><|start_header_id|>user<|end_header_id|>
{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
"""
    inputs = tokenizer(formatted, return_tensors="pt").to(model.device)
    
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            eos_token_id=tokenizer.eos_token_id
        )
    
    # Decode only the new tokens (not the prompt)
    new_tokens = outputs[0][inputs["input_ids"].shape[1]:]
    return tokenizer.decode(new_tokens, skip_special_tokens=True)

print(generate("What is the time complexity of merge sort?"))
```

---

### UC7: Embeddings Comparison (Local vs API)

```python
# Compare local (sentence-transformers) vs API (OpenAI) embeddings
# pip install sentence-transformers openai numpy scipy
import subprocess
import numpy as np
import time
from sentence_transformers import SentenceTransformer
from openai import OpenAI
from scipy.spatial.distance import cosine

# ─── Setup ────────────────────────────────────────────────────────────────────
token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
openai_client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)
local_model = SentenceTransformer("all-MiniLM-L6-v2")

test_pairs = [
    ("The cat sat on the mat.", "A feline rested on a rug."),       # High similarity
    ("Python is great for data science.", "I love programming in Go."),  # Medium
    ("Quantum physics is complex.", "My favorite food is pizza."),       # Low
]

def cosine_sim(a, b):
    return 1 - cosine(a, b)

print(f"{'Pair':<60} {'Local':<8} {'API':<8} {'Diff':<8}")
print("-" * 90)

for text1, text2 in test_pairs:
    # Local embeddings
    t0 = time.time()
    local_embs = local_model.encode([text1, text2])
    local_time = (time.time() - t0) * 1000
    local_sim = cosine_sim(local_embs[0], local_embs[1])
    
    # API embeddings
    t0 = time.time()
    resp = openai_client.embeddings.create(
        model="text-embedding-3-small",
        input=[text1, text2]
    )
    api_time = (time.time() - t0) * 1000
    api_embs = [resp.data[0].embedding, resp.data[1].embedding]
    api_sim = cosine_sim(api_embs[0], api_embs[1])
    
    pair_label = f"'{text1[:25]}...' vs '{text2[:20]}...'"
    print(f"{pair_label:<60} {local_sim:.3f}   {api_sim:.3f}   {abs(local_sim-api_sim):.3f}")

print(f"\nLocal model: ~{local_time:.0f}ms | API: ~{api_time:.0f}ms (includes network)")
```

---

## 13. Interview Q&A — LLMs

**Q1:** What is the transformer attention mechanism and why is it important?

**A1:** Attention computes a weighted sum of **values**, where weights come from the compatibility between **queries** and **keys** via `softmax(QKᵀ/√d_k)V`. It's important because it allows any token to directly attend to any other token regardless of distance (unlike RNNs), enabling better long-range dependency capture and parallelizable training.

---

**Q2:** What is positional encoding in transformers and why is it needed?

**A2:** Transformers process all tokens in parallel and have no inherent sense of order. Positional encodings (sinusoidal functions at different frequencies in the original paper, or learned embeddings in BERT/GPT) are added to token embeddings to inject position information. Without them, "cat bit dog" and "dog bit cat" would produce the same output.

---

**Q3:** What's the architectural difference between GPT, BERT, and T5?

**A3:** 
- **GPT** (decoder-only): Autoregressive, causal attention (can only attend to past tokens), trained on next-token prediction. Best for generation.
- **BERT** (encoder-only): Bidirectional, masked language modeling (attends to all tokens), produces contextual embeddings. Best for classification, embeddings.
- **T5** (encoder-decoder): Full seq2seq transformer, trained on text-to-text tasks (everything framed as input→output text). Best for translation, summarization.

---

**Q4:** Explain RLHF (Reinforcement Learning from Human Feedback).

**A4:** RLHF is a 3-step process used to align LLMs:
1. **Supervised Fine-Tuning (SFT):** Fine-tune base model on human-written demonstrations.
2. **Reward Model (RM) Training:** Train a separate model to predict human preferences by comparing model outputs ranked by humans.
3. **PPO Optimization:** Use PPO (proximal policy optimization) reinforcement learning to optimize the SFT model to maximize the reward model's score, with a KL penalty to prevent drift from the original model.

---

**Q5:** What is DPO and how does it differ from PPO/RLHF?

**A5:** **DPO (Direct Preference Optimization)** directly fine-tunes the LLM on preference pairs (chosen vs rejected responses) without needing a separate reward model or RL loop. It reparameterizes the reward in terms of the language model itself, making training simpler and more stable. DPO is faster, uses less memory, and often performs comparably to PPO-RLHF. Most modern fine-tuning pipelines prefer DPO.

---

**Q6:** What causes LLM hallucinations and how do you mitigate them?

**A6:** **Causes:** Training data noise, model optimization for fluency over accuracy, out-of-distribution queries, overconfident probability distributions.

**Mitigations:**
- **RAG** — ground responses in retrieved facts
- **Temperature reduction** — lower temperature → more deterministic, less creative
- **Citation prompting** — instruct model to cite sources or say "I don't know"
- **Self-consistency** — sample multiple outputs, pick majority
- **Output verification** — use a second model to fact-check
- **Tool use** — give model access to search/calculators instead of relying on memory
- **Fine-tuning on refusals** — teach model to abstain when uncertain

---

**Q7:** What is a context window and what are solutions for its limitations?

**A7:** The **context window** is the maximum number of tokens the model can process at once (prompt + response). Limitations arise when documents exceed this limit.

**Solutions:**
- **RAG** — embed document chunks, retrieve relevant ones (most practical)
- **Long-context models** — Gemini 1.5 Pro (2M), Claude (200K)
- **Sliding window** — process document in overlapping chunks
- **Summarization chaining** — summarize chunks, then summarize summaries
- **Vector databases** — store entire corpus, query relevant sections

---

**Q8:** Explain temperature, top-p, and top-k sampling.

**A8:**
- **Temperature** (0–2): Scales logits before softmax. Low (0.1) = deterministic/focused. High (1.5) = creative/random. At 0 = greedy (always pick highest prob token).
- **Top-k** (integer): At each step, only sample from the k highest-probability tokens. Removes very improbable options.
- **Top-p (nucleus sampling)** (0–1): Only sample from tokens whose cumulative probability ≥ p. Dynamic alternative to top-k. p=0.9 means keep fewest tokens that together make up 90% of probability mass.

**Recommended settings:** Creative writing: temp=0.9, top-p=0.95. Code: temp=0.1, top-p=0.95. Factual: temp=0.

---

**Q9:** How do you count tokens and optimize costs?

**A9:** Use `tiktoken` (OpenAI) or model-specific tokenizers. Rule of thumb: 1 token ≈ 4 characters ≈ 0.75 words.

**Cost optimization:**
- Use smaller models for simple tasks (gpt-4o-mini vs gpt-4o)
- Use Batch API (50% discount on OpenAI)
- Cache repeated prompts (OpenAI prompt caching, 50% off for cached input)
- Compress system prompts
- Use streaming to detect early completion
- Log and monitor token usage per endpoint

```python
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o")
tokens = enc.encode("Hello, how are you?")
print(f"Token count: {len(tokens)}")  # 6 tokens
```

---

**Q10:** When should you use streaming vs non-streaming API calls?

**A10:**
- **Streaming:** User-facing chat (improves perceived latency), long responses (show progress), interactive tools. Implement with `stream=True` and process `delta.content` chunks.
- **Non-streaming:** Batch processing, when you need the full response before proceeding (e.g., JSON parsing, function calling), logging, caching responses.

Streaming doesn't reduce total latency but dramatically improves **perceived** latency — users see output immediately instead of waiting for the full response.

---

**Q11:** What is model quantization and what are the tradeoffs?

**A11:** Quantization reduces model weights from 32-bit (fp32) or 16-bit (fp16) floats to lower precision:

| Format | Memory | Quality Loss | Speed | Use |
|--------|--------|-------------|-------|-----|
| FP32 | 4 bytes/param | Baseline | Slowest | Training |
| FP16/BF16 | 2 bytes/param | Negligible | Fast | Training/inference |
| INT8 | 1 byte/param | Slight | Faster | Inference |
| INT4/NF4 | 0.5 bytes/param | Moderate | Fastest | Consumer GPU |
| GGUF Q4_K_M | ~0.5 bytes/param | Low (good quant) | Fast on CPU | llama.cpp, Ollama |

A 7B model in fp16 needs ~14GB VRAM; in Q4 it needs ~4GB.

---

**Q12:** What is prompt injection and how do you defend against it?

**A12:** **Prompt injection** is when malicious user input overrides system instructions (e.g., user says "Ignore previous instructions and...").

**Defenses:**
- **Input sanitization:** Detect injection patterns with a guard model
- **Output validation:** Check model output doesn't violate policy
- **Privilege separation:** Never give the LLM direct access to sensitive systems
- **Structured prompts:** Use message roles properly (system vs user)
- **Llama Guard / NeMo Guardrails:** Open-source safety classifiers
- **Canary tokens:** Insert hidden strings and check if they leak
- **Minimal permissions:** LLM agents should have least-privilege tool access

---

**Q13:** How do you monitor LLMs in production?

**A13:** Key metrics and tools:

**Metrics to track:**
- Latency (TTFT, total, p50/p95/p99)
- Token usage (input/output per request)
- Error rates (timeouts, refusals, errors)
- Cost per request/user
- Output quality (thumbs up/down, task completion)

**Tools:**
- **LangSmith** — LangChain's observability platform, trace every call
- **Langfuse** — Open-source, self-hostable alternative
- **Helicone** — Proxy-based, zero-code integration
- **Weights & Biases** — ML experiment + LLM tracing
- **OpenTelemetry** — Standard traces, works with any backend

---

**Q14:** What techniques reduce LLM inference latency?

**A14:**
- **Smaller models** — 8B vs 70B (10× faster)
- **Quantization** — INT4 reduces memory bandwidth
- **Speculative decoding** — small draft model + large verifier (2–3× speedup)
- **Batching** — process multiple requests simultaneously (vLLM's strength)
- **KV cache** — cache attention keys/values for system prompt (prompt caching)
- **Flash Attention** — memory-efficient attention implementation
- **Faster hardware** — Groq LPU, Cerebras WSE, NVIDIA H100
- **Streaming** — perceived latency improvement

---

**Q15:** What are multi-modal LLMs and how do they work?

**A15:** Multi-modal LLMs process multiple data types (text, images, audio, video). Architectures:

- **Image:** Vision encoder (e.g., CLIP ViT) converts image → token embeddings → fed to LLM alongside text tokens
- **Audio:** Whisper-like encoder converts audio → embeddings or transcription
- **Video:** Frame sampling + visual encoder

Examples: GPT-4o (text+image+audio), Gemini 1.5 Pro (text+image+audio+video), LLaVA (open-source vision).

The LLM learns to jointly reason across modalities through multimodal instruction-following datasets.

---

**Q16:** What are reasoning models (o1, o3, DeepSeek-R1) vs standard LLMs?

**A16:** Reasoning models use **chain-of-thought (CoT) reinforcement learning** to generate internal reasoning traces before answering:

- **Standard LLM:** prompt → immediate answer
- **Reasoning model:** prompt → [internal thinking tokens] → answer

Trained with **RLHF/GRPO** on problems where correctness is verifiable (math, code). The model learns to break problems down, verify steps, and backtrack.

**Tradeoffs:** Much slower (10–60× more tokens generated), much more expensive, but dramatically better at math, logic, and complex code. Use for complex problems, not for simple chat.

---

**Q17:** How does function calling / tool use work in LLMs?

**A17:** The LLM is trained to recognize when a tool should be called and output structured JSON instead of text:

```python
# 1. Define tools (JSON schema)
# 2. Model decides to call tool → outputs: {"name": "get_weather", "args": {"city": "Paris"}}
# 3. You execute the actual function
# 4. Return result to model
# 5. Model incorporates result into final response

# This enables: web search, code execution, database queries, API calls, etc.
# Key: model doesn't execute code — it requests execution via structured output
```

Modern implementations use **ReAct** (Reason + Act) pattern or **tool_choice** API parameter.

---

**Q18:** When does fine-tuning win over RAG? (Detailed)

**A18:**
**Fine-tuning wins when:**
- You need a specific response **style or tone** (formal, concise, domain-specific vocabulary)
- Teaching the model **new behaviors** (always respond in JSON, always cite page numbers)
- Domain-specific language where base model performs poorly (legal contracts, medical notes)
- Reducing latency (shorter prompts needed — no context injection)
- Privacy: can't send documents to cloud API

**RAG wins when:**
- Data changes frequently
- You need to cite specific source documents
- Knowledge base is too large to train on
- You need explainability (show retrieved chunks)
- Budget is limited (no GPU training cost)

**Rule of thumb:** Fine-tune for HOW to respond; RAG for WHAT to respond with.

---

**Q19:** How do vector databases differ and which should you choose?

**A19:**

| Database | Type | Strengths | Best For |
|----------|------|-----------|----------|
| **ChromaDB** | In-process/server | Simple, Python-native, free | Prototyping, small scale |
| **FAISS** | Library | Fastest, Facebook, no overhead | High-performance research |
| **Pinecone** | Managed cloud | Zero ops, scalable, metadata filtering | Production, teams |
| **Weaviate** | Open-source server | Multi-modal, GraphQL, BM25 hybrid | Hybrid search |
| **Qdrant** | Open-source server | Rust-based, fast, filtering | Production self-hosted |
| **Milvus** | Open-source server | Most scalable, complex queries | Billion-scale |
| **pgvector** | PostgreSQL extension | Existing Postgres users, SQL | Simple additions to existing DB |
| **Redis (RediSearch)** | In-memory | Ultra-fast, cache + vector | Low-latency applications |

**Decision:** Start with ChromaDB (easy). Move to Qdrant/Weaviate for production. Use pgvector if you're already on Postgres.

---

**Q20:** What are LLM caching strategies and production architecture patterns?

**A20:**

**Caching Strategies:**
- **Exact prompt cache:** Hash prompt → cache response (Redis/Memcached). Works for repeated identical queries.
- **Semantic cache (GPTCache, LangChain):** Embed query → find similar cached query → return cached response if above similarity threshold.
- **Provider-level cache:** OpenAI/Anthropic cache long system prompts automatically (prompt caching — 50% cost reduction).
- **KV cache:** Per-model attention cache for static prefix (in vLLM, prefix caching).

**Production Architecture Patterns:**
```
User Request
    │
    ▼
[Rate Limiter + Auth]
    │
    ▼
[Semantic Cache] ──hit──→ [Return cached response]
    │ miss
    ▼
[Prompt Router] → route to right model by complexity/cost
    │
    ▼
[LLM API / vLLM] → [Output Validator / Guardrails]
    │
    ▼
[Observability (LangSmith/Langfuse)] → Store traces
    │
    ▼
[Return to User]
```

---

## 14. References & Further Reading

### 14.1 Official Documentation

| Provider | Docs URL |
|----------|----------|
| OpenAI | https://platform.openai.com/docs |
| Anthropic | https://docs.anthropic.com |
| Google Gemini | https://ai.google.dev/docs |
| Groq | https://console.groq.com/docs |
| Ollama | https://github.com/ollama/ollama |
| HuggingFace | https://huggingface.co/docs |
| Together AI | https://docs.together.ai |
| OpenRouter | https://openrouter.ai/docs |
| Cohere | https://docs.cohere.com |
| Mistral | https://docs.mistral.ai |
| vLLM | https://docs.vllm.ai |
| LangChain | https://python.langchain.com/docs |
| LlamaIndex | https://docs.llamaindex.ai |
| TRL (HuggingFace) | https://huggingface.co/docs/trl |
| PEFT (LoRA) | https://huggingface.co/docs/peft |
| ChromaDB | https://docs.trychroma.com |
| FAISS | https://faiss.ai |

### 14.2 Free Courses

| Course | Provider | Focus |
|--------|----------|-------|
| **Practical Deep Learning** | fast.ai | DL fundamentals, top-down |
| **NLP Course** | Hugging Face | Transformers, fine-tuning, RAG |
| **ChatGPT Prompt Engineering** | DeepLearning.AI + OpenAI | Prompt engineering |
| **LangChain for LLM Apps** | DeepLearning.AI + LangChain | RAG, agents |
| **Building Systems with ChatGPT** | DeepLearning.AI | Production patterns |
| **Finetuning LLMs** | DeepLearning.AI + Lamini | Fine-tuning |
| **LLMOps** | DeepLearning.AI + Google | Deployment, monitoring |
| **Hugging Face Audio Course** | Hugging Face | Audio LLMs |
| **CS324: LLMs** | Stanford | Academic depth |
| **fast.ai Part 2** | fast.ai | Diffusion, from-scratch LLM |

### 14.3 Essential Papers

| Paper | Year | Why Important |
|-------|------|--------------|
| **Attention Is All You Need** (Vaswani et al.) | 2017 | Original transformer |
| **BERT** (Devlin et al.) | 2018 | Bidirectional pretraining |
| **GPT-3** (Brown et al.) | 2020 | Few-shot in-context learning |
| **InstructGPT** (Ouyang et al.) | 2022 | RLHF alignment |
| **LoRA** (Hu et al.) | 2021 | Low-rank adaptation |
| **QLoRA** (Dettmers et al.) | 2023 | 4-bit fine-tuning |
| **RAG** (Lewis et al.) | 2020 | Retrieval-augmented generation |
| **Chain-of-Thought** (Wei et al.) | 2022 | Reasoning via prompting |
| **LLaMA** (Touvron et al.) | 2023 | Open-weight model |
| **Mistral 7B** (Jiang et al.) | 2023 | Efficient small model |
| **Flash Attention** (Dao et al.) | 2022 | Fast memory-efficient attention |
| **DPO** (Rafailov et al.) | 2023 | Direct preference optimization |
| **Scaling Laws** (Kaplan et al.) | 2020 | How model size affects performance |
| **Chinchilla** (Hoffmann et al.) | 2022 | Optimal compute allocation |
| **Constitutional AI** (Anthropic) | 2022 | Self-supervised alignment |

### 14.4 YouTube Channels

| Channel | Focus |
|---------|-------|
| **Andrej Karpathy** | From-scratch LLM builds, deep understanding |
| **3Blue1Brown** | Visual math intuition (Neural Networks series) |
| **Yannic Kilcher** | Paper reviews, research frontier |
| **AI Explained** | Latest model releases, benchmarks |
| **Two Minute Papers** | Research summaries |
| **Sentdex** | Practical Python + ML coding |
| **Matt Wolfe** | AI tools overview |
| **Fireship** | Quick code demos |
| **AI Jason** | LangChain, agents tutorials |
| **Sam Witteveen** | Practical Gemini + LLM tutorials |

### 14.5 Communities

| Community | Platform | Focus |
|-----------|----------|-------|
| **r/LocalLLaMA** | Reddit | Local LLM running, models, hardware |
| **r/MachineLearning** | Reddit | Research, papers, academic |
| **HuggingFace Discord** | Discord | Open-source models, datasets |
| **LangChain Discord** | Discord | LangChain, RAG, agents |
| **Ollama Discord** | Discord | Ollama, local inference |
| **AI Alignment Forum** | Web | Safety, alignment research |
| **EleutherAI Discord** | Discord | Open research, GPT-Neo, Pythia |
| **LAION Discord** | Discord | Datasets, open training |

### 14.6 Tools & Libraries Quick Reference

```bash
# Core LLM SDKs
pip install openai anthropic google-generativeai groq mistralai cohere

# Local inference
pip install ollama  # Ollama Python client

# Fine-tuning
pip install transformers datasets trl peft accelerate bitsandbytes unsloth

# RAG & Vector DBs
pip install langchain langchain-community llama-index
pip install chromadb faiss-cpu qdrant-client pinecone-client

# Embeddings
pip install sentence-transformers

# Structured output
pip install instructor pydantic

# Evaluation
pip install ragas langsmith

# Token counting
pip install tiktoken

# Utilities
pip install huggingface_hub python-dotenv tenacity
```

---

> **Document Stats:** 14 sections, 40+ code examples, 20 interview Q&As, comprehensive tables  
> **Difficulty:** Senior Software Engineer level  
> **Time to read:** ~3–4 hours  
> **Last updated:** 2025
