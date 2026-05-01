# Complete LangChain Tutorials — Theory Reference

## 1. SQL Chains — Natural Language to SQL
- SQLDatabase: wraps SQLAlchemy connection, introspects table schemas automatically
- create_sql_query_chain: generates SQL from natural language without executing it
- create_sql_agent: full agent that generates, executes, and interprets SQL results
- QuerySQLDataBaseTool: tool for executing SQL queries against the database
- Process: NL question -> SQL query -> DB execution -> result interpretation -> final answer
- Supported databases: SQLite, PostgreSQL, MySQL, MSSQL, Oracle via SQLAlchemy
- Schema injection: model sees table names, column definitions, and sample rows
- Prompt includes: dialect, table schemas, question, few-shot SQL examples
- Safety: SQL agent should be restricted to read-only operations in production
- Debugging: verbose=True shows each reasoning step and SQL generated

## 2. Document Loaders
- Base class: BaseLoader with .load() returning List[Document]
- Document object: page_content (str) + metadata (dict) — core abstraction
- PyPDFLoader: loads PDFs page by page, metadata includes page number and source
- TextLoader: plain text files — set encoding='utf-8' to avoid encoding errors
- CSVLoader: each row becomes a Document with column names as metadata keys
- UnstructuredWordDocumentLoader: .docx Word files via unstructured library
- WebBaseLoader: scrapes HTML pages using requests + BeautifulSoup
- DirectoryLoader: loads all files matching a glob pattern from a folder recursively
- JSONLoader: loads JSON with jq-style path extraction for nested structures
- YoutubeLoader: transcript extraction from YouTube URLs via youtube-transcript-api
- GitLoader: load source code files from local or remote git repositories
- Metadata preservation: loaders capture source path, page number, row index, URL
- load_and_split(): convenience method that loads and splits in one call

## 3. Text Splitters
- Why split: LLMs have context windows; embeddings work better on focused chunks
- RecursiveCharacterTextSplitter: splits by paragraphs -> sentences -> words -> chars (recommended)
- CharacterTextSplitter: splits on a single separator character (e.g., newline)
- TokenTextSplitter: splits by token count using tiktoken — model-aware splitting
- MarkdownHeaderTextSplitter: splits by # headings, preserves hierarchical structure
- chunk_size: maximum chunk size in characters or tokens
- chunk_overlap: overlap between consecutive chunks to preserve context at boundaries
- add_start_index: adds character offset metadata to each chunk for source tracking
- split_documents(): process a List[Document], preserving metadata from originals
- Best practice: chunk_overlap should be 10-20% of chunk_size for good context flow
- Sentence splitting: use spaCy or NLTK for more linguistically accurate splits
- Chunk size trade-offs: smaller = more precise retrieval, larger = more context per chunk

## 4. Embeddings
- Embeddings: convert text -> dense float vector capturing semantic meaning
- OpenAIEmbeddings: text-embedding-ada-002, text-embedding-3-small, text-embedding-3-large
- HuggingFaceEmbeddings: local models (sentence-transformers/all-MiniLM-L6-v2) — free
- OllamaEmbeddings: local embedding models via Ollama server — no API costs
- CohereEmbeddings: Cohere embed-english-v3.0 with compression support
- embed_documents(texts): batch embed list of strings — use for indexing
- embed_query(text): embed single query — may use different model optimized for queries
- Dimensions: ada-002=1536, text-embedding-3-small=1536, MiniLM=384, large=3072
- Cosine similarity: measures semantic closeness between embedding vectors
- Normalization: normalize embeddings to unit length for consistent similarity scores
- Caching: CacheBackedEmbeddings wraps any embedder with disk/Redis caching

## 5. Vector Stores
- Chroma: local, lightweight, no server needed, SQLite-backed — great for development
- FAISS: Facebook AI Similarity Search — extremely fast in-memory retrieval
- Pinecone: managed cloud vector database — production-scale with managed infrastructure
- Weaviate, Qdrant, Milvus: other production-grade vector stores with advanced features
- from_documents(): create store from List[Document] + embedding model
- from_texts(): create from List[str] + embedding model — simpler interface
- add_documents(): add new documents to an existing vector store
- similarity_search(query, k=4): returns top-k most similar Documents
- similarity_search_with_score(): returns (Document, float_score) tuples
- Max Marginal Relevance (MMR): balances relevance with diversity in results
- as_retriever(): converts vector store to Retriever interface for use in chains
- persist() / save_local(): save Chroma or FAISS store to disk for reuse
- delete(): remove documents by ID from the vector store

