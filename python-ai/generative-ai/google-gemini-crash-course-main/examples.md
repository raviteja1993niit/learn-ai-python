# Google Gemini API — Code Examples (20 Examples)

```bash
pip install google-generativeai pillow python-dotenv
```

---

## Example 1 — Basic Text Generation
```python
import google.generativeai as genai, os
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content("What is machine learning?")
print(response.text)
print("Total tokens:", response.usage_metadata.total_token_count)
```

---

## Example 2 — Multi-part Prompt (Text + Image)
```python
import PIL.Image
model = genai.GenerativeModel("gemini-1.5-flash")
image = PIL.Image.open("photo.jpg")
response = model.generate_content(["Describe this image in detail.", image])
print(response.text)
```

---

## Example 3 — Chat Session
```python
model = genai.GenerativeModel("gemini-1.5-flash")
chat = model.start_chat(history=[])
r1 = chat.send_message("My name is Alice.")
print(r1.text)
r2 = chat.send_message("What's my name?")
print(r2.text)  # Should mention Alice
for msg in chat.history:
    print(f"{msg.role}: {msg.parts[0].text[:60]}")
```

---

## Example 4 — Streaming
```python
model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content("Write a haiku about the ocean.", stream=True)
for chunk in response:
    print(chunk.text, end="", flush=True)
print()
```

---

## Example 5 — System Instructions
```python
model = genai.GenerativeModel(
    "gemini-1.5-flash",
    system_instruction=(
        "You are a senior Python developer. "
        "Always provide working code examples. "
        "Be concise and technical."
    )
)
response = model.generate_content("How do I read a JSON file in Python?")
print(response.text)
```

---

## Example 6 — Safety Settings
```python
from google.generativeai.types import HarmCategory, HarmBlockThreshold

safety = {
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_ONLY_HIGH,
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
}
model = genai.GenerativeModel("gemini-1.5-flash", safety_settings=safety)
response = model.generate_content("Explain conflict resolution techniques.")
print(response.text)
```

---

## Example 7 — Generation Config
```python
from google.generativeai.types import GenerationConfig
config = GenerationConfig(
    temperature=0.7, top_p=0.95, top_k=40,
    max_output_tokens=512, stop_sequences=["END"]
)
model = genai.GenerativeModel("gemini-1.5-flash", generation_config=config)
response = model.generate_content("Tell me a short story about a robot.")
print(response.text)
```

---

## Example 8 — JSON Mode
```python
import json
model = genai.GenerativeModel(
    "gemini-1.5-flash",
    generation_config={"response_mime_type":"application/json"}
)
response = model.generate_content(
    "List 5 programming languages with year created. JSON array format."
)
data = json.loads(response.text)
for item in data:
    print(item)
```

---

## Example 9 — Structured Output with Schema
```python
import typing_extensions as typing, json

class Country(typing.TypedDict):
    name: str
    capital: str
    population_millions: float

model = genai.GenerativeModel(
    "gemini-1.5-flash",
    generation_config={
        "response_mime_type": "application/json",
        "response_schema": list[Country]
    }
)
response = model.generate_content("List 5 countries with capitals and population.")
countries = json.loads(response.text)
for c in countries:
    print(f"{c['name']}: {c['capital']} ({c['population_millions']}M)")
```

---

## Example 10 — Token Counting
```python
import PIL.Image
model = genai.GenerativeModel("gemini-1.5-flash")

# Text only
result = model.count_tokens("How are you today?")
print("Text tokens:", result.total_tokens)

# Text + image
image = PIL.Image.open("photo.jpg")
result = model.count_tokens(["Describe this image.", image])
print("Multimodal tokens:", result.total_tokens)
```

---

## Example 11 — File API: Upload and Use PDF
```python
import time

# Upload a PDF
sample_file = genai.upload_file(path="document.pdf", display_name="Research Paper")
print(f"Uploaded: {sample_file.uri}, State: {sample_file.state.name}")

# Wait for processing
while sample_file.state.name == "PROCESSING":
    time.sleep(5)
    sample_file = genai.get_file(sample_file.name)
print(f"Ready: {sample_file.state.name}")

# Use file with model
model = genai.GenerativeModel("gemini-1.5-pro")
response = model.generate_content(["Summarise this paper.", sample_file])
print(response.text)

# Clean up
genai.delete_file(sample_file.name)
```

---

