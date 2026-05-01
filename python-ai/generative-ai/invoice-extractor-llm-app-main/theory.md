# Multimodal LLM Applications — Complete Reference

## Table of Contents
1. Multimodal AI Overview  2. Vision LLMs Comparison  3. Image Input Formats
4. Prompt Engineering for Vision  5. Document AI  6. OCR vs Vision LLM
7. Structured Extraction  8. PDF Processing  9. Multi-image Analysis
10. Video Understanding  11. Audio Input  12. Image Retrieval with CLIP
13. Multimodal RAG  14. Token Costs for Images  15. Resolution and Detail

---

## 1. Multimodal AI Overview

Multimodal AI processes multiple data types simultaneously: text + image + audio + video.

### Input/Output Matrix
| Model              | Text | Image | Audio | Video | Output         |
|--------------------|------|-------|-------|-------|----------------|
| GPT-4o             | In   | In    | In    | No    | Text           |
| GPT-4o-mini        | In   | In    | No    | No    | Text           |
| Gemini 1.5 Pro     | In   | In    | In    | In    | Text           |
| Gemini 1.5 Flash   | In   | In    | In    | In    | Text           |
| Claude 3 Opus/Sonnet| In  | In    | No    | No    | Text           |
| LLaVA              | In   | In    | No    | No    | Text (local)   |

### Use Cases
- **Document processing**: invoices, receipts, forms, contracts
- **Medical imaging**: describe X-rays, MRIs (descriptive, not diagnostic)
- **Chart analysis**: extract data from graphs and charts
- **Code screenshots**: extract and explain code from screenshots
- **Product images**: e-commerce descriptions, quality control
- **Video summarisation**: extract key moments and topics

---

## 2. Vision LLMs Comparison

### GPT-4o Vision
- Best for: detailed image analysis, document extraction, UI description
- Max images per request: 10 (varies by size constraints)
- detail parameter: low (85 tokens), high (up to 1445 tokens)
- Pricing: same as gpt-4o text pricing + image tokens

### Gemini 1.5 Pro Vision
- Best for: video understanding, long PDF analysis, multi-image sequences
- Accepts: images (inline or File API), video, audio, PDF
- Context: 2M tokens — can process entire videos
- Pricing: ~263 tokens/sec for video

### Claude 3 Vision (Anthropic)
- Best for: precise document extraction, following complex visual instructions
- Strong at: reading handwriting, understanding diagrams, charts
- Format: base64 or URL

### LLaVA (Open Source, Local)
- Run locally via Ollama: `ollama pull llava`
- Privacy: data never leaves your machine
- Weaker than commercial models for complex extraction

---

## 3. Image Input Formats

### URL (Simplest)
```python
{"type":"image_url","image_url":{"url":"https://example.com/image.jpg"}}
```
Pros: Simple; Cons: URL must be publicly accessible; slower for private images.

### Base64 (Recommended for Local Files)
```python
import base64
def encode_image(path, mime="image/jpeg"):
    with open(path,"rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    return f"data:{mime};base64,{b64}"

image_data = encode_image("invoice.jpg")
{"type":"image_url","image_url":{"url":image_data}}
```

### PIL Image (Gemini)
```python
import PIL.Image
image = PIL.Image.open("photo.jpg")
response = model.generate_content(["Describe this.", image])
```

### File API (Gemini — Large Files)
```python
file = genai.upload_file(path="document.pdf", display_name="Invoice PDF")
# Wait for processing, then use in generate_content
```

### MIME Types
| Extension | MIME Type       |
|-----------|-----------------|
| .jpg      | image/jpeg      |
| .png      | image/png       |
| .gif      | image/gif       |
| .webp     | image/webp      |
| .pdf      | application/pdf |
| .mp4      | video/mp4       |
| .mp3      | audio/mpeg      |

---

## 4. Prompt Engineering for Vision

### Be Specific About What to Extract
Bad: "What is in this image?"
Good: "This is an invoice. Extract: vendor name, invoice number, date, line items (description, qty, unit price), subtotal, tax amount, total. Return as JSON."

### Specify Output Format
```
Extract the following from this receipt and return as JSON with exactly these keys:
{
  "store_name": string,
  "date": "YYYY-MM-DD",
  "items": [{"name": string, "price": float}],
  "total": float,
  "currency": "USD"|"EUR"|...
}
If any field is not visible, use null.
```

### Use Roles in Multi-part Prompts
```python
messages = [{
    "role": "system",
    "content": "You are a document extraction specialist. Extract data exactly as instructed. If a field is not found, return null."
}, {
    "role": "user",
    "content": [
        {"type": "text", "text": "Extract all data from this invoice as JSON."},
        {"type": "image_url", "image_url": {"url": image_url}}
    ]
}]
```

