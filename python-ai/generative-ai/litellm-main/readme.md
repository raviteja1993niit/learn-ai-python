# ⚡ LiteLLM — Unified LLM API for 100+ Models

## What is LiteLLM?
LiteLLM is a Python library and proxy server that provides a single OpenAI-compatible interface for 100+ LLM providers including OpenAI, Anthropic, Google Gemini, AWS Bedrock, Azure OpenAI, Ollama, Cohere, and more. Swap models with a single string change, no SDK rewrites needed. It also offers a proxy server for team-wide load balancing, cost tracking, and caching.

## Why Learn It?
- Write once, run on any provider — avoid vendor lock-in from day one
- Built-in cost tracking, fallbacks, retries, and rate limit handling
- LiteLLM Proxy turns it into a team-wide LLM gateway with logging
- Drop-in replacement for the OpenAI SDK in existing codebases

## Key Concepts
```python
import litellm
from litellm import completion, acompletion

# --- Provider strings: "provider/model-name" ---
# openai/gpt-4o          anthropic/claude-3-5-sonnet-20241022
# gemini/gemini-1.5-pro  ollama/llama3   azure/gpt-4o
# bedrock/anthropic.claude-3-sonnet-20240229-v1:0

# --- Basic call (drop-in for OpenAI) ---
response = completion(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "What is the speed of light?"}],
)
print(response.choices[0].message.content)

# --- Switch provider with one string change ---
claude_resp = completion(
    model="anthropic/claude-3-5-haiku-20241022",
    messages=[{"role": "user", "content": "Explain recursion briefly."}],
    max_tokens=256,
)

# --- Ollama local model ---
local_resp = completion(
    model="ollama/llama3",
    messages=[{"role": "user", "content": "Hello from local!"}],
    api_base="http://localhost:11434",
)

# --- Streaming ---
for chunk in completion(
    model="openai/gpt-4o-mini",
    messages=[{"role": "user", "content": "Count to 5 slowly."}],
    stream=True,
):
    print(chunk.choices[0].delta.content or "", end="", flush=True)

# --- Async ---
import asyncio
async def ask():
    resp = await acompletion(
        model="anthropic/claude-3-5-sonnet-20241022",
        messages=[{"role": "user", "content": "Async hello!"}],
    )
    return resp.choices[0].message.content

asyncio.run(ask())

# --- Cost tracking ---
resp = completion(model="openai/gpt-4o", messages=[{"role": "user", "content": "Hi"}])
cost = litellm.completion_cost(completion_response=resp)
print(f"Cost: ${cost:.6f}")

# --- Fallbacks & Retries ---
litellm.set_verbose = False
resp = completion(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "Fallback test"}],
    fallbacks=["anthropic/claude-3-5-haiku-20241022", "ollama/llama3"],
    num_retries=3,
)

# --- Caching ---
from litellm.caching import Cache
litellm.cache = Cache(type="disk")  # or "redis", "in-memory"
resp1 = completion(model="openai/gpt-4o-mini", messages=[{"role": "user", "content": "Same question"}])
resp2 = completion(model="openai/gpt-4o-mini", messages=[{"role": "user", "content": "Same question"}])
# resp2 returns from cache — $0 cost

# --- Token budget management ---
resp = completion(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "Long task..."}],
    max_budget=0.01,  # stop if cost exceeds $0.01
)
```

## Learning Path
1. `pip install litellm` and make your first call with `litellm.completion()`
2. Swap `model=` strings to call OpenAI, Anthropic, and Gemini with the same code
3. Add streaming and async patterns to your calls
4. Use `litellm.completion_cost()` to track spend across providers
5. Configure `fallbacks` and `num_retries` for resilient production calls
6. Enable disk or Redis caching to eliminate redundant API calls
7. Set up the LiteLLM Proxy with `proxy_config.yaml` for team-wide routing
8. Add load balancing across multiple API keys or model endpoints

## What to Build
- [ ] Provider cost comparison script: same prompt → all providers → ranked by cost/quality
- [ ] Resilient LLM wrapper with automatic fallback chain (GPT → Claude → Ollama)
- [ ] Cached QA bot: identical questions served from cache for $0
- [ ] LiteLLM Proxy deployment with load balancing across 3 OpenAI keys
- [ ] Budget tracker: daily spend dashboard across all providers

## Related Folders
- `generative-ai\anthropic-claude-api-main\` — direct Claude SDK (what LiteLLM wraps)
- `generative-ai\openai-function-calling-main\` — OpenAI-specific features LiteLLM exposes
- `generative-ai\instructor-structured-outputs-main\` — structured outputs compatible with LiteLLM
