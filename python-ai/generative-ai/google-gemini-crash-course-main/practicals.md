# Google Gemini API — Practical Projects (10 Projects)

```bash
pip install google-generativeai pillow python-dotenv pypdf2 streamlit numpy
```

---

## Project 1 — Multimodal Image Analyser
**Goal**: Analyse any image and answer questions about it.
**Features**: upload image, ask multiple questions, export Q&A to JSON
**Key concepts**: File API, multi-part messages, session history
**Hint**:
```python
image = PIL.Image.open("image.jpg")
model = genai.GenerativeModel("gemini-1.5-flash")
chat = model.start_chat()
r = chat.send_message(["What is in this image?", image])
print(r.text)
# Follow up with text-only questions using same chat session
r2 = chat.send_message("What colours are most prominent?")
```

---

## Project 2 — PDF Summariser and Q&A
**Goal**: Upload a PDF, get a summary, then answer questions about it.
**Features**: executive summary, bullet-point key findings, Q&A mode, multi-PDF support
**Key concepts**: File API, long-context, prompt engineering
**Hint**: Use Gemini 1.5 Pro for 2M context; upload PDF with File API, keep file handle, query multiple times without re-uploading

---

## Project 3 — AI Code Reviewer
**Goal**: Review code files for bugs, style, and security issues.
**Features**: multi-language support, severity ratings, fix suggestions, batch review
**Key concepts**: structured output, File API for large files, response schema
**Hint**:
```python
import typing_extensions as typing
class Issue(typing.TypedDict):
    line: int
    severity: str
    category: str
    description: str
    suggestion: str
model = genai.GenerativeModel("gemini-1.5-flash",
    generation_config={"response_mime_type":"application/json",
                       "response_schema":list[Issue]})
```

---

## Project 4 — Search-Grounded Chatbot
**Goal**: Chatbot that answers questions with live Google Search grounding.
**Features**: cited answers, source links, follow-up questions, topic focus
**Key concepts**: Grounding tool, grounding_metadata, citation display
**Hint**: Extract sources from response.candidates[0].grounding_metadata.grounding_chunks and display them with the answer

---

## Project 5 — YouTube Video Analyser
**Goal**: Upload a video file, extract insights and Q&A.
**Features**: timeline summary, topic extraction, Q&A, highlight moments
**Key concepts**: File API for video, state polling (PROCESSING), Gemini 1.5 Pro
**Hint**: Poll `sample_file.state.name != "ACTIVE"` with time.sleep(5); use Gemini 1.5 Pro for best video understanding

---

## Project 6 — Multi-document Comparison
**Goal**: Compare 2-3 documents and highlight differences/similarities.
**Features**: side-by-side comparison, key differences table, consensus summary
**Key concepts**: multi-file upload, structured output, long context
**Hint**: Upload all documents with File API, pass all as parts in one prompt; ask for structured JSON comparison table

---

## Project 7 — Semantic Search with Gemini Embeddings
**Goal**: Build a searchable knowledge base using Gemini embeddings.
**Features**: index 50+ paragraphs, semantic search, top-5 results, follow-up answers
**Key concepts**: embed_content(), task types, cosine similarity, numpy
**Hint**: Use RETRIEVAL_DOCUMENT for indexing and RETRIEVAL_QUERY for queries; text-embedding-004 has 768 dimensions

---

## Project 8 — Function-Calling Data Pipeline Agent
**Goal**: Agent that can query databases, do calculations, and format reports.
**Tools to implement**: query_db(sql), calculate(expr), format_table(data), send_email(to, subject, body)
**Key concepts**: function calling, automatic function calling, multi-step reasoning
**Hint**: Pass Python functions directly to tools=[f1, f2, ...] and set enable_automatic_function_calling=True

---

## Project 9 — Structured Data Extractor
**Goal**: Extract structured data from any document type (invoice, form, receipt).
**Features**: configurable extraction schema, batch processing, CSV export
**Key concepts**: response_schema, TypedDict, File API
**Hint**:
```python
class Invoice(typing.TypedDict):
    vendor: str
    date: str
    items: list[dict]
    total: float
    currency: str
model = genai.GenerativeModel("gemini-1.5-flash",
    generation_config={"response_mime_type":"application/json",
                       "response_schema":Invoice})
```

---

## Project 10 — Streamlit Gemini Chat App
**Goal**: Full-featured web chat UI using Gemini.
**Features**: model selector, file upload (images/PDFs), streaming, history, export
**Key concepts**: Streamlit session_state, streaming, file handling
**Hint**:
```python
import streamlit as st
import google.generativeai as genai

if "chat" not in st.session_state:
    model = genai.GenerativeModel("gemini-1.5-flash")
    st.session_state.chat = model.start_chat(history=[])

if prompt := st.chat_input("Message Gemini"):
    with st.chat_message("assistant"):
        response = st.session_state.chat.send_message(prompt, stream=True)
        st.write_stream(chunk.text for chunk in response)
```