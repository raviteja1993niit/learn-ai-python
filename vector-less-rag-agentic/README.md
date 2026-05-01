# Agentic Vector-less RAG App

A **non-programmatic RAG app** — no BM25, no embeddings, no retrieval code.  
Documents are converted to a **structured JSON tree** and the **GitHub Copilot LLM acts as the retrieval agent** by reading the full document context.

## Architecture

```
Document (PDF / DOCX / XLSX)
         │
         ▼
   convert.py         ← helper script: extracts sections + tables
         │
         ▼
   JSON Tree File     ← structured: { sections: [...], tables: [...] }
         │
         ▼
   ask.py             ← helper script: sends full JSON to Copilot LLM
         │
         ▼
   GitHub Copilot LLM ← acts as the agent: reads JSON, retrieves, answers
         │
         ▼
      Answer
```

**Key difference from vector RAG:**  
The LLM receives the **entire document** as structured JSON context and uses its own reasoning to find relevant information — no BM25, no embeddings, no retriever class needed.

---

## Setup

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Authenticate (one-time, no token entry ever again)

**Option A — GitHub CLI (recommended):**
```bash
# Install gh CLI if you don't have it: https://cli.github.com
gh auth login
```
That's it. The app reads your token automatically via `gh auth token`.

**Option B — Environment variable:**
```bash
set GITHUB_TOKEN=ghp_your_token   # Windows
export GITHUB_TOKEN=ghp_your_token # Mac/Linux
```
Get a free token at [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new) (no scopes needed).

---

## Usage

### Option A — Streamlit Web UI (recommended)

```bash
streamlit run app.py
```

1. Open the browser (usually http://localhost:8501)
2. Paste your GitHub Token in the sidebar
3. Upload a PDF, DOCX, or XLSX file
4. The app converts it to a JSON tree automatically
5. Ask questions in the chat box — the LLM answers from the full document

### Option B — CLI Scripts

**Step 1:** Convert document to JSON tree
```bash
python convert.py report.pdf                    # → report.json (auto-detects TOC)
python convert.py contract.docx output.json     # custom output path
python convert.py data.xlsx
```

**Step 2:** Ask questions (no token arg — uses gh CLI auth automatically)
```bash
python ask.py report.json "What is the total revenue?"
python ask.py report.json "Summarize the key findings" --model gpt-4o
```

---

## Available Models

| Model | Notes |
|-------|-------|
| `gpt-4o-mini` | Default — fast, free tier |
| `gpt-4o` | Best quality, 128K context |
| `Meta-Llama-3.1-70B-Instruct` | Open-source, strong |
| `Meta-Llama-3.1-8B-Instruct` | Open-source, fast |
| `Phi-3.5-mini-instruct` | Microsoft, very fast |
| `mistral-large` | Mistral, strong reasoning |
| `mistral-small` | Mistral, fast |

---

## Document Structure Support

| Document type | With TOC | Without TOC |
|--------------|----------|-------------|
| **PDF** | Uses PDF outline/bookmarks as section boundaries | Scans each line: heading patterns → section splits; first meaningful sentence → auto-heading |
| **DOCX** | Uses Word Heading styles (Heading 1/2/3…) | Detects heading-like lines by pattern; falls back to grouping paragraphs with auto-generated headings |
| **XLSX** | Sheet names are always the headings | N/A |

Auto-heading logic (for no-TOC docs):
- Numbered lines: `1.`, `1.2`, `Chapter 3` → section heading
- ALL-CAPS short lines → section heading  
- Title-case lines ≤ 12 words without sentence punctuation → section heading
- If nothing qualifies: first sentence of the paragraph block becomes the heading

The `convert.py` script produces:

```json
{
  "filename": "report.pdf",
  "file_type": "pdf",
  "sections": [
    {
      "id": 0,
      "heading": "Executive Summary",
      "level": 1,
      "content": "This report covers..."
    }
  ],
  "tables": [
    {
      "id": 0,
      "section_id": 0,
      "headers": ["Year", "Revenue", "Profit"],
      "rows": [["2023", "10M", "2M"], ["2024", "15M", "4M"]]
    }
  ]
}
```

You can inspect or edit this JSON file before asking questions.

---

## Compared to vector-less-rag-app

| Feature | `vector-less-rag-app` | `vector-less-rag-agentic` |
|---------|----------------------|--------------------------|
| Retrieval | BM25 keyword search | LLM reads full document |
| Context | Top-K chunks only | Full JSON tree |
| Code complexity | Retriever + chunker classes | 2 simple scripts |
| Best for | Large docs (>50 pages) | Small–medium docs |
| Structure-aware | No | Yes (sections + tables) |