---

## 5. Document AI

### Types of Business Documents
| Document      | Key Fields to Extract                                    |
|---------------|----------------------------------------------------------|
| Invoice       | vendor, date, items, subtotal, tax, total, currency      |
| Receipt       | store, date, items, total, payment method                |
| Form          | field names and values, checkboxes, signatures           |
| Contract      | parties, dates, key clauses, amounts, signatures         |
| Bank statement| transactions, dates, amounts, balances, account number   |

### Extraction Pattern
1. Encode image as base64 (or use URL)
2. Write specific extraction prompt with JSON schema
3. Use JSON mode or structured outputs
4. Validate with Pydantic
5. Handle missing fields gracefully

---

## 6. OCR vs Vision LLM

| Aspect            | Traditional OCR          | Vision LLM                        |
|-------------------|--------------------------|-----------------------------------|
| Text accuracy     | High for clean print     | Good, better on degraded/handwritten|
| Structure         | Needs extra parsing      | Understands layout naturally       |
| JSON output       | Requires post-processing | Native with prompting              |
| Handwriting       | Poor                     | Good (GPT-4o, Gemini)             |
| Tables            | Difficult                | Excellent                         |
| Context awareness | None                     | Understands document context       |
| Speed             | Fast (local)             | Slower, API latency                |
| Cost              | Low/free                 | Per-token pricing                  |
| Privacy           | Local                    | API (data leaves your system)      |

### Hybrid Approach
Use OCR for initial text extraction, then LLM for understanding and structuring:
```python
import pytesseract
from PIL import Image

def hybrid_extract(image_path):
    # Step 1: OCR for raw text
    ocr_text = pytesseract.image_to_string(Image.open(image_path))
    # Step 2: LLM for structuring
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Extract structured JSON from this invoice text."},
            {"role":"user","content":ocr_text}
        ],
        response_format={"type":"json_object"}
    )
    return json.loads(response.choices[0].message.content)
```

---

## 7. Structured Extraction from Images

### Pydantic + Vision
```python
from pydantic import BaseModel
from typing import Optional, List

class LineItem(BaseModel):
    description: str
    quantity: float
    unit_price: float
    total: float

class Invoice(BaseModel):
    vendor_name: str
    invoice_number: Optional[str]
    date: Optional[str]
    items: List[LineItem]
    subtotal: float
    tax: Optional[float]
    total: float
    currency: str = "USD"

def extract_invoice(image_path):
    b64 = encode_image(image_path)
    response = client.beta.chat.completions.parse(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":"Extract all invoice data."},
            {"type":"image_url","image_url":{"url":b64}}
        ]}],
        response_format=Invoice
    )
    return response.choices[0].message.parsed
```

---

## 8. PDF Processing

### PyMuPDF (fitz) — Extract Text + Images
```bash
pip install pymupdf
```
```python
import fitz   # pymupdf

def extract_pdf_pages(pdf_path):
    doc = fitz.open(pdf_path)
    pages = []
    for page in doc:
        text = page.get_text()
        pix = page.get_pixmap(matrix=fitz.Matrix(2,2))  # 2x resolution
        img_bytes = pix.tobytes("png")
        pages.append({"text": text, "image_bytes": img_bytes})
    doc.close()
    return pages
```

### pdfplumber — Tables and Text
```bash
pip install pdfplumber
```
```python
import pdfplumber
def extract_with_tables(pdf_path):
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            print("TEXT:", page.extract_text())
            tables = page.extract_tables()
            for table in tables:
                for row in table:
                    print(row)
```

---

## 9. Multi-image Analysis

### Compare Two Images
```python
def compare_images(image1_path, image2_path, question):
    imgs = [encode_image(p) for p in [image1_path, image2_path]]
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":question},
            {"type":"text","text":"Image 1:"},
            {"type":"image_url","image_url":{"url":imgs[0]}},
            {"type":"text","text":"Image 2:"},
            {"type":"image_url","image_url":{"url":imgs[1]}}
        ]}]
    )
    return response.choices[0].message.content

result = compare_images("before.jpg","after.jpg","What changed between these two images?")
```

### Batch Image Processing
```python
def batch_describe(image_paths, batch_size=5):
    results = []
    for i in range(0, len(image_paths), batch_size):
        batch = image_paths[i:i+batch_size]
        for path in batch:
            b64 = encode_image(path)
            r = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role":"user","content":[
                    {"type":"text","text":"Describe this image in one sentence."},
                    {"type":"image_url","image_url":{"url":b64,"detail":"low"}}
                ]}], max_tokens=100)
            results.append({"file":path,"description":r.choices[0].message.content})
        import time; time.sleep(1)  # rate limit
    return results
```

---

## 10. Video Understanding (Gemini)

