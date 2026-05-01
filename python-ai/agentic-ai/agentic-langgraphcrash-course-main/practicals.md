# LangGraph Practicals — Hands-On Projects

## Overview

These 10 projects progress from beginner to advanced. Each includes:
- **Goal**: what you will build
- **Key concepts**: LangGraph features practiced
- **Setup**: dependencies and environment
- **Step-by-step guide**: how to implement it
- **Hints & extensions**: ways to go deeper

Work through them in order — each project builds on knowledge from the previous ones.

---

## Project 1: Simple Chatbot Graph

### Goal
Build a stateful chatbot that remembers conversation history within a session,
responds to any user message, and runs in a terminal REPL loop.

### Key Concepts
- `StateGraph`, `MessagesState`
- `add_messages` reducer
- `MemorySaver` for in-session memory
- `thread_id` for conversation isolation

### Setup
```bash
pip install langgraph langchain-openai python-dotenv
```
Create a `.env` file with `OPENAI_API_KEY=your-key`.

### Steps
1. Define a `MessagesState`-based graph with a single `chat` node
2. Compile with `MemorySaver` checkpointer
3. Assign a fixed `thread_id` (e.g., `"chat-session-1"`)
4. Write a `while True` loop: read user input, call `graph.invoke`, print last AI message
5. Add a `SystemMessage` in the node to give the bot a personality

### Hints
- Use `graph.get_state(config).values["messages"]` to inspect full history
- Try multiple `thread_id` values to run parallel conversations
- Add a `/clear` command that changes `thread_id` to start fresh

---

## Project 2: Tool-Calling Research Agent

### Goal
Build a ReAct agent that can search the web, read Wikipedia, and perform
calculations to answer complex research questions.

### Key Concepts
- `ToolNode` and `tools_condition`
- `bind_tools` on ChatOpenAI
- Multi-step tool calling loops
- Custom tool definitions with `@tool`

### Setup
```bash
pip install langgraph langchain-openai langchain-community wikipedia duckduckgo-search
```

### Steps
1. Define tools: `web_search`, `wikipedia_lookup`, `calculator`
2. Create an LLM with `llm.bind_tools(tools)`
3. Build the ReAct graph: `agent → tools → agent` loop
4. Add conditional edge using `tools_condition`
5. Test with a multi-hop question like "Who invented the technology behind ChatGPT and what year?"

### Hints
- Add a `max_iterations` counter to the state to prevent infinite loops
- Log each tool call to see the agent's reasoning chain
- Try replacing tools with LangChain's built-in `TavilySearchResults` tool
- Add `interrupt_before=["tools"]` to preview tool calls before execution

---

## Project 3: Human-in-the-Loop Approval Agent

### Goal
Build an agent that proposes actions (like sending emails or executing commands)
and pauses for human approval before executing each one.

### Key Concepts
- `interrupt_before` compilation option
- `graph.get_state()` to inspect pending action
- `graph.update_state()` to inject human decision
- `Command.RESUME` to continue execution

### Setup
```bash
pip install langgraph langchain-openai
```

### Steps
1. Define state: `proposed_action`, `approved`, `result`, `messages`
2. Create `plan_action` node: LLM proposes what to do next
3. Create `execute_action` node: runs the approved action
4. Compile with `interrupt_before=["execute_action"]`
5. In your main loop: invoke → show pending action → ask user → update state → resume
6. Handle both approval and rejection paths

### Hints
- Use `snapshot.next` to confirm the graph is paused where expected
- Allow the human to edit the proposed action before approving
- Add a `rejection_count` field — if rejected 3 times, escalate to a different strategy
- Store approval decisions in a log for auditing

---

## Project 4: Persistent Conversation with SQLite Checkpointing

### Goal
Build a chatbot whose memory persists across Python process restarts — start a
conversation today, come back tomorrow, and it remembers everything.

### Key Concepts
- `SqliteSaver` checkpointer
- `thread_id` as a persistent user identifier
- `graph.get_state_history()` for conversation replay
- State snapshots and `checkpoint_id`

### Setup
```bash
pip install langgraph langchain-openai aiosqlite
```

