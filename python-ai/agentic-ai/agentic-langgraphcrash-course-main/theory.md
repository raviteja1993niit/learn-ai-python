# LangGraph Theory Guide — Comprehensive Reference

## 1. What is LangGraph? Why Graphs for Agents?

LangGraph is a library built on top of LangChain that enables you to build stateful,
multi-actor applications with Large Language Models (LLMs). It models agent workflows
as directed graphs, where nodes represent computation steps and edges represent the
flow of data between steps.

### Why graphs?

Traditional LLM pipelines are linear: input → LLM → output. Real-world agents need:
- **Loops**: retry, reflect, or iterate until a condition is met
- **Branching**: take different paths based on LLM output or tool results
- **Persistence**: remember what happened across multiple invocations
- **Parallelism**: run independent steps concurrently
- **Human oversight**: pause and wait for a human decision mid-execution

A graph naturally expresses all of these. Each execution traverses the graph, and the
framework manages state transitions, persistence, and streaming automatically.

LangGraph is inspired by Pregel (Google's large-scale graph processing system) and
Apache Beam, using a message-passing model internally. It is production-ready and
powers many real-world agentic systems.

---

## 2. Nodes: Python Functions That Process State

A **node** is simply a Python function (or callable) that:
1. Receives the current state as its only argument
2. Performs some computation (call an LLM, run a tool, transform data)
3. Returns a dictionary of updates to apply to the state

### Node contract

```python
def my_node(state: MyState) -> dict:
    # read from state
    # do work
    return {"key": new_value}  # partial update
```

The return value is merged into the current state using the state's reducer logic
(see Section 13 for `add_messages`). You do NOT return the full state — only the
fields you want to change.

### Async nodes

Nodes can be async for I/O-bound work:

```python
async def async_node(state: MyState) -> dict:
    result = await some_async_call(state["input"])
    return {"output": result}
```

### Special nodes

- `START`: the virtual entry point (built-in)
- `END`: the virtual terminal node (built-in)
- `ToolNode`: a pre-built node that executes tool calls (Section 12)

---

## 3. Edges: Connections Between Nodes

Edges define the flow of execution between nodes. There are two types:

### Unconditional edges

An unconditional edge always routes from node A to node B:

```python
graph.add_edge("node_a", "node_b")
```

After `node_a` finishes, execution always proceeds to `node_b`.

### Conditional edges

A conditional edge uses a **router function** to decide the next node at runtime:

```python
graph.add_conditional_edges(
    "node_a",
    routing_function,   # returns a string (node name) or list of names
    {"option_1": "node_b", "option_2": "node_c"}  # optional mapping
)
```

The routing function receives the current state and returns a string identifying
the next node. This is how branching and loops are implemented.

### Entry point

```python
graph.set_entry_point("first_node")
# or equivalently:
graph.add_edge(START, "first_node")
```

### Finish point

```python
graph.set_finish_point("last_node")
# or equivalently:
graph.add_edge("last_node", END)
```

---

## 4. State: TypedDict Defining the Graph's Data

State is the shared memory of the graph. Every node reads from and writes to state.
It is defined as a Python `TypedDict`:

```python
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    user_input: str
    loop_count: int
    final_answer: str
```

### Key principles

- **All fields are optional** by default (nodes return partial updates)
- **Annotations** (like `add_messages`) define how values are merged when a node
  returns an update — this is called a **reducer**
- Without an annotation, a field is simply overwritten by the latest update
- State is immutable within a node; you return new values, never mutate in place

### Default reducer (overwrite)

```python
class State(TypedDict):
    counter: int  # overwritten each time
```

### Custom reducer

```python
def append_list(existing: list, new: list) -> list:
    return existing + new

class State(TypedDict):
    items: Annotated[list, append_list]
```

---

## 5. StateGraph Compilation and Invocation

### Building the graph

```python
from langgraph.graph import StateGraph, END

builder = StateGraph(AgentState)
builder.add_node("node_a", node_a_fn)
builder.add_node("node_b", node_b_fn)
builder.set_entry_point("node_a")
builder.add_edge("node_a", "node_b")
builder.add_edge("node_b", END)

graph = builder.compile()
```

### Invocation

```python
# Synchronous
result = graph.invoke({"messages": [], "user_input": "Hello"})

# Async
result = await graph.ainvoke({"messages": [], "user_input": "Hello"})
```

`invoke` runs the graph to completion and returns the final state.

### Config and thread_id

When using checkpointing, pass a config dict:

```python
config = {"configurable": {"thread_id": "user-123"}}
result = graph.invoke(initial_state, config=config)
```

---

## 6. Conditional Edges: Route Based on State

Conditional edges are the mechanism for all decision-making in LangGraph.

### Router function pattern

```python
def should_continue(state: AgentState) -> str:
    messages = state["messages"]
    last_message = messages[-1]
    if last_message.tool_calls:
        return "tools"
    return "end"

graph.add_conditional_edges(
    "agent",
    should_continue,
    {"tools": "tool_node", "end": END}
)
```

### Routing to multiple nodes (parallel fan-out)

```python
def fan_out(state: State) -> list[str]:
    return ["node_a", "node_b"]  # both run in parallel

graph.add_conditional_edges("start_node", fan_out)
```

### Using Literal types for clarity

```python
from typing import Literal

def router(state: State) -> Literal["tools", "respond", "escalate"]:
    ...
```

---

## 7. Checkpointing: MemorySaver and SqliteSaver

Checkpointing gives your graph **persistence** — the ability to pause, resume, and
replay execution. After every node, the current state is saved to the checkpointer.

### MemorySaver (in-memory, for development)

```python
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()
graph = builder.compile(checkpointer=memory)
```

State is stored in RAM. Lost when the process restarts. Perfect for development and testing.

### SqliteSaver (on-disk, for production-like persistence)

```python
from langgraph.checkpoint.sqlite import SqliteSaver

with SqliteSaver.from_conn_string("checkpoints.db") as saver:
    graph = builder.compile(checkpointer=saver)
    result = graph.invoke(state, config={"configurable": {"thread_id": "t1"}})
```

State is persisted to a SQLite database file. Survives process restarts.

### thread_id

Each conversation or workflow instance uses a unique `thread_id`. All checkpoints for
the same thread are stored together, enabling full replay and resumption.

### Replaying state

```python
# Get state at a specific checkpoint
state_snapshot = graph.get_state(config)

# Get full history
for checkpoint in graph.get_state_history(config):
    print(checkpoint)
```

---

## 8. Human-in-the-Loop: interrupt_before, interrupt_after, Command.RESUME

Human-in-the-loop (HITL) allows an agent to pause mid-execution, present information
to a human, and resume after receiving human input.

### interrupt_before

Pause BEFORE a node executes:

```python
graph = builder.compile(
    checkpointer=memory,
    interrupt_before=["approval_node"]
)
```

When the graph reaches `approval_node`, it saves state and raises `GraphInterrupt`.

### interrupt_after

Pause AFTER a node executes:

```python
graph = builder.compile(
    checkpointer=memory,
    interrupt_after=["draft_node"]
)
```

### Resuming with Command

```python
from langgraph.types import Command

# Resume without modification
graph.invoke(Command(resume=None), config=config)

# Resume with human feedback
graph.invoke(Command(resume={"approved": True, "comment": "Looks good"}), config=config)
```

### interrupt() function (inline interruption)

You can also interrupt from within a node:

```python
from langgraph.types import interrupt

def human_review_node(state: State) -> dict:
    human_decision = interrupt({"question": "Approve this action?", "data": state})
    if human_decision["approved"]:
        return {"status": "approved"}
    return {"status": "rejected"}
```

---

## 9. Streaming: stream() vs astream()

Streaming lets you observe the graph's execution in real time — node by node or
token by token.

### stream() — synchronous, node-by-node

```python
for event in graph.stream(initial_state, config=config):
    for node_name, node_output in event.items():
        print(f"Node: {node_name}, Output: {node_output}")
```

Each `event` is a dict mapping a node name to its output.

### astream() — async streaming

```python
async for event in graph.astream(initial_state, config=config):
    for node_name, node_output in event.items():
        print(f"Node: {node_name}, Output: {node_output}")
```

### Stream modes

```python
# "values" — emit full state after each node
for state in graph.stream(input, stream_mode="values"):
    print(state)

# "updates" — emit only the delta (default)
for update in graph.stream(input, stream_mode="updates"):
    print(update)

# "debug" — verbose internal events
for event in graph.stream(input, stream_mode="debug"):
    print(event)
```

### Token-by-token streaming (LLM tokens)

```python
async for event in graph.astream_events(initial_state, version="v2"):
    if event["event"] == "on_chat_model_stream":
        chunk = event["data"]["chunk"]
        print(chunk.content, end="", flush=True)
```

---

## 10. Subgraphs: Composing Graphs Within Graphs

Subgraphs allow you to build modular, reusable graph components and compose them
into larger graphs.

### Creating a subgraph

```python
sub_builder = StateGraph(SubState)
sub_builder.add_node("step1", step1_fn)
sub_builder.add_node("step2", step2_fn)
sub_builder.set_entry_point("step1")
sub_builder.add_edge("step1", "step2")
sub_builder.add_edge("step2", END)
subgraph = sub_builder.compile()
```

### Using subgraph as a node

```python
main_builder = StateGraph(MainState)
main_builder.add_node("sub_process", subgraph)  # compiled graph as node
main_builder.add_node("post_process", post_fn)
main_builder.set_entry_point("sub_process")
main_builder.add_edge("sub_process", "post_process")
```

### State transformation

If the parent and subgraph have different state schemas, add a transformation node
before and after the subgraph to map between them.

---

## 11. Multi-Agent Architectures: Supervisor and Swarm

### Supervisor architecture

A central "supervisor" agent decides which specialized agent to call next:

```
User → Supervisor → [Research Agent | Writing Agent | Code Agent] → Supervisor → User
```

The supervisor is a node that uses an LLM to classify the task and routes to the
appropriate specialist. Specialists report back to the supervisor when done.

### Swarm architecture

Agents in a swarm communicate peer-to-peer, handing off control to each other:

```
Agent A → Agent B → Agent C → Agent A (loop until done)
```

Each agent can decide to hand off to another agent using a special `handoff` tool.
`langgraph_swarm` provides built-in support for this pattern.

### Key design principles

- Each agent is a node (or subgraph) in the parent graph
- Shared state allows agents to read each other's outputs
- Use `Command(goto=...)` to programmatically route between agents
- Checkpointing works across the entire multi-agent graph

---

## 12. Tool Nodes: ToolNode — Automatic Tool Execution

`ToolNode` is a pre-built node that automatically executes tool calls found in the
last AI message.

### Setup

```python
from langgraph.prebuilt import ToolNode
from langchain_core.tools import tool

@tool
def search_web(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query}"

tools = [search_web]
tool_node = ToolNode(tools)
```

### Integration with ReAct loop

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o").bind_tools(tools)

def agent_node(state: MessagesState) -> dict:
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: MessagesState) -> str:
    if state["messages"][-1].tool_calls:
        return "tools"
    return END

