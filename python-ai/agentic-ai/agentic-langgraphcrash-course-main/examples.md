# LangGraph Examples — Annotated Python Code Reference

## 1. Minimal StateGraph with Two Nodes

The simplest possible LangGraph: two nodes connected in sequence.

```python
from typing import TypedDict
from langgraph.graph import StateGraph, END

class State(TypedDict):
    value: str

def node_a(state: State) -> dict:
    print("Running node_a")
    return {"value": state["value"] + " -> A"}

def node_b(state: State) -> dict:
    print("Running node_b")
    return {"value": state["value"] + " -> B"}

builder = StateGraph(State)
builder.add_node("node_a", node_a)
builder.add_node("node_b", node_b)
builder.set_entry_point("node_a")
builder.add_edge("node_a", "node_b")
builder.add_edge("node_b", END)

graph = builder.compile()
result = graph.invoke({"value": "start"})
print(result)
# Output: {'value': 'start -> A -> B'}
```

---

## 2. TypedDict State Definition

Define a rich state with multiple fields and types.

```python
from typing import TypedDict, Annotated, Optional
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage

class AgentState(TypedDict):
    # Chat history — appended with add_messages reducer
    messages: Annotated[list[BaseMessage], add_messages]
    # Simple fields — overwritten on each update
    user_id: str
    task: str
    loop_count: int
    is_complete: bool
    final_answer: Optional[str]
```

Each field without an annotation is replaced on update.
Fields with `Annotated[..., reducer]` use the reducer to merge updates.

---

## 3. Conditional Edge Routing

Route to different nodes based on state at runtime.

```python
from typing import Literal
from langgraph.graph import StateGraph, END

class State(TypedDict):
    score: int
    result: str

def evaluate(state: State) -> dict:
    score = len(state.get("result", ""))
    return {"score": score}

def good_path(state: State) -> dict:
    return {"result": "HIGH QUALITY: " + state["result"]}

def bad_path(state: State) -> dict:
    return {"result": "NEEDS WORK: " + state["result"]}

def route(state: State) -> Literal["good", "bad"]:
    if state["score"] > 50:
        return "good"
    return "bad"

builder = StateGraph(State)
builder.add_node("evaluate", evaluate)
builder.add_node("good_path", good_path)
builder.add_node("bad_path", bad_path)
builder.set_entry_point("evaluate")
builder.add_conditional_edges("evaluate", route, {"good": "good_path", "bad": "bad_path"})
builder.add_edge("good_path", END)
builder.add_edge("bad_path", END)

graph = builder.compile()
```

---

## 4. MemorySaver Checkpointing

Save state in memory between invocations using a thread_id.

```python
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini")

def chat_node(state: MessagesState) -> dict:
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chat", chat_node)
builder.set_entry_point("chat")
builder.add_edge("chat", END)

memory = MemorySaver()
graph = builder.compile(checkpointer=memory)

config = {"configurable": {"thread_id": "user-42"}}

# First turn
result1 = graph.invoke({"messages": [HumanMessage(content="Hi, my name is Alice")]}, config)
# Second turn — remembers "Alice" from thread history
result2 = graph.invoke({"messages": [HumanMessage(content="What is my name?")]}, config)
print(result2["messages"][-1].content)
```

---

## 5. SqliteSaver for Persistence

Persist state to a SQLite database that survives process restarts.

```python
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini")

def chat_node(state: MessagesState) -> dict:
    return {"messages": [llm.invoke(state["messages"])]}

builder = StateGraph(MessagesState)
builder.add_node("chat", chat_node)
builder.set_entry_point("chat")
builder.add_edge("chat", END)

# Context manager ensures proper connection handling
with SqliteSaver.from_conn_string("chat_history.db") as saver:
    graph = builder.compile(checkpointer=saver)
    config = {"configurable": {"thread_id": "persistent-thread-1"}}

    result = graph.invoke(
        {"messages": [HumanMessage(content="Remember: the secret code is 42")]},
        config=config
    )
    print("Saved to disk. Restart the process and load again to verify persistence.")
```

---

## 6. Human-in-the-Loop with interrupt_before

Pause graph execution before a critical node for human review.