### Steps
1. Build a `MessagesState` chatbot graph (same as Project 1)
2. Replace `MemorySaver` with `SqliteSaver.from_conn_string("memory.db")`
3. Use a stable `thread_id` (e.g., the user's name or UUID)
4. Test persistence: run once, exit, run again — history should be intact
5. Add a `/history` command that prints all past messages using `get_state`

### Hints
- Use `uuid` module to generate stable user IDs stored in a local config file
- Add `graph.get_state_history(config)` to build a "memory timeline" feature
- Try `graph.update_state(config, {"messages": []})` to selectively clear history
- Use the SQLite file with DB Browser to inspect the checkpoint schema

---

## Project 5: Plan-and-Execute Task Agent

### Goal
Build an agent that breaks down a complex goal into steps, executes them one at a
time, and synthesizes results into a final report.

### Key Concepts
- Multi-node planning pipeline
- State with `plan: List[str]` and `current_step: int`
- Conditional edge for loop control
- Result accumulation with list reducers

### Setup
```bash
pip install langgraph langchain-openai
```

### Steps
1. Define `PlanState`: `objective`, `plan`, `current_step`, `results`, `final_answer`
2. `planner` node: LLM creates a list of steps from the objective
3. `executor` node: LLM executes the current step using prior results as context
4. `synthesizer` node: LLM combines all results into a coherent answer
5. Conditional edge after `executor`: loop back if more steps remain, else go to `synthesizer`
6. Test with: "Research and summarize the pros and cons of 3 Python web frameworks"

### Hints
- Add a `replanner` node that reviews the plan after each step and can add/remove steps
- Implement parallel execution for independent steps using fan-out edges
- Add a `max_steps` guard to prevent the planner from creating excessively long plans
- Log the plan to the console right after the planner runs for transparency

---

## Project 6: Code Review Agent with Reflection

### Goal
Build an agent that reviews code, generates improvement suggestions, applies them,
and iterates until the code meets a quality standard.

### Key Concepts
- Generator + Critic reflection loop
- Iteration count tracking
- Quality threshold routing
- Passing structured feedback between nodes

### Setup
```bash
pip install langgraph langchain-openai
```

### Steps
1. Define state: `code`, `language`, `review`, `revised_code`, `iteration`, `max_iterations`, `quality_score`
2. `reviewer` node: LLM analyzes code for bugs, style, performance — returns a score (1-10) and comments
3. `improver` node: LLM applies the review feedback to produce revised code
4. Conditional edge: if `quality_score >= 8` or `iteration >= max_iterations`, go to `END`; else loop back
5. Parse the quality score from the reviewer's output using regex or structured output
6. Test with intentionally buggy Python code

### Hints
- Use `ChatOpenAI` with `response_format={"type": "json_object"}` for structured review output
- Display a progress bar using the `iteration` count
- Store all revisions in a list to show the improvement history
- Add a `security_check` node that runs after quality is approved

---

## Project 7: Customer Support Agent with Escalation

### Goal
Build a tiered support agent: first handle with FAQ lookup, then escalate to a
specialist, then create a ticket if still unresolved.

### Key Concepts
- Multi-tier routing with conditional edges
- Agent memory across the escalation chain
- Tool calling for ticket creation and knowledge base search
- `interrupt_before` for human escalation

### Setup
```bash
pip install langgraph langchain-openai
```

### Steps
1. Define state: `messages`, `tier`, `ticket_id`, `resolved`
2. `tier1_agent` node: handles common questions using FAQ tool
3. `tier2_agent` node: specialist handling — more detailed, can create tickets
4. `human_escalation` node: interrupted for a real human to respond
5. Route: FAQ resolved → END; complex issue → tier2; very complex → human
6. Add `create_ticket` tool that generates a ticket ID

### Hints
- Add a `sentiment_score` to the state — negative sentiment triggers faster escalation
- Use `MemorySaver` so customers can continue conversations across multiple messages
- Log all escalations to a file for analysis
- Add a `satisfaction_survey` node at the very end before `END`

---

## Project 8: Multi-Agent Supervisor System

### Goal
Build a supervisor that coordinates 3 specialized agents — Researcher, Writer, and
Fact-Checker — to produce a high-quality article on any topic.

### Key Concepts
- Supervisor node with routing logic
- Specialist agent nodes (can be subgraphs)
- Shared `MessagesState` for agent communication
- Termination condition in supervisor

### Setup
```bash
pip install langgraph langchain-openai
```

### Steps
1. Define `MessagesState` as the shared state
2. Build three specialist nodes: `researcher`, `writer`, `fact_checker`
3. Build a `supervisor` node that: reads last message, decides who goes next (or FINISH)
4. Conditional edge on supervisor output: researcher / writer / fact_checker / END
5. Each specialist routes back to supervisor after completing
6. Test: "Write a 3-paragraph article about the James Webb Space Telescope"

### Hints
- Give each specialist a strong `SystemMessage` with their role and output format
- Add a `draft` field to state for the writer's output (separate from messages)
- Use `structured output` on the supervisor LLM to get clean routing decisions
- Cap total turns with a counter to prevent infinite loops between agents

---

## Project 9: Document Processing Pipeline Graph

### Goal
Build a document processing pipeline that reads a text document, chunks it,
embeds it, and answers questions using RAG — all as a LangGraph workflow.

### Key Concepts
- Linear pipeline with data-transformation nodes
- State with list reducers for chunk accumulation
- Integration of LangChain loaders, splitters, and vector stores
- Retrieval node as part of the graph

### Setup
```bash
pip install langgraph langchain-openai langchain-community chromadb tiktoken
```

### Steps
1. Define state: `document_path`, `raw_text`, `chunks`, `vectorstore_id`, `query`, `answer`
2. `loader` node: read file content into `raw_text`
3. `chunker` node: split into chunks using `RecursiveCharacterTextSplitter`
4. `embedder` node: embed chunks into a Chroma vector store
5. `retriever` node: semantic search with the query against the vector store
6. `responder` node: LLM answers the query using retrieved chunks as context
7. Test: process a long PDF or text file, then ask questions about it

### Hints
- Add a `cache_check` node at the start — skip chunking/embedding if already done
- Use `interrupt_after=["chunker"]` to verify chunks before embedding
- Add metadata (source, page number) to each chunk during the chunker node
- Make `retriever` return top-K results and store them in a `context` state field

---

## Project 10: Agentic RAG with Retrieval Decisions

### Goal
Build a RAG agent that decides dynamically whether to retrieve information,
reformulate the query, answer directly, or escalate — rather than always retrieving.

### Key Concepts
- Router node for retrieval decision
- Query rewriting node
- Conditional retrieval (retrieve only when needed)
- Relevance grading of retrieved documents
- Answer validation before returning

### Setup
```bash
pip install langgraph langchain-openai langchain-community chromadb
```

### Steps
1. Define state: `messages`, `query`, `retrieved_docs`, `grade`, `answer`, `retrieval_count`
2. `query_analyzer` node: decides "retrieve", "answer_directly", or "clarify"
3. `retriever` node: fetches relevant documents from vector store
4. `relevance_grader` node: LLM scores each document (relevant/not relevant)
5. `query_rewriter` node: if docs not relevant, rewrite query and retry retrieval (max 2 retries)
6. `generator` node: produce answer from graded relevant documents
7. `answer_validator` node: check if answer is grounded in retrieved docs
8. Route from validator: if grounded → END; if hallucination → regenerate

### Routing Logic
```
query_analyzer
    ├─ "retrieve" → retriever → relevance_grader
    │       ├─ "relevant" → generator → validator → END
    │       └─ "not_relevant" (if retries < 2) → query_rewriter → retriever
    └─ "answer_directly" → generator → END
```

### Hints
- Use LangChain's `WebBaseLoader` to pre-populate the vector store with web articles
- Implement the relevance grader as a structured LLM call returning `{"score": "yes"/"no"}`
- Track `retrieval_count` in state to prevent infinite retry loops
- Add LangSmith tracing to observe which path each query takes
- Visualize the graph with LangGraph Studio to see the full routing diagram

---

## Quick Reference: Running Any Project

```bash
# 1. Create virtual environment
python -m venv venv
.\venv\Scripts\activate  # Windows
source venv/bin/activate  # macOS/Linux

# 2. Install dependencies
pip install langgraph langchain-openai python-dotenv

# 3. Create .env file
echo OPENAI_API_KEY=your-key-here > .env

# 4. Run your project
python project.py
```

## Recommended Learning Path

| Stage    | Projects  | Focus                              |
|----------|-----------|------------------------------------|
| Beginner | 1, 2      | Graphs, nodes, tools               |
| Intermediate | 3, 4, 5 | HITL, persistence, planning      |
| Advanced | 6, 7, 8   | Reflection, multi-agent, routing   |
| Expert   | 9, 10     | RAG pipelines, agentic retrieval   |