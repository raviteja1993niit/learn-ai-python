# Multimodal LLM Applications — Practical Projects (10 Projects)

```bash
pip install openai google-generativeai pymupdf pdfplumber pydantic streamlit boto3 pillow
```

---

## Project 1 — Invoice Extractor App (Structured Output)
**Goal**: Upload invoice image → get fully structured JSON data.
**Features**: batch processing, CSV export, confidence scoring, error handling for missing fields
**Stack**: GPT-4o Vision, Pydantic, Streamlit or CLI
**Key concepts**: base64 encoding, structured outputs, Optional fields
**Hint**:
```python
from pydantic import BaseModel
from typing import Optional, List
class LineItem(BaseModel):
    description: str; quantity: float; unit_price: float; total: float
class Invoice(BaseModel):
    vendor_name: str; invoice_number: Optional[str]; date: Optional[str]
    items: List[LineItem]; subtotal: float; tax: Optional[float]; total: float
# Use client.beta.chat.completions.parse() with response_format=Invoice
```
**Extension**: Compare GPT-4o vs Claude 3.5 Sonnet accuracy on same invoices.

---

## Project 2 — Medical Image Describer (Educational)
**Goal**: Describe medical/anatomical images for educational purposes.
**Disclaimer**: Always include "NOT for clinical use" warnings.
**Features**: image description, anatomical structure identification, educational notes
**Key concepts**: responsible AI, system prompt constraints, vision API
**Hint**: System prompt must include explicit disclaimer; use high detail; prompt for educational description only
**Extension**: Build flashcard quiz from descriptions for medical students.

---

## Project 3 — Chart / Graph Data Extractor
**Goal**: Extract raw data from chart images (bar, line, pie, scatter).
**Features**: chart type detection, data table extraction, matplotlib recreation from extracted data
**Stack**: GPT-4o Vision + JSON mode
**Key concepts**: structured data extraction, image analysis
**Hint**: Prompt: "Extract all data points. Return JSON: {chart_type, title, x_label, y_label, data: [{label, value}]}"
**Extension**: Use extracted data to recreate the chart with matplotlib.

---

## Project 4 — Multi-Document PDF Analyser
**Goal**: Upload 3+ PDFs, compare and synthesise insights.
**Features**: per-document summary, cross-document comparison, Q&A mode
**Stack**: Gemini 1.5 Pro File API (2M context)
**Key concepts**: File API, multiple file references, long-context reasoning
**Hint**: Upload all PDFs, keep file handles, pass all to generate_content in one call for comparison

---

## Project 5 — Meeting Recording Summariser
**Goal**: Upload audio recording → transcript + structured meeting notes.
**Features**: speaker diarisation (if available), action items, decisions, follow-ups
**Stack**: Whisper (STT) + GPT-4o (analysis)
**Key concepts**: audio transcription, structured analysis, markdown output
**Hint**:
```python
# Whisper returns timestamps in verbose_json mode
with open("meeting.mp3","rb") as f:
    t = client.audio.transcriptions.create(model="whisper-1", file=f,
        response_format="verbose_json")
# Then use GPT to extract: attendees, agenda, decisions, actions
```

---

## Project 6 — Product Catalogue Generator
**Goal**: Photograph products → auto-generate structured product listings.
**Features**: title, description, category detection, key features, tags, SEO keywords
**Stack**: GPT-4o Vision + JSON mode
**Key concepts**: product understanding, structured output, batch processing
**Hint**: Process entire folder of product images; output to CSV for e-commerce import; use detail="high" for product images

---

## Project 7 — Document Classification System
**Goal**: Classify documents (invoice, contract, form, receipt, letter) and extract type-specific data.
**Features**: automatic type detection, schema-based extraction per type, confidence score
**Architecture**: Vision → classify → select schema → extract → validate
**Key concepts**: conditional prompting, Pydantic discriminated unions, batch processing
**Hint**:
```python
# Step 1: classify
r = client.chat.completions.create(model="gpt-4o-mini",
    messages=[{"role":"user","content":[
        {"type":"text","text":"What type of document is this? Reply with one word: invoice/receipt/contract/form/other"},
        {"type":"image_url","image_url":{"url":b64}}
    ]}], max_tokens=5)
doc_type = r.choices[0].message.content.strip().lower()
# Step 2: extract using type-specific schema
```

---

## Project 8 — Visual QA Chatbot (Streamlit)
**Goal**: Web app where users upload an image and ask unlimited questions.
**Features**: image upload, multi-turn Q&A, conversation history, export transcript
**Stack**: GPT-4o, Streamlit
**Key concepts**: session state for image + history, Streamlit file_uploader, multi-turn vision
**Hint**:
```python
import streamlit as st
uploaded = st.file_uploader("Upload image", type=["jpg","png","jpeg"])
if uploaded:
    b64 = base64.b64encode(uploaded.read()).decode()
    if "vqa_history" not in st.session_state:
        st.session_state.vqa_history = [
            {"role":"user","content":[
                {"type":"text","text":"Image loaded for Q&A"},
                {"type":"image_url","image_url":{"url":f"data:image/jpeg;base64,{b64}"}}
            ]},
            {"role":"assistant","content":"Image loaded. Ask me anything about it."}
        ]
```

---

## Project 9 — Receipt-to-Expense Report
**Goal**: Photograph multiple receipts → generate formatted expense report.
**Features**: extract per-receipt data, categorise expenses, total per category, Excel output
**Stack**: GPT-4o Vision + Pydantic + openpyxl
**Key concepts**: batch extraction, categorisation, data aggregation
**Hint**: Categories: meals, transport, accommodation, supplies, other; prompt model to assign category based on store name and items
**Extension**: Auto-detect currency and convert to base currency using an exchange rate API.

---

## Project 10 — Multimodal RAG with PDF and Images
**Goal**: Build a searchable knowledge base from PDFs that includes visual understanding.
**Architecture**: PDF → extract pages as images → CLIP embed page images → user query → retrieve similar pages → GPT-4o vision answers
**Features**: page-level retrieval, visual context in answers, multi-PDF support
**Key concepts**: CLIP embeddings, multimodal retrieval, ColPali-inspired approach
**Hint**:
```python
import fitz, open_clip, torch
from PIL import Image
model_clip, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai")
def embed_page_image(img_path):
    img = preprocess(Image.open(img_path)).unsqueeze(0)
    with torch.no_grad(): return model_clip.encode_image(img).squeeze().numpy()
def embed_query(text):
    import open_clip
    tokens = open_clip.get_tokenizer("ViT-B-32")([text])
    with torch.no_grad(): return model_clip.encode_text(tokens).squeeze().numpy()
```
**Extension**: Add a Streamlit UI with PDF upload and a chat interface.