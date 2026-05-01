# Building Agentic AI with LangGraph — A Complete Guide
> *Based on: YouTube: "LangGraph Crash Course — Building Agentic AI Applications" by Krish Naik*
> *Generated: 2026-04-28 | Audience: Beginner to Intermediate*

---

## 🧭 What This Guide Covers

This guide transforms a comprehensive LangGraph crash course into a structured, hands-on reference. The narrator — Krish Naik — walks you from absolute zero (project setup) all the way through building a basic chatbot, wiring in external tools, understanding the ReACT agent loop, adding persistent memory, working with streaming modes, implementing human-in-the-loop feedback, and finally building MCP servers from scratch. By the end you will understand not just *how* to use LangGraph but *why* every design decision exists.

---

## 💡 The Big Picture

LangGraph is a Python library built on top of LangChain that lets you model AI workflows as **graphs** — nodes connected by edges — where a shared **state** flows through the entire execution. The key insight is that complex workflows (think: extract a YouTube transcript → generate a title → write a blog post) can be broken down into individual nodes, each with a clear responsibility, and the graph wires them together.

> 💬 *"In langraph if you want to solve this kind of workflows there are two ways — graph API and functional API. According to my experience I feel graph API is the most easiest and most best way."*

The narrator frames LangGraph around a concrete use case he genuinely wanted to solve: *he uploads a lot of YouTube videos and wanted an automated pipeline to turn each video into a blog post*. That example — YouTube URL → transcript → title → content — is the thread that makes every concept in this guide click.

There are two API styles in LangGraph:

| API Style | Best For | When to Switch |
|-----------|----------|----------------|
| **Graph API** | Learning, most use cases | Stay here until very comfortable |
| **Functional API** | Advanced patterns, expert users | Only once Graph API is mastered |

---

## 📚 Core Concepts

### Nodes

A **node** is a unit of work in your graph. Every node has:
1. A **name** (a string you choose)
2. A **node definition** — a Python function that receives the current state and returns an update to it

In the YouTube-to-blog example, the nodes are:
- `transcript_generator` → takes a YouTube URL, outputs a transcript
- `title_generator` → takes a transcript, outputs a title
- `content_generator` → takes a title + transcript, outputs the full blog post

> 💬 *"Whenever we talk about nodes, as soon as you create a node, we also have to create a node implementation — some functionality with respect to this particular node."*

In code, a node definition looks like this:

```python
def chatbot(state: State):
    return {"messages": [llm.invoke(state["messages"])]}
```

### Edges

An **edge** is the connection between two nodes — it defines which node runs after which. The fundamental job of an edge is to move information (or control flow) from one node to the next.

There are two types:

| Edge Type | Use When |
|-----------|----------|
| **Regular edge** (`add_edge`) | There is exactly one path out of a node |
| **Conditional edge** (`add_conditional_edges`) | A node can route to two or more different next nodes |

> 💬 *"Edge main fundamental is that the flow of information should go from node to node."*

Conditional edges are how tool-calling chatbots work: after the LLM responds, if it made a tool call, go to the tool node; if it answered directly, go to end.

### State

The **state** is the shared memory of the entire graph. Every node can read from it and write to it. You define the state as a Python class that inherits from `TypedDict`:

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph.message import add_messages

class State(TypedDict):
    """
    The state key 'messages' uses add_messages as a reducer.
    This appends messages to the list rather than overwriting them.
    """
    messages: Annotated[list, add_messages]
```

> 💬 *"The state it is able to maintain the context of the state at every node. And this entire graph we basically say it as state graph — because it is able to maintain the context of the state at every node."*

**Why TypedDict?** Because the state returns data in dictionary form (`{"messages": [...]}`) and TypedDict makes that type-safe at development time.

### Reducers

A **reducer** controls *how* a state key gets updated when a node writes to it. Without a reducer, each node write **replaces** the existing value. With `add_messages` as the reducer, each new message gets **appended** to the list instead.

```python
# Without reducer: second message replaces first
# With add_messages reducer: second message appends to list
messages: Annotated[list, add_messages]
```

> 💬 *"When we say reducer, that basically means it is not going to replace this list with respect to every conversation we have. Instead, it is going to append."*

This is what makes a chatbot feel like a *conversation* — every exchange accumulates in the messages list and is available to all nodes in the graph.

### StateGraph

`StateGraph` is the container for your entire graph. You pass it your State class, then add nodes and edges to it, and finally compile it.

```python
from langgraph.graph import StateGraph, START, END

