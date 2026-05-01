# OpenAI API — Complete Reference

## Table of Contents
1. API Overview  2. Authentication  3. Chat Completions API
4. Messages & Roles  5. Parameters  6. Model Families
7. Streaming  8. Function Calling  9. JSON Mode
10. Structured Outputs  11. Vision API  12. Embeddings
13. Audio API  14. DALL-E  15. Assistants API
16. Moderation  17. Token Counting  18. Error Handling
19. Best Practices

---

## 1. API Overview

The OpenAI API exposes state-of-the-art AI through a REST interface.

| Product         | Endpoint                     | Use                          |
|-----------------|------------------------------|------------------------------|
| Chat            | /v1/chat/completions         | Text generation / reasoning  |
| Embeddings      | /v1/embeddings               | Semantic vectors             |
| Images          | /v1/images/generations       | DALL-E image generation      |
| Audio STT       | /v1/audio/transcriptions     | Whisper speech-to-text       |
| Audio TTS       | /v1/audio/speech             | Text-to-speech               |
| Assistants      | /v1/assistants               | Stateful agents with tools   |
| Moderation      | /v1/moderations              | Content safety               |
| Fine-tuning     | /v1/fine_tuning/jobs         | Custom model training        |

**SDK install**: `pip install openai>=1.0`

### Rate Limits (approximate)
- Tier 1: 500 RPM, 30 000 TPM (gpt-4o-mini)
- Tier 2: 5 000 RPM, 450 000 TPM (gpt-4o)
- Response headers: x-ratelimit-remaining-requests, x-ratelimit-reset-requests

### Pricing (approximate)
- gpt-4o-mini: \.15/1M input, \.60/1M output
- gpt-4o:       \.50/1M input, \.00/1M output
- text-embedding-3-small: \.02/1M tokens

---

## 2. Authentication

Generate keys at https://platform.openai.com/api-keys.
Never hardcode keys — always use environment variables.

`.env
OPENAI_API_KEY=sk-proj-...
OPENAI_ORG_ID=org-...
OPENAI_PROJECT_ID=proj_...
`

`python
from openai import OpenAI
client = OpenAI()                        # auto-reads OPENAI_API_KEY
# or explicit:
client = OpenAI(api_key="sk-...", organization="org-...", timeout=30.0)
`

Use python-dotenv in development:
`python
from dotenv import load_dotenv; load_dotenv()
`

---

## 3. Chat Completions API

**Endpoint**: POST /v1/chat/completions
Stateless — send the entire conversation history each request.

`python
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user",   "content": "What is the capital of France?"},
    ]
)
print(response.choices[0].message.content)
`

### Response Object
`
ChatCompletion
  id, created, model
  choices[0]
    message.role, message.content
    finish_reason: "stop"|"length"|"tool_calls"|"content_filter"
  usage.prompt_tokens, usage.completion_tokens, usage.total_tokens
`

### finish_reason Values
| Value          | Meaning                                    |
|----------------|--------------------------------------------|
| stop           | Natural end of generation                  |
| length         | Hit max_tokens limit                       |
| tool_calls     | Model wants to call a function/tool        |
| content_filter | Content policy blocked generation          |

---

## 4. Messages Structure & Roles

Every message: `{"role": "<role>", "content": "<text>"}`

| Role      | Purpose                                              |
|-----------|------------------------------------------------------|
| system    | Sets persona/behavior (first message)                |
| user      | Human turn                                           |
| assistant | Previous model response (replay for context)         |
| tool      | Result returned from a function call                 |

### Multi-turn Memory Pattern
`python
history = [{"role": "system", "content": "You are a Python tutor."}]
def chat(msg):
    history.append({"role": "user", "content": msg})
    r = client.chat.completions.create(model="gpt-4o-mini", messages=history)
    reply = r.choices[0].message.content
    history.append({"role": "assistant", "content": reply})
    return reply
`

### Content as List (multi-modal)
`python
{"role": "user", "content": [
    {"type": "text", "text": "Describe this:"},
    {"type": "image_url", "image_url": {"url": "https://example.com/img.jpg"}}
]}
`

---

## 5. Parameters Deep Dive

| Parameter         | Range            | Effect                                      |
|-------------------|------------------|---------------------------------------------|
| temperature       | 0.0 – 2.0        | Randomness. 0=deterministic, 1=default      |
| max_tokens        | 1 – ctx limit    | Cap on output length                        |
| top_p             | 0.0 – 1.0        | Nucleus sampling (alter OR temperature)     |
| frequency_penalty | -2.0 – 2.0       | Penalise repeated tokens (reduce loops)     |
| presence_penalty  | -2.0 – 2.0       | Penalise any prior token (encourage variety)|
| stop              | str/list (≤4)    | Stop generation at these strings            |
| n                 | ≥ 1              | Number of completions                       |
| seed              | any int          | Reproducibility (deterministic outputs)     |
| stream            | bool             | Server-sent events streaming                |
| logprobs          | bool             | Return per-token log probabilities          |
| response_format   | dict             | JSON mode / structured output               |

