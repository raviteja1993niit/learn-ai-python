# DeepSeek R1 — Reasoning Model: Complete Reference

## Table of Contents
1. What is DeepSeek R1?  2. Architecture & Reasoning Process  3. Model Variants
4. Access Methods  5. DeepSeek API (OpenAI-compatible)  6. Reasoning Output Parsing
7. Temperature Recommendations  8. DeepSeek vs GPT-4o vs Gemini
9. RAG with DeepSeek  10. DeepSeek Coder  11. Running Locally with Ollama
12. Cost Comparison  13. Groq API Access  14. Best Practices

---

## 1. What is DeepSeek R1?

DeepSeek R1 is an open-weight reasoning model developed by DeepSeek (China).
It excels at complex, multi-step tasks: mathematics, coding, scientific reasoning, and logic.

### Key Differentiators
- **Chain-of-thought reasoning**: produces explicit reasoning in `<think>...</think>` tags
- **Open weights**: can be run locally or via third-party APIs
- **Cost efficiency**: ~10-30x cheaper than GPT-4 for equivalent reasoning quality
- **Specialisation**: outperforms GPT-4o on math benchmarks (MATH, AIME, Codeforces)

### When to Use R1
```
Complex math / proofs          → R1 (beats GPT-4o)
Advanced coding problems       → R1 or R1-distill-Qwen-32B
Multi-step logical reasoning   → R1
General conversation           → GPT-4o or Gemini 1.5 Flash
Creative writing               → GPT-4o or Claude
Fast, cheap classification     → gpt-4o-mini or Gemini Flash
Document understanding         → Gemini 1.5 Pro (2M context)
```

---

## 2. Architecture & Reasoning Process

### Chain-of-Thought with Think Tags
DeepSeek R1 surfaces its internal reasoning as `<think>` ... `</think>` blocks before the final answer.

```
User: "What is 17 * 23?"
R1 response:
<think>
I need to multiply 17 by 23.
17 * 20 = 340
17 * 3 = 51
340 + 51 = 391
</think>
17 * 23 = 391
```

### How to Parse
```python
def parse_r1_response(text):
    import re
    think_match = re.search(r'<think>(.*?)</think>', text, re.DOTALL)
    reasoning = think_match.group(1).strip() if think_match else ""
    answer = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL).strip()
    return {"reasoning": reasoning, "answer": answer}
```

### Architecture Notes
- Based on Mixture-of-Experts (MoE) transformer
- 671B total parameters, ~37B active per forward pass
- Trained with GRPO (Group Relative Policy Optimisation) — RL on reasoning quality
- Zero-shot chain-of-thought emerges naturally without CoT prompting

---

## 3. Model Variants

| Model                    | Size  | Description                              | Use case                    |
|--------------------------|-------|------------------------------------------|-----------------------------|
| deepseek-r1              | 671B  | Full reasoning model                     | Best quality                |
| deepseek-r1-zero         | 671B  | Pure RL trained, no SFT                  | Research / exploration      |
| deepseek-r1-distill-llama-70b  | 70B | Distilled into Llama-3 70B         | Balanced speed/quality      |
| deepseek-r1-distill-llama-8b   | 8B  | Distilled into Llama-3 8B          | Fast, local                 |
| deepseek-r1-distill-qwen-32b   | 32B | Distilled into Qwen-2.5 32B        | Code & math specialist      |
| deepseek-r1-distill-qwen-7b    | 7B  | Distilled into Qwen-2.5 7B         | Very fast local              |
| deepseek-v3              | 671B  | Instruction model (not reasoning)         | General tasks, cheap        |

### Choosing a Variant
- Production reasoning quality: deepseek-r1 via DeepSeek API
- Local with GPU: deepseek-r1-distill-qwen-32b (requires ~24GB VRAM)
- Very low resource: deepseek-r1-distill-llama-8b (requires ~8GB VRAM)
- Via Groq (fast inference): deepseek-r1-distill-llama-70b

---

## 4. Access Methods

### 4.1 DeepSeek API (Official)
```bash
pip install openai   # uses OpenAI-compatible client
```
- Base URL: https://api.deepseek.com
- Signup: https://platform.deepseek.com
- Models: deepseek-reasoner (R1), deepseek-chat (V3)

### 4.2 Ollama (Local)
```bash
ollama pull deepseek-r1:7b      # 7B distilled, ~4.5GB
ollama pull deepseek-r1:14b     # 14B distilled, ~9GB
ollama pull deepseek-r1:32b     # 32B distilled, ~20GB
ollama run deepseek-r1:7b
```