graph_builder = StateGraph(State)
```

`START` and `END` are special built-in node names that represent the entry and exit points of the graph. All graphs must begin at `START` and terminate at `END`.

---

## ⚙️ How It Works — Under the Hood

### The Graph Lifecycle

Every LangGraph workflow follows the same lifecycle:

```
Define State class
       ↓
Create StateGraph(State)
       ↓
Add nodes (graph_builder.add_node)
       ↓
Add edges (graph_builder.add_edge / add_conditional_edges)
       ↓
Compile (graph_builder.compile())
       ↓
Invoke or Stream (graph.invoke / graph.stream)
```

> 💬 *"The compilation is necessary so that we can execute the graph. Unless and until the graph is not compiled you will not be able to execute it."*

### How Nodes Receive and Return State

Each node function takes the current `state` as its argument and returns a **partial dictionary** — only the keys it wants to update. LangGraph merges this partial dictionary back into the full state using the reducers you defined:

```python
def chatbot(state: State):
    # state["messages"] = all messages so far
    response = llm.invoke(state["messages"])
    # Return only what this node changes
    return {"messages": [response]}
    # add_messages reducer will APPEND response, not replace
```

### How Tool Calls Flow

When an LLM is bound with tools, it can respond with either:
- A **regular AI message** (direct answer) → condition routes to `END`
- A **tool call message** (empty content, but includes tool name + arguments) → condition routes to the tools node

The `tools_condition` from `langgraph.prebuilt` encodes exactly this logic — you don't have to write the if/else yourself:

```
Input
  ↓
tool_calling_llm node
  ↓ (conditional edge via tools_condition)
  ├─ tool call? → tools node → back to tool_calling_llm (ReACT) or END
  └─ direct answer? → END
```

---

## 🔧 Practical Usage & Implementation

### Setting Up with UV Package Manager

The narrator uses **UV** — a Rust-based Python package manager that is 10–100× faster than pip. It replaces pip, poetry, pyenv, and pipx with a single tool.

```powershell
# Install UV on Windows (PowerShell)
pip install uv

# Initialise a new project workspace
uv init

# Create a virtual environment
uv venv

# Activate the environment (Windows)
.venv\Scripts\activate

# Install dependencies from requirements.txt
uv add -r requirements.txt
```

A typical `requirements.txt` for LangGraph projects:

```
langgraph
langchain
langsmith
langchain-groq
langchain-tavily
python-dotenv
ipykernel
```

> 💬 *"UV package manager — it is a really fast, extremely fast Python package and project manager and it is completely written in Rust."*

### Building a Basic Chatbot

**Imports and LLM initialisation:**

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model
import os
from dotenv import load_dotenv

load_dotenv()

# Init the LLM — works with any provider
llm = init_chat_model(model="groq:llama3-8b-8192")
```

**Define the State:**

```python
class State(TypedDict):
    """
    messages: list of conversation turns.
    add_messages reducer appends each new message
    rather than overwriting the list.
    """
    messages: Annotated[list, add_messages]
```

**Define the chatbot node:**

```python
def chatbot(state: State):
    return {"messages": [llm.invoke(state["messages"])]}
```

**Build, compile and run the graph:**

```python
graph_builder = StateGraph(State)
graph_builder.add_node("llm_chatbot", chatbot)
graph_builder.add_edge(START, "llm_chatbot")
graph_builder.add_edge("llm_chatbot", END)

graph = graph_builder.compile()

# Invoke
response = graph.invoke({"messages": ["hi"]})
print(response["messages"][-1].content)
```

