# LangChain V1 — Complete Theory Reference

## 1. What is LangChain? Why Orchestration Frameworks Exist
- LLMs are powerful but need to be composed with external data, memory, tools, and logic
- LangChain is a Python/JS framework that orchestrates LLMs into production-ready applications
- Core idea: chain multiple components (prompts -> model -> parser) into pipelines
- Why use LangChain: standardized interfaces, integrations, debugging tools (LangSmith), deployment (LangServe)
- Version history: v0.1 (chains/agents), v0.2 (LCEL focus), v0.3 (current)
- Without orchestration: manually wire API calls, parse responses, manage errors, handle state
- LangChain provides: composable primitives, 600+ integrations, streaming, async, observability
- Production needs: retry logic, fallbacks, caching, rate limiting — LangChain handles all of these

## 2. LangChain Expression Language (LCEL)
- LCEL uses the | pipe operator to compose Runnable objects
- Every component is a Runnable: Prompt, Model, Parser, Retriever
- The pipe operator creates a RunnableSequence
- Supports: invoke, stream, batch, astream, astream_log
- Benefits: streaming support, async support, parallel execution, type safety
- RunnableParallel: run multiple chains in parallel and merge outputs
- RunnablePassthrough: pass input through unchanged (used in RAG pipelines)
- RunnableLambda: wrap any Python function as a Runnable
- LCEL is lazy: chains are defined first, then executed when invoke/stream/batch is called
- Type checking: LCEL chains validate input/output types at definition time
- Composability: any Runnable can be swapped for another with the same interface
- astream_log: streams both final output and intermediate steps for debugging

## 3. Core Components
- ChatModels: interface with LLM providers (OpenAI, Anthropic, Groq, Ollama)
- Prompts: templates for structuring model inputs with variable substitution
- OutputParsers: transform raw model output into structured Python formats
- Retrievers: fetch relevant documents from vector stores based on semantic similarity
- Tools: functions the LLM can call to interact with external systems
- Memory: stores and retrieves conversation history across multiple turns
- Callbacks: hooks for logging, monitoring, and streaming during chain execution
- Chains: sequences of components connected with LCEL pipe operator

## 4. ChatModels — Unified Interface
- ChatOpenAI: temperature, model, api_key, streaming, max_tokens, organization
- ChatAnthropic: claude-3-opus, claude-3-sonnet, claude-haiku — different speed/cost tradeoffs
- ChatGroq: llama3-70b, mixtral-8x7b, gemma — ultra-fast inference via Groq hardware
- ChatOllama: local models (llama3, mistral, phi3) via Ollama server — no API costs
- All implement: invoke(), stream(), batch(), bind_tools(), with_structured_output()
- model.invoke(messages) returns AIMessage with content, additional_kwargs
- Configuring models: temperature=0 for deterministic, temperature=1 for creative outputs
- Model selection: consider latency, cost, context window, capability for your use case
- Fallbacks: .with_fallbacks([backup_model]) — switch to backup if primary fails
- Retries: .with_retry(stop_after_attempt=3, wait_exponential_jitter=True)
- Caching: use LangChain's CacheBackedEmbeddings or SQLiteCache to avoid repeat API calls

## 5. Prompt Templates
- PromptTemplate: single string template with {variables} — for non-chat models
- ChatPromptTemplate: list of (role, template) tuples — preferred for chat models
- SystemMessage: sets assistant persona, constraints, and behavior for entire conversation
- HumanMessage: user's input in the conversation turn
- AIMessage: previous assistant responses (used for multi-turn conversation history)
- MessagesPlaceholder: inserts a variable-length list of messages at a specific position
- from_messages() classmethod: create ChatPromptTemplate from list of (role, template) tuples
- Template variables filled with .format_messages(**kwargs) or automatically via LCEL
- partial(): pre-fill some variables, keep others dynamic — useful for format_instructions
- Prompt validation: LangChain checks that all required variables are provided at invocation
- Reusable prompts: define once, use in multiple chains with different LLMs

## 6. Output Parsers
- StrOutputParser: converts AIMessage to plain string — most common choice
- JsonOutputParser: parses JSON from model output, returns Python dict
- PydanticOutputParser: validates output against Pydantic model schema — type-safe
- CommaSeparatedListOutputParser: splits comma-separated output into Python list
- get_format_instructions(): returns instructions to append to prompt for format guidance
- Parsers are Runnables — use in LCEL chains with | operator
- Error handling: parsers raise OutputParserException on malformed output
- Retry with fix: OutputFixingParser wraps another parser and retries on parse failure
- Chain integration: prompt.partial(format_instructions=parser.get_format_instructions())