### Rules of thumb
- Creative writing: temperature 0.8-1.2, leave top_p=1.0
- Factual / code: temperature 0.0-0.3
- Do NOT change both temperature AND top_p simultaneously

---

## 6. Model Families

### GPT-4o (Omni)
- Context: 128K input, 16K output
- Multimodal: text + image input
- gpt-4o: full capability, higher cost
- gpt-4o-mini: 3× cheaper, slightly less capable — default for most workloads

### o1 / o1-mini (Reasoning)
- Internal chain-of-thought (not visible)
- Best for: maths, coding, logic puzzles
- Constraints: no streaming, no system message (use "developer" role)
- o1-mini: faster, cheaper, less broad knowledge

### o3-mini (2025)
- Cost-effective reasoning with configurable effort: low/medium/high
- Outperforms o1 on STEM benchmarks at lower cost

### Selection Guide
`
High-volume, simple tasks    → gpt-4o-mini
Vision / multimodal          → gpt-4o
Hard math / coding           → o1-mini / o3-mini
Long documents               → gpt-4o (128K)
Real-time chat               → gpt-4o-mini + streaming
`

---

## 7. Streaming

`python
stream = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Write a haiku about Python."}],
    stream=True
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
`

### Context Manager API
`python
with client.chat.completions.stream(model="gpt-4o-mini", messages=[...]) as s:
    for text in s.text_stream:
        print(text, end="", flush=True)
    final = s.get_final_completion()
`

Use streaming for: chat UIs, long outputs, progressive rendering.

---

## 8. Function Calling / Tool Use

Two-turn pattern: model signals tool call → execute → feed result back.

### Define Tools
`python
tools = [{"type": "function", "function": {
    "name": "get_weather",
    "description": "Get current weather for a city",
    "parameters": {"type": "object",
        "properties": {
            "city": {"type": "string"},
            "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
        }, "required": ["city"]}
}}]
`

### Agentic Loop
`python
while True:
    resp = client.chat.completions.create(
        model="gpt-4o-mini", messages=msgs, tools=tools)
    msg = resp.choices[0].message
    if resp.choices[0].finish_reason == "stop":
        return msg.content
    msgs.append(msg)
    for tc in msg.tool_calls:
        result = dispatch(tc.function.name, json.loads(tc.function.arguments))
        msgs.append({"role":"tool","tool_call_id":tc.id,"content":str(result)})
`

### tool_choice Values
- "auto"      — model decides whether to use a tool
- "none"      — never use tools
- "required"  — must use at least one tool
- {"type": "function", "function": {"name": "X"}} — force specific tool

---

## 9. JSON Mode

Forces valid JSON output. You MUST instruct the model to output JSON in the prompt.

`python
response = client.chat.completions.create(
    model="gpt-4o-mini",
    response_format={"type": "json_object"},
    messages=[
        {"role": "system", "content": "Output valid JSON only."},
        {"role": "user", "content": "List 3 world capitals as JSON."}
    ]
)
import json
data = json.loads(response.choices[0].message.content)
`

---

## 10. Structured Outputs

Guarantees output matches a Pydantic / JSON Schema exactly.

`python
from pydantic import BaseModel
class Event(BaseModel):
    name: str; date: str; location: str; participants: list[str]

response = client.beta.chat.completions.parse(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":"Alice and Bob meet Jan 15 in Paris."}],
    response_format=Event
)
event = response.choices[0].message.parsed  # typed Event object
print(event.name, event.date, event.location)
`

---

## 11. Vision API

GPT-4o and gpt-4o-mini accept images in messages.

`python
# URL
{"role":"user","content":[
    {"type":"text","text":"What is in this image?"},
    {"type":"image_url","image_url":{"url":"https://...","detail":"high"}}
]}

# Base64
import base64
b64 = base64.b64encode(open("img.jpg","rb").read()).decode()
{"type":"image_url","image_url":{"url":f"data:image/jpeg;base64,{b64}"}}
`

### detail Parameter
| Value  | Tokens | Use case                        |
|--------|--------|---------------------------------|
| low    | 85     | Quick check, simple images      |
| high   | ≤1445  | Fine details, text in images    |
| auto   | varies | Model chooses (default)         |

---

## 12. Embeddings API

Endpoint: POST /v1/embeddings

| Model                     | Dimensions | Notes                        |
|---------------------------|------------|------------------------------|
| text-embedding-3-small    | 1536       | Best cost/performance ratio  |
| text-embedding-3-large    | 3072       | Highest accuracy             |
| text-embedding-ada-002    | 1536       | Legacy, still supported      |

`python
resp = client.embeddings.create(model="text-embedding-3-small", input="hello")
vec = resp.data[0].embedding   # list[float], len=1536

# Cosine similarity
import numpy as np
def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a,b) / (np.linalg.norm(a) * np.linalg.norm(b)))
`