**Visualise the graph:**

```python
from IPython.display import Image, display

try:
    display(Image(graph.get_graph().draw_mermaid_png()))
except Exception:
    pass
```

### Building a Chatbot with Tools

The fundamental question this solves: *"What if the LLM doesn't know the answer because it requires live information?"* You bind external tools to the LLM so it can delegate.

**Step 1 — Define or import tools:**

```python
from langchain_tavily import TavilySearch

# Internet search tool
tavily_search = TavilySearch(max_results=2)

# Custom tool — docstring is what teaches the LLM what this tool does
def multiply(a: int, b: int) -> int:
    """
    Multiply a and b.
    Args:
        a: First integer
        b: Second integer
    Returns:
        int: Product of a and b
    """
    return a * b

tools = [tavily_search, multiply]
```

> 💬 *"When you define any custom tool you also need to provide the docstring. With the help of this docstring the LLM will know what are the inputs and what are the arguments that is required."*

**Step 2 — Bind tools to the LLM:**

```python
llm_with_tools = llm.bind_tools(tools)
```

Binding means the LLM *knows* which tools exist. It reads the docstrings to understand when to call each one.

**Step 3 — Import ToolNode and tools_condition:**

```python
from langgraph.prebuilt import ToolNode, tools_condition
```

`ToolNode` wraps your list of tools into a node that executes whichever tool the LLM called.  
`tools_condition` is the conditional routing function that routes to `tools` if the latest message is a tool call, or to `END` if it is a direct answer.

**Step 4 — Build the graph with conditional edges:**

```python
def tool_calling_llm(state: State):
    return {"messages": [llm_with_tools.invoke(state["messages"])]}

builder = StateGraph(State)
builder.add_node("tool_calling_llm", tool_calling_llm)
builder.add_node("tools", ToolNode(tools))

builder.add_edge(START, "tool_calling_llm")
builder.add_conditional_edges("tool_calling_llm", tools_condition)
builder.add_edge("tools", END)   # simple tool call — goes to END

graph = builder.compile()
```

> 💬 *"Tool condition applies two different conditions. If the latest message from the assistant is a tool call, tool condition routes to tool node. If it is not a tool call, tool condition routes to end."*

### ReACT Agent Architecture

A plain tool-calling chatbot has a limitation: if you ask *two* things in one message (e.g. "give me the recent AI news and then multiply 5 by 10"), it answers the first tool call and then goes straight to `END` — the second request is dropped.

The fix is the **ReACT loop**: instead of routing tools → END, route tools → back to the LLM. The LLM keeps acting until every part of the query is resolved.

```
Input
  ↓
tool_calling_llm ──── direct answer ──────────────────→ END
      ↑                    
      │                    
   tools ←── tool call ─────┘
   (result goes back to LLM)
```

**The only code change needed:**

```python
# Before: builder.add_edge("tools", END)
# After:
builder.add_edge("tools", "tool_calling_llm")   # loop back!
```

The three pillars of ReACT:

| Step | What Happens |
|------|-------------|
| **Act** | LLM receives input and makes a tool call |
| **Observe** | LLM receives the tool result and decides what to do next |
| **Reason** | LLM determines: is the full query satisfied? If yes → END. If no → Act again |

> 💬 *"This way of communication — this agent architecture — is basically called as react agent architecture. In react there are three main key terms: act, observe, and reason."*

LangGraph's `prebuilt.create_react_agent` packages this entire pattern for you:

```python
from langgraph.prebuilt import create_react_agent

agent = create_react_agent(model=llm, tools=tools)
```

### Adding Memory (Persistent Checkpointing)

Without memory, every graph invocation starts fresh. The chatbot forgets the previous turn. The narrator demonstrates this problem by asking "what is my name?" after saying "my name is Krish" — and the bot has no idea.

LangGraph solves this with **MemorySaver** — an in-memory checkpoint store that saves the full state after every node execution.

```python
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()

# Pass checkpointer at compile time
graph = builder.compile(checkpointer=memory)
```

