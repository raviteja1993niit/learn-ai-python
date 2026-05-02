# LangGraph — Comprehensive Guide for Software Developers

> **Auth pattern used throughout this guide (GitHub Copilot free tier):**
> ```python
> import subprocess
> from openai import OpenAI
> token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
> client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)
> ```

---

## Table of Contents

1. [What is LangGraph?](#1-what-is-langgraph)
2. [Installation & Core Concepts](#2-installation--core-concepts)
3. [Your First Graph](#3-your-first-graph)
4. [Conditional Routing](#4-conditional-routing)
5. [Checkpointing & Persistence](#5-checkpointing--persistence)
6. [Human-in-the-Loop](#6-human-in-the-loop)
7. [Multi-Agent Patterns](#7-multi-agent-patterns)
8. [Streaming](#8-streaming)
9. [Tool Calling Nodes](#9-tool-calling-nodes)
10. [Subgraphs](#10-subgraphs)
11. [State Management](#11-state-management)
12. [Error Handling & Retries](#12-error-handling--retries)
13. [LangGraph + LangSmith](#13-langgraph--langsmith)
14. [Production Patterns](#14-production-patterns)
15. [Interview Q&A](#15-interview-qa)
16. [Complete End-to-End Example — Self-RAG Agent](#16-complete-end-to-end-example--self-rag-agent)

---

## 1. What is LangGraph?

LangGraph is a **graph-based stateful agent framework** built on top of LangChain. It models AI workflows as directed graphs where:

- **Nodes** = Python functions (LLM calls, tool invocations, business logic)
- **Edges** = transitions between nodes (fixed or conditional)
- **State** = a typed dictionary that flows through the graph and is mutated at each node

### Key Advantages Over Plain LangChain Chains

| Feature | LangChain (LCEL) | LangGraph |
|---|---|---|
| Cycles / loops | ❌ No | ✅ Yes |
| Persistent state | ❌ Manual | ✅ Built-in checkpointing |
| Human-in-the-loop | ❌ Awkward | ✅ First-class `interrupt_before/after` |
| Branching logic | Limited | ✅ `add_conditional_edges` |
| Multi-agent orchestration | ❌ No | ✅ Supervisor / Swarm patterns |
| Streaming mid-graph | Limited | ✅ `stream_mode` options |

### When to Use What

| Scenario | Best Tool |
|---|---|
| Simple sequential LLM pipeline | LangChain LCEL |
| Stateful agent with loops + memory | **LangGraph** |
| Multi-agent with roles and tasks | **LangGraph** or CrewAI |
| Fully autonomous collaborative agents | CrewAI / AutoGen |
| Enterprise .NET / Java environments | AutoGen (multi-lang) |

**Rule of thumb:** If your agent needs to *loop*, *pause for human review*, or *remember state across turns*, use LangGraph.

---

## 2. Installation & Core Concepts

```bash
pip install langgraph langgraph-checkpoint-sqlite langchain-openai langchain-core
```

### Core Building Blocks

```python
from typing import TypedDict, Annotated
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

# ── 1. STATE ──────────────────────────────────────────────────
# A TypedDict that holds all data flowing through the graph.
# Every node receives the full state and returns a partial update.

class MyState(TypedDict):
    input: str
    result: str
    steps: Annotated[list[str], operator.add]   # reducer: auto-appends

# ── 2. NODES ──────────────────────────────────────────────────
# Plain Python functions: (state) -> dict  (partial state update)

def my_node(state: MyState) -> dict:
    return {"result": state["input"].upper(), "steps": ["my_node ran"]}

# ── 3. GRAPH BUILDER ──────────────────────────────────────────
builder = StateGraph(MyState)
builder.add_node("my_node", my_node)

# ── 4. EDGES ──────────────────────────────────────────────────
# Direct edge: always go from A → B
builder.add_edge(START, "my_node")
builder.add_edge("my_node", END)

# Conditional edge (covered in section 4)
# builder.add_conditional_edges("node_a", routing_fn, {"yes": "node_b", "no": "node_c"})

# ── 5. COMPILE ────────────────────────────────────────────────
# Optionally pass a checkpointer for persistence
graph = builder.compile()

# ── 6. INVOKE ─────────────────────────────────────────────────
result = graph.invoke({"input": "hello", "steps": []})
print(result)  # {'input': 'hello', 'result': 'HELLO', 'steps': ['my_node ran']}
```

---

## 3. Your First Graph

A simple 3-node pipeline: **input_node → process_node → output_node**

```python
import subprocess
from openai import OpenAI
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

# Auth
token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

# ── State ─────────────────────────────────────────────────────
class PipelineState(TypedDict):
    raw_input: str
    cleaned_input: str
    llm_response: str
    final_output: str

# ── Nodes ─────────────────────────────────────────────────────
def input_node(state: PipelineState) -> dict:
    """Normalize the raw input."""
    cleaned = state["raw_input"].strip().lower()
    print(f"[input_node] cleaned: {cleaned!r}")
    return {"cleaned_input": cleaned}

def process_node(state: PipelineState) -> dict:
    """Send to LLM."""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "You are a helpful assistant. Answer concisely."},
            {"role": "user", "content": state["cleaned_input"]},
        ],
        max_tokens=200,
    )
    answer = response.choices[0].message.content
    print(f"[process_node] LLM response: {answer[:80]}...")
    return {"llm_response": answer}

def output_node(state: PipelineState) -> dict:
    """Format the final output."""
    final = f"=== ANSWER ===\n{state['llm_response']}\n=============="
    print(f"[output_node] formatted output ready")
    return {"final_output": final}

# ── Build Graph ───────────────────────────────────────────────
builder = StateGraph(PipelineState)
builder.add_node("input_node", input_node)
builder.add_node("process_node", process_node)
builder.add_node("output_node", output_node)

builder.add_edge(START, "input_node")
builder.add_edge("input_node", "process_node")
builder.add_edge("process_node", "output_node")
builder.add_edge("output_node", END)

graph = builder.compile()

# ── Run ───────────────────────────────────────────────────────
result = graph.invoke({
    "raw_input": "  What is LangGraph?  ",
    "cleaned_input": "",
    "llm_response": "",
    "final_output": "",
})
print(result["final_output"])
```

---

## 4. Conditional Routing

`add_conditional_edges()` lets a node branch to different next nodes based on a routing function.

```python
import subprocess
from openai import OpenAI
from typing import TypedDict, Literal
from langgraph.graph import StateGraph, START, END

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

# ── State ─────────────────────────────────────────────────────
class RAGState(TypedDict):
    question: str
    document: str
    grade: str          # "relevant" | "not_relevant"
    answer: str
    web_results: str

# ── Nodes ─────────────────────────────────────────────────────
def retrieve_node(state: RAGState) -> dict:
    # Simulate retrieval
    fake_doc = "LangGraph is a stateful agent framework built on LangChain."
    print(f"[retrieve] fetched document")
    return {"document": fake_doc}

def grade_node(state: RAGState) -> dict:
    """Ask LLM to grade document relevance."""
    prompt = f"""Does this document answer the question?
Question: {state['question']}
Document: {state['document']}
Reply with exactly one word: relevant or not_relevant"""
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=10,
    )
    grade = resp.choices[0].message.content.strip().lower()
    grade = "relevant" if "relevant" in grade and "not" not in grade else "not_relevant"
    print(f"[grade] document is: {grade}")
    return {"grade": grade}

def answer_node(state: RAGState) -> dict:
    """Generate answer from retrieved document."""
    prompt = f"Answer using this document:\n{state['document']}\n\nQuestion: {state['question']}"
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200,
    )
    return {"answer": resp.choices[0].message.content}

def web_search_node(state: RAGState) -> dict:
    """Fallback: simulate web search."""
    print(f"[web_search] document was irrelevant, searching web...")
    web_result = f"Web result: LangGraph enables stateful multi-agent workflows."
    return {"web_results": web_result, "answer": f"Based on web search: {web_result}"}

# ── Routing Function ──────────────────────────────────────────
def route_after_grading(state: RAGState) -> Literal["answer_node", "web_search_node"]:
    """Return the name of the next node."""
    if state["grade"] == "relevant":
        return "answer_node"
    return "web_search_node"

# ── Build Graph ───────────────────────────────────────────────
builder = StateGraph(RAGState)
builder.add_node("retrieve_node", retrieve_node)
builder.add_node("grade_node", grade_node)
builder.add_node("answer_node", answer_node)
builder.add_node("web_search_node", web_search_node)

builder.add_edge(START, "retrieve_node")
builder.add_edge("retrieve_node", "grade_node")

# Conditional: grade_node → route_after_grading() → answer_node OR web_search_node
builder.add_conditional_edges(
    "grade_node",
    route_after_grading,
    {
        "answer_node": "answer_node",
        "web_search_node": "web_search_node",
    },
)
builder.add_edge("answer_node", END)
builder.add_edge("web_search_node", END)

graph = builder.compile()

result = graph.invoke({
    "question": "What is LangGraph?",
    "document": "", "grade": "", "answer": "", "web_results": "",
})
print("ANSWER:", result["answer"])
```

---

## 5. Checkpointing & Persistence

Checkpointers save graph state after every node so you can resume after crashes, support long-running jobs, and isolate sessions with `thread_id`.

### MemorySaver (in-memory, lost on restart)

```python
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated
import operator

class CountState(TypedDict):
    count: int
    messages: Annotated[list[str], operator.add]

def increment(state: CountState) -> dict:
    new_count = state["count"] + 1
    print(f"[increment] count = {new_count}")
    return {"count": new_count, "messages": [f"incremented to {new_count}"]}

builder = StateGraph(CountState)
builder.add_node("increment", increment)
builder.add_edge(START, "increment")
builder.add_edge("increment", END)

memory = MemorySaver()
graph = builder.compile(checkpointer=memory)

# thread_id isolates different sessions
config_a = {"configurable": {"thread_id": "session-001"}}
config_b = {"configurable": {"thread_id": "session-002"}}

# Session A: run 3 times — state accumulates
graph.invoke({"count": 0, "messages": []}, config=config_a)
graph.invoke({"count": 0, "messages": []}, config=config_a)  # count: 2
result_a = graph.invoke({"count": 0, "messages": []}, config=config_a)
print("Session A count:", result_a["count"])   # 3
print("Session A messages:", result_a["messages"])  # 3 entries

# Session B: independent
result_b = graph.invoke({"count": 0, "messages": []}, config=config_b)
print("Session B count:", result_b["count"])   # 1
```

### SqliteSaver (persistent across process restarts)

```python
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph import StateGraph, START, END
from typing import TypedDict
import sqlite3

class JobState(TypedDict):
    job_id: str
    status: str
    result: str

def process_job(state: JobState) -> dict:
    print(f"[process_job] Processing {state['job_id']}")
    return {"status": "completed", "result": f"Done processing {state['job_id']}"}

builder = StateGraph(JobState)
builder.add_node("process_job", process_job)
builder.add_edge(START, "process_job")
builder.add_edge("process_job", END)

# Uses a local SQLite file — survives restarts
DB_PATH = "graph_checkpoints.db"
conn = sqlite3.connect(DB_PATH, check_same_thread=False)
saver = SqliteSaver(conn)
graph = builder.compile(checkpointer=saver)

config = {"configurable": {"thread_id": "job-abc-123"}}
result = graph.invoke({"job_id": "abc-123", "status": "pending", "result": ""}, config=config)
print(result)

# To resume / inspect state after a crash:
checkpoint = graph.get_state(config)
print("Saved state:", checkpoint.values)

# To get full history:
for snapshot in graph.get_state_history(config):
    print(f"  step={snapshot.metadata.get('step')}, values={snapshot.values}")

conn.close()
```

### Simulating Crash and Resume

```python
import sqlite3
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class WorkflowState(TypedDict):
    stage: str
    data: str

CRASH_SIMULATION = False  # set True to simulate crash

def stage_one(state: WorkflowState) -> dict:
    print("[stage_one] running")
    return {"stage": "after_one", "data": "stage1_data"}

def stage_two(state: WorkflowState) -> dict:
    if CRASH_SIMULATION:
        raise RuntimeError("Simulated crash in stage_two!")
    print("[stage_two] running")
    return {"stage": "complete", "data": state["data"] + "+stage2_data"}

builder = StateGraph(WorkflowState)
builder.add_node("stage_one", stage_one)
builder.add_node("stage_two", stage_two)
builder.add_edge(START, "stage_one")
builder.add_edge("stage_one", "stage_two")
builder.add_edge("stage_two", END)

conn = sqlite3.connect(":memory:", check_same_thread=False)
graph = builder.compile(checkpointer=SqliteSaver(conn))
config = {"configurable": {"thread_id": "resume-demo"}}

# First run (may crash at stage_two)
try:
    result = graph.invoke({"stage": "start", "data": ""}, config=config)
    print("Completed:", result)
except Exception as e:
    print(f"Crashed: {e}")
    # Fix the issue, then resume from last checkpoint:
    CRASH_SIMULATION = False
    saved = graph.get_state(config)
    print("Resuming from stage:", saved.values.get("stage"))
    result = graph.invoke(None, config=config)  # None = resume from checkpoint
    print("Resumed result:", result)
```

---

## 6. Human-in-the-Loop

LangGraph supports pausing execution to wait for human input.

### interrupt_before / interrupt_after

```python
import subprocess
from openai import OpenAI
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver
from langgraph.errors import NodeInterrupt

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class CodeReviewState(TypedDict):
    task: str
    generated_code: str
    human_feedback: str
    final_code: str
    approved: bool

def write_code(state: CodeReviewState) -> dict:
    """AI generates code."""
    prompt = f"Write a Python function for: {state['task']}\nReturn only the code, no explanation."
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=300,
    )
    code = resp.choices[0].message.content
    print(f"[write_code] Generated:\n{code}")
    return {"generated_code": code}

def human_review(state: CodeReviewState) -> dict:
    """
    This node raises NodeInterrupt — graph pauses here.
    The caller (human) reads the state, decides, then resumes.
    """
    raise NodeInterrupt(
        f"Human review required!\n\nGenerated code:\n{state['generated_code']}\n\n"
        "Call graph.update_state() with {'human_feedback': '...', 'approved': True/False}"
    )

def revise_or_finalize(state: CodeReviewState) -> dict:
    """Incorporate feedback or finalize."""
    if state.get("approved"):
        print("[revise_or_finalize] Approved! Finalizing.")
        return {"final_code": state["generated_code"]}
    # Revise based on feedback
    prompt = (
        f"Original code:\n{state['generated_code']}\n\n"
        f"Human feedback: {state['human_feedback']}\n\n"
        "Revise the code to address the feedback. Return only code."
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=300,
    )
    revised = resp.choices[0].message.content
    print(f"[revise_or_finalize] Revised code ready")
    return {"final_code": revised}

# ── Build ─────────────────────────────────────────────────────
builder = StateGraph(CodeReviewState)
builder.add_node("write_code", write_code)
builder.add_node("human_review", human_review)
builder.add_node("revise_or_finalize", revise_or_finalize)

builder.add_edge(START, "write_code")
builder.add_edge("write_code", "human_review")
builder.add_edge("human_review", "revise_or_finalize")
builder.add_edge("revise_or_finalize", END)

memory = MemorySaver()
graph = builder.compile(checkpointer=memory, interrupt_before=["human_review"])
config = {"configurable": {"thread_id": "code-review-001"}}

# ── Step 1: Run until interrupt ───────────────────────────────
initial_state = {
    "task": "sort a list of dictionaries by a given key",
    "generated_code": "",
    "human_feedback": "",
    "final_code": "",
    "approved": False,
}
for event in graph.stream(initial_state, config=config):
    print("Event:", list(event.keys()))

print("\n--- GRAPH PAUSED — waiting for human review ---")
current = graph.get_state(config)
print("Current node:", current.next)

# ── Step 2: Human reviews and updates state ───────────────────
graph.update_state(
    config,
    {"human_feedback": "Add type hints and a docstring", "approved": False},
)

# ── Step 3: Resume ────────────────────────────────────────────
print("\n--- RESUMING GRAPH ---")
final = graph.invoke(None, config=config)
print("\nFinal Code:\n", final["final_code"])
```

### Using interrupt_after

```python
# interrupt_after pauses AFTER the named node completes.
# Useful when you want to see the output before deciding to continue.
graph_after = builder.compile(
    checkpointer=MemorySaver(),
    interrupt_after=["write_code"],  # pause after write_code, before human_review
)
```

---

## 7. Multi-Agent Patterns

### Supervisor Pattern

One orchestrator node decides which specialist agent to invoke next.

```python
import subprocess
from openai import OpenAI
from typing import TypedDict, Literal, Annotated
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

AGENTS = ["researcher", "writer", "reviewer"]

class SupervisorState(TypedDict):
    task: str
    research: str
    draft: str
    review: str
    final_article: str
    next_agent: str
    iteration: int
    log: Annotated[list[str], operator.add]

def _llm(prompt: str, max_tokens: int = 400) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=max_tokens,
    )
    return resp.choices[0].message.content.strip()

# ── Supervisor ────────────────────────────────────────────────
def supervisor(state: SupervisorState) -> dict:
    """Decide which agent to call next."""
    context = (
        f"Task: {state['task']}\n"
        f"Research done: {'Yes' if state['research'] else 'No'}\n"
        f"Draft done: {'Yes' if state['draft'] else 'No'}\n"
        f"Review done: {'Yes' if state['review'] else 'No'}\n"
        f"Iteration: {state['iteration']}\n\n"
        "Choose the next agent: researcher, writer, reviewer, or FINISH.\n"
        "Reply with exactly one word."
    )
    decision = _llm(context, max_tokens=10).lower()
    if "finish" in decision or state["iteration"] >= 3:
        decision = "FINISH"
    print(f"[supervisor] → {decision}")
    return {"next_agent": decision, "log": [f"supervisor decided: {decision}"]}

def researcher(state: SupervisorState) -> dict:
    research = _llm(f"Research this topic thoroughly: {state['task']}")
    print(f"[researcher] done")
    return {"research": research, "iteration": state["iteration"] + 1, "log": ["researcher completed"]}

def writer(state: SupervisorState) -> dict:
    draft = _llm(f"Write an article about: {state['task']}\n\nResearch notes:\n{state['research']}")
    print(f"[writer] done")
    return {"draft": draft, "log": ["writer completed"]}

def reviewer(state: SupervisorState) -> dict:
    review = _llm(
        f"Review this article and give concise improvement suggestions:\n{state['draft']}"
    )
    # Auto-apply review for demo
    final = _llm(f"Improve this article based on review:\nArticle:\n{state['draft']}\nReview:\n{review}")
    print(f"[reviewer] done")
    return {"review": review, "final_article": final, "log": ["reviewer completed"]}

# ── Routing ───────────────────────────────────────────────────
def route_supervisor(state: SupervisorState) -> str:
    next_a = state.get("next_agent", "")
    if next_a == "FINISH" or "finish" in next_a:
        return END
    return next_a if next_a in AGENTS else END

# ── Build ─────────────────────────────────────────────────────
builder = StateGraph(SupervisorState)
builder.add_node("supervisor", supervisor)
builder.add_node("researcher", researcher)
builder.add_node("writer", writer)
builder.add_node("reviewer", reviewer)

builder.add_edge(START, "supervisor")
builder.add_conditional_edges("supervisor", route_supervisor, {
    "researcher": "researcher",
    "writer": "writer",
    "reviewer": "reviewer",
    END: END,
})
# All agents report back to supervisor
for agent in AGENTS:
    builder.add_edge(agent, "supervisor")

graph = builder.compile(checkpointer=MemorySaver())
config = {"configurable": {"thread_id": "supervisor-demo"}}

result = graph.invoke({
    "task": "The impact of LangGraph on AI agent development",
    "research": "", "draft": "", "review": "", "final_article": "",
    "next_agent": "", "iteration": 0, "log": [],
}, config=config)

print("\n=== FINAL ARTICLE (excerpt) ===")
print((result.get("final_article") or result.get("draft", ""))[:500])
print("\n=== LOG ===")
for entry in result["log"]:
    print(" -", entry)
```

### Swarm Pattern (agents hand off to each other)

```python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

class SwarmState(TypedDict):
    task: str
    current_agent: str
    output: str

# In the swarm pattern each agent decides the next agent itself
# (no central supervisor)
def agent_a(state: SwarmState) -> dict:
    print("[Agent A] handling task, handing off to Agent B")
    return {"current_agent": "agent_b", "output": state["output"] + " [A processed]"}

def agent_b(state: SwarmState) -> dict:
    print("[Agent B] finalizing")
    return {"current_agent": "done", "output": state["output"] + " [B finalized]"}

def route_swarm(state: SwarmState) -> str:
    return state["current_agent"] if state["current_agent"] != "done" else END

builder = StateGraph(SwarmState)
builder.add_node("agent_a", agent_a)
builder.add_node("agent_b", agent_b)
builder.add_edge(START, "agent_a")
builder.add_conditional_edges("agent_a", route_swarm, {"agent_b": "agent_b", END: END})
builder.add_edge("agent_b", END)

swarm = builder.compile()
print(swarm.invoke({"task": "analyze data", "current_agent": "agent_a", "output": ""}))
```

---

## 8. Streaming

### stream() modes

```python
import subprocess
from openai import OpenAI
from typing import TypedDict, Annotated
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class ChatState(TypedDict):
    messages: Annotated[list[dict], operator.add]
    response: str

def chat_node(state: ChatState) -> dict:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=state["messages"],
        max_tokens=300,
        stream=True,
    )
    full_response = ""
    print("[chat_node] streaming: ", end="", flush=True)
    for chunk in resp:
        delta = chunk.choices[0].delta.content or ""
        print(delta, end="", flush=True)
        full_response += delta
    print()  # newline
    return {
        "response": full_response,
        "messages": [{"role": "assistant", "content": full_response}],
    }

builder = StateGraph(ChatState)
builder.add_node("chat_node", chat_node)
builder.add_edge(START, "chat_node")
builder.add_edge("chat_node", END)

memory = MemorySaver()
graph = builder.compile(checkpointer=memory)
config = {"configurable": {"thread_id": "chat-stream-demo"}}

initial = {
    "messages": [{"role": "user", "content": "What are 3 benefits of LangGraph?"}],
    "response": "",
}

# ── stream_mode="values" → full state snapshot after each node ──
print("\n=== stream_mode='values' ===")
for state_snapshot in graph.stream(initial, config=config, stream_mode="values"):
    print(f"  keys: {list(state_snapshot.keys())}")

# ── stream_mode="updates" → only the changed keys from each node ──
print("\n=== stream_mode='updates' ===")
config2 = {"configurable": {"thread_id": "chat-stream-demo-2"}}
for node_name, updates in graph.stream(initial, config=config2, stream_mode="updates"):
    print(f"  node={node_name}, updated_keys={list(updates.keys())}")

# ── stream_mode="debug" → verbose internal events ──
print("\n=== stream_mode='debug' (first 3 events) ===")
config3 = {"configurable": {"thread_id": "chat-stream-demo-3"}}
events = list(graph.stream(initial, config=config3, stream_mode="debug"))
for evt in events[:3]:
    print(f"  type={evt.get('type')}, step={evt.get('step')}")
```

### Async Streaming

```python
import asyncio
import subprocess
from openai import AsyncOpenAI
from typing import TypedDict, Annotated
import operator
from langgraph.graph import StateGraph, START, END

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
async_client = AsyncOpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class AsyncChatState(TypedDict):
    question: str
    answer: str

async def async_llm_node(state: AsyncChatState) -> dict:
    resp = await async_client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": state["question"]}],
        max_tokens=200,
    )
    return {"answer": resp.choices[0].message.content}

builder = StateGraph(AsyncChatState)
builder.add_node("llm", async_llm_node)
builder.add_edge(START, "llm")
builder.add_edge("llm", END)
async_graph = builder.compile()

async def main():
    async for chunk in async_graph.astream(
        {"question": "What is astream in LangGraph?", "answer": ""},
        stream_mode="updates",
    ):
        node, updates = chunk
        print(f"[{node}] answer: {updates.get('answer', '')[:100]}")

asyncio.run(main())
```

---

## 9. Tool Calling Nodes

### create_react_agent() Shortcut

```python
import subprocess
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()

llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=gh_token,
)

# ── Define 3 custom tools ─────────────────────────────────────
@tool
def calculator(expression: str) -> str:
    """Evaluate a mathematical expression. Example: '2 + 2 * 10'"""
    try:
        result = eval(expression, {"__builtins__": {}})
        return str(result)
    except Exception as e:
        return f"Error: {e}"

@tool
def word_count(text: str) -> str:
    """Count the number of words in the given text."""
    count = len(text.split())
    return f"{count} words"

@tool
def reverse_string(text: str) -> str:
    """Reverse the characters in a string."""
    return text[::-1]

# ── Create ReAct agent in one line ───────────────────────────
memory = MemorySaver()
agent = create_react_agent(
    model=llm,
    tools=[calculator, word_count, reverse_string],
    checkpointer=memory,
)

config = {"configurable": {"thread_id": "react-demo"}}
result = agent.invoke(
    {"messages": [{"role": "user", "content": "What is 15 * 23 + 7? Also reverse the word 'LangGraph'."}]},
    config=config,
)
for msg in result["messages"]:
    print(f"[{msg.type}]: {msg.content[:200] if hasattr(msg, 'content') else msg}")
```

### Custom ToolNode

```python
import json
import subprocess
from openai import OpenAI
from typing import TypedDict, Annotated
import operator
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, ToolMessage
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import ToolNode
from langgraph.graph import StateGraph, START, END, MessagesState

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=gh_token,
)

@tool
def get_weather(city: str) -> str:
    """Get current weather for a city (simulated)."""
    fake_data = {"london": "15°C, cloudy", "tokyo": "22°C, sunny", "new york": "18°C, partly cloudy"}
    return fake_data.get(city.lower(), f"Weather data unavailable for {city}")

tools = [get_weather]
llm_with_tools = llm.bind_tools(tools)
tool_node = ToolNode(tools)

def call_llm(state: MessagesState) -> dict:
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: MessagesState) -> str:
    last = state["messages"][-1]
    if hasattr(last, "tool_calls") and last.tool_calls:
        return "tools"
    return END

builder = StateGraph(MessagesState)
builder.add_node("llm", call_llm)
builder.add_node("tools", tool_node)
builder.add_edge(START, "llm")
builder.add_conditional_edges("llm", should_continue, {"tools": "tools", END: END})
builder.add_edge("tools", "llm")

agent_graph = builder.compile()
result = agent_graph.invoke({
    "messages": [HumanMessage(content="What's the weather in London and Tokyo?")]
})
print(result["messages"][-1].content)
```

---

## 10. Subgraphs

Subgraphs let you encapsulate complex logic into reusable components.

```python
import subprocess
from openai import OpenAI
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

def _llm(prompt: str, max_tokens: int = 300) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=max_tokens,
    )
    return resp.choices[0].message.content.strip()

# ── SUBGRAPH: Code Review ─────────────────────────────────────
# The subgraph has its OWN state schema.
# Keys shared with parent must have the same name and type.

class CodeReviewSubState(TypedDict):
    code: str           # shared with parent (same name + type)
    review_comments: str
    quality_score: int

def syntax_check(state: CodeReviewSubState) -> dict:
    result = _llm(f"Check this code for syntax errors. Reply 'OK' or list errors:\n{state['code']}", 50)
    print(f"  [subgraph:syntax_check] {result[:60]}")
    return {"review_comments": f"Syntax: {result}"}

def quality_check(state: CodeReviewSubState) -> dict:
    result = _llm(
        f"Rate this code quality from 1-10 and explain briefly:\n{state['code']}", 100
    )
    # Extract score (naive)
    score = 7
    for word in result.split():
        if word.isdigit() and 1 <= int(word) <= 10:
            score = int(word)
            break
    print(f"  [subgraph:quality_check] score={score}")
    return {"quality_score": score, "review_comments": state["review_comments"] + f" | Quality: {result[:80]}"}

sub_builder = StateGraph(CodeReviewSubState)
sub_builder.add_node("syntax_check", syntax_check)
sub_builder.add_node("quality_check", quality_check)
sub_builder.add_edge(START, "syntax_check")
sub_builder.add_edge("syntax_check", "quality_check")
sub_builder.add_edge("quality_check", END)
code_review_subgraph = sub_builder.compile()

# ── PARENT GRAPH ──────────────────────────────────────────────
class ParentState(TypedDict):
    task: str
    code: str           # shared key — LangGraph maps this to subgraph
    review_comments: str
    quality_score: int
    deployment_decision: str

def generate_code(state: ParentState) -> dict:
    code = _llm(f"Write a simple Python function for: {state['task']}\nReturn only code.")
    print(f"[parent:generate_code] code generated")
    return {"code": code}

def decide_deployment(state: ParentState) -> dict:
    if state.get("quality_score", 0) >= 7:
        decision = "APPROVED — deploy to production"
    else:
        decision = f"REJECTED — quality score {state.get('quality_score')} < 7"
    print(f"[parent:decide_deployment] {decision}")
    return {"deployment_decision": decision}

parent_builder = StateGraph(ParentState)
parent_builder.add_node("generate_code", generate_code)
parent_builder.add_node("code_review", code_review_subgraph)  # subgraph as node
parent_builder.add_node("decide_deployment", decide_deployment)

parent_builder.add_edge(START, "generate_code")
parent_builder.add_edge("generate_code", "code_review")
parent_builder.add_edge("code_review", "decide_deployment")
parent_builder.add_edge("decide_deployment", END)

parent_graph = parent_builder.compile()

result = parent_graph.invoke({
    "task": "calculate fibonacci sequence up to n terms",
    "code": "", "review_comments": "", "quality_score": 0, "deployment_decision": "",
})
print("\n=== RESULTS ===")
print(f"Quality Score : {result['quality_score']}/10")
print(f"Review        : {result['review_comments'][:120]}")
print(f"Decision      : {result['deployment_decision']}")
```

---

## 11. State Management

### Reducers and Annotated State

```python
from typing import TypedDict, Annotated
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages  # built-in message reducer

# ── Custom reducer ────────────────────────────────────────────
def keep_latest(existing: str, new: str) -> str:
    """Custom reducer: always keep the latest non-empty value."""
    return new if new else existing

class AdvancedState(TypedDict):
    # operator.add: new items are APPENDED (never replaced)
    log: Annotated[list[str], operator.add]

    # add_messages: deduplicates by message ID, supports updates
    messages: Annotated[list, add_messages]

    # Custom reducer
    status: Annotated[str, keep_latest]

    # No annotation = LAST WRITE WINS (default)
    counter: int

def node_a(state: AdvancedState) -> dict:
    return {
        "log": ["node_a ran"],
        "status": "processing",
        "counter": state["counter"] + 1,
    }

def node_b(state: AdvancedState) -> dict:
    return {
        "log": ["node_b ran"],
        "status": "done",
        "counter": state["counter"] + 1,
    }

builder = StateGraph(AdvancedState)
builder.add_node("node_a", node_a)
builder.add_node("node_b", node_b)
builder.add_edge(START, "node_a")
builder.add_edge("node_a", "node_b")
builder.add_edge("node_b", END)

graph = builder.compile()
result = graph.invoke({"log": [], "messages": [], "status": "idle", "counter": 0})
print("log:", result["log"])        # ['node_a ran', 'node_b ran']  — appended
print("status:", result["status"])  # 'done'  — latest wins
print("counter:", result["counter"])  # 2

# ── MessagesState shortcut ────────────────────────────────────
from langgraph.graph import MessagesState
# MessagesState is pre-built with: messages: Annotated[list[BaseMessage], add_messages]
# Use it when building chat agents to avoid boilerplate.
```

### Shared vs Private State (Input/Output Schemas)

```python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

class PrivateState(TypedDict):
    """Full internal state — only visible inside the graph."""
    user_input: str
    internal_scratchpad: str  # private: not exposed to caller
    final_answer: str

class PublicInput(TypedDict):
    """What the caller provides."""
    user_input: str

class PublicOutput(TypedDict):
    """What the caller receives back."""
    final_answer: str

def process(state: PrivateState) -> dict:
    scratchpad = f"Thinking about: {state['user_input']}"
    answer = f"Answer to '{state['user_input']}'"
    return {"internal_scratchpad": scratchpad, "final_answer": answer}

builder = StateGraph(PrivateState, input=PublicInput, output=PublicOutput)
builder.add_node("process", process)
builder.add_edge(START, "process")
builder.add_edge("process", END)
graph = builder.compile()

# Caller only needs to provide PublicInput fields
result = graph.invoke({"user_input": "hello"})
print(result)  # {'final_answer': "Answer to 'hello'"} — internal_scratchpad hidden
```

---

## 12. Error Handling & Retries

```python
import subprocess
import time
from openai import OpenAI
from typing import TypedDict, Annotated
import operator
from langgraph.graph import StateGraph, START, END

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class RobustState(TypedDict):
    task: str
    result: str
    errors: Annotated[list[str], operator.add]
    retry_count: int
    status: str

MAX_RETRIES = 3
_call_count = 0  # simulate flaky service

def flaky_llm_node(state: RobustState) -> dict:
    """Simulates a node that sometimes fails."""
    global _call_count
    _call_count += 1

    try:
        # Simulate transient failure on first 2 calls
        if _call_count <= 2:
            raise ConnectionError(f"Simulated transient error (attempt {_call_count})")

        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": state["task"]}],
            max_tokens=100,
        )
        return {"result": resp.choices[0].message.content, "status": "success"}

    except ConnectionError as e:
        # Transient error — signal retry
        print(f"  [flaky_llm_node] transient error: {e}")
        return {
            "errors": [str(e)],
            "retry_count": state["retry_count"] + 1,
            "status": "retry",
        }
    except Exception as e:
        # Permanent error — go to dead-letter
        print(f"  [flaky_llm_node] permanent error: {e}")
        return {"errors": [str(e)], "status": "dead_letter"}

def retry_wait(state: RobustState) -> dict:
    """Exponential backoff before retry."""
    wait = 2 ** state["retry_count"]
    print(f"  [retry_wait] waiting {wait}s before retry #{state['retry_count']}")
    time.sleep(min(wait, 5))  # cap at 5s for demo
    return {}

def dead_letter_node(state: RobustState) -> dict:
    """Log permanently failed tasks."""
    print(f"  [dead_letter] task permanently failed after {state['retry_count']} retries")
    print(f"  [dead_letter] errors: {state['errors']}")
    return {"result": "FAILED", "status": "dead_letter"}

def fallback_node(state: RobustState) -> dict:
    """Return a safe default answer."""
    print(f"  [fallback] max retries exceeded — using fallback")
    return {"result": "Fallback response: unable to process task.", "status": "fallback"}

def route_after_llm(state: RobustState) -> str:
    if state["status"] == "success":
        return END
    if state["status"] == "dead_letter":
        return "dead_letter_node"
    if state["retry_count"] >= MAX_RETRIES:
        return "fallback_node"
    return "retry_wait"  # transient error — retry

builder = StateGraph(RobustState)
builder.add_node("flaky_llm_node", flaky_llm_node)
builder.add_node("retry_wait", retry_wait)
builder.add_node("dead_letter_node", dead_letter_node)
builder.add_node("fallback_node", fallback_node)

builder.add_edge(START, "flaky_llm_node")
builder.add_conditional_edges("flaky_llm_node", route_after_llm, {
    END: END,
    "dead_letter_node": "dead_letter_node",
    "fallback_node": "fallback_node",
    "retry_wait": "retry_wait",
})
builder.add_edge("retry_wait", "flaky_llm_node")  # loop back
builder.add_edge("dead_letter_node", END)
builder.add_edge("fallback_node", END)

graph = builder.compile()
result = graph.invoke({
    "task": "Explain retry patterns in 1 sentence.",
    "result": "", "errors": [], "retry_count": 0, "status": "pending",
})
print(f"\nFinal status : {result['status']}")
print(f"Result       : {result['result']}")
print(f"Errors seen  : {result['errors']}")
```

---

## 13. LangGraph + LangSmith

LangSmith provides automatic tracing, visualization, and debugging for LangGraph runs.

```python
import os
import subprocess
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
from langgraph.prebuilt import create_react_agent
from langchain_core.tools import tool

# ── Set LangSmith environment variables ───────────────────────
# Get a free API key at https://smith.langchain.com
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "your-langsmith-api-key"   # replace with real key
os.environ["LANGCHAIN_PROJECT"] = "langgraph-demo"

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=gh_token,
)

@tool
def add_numbers(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

agent = create_react_agent(model=llm, tools=[add_numbers])

# Every invoke is automatically traced in LangSmith
result = agent.invoke({"messages": [HumanMessage(content="What is 42 + 58?")]})
print(result["messages"][-1].content)
# → Go to https://smith.langchain.com to see the full trace

# ── Visualize graph structure ─────────────────────────────────
# Generate ASCII diagram in terminal:
print(agent.get_graph().draw_ascii())

# Generate Mermaid diagram (paste into https://mermaid.live):
print(agent.get_graph().draw_mermaid())

# Save as PNG (requires graphviz + pygraphviz):
# agent.get_graph().draw_png("my_agent.png")
```

---

## 14. Production Patterns

### FastAPI Wrapper

```python
# app.py — run with: uvicorn app:app --reload
import subprocess
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from openai import OpenAI
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=gh_token)

class AgentState(TypedDict):
    question: str
    answer: str

def answer_node(state: AgentState) -> dict:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": state["question"]}],
        max_tokens=300,
    )
    return {"answer": resp.choices[0].message.content}

builder = StateGraph(AgentState)
builder.add_node("answer", answer_node)
builder.add_edge(START, "answer")
builder.add_edge("answer", END)

memory = MemorySaver()
graph = builder.compile(checkpointer=memory)

app = FastAPI(title="LangGraph Agent API")

class QuestionRequest(BaseModel):
    question: str
    thread_id: Optional[str] = "default"

class AnswerResponse(BaseModel):
    answer: str
    thread_id: str

@app.post("/ask", response_model=AnswerResponse)
async def ask(req: QuestionRequest):
    config = {"configurable": {"thread_id": req.thread_id}}
    try:
        result = graph.invoke(
            {"question": req.question, "answer": ""},
            config=config,
        )
        return AnswerResponse(answer=result["answer"], thread_id=req.thread_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history/{thread_id}")
async def get_history(thread_id: str):
    config = {"configurable": {"thread_id": thread_id}}
    state = graph.get_state(config)
    return {"thread_id": thread_id, "values": state.values if state else {}}

@app.get("/health")
async def health():
    return {"status": "ok"}

# To run: uvicorn app:app --reload
# Test: curl -X POST http://localhost:8000/ask -H "Content-Type: application/json" \
#        -d '{"question": "What is LangGraph?", "thread_id": "user-123"}'
```

### Background Runs with asyncio

```python
import asyncio
import subprocess
from openai import OpenAI
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class BatchState(TypedDict):
    item: str
    result: str

def process_item(state: BatchState) -> dict:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": f"Summarize in 5 words: {state['item']}"}],
        max_tokens=20,
    )
    return {"result": resp.choices[0].message.content.strip()}

builder = StateGraph(BatchState)
builder.add_node("process", process_item)
builder.add_edge(START, "process")
builder.add_edge("process", END)
batch_graph = builder.compile()

async def process_batch(items: list[str]) -> list[dict]:
    """Process multiple items concurrently using asyncio."""
    tasks = [
        asyncio.to_thread(batch_graph.invoke, {"item": item, "result": ""})
        for item in items
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return [
        {"item": item, "result": r["result"] if isinstance(r, dict) else str(r)}
        for item, r in zip(items, results)
    ]

async def main():
    items = ["Python programming", "LangGraph framework", "AI agents", "Machine learning"]
    print(f"Processing {len(items)} items concurrently...")
    results = await process_batch(items)
    for r in results:
        print(f"  {r['item']!r:30} → {r['result']}")

asyncio.run(main())
```

---

## 15. Interview Q&A

**Q1: What is the difference between LangChain and LangGraph?**

> LangChain provides composable building blocks (LLMs, prompts, chains, tools) for linear pipelines. LangGraph adds a **stateful graph layer** on top, enabling cycles (loops), persistent state, human-in-the-loop, and complex multi-agent coordination. Use LangChain for simple sequential tasks; use LangGraph when you need agents that loop, branch, and remember state.

---

**Q2: What is a StateGraph and how is State defined?**

> `StateGraph` is LangGraph's main graph class. State is a `TypedDict` that holds all shared data flowing through the graph. Every node receives the full state and returns a **partial update** (a dict of only the keys it changes). LangGraph merges this partial update back into the state using reducer functions.

```python
from typing import TypedDict, Annotated
import operator

class MyState(TypedDict):
    counter: int                                    # last-write-wins
    history: Annotated[list[str], operator.add]    # append-only reducer
```

---

**Q3: How do conditional edges work in LangGraph?**

> `add_conditional_edges(source_node, routing_fn, mapping)` — after `source_node` completes, LangGraph calls `routing_fn(state)` which returns a string key. That key is looked up in `mapping` to determine the next node. This implements branching and multi-path workflows.

```python
def router(state) -> str:
    return "node_a" if state["score"] > 0.5 else "node_b"

builder.add_conditional_edges("grader", router, {"node_a": "node_a", "node_b": "node_b"})
```

---

**Q4: What is checkpointing and why is it important?**

> Checkpointing saves the full graph state after every node execution. It enables: (1) **resuming** after crashes, (2) **human-in-the-loop** (pause, modify state, resume), (3) **session isolation** via `thread_id`, (4) **time-travel debugging** by replaying from any historical snapshot. `MemorySaver` stores checkpoints in-memory; `SqliteSaver` persists them to disk.

---

**Q5: How do you implement human-in-the-loop in LangGraph?**

> Three approaches: (1) `interrupt_before=["node_name"]` — graph pauses before the node; (2) `interrupt_after=["node_name"]` — pauses after; (3) raise `NodeInterrupt` inside a node. After pausing, inspect state with `graph.get_state(config)`, modify it with `graph.update_state(config, updates)`, then resume by calling `graph.invoke(None, config=config)`.

---

**Q6: Explain the supervisor multi-agent pattern.**

> A central **supervisor** node receives the current state and decides which specialist agent to invoke next. Each specialist completes its task and returns to the supervisor. The supervisor uses `add_conditional_edges` to route between agents and decides when to call `END`. This implements an orchestrator-worker hierarchy without hard-coded execution order.

---

**Q7: What is the difference between stream_mode values, updates, and debug?**

> - `"values"` — emits the **full state snapshot** after each node runs. Best for monitoring overall state.
> - `"updates"` — emits only the **partial dict** returned by each node (what changed). Best for lightweight streaming.
> - `"debug"` — emits verbose internal events (task starts, checkpoints, errors). Best for debugging.

---

**Q8: How do you share state between a subgraph and its parent?**

> State keys with the **same name and type** in both the parent and subgraph schemas are automatically mapped by LangGraph. When the subgraph runs, it receives the matching keys from parent state. When it finishes, its output is merged back into the parent. Keys that exist only in the subgraph remain private to it.

---

**Q9: What is MemorySaver vs SqliteSaver?**

> `MemorySaver` stores checkpoints in a Python dictionary in RAM — fast, no dependencies, but lost when the process exits. `SqliteSaver` persists checkpoints to a SQLite database file — survives restarts, suitable for development and low-scale production. For production at scale, use `PostgresSaver` (from `langgraph-checkpoint-postgres`).

---

**Q10: How do you handle tool errors in a LangGraph agent?**

> Wrap tool logic in `try/except`. `ToolNode` automatically catches exceptions and converts them to `ToolMessage` with `status="error"` so the LLM can see the error and recover. For node-level retries, use conditional edges that check `status` and loop back with exponential backoff. For permanent failures, route to a dead-letter node.

---

**Q11: What is interrupt_before vs interrupt_after?**

> `interrupt_before=["node"]` — graph **pauses before** the node runs. Use when you want to review/modify the state that will be *input* to that node.  
> `interrupt_after=["node"]` — graph **pauses after** the node runs. Use when you want to review the node's *output* before continuing.  
> Both require a checkpointer to be set; both resume with `graph.invoke(None, config=config)`.

---

**Q12: How do you build a self-correcting RAG agent with LangGraph?**

> Define states: retrieve → grade → (if relevant) answer / (if not) rewrite query → retrieve again. The key loop is: `grade_node` → conditional edge → `rewrite_node` → `retrieve_node` → `grade_node`. This creates a self-correcting cycle that keeps searching until it finds a relevant document (with a max-iteration guard to prevent infinite loops). See Section 16 for full code.

---

**Q13: When should you use create_react_agent vs building a custom graph?**

> Use `create_react_agent` for standard tool-calling agents — it handles the LLM ↔ tool ↔ LLM loop automatically. Build a **custom graph** when you need: multiple specialized nodes beyond tool calling, complex branching logic, human-in-the-loop steps, subgraphs, custom state reducers, or a supervisor pattern with multiple agents.

---

**Q14: How does LangGraph compare to CrewAI for multi-agent systems?**

> LangGraph gives **full control** — you define every node, edge, and state update explicitly. It's lower-level, more flexible, and integrates deeply with LangChain. CrewAI is **higher-level** — you define agents with roles/goals/tools and it orchestrates them automatically. Choose LangGraph for custom workflows requiring fine-grained control; choose CrewAI for rapid prototyping of role-based collaborative agents.

---

**Q15: How do you visualize a LangGraph graph?**

```python
# ASCII (works anywhere)
print(graph.get_graph().draw_ascii())

# Mermaid (paste at https://mermaid.live)
print(graph.get_graph().draw_mermaid())

# PNG (requires: pip install pygraphviz)
graph.get_graph().draw_png("my_graph.png")

# With subgraphs expanded
print(graph.get_graph(xray=True).draw_ascii())
```

---

## 16. Complete End-to-End Example — Self-RAG Agent

A Self-RAG (Retrieval-Augmented Generation) agent that:
1. **Retrieves** documents for the question
2. **Grades** each document for relevance
3. **Rewrites** the query if documents are irrelevant
4. **Loops back** to retrieve with the new query
5. **Generates** a grounded answer when relevant docs are found
6. **Guards** against infinite loops with a max-iteration counter

```python
"""
Self-RAG Agent with LangGraph
─────────────────────────────
Flow:
  START
    │
    ▼
  retrieve ──────────────────────────────────────────────────────────────┐
    │                                                                     │
    ▼                                                                     │
  grade_documents                                                         │
    │                                                                     │
    ├─ all_relevant ──► generate_answer ──► check_hallucination           │
    │                          │                                          │
    │                          ├─ grounded ──► END                        │
    │                          └─ hallucinated ──► generate_answer        │
    │                                                                     │
    └─ not_relevant (or max iterations) ──► rewrite_query ───────────────┘
"""

import subprocess
from openai import OpenAI
from typing import TypedDict, Annotated, Literal
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

# ── Auth ──────────────────────────────────────────────────────
token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

MAX_RETRIEVE_ITERATIONS = 3
MAX_GENERATION_RETRIES = 2

# ── State ─────────────────────────────────────────────────────
class SelfRAGState(TypedDict):
    question: str                                       # original question
    current_query: str                                  # may be rewritten
    documents: list[str]                                # retrieved docs
    relevant_docs: list[str]                            # graded-relevant docs
    answer: str                                         # generated answer
    retrieve_iterations: int                            # loop guard
    generation_retries: int                             # hallucination guard
    log: Annotated[list[str], operator.add]             # audit trail
    final_status: str

# ── Simulated Vector Store ────────────────────────────────────
KNOWLEDGE_BASE = {
    "langgraph": [
        "LangGraph is a stateful, graph-based agent framework built on LangChain.",
        "LangGraph supports cycles, human-in-the-loop, and persistent state via checkpointing.",
        "In LangGraph, nodes are Python functions and edges define transitions between them.",
    ],
    "langchain": [
        "LangChain provides composable building blocks for LLM applications.",
        "LangChain Expression Language (LCEL) enables building sequential pipelines.",
    ],
    "rag": [
        "Retrieval-Augmented Generation (RAG) combines document retrieval with LLM generation.",
        "Self-RAG extends RAG by grading retrieved documents and rewriting queries when needed.",
        "In Self-RAG, a grader LLM scores each retrieved document for relevance before generation.",
    ],
    "agents": [
        "AI agents use LLMs to decide which tools to call in order to complete a task.",
        "ReAct agents interleave reasoning and action steps in a loop.",
    ],
}

def simulated_retrieval(query: str) -> list[str]:
    """Simple keyword-based retrieval from our fake knowledge base."""
    query_lower = query.lower()
    results = []
    for topic, docs in KNOWLEDGE_BASE.items():
        if topic in query_lower or any(word in query_lower for word in topic.split()):
            results.extend(docs)
    if not results:
        results = ["No specific documents found for the query."]
    return results[:4]  # Return top 4

# ── Helper ────────────────────────────────────────────────────
def _llm(system: str, user: str, max_tokens: int = 400) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        max_tokens=max_tokens,
    )
    return resp.choices[0].message.content.strip()

# ── Node 1: Retrieve ──────────────────────────────────────────
def retrieve(state: SelfRAGState) -> dict:
    query = state.get("current_query") or state["question"]
    iteration = state.get("retrieve_iterations", 0) + 1
    print(f"\n[retrieve] iteration={iteration}, query={query!r}")

    docs = simulated_retrieval(query)
    print(f"[retrieve] found {len(docs)} documents")

    return {
        "documents": docs,
        "retrieve_iterations": iteration,
        "log": [f"retrieve(iter={iteration}): fetched {len(docs)} docs for query={query!r}"],
    }

# ── Node 2: Grade Documents ───────────────────────────────────
def grade_documents(state: SelfRAGState) -> dict:
    question = state["question"]
    docs = state["documents"]
    print(f"[grade_documents] grading {len(docs)} documents...")

    relevant = []
    for i, doc in enumerate(docs):
        prompt = (
            f"Is this document relevant to answering the question?\n\n"
            f"Question: {question}\n\n"
            f"Document: {doc}\n\n"
            "Reply with exactly: yes or no"
        )
        grade = _llm("You are a document relevance grader.", prompt, max_tokens=5).lower()
        is_relevant = "yes" in grade
        if is_relevant:
            relevant.append(doc)
        print(f"  doc[{i}]: {'✓ relevant' if is_relevant else '✗ not relevant'}")

    print(f"[grade_documents] {len(relevant)}/{len(docs)} documents are relevant")
    return {
        "relevant_docs": relevant,
        "log": [f"grade_documents: {len(relevant)}/{len(docs)} relevant"],
    }

# ── Node 3: Rewrite Query ─────────────────────────────────────
def rewrite_query(state: SelfRAGState) -> dict:
    original = state["question"]
    current = state.get("current_query") or original
    iteration = state.get("retrieve_iterations", 0)

    print(f"[rewrite_query] improving query (attempt {iteration})")
    new_query = _llm(
        "You are a query rewriter. Improve the query to retrieve more relevant documents.",
        f"Original question: {original}\nCurrent query: {current}\n\n"
        "Rewrite the query to be more specific and likely to retrieve relevant documents. "
        "Return only the rewritten query.",
        max_tokens=80,
    )
    print(f"[rewrite_query] new query: {new_query!r}")
    return {
        "current_query": new_query,
        "log": [f"rewrite_query(iter={iteration}): {current!r} → {new_query!r}"],
    }

# ── Node 4: Generate Answer ───────────────────────────────────
def generate_answer(state: SelfRAGState) -> dict:
    question = state["question"]
    docs = state["relevant_docs"] or state["documents"]
    retries = state.get("generation_retries", 0) + 1

    print(f"[generate_answer] generating (retry={retries})")
    context = "\n\n".join(f"Document {i+1}: {doc}" for i, doc in enumerate(docs))

    answer = _llm(
        "You are a precise Q&A assistant. Answer ONLY using the provided documents. "
        "If the documents don't contain the answer, say so explicitly.",
        f"Documents:\n{context}\n\nQuestion: {question}\n\nAnswer:",
        max_tokens=400,
    )
    print(f"[generate_answer] answer: {answer[:100]}...")
    return {
        "answer": answer,
        "generation_retries": retries,
        "log": [f"generate_answer(retry={retries}): generated answer"],
    }

# ── Node 5: Check Hallucination ───────────────────────────────
def check_hallucination(state: SelfRAGState) -> dict:
    docs = state["relevant_docs"] or state["documents"]
    answer = state["answer"]
    context = "\n".join(docs)

    print(f"[check_hallucination] verifying answer is grounded...")
    verdict = _llm(
        "You are a hallucination detector. Check if the answer is grounded in the documents.",
        f"Documents:\n{context}\n\nAnswer:\n{answer}\n\n"
        "Is this answer supported by the documents? Reply with exactly: grounded or hallucinated",
        max_tokens=10,
    ).lower()
    is_grounded = "grounded" in verdict and "hallucinated" not in verdict
    print(f"[check_hallucination] verdict: {'✓ grounded' if is_grounded else '✗ hallucinated'}")
    return {
        "final_status": "grounded" if is_grounded else "hallucinated",
        "log": [f"check_hallucination: {'grounded' if is_grounded else 'hallucinated'}"],
    }

# ── Routing Functions ─────────────────────────────────────────
def route_after_grading(state: SelfRAGState) -> str:
    """Route based on relevance. Guard against infinite loops."""
    has_relevant = bool(state.get("relevant_docs"))
    iterations = state.get("retrieve_iterations", 0)

    if has_relevant:
        return "generate_answer"
    if iterations >= MAX_RETRIEVE_ITERATIONS:
        print(f"[router] max iterations ({MAX_RETRIEVE_ITERATIONS}) reached — generating from best available docs")
        return "generate_answer"
    return "rewrite_query"

def route_after_generation(state: SelfRAGState) -> str:
    """Route based on hallucination check. Guard against infinite retries."""
    status = state.get("final_status", "")
    retries = state.get("generation_retries", 0)

    if status == "grounded":
        return END
    if retries >= MAX_GENERATION_RETRIES:
        print(f"[router] max generation retries reached — accepting answer as-is")
        return END
    return "generate_answer"

# ── Build Graph ───────────────────────────────────────────────
builder = StateGraph(SelfRAGState)

builder.add_node("retrieve", retrieve)
builder.add_node("grade_documents", grade_documents)
builder.add_node("rewrite_query", rewrite_query)
builder.add_node("generate_answer", generate_answer)
builder.add_node("check_hallucination", check_hallucination)

builder.add_edge(START, "retrieve")
builder.add_edge("retrieve", "grade_documents")
builder.add_conditional_edges(
    "grade_documents",
    route_after_grading,
    {
        "generate_answer": "generate_answer",
        "rewrite_query": "rewrite_query",
    },
)
builder.add_edge("rewrite_query", "retrieve")
builder.add_edge("generate_answer", "check_hallucination")
builder.add_conditional_edges(
    "check_hallucination",
    route_after_generation,
    {
        END: END,
        "generate_answer": "generate_answer",
    },
)

memory = MemorySaver()
self_rag_graph = builder.compile(checkpointer=memory)

# ── Run ───────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("SELF-RAG AGENT — LangGraph End-to-End Demo")
    print("=" * 60)

    questions = [
        "What is LangGraph and how does it support stateful agents?",
        "How does Self-RAG improve on standard RAG?",
    ]

    for i, question in enumerate(questions):
        print(f"\n{'─'*60}")
        print(f"QUESTION {i+1}: {question}")
        print("─" * 60)

        config = {"configurable": {"thread_id": f"self-rag-{i}"}}
        initial_state: SelfRAGState = {
            "question": question,
            "current_query": "",
            "documents": [],
            "relevant_docs": [],
            "answer": "",
            "retrieve_iterations": 0,
            "generation_retries": 0,
            "log": [],
            "final_status": "",
        }

        result = self_rag_graph.invoke(initial_state, config=config)

        print(f"\n{'─'*40}")
        print(f"FINAL ANSWER:\n{result['answer']}")
        print(f"\nStatus         : {result['final_status'] or 'completed'}")
        print(f"Retrieve iters : {result['retrieve_iterations']}")
        print(f"Gen retries    : {result['generation_retries']}")
        print(f"\nExecution log:")
        for entry in result["log"]:
            print(f"  → {entry}")
```

---

## Quick Reference Card

```
StateGraph(StateType)              — create graph
  .add_node(name, fn)              — register node function
  .add_edge(a, b)                  — fixed transition a→b
  .add_conditional_edges(          — branching transition
      src, routing_fn, mapping)
  .compile(checkpointer=...,       — build runnable graph
           interrupt_before=[...])
  .invoke(state, config=...)       — run synchronously
  .stream(state, config=...,       — stream events
          stream_mode="updates")
  .astream(...)                    — async stream
  .get_state(config)               — read checkpoint
  .update_state(config, updates)   — modify paused state
  .get_state_history(config)       — all snapshots

Checkpointers:
  MemorySaver()                    — in-memory
  SqliteSaver(conn)                — SQLite file
  PostgresSaver(conn)              — PostgreSQL (production)

Special nodes:
  START                            — graph entry point
  END                              — graph exit point

State reducers:
  Annotated[list, operator.add]    — append-only list
  Annotated[list, add_messages]    — messages with dedup
  Annotated[T, custom_fn]          — custom merge logic

Config:
  {"configurable": {"thread_id": "..."}}   — session isolation
```