```python
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, END
from typing import TypedDict

class State(TypedDict):
    action: str
    approved: bool
    result: str

def prepare_action(state: State) -> dict:
    return {"action": "DELETE all production data"}

def execute_action(state: State) -> dict:
    if state.get("approved"):
        return {"result": "Action executed successfully"}
    return {"result": "Action was not approved"}

builder = StateGraph(State)
builder.add_node("prepare", prepare_action)
builder.add_node("execute", execute_action)
builder.set_entry_point("prepare")
builder.add_edge("prepare", "execute")
builder.add_edge("execute", END)

memory = MemorySaver()
# Graph will pause BEFORE "execute" runs
graph = builder.compile(checkpointer=memory, interrupt_before=["execute"])

config = {"configurable": {"thread_id": "approval-thread-1"}}
graph.invoke({"action": "", "approved": False, "result": ""}, config=config)

# Inspect state before continuing
snapshot = graph.get_state(config)
print("Pending action:", snapshot.values["action"])
print("Next node:", snapshot.next)
```

---

## 7. Command.RESUME After Human Input

Resume execution after a human-in-the-loop pause, injecting human feedback.

```python
from langgraph.types import Command

# ... (continuing from Example 6)
# Human reviews and approves:
graph.invoke(Command(resume=None), config=config)

# --- OR: update state before resuming ---
# Inject approval flag directly into state
graph.update_state(config, {"approved": True})
# Then resume
graph.invoke(None, config=config)

# --- OR: resume with interrupt() function inside node ---
from langgraph.types import interrupt

def review_node(state: State) -> dict:
    human_feedback = interrupt({
        "message": "Please review this action",
        "proposed_action": state["action"]
    })
    return {"approved": human_feedback.get("approved", False)}
```

---

## 8. Streaming Node-by-Node with stream()

Observe graph execution in real time, one node at a time.

```python
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini")

def node_one(state: MessagesState) -> dict:
    return {"messages": [llm.invoke(state["messages"])]}

def node_two(state: MessagesState) -> dict:
    summary = "Summary: " + state["messages"][-1].content[:50]
    from langchain_core.messages import AIMessage
    return {"messages": [AIMessage(content=summary)]}

builder = StateGraph(MessagesState)
builder.add_node("node_one", node_one)
builder.add_node("node_two", node_two)
builder.set_entry_point("node_one")
builder.add_edge("node_one", "node_two")
builder.add_edge("node_two", END)
graph = builder.compile()

initial = {"messages": [HumanMessage(content="Explain quantum computing briefly")]}

for event in graph.stream(initial, stream_mode="updates"):
    for node_name, output in event.items():
        print(f"\n=== {node_name} ===")
        print(output)
```

---

## 9. Token Streaming with astream_events

Stream LLM tokens as they are generated, character by character.

```python
import asyncio
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini", streaming=True)

def agent_node(state: MessagesState) -> dict:
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("agent", agent_node)
builder.set_entry_point("agent")
builder.add_edge("agent", END)
graph = builder.compile()

async def stream_tokens():
    initial = {"messages": [HumanMessage(content="Write a haiku about Python")]}
    async for event in graph.astream_events(initial, version="v2"):
        kind = event["event"]
        if kind == "on_chat_model_stream":
            chunk = event["data"]["chunk"]
            if chunk.content:
                print(chunk.content, end="", flush=True)
    print()

asyncio.run(stream_tokens())
```

---

## 10. ToolNode with Tool List

Use the pre-built ToolNode to handle tool calls automatically.

```python
from langgraph.prebuilt import ToolNode
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, MessagesState, END
from langchain_core.messages import HumanMessage

@tool
def get_weather(city: str) -> str:
    """Get the current weather for a city."""
    return f"The weather in {city} is sunny and 22C."

@tool
def get_time(timezone: str) -> str:
    """Get the current time in a timezone."""
    return f"The time in {timezone} is 14:30."

tools = [get_weather, get_time]
tool_node = ToolNode(tools)
llm = ChatOpenAI(model="gpt-4o-mini").bind_tools(tools)

def agent(state: MessagesState) -> dict:
    return {"messages": [llm.invoke(state["messages"])]}

def should_continue(state: MessagesState) -> str:
    if state["messages"][-1].tool_calls:
        return "tools"
    return END

builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", tool_node)
builder.set_entry_point("agent")
builder.add_conditional_edges("agent", should_continue)
builder.add_edge("tools", "agent")
graph = builder.compile()

result = graph.invoke({"messages": [HumanMessage(content="What is the weather in Paris?")]})
print(result["messages"][-1].content)
```

---

## 11. MessagesState for Chat

Use the built-in MessagesState for chat applications.