Supports custom dimensions (text-embedding-3 models only):
`python
resp = client.embeddings.create(model="text-embedding-3-large", input="x", dimensions=256)
`

---

## 13. Audio API

### Whisper — Speech to Text
`python
with open("audio.mp3","rb") as f:
    t = client.audio.transcriptions.create(model="whisper-1", file=f, language="en")
print(t.text)
`
Formats: mp3, mp4, mpeg, m4a, wav, webm. Max 25MB.

### TTS — Text to Speech
`python
resp = client.audio.speech.create(
    model="tts-1-hd",  # or tts-1
    voice="nova",       # alloy|echo|fable|onyx|nova|shimmer
    input="Hello, world!", speed=1.0)
resp.stream_to_file("out.mp3")
`

---

## 14. DALL-E API

`python
# Generate (DALL-E 3)
r = client.images.generate(
    model="dall-e-3", prompt="A futuristic city, digital art",
    n=1, size="1024x1024", quality="hd", style="vivid")
print(r.data[0].url)

# DALL-E 2 variations
r = client.images.create_variation(image=open("img.png","rb"), n=3, size="512x512")

# DALL-E 2 inpainting
r = client.images.edit(image=open("img.png","rb"), mask=open("mask.png","rb"),
    prompt="Add a rainbow", n=1, size="1024x1024")
`

### Sizes
| DALL-E 3     | DALL-E 2               |
|--------------|------------------------|
| 1024×1024    | 256×256, 512×512       |
| 1792×1024    | 1024×1024              |
| 1024×1792    |                        |

---

## 15. Assistants API

Stateful agents with persistent threads, tools, and file access.

### Concepts
- **Assistant**: model + instructions + tools
- **Thread**: conversation session (persists messages)
- **Run**: execute assistant on a thread
- **Built-in tools**: file_search (RAG), code_interpreter, function

`python
asst = client.beta.assistants.create(
    model="gpt-4o-mini", instructions="You are a data analyst.",
    tools=[{"type":"code_interpreter"}])
thread = client.beta.threads.create()
client.beta.threads.messages.create(thread_id=thread.id,
    role="user", content="Compute 1+1")
run = client.beta.threads.runs.create_and_poll(
    thread_id=thread.id, assistant_id=asst.id)
msgs = client.beta.threads.messages.list(thread_id=thread.id)
print(msgs.data[0].content[0].text.value)
`

---

## 16. Moderation API

Free content safety classifier.

`python
r = client.moderations.create(input="Some text to check")
res = r.results[0]
print(res.flagged)          # bool
print(res.categories)       # CategoryFlags object
print(res.category_scores)  # CategoryScores object
`

Categories: hate, hate/threatening, harassment, self-harm, sexual,
sexual/minors, violence, violence/graphic.

---

## 17. Token Counting with tiktoken

`python
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o")
print(len(enc.encode("Hello, world!")))  # 4

def estimate_tokens(messages, model="gpt-4o-mini"):
    enc = tiktoken.encoding_for_model(model)
    total = 3
    for m in messages:
        total += 4 + len(enc.encode(m.get("content","") or ""))
    return total
`

Context windows:
| Model       | Max Input | Max Output |
|-------------|-----------|------------|
| gpt-4o      | 128K      | 16K        |
| gpt-4o-mini | 128K      | 16K        |
| o1          | 200K      | 100K       |

---

## 18. Error Handling & Retries

`python
import time
from openai import RateLimitError, APITimeoutError, APIConnectionError

def create_with_retry(messages, max_retries=5):
    for attempt in range(max_retries):
        try:
            return client.chat.completions.create(
                model="gpt-4o-mini", messages=messages)
        except RateLimitError:
            time.sleep(2 ** attempt)
        except (APITimeoutError, APIConnectionError):
            time.sleep(1)
    raise RuntimeError("Max retries exceeded")
`

### Exception Hierarchy
`
openai.APIError
  APIConnectionError  — network issues
  APITimeoutError     — request timeout
  AuthenticationError — invalid API key (401)
  RateLimitError      — quota exceeded (429)
  BadRequestError     — invalid request (400)
  InternalServerError — OpenAI server error (500)
`

---

## 19. Best Practices

### System Prompt Design
- State role, constraints, and output format clearly
- Include 2-3 few-shot examples for niche tasks
- Keep system prompt ≤ 500 tokens for cost

### Cost Optimization
- Default to gpt-4o-mini; escalate only when needed
- Set max_tokens to cap outputs
- Enable Prompt Caching for repeated prefixes (50% savings)
- Batch non-real-time requests via the Batch API (\.50 discount)
- Cache embeddings locally — avoid re-embedding same content

### Security
- Never expose API key client-side
- Use separate keys per environment (dev / staging / prod)
- Set usage alerts at platform.openai.com/usage
- Use moderation API to screen user inputs in production

### Testing
- Use seed for reproducible test outputs
- Log response.id for OpenAI support tickets
- Record input/output token counts for cost forecasting