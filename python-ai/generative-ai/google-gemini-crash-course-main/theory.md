# Google Gemini API — Complete Reference

## Table of Contents
1. Gemini Model Family  2. SDK Overview  3. Authentication
4. Basic Text Generation  5. Multi-part Messages  6. Chat Sessions
7. Streaming  8. System Instructions  9. Safety Settings
10. Generation Config  11. Grounding with Search  12. JSON Mode
13. Structured Output  14. File API  15. Token Counting
16. Embeddings  17. Function Calling  18. Context Caching
19. Vertex AI Integration  20. Best Practices

---

## 1. Gemini Model Family

| Model               | Context   | Modalities              | Best For                    |
|---------------------|-----------|-------------------------|-----------------------------|
| gemini-2.0-flash    | 1M tokens | Text,image,audio,video  | Fast, cost-effective (2025) |
| gemini-1.5-pro      | 2M tokens | Text,image,audio,video  | Complex long-context tasks  |
| gemini-1.5-flash    | 1M tokens | Text,image,audio,video  | Speed + multimodal balance  |
| gemini-1.0-pro      | 32K       | Text only               | Legacy; use 1.5-flash       |
| text-embedding-004  | 2K        | Text                    | Semantic embeddings         |

### Key Capabilities
- 2M token context (1.5 Pro) — fit 2 hours of video, entire codebases
- Native multimodal: send images, audio, video, and text together
- Built-in Google Search grounding
- Code execution tool (Python sandbox)
- Function calling for custom integrations

---

## 2. SDK Overview

### Old SDK (google-generativeai)
`ash
pip install google-generativeai
`
`python
import google.generativeai as genai
genai.configure(api_key="YOUR_KEY")
model = genai.GenerativeModel("gemini-1.5-flash")
`

### New SDK (google-genai) — Recommended for 2025
`ash
pip install google-genai
`
`python
from google import genai
client = genai.Client(api_key="YOUR_KEY")
`

### Differences
| Feature            | google-generativeai   | google-genai           |
|--------------------|-----------------------|------------------------|
| Style              | Module-level config   | Client object          |
| Async              | Limited               | Full async support     |
| Streaming          | Yes                   | Yes (improved)         |
| Live API           | No                    | Yes                    |
| Recommendation     | Legacy                | Use for new projects   |

---

## 3. Authentication

`ash
# Set environment variable
export GOOGLE_API_KEY="AIza..."  # Linux/Mac
set GOOGLE_API_KEY=AIza...       # Windows
`

`python
import os
import google.generativeai as genai

# Option 1: From environment variable
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])

# Option 2: Explicit
genai.configure(api_key="AIza...")

# Option 3: Using new SDK
from google import genai as genai_new
client = genai_new.Client(api_key=os.environ["GOOGLE_API_KEY"])
`

Get API key at: https://aistudio.google.com/app/apikey

---

## 4. Basic Text Generation

`python
import google.generativeai as genai
import os
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])

model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content("What is the capital of Japan?")
print(response.text)
print("Tokens used:", response.usage_metadata.total_token_count)
`

### Response Object
`
GenerateContentResponse
  text              — shortcut for candidates[0].content.parts[0].text
  candidates[]
    content.parts[].text
    finish_reason   STOP | MAX_TOKENS | SAFETY | OTHER
    safety_ratings[]
  usage_metadata
    prompt_token_count
    candidates_token_count
    total_token_count
`

---

## 5. Multi-part Messages (Multimodal)

Send text + images together using Part objects.

`python
import PIL.Image

model = genai.GenerativeModel("gemini-1.5-flash")
image = PIL.Image.open("photo.jpg")
response = model.generate_content([
    "Describe what you see in this image in detail.",
    image
])
print(response.text)
`

### inline_data (bytes)
`python
import pathlib
image_bytes = pathlib.Path("photo.jpg").read_bytes()
from google.generativeai.types import content_types
part = content_types.to_part({"mime_type":"image/jpeg","data":image_bytes})
response = model.generate_content(["What is in this image?", part])
`

### PDF Input
`python
pdf_bytes = pathlib.Path("document.pdf").read_bytes()
response = model.generate_content([
    "Summarise this document.",
    {"mime_type": "application/pdf", "data": pdf_bytes}
])
`

---

## 6. Chat Sessions

Gemini maintains conversation history automatically within a session.