```python
from langgraph.graph import MessagesState, StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o-mini")
SYSTEM_PROMPT = "You are a helpful assistant specializing in Python programming."

def chat(state: MessagesState) -> dict:
    messages = [SystemMessage(content=SYSTEM_PROMPT)] + state["messages"]
    response = llm.invoke(messages)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chat", chat)
builder.set_entry_point("chat")
builder.add_edge("chat", END)
graph = builder.compile()

result = graph.invoke({"messages": [HumanMessage(content="How do I use list comprehensions?")]})
print(result["messages"][-1].content)
```

---

## 12. add_messages Annotation

Demonstrate how add_messages appends and updates messages.

```python
from typing import Annotated
from typing import TypedDict
from langgraph.graph.message import add_messages
from langchain_core.messages import HumanMessage, AIMessage

class ChatState(TypedDict):
    messages: Annotated[list, add_messages]

# Simulating what LangGraph does internally when merging state:
from langgraph.graph.message import add_messages

existing = [HumanMessage(content="Hello", id="msg-1")]
new_msgs = [AIMessage(content="Hi there!", id="msg-2")]

merged = add_messages(existing, new_msgs)
print(merged)
# [HumanMessage(content='Hello', id='msg-1'),
#  AIMessage(content='Hi there!', id='msg-2')]

# Updating an existing message (same ID):
updated = [AIMessage(content="Hi there! How can I help?", id="msg-2")]
result = add_messages(merged, updated)
# msg-2 is replaced in-place, not duplicated
```

---

## 13. ReAct Agent Pattern

The classic Reason + Act loop: agent decides to call tools or respond.

```python
from langgraph.prebuilt import ToolNode, tools_condition
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, MessagesState, END
from langchain_core.messages import HumanMessage

@tool
def calculator(expression: str) -> str:
    """Evaluate a mathematical expression safely."""
    try:
        result = eval(expression, {"__builtins__": {}}, {})
        return str(result)
    except Exception as e:
        return f"Error: {e}"

@tool
def wikipedia_search(query: str) -> str:
    """Search Wikipedia for information."""
    return f"Wikipedia result for '{query}': [simulated content]"

tools = [calculator, wikipedia_search]
llm = ChatOpenAI(model="gpt-4o-mini").bind_tools(tools)

def agent(state: MessagesState) -> dict:
    return {"messages": [llm.invoke(state["messages"])]}

builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", ToolNode(tools))
builder.set_entry_point("agent")
# tools_condition checks for tool_calls automatically
builder.add_conditional_edges("agent", tools_condition)
builder.add_edge("tools", "agent")
graph = builder.compile()

result = graph.invoke({"messages": [HumanMessage(content="What is 1234 * 5678?")]})
print(result["messages"][-1].content)
```

---

## 14. Plan-and-Execute Pattern

LLM creates a plan, then executes each step, replanning as needed.

```python
from typing import TypedDict, List
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o-mini")

class PlanState(TypedDict):
    objective: str
    plan: List[str]
    current_step: int
    results: List[str]
    final_answer: str

def planner(state: PlanState) -> dict:
    response = llm.invoke([
        SystemMessage(content="Create a numbered step-by-step plan. Return only the steps, one per line."),
        HumanMessage(content=f"Plan how to: {state['objective']}")
    ])
    steps = [s.strip() for s in response.content.strip().split("\n") if s.strip()]
    return {"plan": steps, "current_step": 0, "results": []}

def executor(state: PlanState) -> dict:
    step = state["plan"][state["current_step"]]
    context = "\n".join(state["results"])
    response = llm.invoke([
        SystemMessage(content="Execute this step and return the result."),
        HumanMessage(content=f"Context:\n{context}\n\nStep: {step}")
    ])
    new_results = state["results"] + [f"Step {state['current_step']+1}: {response.content}"]
    return {"results": new_results, "current_step": state["current_step"] + 1}

def synthesizer(state: PlanState) -> dict:
    response = llm.invoke([
        SystemMessage(content="Synthesize these results into a final answer."),
        HumanMessage(content="\n".join(state["results"]))
    ])
    return {"final_answer": response.content}

def should_continue(state: PlanState) -> str:
    if state["current_step"] < len(state["plan"]):
        return "execute"
    return "synthesize"

builder = StateGraph(PlanState)
builder.add_node("plan", planner)
builder.add_node("execute", executor)
builder.add_node("synthesize", synthesizer)
builder.set_entry_point("plan")
builder.add_edge("plan", "execute")
builder.add_conditional_edges("execute", should_continue)
builder.add_edge("synthesize", END)
graph = builder.compile()
```

