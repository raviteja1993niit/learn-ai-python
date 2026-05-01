# Vector-Less RAG App

A Streamlit web app that lets you upload **PDF**, **Word (.docx)**, or **Excel (.xlsx)** files and ask natural language questions. It uses **BM25 keyword search** (no vector embeddings) to retrieve relevant chunks and **GitHub Copilot's hosted LLMs** (via the free GitHub Models API) to generate answers.

## How It Works

```
Upload file → Parse text → Split into chunks → BM25 index
                                                    ↓
                              Ask question → Retrieve top-K chunks → GitHub LLM → Answer
```

## Prerequisites

### Get a Free GitHub Personal Access Token (PAT)
1. Go to [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)
2. Give it any name (e.g. `rag-app`)
3. **No scopes required** — leave all checkboxes unchecked
4. Click **Generate token** and copy it

> You can also set `GITHUB_TOKEN` as an environment variable so you don't have to paste it every time.

## Installation

### Create and activate a virtual environment (recommended)
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### Install dependencies
```bash
pip install -r requirements.txt
```

## Running the App

```bash
streamlit run app.py
```

Then open [http://localhost:8501](http://localhost:8501), paste your GitHub PAT in the sidebar, upload a file, and start asking questions.

## Available Models (GitHub Models API)

| Model | Notes |
|---|---|
| `gpt-4o` | Best quality |
| `gpt-4o-mini` | Fast, free tier default |
| `Meta-Llama-3.1-70B-Instruct` | Open-source, very capable |
| `Meta-Llama-3.1-8B-Instruct` | Lighter/faster |
| `Phi-3.5-mini-instruct` | Microsoft, very lightweight |
| `mistral-large` | Mistral AI |

## Configuration (Sidebar)

| Setting | Description | Default |
|---|---|---|
| GitHub PAT | Your personal access token | from env / input |
| Model | Which GitHub-hosted model to use | `gpt-4o-mini` |
| Top-K chunks | How many chunks to send as context | 5 |
| Chunk size | Characters per chunk | 500 |
| Chunk overlap | Overlap between adjacent chunks | 50 |

## Project Structure

```
vector-less-rag-app/
├── app.py              # Streamlit UI
├── requirements.txt    # Python dependencies
├── README.md
└── src/
    ├── parser.py       # PDF/DOCX/XLSX text extraction
    ├── chunker.py      # Text chunking
    ├── retriever.py    # BM25 retrieval
    ├── llm.py          # GitHub Models API client
    └── rag.py          # Pipeline orchestrator
```

## Supported File Types

| Format | Extension | Library Used |
|---|---|---|
| PDF | `.pdf` | PyPDF2 |
| Word | `.docx` | python-docx |
| Excel | `.xlsx`, `.xls` | openpyxl |