graph.add_node("agent", agent_node)
graph.add_node("tools", tool_node)
graph.add_conditional_edges("agent", should_continue)
graph.add_edge("tools", "agent")
```

---

## 13. Message State: add_messages Annotation and MessagesState

### add_messages reducer

The `add_messages` annotation makes a list field act like a chat history — new
messages are appended rather than overwriting the list:

```python
from typing import Annotated
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]
```

`add_messages` also handles deduplication: if you return a message with the same ID
as an existing one, it is updated in place (useful for streaming).

### MessagesState shortcut

LangGraph provides a built-in state class for chat applications:

```python
from langgraph.graph import MessagesState

# Equivalent to:
# class MessagesState(TypedDict):
#     messages: Annotated[list[BaseMessage], add_messages]
```

Use `MessagesState` as the base for any conversational agent.

---

## 14. Debugging: LangSmith Tracing + LangGraph Studio

### LangSmith tracing

Set environment variables to enable automatic tracing:

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "your-api-key"
os.environ["LANGCHAIN_PROJECT"] = "my-langgraph-project"
```

Every graph invocation is traced and visible in the LangSmith UI, including:
- Node-by-node execution timeline
- Input/output at each node
- LLM calls with token counts and latency
- Tool calls and results

### LangGraph Studio

LangGraph Studio is a desktop IDE for visualizing and debugging graphs:
- Visual graph diagram updated in real time
- Step through execution node by node
- Inspect and edit state at any checkpoint
- Replay from any historical checkpoint
- Hot-reload graph code changes