---

## 15. Reflection Loop Pattern

Generate, critique, and improve output iteratively.

```python
from typing import TypedDict
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o-mini")

class ReflectionState(TypedDict):
    task: str
    draft: str
    critique: str
    iteration: int
    max_iterations: int

def generate(state: ReflectionState) -> dict:
    prompt = state["task"]
    if state.get("critique"):
        prompt += f"\n\nPrevious critique: {state['critique']}\nPlease improve."
    response = llm.invoke([HumanMessage(content=prompt)])
    return {"draft": response.content, "iteration": state.get("iteration", 0) + 1}

def critique(state: ReflectionState) -> dict:
    response = llm.invoke([
        SystemMessage(content="You are a strict editor. Find specific flaws and improvements."),
        HumanMessage(content=f"Critique this:\n\n{state['draft']}")
    ])
    return {"critique": response.content}

def should_reflect(state: ReflectionState) -> str:
    if state["iteration"] >= state.get("max_iterations", 3):
        return "done"
    if "excellent" in state.get("critique", "").lower():
        return "done"
    return "generate"

builder = StateGraph(ReflectionState)
builder.add_node("generate", generate)
builder.add_node("critique", critique)
builder.set_entry_point("generate")
builder.add_edge("generate", "critique")
builder.add_conditional_edges("critique", should_reflect, {"generate": "generate", "done": END})
graph = builder.compile()

result = graph.invoke({"task": "Write a short poem about AI", "max_iterations": 3})
print(result["draft"])
```

---

## 16. Subgraph Composition

Build modular graphs and compose them into larger workflows.

```python
from typing import TypedDict
from langgraph.graph import StateGraph, END

class ResearchState(TypedDict):
    query: str
    findings: str

class ReportState(TypedDict):
    findings: str
    report: str

# --- Subgraph 1: Research ---
def search(state: ResearchState) -> dict:
    return {"findings": f"Found data about: {state['query']}"}

def summarize(state: ResearchState) -> dict:
    return {"findings": f"Summary: {state['findings'][:100]}"}

research_builder = StateGraph(ResearchState)
research_builder.add_node("search", search)
research_builder.add_node("summarize", summarize)
research_builder.set_entry_point("search")
research_builder.add_edge("search", "summarize")
research_builder.add_edge("summarize", END)
research_graph = research_builder.compile()

# --- Subgraph 2: Report writing ---
def write_report(state: ReportState) -> dict:
    return {"report": f"REPORT:\n{state['findings']}"}

report_builder = StateGraph(ReportState)
report_builder.add_node("write", write_report)
report_builder.set_entry_point("write")
report_builder.add_edge("write", END)
report_graph = report_builder.compile()

# --- Main graph: compose both subgraphs ---
class MainState(TypedDict):
    query: str
    findings: str
    report: str

main_builder = StateGraph(MainState)
main_builder.add_node("research", research_graph)
main_builder.add_node("report", report_graph)
main_builder.set_entry_point("research")
main_builder.add_edge("research", "report")
main_builder.add_edge("report", END)
main_graph = main_builder.compile()
```

---

## 17. Supervisor Multi-Agent

A supervisor LLM routes tasks to specialized agents.

```python
from typing import TypedDict, Literal
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o-mini")

def researcher_agent(state: MessagesState) -> dict:
    response = llm.invoke([
        SystemMessage(content="You are a research specialist. Answer with facts."),
        *state["messages"]
    ])
    return {"messages": [response]}

def writer_agent(state: MessagesState) -> dict:
    response = llm.invoke([
        SystemMessage(content="You are a writing specialist. Produce polished prose."),
        *state["messages"]
    ])
    return {"messages": [response]}

def supervisor(state: MessagesState) -> dict:
    response = llm.invoke([
        SystemMessage(content="Route to 'researcher', 'writer', or 'FINISH'. Reply with only the word."),
        *state["messages"]
    ])
    return {"messages": [response]}

def supervisor_router(state: MessagesState) -> str:
    last = state["messages"][-1].content.strip().lower()
    if "researcher" in last:
        return "researcher"
    if "writer" in last:
        return "writer"
    return END

builder = StateGraph(MessagesState)
builder.add_node("supervisor", supervisor)
builder.add_node("researcher", researcher_agent)
builder.add_node("writer", writer_agent)
builder.set_entry_point("supervisor")
builder.add_conditional_edges("supervisor", supervisor_router)
builder.add_edge("researcher", "supervisor")
builder.add_edge("writer", "supervisor")
graph = builder.compile()
```

