# 👁️ Multimodal AI (Vision + Language) — Images, Video & Audio with LLMs

## What is Multimodal AI?
Multimodal AI combines multiple input types — images, video, audio, and text — in a single model inference call. Modern LLMs like GPT-4o, Gemini 1.5 Pro, and LLaVA accept rich content arrays so you can ask questions about images, extract data from documents, analyse charts, and transcribe audio all within the same pipeline.

## Why Learn It?
- Unlocks use cases impossible with text-only models (OCR, visual QA, chart analysis)
- GPT-4o and Gemini natively handle images, video frames, and audio
- Local vision models (LLaVA via Ollama) enable private, offline workflows
- Foundation for document intelligence, medical imaging, and accessibility tools

## Key Concepts
```python
import openai, base64, httpx
import google.generativeai as genai
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

client = openai.OpenAI()

# --- GPT-4o Vision: URL ---
resp = client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": "https://example.com/chart.png", "detail": "high"}},
            {"type": "text", "text": "What trend does this chart show?"},
        ],
    }],
    max_tokens=512,
)
print(resp.choices[0].message.content)

# --- GPT-4o Vision: base64 local file ---
with open("invoice.pdf.png", "rb") as f:
    b64 = base64.b64encode(f.read()).decode()
resp = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": [
        {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}},
        {"type": "text", "text": "Extract all line items and totals as JSON."},
    ]}],
)

# --- Gemini 1.5 Pro Multimodal ---
genai.configure(api_key="YOUR_KEY")
gemini = genai.GenerativeModel("gemini-1.5-pro")
import PIL.Image
img = PIL.Image.open("diagram.png")
gemini_resp = gemini.generate_content(["Explain this architecture diagram.", img])
print(gemini_resp.text)

# --- LLaVA via Ollama (local, private) ---
import ollama
with open("screenshot.png", "rb") as f:
    raw = f.read()
ollama_resp = ollama.chat(
    model="llava",
    messages=[{"role": "user", "content": "Describe what you see.", "images": [raw]}],
)
print(ollama_resp["message"]["content"])

# --- Audio: Whisper → GPT pipeline ---
audio_resp = client.audio.transcriptions.create(
    model="whisper-1", file=open("recording.mp3", "rb")
)
transcript = audio_resp.text
followup = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": f"Summarise this transcript:\n{transcript}"}],
)

# --- LangChain image chain ---
lc_model = ChatOpenAI(model="gpt-4o")
msg = HumanMessage(content=[
    {"type": "image_url", "image_url": {"url": "https://example.com/photo.jpg"}},
    {"type": "text", "text": "What objects are visible?"},
])
lc_resp = lc_model.invoke([msg])
```

## Learning Path
1. Send a URL-based image to GPT-4o and ask a question about it
2. Encode a local file as base64 and perform OCR / data extraction
3. Try Gemini 1.5 Pro with `PIL.Image` for multimodal generation
4. Run LLaVA locally via Ollama for fully private vision inference
5. Build the Whisper → GPT audio summarisation pipeline
6. Use LangChain image chains for composable vision workflows
7. Explore Gemini video understanding with uploaded video files
8. Build a full visual QA app with file upload and streaming answers

## What to Build
- [ ] Invoice/receipt OCR extractor: image → structured JSON
- [ ] Chart analyst: upload any chart image, receive trend summary
- [ ] Visual QA web app with Gradio or Streamlit + GPT-4o backend
- [ ] Private document scanner using LLaVA + Ollama (no data leaves machine)
- [ ] Podcast summariser: MP3 → Whisper transcript → GPT summary

## Related Folders
- `generative-ai\anthropic-claude-api-main\` — Claude vision with base64 content blocks
- `generative-ai\openai-function-calling-main\` — combining vision with tool calls
- `generative-ai\litellm-main\` — unified multimodal calls across providers