### get_state and get_state_history

```python
# Current state
snapshot = graph.get_state(config)
print(snapshot.values)
print(snapshot.next)  # which node runs next

# Full history
for state in graph.get_state_history(config):
    print(state.config["configurable"]["checkpoint_id"])
```

---

## 15. Common Patterns

### ReAct Agent (Reason + Act)

The most common agentic pattern: the LLM reasons about what to do, calls a tool,
observes the result, and repeats until it has a final answer.

Loop: `agent → tools → agent → ... → END`

### Plan-and-Execute

1. **Planner node**: LLM generates a step-by-step plan
2. **Executor node**: executes one step at a time
3. **Replanner node**: updates the plan based on intermediate results
4. Repeat until the plan is complete

Better than ReAct for long-horizon tasks requiring multiple steps.

### Reflection / Self-Critique

1. **Generator node**: produce an initial draft/answer
2. **Critic node**: evaluate the draft and suggest improvements
3. **Loop back** to generator with feedback
4. Repeat N times or until quality threshold met

Improves output quality through iterative refinement.

---

## 16. Multimodal Inputs in Graph Nodes

LangGraph nodes can process any data type, including images, audio, and documents.

### Image input with vision models

```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

vision_llm = ChatOpenAI(model="gpt-4o")

def vision_node(state: MessagesState) -> dict:
    message = HumanMessage(content=[
        {"type": "text", "text": state["prompt"]},
        {"type": "image_url", "image_url": {"url": state["image_url"]}}
    ])
    response = vision_llm.invoke([message])
    return {"messages": [response]}
```

### Document processing

Use loader nodes to extract text from PDFs, HTML, or other formats before passing
to LLM nodes. Combine with retrieval nodes for RAG workflows.

### Audio / video

Pass base64-encoded audio or video URLs in message content for models that support
multimodal inputs. The graph structure remains the same — only the node
implementation changes.

---

## Summary

LangGraph provides all the primitives needed to build production-grade AI agents:

| Concept        | Purpose                                      |
|---------------|----------------------------------------------|
| Node          | Unit of computation                          |
| Edge          | Flow control between nodes                   |
| State         | Shared memory across nodes                   |
| Checkpointer  | Persistence and resumability                 |
| HITL          | Human oversight and intervention             |
| Streaming     | Real-time observability                      |
| Subgraphs     | Modularity and reuse                         |
| Multi-agent   | Collaboration between specialized agents     |
| ToolNode      | Automatic tool execution                     |
| LangSmith     | Tracing, debugging, and monitoring           |

Master these concepts and you can build any agentic application with LangGraph.