## 6. Retrievers
- VectorStoreRetriever: wraps vector store, implements get_relevant_documents() interface
- search_type: "similarity" (default), "mmr", "similarity_score_threshold"
- search_kwargs: dict with k, fetch_k, lambda_mult, score_threshold parameters
- MultiQueryRetriever: generates multiple query variations using LLM, merges unique results
- ContextualCompressionRetriever: re-ranks and compresses retrieved docs to relevant portions
- EnsembleRetriever: combines BM25 keyword search + vector semantic search (hybrid)
- ParentDocumentRetriever: retrieve small chunks but return their larger parent documents
- SelfQueryRetriever: parses structured metadata filters from natural language queries
- Retriever interface: invoke(query) -> List[Document] — consistent across all types
- MultiQueryRetriever benefit: overcomes embedding limitations by diversifying query phrasing
- Score threshold: filter out low-relevance documents before passing to LLM

## 7. RAG (Retrieval-Augmented Generation)
- RAG pipeline: Load -> Split -> Embed -> Store -> Retrieve -> Generate
- Why RAG: add private/current knowledge to LLMs without expensive fine-tuning
- Step 1 — Load: use document loaders to get raw Documents from files/web/APIs
- Step 2 — Split: chunk with RecursiveCharacterTextSplitter for optimal retrieval
- Step 3 — Embed: convert chunks to vectors with embedding model of choice
- Step 4 — Store: save vectors to Chroma/FAISS with from_documents()
- Step 5 — Retrieve: given query, find top-k relevant chunks using similarity search
- Step 6 — Generate: pass context + query to LLM, get grounded answer
- RAG prompt template: "Answer based on context: {context}\nQuestion: {question}"
- RunnablePassthrough: pass original question through while context branch retrieves docs
- format_docs(): join List[Document] into single context string for LLM prompt
- Context stuffing: "stuff" all retrieved docs into prompt — simplest strategy
- Map-reduce: process each doc separately, then combine — handles more docs

## 8. Conversational RAG
- Challenge: RAG needs to handle follow-up questions that reference previous exchanges
- Problem: "Tell me more about that" doesn't work as standalone retrieval query
- Solution: rephrase follow-up using chat history to create standalone question first
- create_history_aware_retriever: takes chat history + question -> standalone question -> docs
- create_stuff_documents_chain: combines context + question -> final answer from LLM
- create_retrieval_chain: combines history-aware retriever + document QA chain
- Chat history stored in ChatMessageHistory (in-memory or persistent backend)
- RunnableWithMessageHistory: wraps any chain to add automatic history management
- Session management: different session_ids get completely separate conversation histories
- History injection: MessagesPlaceholder(variable_name="chat_history") in prompt template
- Output key: create_retrieval_chain returns dict with "answer" and "context" keys

## 9. LangChain Agents
- Agent: LLM that reasons about which tools to use and in what order to solve a task
- ReAct pattern: Reason -> Act -> Observe -> Reason -> Act -> ... -> Final Answer
- create_react_agent(llm, tools, prompt): builds a ReAct agent from components
- AgentExecutor: runs the agent loop with tool execution and error handling
- max_iterations: prevent infinite loops — set to 5-10 for most tasks
- handle_parsing_errors: gracefully handle malformed tool call format from LLM
- verbose=True: see each Thought/Action/Observation step in agent's reasoning
- return_intermediate_steps=True: get all reasoning steps alongside final answer
- early_stopping_method: "force" generates answer immediately, "generate" prompts model
- Agent loop: model decides action, executor runs tool, observation fed back to model

## 10. Agent Tools
- DuckDuckGoSearchResults: real-time web search with no API key required
- WikipediaQueryRun: search Wikipedia, returns article summaries
- PythonREPLTool: execute Python code in a REPL — powerful but dangerous, use carefully
- RequestsGetTool: make HTTP GET requests to external APIs
- ShellTool: run shell commands — restrict permissions in production environments
- @tool decorator: create custom tools from Python functions with docstring descriptions
- Tool schema: name, description (critical!), args_schema (Pydantic model)
- Tool description quality directly impacts how often and correctly agent uses it
- Return type convention: tools should always return strings for agent compatibility
- Error returns: return error message string instead of raising exceptions in tools

