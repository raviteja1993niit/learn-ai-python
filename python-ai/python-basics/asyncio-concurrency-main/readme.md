# ⚡ asyncio & Async Python — Concurrency for AI Applications

## What is asyncio?
`asyncio` is Python's built-in library for writing concurrent code using the `async`/`await` syntax and a single-threaded event loop. It is essential for building fast AI backends, streaming LLM responses, and running multiple API calls in parallel without blocking.

## Why Learn It?
- LLM API calls are I/O-bound — `asyncio.gather` can run dozens concurrently instead of sequentially
- FastAPI is fully async-native; writing sync handlers wastes its concurrency model
- Streaming token-by-token responses from OpenAI/Anthropic requires async generators
- Background tasks (embeddings, logging, webhooks) can run without blocking the main response

## Key Concepts
```python
import asyncio
import httpx

# Run multiple LLM calls concurrently
async def fetch_completion(client: httpx.AsyncClient, prompt: str) -> str:
    response = await client.post(
        "https://api.openai.com/v1/chat/completions",
        json={"model": "gpt-4o-mini", "messages": [{"role": "user", "content": prompt}]},
        headers={"Authorization": "Bearer sk-..."},
    )
    return response.json()["choices"][0]["message"]["content"]

async def run_parallel_prompts(prompts: list[str]) -> list[str]:
    async with httpx.AsyncClient(timeout=30) as client:
        tasks = [fetch_completion(client, p) for p in prompts]
        return await asyncio.gather(*tasks)

# Async generator for streaming
async def stream_tokens(response):
    async for chunk in response.aiter_lines():
        if chunk.startswith("data: "):
            yield chunk[6:]

# Producer/consumer with asyncio.Queue
async def producer(queue: asyncio.Queue):
    for i in range(5):
        await queue.put(f"item-{i}")
        await asyncio.sleep(0.1)

async def consumer(queue: asyncio.Queue):
    while True:
        item = await queue.get()
        print(f"Processing {item}")
        queue.task_done()

results = asyncio.run(run_parallel_prompts(["Explain AI", "Explain ML"]))
```

## Learning Path
1. `pip install httpx asyncio`
2. Understand `async def`, `await`, and the event loop — run with `asyncio.run()`
3. Use `asyncio.gather()` to fan out concurrent API requests and collect results
4. Build async generators for token streaming from OpenAI's streaming endpoint
5. Integrate with FastAPI `BackgroundTasks` and `asyncio.Queue` for pipeline patterns

## What to Build
- [ ] A parallel prompt runner that sends 10 prompts to an LLM simultaneously and times the speedup
- [ ] A streaming chat endpoint in FastAPI that yields tokens as a `StreamingResponse`
- [ ] An async web scraper that fetches 50 URLs concurrently using `httpx.AsyncClient`

## Related Folders
- `python-basics/pydantic-v2-main/` — Pydantic models validate async API responses
- `machine-learning/evidently-ai-model-monitoring-main/` — async background tasks can push metrics to monitoring
