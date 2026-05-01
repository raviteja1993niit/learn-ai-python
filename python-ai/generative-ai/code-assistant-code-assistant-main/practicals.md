# Code Assistant, AI Search, Chatbot — Practical Projects (10 Projects)

```bash
pip install openai pydantic streamlit tavily-python duckduckgo-search gitpython rasa
```

---

## Project 1 — GitHub Code Reviewer
**Goal**: Automatically review pull request diffs using GPT-4o.
**Features**: clone repo, get diff, structured review (bugs/security/style), markdown report, GitHub comment posting
**Key concepts**: gitpython, diff parsing, structured outputs, GitHub API
**Hint**:
```python
import subprocess
diff = subprocess.run(["git","diff","main...HEAD","--","*.py"],
    capture_output=True, text=True).stdout
review = review_code(diff)  # use structured Review pydantic model
```
**Extension**: Add as a GitHub Action that runs on every pull request.

---

## Project 2 — Intelligent Code Search
**Goal**: Search a codebase semantically (not just text match).
**Features**: index all .py files as embeddings, semantic search, show relevant code snippets, navigate to definitions
**Key concepts**: text embeddings, cosine similarity, file indexing, chunking
**Architecture**:
```
.py files → chunk functions → embed → JSON index
User query → embed → cosine search → top-5 relevant functions
```
**Hint**: Split Python files by function using `ast` module; embed each function body separately

---

## Project 3 — Smart AI Search Engine (Web App)
**Goal**: ChatGPT-like web search with cited sources.
**Features**: search-augmented answers, source citations, follow-up questions, search history
**Stack**: Streamlit + Tavily + GPT-4o
**Key concepts**: Tavily API, retrieval-augmented generation, Streamlit
**Hint**:
```python
import streamlit as st
query = st.text_input("Search")
if query:
    results = tavily.search(query=query, max_results=5)
    answer = grounded_answer(query)["answer"]
    st.write(answer)
    for r in results["results"]:
        st.caption(f"Source: {r['url']}")
```

---

## Project 4 — Domain-specific Support Chatbot
**Goal**: Build a chatbot for a specific domain (e-commerce, healthcare, banking).
**Features**: custom persona, FAQ knowledge base, escalation logic, conversation logging
**Key concepts**: system prompt design, guardrails, memory, intent detection
**Hint**: Load FAQ from CSV/JSON into vector store; retrieve relevant answers; use them as context in system prompt
**Extension**: Add Rasa for intent classification to handle structured commands (check balance, place order)

---

## Project 5 — Automated Documentation Generator
**Goal**: Scan a Python project and auto-generate documentation.
**Features**: docstrings for all functions, README.md generation, API reference, architecture diagram description
**Key concepts**: ast module, file traversal, batch LLM calls, markdown
**Hint**:
```python
import ast, os
def get_functions(py_file):
    with open(py_file) as f:
        tree = ast.parse(f.read())
    return [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]
# For each function: extract source with inspect, generate docstring with LLM
```

---

## Project 6 — Interactive Coding Tutor
**Goal**: Personalised coding tutor that teaches through examples and exercises.
**Features**: concept explanation, interactive exercises, hint system, progress tracking
**Key concepts**: multi-turn conversation, structured lesson plans, Socratic method
**Hint**: System prompt = Socratic teacher; never give full answer immediately; ask "what do you think?" first
**Extension**: Adaptive difficulty based on user's error rate.

---

## Project 7 — Code Security Auditor
**Goal**: Scan Python files for security vulnerabilities.
**Vulnerabilities to detect**: SQL injection, XSS, hardcoded credentials, SSRF, path traversal, weak crypto
**Features**: severity rating, CWE classification, fix suggestions, HTML report
**Key concepts**: structured output, security prompt engineering
**Hint**: System prompt must list OWASP top 10 and common Python security issues; use Pydantic for structured findings
**Extension**: Compare results with Bandit (static analysis tool) for validation.

---

## Project 8 — Multi-language Code Converter
**Goal**: Convert code between programming languages while preserving semantics.
**Supported pairs**: Python↔JavaScript, Python↔Go, Python↔Java, Python↔TypeScript
**Features**: side-by-side display, explanation of idiom differences, test equivalence checking
**Key concepts**: language-specific prompting, code comparison
**Hint**: "Translate to idiomatic {target_language}. Explain top 3 language-specific differences in comments."

---

## Project 9 — Rasa Domain Chatbot
**Goal**: Build a full Rasa chatbot for a specific domain.
**Requirements**: 5+ intents, 2+ entities, 2 custom actions, 3+ conversation flows, API integration
**Architecture**: Rasa NLU → policies → custom actions → backend API → user
**Hint**:
```bash
rasa init my_chatbot
# Edit: data/nlu.yml (intents), domain.yml (responses), actions/actions.py
rasa train && rasa shell
```
**Extension**: Add Duckling for entity extraction (dates, amounts, emails).

---

## Project 10 — Full-stack LLM App (Backend + Frontend)
**Goal**: Build a complete production-ready LLM application.
**Architecture**: FastAPI backend + React/Streamlit frontend + SQLite conversation storage
**Features**: user authentication, conversation history, model selector, streaming responses, export to PDF
**Backend hints**:
```python
from fastapi import FastAPI
app = FastAPI()
@app.post("/chat")
async def chat(request: ChatRequest):
    # authenticate, load history from DB, call LLM, save to DB, return
    pass
```
**Frontend hints**: Use Streamlit for simplicity; or React with EventSource for streaming
**Extension**: Add analytics dashboard showing usage statistics by user and model.