```python
import google.generativeai as genai, time

def analyse_video(video_path):
    print("Uploading video...")
    video_file = genai.upload_file(path=video_path, display_name="Video")
    while video_file.state.name == "PROCESSING":
        print("Processing...", end="", flush=True)
        time.sleep(5)
        video_file = genai.get_file(video_file.name)
    print(" Done!")
    model = genai.GenerativeModel("gemini-1.5-pro")
    response = model.generate_content([
        video_file,
        "Provide a detailed summary of this video. Include: 1) Main topic, 2) Key points with timestamps, 3) Conclusion"
    ])
    genai.delete_file(video_file.name)
    return response.text
```

---

## 11. Audio Input

### Whisper → LLM Pipeline
```python
def audio_to_insight(audio_path):
    # Step 1: Transcribe
    with open(audio_path,"rb") as f:
        transcript = client.audio.transcriptions.create(
            model="whisper-1", file=f, response_format="text"
        )
    # Step 2: Analyse
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Analyse this speech transcript. Extract: key topics, action items, sentiment, summary."},
            {"role":"user","content":transcript}
        ]
    )
    return {"transcript": transcript, "analysis": response.choices[0].message.content}
```

---

## 12. Image Retrieval with CLIP

CLIP creates shared text-image embedding space for cross-modal search.

```bash
pip install open-clip-torch pillow
```
```python
import open_clip, torch
from PIL import Image

model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai")
tokenizer = open_clip.get_tokenizer("ViT-B-32")

def image_embedding(path):
    img = preprocess(Image.open(path)).unsqueeze(0)
    with torch.no_grad():
        return model.encode_image(img).squeeze().numpy()

def text_embedding(text):
    tokens = tokenizer([text])
    with torch.no_grad():
        return model.encode_text(tokens).squeeze().numpy()
```

---

## 13. Multimodal RAG (ColPali Approach)

Traditional RAG loses visual information when converting PDFs to text.
ColPali embeds page images directly for retrieval.

```python
# Simplified multimodal RAG approach:
# 1. Convert PDF pages to images (PyMuPDF)
# 2. Embed each page image using CLIP or similar
# 3. For query: embed query text, find similar page images
# 4. Send retrieved page images + query to GPT-4o or Gemini

def multimodal_rag(query, page_images, page_embeddings):
    q_emb = text_embedding(query)
    from numpy.linalg import norm
    scores = [float(q_emb@p/(norm(q_emb)*norm(p))) for p in page_embeddings]
    top_pages = [page_images[i] for i in sorted(range(len(scores)), key=lambda i:-scores[i])[:3]]
    
    content = [{"type":"text","text":f"Answer this question: {query}"}]
    for img in top_pages:
        content.append({"type":"image_url","image_url":{"url":encode_image(img)}})
    
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":content}]
    )
    return r.choices[0].message.content
```

---

## 14. Token Costs for Images

### GPT-4o Image Pricing
| detail | Base tokens | Tiles         | Total tokens (approx) |
|--------|-------------|---------------|-----------------------|
| low    | 85          | 0             | 85                    |
| high   | 85          | varies (512px tiles × 170 each) | 170-1445 |

For high detail: image resized to max 2048px, then tiled in 512px chunks.
Each tile = 170 tokens + 85 base = 255 per tile.

### Calculate Image Cost
```python
def estimate_image_tokens(width, height, detail="high"):
    if detail == "low": return 85
    # Resize to fit 2048x2048
    max_dim = 2048
    scale = min(max_dim/width, max_dim/height, 1)
    w, h = int(width*scale), int(height*scale)
    # Resize shortest side to 768
    scale2 = 768/min(w,h)
    w, h = int(w*scale2), int(h*scale2)
    tiles_w = (w + 511) // 512
    tiles_h = (h + 511) // 512
    return 85 + (tiles_w * tiles_h * 170)

print(estimate_image_tokens(1920, 1080, "high"))  # approx 765
```

---

## 15. Resolution and Detail Tradeoffs

### Recommendations
| Use Case                    | detail    | Reason                              |
|-----------------------------|-----------|-------------------------------------|
| Invoice / receipt           | high      | Need to read small text and numbers |
| Simple scene description    | low       | Save tokens for basic Q&A           |
| Chart analysis              | high      | Need to read axis labels and values |
| UI screenshot               | high      | Small UI elements need detail       |
| Multiple image comparison   | low       | Save tokens when processing many    |
| Handwritten text            | high      | Fine details needed                 |
| Product thumbnail           | low       | Colour/shape sufficient             |

### Pre-processing for Better Results
- Increase contrast before sending degraded images
- Crop to relevant region (reduces tokens + improves focus)
- Convert to JPEG for lower file size (no quality loss for LLM input)
- For tables: ensure borders are clear; use high detail