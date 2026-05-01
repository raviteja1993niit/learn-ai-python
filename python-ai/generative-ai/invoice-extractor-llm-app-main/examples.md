# Multimodal LLM Applications — Code Examples (20 Examples)

```bash
pip install openai google-generativeai pymupdf pdfplumber pydantic pillow open-clip-torch
```

---

## Example 1 — Describe Image via URL
```python
from openai import OpenAI
client = OpenAI()

r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role":"user","content":[
        {"type":"text","text":"What is in this image? Be specific."},
        {"type":"image_url","image_url":{"url":"https://upload.wikimedia.org/wikipedia/commons/4/4f/Cub_portrait_2.jpg","detail":"low"}}
    ]}], max_tokens=200
)
print(r.choices[0].message.content)
```

---

## Example 2 — Encode and Describe Local Image
```python
import base64
def encode_image(path, mime="image/jpeg"):
    with open(path,"rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    return f"data:{mime};base64,{b64}"

def describe_image(image_path, prompt="Describe this image."):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":prompt},
            {"type":"image_url","image_url":{"url":url,"detail":"high"}}
        ]}], max_tokens=500
    )
    return r.choices[0].message.content

print(describe_image("receipt.jpg","Extract all text you can see."))
```

---

## Example 3 — Invoice Extractor (Pydantic)
```python
from pydantic import BaseModel
from typing import List, Optional

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
    url = encode_image(image_path)
    r = client.beta.chat.completions.parse(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":"Extract all invoice data exactly as structured."},
            {"type":"image_url","image_url":{"url":url,"detail":"high"}}
        ]}],
        response_format=Invoice
    )
    return r.choices[0].message.parsed

# invoice = extract_invoice("invoice.jpg")
# print(invoice.vendor_name, invoice.total)
```

---

## Example 4 — Receipt Parser (JSON Mode)
```python
import json
def parse_receipt(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        response_format={"type":"json_object"},
        messages=[
            {"role":"system","content":"Extract receipt data as JSON. Required fields: store_name, date, items (list of {name, price}), total, currency."},
            {"role":"user","content":[
                {"type":"text","text":"Extract this receipt."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ]
    )
    return json.loads(r.choices[0].message.content)

# receipt = parse_receipt("receipt.jpg")
# print(receipt["total"])
```

---

## Example 5 — Chart / Graph Data Extractor
```python
def extract_chart_data(chart_path):
    url = encode_image(chart_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":"""Extract data from this chart/graph.
Provide:
1. Chart type (bar, line, pie, etc.)
2. Title and axis labels
3. All data points as a table
4. Key observations
Format the data table as: Label | Value"""},
            {"type":"image_url","image_url":{"url":url,"detail":"high"}}
        ]}], max_tokens=800
    )
    return r.choices[0].message.content
```

---

## Example 6 — PDF Text + Image Extraction
```python
import fitz   # PyMuPDF

def extract_pdf(pdf_path, max_pages=5):
    doc = fitz.open(pdf_path)
    pages = []
    for i, page in enumerate(doc[:max_pages]):
        text = page.get_text()
        pix = page.get_pixmap(matrix=fitz.Matrix(1.5,1.5))
        img_path = f"page_{i}.png"
        pix.save(img_path)
        pages.append({"page":i+1, "text":text, "image":img_path})
    doc.close()
    return pages

pages = extract_pdf("document.pdf")
for p in pages:
    print(f"Page {p['page']}: {len(p['text'])} chars")
```

---

## Example 7 — PDF Page Q&A with GPT-4o Vision
```python
def ask_pdf_page(pdf_path, page_num, question):
    doc = fitz.open(pdf_path)
    page = doc[page_num]
    pix = page.get_pixmap(matrix=fitz.Matrix(2,2))
    img_bytes = pix.tobytes("png")
    doc.close()

    b64 = base64.b64encode(img_bytes).decode()
    url = f"data:image/png;base64,{b64}"

    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":question},
            {"type":"image_url","image_url":{"url":url,"detail":"high"}}
        ]}], max_tokens=500
    )
    return r.choices[0].message.content

# answer = ask_pdf_page("contract.pdf", 0, "What is the payment amount?")
```