To use memory, every `invoke` or `stream` call must include a **thread ID** inside a `config` dictionary. The thread ID ties a session to its checkpointed history:

```python
config = {"configurable": {"thread_id": "user_session_42"}}

# First message
graph.invoke({"messages": ["hi, my name is Krish"]}, config=config)

# Second message — graph remembers the first
response = graph.invoke({"messages": ["what is my name?"]}, config=config)
print(response["messages"][-1].content)
# → "Your name is Krish."
```

> 💬 *"When you create an end-to-end application this dynamic thread ID will be maintained in the session itself. So that way we'll be able to maintain this entirely in the memory saver."*

**Important:** Each unique `thread_id` is an isolated conversation. Use a new thread ID for each user session in production.

### Streaming in LangGraph

Instead of waiting for the full graph to finish, streaming lets you display outputs as they arrive. There are two execution methods:

| Method | Style |
|--------|-------|
| `graph.stream(...)` | Synchronous — use in regular Python |
| `graph.astream(...)` | Async — use in async contexts |

Both methods accept a `stream_mode` parameter with two options:

#### `stream_mode="updates"` — Only the latest delta

Only outputs the message(s) generated by the *currently executing* node. You see only what just changed:

```python
for chunk in graph.stream(
    {"messages": ["hi, my name is Krish, I like cricket"]},
    config=config,
    stream_mode="updates"
):
    print(chunk)
# → AI message only (the new content)
```

#### `stream_mode="values"` — Cumulative full state

Outputs the *entire* state after every node executes. You see the growing conversation list:

```python
for chunk in graph.stream(
    {"messages": ["hi, my name is Krish, I like cricket"]},
    config=config,
    stream_mode="values"
):
    print(chunk)
# → human message, then AI message — everything accumulated
```

> 💬 *"In mode equals update, only the message that is currently getting updated only that message will get displayed as an output. Whereas in the case of values everything is getting displayed — your human message, your AI message, everything is getting displayed."*

There is also `graph.stream_events(...)` for very granular, event-level debugging — useful when you need to trace every intermediate step.

### Human in the Loop

Some workflows should not complete automatically — they need a human to review and approve an intermediate step. LangGraph supports this with `interrupt` and `Command`.

**The setup:** Create a `human_assistance` tool that uses `interrupt` to pause execution mid-graph and wait for human input:

```python
from langgraph.types import interrupt, Command
from langchain_core.tools import tool

@tool
def human_assistance(query: str) -> str:
    """Request assistance from a human. Use when the user needs expert human guidance."""
    human_response = interrupt({"query": query})
    return human_response["data"]
```

The `interrupt(...)` call *freezes* graph execution at that point. The graph's state is checkpointed. A human can now inspect the situation and provide a response.

**Resuming the workflow** — pass the human's response via `Command`:

```python
# Execution paused — human provides feedback
human_feedback = "We recommend using LangGraph. It's more reliable than simple autonomous agents."

# Resume with Command
for event in graph.stream(
    Command(resume={"data": human_feedback}),
    config=config,
    stream_mode="values"
):
    print(event)
```

> 💬 *"Interrupt basically means we are interrupting a workflow. It is forcefully interrupting so that a human can provide a feedback."*

This pattern is powerful for any workflow where an LLM action needs approval before proceeding — automated deployments, financial transactions, sensitive content generation.

### Building MCP Servers from Scratch

**Model Context Protocol (MCP)** is a standard for how AI applications communicate with external tools and services. Think of it as a universal adapter: your LangGraph app (the client) talks to any MCP-compliant server (which exposes tools), regardless of who built the server.

```
[Your LangGraph App]
      ↕ (MCP Client)
[MCP Server 1: Math tools]   — stdio transport
[MCP Server 2: Weather API]  — HTTP transport
```

#### Transport Protocols

| Transport | How It Runs | Best For |
|-----------|-------------|----------|
| **stdio** | Server process runs in the terminal; client communicates via stdin/stdout | Local development and testing |
| **Streamable HTTP** | Server runs as an HTTP API on a port (e.g. `http://localhost:8000`) | Production, remote servers |

