# AutoGen — Comprehensive Guide for Software Developers

> **Target:** Multi-agent AI systems that write, execute, and debug code autonomously.
> **Versions covered:** AutoGen 0.2 (`pyautogen`) and AutoGen 0.4 (`autogen-agentchat`)

---

## Table of Contents

1. [What is AutoGen?](#1-what-is-autogen)
2. [Installation & Setup](#2-installation--setup)
3. [Core Agent Types](#3-core-agent-types)
4. [Two-Agent Conversation](#4-two-agent-conversation)
5. [Group Chat](#5-group-chat)
6. [Code Execution](#6-code-execution)
7. [Nested Chats (AutoGen 0.2)](#7-nested-chats-autogen-02)
8. [Function / Tool Calling](#8-function--tool-calling)
9. [AutoGen 0.4 — AgentChat API](#9-autogen-04--agentchat-api)
10. [Memory & Context](#10-memory--context)
11. [Real-World Patterns](#11-real-world-patterns)
12. [Teachable Agents](#12-teachable-agents)
13. [AutoGen Studio](#13-autogen-studio)
14. [Interview Q&A](#14-interview-qa-15-questions)
15. [Complete End-to-End Example](#15-complete-end-to-end-example)

---

## 1. What is AutoGen?

**AutoGen** is Microsoft's open-source multi-agent conversational framework. Unlike frameworks that only chain LLM prompts, AutoGen enables agents to **write code, execute it, observe the result, and iterate** — closing the loop autonomously.

### Key Differentiator: Write AND Execute

```
User task → AssistantAgent writes Python → UserProxyAgent runs it
         ← Result returned to AssistantAgent → fix if needed → loop
```

Most LLM frameworks stop at text generation. AutoGen adds a live execution layer, making it uniquely powerful for:
- Data analysis tasks
- Software engineering automation
- Scientific computing
- DevOps scripting

### AutoGen 0.2 vs 0.4 (AgentChat)

| Feature | AutoGen 0.2 (`pyautogen`) | AutoGen 0.4 (`autogen-agentchat`) |
|---|---|---|
| API style | Imperative, synchronous | Async-first, event-driven |
| Group chat | `GroupChat` + `GroupChatManager` | `RoundRobinGroupChat`, `SelectorGroupChat` |
| Tool calling | `register_for_llm` / `register_for_execution` | `FunctionTool`, `tools=` param |
| Code execution | `code_execution_config` dict | `CodeExecutorAgent` |
| Streaming | Limited | Built-in `MessageStream` |
| Teachable | `TeachableAgent` class | In progress |
| Stability | Stable, widely used | New architecture (recommended for new projects) |

**Rule of thumb:** Use 0.2 for production systems today; use 0.4 for new projects targeting 2025+.

### When to Use AutoGen vs Alternatives

| Use Case | Best Tool |
|---|---|
| Code generation + execution loop | **AutoGen** |
| Role-based agent crews with tasks | **CrewAI** |
| Complex conditional workflows / DAGs | **LangGraph** |
| Simple single-agent RAG chatbot | **LangChain** |
| Structured data extraction pipelines | **LangGraph or Instructor** |

AutoGen's **code executor** is its superpower. If your workflow needs agents that actually *run* code, AutoGen wins.

---

## 2. Installation & Setup

### Install AutoGen 0.2

```bash
pip install pyautogen
# With extras
pip install pyautogen[teachable]   # Teachable agents (requires chromadb)
pip install pyautogen[jupyter]     # Jupyter code executor
pip install pyautogen[docker]      # Docker code executor
```

### Install AutoGen 0.4

```bash
pip install autogen-agentchat autogen-ext[openai]
```

### LLM Config — Standard OpenAI

```python
# autogen_setup.py
import os

config_list = [
    {
        "model": "gpt-4o",
        "api_key": os.environ["OPENAI_API_KEY"],
    }
]

llm_config = {
    "config_list": config_list,
    "temperature": 0,
    "timeout": 120,
    "cache_seed": 42,  # deterministic caching; set None to disable
}
```

### LLM Config — GitHub Copilot Free Auth (Azure Inference)

```python
# github_copilot_config.py
import subprocess

def get_github_token() -> str:
    result = subprocess.run(
        ["gh", "auth", "token"],
        capture_output=True,
        text=True,
    )
    token = result.stdout.strip()
    if not token:
        raise RuntimeError("Not logged in. Run: gh auth login")
    return token

token = get_github_token()

config_list = [
    {
        "model": "gpt-4o",
        "api_key": token,
        "base_url": "https://models.inference.ai.azure.com",
    }
]

llm_config = {"config_list": config_list, "temperature": 0}
```

### LLM Config — Local Ollama

```python
# ollama_config.py
config_list = [
    {
        "model": "ollama/llama3.2",
        "base_url": "http://localhost:11434/v1",
        "api_key": "ollama",  # required but ignored by Ollama
    }
]

llm_config = {"config_list": config_list, "temperature": 0}
```

### Config from JSON file

```python
# Load from OAI_CONFIG_LIST file
import autogen

config_list = autogen.config_list_from_json(
    "OAI_CONFIG_LIST",
    filter_dict={"model": ["gpt-4o", "gpt-4"]},
)
```

`OAI_CONFIG_LIST` example:
```json
[
  {"model": "gpt-4o", "api_key": "sk-..."},
  {"model": "gpt-3.5-turbo", "api_key": "sk-..."}
]
```

---

## 3. Core Agent Types

### AssistantAgent

LLM-powered agent. Generates text, writes code, plans tasks. Does **not** execute code by default.

```python
import autogen

llm_config = {"config_list": [{"model": "gpt-4o", "api_key": "YOUR_KEY"}]}

assistant = autogen.AssistantAgent(
    name="assistant",
    llm_config=llm_config,
    system_message="""You are a senior Python developer.
    Write clean, well-documented code.
    Always include error handling.
    Reply TERMINATE when the task is complete.""",
    max_consecutive_auto_reply=10,
)
```

### UserProxyAgent

Represents a human or execution environment. Can execute code, request human input, or run fully autonomously.

```python
user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",        # NEVER | TERMINATE | ALWAYS
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={
        "work_dir": "workspace",
        "use_docker": False,
    },
)
```

### ConversableAgent — Base Class

Both `AssistantAgent` and `UserProxyAgent` inherit from `ConversableAgent`. Use it for full control:

```python
custom_agent = autogen.ConversableAgent(
    name="custom_reviewer",
    system_message="You are a strict code reviewer. Be concise.",
    llm_config=llm_config,
    human_input_mode="NEVER",
    is_termination_msg=lambda msg: msg.get("content", "").endswith("LGTM"),
    max_consecutive_auto_reply=5,
    default_auto_reply="Please continue.",
)
```

### Key Configuration Parameters

| Parameter | Type | Description |
|---|---|---|
| `name` | str | Unique agent identifier |
| `system_message` | str | LLM persona/instructions |
| `llm_config` | dict \| False | LLM settings; `False` disables LLM |
| `human_input_mode` | str | `NEVER`, `TERMINATE`, `ALWAYS` |
| `max_consecutive_auto_reply` | int | Stops infinite loops |
| `is_termination_msg` | callable | Lambda to detect stop signal |
| `code_execution_config` | dict \| False | Code runner settings |

---

## 4. Two-Agent Conversation

The simplest and most common AutoGen pattern: one agent writes code, the other executes it.

```python
# two_agent_chat.py
import autogen
import os

# --- Config ---
config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

# --- Agents ---
assistant = autogen.AssistantAgent(
    name="assistant",
    llm_config=llm_config,
    system_message="""You are a Python developer.
    Write Python code to solve tasks.
    Put all code in a single ```python code block.
    Reply TERMINATE when the task is complete and tests pass.""",
)

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=8,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={
        "work_dir": "workspace",
        "use_docker": False,
    },
)

# --- Start conversation ---
user_proxy.initiate_chat(
    assistant,
    message="""
    Write a Python function called `fibonacci(n)` that returns the nth Fibonacci number.
    Then write 5 unit tests for it using pytest and run them to confirm they pass.
    """,
)
```

### human_input_mode Options

```python
# NEVER — fully autonomous, never pauses for human input
user_proxy = autogen.UserProxyAgent(
    name="auto_proxy",
    human_input_mode="NEVER",
    ...
)

# TERMINATE — only asks human when is_termination_msg is True
user_proxy = autogen.UserProxyAgent(
    name="supervised_proxy",
    human_input_mode="TERMINATE",
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    ...
)

# ALWAYS — asks human to review every single message
user_proxy = autogen.UserProxyAgent(
    name="manual_proxy",
    human_input_mode="ALWAYS",
    ...
)
```

### Custom Termination Condition

```python
def should_stop(message: dict) -> bool:
    content = message.get("content", "") or ""
    return (
        "TERMINATE" in content
        or "task complete" in content.lower()
        or "all tests passed" in content.lower()
    )

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    is_termination_msg=should_stop,
    max_consecutive_auto_reply=15,
    code_execution_config={"work_dir": "workspace", "use_docker": False},
)
```

---

## 5. Group Chat

Multiple agents collaborating in a shared conversation thread.

### Basic Group Chat

```python
# group_chat_team.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

# --- Define agents ---
pm = autogen.AssistantAgent(
    name="ProductManager",
    system_message="""You are a Product Manager.
    Break down feature requests into clear engineering tasks.
    Be concise. After outlining tasks, say 'PM_DONE'.""",
    llm_config=llm_config,
)

developer = autogen.AssistantAgent(
    name="Developer",
    system_message="""You are a Senior Python Developer.
    Implement the tasks assigned by the PM.
    Write complete, runnable Python code in ```python blocks.""",
    llm_config=llm_config,
)

tester = autogen.AssistantAgent(
    name="Tester",
    system_message="""You are a QA Engineer.
    Write pytest unit tests for the developer's code.
    Cover edge cases. Put tests in ```python blocks.""",
    llm_config=llm_config,
)

reviewer = autogen.AssistantAgent(
    name="CodeReviewer",
    system_message="""You are a Code Reviewer.
    Review the developer's code and tests.
    Point out issues with: style, correctness, security, performance.
    If everything looks good, say 'LGTM - TERMINATE'.""",
    llm_config=llm_config,
)

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=0,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={"work_dir": "workspace", "use_docker": False},
)

# --- Group Chat setup ---
groupchat = autogen.GroupChat(
    agents=[user_proxy, pm, developer, tester, reviewer],
    messages=[],
    max_round=20,
    speaker_selection_method="auto",  # LLM picks who speaks next
)

manager = autogen.GroupChatManager(
    groupchat=groupchat,
    llm_config=llm_config,
)

# --- Start ---
user_proxy.initiate_chat(
    manager,
    message="Build a Python utility class `Stack` with push, pop, peek, is_empty methods.",
)
```

### Speaker Selection Strategies

```python
# auto — GroupChatManager's LLM decides who speaks next (default)
groupchat = autogen.GroupChat(
    agents=agents,
    messages=[],
    max_round=15,
    speaker_selection_method="auto",
)

# round_robin — agents take turns in order
groupchat = autogen.GroupChat(
    agents=agents,
    messages=[],
    max_round=15,
    speaker_selection_method="round_robin",
)

# random — random selection each round
groupchat = autogen.GroupChat(
    agents=agents,
    messages=[],
    max_round=15,
    speaker_selection_method="random",
)

# manual — human picks next speaker in terminal
groupchat = autogen.GroupChat(
    agents=agents,
    messages=[],
    max_round=15,
    speaker_selection_method="manual",
)
```

### Custom Speaker Selection Function

```python
def custom_speaker_selector(last_speaker, groupchat):
    messages = groupchat.messages
    if not messages:
        return pm
    last_name = last_speaker.name
    order = {"ProductManager": developer, "Developer": tester,
             "Tester": reviewer, "CodeReviewer": user_proxy}
    return order.get(last_name, pm)

groupchat = autogen.GroupChat(
    agents=[user_proxy, pm, developer, tester, reviewer],
    messages=[],
    max_round=12,
    speaker_selection_method=custom_speaker_selector,
)
```

---

## 6. Code Execution

### LocalCommandLineCodeExecutor (0.2 style)

```python
# local_executor.py
import autogen

user_proxy = autogen.UserProxyAgent(
    name="executor",
    human_input_mode="NEVER",
    code_execution_config={
        "work_dir": "agent_workspace",   # code files written here
        "use_docker": False,
        "timeout": 60,                   # seconds before timeout
        "last_n_messages": 3,            # look back N messages for code
    },
)
```

### DockerCommandLineCodeExecutor (Isolated)

```python
# docker_executor.py
import autogen

user_proxy = autogen.UserProxyAgent(
    name="docker_executor",
    human_input_mode="NEVER",
    code_execution_config={
        "work_dir": "agent_workspace",
        "use_docker": "python:3.11-slim",  # Docker image to use
        "timeout": 120,
    },
)
```

### LocalCommandLineCodeExecutor (0.4 style)

```python
# executor_v04.py
import asyncio
from autogen_agentchat.agents import CodeExecutorAgent, AssistantAgent
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor
from autogen_ext.models.openai import OpenAIChatCompletionClient
import os

async def main():
    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=os.environ["OPENAI_API_KEY"],
    )

    executor = LocalCommandLineCodeExecutor(work_dir="agent_workspace")
    code_executor_agent = CodeExecutorAgent(
        name="code_executor",
        code_executor=executor,
    )

    assistant = AssistantAgent(
        name="assistant",
        model_client=model_client,
        system_message="Write Python code to answer tasks. Use ```python blocks.",
    )

asyncio.run(main())
```

### Full Example: Data Analysis Agent

```python
# data_analysis_agent.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]

analyst = autogen.AssistantAgent(
    name="DataAnalyst",
    llm_config={"config_list": config_list, "temperature": 0},
    system_message="""You are a data analyst expert in Python and pandas.
    When given a task:
    1. Write complete Python code using pandas, matplotlib, or seaborn.
    2. Include all imports.
    3. Save plots to files (plt.savefig) instead of plt.show().
    4. Print summary statistics.
    5. Say TERMINATE when analysis is complete.""",
)

executor = autogen.UserProxyAgent(
    name="executor",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={
        "work_dir": "analysis_workspace",
        "use_docker": False,
        "timeout": 90,
    },
)

executor.initiate_chat(
    analyst,
    message="""
    Create a sample sales dataset with 100 rows (product, region, sales, month).
    Then:
    1. Calculate total sales by product
    2. Calculate average sales by region
    3. Find the top 3 months by total sales
    4. Print all results clearly
    """,
)
```

---

## 7. Nested Chats (AutoGen 0.2)

Nested chats allow an agent to spawn a sub-conversation triggered by a condition, then return the result to the parent chat.

```python
# nested_chat.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

# Main agents
coordinator = autogen.AssistantAgent(
    name="Coordinator",
    system_message="""You coordinate software development.
    When you receive a task needing deep technical analysis,
    write: ANALYZE: <task description>
    Otherwise handle it directly. Say TERMINATE when done.""",
    llm_config=llm_config,
)

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={"work_dir": "workspace", "use_docker": False},
)

# Sub-conversation agents (for deep analysis)
deep_analyst = autogen.AssistantAgent(
    name="DeepAnalyst",
    system_message="""You perform deep technical analysis.
    Provide detailed breakdown with code examples.
    End with ANALYSIS_COMPLETE.""",
    llm_config=llm_config,
)

analysis_proxy = autogen.UserProxyAgent(
    name="analysis_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=5,
    is_termination_msg=lambda msg: "ANALYSIS_COMPLETE" in msg.get("content", ""),
    code_execution_config=False,
)

# Register nested chat: triggered when message contains "ANALYZE:"
def trigger_analysis(msg):
    return "ANALYZE:" in msg.get("content", "")

def compose_analysis_message(msg, sender):
    content = msg.get("content", "")
    task = content.split("ANALYZE:")[-1].strip()
    return f"Please perform a deep technical analysis of: {task}"

user_proxy.register_nested_chats(
    [
        {
            "recipient": analysis_proxy,
            "sender": analysis_proxy,
            "message": compose_analysis_message,
            "summary_method": "last_msg",
            "max_turns": 4,
        }
    ],
    trigger=trigger_analysis,
)

user_proxy.initiate_chat(
    coordinator,
    message="We need to build a REST API with authentication. What's the best approach?",
)
```

### Nested Chat — Direct Pattern

```python
# Simpler: directly initiate a nested chat
result = analysis_proxy.initiate_chat(
    deep_analyst,
    message="Analyze the performance implications of using async/await in Python FastAPI.",
    max_turns=4,
    summary_method="last_msg",
)
print("Sub-chat summary:", result.summary)
```

---

## 8. Function / Tool Calling

AutoGen supports registering Python functions as tools that agents can call via the LLM's function-calling interface.

```python
# tool_calling.py
import autogen
import os
import json
import math
from datetime import datetime

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

assistant = autogen.AssistantAgent(
    name="tool_assistant",
    llm_config=llm_config,
    system_message="""You are a helpful assistant with access to tools.
    Use tools when appropriate to answer user questions accurately.
    Say TERMINATE when the task is complete.""",
)

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config=False,  # disable code exec, use tools instead
)

# --- Define tools ---

@user_proxy.register_for_execution()
@assistant.register_for_llm(description="Calculate a mathematical expression")
def calculator(expression: str) -> str:
    """Safely evaluate a math expression."""
    try:
        allowed = {k: getattr(math, k) for k in dir(math) if not k.startswith("_")}
        result = eval(expression, {"__builtins__": {}}, allowed)
        return f"Result: {result}"
    except Exception as e:
        return f"Error: {e}"

@user_proxy.register_for_execution()
@assistant.register_for_llm(description="Get the current date and time")
def get_current_datetime() -> str:
    """Return the current date and time."""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

@user_proxy.register_for_execution()
@assistant.register_for_llm(description="Write text content to a file")
def write_file(filename: str, content: str) -> str:
    """Write content to a file in the workspace directory."""
    try:
        path = os.path.join("workspace", filename)
        os.makedirs("workspace", exist_ok=True)
        with open(path, "w") as f:
            f.write(content)
        return f"Successfully wrote {len(content)} characters to {path}"
    except Exception as e:
        return f"Error writing file: {e}"

@user_proxy.register_for_execution()
@assistant.register_for_llm(description="Read the contents of a file")
def read_file(filename: str) -> str:
    """Read and return the contents of a file."""
    try:
        path = os.path.join("workspace", filename)
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return f"File not found: {filename}"
    except Exception as e:
        return f"Error reading file: {e}"

# --- Run ---
user_proxy.initiate_chat(
    assistant,
    message="""
    1. What is the current date and time?
    2. Calculate: sqrt(144) + pow(2, 10)
    3. Write a file called 'report.txt' with a summary of those results.
    """,
)
```

### Tool Registration via llm_config (Alternative)

```python
# tools_via_config.py
tools = [
    {
        "type": "function",
        "function": {
            "name": "search_web",
            "description": "Search the web for information",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "max_results": {"type": "integer", "default": 5},
                },
                "required": ["query"],
            },
        },
    }
]

llm_config_with_tools = {
    "config_list": config_list,
    "temperature": 0,
    "tools": tools,
}
```

---

## 9. AutoGen 0.4 — AgentChat API

AutoGen 0.4 introduces a cleaner, async-first API with improved composability.

```python
# autogen_v04_example.py
import asyncio
import os
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.teams import RoundRobinGroupChat, SelectorGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def two_agent_example():
    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=os.environ["OPENAI_API_KEY"],
    )

    assistant = AssistantAgent(
        name="assistant",
        model_client=model_client,
        system_message="Solve tasks step by step. Say TERMINATE when done.",
    )

    user_proxy = UserProxyAgent(name="user_proxy")

    termination = TextMentionTermination("TERMINATE")

    team = RoundRobinGroupChat(
        participants=[assistant, user_proxy],
        termination_condition=termination,
        max_turns=10,
    )

    await Console(team.run_stream(task="Write a Python function to check if a number is prime."))

async def selector_group_chat_example():
    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=os.environ["OPENAI_API_KEY"],
    )

    planner = AssistantAgent(
        name="Planner",
        model_client=model_client,
        system_message="Plan the solution. Delegate to Coder and Tester.",
    )

    coder = AssistantAgent(
        name="Coder",
        model_client=model_client,
        system_message="Write Python code based on the plan.",
    )

    tester = AssistantAgent(
        name="Tester",
        model_client=model_client,
        system_message="Write tests for the code. Say TERMINATE when tests pass.",
    )

    termination = TextMentionTermination("TERMINATE")

    team = SelectorGroupChat(
        participants=[planner, coder, tester],
        model_client=model_client,
        termination_condition=termination,
        max_turns=15,
    )

    await Console(
        team.run_stream(task="Build a Python class that manages a to-do list.")
    )

async def stream_messages_example():
    """Process message stream manually."""
    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=os.environ["OPENAI_API_KEY"],
    )
    assistant = AssistantAgent(
        name="assistant",
        model_client=model_client,
    )
    user_proxy = UserProxyAgent(name="user")

    termination = TextMentionTermination("TERMINATE")
    team = RoundRobinGroupChat(
        [assistant, user_proxy],
        termination_condition=termination,
        max_turns=6,
    )

    async for message in team.run_stream(task="What is 2+2? Say TERMINATE."):
        print(f"[{message.source}]: {message.content[:100]}")

if __name__ == "__main__":
    asyncio.run(two_agent_example())
```

### CancellationToken Usage

```python
# cancellation_example.py
import asyncio
from autogen_core import CancellationToken
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_ext.models.openai import OpenAIChatCompletionClient
import os

async def main():
    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=os.environ["OPENAI_API_KEY"],
    )
    agent = AssistantAgent("agent", model_client=model_client)
    proxy = AssistantAgent("proxy", model_client=model_client)
    team = RoundRobinGroupChat([agent, proxy], max_turns=20)

    cancellation_token = CancellationToken()

    # Cancel after 5 seconds
    async def cancel_after(seconds):
        await asyncio.sleep(seconds)
        cancellation_token.cancel()
        print("Task cancelled!")

    asyncio.create_task(cancel_after(5))

    try:
        result = await team.run(
            task="Count from 1 to 1000 slowly.",
            cancellation_token=cancellation_token,
        )
    except Exception as e:
        print(f"Cancelled: {e}")

asyncio.run(main())
```

---

## 10. Memory & Context

### Accessing Conversation History

```python
# memory_example.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list}

assistant = autogen.AssistantAgent("assistant", llm_config=llm_config)
user_proxy = autogen.UserProxyAgent(
    "user_proxy",
    human_input_mode="NEVER",
    code_execution_config=False,
    max_consecutive_auto_reply=3,
)

user_proxy.initiate_chat(assistant, message="What is the capital of France?")

# Access full chat history
history = user_proxy.chat_messages[assistant]
for msg in history:
    print(f"[{msg['role']}]: {msg['content'][:80]}")

# Get last N messages
last_3 = history[-3:]
```

### Clearing History Between Tasks

```python
# clear and reuse agents for a new task
user_proxy.clear_history(assistant)
assistant.clear_history(user_proxy)

user_proxy.initiate_chat(
    assistant,
    message="Now tell me about Python decorators.",
    clear_history=True,  # also clears at start of initiate_chat
)
```

### Manual Context Injection

```python
# Inject context into agent's message list before chatting
assistant.update_system_message(
    "You are a Python expert. Remember: project uses Python 3.11, FastAPI, PostgreSQL."
)

# Send initial context message
user_proxy.initiate_chat(
    assistant,
    message="How should I structure database models?",
    silent=False,
)
```

### Summarizing Long Conversations

```python
# Use summary_method in nested or two-agent chat
result = user_proxy.initiate_chat(
    assistant,
    message="Explain the entire history of Python from 1991 to now.",
    max_turns=5,
    summary_method="reflection_with_llm",  # LLM summarizes the chat
    summary_args={
        "summary_prompt": "Summarize the key points discussed in 3 bullet points."
    },
)
print("Summary:", result.summary)
```

---

## 11. Real-World Patterns

### Pattern 1: Code Generation + Test + Fix Loop

```python
# code_test_fix_loop.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

coder = autogen.AssistantAgent(
    name="Coder",
    system_message="""You write Python code.
    When tests fail, read the error and fix the code.
    When all tests pass, say TERMINATE.""",
    llm_config=llm_config,
)

executor = autogen.UserProxyAgent(
    name="Executor",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=15,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config={
        "work_dir": "workspace",
        "use_docker": False,
        "timeout": 60,
    },
)

executor.initiate_chat(
    coder,
    message="""
    Write a Python function `parse_date(date_str)` that:
    - Accepts strings like '2024-01-15', '15/01/2024', 'Jan 15 2024'
    - Returns a datetime.date object
    - Raises ValueError for invalid formats
    Then write and run pytest tests that verify all 3 formats work
    and that invalid input raises ValueError.
    Fix any failures automatically.
    """,
)
```

### Pattern 2: Multi-Agent Debate

```python
# debate_pattern.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0.3}

for_agent = autogen.AssistantAgent(
    name="Proponent",
    system_message="You strongly argue FOR the proposition. Be persuasive and cite evidence.",
    llm_config=llm_config,
)

against_agent = autogen.AssistantAgent(
    name="Opponent",
    system_message="You strongly argue AGAINST the proposition. Be persuasive and cite counter-evidence.",
    llm_config=llm_config,
)

judge = autogen.AssistantAgent(
    name="Judge",
    system_message="""You are an impartial judge.
    After hearing both sides, give a final verdict with reasoning.
    End with: VERDICT: [FOR/AGAINST/NEUTRAL] - TERMINATE""",
    llm_config=llm_config,
)

moderator = autogen.UserProxyAgent(
    name="Moderator",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=0,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config=False,
)

groupchat = autogen.GroupChat(
    agents=[moderator, for_agent, against_agent, judge],
    messages=[],
    max_round=8,
    speaker_selection_method="round_robin",
)

manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_config)

moderator.initiate_chat(
    manager,
    message="Debate topic: 'Microservices are always better than monoliths for modern applications.'",
)
```

### Pattern 3: Research Pipeline

```python
# research_pipeline.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

researcher = autogen.AssistantAgent(
    name="Researcher",
    system_message="""You research topics thoroughly using your training knowledge.
    Provide structured findings with key points.
    When research is done, say RESEARCH_DONE.""",
    llm_config=llm_config,
)

writer = autogen.AssistantAgent(
    name="Writer",
    system_message="""You transform research into polished reports.
    Structure: Executive Summary, Key Findings, Recommendations, Conclusion.
    After writing, say REPORT_DONE - TERMINATE.""",
    llm_config=llm_config,
)

coordinator = autogen.UserProxyAgent(
    name="coordinator",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=0,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config=False,
)

groupchat = autogen.GroupChat(
    agents=[coordinator, researcher, writer],
    messages=[],
    max_round=6,
    speaker_selection_method="round_robin",
)

manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_config)

coordinator.initiate_chat(
    manager,
    message="Research: Best practices for securing Python REST APIs in 2024.",
)
```

### Pattern 4: Code Review Crew

```python
# code_review_crew.py
import autogen
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

security_reviewer = autogen.AssistantAgent(
    name="SecurityReviewer",
    system_message="Review code for security vulnerabilities: SQL injection, XSS, auth issues, secrets exposure.",
    llm_config=llm_config,
)

perf_reviewer = autogen.AssistantAgent(
    name="PerfReviewer",
    system_message="Review code for performance: N+1 queries, memory leaks, blocking I/O, algorithmic complexity.",
    llm_config=llm_config,
)

style_reviewer = autogen.AssistantAgent(
    name="StyleReviewer",
    system_message="Review code for style: PEP 8, naming conventions, docstrings, type hints.",
    llm_config=llm_config,
)

lead_reviewer = autogen.AssistantAgent(
    name="LeadReviewer",
    system_message="""Consolidate all reviews into a final report.
    Format: SECURITY, PERFORMANCE, STYLE sections.
    End with: overall APPROVE or REJECT decision. Then say TERMINATE.""",
    llm_config=llm_config,
)

proxy = autogen.UserProxyAgent(
    name="proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=0,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config=False,
)

groupchat = autogen.GroupChat(
    agents=[proxy, security_reviewer, perf_reviewer, style_reviewer, lead_reviewer],
    messages=[],
    max_round=10,
    speaker_selection_method="round_robin",
)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_config)

code_to_review = """
def get_user(db, user_id):
    query = f"SELECT * FROM users WHERE id = {user_id}"
    return db.execute(query).fetchone()
"""

proxy.initiate_chat(manager, message=f"Review this code:\n```python\n{code_to_review}\n```")
```

---

## 12. Teachable Agents

`TeachableAgent` lets an agent learn from user corrections and recall them in future conversations using a memo database (Chroma vector store).

```python
# teachable_agent.py
# pip install pyautogen[teachable]
import autogen
from autogen.agentchat.contrib.teachable_agent import TeachableAgent
import os

config_list = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm_config = {"config_list": config_list, "temperature": 0}

teachable = TeachableAgent(
    name="TeachableAssistant",
    llm_config=llm_config,
    teach_config={
        "verbosity": 0,
        "reset_db": False,             # False = keep learned facts across sessions
        "path_to_db_dir": "./memo_db", # where to persist the memo DB
        "recall_threshold": 1.5,       # cosine similarity threshold
    },
)

user = autogen.UserProxyAgent(
    name="user",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=3,
    is_termination_msg=lambda msg: "TERMINATE" in msg.get("content", ""),
    code_execution_config=False,
)

# Teaching session — agent will remember these facts
user.initiate_chat(
    teachable,
    message="""
    Remember these preferences:
    - Our project always uses FastAPI (never Flask)
    - We target Python 3.11+
    - All database access goes through SQLAlchemy async
    - Pydantic v2 models for all schemas
    Say TERMINATE when you've acknowledged these.
    """,
)

# Reset chat history but teachable agent still remembers via memo DB
teachable.learn_from_user_feedback()

user.initiate_chat(
    teachable,
    message="What web framework should I use for a new API endpoint?",
    clear_history=True,
)
```

### How TeachableAgent Works Internally

```
User correction → TeachableAgent extracts (question, answer) pairs
               → Stores as embeddings in ChromaDB
               → On future queries: retrieves similar memos
               → Injects remembered facts into LLM context
```

---

## 13. AutoGen Studio

AutoGen Studio provides a browser-based no-code UI for building, testing, and iterating on multi-agent workflows.

### Installation & Launch

```bash
pip install autogenstudio
autogenstudio ui --port 8080 --host 0.0.0.0
# Open http://localhost:8080
```

### Key Features

| Feature | Description |
|---|---|
| **Agent Builder** | Create/configure agents via UI |
| **Workflow Designer** | Link agents into teams visually |
| **Playground** | Chat with your agent team live |
| **Sessions** | Save and replay conversations |
| **Gallery** | Pre-built agent templates |

### Exporting Workflows as Code

```python
# autogenstudio exports workflows to Python; example of exported structure:
workflow = {
    "name": "Software Team",
    "type": "groupchat",
    "agents": [
        {
            "name": "PM",
            "type": "assistant",
            "system_message": "You are a product manager...",
            "llm_config": {"config_list": [...]},
        },
        {
            "name": "Developer",
            "type": "assistant",
            "system_message": "You are a developer...",
            "llm_config": {"config_list": [...]},
        },
    ],
    "groupchat_config": {
        "max_round": 15,
        "speaker_selection_method": "auto",
    },
}
```

### Running AutoGen Studio Programmatically

```python
# autogenstudio_api.py
# AutoGen Studio exposes a REST API
import requests

BASE = "http://localhost:8080/api"

# List workflows
resp = requests.get(f"{BASE}/workflow")
workflows = resp.json()

# Run a workflow
payload = {
    "message": "Build a binary search function in Python with tests.",
    "workflow_id": workflows[0]["id"],
}
result = requests.post(f"{BASE}/workflow/run", json=payload).json()
print(result["status"], result["response"])
```

---

## 14. Interview Q&A (15 Questions)

---

**Q1: What is the difference between AssistantAgent and UserProxyAgent?**

> `AssistantAgent` is LLM-powered — it generates text and code using a language model. It does **not** execute code by default.
> `UserProxyAgent` represents a human or execution environment — it runs code, can prompt for human input, and controls the conversation flow. It may or may not use an LLM.
> Together they form the classic "write + execute" loop: the assistant writes code, the proxy runs it and returns results.

---

**Q2: How do you prevent an AutoGen agent from running code automatically?**

> Set `code_execution_config=False` on the agent:
> ```python
> agent = autogen.UserProxyAgent(
>     name="safe_proxy",
>     human_input_mode="ALWAYS",  # ask human before doing anything
>     code_execution_config=False,  # no code execution
> )
> ```
> Or set `human_input_mode="ALWAYS"` so a human must approve every action.

---

**Q3: What is human_input_mode and what are the options?**

> Controls when the `UserProxyAgent` pauses to request human input:
> - `"NEVER"` — fully autonomous, never pauses (good for pipelines)
> - `"TERMINATE"` — pauses only when `is_termination_msg` returns True (default recommended)
> - `"ALWAYS"` — pauses after every single message (good for demos or high-stakes tasks)

---

**Q4: How does GroupChat speaker selection work?**

> `GroupChatManager` controls who speaks next. Options for `speaker_selection_method`:
> - `"auto"` — the manager's LLM analyzes the conversation and picks the most relevant next agent
> - `"round_robin"` — strict rotation through agent list
> - `"random"` — random agent selected each round
> - `"manual"` — human picks via terminal
> - A callable function `(last_speaker, groupchat) -> Agent`

---

**Q5: What is a nested chat and when would you use it?**

> A nested chat is a sub-conversation spawned within a parent conversation via `register_nested_chats()`. It runs in isolation, produces a result, and that result is injected back into the parent conversation.
> **Use when:** a step in your workflow requires deep multi-turn reasoning that shouldn't pollute the main chat — e.g., a coordinator triggers a specialized research sub-agent, or a QA phase spawns a separate debugging conversation.

---

**Q6: How do you register a custom function/tool in AutoGen?**

> Use the dual decorator pattern:
> ```python
> @user_proxy.register_for_execution()        # handles running the function
> @assistant.register_for_llm(description="...")  # exposes schema to LLM
> def my_tool(param: str) -> str:
>     return f"result: {param}"
> ```
> The LLM sees the JSON schema; the proxy executes the actual Python function.

---

**Q7: What is the difference between AutoGen 0.2 and 0.4?**

> - **0.2** (`pyautogen`): synchronous API, `GroupChat`/`GroupChatManager` pattern, widely used in production, has `TeachableAgent`. Stable.
> - **0.4** (`autogen-agentchat`): fully async, event-driven architecture, `RoundRobinGroupChat`/`SelectorGroupChat`, built-in streaming via `MessageStream`, cleaner API design. Recommended for new projects.
> Key behavior difference: 0.4 separates `CodeExecutorAgent` into its own class; 0.2 bundles execution into `UserProxyAgent`.

---

**Q8: How do you make AutoGen agents stop when a task is complete?**

> Two mechanisms work together:
> 1. The `AssistantAgent` includes a stop phrase (e.g., `"TERMINATE"`) in its `system_message` instructions
> 2. The `UserProxyAgent` uses `is_termination_msg` to detect it:
> ```python
> is_termination_msg=lambda msg: "TERMINATE" in (msg.get("content") or "")
> ```
> Also set `max_consecutive_auto_reply` as a hard ceiling to prevent runaway loops.

---

**Q9: How do you use AutoGen with local models (Ollama)?**

> ```python
> config_list = [{
>     "model": "ollama/llama3.2",
>     "base_url": "http://localhost:11434/v1",
>     "api_key": "ollama",
> }]
> llm_config = {"config_list": config_list, "temperature": 0}
> ```
> Ollama exposes an OpenAI-compatible `/v1` endpoint. For function calling, use models that support it (e.g., `llama3.1`, `mistral-nemo`).

---

**Q10: How does AutoGen compare to CrewAI for code generation tasks?**

> | Aspect | AutoGen | CrewAI |
> |---|---|---|
> | Code execution | Native, built-in | Via tools only |
> | Code-test-fix loop | Automatic | Manual tool setup |
> | Role definition | system_message | Role + goal + backstory |
> | Orchestration | Conversation-driven | Task-driven |
> | Best for | Iterative coding tasks | Role-based business workflows |
> **AutoGen wins for code tasks** because agents natively write, run, observe errors, and fix code in a loop without extra tooling.

---

**Q11: What is DockerCommandLineCodeExecutor and why use it?**

> It runs agent-generated code inside a Docker container instead of the host machine:
> ```python
> code_execution_config={"use_docker": "python:3.11-slim", "work_dir": "workspace"}
> ```
> **Why:** Security isolation — untrusted LLM-generated code can't damage your system. Also ensures a clean, reproducible Python environment with only specified packages installed.

---

**Q12: How do you handle errors when an agent's generated code fails?**

> AutoGen handles this natively: when code fails, the executor sends the error traceback back to the `AssistantAgent` as a message. The assistant reads the error, revises the code, and tries again — automatically. This loop continues up to `max_consecutive_auto_reply`. You can also add a system message instruction: *"If code fails, analyze the error message and fix the code."*

---

**Q13: What is a TeachableAgent?**

> A `TeachableAgent` is an `AssistantAgent` that persists learned facts across sessions using a vector database (ChromaDB). When a user provides a correction or new information, the agent extracts a (question, answer) memo and stores it. On future conversations, relevant memos are retrieved and injected into the LLM context — making the agent improve over time.

---

**Q14: How do you limit the number of conversation rounds?**

> Three ways:
> 1. `max_consecutive_auto_reply=N` on `UserProxyAgent` — stops after N auto-replies without human input
> 2. `max_round=N` in `GroupChat` — hard stop after N total rounds
> 3. `max_turns=N` in `initiate_chat()` — limits turns for that specific conversation
> ```python
> user_proxy.initiate_chat(assistant, message="...", max_turns=5)
> ```

---

**Q15: How do you use AutoGen in a production API?**

> ```python
> # production_api.py — FastAPI + AutoGen
> from fastapi import FastAPI, BackgroundTasks
> from pydantic import BaseModel
> import autogen, uuid, asyncio
> from concurrent.futures import ThreadPoolExecutor
>
> app = FastAPI()
> executor = ThreadPoolExecutor(max_workers=4)
> results = {}
>
> class TaskRequest(BaseModel):
>     task: str
>
> def run_autogen_task(task_id: str, task: str):
>     config_list = [{"model": "gpt-4o", "api_key": "YOUR_KEY"}]
>     assistant = autogen.AssistantAgent("assistant",
>         llm_config={"config_list": config_list})
>     proxy = autogen.UserProxyAgent("proxy",
>         human_input_mode="NEVER",
>         max_consecutive_auto_reply=10,
>         is_termination_msg=lambda m: "TERMINATE" in (m.get("content") or ""),
>         code_execution_config={"work_dir": "workspace", "use_docker": False})
>     proxy.initiate_chat(assistant, message=task)
>     results[task_id] = proxy.chat_messages[assistant][-1]["content"]
>
> @app.post("/run")
> def run_task(req: TaskRequest, background_tasks: BackgroundTasks):
>     task_id = str(uuid.uuid4())
>     background_tasks.add_task(executor.submit, run_autogen_task, task_id, req.task)
>     return {"task_id": task_id}
>
> @app.get("/result/{task_id}")
> def get_result(task_id: str):
>     return {"result": results.get(task_id, "pending")}
> ```
> Key considerations: thread isolation per request, timeout handling, workspace cleanup, async result polling.

---

## 15. Complete End-to-End Example

**Autonomous Software Engineer:** Receives a feature request → writes code → writes tests → runs tests → fixes bugs → delivers final output.

```python
# autonomous_software_engineer.py
"""
Autonomous Software Engineer using AutoGen.
Receives a feature request, writes code, writes tests,
runs tests, fixes any failures, and delivers the final result.

Requirements:
    pip install pyautogen

Usage:
    export OPENAI_API_KEY=sk-...
    python autonomous_software_engineer.py
"""
import autogen
import os
import shutil
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────

WORK_DIR = "ase_workspace"
Path(WORK_DIR).mkdir(exist_ok=True)

def get_llm_config():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        import subprocess
        api_key = subprocess.run(
            ["gh", "auth", "token"], capture_output=True, text=True
        ).stdout.strip()
    return {
        "config_list": [{"model": "gpt-4o", "api_key": api_key,
                         "base_url": "https://models.inference.ai.azure.com"
                         if not os.environ.get("OPENAI_API_KEY") else None}],
        "temperature": 0,
        "cache_seed": None,
    }

llm_config = get_llm_config()
# Remove None base_url if present
llm_config["config_list"] = [
    {k: v for k, v in cfg.items() if v is not None}
    for cfg in llm_config["config_list"]
]

# ─── Agent Definitions ────────────────────────────────────────────────────────

architect = autogen.AssistantAgent(
    name="Architect",
    llm_config=llm_config,
    system_message="""You are a software architect.
    When given a feature request:
    1. Design the solution clearly (classes, functions, interfaces)
    2. List acceptance criteria
    3. Hand off to Developer with: ARCH_DONE
    Be concise. No code yet — design only.""",
)

developer = autogen.AssistantAgent(
    name="Developer",
    llm_config=llm_config,
    system_message="""You are a senior Python developer.
    When given an architecture:
    1. Implement ALL required code in a single ```python block
    2. Include all imports at the top
    3. Write the complete implementation — no placeholders
    4. Save file as: implementation.py
    After implementation, say: DEV_DONE""",
)

tester = autogen.AssistantAgent(
    name="Tester",
    llm_config=llm_config,
    system_message="""You are a QA engineer.
    When implementation is ready:
    1. Write comprehensive pytest tests in a single ```python block
    2. Cover: happy path, edge cases, error cases
    3. Import from implementation module
    4. Save as: test_implementation.py
    Run the tests after writing them.
    If tests pass, say: ALL_TESTS_PASSED - TERMINATE
    If tests fail, describe what needs fixing.""",
)

fixer = autogen.AssistantAgent(
    name="BugFixer",
    llm_config=llm_config,
    system_message="""You are a debugging expert.
    When given test failures:
    1. Analyze the error output carefully
    2. Fix the implementation (rewrite the full file)
    3. Put fixed code in a ```python block saving to implementation.py
    4. Say: FIX_APPLIED
    Be systematic — fix root causes, not symptoms.""",
)

executor = autogen.UserProxyAgent(
    name="Executor",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=25,
    is_termination_msg=lambda msg: (
        "TERMINATE" in (msg.get("content") or "")
        or "ALL_TESTS_PASSED" in (msg.get("content") or "")
    ),
    code_execution_config={
        "work_dir": WORK_DIR,
        "use_docker": False,
        "timeout": 60,
        "last_n_messages": 5,
    },
)

# ─── Group Chat ───────────────────────────────────────────────────────────────

def select_next_speaker(last_speaker, groupchat):
    """Custom speaker selection: architect → developer → tester → fixer → tester..."""
    msgs = groupchat.messages
    if not msgs:
        return architect

    last_content = (msgs[-1].get("content") or "").strip()

    if last_speaker.name == "Executor":
        # After execution: check what was last requested
        for msg in reversed(msgs[:-1]):
            speaker = msg.get("name", "")
            if speaker == "Architect" and "ARCH_DONE" in (msg.get("content") or ""):
                return developer
            if speaker == "Developer" and "DEV_DONE" in (msg.get("content") or ""):
                return tester
            if speaker == "Tester" and "FIX_APPLIED" not in (msg.get("content") or ""):
                return fixer
            if speaker == "BugFixer":
                return tester
        return developer

    routing = {
        "Architect": developer,
        "Developer": executor,
        "Tester": executor,
        "BugFixer": executor,
    }
    return routing.get(last_speaker.name, architect)

groupchat = autogen.GroupChat(
    agents=[executor, architect, developer, tester, fixer],
    messages=[],
    max_round=30,
    speaker_selection_method=select_next_speaker,
)

manager = autogen.GroupChatManager(
    groupchat=groupchat,
    llm_config=llm_config,
)

# ─── Feature Request ──────────────────────────────────────────────────────────

FEATURE_REQUEST = """
Build a Python module for a simple in-memory task management system with:

1. A `Task` dataclass with fields: id (auto-generated UUID), title, description,
   status (todo/in_progress/done), created_at, updated_at

2. A `TaskManager` class with methods:
   - create_task(title, description) -> Task
   - get_task(task_id) -> Task | None
   - list_tasks(status=None) -> list[Task]  (filter by status if given)
   - update_status(task_id, new_status) -> Task | None
   - delete_task(task_id) -> bool

3. All methods should have proper type hints and docstrings
4. Raise ValueError for invalid status values
5. update_status should update the updated_at timestamp
"""

# ─── Run ──────────────────────────────────────────────────────────────────────

print("=" * 60)
print("🤖 Autonomous Software Engineer Starting...")
print("=" * 60)
print(f"Feature Request:\n{FEATURE_REQUEST}\n")
print("=" * 60)

executor.initiate_chat(
    manager,
    message=FEATURE_REQUEST,
)

# ─── Final Report ─────────────────────────────────────────────────────────────

print("\n" + "=" * 60)
print("✅ Task Complete! Workspace contents:")
for f in Path(WORK_DIR).iterdir():
    size = f.stat().st_size
    print(f"  📄 {f.name} ({size} bytes)")

print("=" * 60)
print(f"All files saved to: {WORK_DIR}/")
```

### What This Example Demonstrates

| Phase | Agent | Action |
|---|---|---|
| 1. Design | Architect | Breaks down feature into design |
| 2. Implement | Developer | Writes full Python implementation |
| 3. Test | Tester | Writes and runs pytest tests |
| 4. Fix (if needed) | BugFixer | Analyzes failures, fixes code |
| 5. Re-test | Tester | Confirms all tests pass |
| 6. Complete | Executor | Reports final status |

The agents communicate entirely via the `GroupChat`, with the `Executor` running all code and feeding results back. The loop continues until tests pass or `max_round` is hit — a fully autonomous software engineering pipeline.

---

## Quick Reference Card

```python
# ── MINIMAL SETUP ──────────────────────────────────────────
import autogen, os
cfg = [{"model": "gpt-4o", "api_key": os.environ["OPENAI_API_KEY"]}]
llm = {"config_list": cfg, "temperature": 0}

# ── TWO-AGENT CHAT ─────────────────────────────────────────
assistant = autogen.AssistantAgent("assistant", llm_config=llm)
proxy = autogen.UserProxyAgent("proxy", human_input_mode="NEVER",
    code_execution_config={"work_dir": "ws", "use_docker": False},
    is_termination_msg=lambda m: "TERMINATE" in (m.get("content") or ""))
proxy.initiate_chat(assistant, message="Your task here")

# ── GROUP CHAT ─────────────────────────────────────────────
gc = autogen.GroupChat(agents=[proxy, a1, a2, a3], messages=[], max_round=15)
mgr = autogen.GroupChatManager(groupchat=gc, llm_config=llm)
proxy.initiate_chat(mgr, message="Group task here")

# ── TOOL REGISTRATION ──────────────────────────────────────
@proxy.register_for_execution()
@assistant.register_for_llm(description="Tool description")
def my_tool(input: str) -> str: return f"result: {input}"

# ── TERMINATION ────────────────────────────────────────────
# In system_message: "Say TERMINATE when done."
# In agent: is_termination_msg=lambda m: "TERMINATE" in (m.get("content") or "")
# Hard limit: max_consecutive_auto_reply=10
```

---

*Guide version: AutoGen 0.2.x / 0.4.x — Generated for EngX AI Coach for Software Developers*
