# 🟠 Anthropic Claude API — Direct Integration with Claude Models

## What is the Anthropic Claude API?
The Anthropic Claude API gives you programmatic access to Claude models (Haiku, Sonnet, Opus) via a Python SDK. It supports multi-turn conversations, streaming, vision, tool use, and prompt caching — all through a clean `messages.create` interface similar to OpenAI but with Claude-specific features like extended context and constitutional AI alignment.

## Why Learn It?
- Claude often outperforms GPT on reasoning, coding, and long-context tasks
- Unique features: 200K context window, prompt caching, constitutional safety
- Tool use API is clean and composable for agentic workflows
- Essential for multi-provider AI systems and cost/quality benchmarking

## Key Concepts
```python
import anthropic
import base64

client = anthropic.Anthropic()  # uses ANTHROPIC_API_KEY from env

# --- Basic message ---
response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    system="You are a concise Python expert.",
    messages=[{"role": "user", "content": "Explain list comprehensions."}],
)
print(response.content[0].text)

# --- Multi-turn conversation ---
history = []
history.append({"role": "user", "content": "My name is Ada."})
history.append({"role": "assistant", "content": "Nice to meet you, Ada!"})
history.append({"role": "user", "content": "What's my name?"})
resp = client.messages.create(model="claude-3-5-haiku-20241022", max_tokens=256, messages=history)

# --- Streaming ---
with client.messages.stream(
    model="claude-3-5-sonnet-20241022",
    max_tokens=512,
    messages=[{"role": "user", "content": "Write a haiku about Python."}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)

# --- Vision (base64 image) ---
with open("chart.png", "rb") as f:
    img_data = base64.standard_b64encode(f.read()).decode("utf-8")

vision_resp = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": img_data}},
            {"type": "text", "text": "Describe the trends in this chart."},
        ],
    }],
)

# --- Tool Use ---
tools = [{
    "name": "get_stock_price",
    "description": "Get current stock price for a ticker",
    "input_schema": {
        "type": "object",
        "properties": {"ticker": {"type": "string"}},
        "required": ["ticker"],
    },
}]
tool_resp = client.messages.create(
    model="claude-3-5-sonnet-20241022", max_tokens=512,
    tools=tools,
    messages=[{"role": "user", "content": "What is AAPL's price?"}],
)
for block in tool_resp.content:
    if block.type == "tool_use":
        print(block.name, block.input)  # ToolUseBlock

# --- Prompt Caching (cost optimisation) ---
cached_resp = client.messages.create(
    model="claude-3-5-sonnet-20241022", max_tokens=512,
    system=[{"type": "text", "text": "Long system prompt...", "cache_control": {"type": "ephemeral"}}],
    messages=[{"role": "user", "content": "Question about the system prompt context"}],
)
print(cached_resp.usage)  # shows cache_read_input_tokens
```

## Learning Path
1. Set `ANTHROPIC_API_KEY` and run a basic `messages.create` call
2. Build a multi-turn chat loop with conversation history
3. Add streaming for real-time output
4. Try vision with a base64-encoded image
5. Implement tool use (define tools, handle `ToolUseBlock`, return results)
6. Explore prompt caching to reduce costs on repeated context
7. Compare Claude vs GPT on your specific task/benchmark
8. Count tokens with `client.messages.count_tokens()`

## What to Build
- [ ] Multi-turn CLI chatbot with streaming output
- [ ] Image analysis tool: upload any image and ask questions
- [ ] Tool-use agent that queries a real API (weather, stocks, search)
- [ ] Prompt caching benchmark: measure cost savings on long system prompts
- [ ] Claude vs GPT quality comparison script on coding tasks

## Related Folders
- `generative-ai\openai-function-calling-main\` — OpenAI's equivalent tool use and structured outputs
- `generative-ai\multimodal-ai-vision-language-main\` — broader multimodal patterns across providers
- `generative-ai\litellm-main\` — unified API to call Claude + GPT + others interchangeably
