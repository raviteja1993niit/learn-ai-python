# 🌪️ Mistral API & Open Models — Fast, Open, and Function-Capable

## What is this?
Mistral AI offers a family of open-weight and API-accessible models from the efficient 7B to the powerful Mistral-Large, plus Mixtral — a Mixture-of-Experts (MoE) architecture that routes tokens through sparse expert networks for strong performance at low inference cost. The `mistralai` Python client mirrors the OpenAI SDK design for easy migration.

## Why Learn It?
- Mistral-7B-Instruct outperforms GPT-3.5 on many benchmarks at a fraction of the cost
- Mixtral-8x7B uses only 2 of 8 expert networks per token — near-13B quality at ~7B compute
- Open-weight models can run locally via Ollama or vLLM — zero API cost, full data privacy
- Native function calling and JSON mode make Mistral models drop-in replacements for GPT-4o in agents

## Key Concepts
```python
# pip install mistralai langchain-mistralai ollama

# ── 1. Basic Chat Completion ──────────────────────────────────────────────────
from mistralai import Mistral

client = Mistral(api_key="YOUR_MISTRAL_API_KEY")   # or os.environ["MISTRAL_API_KEY"]

response = client.chat.complete(
    model="mistral-large-latest",
    messages=[
        {"role": "system", "content": "You are a concise Python tutor."},
        {"role": "user",   "content": "Explain list comprehensions in 2 sentences."},
    ],
    temperature=0.3,
    max_tokens=256,
)
print(response.choices[0].message.content)

# ── 2. Streaming ──────────────────────────────────────────────────────────────
stream = client.chat.stream(
    model="open-mixtral-8x7b",
    messages=[{"role": "user", "content": "Write a haiku about gradient descent."}],
)
for chunk in stream:
    delta = chunk.data.choices[0].delta.content
    if delta:
        print(delta, end="", flush=True)

# ── 3. Embeddings ─────────────────────────────────────────────────────────────
embed_resp = client.embeddings.create(
    model="mistral-embed",
    inputs=["What is machine learning?", "What is deep learning?"],
)
vectors = [e.embedding for e in embed_resp.data]
print(f"Embedding dim: {len(vectors[0])}")   # 1024

# cosine similarity
import numpy as np
def cosine(a, b): return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
print(f"Similarity: {cosine(vectors[0], vectors[1]):.4f}")

# ── 4. Function Calling ───────────────────────────────────────────────────────
import json

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_stock_price",
            "description": "Get the current price of a stock by ticker symbol.",
            "parameters": {
                "type": "object",
                "properties": {
                    "ticker": {"type": "string", "description": "Stock ticker, e.g. AAPL"}
                },
                "required": ["ticker"],
            },
        },
    }
]

fc_response = client.chat.complete(
    model="mistral-large-latest",
    messages=[{"role": "user", "content": "What is the price of NVDA?"}],
    tools=tools,
    tool_choice="auto",
)

tool_call = fc_response.choices[0].message.tool_calls[0]
args = json.loads(tool_call.function.arguments)
print(f"Calling: {tool_call.function.name}({args})")

# ── 5. LangChain Integration ──────────────────────────────────────────────────
from langchain_mistralai import ChatMistralAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatMistralAI(model="mistral-large-latest", temperature=0.2)
msgs = [
    SystemMessage(content="Respond only in bullet points."),
    HumanMessage(content="Top 3 uses of embeddings in ML?"),
]
result = llm.invoke(msgs)
print(result.content)

# ── 6. Running Mistral Locally with Ollama ────────────────────────────────────
# Terminal: ollama pull mistral && ollama serve
import ollama

local_resp = ollama.chat(
    model="mistral",
    messages=[{"role": "user", "content": "Summarize the attention mechanism."}],
)
print(local_resp["message"]["content"])

# ── 7. Model Tiers Reference ─────────────────────────────────────────────────
# mistral-7b-instruct-v0.3  → lightweight, fast, open-weight
# open-mixtral-8x7b         → MoE, 8 experts, 2 active per token, strong at coding
# open-mixtral-8x22b        → larger MoE, near GPT-4 quality
# mistral-large-latest      → flagship closed API model
# codestral-latest          → code-specialized, supports fill-in-the-middle (FIM)
# mistral-embed             → 1024-dim embeddings
```

## Learning Path
1. `pip install mistralai langchain-mistralai`
2. Get a free API key at console.mistral.ai
3. Run chat, streaming, and embeddings examples above
4. Implement a function-calling agent that can look up weather or run code
5. Pull `mistral` with Ollama and run the same prompts locally — compare latency
6. Replace OpenAI calls in an existing LangChain chain with `ChatMistralAI`

## What to Build
- [ ] RAG pipeline using `mistral-embed` for retrieval + `mistral-large` for generation
- [ ] Function-calling agent with 3+ tools (calculator, search, code runner)
- [ ] Compare Mistral-7B vs Mixtral-8x7B vs Mistral-Large on a benchmark of 20 prompts
- [ ] LangChain ReAct agent backed by a locally running Mistral via Ollama
- [ ] Codestral FIM demo: complete a half-written Python function

## Related Folders
- `generative-ai\openai-api-main\` — compare API patterns with OpenAI SDK
- `generative-ai\langchain-main\` — plug Mistral into chains and agents
- `generative-ai\rag-main\` — use `mistral-embed` in a retrieval pipeline