## 7. Chains with LCEL
- Basic chain: prompt | model | parser
- Adding format instructions: prompt.partial(format_instructions=parser.get_format_instructions())
- RunnableParallel example: run sentiment + summary chains simultaneously, merge results
- RunnablePassthrough: pass original input alongside retrieved docs in RAG chains
- Nested chains: chain1 | chain2 | chain3 — output of each feeds to next
- itemgetter: extract specific keys from dict inputs using operator.itemgetter
- Named chains: .with_config(run_name="MyChain") for LangSmith tracing visibility
- Input/Output mapping: use dict-style RunnableParallel to reshape data between steps
- Conditional chains: use RunnableLambda to add if/else branching logic
- Debugging: set LANGCHAIN_VERBOSE=true environment variable to see all steps

## 8. Memory and Conversation History
- ConversationBufferMemory: stores all messages verbatim — grows without limit
- ConversationBufferWindowMemory: keeps last K messages — prevents context overflow
- ConversationSummaryMemory: uses LLM to summarize old messages — saves tokens
- ConversationSummaryBufferMemory: hybrid — buffer recent, summarize older messages
- ChatMessageHistory: simple list-based in-memory message store (InMemoryChatMessageHistory)
- RunnableWithMessageHistory: wraps any chain with persistent conversation history
- Session IDs: string identifier to separate different user conversations
- Memory vs History: memory is LangChain abstraction, ChatMessageHistory is storage backend
- External storage: Redis, DynamoDB, MongoDB backends for production persistence
- Memory injection: MessagesPlaceholder(variable_name="history") in ChatPromptTemplate

## 9. Message Types
- BaseMessage: base class for all message types in LangChain
- HumanMessage: from the user — represents user's turn in conversation
- AIMessage: from the model — has additional_kwargs for tool_calls metadata
- SystemMessage: instructions and persona for the model — processed before conversation
- FunctionMessage / ToolMessage: results from tool execution — passed back to model
- ChatPromptTemplate uses these to build structured multi-turn conversations
- Message conversion: most chat model APIs use role-based format (system/user/assistant)
- History management: append HumanMessage and AIMessage alternately for context

## 10. Runnable Interface
- invoke(input): synchronous single call — returns final output
- stream(input): returns iterator of chunks for real-time streaming display
- batch(inputs): parallel processing of multiple inputs — returns list of outputs
- ainvoke(input): async single call — use with await in async functions
- astream(input): async streaming iterator — use with async for in async functions
- astream_log(): streams intermediate steps too — useful for complex chain debugging
- Configuring at runtime: .with_config(run_name="MyChain", tags=["prod"])
- Retries: .with_retry(stop_after_attempt=3, retry_on_exception=RateLimitError)
- Fallbacks: .with_fallbacks([backup_model]) — try backup if primary raises exception
- Binding: .bind(stop=["\nHuman:"]) — fix parameters for all invocations
- max_concurrency: batch() accepts max_concurrency to limit parallel calls

## 11. LangChain Hub
- hub.pull("hwchase17/openai-tools-agent"): pull community prompts by name
- Prompts are versioned with commit hashes for reproducibility
- Use langchain hub package: from langchain import hub
- Benefit: reuse battle-tested prompts without writing from scratch
- hub.push(): share your own prompts with the community (requires LANGCHAIN_API_KEY)
- Pinning versions: hub.pull("owner/prompt:commit-hash") for stable production builds
- Popular prompts: hwchase17/react, hwchase17/openai-tools-agent, langchain-ai/sql-agent-system-prompt
- Inspect pulled prompts: print the prompt object to see messages and variables

## 12. Structured Output
- model.with_structured_output(Schema): forces model to return structured data
- Works with Pydantic models (recommended) or TypedDict
- Uses function calling / tool calling API under the hood — no manual parsing
- Eliminates need for manual JSON parsing or prompt-based format instructions
- Supports strict mode for OpenAI models: .with_structured_output(Schema, strict=True)
- Returns validated Python objects directly — access fields as attributes
- Nested schemas: Pydantic models can contain other Pydantic models as fields
- Optional fields: use Optional[str] = None for fields that may not always be present
- Field descriptions: Field(description="...") helps model understand what to populate

## 13. Tool Calling
- @tool decorator: convert Python function into LangChain Tool automatically
- Tool name, description, and args_schema auto-generated from docstring and type hints
- model.bind_tools(tools): attach tools to model for function/tool calling API
- Model returns AIMessage with tool_calls attribute when it decides to use a tool
- ToolNode: executes tool calls from AIMessage (used in LangGraph agent workflows)
- Manual tool execution: tool.invoke(tool_call["args"]) for custom handling
- Tool schemas: define with Pydantic BaseModel for complex argument structures
- Return types: tools should return strings — convert other types explicitly
- Error handling in tools: wrap with try/except and return error message string
- Tool descriptions are critical: model selects tools based on name and description quality

## 14. Callbacks
- BaseCallbackHandler: override methods (on_llm_start, on_llm_end, on_chain_start, etc.)
- StreamingStdOutCallbackHandler: prints streaming tokens to stdout automatically
- callbacks=[handler]: pass list of handlers to model, chain, or agent executor
- LangSmith: cloud tracing and monitoring platform — set LANGCHAIN_TRACING_V2=true
- set_verbose(True): enable chain-level debug logging to see all inputs/outputs
- on_tool_start, on_tool_end: trace tool usage and execution time
- Async callbacks: implement async versions for high-throughput async applications
- Multiple callbacks: pass list of handlers to combine streaming + logging + tracing
- Custom callbacks: subclass BaseCallbackHandler to build custom monitoring solutions

