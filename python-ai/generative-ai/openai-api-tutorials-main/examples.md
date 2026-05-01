# OpenAI API — Code Examples (25 Examples)

```bash
pip install openai python-dotenv tiktoken pydantic
```

---

## Example 1 — Basic Chat Completion
```python
from openai import OpenAI
client = OpenAI()
r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":"Explain machine learning in one sentence."}]
)
print(r.choices[0].message.content)
print("Tokens:", r.usage.total_tokens)
```

---

## Example 2 — System Prompt Persona
```python
r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role":"system","content":"You are a pirate. Reply only in pirate speak."},
        {"role":"user","content":"How is the weather?"}
    ],
    temperature=0.9, max_tokens=100
)
print(r.choices[0].message.content)
```

---

## Example 3 — Multi-turn Conversation
```python
history = [{"role":"system","content":"You are a helpful math tutor."}]
def chat(user_input):
    history.append({"role":"user","content":user_input})
    r = client.chat.completions.create(model="gpt-4o-mini", messages=history)
    reply = r.choices[0].message.content
    history.append({"role":"assistant","content":reply})
    return reply
print(chat("What is the derivative of x^2?"))
print(chat("And x^3?"))   # model retains context
```

---

## Example 4 — Streaming Output
```python
stream = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":"Write a short story about a robot."}],
    stream=True
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

---

## Example 5 — Temperature Sweep
```python
prompt = "Suggest a name for a coffee shop."
for temp in [0.0, 0.5, 1.0, 1.5]:
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role":"user","content":prompt}],
        temperature=temp, max_tokens=30
    )
    print(f"temp={temp}: {r.choices[0].message.content.strip()}")
```

---

## Example 6 — JSON Mode
```python
import json
r = client.chat.completions.create(
    model="gpt-4o-mini",
    response_format={"type":"json_object"},
    messages=[
        {"role":"system","content":"Return valid JSON only."},
        {"role":"user","content":"List 5 world capitals as {\"capitals\":[...]}"}
    ]
)
data = json.loads(r.choices[0].message.content)
print(data["capitals"])
```

---

## Example 7 — Structured Outputs (Pydantic)
```python
from pydantic import BaseModel
from typing import List
class Product(BaseModel):
    name: str
    price: float
    category: str
    tags: List[str]

r = client.beta.chat.completions.parse(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":"Describe a red 15-inch laptop for 999 dollars."}],
    response_format=Product
)
p = r.choices[0].message.parsed
print(p.name, p.price, p.tags)
```

---

## Example 8 — Function Calling (Single Tool)
```python
import json
tools = [{"type":"function","function":{
    "name":"get_weather",
    "description":"Get weather for a city",
    "parameters":{"type":"object",
      "properties":{"city":{"type":"string"},"unit":{"type":"string","enum":["celsius","fahrenheit"]}},
      "required":["city"]}}}]

def get_weather(city, unit="celsius"):
    return {"city":city,"temp":22,"unit":unit}

msgs = [{"role":"user","content":"Weather in Paris?"}]
r = client.chat.completions.create(model="gpt-4o-mini", messages=msgs, tools=tools)
m = r.choices[0].message
if m.tool_calls:
    tc = m.tool_calls[0]
    result = get_weather(**json.loads(tc.function.arguments))
    msgs += [m, {"role":"tool","tool_call_id":tc.id,"content":json.dumps(result)}]
    final = client.chat.completions.create(model="gpt-4o-mini", messages=msgs)
    print(final.choices[0].message.content)
```

---

## Example 9 — Agentic Loop (Multi-step Tool Use)
```python
def agent_loop(user_msg, tools, dispatch_fn):
    msgs = [{"role":"user","content":user_msg}]
    while True:
        r = client.chat.completions.create(model="gpt-4o-mini", messages=msgs, tools=tools)
        m = r.choices[0].message
        if r.choices[0].finish_reason == "stop":
            return m.content
        msgs.append(m)
        for tc in (m.tool_calls or []):
            res = dispatch_fn(tc.function.name, json.loads(tc.function.arguments))
            msgs.append({"role":"tool","tool_call_id":tc.id,"content":str(res)})