---

## Example 8 — Medical Image Describer (Non-diagnostic)
```python
def describe_medical_image(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"You describe medical images for educational purposes only. Always note this is NOT a clinical diagnosis."},
            {"role":"user","content":[
                {"type":"text","text":"Describe the visible structures in this medical image. Educational description only."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ], max_tokens=500
    )
    return r.choices[0].message.content
```

---

## Example 9 — Compare Two Images
```python
def compare_images(path1, path2, question="What are the key differences?"):
    imgs = [encode_image(p) for p in [path1, path2]]
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"user","content":[
            {"type":"text","text":question},
            {"type":"image_url","image_url":{"url":imgs[0]}},
            {"type":"image_url","image_url":{"url":imgs[1]}}
        ]}], max_tokens=500
    )
    return r.choices[0].message.content

print(compare_images("before.jpg","after.jpg","What changed between these images?"))
```

---

## Example 10 — Whisper + GPT-4o Audio Pipeline
```python
def audio_to_summary(audio_path):
    # Step 1: Transcribe
    with open(audio_path,"rb") as f:
        transcript = client.audio.transcriptions.create(
            model="whisper-1", file=f, response_format="text"
        )
    # Step 2: Summarise + extract actions
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Summarise this transcript. Extract: key topics, decisions made, action items with owners."},
            {"role":"user","content":transcript}
        ]
    )
    return {"transcript": transcript, "summary": r.choices[0].message.content}
```

---

## Example 11 — Batch Image Processor
```python
import os, csv, time

def batch_process_images(folder, output_csv="results.csv"):
    results = []
    image_files = [f for f in os.listdir(folder) if f.endswith((".jpg",".png",".jpeg"))]
    for i, fname in enumerate(image_files):
        path = os.path.join(folder, fname)
        url = encode_image(path)
        r = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role":"user","content":[
                {"type":"text","text":"Describe this image in one sentence."},
                {"type":"image_url","image_url":{"url":url,"detail":"low"}}
            ]}], max_tokens=100
        )
        results.append({"file":fname,"description":r.choices[0].message.content})
        print(f"[{i+1}/{len(image_files)}] {fname}")
        time.sleep(0.5)  # rate limit
    with open(output_csv,"w",newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["file","description"])
        writer.writeheader(); writer.writerows(results)
    return results
```

---

## Example 12 — Claude Vision via Bedrock
```python
import boto3, json, base64

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

def claude_vision(image_path, prompt):
    with open(image_path,"rb") as f:
        img_b64 = base64.b64encode(f.read()).decode()
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role":"user","content":[
            {"type":"image","source":{"type":"base64","media_type":"image/jpeg","data":img_b64}},
            {"type":"text","text":prompt}
        ]}]
    })
    r = bedrock.invoke_model(modelId="anthropic.claude-3-5-sonnet-20241022-v2:0", body=body)
    return json.loads(r["body"].read())["content"][0]["text"]
```

---

## Example 13 — Gemini PDF Analyser
```python
import google.generativeai as genai, time

def gemini_pdf_qa(pdf_path, question):
    f = genai.upload_file(path=pdf_path, display_name="Document")
    while f.state.name == "PROCESSING":
        time.sleep(3); f = genai.get_file(f.name)
    model = genai.GenerativeModel("gemini-1.5-pro")
    r = model.generate_content([f, question])
    genai.delete_file(f.name)
    return r.text

# print(gemini_pdf_qa("annual_report.pdf","What were the key financial highlights?"))
```

---

## Example 14 — Table Extractor from Image
```python
def extract_table(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        response_format={"type":"json_object"},
        messages=[
            {"role":"system","content":"Extract tables from images as JSON. Return: {headers:[...], rows:[[...],[...]]}"},
            {"role":"user","content":[
                {"type":"text","text":"Extract all table data from this image as JSON."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ]
    )
    import json
    return json.loads(r.choices[0].message.content)
```