#### Building an MCP Server with FastMCP

Install the required libraries:

```
langchain-groq
langchain-mcp-adapters
fastmcp
mcp
langgraph
```

**Math server — `math_server.py` (stdio transport):**

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("math")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

@mcp.tool()
def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b

if __name__ == "__main__":
    # stdio: receives/sends via command line standard I/O
    mcp.run(transport="stdio")
```

**Weather server — `weather.py` (streamable HTTP transport):**

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("weather")

@mcp.tool()
def get_weather(location: str) -> str:
    """Get the weather for a location."""
    # In a real app, call a weather API here
    return f"It's always raining in {location}."

if __name__ == "__main__":
    # streamable HTTP: runs as an API on http://localhost:8000
    mcp.run(transport="streamable-http")
```

Run the weather server in a terminal first:

```bash
python weather.py
# → Serving on http://localhost:8000/mcp
```

#### Building an MCP Client — `client.py`

```python
import asyncio
import os
from dotenv import load_dotenv
from langchain_mcp_adapters.client import MultiServerMCPClient
from langgraph.prebuilt import create_react_agent
from langchain_groq import ChatGroq

load_dotenv()

async def main():
    # Connect to both MCP servers
    async with MultiServerMCPClient(
        {
            "math": {
                "command": "python",
                "args": ["math_server.py"],   # absolute path in production
                "transport": "stdio",
            },
            "weather": {
                "url": "http://localhost:8000/mcp",
                "transport": "streamable_http",
            },
        }
    ) as client:
        # Get all tools from all connected servers
        tools = await client.get_tools()

        # Create a ReACT agent with the MCP tools
        model = ChatGroq(model="qwen-qw-32b")
        agent = create_react_agent(model, tools)

        # Math query
        math_response = await agent.ainvoke(
            {"messages": [{"role": "user", "content": "What is 3 + 5 * 2?"}]}
        )
        print("Math response:", math_response["messages"][-1].content)

        # Weather query
        weather_response = await agent.ainvoke(
            {"messages": [{"role": "user", "content": "What is the weather in California?"}]}
        )
        print("Weather response:", weather_response["messages"][-1].content)

asyncio.run(main())
```

> 💬 *"In short what all things we did? We created a client and this client were able to communicate with two MCP servers. This MCP server is communicating with transport equal to stdio and this MCP server you are able to communicate with HTTP protocol transport."*

---

## ⚠️ Gotchas & Common Mistakes

| Gotcha | Why It Happens | Narrator's Advice |
|--------|---------------|-------------------|
| **Missing docstrings on custom tools** | LLM cannot understand what the tool does or when to call it | Always write a clear docstring — it is literally the LLM's instruction manual for that tool |
| **Kernel restart needed after adding API keys to `.env`** | `load_dotenv()` was called before the `.env` file existed; the key is never loaded into `os.environ` | Restart the Jupyter kernel after modifying `.env`, then re-execute all cells |
| **Node already present error** | Compiling a graph that has a node added twice (often from re-running cells without reinitialising `graph_builder`) | Recreate the `StateGraph` object before recompiling |
| **Tool result not appearing (multiply returned null)** | Custom tool function body was missing the `return` statement | Always include `return` in your tool — the LLM receives `None` if you forget |
| **Memory not persisting across invocations** | Using `graph.invoke` without a `config` containing a `thread_id` | Always pass `config={"configurable": {"thread_id": "<id>"}}` when using MemorySaver |
| **Graph routes to END before answering all questions** | Tool output goes to `END` instead of looping back to the LLM | Change `builder.add_edge("tools", END)` to `builder.add_edge("tools", "tool_calling_llm")` for ReACT behaviour |
| **stdio MCP server appears to do nothing when run** | stdio transport doesn't print anything — it waits for input on stdin | This is correct; the client invokes it programmatically. Use streamable HTTP if you need to inspect it via a browser |
| **Wrong path for MCP server in client config** | `"args": ["math_server.py"]` only works if your working directory matches | Use the absolute path to the server file in production |