```

---

## Example 10 — Vision: Image URL
```python
r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":[
        {"type":"text","text":"What do you see in this image?"},
        {"type":"image_url","image_url":{
            "url":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png",
            "detail":"low"
        }}
    ]}],
    max_tokens=200
)
print(r.choices[0].message.content)
```

---

## Example 11 — Vision: Base64 Local Image
```python
import base64
def encode_image(path):
    with open(path,"rb") as f:
        return base64.b64encode(f.read()).decode()

b64 = encode_image("screenshot.png")
r = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role":"user","content":[
        {"type":"text","text":"Describe the UI elements."},
        {"type":"image_url","image_url":{"url":f"data:image/png;base64,{b64}"}}
    ]}]
)
print(r.choices[0].message.content)
```

---

## Example 12 — Embeddings: Cosine Similarity
```python
import numpy as np
def embed(text):
    r = client.embeddings.create(model="text-embedding-3-small", input=text)
    return np.array(r.data[0].embedding)

def cosine(a, b):
    return float(np.dot(a,b) / (np.linalg.norm(a) * np.linalg.norm(b)))

sentences = ["I love dogs","Cats are great pets","I enjoy hiking"]
q_vec = embed("I like animals")
results = sorted(((s, cosine(q_vec, embed(s))) for s in sentences), key=lambda x:-x[1])
for s, score in results:
    print(f"{score:.3f}: {s}")
```

---

## Example 13 — Embeddings: Semantic Search
```python
docs = ["Python is a high-level language.","JavaScript runs in browsers.",
        "ML uses statistics.","Deep learning uses neural networks."]
doc_vecs = [embed(d) for d in docs]

def search(query, k=2):
    q = embed(query)
    ranked = sorted(range(len(docs)), key=lambda i:-cosine(q, doc_vecs[i]))
    return [(docs[i], cosine(q, doc_vecs[i])) for i in ranked[:k]]

for doc, score in search("neural networks and AI"):
    print(f"{score:.3f}: {doc}")
```

---

## Example 14 — Whisper Transcription
```python
with open("audio.mp3","rb") as f:
    t = client.audio.transcriptions.create(
        model="whisper-1", file=f,
        response_format="verbose_json",
        language="en"
    )
print(t.text)
```

---

## Example 15 — TTS Text to Speech
```python
r = client.audio.speech.create(
    model="tts-1-hd", voice="nova",
    input="Welcome to our AI-powered assistant.",
    speed=1.0
)
r.stream_to_file("welcome.mp3")
# voices: alloy, echo, fable, onyx, nova, shimmer
```

---

## Example 16 — DALL-E 3 Image Generation
```python
r = client.images.generate(
    model="dall-e-3",
    prompt="A serene Japanese garden with cherry blossoms, watercolor style",
    n=1, size="1024x1024", quality="hd", style="natural"
)
print("URL:", r.data[0].url)
print("Revised prompt:", r.data[0].revised_prompt)
```

---

## Example 17 — DALL-E 2 Batch Generation (b64)
```python
import base64
r = client.images.generate(
    model="dall-e-2", prompt="Abstract geometric art, vibrant colors",
    n=4, size="512x512", response_format="b64_json"
)
for i, img in enumerate(r.data):
    with open(f"output_{i}.png","wb") as f:
        f.write(base64.b64decode(img.b64_json))
    print(f"Saved output_{i}.png")
```

---

## Example 18 — Moderation
```python
def check_content(text):
    r = client.moderations.create(input=text)
    res = r.results[0]
    if res.flagged:
        cats = [k for k,v in res.categories.__dict__.items() if v]
        print(f"FLAGGED: {cats}")
    else:
        print("Content is safe")
    return not res.flagged

check_content("I love machine learning!")
```

---

## Example 19 — Token Counting with tiktoken
```python
import tiktoken
def count_tokens(messages, model="gpt-4o-mini"):
    enc = tiktoken.encoding_for_model(model)
    total = 3
    for m in messages:
        total += 4 + len(enc.encode(m.get("content","") or ""))
    return total