### 4.3 Groq API (Fast, Free Tier)
```bash
pip install groq
```
Models: deepseek-r1-distill-llama-70b (very fast, free tier available)

### 4.4 AWS Bedrock
Model ID: us.deepseek.r1-v1:0
Region: us-east-1, us-west-2

### 4.5 Azure AI Foundry
Model: deepseek-r1 (available in Azure marketplace)

---

## 5. DeepSeek API (OpenAI-Compatible)

The DeepSeek API is compatible with the OpenAI Python SDK — just swap the base_url.

```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ["DEEPSEEK_API_KEY"],
    base_url="https://api.deepseek.com"
)

response = client.chat.completions.create(
    model="deepseek-reasoner",    # R1
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Solve: If 2^x = 32, what is x?"}
    ]
)
print(response.choices[0].message.content)
# Note: reasoning_content is available in DeepSeek API response
reasoning = response.choices[0].message.reasoning_content
answer = response.choices[0].message.content
```

### reasoning_content Field
DeepSeek API returns reasoning separately from the final answer:
```python
msg = response.choices[0].message
print("Reasoning:", msg.reasoning_content)  # <think> content
print("Answer:", msg.content)               # final answer
```

---

## 6. Reasoning Output Parsing

For APIs that return raw text with `<think>` tags (Ollama, Groq):

```python
import re

def parse_deepseek_output(text):
    """Extract thinking and answer from DeepSeek R1 output."""
    # Extract think block
    think_pattern = re.compile(r'<think>(.*?)</think>', re.DOTALL)
    think_match = think_pattern.search(text)
    
    if think_match:
        thinking = think_match.group(1).strip()
        answer = think_pattern.sub('', text).strip()
    else:
        thinking = ""
        answer = text.strip()
    
    return {"thinking": thinking, "answer": answer}

# Example usage
raw = "<think>Let me calculate step by step...</think>\nThe answer is 42."
result = parse_deepseek_output(raw)
print("Thinking:", result["thinking"][:100])
print("Answer:", result["answer"])
```

---

## 7. Temperature Recommendations

DeepSeek recommends specific temperature settings for R1 models.

| Task                    | Recommended Temp | Notes                                    |
|-------------------------|-----------------|------------------------------------------|
| Math / coding           | 0.6             | Default recommendation                   |
| Logical reasoning       | 0.6-0.7         | Avoid 0 (greedy) — poor for reasoning    |
| Creative writing        | Not R1's strength| Use 0.7-0.9 if needed                   |
| Factual Q&A             | 0.1-0.3         | Lower for factual consistency            |
| Code generation         | 0.6             | Consistent with math recommendation      |

**Important**: Do NOT use temperature=0 (greedy decoding) with R1 — it degrades reasoning quality. DeepSeek officially recommends 0.6 as default.

```python
response = client.chat.completions.create(
    model="deepseek-reasoner",
    temperature=0.6,   # DeepSeek's recommended default
    messages=[...]
)
```

---

## 8. DeepSeek vs GPT-4o vs Gemini 1.5 Pro

| Benchmark        | DeepSeek R1 | GPT-4o     | Gemini 1.5 Pro |
|------------------|-------------|------------|----------------|
| MATH             | 97.3%       | 76.6%      | 67.7%          |
| AIME 2024        | 79.8%       | 9.3%       | 14.7%          |
| Codeforces       | 96.3%       | 67.3%      | 62.8%          |
| MMLU             | 90.8%       | 88.7%      | 83.7%          |
| HumanEval        | 92.7%       | 90.2%      | 87.8%          |
| Price (1M tok)   | ~$2.19 in   | ~$2.50 in  | ~$1.25 in      |
| Context          | 64K         | 128K       | 2M             |

*Benchmarks approximate, vary by source and version.*

---

## 9. RAG with DeepSeek R1

RAG pattern: retrieve relevant chunks → feed as context → R1 reasons over them.

