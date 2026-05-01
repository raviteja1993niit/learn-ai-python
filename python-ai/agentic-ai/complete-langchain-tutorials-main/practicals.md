# Complete LangChain Tutorials — Practical Projects

## Project 1: Complete PDF Chatbot
**Goal:** Upload a PDF and chat with its contents using conversational RAG.
**Steps:**
1. Load PDF with PyPDFLoader
2. Split with RecursiveCharacterTextSplitter (chunk_size=1000, overlap=200)
3. Embed with OpenAIEmbeddings, store in Chroma with persist_directory
4. Build conversational RAG chain using create_history_aware_retriever
5. Build interactive CLI loop: user types questions, bot answers from PDF context
**Key concepts:** RAG pipeline, conversational history, vector stores
**Hints:**
- Add "I don't know" fallback when answer is not found in context
- Display retrieved source page numbers alongside each answer
- Allow PDF path as a command-line argument for flexibility
**Extension:** Support loading multiple PDFs simultaneously into the same vector store

---

## Project 2: SQL Natural Language Interface
**Goal:** Query any SQLite database using plain English questions.
**Steps:**
1. Connect SQLDatabase to a sample SQLite database (use chinook.db from SQLite samples)
2. Use create_sql_agent with agent_type="openai-tools" for reliable tool calling
3. Build interactive CLI loop for asking natural language questions
4. Log all generated SQL queries and their results to a log file
**Key concepts:** SQL agents, SQLDatabase, create_sql_agent
**Hints:**
- Use verbose=True to see the SQL reasoning and query generation steps
- Test with: "Show top 5 customers by total purchase amount"
- Add input validation to block potentially harmful SQL (DROP, DELETE, UPDATE)
**Extension:** Connect to PostgreSQL, add a "explain this result" feature

---

## Project 3: Web Scraping + Q&A
**Goal:** Scrape a website and answer questions about its content using RAG.
**Steps:**
1. Use WebBaseLoader to scrape 3-5 related URLs (e.g., documentation pages)
2. Split and embed scraped content into Chroma vector store
3. Build RAG question-answering chain
4. Accept URL list from user input at runtime
**Key concepts:** WebBaseLoader, BeautifulSoup filtering, RAG pipeline
**Hints:**
- Handle rate limiting: add time.sleep(1) between requests to avoid blocking
- Filter HTML noise with BeautifulSoup class selectors to get clean content
- Add URL validation before attempting to scrape
**Extension:** Schedule automatic re-scraping hourly to keep knowledge base fresh

---

## Project 4: Multi-Document RAG System
**Goal:** Build a RAG system over a folder of mixed documents (PDF, TXT, DOCX).
**Steps:**
1. Use DirectoryLoader to load all docs from a specified folder
2. Map file extensions to appropriate loaders (PDF, TXT, DOCX)
3. Split, embed, and store all document chunks in Chroma
4. Tag each chunk with source filename and document type in metadata
5. Show source files cited in each response
**Key concepts:** DirectoryLoader, metadata filtering, multi-format loading
**Hints:**
- Use glob="**/*.pdf" to target specific file types within DirectoryLoader
- Deduplicate chunks based on content hash before inserting to vector store
- Rebuild vector store only when source files have changed (check modification times)
**Extension:** Add document management UI: add/remove individual files from the index

---

## Project 5: Wikipedia Research Agent
**Goal:** Agent that researches a topic using Wikipedia and synthesizes a report.
**Steps:**
1. Create agent with WikipediaQueryRun as primary research tool
2. Add DuckDuckGoSearchResults for current information not on Wikipedia
3. Prompt agent to research from multiple angles: history, applications, criticism
4. Format final output as structured report (Introduction, Findings, Conclusion)
**Key concepts:** AgentExecutor, WikipediaQueryRun, DuckDuckGoSearchResults
**Hints:**
- Set max_iterations=10 for thorough multi-step research
- Ask agent to cite specific Wikipedia article titles in the report
- Save the final report to a markdown file with the topic name as filename
**Extension:** Add fact-checking step: verify key claims across multiple sources

---