msgs = [{"role":"system","content":"You are helpful."},
        {"role":"user","content":"Explain quantum computing."}]
print("Tokens:", count_tokens(msgs))
```

---

## Example 20 — Assistants API: Code Interpreter
```python
asst = client.beta.assistants.create(
    name="Analyst", model="gpt-4o-mini",
    instructions="Use Python for all analysis.",
    tools=[{"type":"code_interpreter"}])
thread = client.beta.threads.create()
client.beta.threads.messages.create(thread_id=thread.id, role="user",
    content="Print the first 10 Fibonacci numbers.")
run = client.beta.threads.runs.create_and_poll(
    thread_id=thread.id, assistant_id=asst.id)
msgs = client.beta.threads.messages.list(thread_id=thread.id)
print(msgs.data[0].content[0].text.value)
client.beta.assistants.delete(asst.id)
```

---

## Example 21 — Assistants API: File Search (RAG)
```python
vs = client.beta.vector_stores.create(name="My Docs")
file_resp = client.files.create(file=open("document.txt","rb"), purpose="assistants")
client.beta.vector_stores.files.create(vector_store_id=vs.id, file_id=file_resp.id)

asst = client.beta.assistants.create(
    model="gpt-4o-mini",
    tools=[{"type":"file_search"}],
    tool_resources={"file_search":{"vector_store_ids":[vs.id]}})
thread = client.beta.threads.create()
client.beta.threads.messages.create(thread_id=thread.id, role="user",
    content="Summarise the document.")
run = client.beta.threads.runs.create_and_poll(
    thread_id=thread.id, assistant_id=asst.id)
msgs = client.beta.threads.messages.list(thread_id=thread.id)
print(msgs.data[0].content[0].text.value)
```

---

## Example 22 — Retry with Exponential Backoff
```python
import time
from openai import RateLimitError, APITimeoutError

def create_with_backoff(msgs, model="gpt-4o-mini", max_retries=5):
    for attempt in range(max_retries):
        try:
            return client.chat.completions.create(model=model, messages=msgs)
        except (RateLimitError, APITimeoutError):
            wait = min(2**attempt, 60)
            print(f"Retrying in {wait}s (attempt {attempt+1}/{max_retries})")
            time.sleep(wait)
    raise RuntimeError("Max retries exceeded")
```

---

## Example 23 — Async Parallel Calls
```python
import asyncio
from openai import AsyncOpenAI
aclient = AsyncOpenAI()

async def async_chat(prompt):
    r = await aclient.chat.completions.create(
        model="gpt-4o-mini", messages=[{"role":"user","content":prompt}])
    return r.choices[0].message.content

async def main():
    topics = ["Python","Rust","Go","TypeScript"]
    prompts = [f"One fact about {t}" for t in topics]
    results = await asyncio.gather(*[async_chat(p) for p in prompts])
    for topic, result in zip(topics, results):
        print(f"{topic}: {result[:60]}")

asyncio.run(main())
```

---

## Example 24 — Few-Shot Sentiment Classification
```python
few_shot = [
    {"role":"system","content":"Classify as POSITIVE, NEGATIVE, or NEUTRAL."},
    {"role":"user","content":"I love this product!"},
    {"role":"assistant","content":"POSITIVE"},
    {"role":"user","content":"Worst experience ever."},
    {"role":"assistant","content":"NEGATIVE"},
    {"role":"user","content":"Package arrived on time."},
    {"role":"assistant","content":"NEUTRAL"},
    {"role":"user","content":"This exceeded all my expectations!"}
]
r = client.chat.completions.create(model="gpt-4o-mini", messages=few_shot, max_tokens=10)
print(r.choices[0].message.content)   # POSITIVE
```

---

## Example 25 — Chain-of-Thought Prompting
```python
cot_system = {
    "role":"system",
    "content":("Think step by step. Show your reasoning before the final answer. "
               "Format: REASONING: ... ANSWER: ...")
}
r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[cot_system,
              {"role":"user","content":"A farmer has 17 sheep. All but 9 die. How many are left?"}],
    temperature=0.3
)
print(r.choices[0].message.content)
```