```python
# rag_deep.py pattern
from openai import OpenAI
import numpy as np

client = OpenAI(api_key=DEEPSEEK_KEY, base_url="https://api.deepseek.com")

def embed(text):
    # Use any embedding model for retrieval
    from openai import OpenAI as OAI
    oai = OAI()
    return np.array(oai.embeddings.create(model="text-embedding-3-small", input=text).data[0].embedding)

def rag_query(question, docs):
    q_vec = embed(question)
    doc_vecs = [embed(d) for d in docs]
    scores = [float(np.dot(q_vec, dv)/(np.linalg.norm(q_vec)*np.linalg.norm(dv))) for dv in doc_vecs]
    top_docs = [docs[i] for i in sorted(range(len(docs)), key=lambda i: -scores[i])[:3]]
    
    context = "\n\n".join(top_docs)
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":f"Answer using ONLY this context:\n\n{context}"},
            {"role":"user","content":question}
        ]
    )
    return response.choices[0].message.content

print(rag_query("What is the main topic?", ["Doc 1...", "Doc 2...", "Doc 3..."]))
```

---

## 10. DeepSeek Coder

Specialised code generation model in the DeepSeek family.

```python
client = OpenAI(api_key=DEEPSEEK_KEY, base_url="https://api.deepseek.com")

def generate_code(spec, language="Python"):
    response = client.chat.completions.create(
        model="deepseek-chat",   # deepseek-v3 is excellent for code
        temperature=0.0,
        messages=[
            {"role":"system","content":f"You are an expert {language} developer. Write clean, documented code."},
            {"role":"user","content":spec}
        ]
    )
    return response.choices[0].message.content

code = generate_code("Write a binary search function with docstring and type hints.")
print(code)
```

---

## 11. Running Locally with Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh   # Linux/Mac
# Windows: download from https://ollama.ai

# Pull and run model
ollama pull deepseek-r1:7b
ollama run deepseek-r1:7b

# Use with OpenAI SDK
```

```python
from openai import OpenAI

# Ollama's OpenAI-compatible API
client = OpenAI(
    api_key="ollama",             # any string
    base_url="http://localhost:11434/v1"
)

response = client.chat.completions.create(
    model="deepseek-r1:7b",
    temperature=0.6,
    messages=[{"role":"user","content":"Solve: x^2 - 5x + 6 = 0"}]
)
print(response.choices[0].message.content)
```

---

## 12. Cost Comparison

| Provider          | Model                     | Input/1M  | Output/1M | Speed       |
|-------------------|---------------------------|-----------|-----------|-------------|
| DeepSeek API      | deepseek-reasoner (R1)    | $0.55     | $2.19     | Medium      |
| DeepSeek API      | deepseek-chat (V3)        | $0.27     | $1.10     | Fast        |
| Groq              | deepseek-r1-llama-70b     | Free tier | Free tier | Very fast   |
| OpenAI            | gpt-4o                    | $2.50     | $10.00    | Fast        |
| OpenAI            | o1                        | $15.00    | $60.00    | Slow        |
| Anthropic         | Claude 3.5 Sonnet         | $3.00     | $15.00    | Fast        |
| Ollama (local)    | deepseek-r1:7b            | Free      | Free      | GPU-limited |

---

## 13. Groq API Access

```bash
pip install groq
```

```python
from groq import Groq
import os

client = Groq(api_key=os.environ["GROQ_API_KEY"])

response = client.chat.completions.create(
    model="deepseek-r1-distill-llama-70b",
    messages=[{"role":"user","content":"Prove that sqrt(2) is irrational."}],
    temperature=0.6,
    max_tokens=4096
)

# Parse think tags from Groq response
from parse_deepseek_output import parse_deepseek_output
result = parse_deepseek_output(response.choices[0].message.content)
print("Answer:", result["answer"])
```

---

## 14. Best Practices

### Prompting R1
- Keep system prompts concise — R1 reasons better with focused instructions
- Do NOT add "think step by step" — R1 does this automatically
- For coding: specify language, style, docstring requirements
- For math: specify output format (LaTeX, plain text, numerical only)

### Handling Reasoning Output
- Always parse `<think>` blocks separately from the final answer
- Log reasoning for debugging — it shows you why R1 made a decision
- Reasoning tokens are NOT counted in output tokens for billing on DeepSeek API

### Performance
- Use temperature=0.6 as default for all reasoning tasks
- For multi-step agent tasks: DeepSeek R1 > GPT-4o (better planning)
- For tasks requiring large context (>64K): switch to Gemini 1.5 Pro

### Security
- Store DEEPSEEK_API_KEY in environment variables
- Rate limits: 8 RPM (free tier), 60 RPM (paid)
- Default timeout is 300s — R1 can take 30-120s for hard problems