## Project 6: CSV Data Analyst Agent
**Goal:** Natural language analysis of CSV data using Python code execution.
**Steps:**
1. Load a CSV file with pandas and display column names and sample rows
2. Use PythonREPLTool to enable the agent to write and run pandas analysis code
3. Build agent that answers questions like "What is the average sales by region?"
4. Generate summary statistics and visualizations on user request
**Key concepts:** PythonREPLTool, pandas integration, AgentExecutor
**Hints:**
- Pre-load the CSV into a pandas DataFrame in the tool execution context
- Sanitize and review generated code before execution in production
- Capture matplotlib plot outputs and save to image files automatically
**Extension:** Support multiple CSV files; add automatic data quality checks and suggestions

---

## Project 7: Company Knowledge Base Chatbot
**Goal:** Internal Q&A bot for company documents (policies, FAQs, onboarding guides).
**Steps:**
1. Create sample company documents: policy.txt, faq.txt, employee_handbook.txt
2. Load, split, embed into persistent Chroma vector store
3. Build RAG chain with professional, helpful persona in system message
4. Add metadata filtering by document type for targeted retrieval
**Key concepts:** Persistent vector store, metadata filtering, professional persona
**Hints:**
- Add document categories as metadata during loading (type: "policy", "faq", etc.)
- Filter retrieval by category when the query clearly relates to one type
- Log all unanswered questions to identify content gaps in the knowledge base
**Extension:** Add document update notifications when source files change on disk

---

## Project 8: Code Documentation Search
**Goal:** Search and Q&A over a codebase using embeddings and RAG.
**Steps:**
1. Use DirectoryLoader with glob="**/*.py" to load Python source files
2. Use MarkdownHeaderTextSplitter for .md documentation files
3. Embed all code and docs and store in FAISS for fast retrieval
4. Build Q&A chain: "How do I use the X function?" or "What does Y class do?"
**Key concepts:** DirectoryLoader, FAISS, code search, MarkdownHeaderTextSplitter
**Hints:**
- Include file path and function names in document metadata for source attribution
- Use MMR (max marginal relevance) retrieval for diverse code examples in results
- Support queries like "find code similar to this snippet" by embedding the snippet
**Extension:** Auto-generate docstrings for Python functions that are missing them

---

## Project 9: Multi-Tool Research Agent
**Goal:** Full research agent combining web search, Wikipedia, calculator, and custom tools.
**Steps:**
1. Combine DuckDuckGoSearchResults, WikipediaQueryRun, and a calculator tool
2. Create a custom report-formatting tool that structures research output
3. Build agent with clear, specific tool descriptions (critical for correct selection)
4. Test on 5 complex multi-step research questions requiring multiple tool uses
**Key concepts:** Multi-tool agents, create_openai_tools_agent, tool descriptions
**Hints:**
- Write detailed tool descriptions — they directly determine when the agent uses each tool
- Handle tool failures gracefully: wrap all tool code in try/except blocks
- Use return_intermediate_steps=True in AgentExecutor to audit the full reasoning chain
**Extension:** Add a PDF reader tool that can extract text from files during research

---

## Project 10: LangServe REST API Deployment
**Goal:** Package a RAG chain as a production-ready REST API with FastAPI and LangServe.
**Steps:**
1. Build a complete RAG chain (load docs, create vector store, build retrieval chain)
2. Wrap with FastAPI app using LangServe add_routes()
3. Expose /rag/invoke and /rag/stream endpoints automatically
4. Test with curl commands and the auto-generated playground UI at /rag/playground
**Setup (server.py):**
```python
from fastapi import FastAPI
from langserve import add_routes
# ... import and build your rag_chain
app = FastAPI(title="RAG API")
add_routes(app, rag_chain, path="/rag")
# Run: uvicorn server:app --reload --port 8000
```
**Key concepts:** LangServe, FastAPI, add_routes, RemoteRunnable client
**Hints:**
- Add CORS middleware for frontend JavaScript access from different origins
- Add API key authentication using FastAPI's Header dependency injection
- Test with RemoteRunnable("http://localhost:8000/rag") as a local chain in a client script
**Extension:** Deploy to Railway or Render with Docker; add rate limiting middleware