`python
model = genai.GenerativeModel("gemini-1.5-flash")
chat = model.start_chat(history=[])

response = chat.send_message("Hello! I want to learn Python.")
print(response.text)

response2 = chat.send_message("What should I learn first?")
print(response2.text)

# Access history
for msg in chat.history:
    print(f"{msg.role}: {msg.parts[0].text[:80]}")
`

### Pre-load History
`python
chat = model.start_chat(history=[
    {"role": "user",  "parts": ["My name is Alice."]},
    {"role": "model", "parts": ["Nice to meet you, Alice!"]}
])
response = chat.send_message("What's my name?")
print(response.text)  # Should mention Alice
`

---

## 7. Streaming

`python
model = genai.GenerativeModel("gemini-1.5-flash")
response = model.generate_content(
    "Write a short story about a space explorer.",
    stream=True
)
for chunk in response:
    print(chunk.text, end="", flush=True)
print()

# Streaming in chat
chat = model.start_chat()
response = chat.send_message("Tell me about black holes.", stream=True)
for chunk in response:
    print(chunk.text, end="", flush=True)
`

---

## 8. System Instructions

Sets the model's persona and behavior before any user message.

`python
model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    system_instruction=(
        "You are a senior Python developer. "
        "Always provide code examples. "
        "Keep explanations concise and technical."
    )
)
response = model.generate_content("How do I read a JSON file?")
print(response.text)
`

---

## 9. Safety Settings

Control content filtering thresholds.

`python
from google.generativeai.types import HarmCategory, HarmBlockThreshold

safety = {
    HarmCategory.HARM_CATEGORY_HARASSMENT:       HarmBlockThreshold.BLOCK_ONLY_HIGH,
    HarmCategory.HARM_CATEGORY_HATE_SPEECH:      HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT:HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT:HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
}
model = genai.GenerativeModel("gemini-1.5-flash", safety_settings=safety)
`

### Threshold Levels
- BLOCK_NONE — allow all
- BLOCK_ONLY_HIGH — block only high-probability harmful content
- BLOCK_MEDIUM_AND_ABOVE — block medium+ (default)
- BLOCK_LOW_AND_ABOVE — most restrictive

---

## 10. Generation Config

Fine-tune response generation behaviour.

`python
from google.generativeai.types import GenerationConfig

config = GenerationConfig(
    temperature=0.7,        # 0.0–2.0; creativity
    top_p=0.95,             # nucleus sampling
    top_k=40,               # top-k sampling (unique to Gemini)
    max_output_tokens=1024, # output length cap
    stop_sequences=["END"], # stop generation at this string
    candidate_count=1       # number of response candidates
)
model = genai.GenerativeModel("gemini-1.5-flash", generation_config=config)
`

---

## 11. Grounding with Google Search

Connect Gemini to live Google Search for up-to-date, cited answers.

`python
from google.generativeai.types import Tool, GoogleSearchRetrieval

model = genai.GenerativeModel(
    "gemini-1.5-flash",
    tools=[Tool(google_search_retrieval=GoogleSearchRetrieval())]
)
response = model.generate_content("What happened in AI news today?")
print(response.text)

# Access grounding metadata
if response.candidates[0].grounding_metadata:
    for chunk in response.candidates[0].grounding_metadata.grounding_chunks:
        print(f"Source: {chunk.web.uri}")
`

---

## 12. JSON Mode

Force JSON output via response_mime_type.

`python
model = genai.GenerativeModel(
    "gemini-1.5-flash",
    generation_config={"response_mime_type": "application/json"}
)
response = model.generate_content(
    "List 5 programming languages with their year created. Return as JSON array."
)
import json
data = json.loads(response.text)
print(data)
`

---

## 13. Structured Output with response_schema

Guarantee output matches a schema (Gemini 1.5 Flash/Pro).

`python
import typing_extensions as typing

class Language(typing.TypedDict):
    name: str
    year: int
    paradigm: str

model = genai.GenerativeModel(
    "gemini-1.5-flash",
    generation_config={
        "response_mime_type": "application/json",
        "response_schema": list[Language]
    }
)
response = model.generate_content("List 5 programming languages.")
languages = json.loads(response.text)
`

---

## 14. File API

Upload large files (video, audio, PDF, images) for use across requests.