## 11. Multi-Tool Agents
- Bind multiple tools to the agent with model.bind_tools([tool1, tool2, tool3])
- Agent selects appropriate tool based on tool names and description matching
- Tool descriptions must be clear, specific, and non-overlapping between tools
- Handle tool errors: wrap tool body in try/except, return descriptive error strings
- Chain tool results: agent naturally uses output of one tool as input to another
- OpenAI Tools agent: uses function calling API — more reliable than ReAct text parsing
- create_openai_tools_agent: preferred for OpenAI models — structured tool calls
- ToolNode (LangGraph): executes parallel tool calls from a single AIMessage
- Tool namespacing: prefix tool names with domain ("search_", "db_") for clarity

## 12. LangServe — Deploy as REST API
- LangServe: deploy any LangChain chain as a FastAPI REST API with one function call
- from langserve import add_routes: register chain with FastAPI app instance
- Routes auto-created: POST /chain/invoke, /chain/stream, /chain/batch, /chain/stream_log
- Playground: auto-generated interactive UI at /chain/playground for testing
- RemoteRunnable: Python client to call LangServe endpoints as if they were local chains
- Authentication: add FastAPI middleware or dependencies for API key validation
- Deployment: Uvicorn server, Docker containerization, cloud platforms (Railway, Fly.io)
- Input/Output schemas: auto-generated OpenAPI docs from chain type annotations
- CORS: add CORSMiddleware for frontend JavaScript access from different origins
- Health check: GET /chain/config returns chain configuration for monitoring
---

## 13. Advanced Retrieval Patterns

### Ensemble Retriever (Hybrid Search)
Combines BM25 keyword search with dense vector search for better recall.

    from langchain.retrievers import EnsembleRetriever
    from langchain_community.retrievers import BM25Retriever

    bm25 = BM25Retriever.from_documents(docs)
    vector = vectorstore.as_retriever()
    ensemble = EnsembleRetriever(
        retrievers=[bm25, vector],
        weights=[0.4, 0.6]
    )

### Self-Query Retriever
Automatically parses natural language filter conditions from the query.
Example: 'Show me Python docs from 2024' triggers a metadata filter year=2024.

### Parent Document Retriever
Stores small child chunks in the vector store for precise retrieval.
Returns the larger parent document for full context in generation.

### Time-Weighted Retriever
Scores documents by both semantic similarity and recency.
Useful for news, support tickets, and time-sensitive information.

---

## 14. LangGraph Integration with LangChain

LangGraph extends LangChain with stateful, graph-based agent workflows.

### StateGraph Basics
    from langgraph.graph import StateGraph, END
    from typing import TypedDict

    class AgentState(TypedDict):
        messages: list
        documents: list

    graph = StateGraph(AgentState)
    graph.add_node('retrieve', retrieve_docs)
    graph.add_node('generate', generate_answer)
    graph.set_entry_point('retrieve')
    graph.add_edge('retrieve', 'generate')
    graph.add_edge('generate', END)
    app = graph.compile()

---

## 15. LangChain v0.3 Migration Notes

### Deprecated → New API Mapping

| Old API | New API |
|---|---|
| LLMChain | LCEL: prompt | llm | parser |
| RetrievalQA | LCEL RAG chain |
| ConversationalRetrievalChain | create_history_aware_retriever |
| AgentType.ZERO_SHOT_REACT | create_react_agent |
| load_qa_chain | Custom LCEL chain |

### New install_packages (v0.3)
    pip install langchain==0.3.x
    pip install langchain-openai langchain-anthropic
    pip install langchain-community langchain-core

---

## 16. Token Management and Cost Control

### Counting Tokens Before Calling
Use tiktoken to estimate token cost before making expensive API calls.

    import tiktoken
    enc = tiktoken.encoding_for_model('gpt-4o')
    tokens = len(enc.encode(text))

### Tracking Spend with Callbacks
    from langchain_community.callbacks import get_openai_callback
    with get_openai_callback() as cb:
        result = chain.invoke({'question': 'What is RAG?'})
        print(f'Tokens: {cb.total_tokens}, Cost: {cb.total_cost:.4f}')

### Reducing Token Usage
- Use chunk_size=512 instead of 2048 for retrieval context
- Summarize retrieved docs before passing to LLM
- Use cheaper models (gpt-4o-mini) for simpler tasks
- Cache repeated identical queries with SQLiteCache