---

## 🔗 How It Connects to Other Concepts

### LangChain vs LangGraph

LangGraph is built *on top of* LangChain. LangChain gives you the building blocks (LLMs, tools, prompts, chains). LangGraph adds the **graph execution engine** — the ability to model control flow, loops, and branching with explicit state management.

> 💬 *"However, LangChain has limitations" — LangGraph was built specifically to handle complex workflows and agent loops that LangChain chains alone cannot express cleanly.*

### LangSmith / LangSmith Studio

The narrator mentions **LangSmith** for tracking, evaluation, and debugging of LangGraph applications — it integrates directly and lets you inspect every node execution, state snapshot, and tool call in a visual dashboard.

### MCP and the Agentic Ecosystem

MCP (Model Context Protocol) is positioned as the universal interface between AI apps and the services they depend on. Third-party companies can build MCP servers exposing their APIs, and any LangGraph app with an MCP client can consume them without custom integration code. This mirrors how HTTP made the web interoperable.

### The Three-Part Course Roadmap

The narrator positions this content (Part 1) within a larger journey:

| Part | Focus |
|------|-------|
| **Part 1** (this guide) | Fundamentals: chatbot, tools, ReACT, memory, streaming, human-in-loop, MCP |
| **Part 2** | Advanced: multi-agent workflows, agent-to-agent communication, multi-state management, Functional API, LangSmith Studio debugging |
| **Part 3** | Production: end-to-end projects, LMOS pipelines, deployment on Hugging Face Spaces, evaluation metrics, MLflow, AWS, Grafana |

---

## 🎯 Key Takeaways

- **LangGraph = graphs for AI workflows.** Every workflow is nodes (units of work), edges (flow of control), and state (shared data). Get these three concepts locked in and everything else follows.
- **Reducers are the secret to conversational memory within a session.** `add_messages` appends to the list — without it, every node invocation would wipe the conversation history.
- **Binding tools tells the LLM *what it has*. Docstrings tell it *when to use each one*.** Never skip docstrings on custom tools.
- **`tools_condition` handles the if/else so you don't have to.** Route a conditional edge through it and LangGraph automatically decides: tool call → tools node, direct answer → END.
- **ReACT = just one edge change.** Routing `tools → tool_calling_llm` instead of `tools → END` turns a one-shot tool call into a reasoning loop.
- **Memory requires a thread ID.** `MemorySaver` alone does nothing; you must pass `{"configurable": {"thread_id": "..."}}` in the config on every call.
- **`stream_mode="updates"` for live UI output; `stream_mode="values"` for full state inspection.**
- **MCP has two transport modes.** Use `stdio` for local testing (server runs in terminal), `streamable-http` for services that need to be reachable over a network.
- **FastMCP makes MCP server creation trivial.** Decorate a Python function with `@mcp.tool()`, add a docstring, and you have an MCP-compliant tool.

---

## 📖 Narrator's Own Words

> *"Trust me — as you go ahead, any kind of graph, any kind of complex workflow that you have in your mind, you should be able to execute it."*

> *"LLM is actually the brain behind taking this decision. And when LLM is binding with these tools — it is just like giving LLM some kind of weapons to solve your input."*

> *"So this way of interaction of LLM with tools — this agent architecture — is basically called as react agent architecture. And this was the rise — because of this, agentic AI has become very much popular."*

> *"Langraph has a very special property in order to overcome this advantage which is called as memory. And this memory actually solves a major problem — persistent checkpointing."*

> *"The transport is equal to stdio. It tells the server to use standard input output to receive and respond to the tool functional calls."*

> *"At the end of the day, it's all about how you are using some specific models and which model you really want to use."*

---

*Guide synthesised from: YouTube: "LangGraph Crash Course — Building Agentic AI Applications" by Krish Naik | Agent: transcript-guide v1.0.0 | Validated: 2026-04-28*