## Example 12 — File API: Video Analysis
```python
import time
video_file = genai.upload_file(path="video.mp4", display_name="My Video")
while video_file.state.name == "PROCESSING":
    print("Processing video...")
    time.sleep(10)
    video_file = genai.get_file(video_file.name)

model = genai.GenerativeModel("gemini-1.5-pro")
response = model.generate_content([
    video_file,
    "List the key topics covered in this video with timestamps."
])
print(response.text)
```

---

## Example 13 — Embeddings
```python
import numpy as np

def get_embedding(text, task="RETRIEVAL_DOCUMENT"):
    result = genai.embed_content(
        model="models/text-embedding-004",
        content=text,
        task_type=task
    )
    return np.array(result["embedding"])

def cosine_sim(a, b):
    return float(np.dot(a,b) / (np.linalg.norm(a) * np.linalg.norm(b)))

docs = ["Python is great", "Java is verbose", "JavaScript is everywhere"]
doc_vecs = [get_embedding(d) for d in docs]

query_vec = get_embedding("scripting language", task="RETRIEVAL_QUERY")
scores = [(docs[i], cosine_sim(query_vec, doc_vecs[i])) for i in range(len(docs))]
for doc, score in sorted(scores, key=lambda x:-x[1]):
    print(f"{score:.3f}: {doc}")
```

---

## Example 14 — Function Calling (Auto Mode)
```python
def get_current_temperature(location: str) -> str:
    """Get the current temperature for a location."""
    return f"The temperature in {location} is 22 degrees Celsius."

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    tools=[get_current_temperature]
)
chat = model.start_chat(enable_automatic_function_calling=True)
response = chat.send_message("What is the temperature in Tokyo right now?")
print(response.text)   # Gemini calls the function automatically
```

---

## Example 15 — Grounding with Google Search
```python
from google.generativeai.types import Tool, GoogleSearchRetrieval

model = genai.GenerativeModel(
    "gemini-1.5-flash",
    tools=[Tool(google_search_retrieval=GoogleSearchRetrieval())]
)
response = model.generate_content("What are the latest AI developments this week?")
print(response.text)

# Show sources
if response.candidates[0].grounding_metadata:
    for chunk in response.candidates[0].grounding_metadata.grounding_chunks:
        print(f"Source: {chunk.web.uri}")
```

---

## Example 16 — Context Caching
```python
import datetime, time

long_text = "..." * 5000  # Large document

cache = genai.caching.CachedContent.create(
    model="models/gemini-1.5-flash-001",
    display_name="Large Document Cache",
    system_instruction="Answer questions based on the provided document.",
    contents=[{"role":"user","parts":[{"text":long_text}]}],
    ttl=datetime.timedelta(hours=1)
)
model = genai.GenerativeModel.from_cached_content(cached_content=cache)
r = model.generate_content("Summarize the main points.")
print(r.text)
```

---

## Example 17 — New SDK (google-genai)
```python
from google import genai as genai_new
import os

client = genai_new.Client(api_key=os.environ["GOOGLE_API_KEY"])
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents="Explain transformers in machine learning."
)
print(response.text)
```

---

## Example 18 — Async Generation (new SDK)
```python
import asyncio
from google import genai as genai_new

async def main():
    client = genai_new.Client()
    prompts = ["Fact about Python", "Fact about Rust", "Fact about Go"]
    tasks = [
        client.aio.models.generate_content(model="gemini-2.0-flash", contents=p)
        for p in prompts
    ]
    results = await asyncio.gather(*tasks)
    for r in results:
        print(r.text[:80])

asyncio.run(main())
```

---

## Example 19 — Multi-Image Comparison
```python
import PIL.Image
model = genai.GenerativeModel("gemini-1.5-flash")
img1 = PIL.Image.open("before.jpg")
img2 = PIL.Image.open("after.jpg")
response = model.generate_content([
    "Compare these two images. What changed?",
    "Image 1 (before):", img1,
    "Image 2 (after):", img2
])
print(response.text)
```

---

## Example 20 — PDF Q&A with File API
```python
# Upload once, query multiple times
pdf_file = genai.upload_file(path="research.pdf")
model = genai.GenerativeModel("gemini-1.5-pro")

questions = [
    "What is the main hypothesis of this paper?",
    "What methodology was used?",
    "What were the key findings?"
]
for q in questions:
    r = model.generate_content([q, pdf_file])
    print(f"Q: {q}")
    print(f"A: {r.text[:200]}\n")

genai.delete_file(pdf_file.name)
```