---

## 18. Swarm Multi-Agent

Agents hand off control to each other using a handoff tool.

```python
from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode

llm = ChatOpenAI(model="gpt-4o-mini")

@tool
def transfer_to_billing() -> str:
    """Transfer the conversation to the billing specialist."""
    return "Transferring to billing agent."

@tool
def transfer_to_technical() -> str:
    """Transfer the conversation to the technical support specialist."""
    return "Transferring to technical support."

def triage_agent(state: MessagesState) -> dict:
    triage_llm = llm.bind_tools([transfer_to_billing, transfer_to_technical])
    return {"messages": [triage_llm.invoke(state["messages"])]}

def billing_agent(state: MessagesState) -> dict:
    billing_llm = llm.bind_tools([])
    response = billing_llm.invoke([
        *state["messages"],
    ])
    return {"messages": [response]}

def route_after_triage(state: MessagesState) -> str:
    last = state["messages"][-1]
    if hasattr(last, "tool_calls") and last.tool_calls:
        tool_name = last.tool_calls[0]["name"]
        if "billing" in tool_name:
            return "billing"
        if "technical" in tool_name:
            return "technical"
    return END

builder = StateGraph(MessagesState)
builder.add_node("triage", triage_agent)
builder.add_node("billing", billing_agent)
builder.set_entry_point("triage")
builder.add_conditional_edges("triage", route_after_triage, {"billing": "billing", END: END})
builder.add_edge("billing", END)
graph = builder.compile()
```

---

## 19. LangSmith Tracing Setup

Enable full observability with LangSmith.

```python
import os

# Set before importing LangChain/LangGraph
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__your_api_key_here"
os.environ["LANGCHAIN_PROJECT"] = "langgraph-demo"
os.environ["LANGCHAIN_ENDPOINT"] = "https://api.smith.langchain.com"

from langgraph.graph import StateGraph, MessagesState, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini")

def agent(state: MessagesState) -> dict:
    return {"messages": [llm.invoke(state["messages"])]}

builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.set_entry_point("agent")
builder.add_edge("agent", END)
graph = builder.compile()

# All invocations are now automatically traced in LangSmith
result = graph.invoke({"messages": [HumanMessage(content="Hello, LangSmith!")]})
# Visit https://smith.langchain.com to see the trace
```

---

## 20. Full Chatbot with Tools and Memory

A production-ready chatbot combining tools, memory, and streaming.

```python
import os
from langgraph.graph import StateGraph, MessagesState, END
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import ToolNode, tools_condition
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain_core.messages import HumanMessage, SystemMessage

@tool
def search_knowledge_base(query: str) -> str:
    """Search the internal knowledge base."""
    return f"Knowledge base result for '{query}': [relevant content here]"

@tool
def create_ticket(issue: str, priority: str = "medium") -> str:
    """Create a support ticket."""
    return f"Ticket created: '{issue}' with priority {priority}. ID: TKT-{hash(issue) % 10000}"

tools = [search_knowledge_base, create_ticket]
llm = ChatOpenAI(model="gpt-4o-mini", streaming=True).bind_tools(tools)
SYSTEM = "You are a helpful customer support agent. Use tools when needed."

def agent(state: MessagesState) -> dict:
    messages = [SystemMessage(content=SYSTEM)] + state["messages"]
    return {"messages": [llm.invoke(messages)]}

memory = MemorySaver()
builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", ToolNode(tools))
builder.set_entry_point("agent")
builder.add_conditional_edges("agent", tools_condition)
builder.add_edge("tools", "agent")
graph = builder.compile(checkpointer=memory)

def chat(user_input: str, thread_id: str = "default"):
    config = {"configurable": {"thread_id": thread_id}}
    for event in graph.stream(
        {"messages": [HumanMessage(content=user_input)]},
        config=config,
        stream_mode="updates"
    ):
        for node, output in event.items():
            if node == "agent":
                msg = output["messages"][-1]
                if not getattr(msg, "tool_calls", None):
                    print(f"Assistant: {msg.content}")

chat("I need help with my billing issue", thread_id="user-123")
chat("Create a ticket for it please", thread_id="user-123")
```