---

## Example 15 — Form Field Extractor
```python
def extract_form(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        response_format={"type":"json_object"},
        messages=[
            {"role":"system","content":"Extract form fields as JSON: {field_name: value}. For empty fields use null. For checkboxes use true/false."},
            {"role":"user","content":[
                {"type":"text","text":"Extract all form fields and their values."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ]
    )
    import json
    return json.loads(r.choices[0].message.content)
```

---

## Example 16 — Product Image to Description
```python
def product_to_listing(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"You write product listings for e-commerce. Be specific about visible features."},
            {"role":"user","content":[
                {"type":"text","text":"Write an e-commerce product description for this item. Include: title, 3 bullet point features, full description (2 sentences)."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ], max_tokens=300
    )
    return r.choices[0].message.content
```

---

## Example 17 — Code Screenshot Extractor
```python
def extract_code_from_screenshot(image_path):
    url = encode_image(image_path)
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"Extract code from screenshots. Return ONLY the code, no explanation."},
            {"role":"user","content":[
                {"type":"text","text":"Extract the code from this screenshot. Preserve formatting exactly."},
                {"type":"image_url","image_url":{"url":url,"detail":"high"}}
            ]}
        ], max_tokens=2000
    )
    return r.choices[0].message.content
```

---

## Example 18 — Estimate Image Token Cost
```python
def estimate_vision_tokens(width, height, detail="high"):
    if detail == "low": return 85
    max_dim = 2048
    scale = min(max_dim/width, max_dim/height, 1.0)
    w, h = int(width*scale), int(height*scale)
    min_side = min(w,h)
    if min_side > 768:
        scale2 = 768/min_side
        w, h = int(w*scale2), int(h*scale2)
    tiles = ((w+511)//512) * ((h+511)//512)
    return 85 + tiles * 170

for size in [(640,480),(1920,1080),(3840,2160)]:
    tokens = estimate_vision_tokens(*size)
    cost = tokens * 10 / 1e6   # gpt-4o output price per token as approx
    print(f"{size[0]}x{size[1]}: {tokens} tokens (~${cost:.5f})")
```

---

## Example 19 — Multi-page PDF Summariser
```python
def summarise_pdf(pdf_path, pages_per_chunk=3):
    pages = extract_pdf(pdf_path)
    chunk_summaries = []
    for i in range(0, len(pages), pages_per_chunk):
        chunk = pages[i:i+pages_per_chunk]
        combined_text = "\n---\n".join(p["text"] for p in chunk)
        r = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role":"system","content":"Summarise this document section in 3 bullet points."},
                {"role":"user","content":combined_text[:3000]}
            ], max_tokens=200
        )
        chunk_summaries.append(r.choices[0].message.content)
    # Final reduction
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Create a cohesive executive summary from these section summaries."},
            {"role":"user","content":"\n\n".join(chunk_summaries)}
        ], max_tokens=400
    )
    return r.choices[0].message.content
```

---

## Example 20 — Image QA Chatbot Session
```python
def image_qa_session(image_path):
    b64_url = encode_image(image_path)
    messages = [
        {"role":"system","content":"You are analysing the provided image. Answer questions about it accurately."},
        {"role":"user","content":[
            {"type":"text","text":"I will ask you questions about this image."},
            {"type":"image_url","image_url":{"url":b64_url,"detail":"high"}}
        ]},
        {"role":"assistant","content":"I can see the image. What would you like to know?"}
    ]
    print("Image loaded. Type 'quit' to exit.")
    while True:
        q = input("Question: ").strip()
        if q.lower() == "quit": break
        messages.append({"role":"user","content":q})
        r = client.chat.completions.create(model="gpt-4o", messages=messages, max_tokens=300)
        answer = r.choices[0].message.content
        messages.append({"role":"assistant","content":answer})
        print(f"Answer: {answer}\n")
```