## 15. LangChain Ecosystem
- LangChain Core: base abstractions and LCEL (langchain-core) — minimal dependencies
- LangChain Community: third-party integrations (langchain-community) — document loaders, tools
- LangChain OpenAI: OpenAI-specific package (langchain-openai) — optimized integration
- LangGraph: stateful multi-agent workflows using graph-based state machines
- LangServe: deploy chains as REST APIs with FastAPI — includes playground UI
- LangSmith: observability, testing, evaluation, and prompt management platform
- Integration packages: langchain-anthropic, langchain-groq, langchain-ollama
- Package versioning: core, openai, community have independent version numbers
- Installation: pip install langchain langchain-openai langchain-community
- Dependencies: keep core minimal, install integrations only as needed
- Migration: v0.1 -> v0.2 moved from legacy chains to LCEL; v0.3 adds stricter typing
---

## 16. LangChain Ecosystem and Integrations

LangChain integrates with 50+ LLM providers and 100+ tools/services.

### LLM Provider Integrations

| Provider | Package | Class |
|---|---|---|
| OpenAI | langchain-openai | ChatOpenAI |
| Anthropic | langchain-anthropic | ChatAnthropic |
| Google | langchain-google-genai | ChatGoogleGenerativeAI |
| Groq | langchain-groq | ChatGroq |
| Ollama (local) | langchain-ollama | ChatOllama |
| Mistral | langchain-mistralai | ChatMistralAI |
| Cohere | langchain-cohere | ChatCohere |

### Vector Store Integrations
- **Chroma** — lightweight local vector DB
- **FAISS** — Facebook AI Similarity Search, in-memory
- **Pinecone** — managed cloud vector DB
- **Weaviate** — open-source vector DB with GraphQL
- **Qdrant** — high-performance Rust-based vector DB
- **pgvector** — PostgreSQL extension for vectors

### Key LangChain Packages (v0.3+)

    langchain-core        # Base abstractions (Runnable, etc.)
    langchain             # Main chain/agent logic
    langchain-community   # Community integrations
    langchain-openai      # OpenAI-specific classes
    langchain-anthropic   # Anthropic-specific classes
    langsmith             # Tracing and evaluation
    langgraph             # Graph-based agents
    langserve             # Serve chains as REST APIs

### LCEL Runnable Interface Summary

Every LCEL component implements the Runnable interface:
- invoke(input) — single synchronous call
- ainvoke(input) — single async call
- stream(input) — sync streaming (yields chunks)
- astream(input) — async streaming
- batch(inputs) — parallel list of calls
- abatch(inputs) — async parallel calls
- get_input_schema() — returns input JSON schema
- get_output_schema() — returns output JSON schema

### RunnablePassthrough and RunnableParallel

    from langchain_core.runnables import RunnablePassthrough, RunnableParallel

    chain = RunnableParallel({
        'original': RunnablePassthrough(),
        'translated': prompt | model | parser
    })

### Error Handling and Retry

    chain_with_retry = chain.with_retry(stop_after_attempt=3)
    chain_with_fallback = primary_chain.with_fallbacks([backup_chain])

---

## 17. Production Best Practices

### Rate Limiting
Use exponential backoff with the 	enacity library for robust retries.
Configure RateLimiter in ChatOpenAI for request throttling.

### Token Usage Tracking
Use get_openai_callback() context manager to track token consumption and cost.
Log token counts per chain invocation for budget monitoring.

### Caching Responses
InMemoryCache — fast, ephemeral, ideal for development.
SQLiteCache — persistent, good for repeated identical queries.
RedisCache — distributed, production-ready for multi-process apps.

### Async at Scale
Use ainvoke() / abatch() for high-throughput API servers.
Pair with asyncio.gather() to run multiple chains concurrently.
FastAPI + async LangChain = efficient production serving.

---

## 18. Debugging and Testing LangChain Apps

### LangSmith Tracing
Set LANGCHAIN_TRACING_V2=true and LANGCHAIN_API_KEY to auto-trace all runs.
Every chain invocation appears in the LangSmith UI with full input/output.

### Verbose Mode
Set verbose=True on any chain or agent for console debugging.

### Unit Testing Chains
Use FakeListLLM or MockChatModel for deterministic test responses.
Test each component independently before integrating.

---

## 19. LangChain vs Alternatives

| Framework | Strengths | Weaknesses |
|---|---|---|
| LangChain | Huge ecosystem, LCEL flexibility | Complexity, frequent API changes |
| LlamaIndex | Better RAG, document focus | Smaller ecosystem |
| Haystack | Production pipelines, serializable | Steeper learning curve |
| DSPy | Prompt optimization, programmatic | Different paradigm |
| CrewAI | Multi-agent teams | Less flexible than LangGraph |