`python
# Upload
sample_file = genai.upload_file(
    path="video.mp4",
    display_name="My Video"
)
print(f"URI: {sample_file.uri}, State: {sample_file.state.name}")

# Wait for processing
import time
while sample_file.state.name == "PROCESSING":
    time.sleep(5)
    sample_file = genai.get_file(sample_file.name)

# Use the file
model = genai.GenerativeModel("gemini-1.5-pro")
response = model.generate_content(["Describe the key moments in this video.", sample_file])
print(response.text)

# List and delete files
for f in genai.list_files(): print(f.name)
genai.delete_file(sample_file.name)
`

Supported: images (JPEG/PNG/GIF/WEBP), video (MP4/MOV), audio (MP3/WAV/AIFF), docs (PDF, TXT, HTML, MD, CSV, XML, RTF).

---

## 15. Token Counting

`python
model = genai.GenerativeModel("gemini-1.5-flash")

# Count tokens for a simple prompt
result = model.count_tokens("Hello, how are you today?")
print(result.total_tokens)

# Count for multimodal
image = PIL.Image.open("photo.jpg")
result = model.count_tokens(["Describe this image.", image])
print(result.total_tokens)
`

---

## 16. Embeddings

`python
result = genai.embed_content(
    model="models/text-embedding-004",
    content="The quick brown fox jumps over the lazy dog",
    task_type="RETRIEVAL_DOCUMENT"
)
embedding = result["embedding"]  # list of 768 floats

# Task types
# RETRIEVAL_QUERY       — short queries
# RETRIEVAL_DOCUMENT    — documents to be retrieved
# SEMANTIC_SIMILARITY   — compare sentence similarity
# CLASSIFICATION        — classification tasks
# CLUSTERING            — clustering tasks
`

---

## 17. Function Calling

`python
def set_light(brightness: float, color_temp: str) -> dict:
    return {"brightness": brightness, "color_temp": color_temp, "status": "set"}

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    tools=[set_light]  # pass Python function directly!
)
chat = model.start_chat(enable_automatic_function_calling=True)
response = chat.send_message("Dim the lights to 30% with warm white.")
print(response.text)  # Gemini calls set_light and responds
`

---

## 18. Context Caching

Cache large context (system prompt + documents) to reduce cost on repeated calls.

`python
import datetime

# Create cache
cache = genai.caching.CachedContent.create(
    model="models/gemini-1.5-flash-001",
    display_name="Research Paper Cache",
    system_instruction="You are an expert researcher. Answer questions from the paper.",
    contents=[{"role":"user","parts":[{"text": long_paper_text}]}],
    ttl=datetime.timedelta(hours=1)
)

# Use cached model
model = genai.GenerativeModel.from_cached_content(cached_content=cache)
response = model.generate_content("What are the main findings?")
print(response.text)
`

---

## 19. Vertex AI Integration

For production deployments on GCP with enterprise security and scalability.

`ash
pip install google-cloud-aiplatform
gcloud auth application-default login
`

`python
import vertexai
from vertexai.generative_models import GenerativeModel

vertexai.init(project="your-project-id", location="us-central1")
model = GenerativeModel("gemini-1.5-flash")
response = model.generate_content("Explain transformers.")
print(response.text)
`

### Vertex AI vs AI Studio API
| Feature         | AI Studio (google-generativeai) | Vertex AI           |
|-----------------|---------------------------------|---------------------|
| Auth            | API key                         | GCP service account |
| Data residency  | No guarantee                    | Yes (region-locked) |
| SLA             | No SLA                          | Enterprise SLA      |
| Tuning          | Limited                         | Full Vertex tuning  |
| Cost            | Quota-based                     | Pay-per-use         |

---

## 20. Best Practices

### Performance
- Use gemini-1.5-flash for most tasks (faster, cheaper than Pro)
- Enable Context Caching for repeated large contexts (saves 75% cost)
- Use File API for media > 20MB instead of inline base64

### Prompting
- System instructions are more reliable than user-turn instructions
- For JSON output, always specify the exact schema in the prompt
- Top-k (40 default) helps with repetition; lower = more focused

### Safety
- Adjust safety settings per use case; log blocked responses for review
- Always check response.candidates[0].finish_reason before accessing .text

### Cost Estimation
- Count tokens before large requests using model.count_tokens()
- Videos billed at ~263 tokens/second
- Audio billed at ~32 tokens/second