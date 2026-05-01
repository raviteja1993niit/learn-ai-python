# AutoGen Code Examples

A comprehensive reference of annotated Python code examples for the AutoGen framework.
Each example includes a comment block explaining its purpose and key concepts.

---

## Table of Contents

1. Two-Agent Conversation
2. AssistantAgent with System Message and model_client
3. UserProxyAgent with NEVER Human Input Mode
4. Code Execution - LocalCommandLineCodeExecutor
5. Code Execution - DockerCommandLineCodeExecutor
6. Agent with Tool Use (@tool decorator)
7. FunctionTool Definition and Use
8. MaxMessageTermination
9. TextMentionTermination
10. GroupChat with 3 Agents
11. GroupChatManager Setup
12. Custom Speaker Selection Function
13. Custom BaseChatAgent Subclass
14. Nested Chat Pattern
15. Streaming Response with on_messages_stream()
16. save_state and load_state
17. CacheClient (DiskCacheClient) Usage
18. SocietyOfMindAgent
19. Code Generation Agent
20. Data Analysis Multi-Agent Team
21. Debate Agents (Pro/Con)

---

## 1. Two-Agent Conversation

```python
# ---------------------------------------------------------------------------
# Example 1: Two-Agent Conversation
# ---------------------------------------------------------------------------
# The most fundamental AutoGen pattern.
# - AssistantAgent: powered by an LLM, generates replies.
# - UserProxyAgent: represents the human side; can execute code or relay input.
# The two agents take turns until a termination condition is met.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def two_agent_chat():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    assistant = AssistantAgent(
        name="assistant",
        model_client=model_client,
    )
    user_proxy = UserProxyAgent(name="user_proxy")

    termination = MaxMessageTermination(max_messages=6)
    team = RoundRobinGroupChat([assistant, user_proxy], termination_condition=termination)

    result = await team.run(task="Explain the difference between lists and tuples in Python.")
    print(result.messages[-1].content)

asyncio.run(two_agent_chat())
```

---

## 2. AssistantAgent with System Message and model_client

```python
# ---------------------------------------------------------------------------
# Example 2: AssistantAgent with System Message and model_client
# ---------------------------------------------------------------------------
# A custom system_message shapes the assistant's persona and behaviour.
# model_client wraps the underlying LLM provider (here: OpenAI GPT-4o).
# This is the primary way to configure an agent's role and constraints.
# ---------------------------------------------------------------------------

from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_agentchat.messages import TextMessage
from autogen_core import CancellationToken
import asyncio

async def assistant_with_system_message():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    agent = AssistantAgent(
        name="python_tutor",
        model_client=model_client,
        system_message=(
            "You are an expert Python tutor. "
            "Always provide clear, concise explanations with working code examples. "
            "Format code using markdown code fences."
        ),
    )

    response = await agent.on_messages(
        [TextMessage(content="What is a Python decorator?", source="user")],
        cancellation_token=CancellationToken(),
    )
    print(response.chat_message.content)

asyncio.run(assistant_with_system_message())
```

---

## 3. UserProxyAgent with NEVER Human Input Mode

```python
# ---------------------------------------------------------------------------
# Example 3: UserProxyAgent with NEVER Human Input Mode
# ---------------------------------------------------------------------------
# Setting human_input_mode='NEVER' makes UserProxyAgent fully autonomous.
# It never pauses to ask for human input during a conversation.
# Useful for automated pipelines and CI/CD workflows.
# ---------------------------------------------------------------------------

from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
import asyncio

async def never_input_mode():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")
    assistant = AssistantAgent(name="assistant", model_client=model_client)

    # human_input_mode='NEVER' — no prompts, fully automated
    user_proxy = UserProxyAgent(
        name="user_proxy",
        human_input_mode="NEVER",
    )

    termination = MaxMessageTermination(max_messages=4)
    team = RoundRobinGroupChat([user_proxy, assistant], termination_condition=termination)

    result = await team.run(task="Write a Python one-liner that reverses a string.")
    for msg in result.messages:
        print(f"[{msg.source}]: {msg.content}\n")

asyncio.run(never_input_mode())
```

---

## 4. Code Execution - LocalCommandLineCodeExecutor

```python
# ---------------------------------------------------------------------------
# Example 4: Code Execution with LocalCommandLineCodeExecutor
# ---------------------------------------------------------------------------
# LocalCommandLineCodeExecutor runs generated code directly on the host machine
# inside a specified working directory.
# Best for local development; avoid in production without sandboxing.
# ---------------------------------------------------------------------------

import asyncio
from pathlib import Path
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor

async def local_code_execution():
    work_dir = Path("coding_workspace")
    work_dir.mkdir(exist_ok=True)
    executor = LocalCommandLineCodeExecutor(work_dir=work_dir)

    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    assistant = AssistantAgent(
        name="coder",
        model_client=model_client,
        system_message="Write Python code to solve the task. Put code in a ```python block.",
    )
    user_proxy = UserProxyAgent(
        name="executor",
        human_input_mode="NEVER",
        code_executor=executor,
    )

    termination = MaxMessageTermination(max_messages=6)
    team = RoundRobinGroupChat([assistant, user_proxy], termination_condition=termination)

    result = await team.run(task="Write and run code that prints the first 10 Fibonacci numbers.")
    print(result.messages[-1].content)

asyncio.run(local_code_execution())
```

---

## 5. Code Execution - DockerCommandLineCodeExecutor

```python
# ---------------------------------------------------------------------------
# Example 5: Code Execution with DockerCommandLineCodeExecutor
# ---------------------------------------------------------------------------
# DockerCommandLineCodeExecutor runs generated code inside a Docker container,
# providing isolation from the host system.
# Requires Docker to be running. Ideal for production or untrusted code.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.code_executors.docker import DockerCommandLineCodeExecutor

async def docker_code_execution():
    # The executor spins up a temporary Docker container.
    async with DockerCommandLineCodeExecutor(image="python:3.12-slim") as executor:
        model_client = OpenAIChatCompletionClient(model="gpt-4o")

        assistant = AssistantAgent(
            name="coder",
            model_client=model_client,
            system_message="Solve the task by writing executable Python code.",
        )
        user_proxy = UserProxyAgent(
            name="docker_executor",
            human_input_mode="NEVER",
            code_executor=executor,
        )

        termination = MaxMessageTermination(max_messages=6)
        team = RoundRobinGroupChat([assistant, user_proxy], termination_condition=termination)
        result = await team.run(task="Calculate and print the sum of all primes below 100.")
        print(result.messages[-1].content)

asyncio.run(docker_code_execution())
```

---

## 6. Agent with Tool Use (@tool decorator)

```python
# ---------------------------------------------------------------------------
# Example 6: Agent with Tool Use via @tool Decorator
# ---------------------------------------------------------------------------
# The @tool decorator exposes a plain Python function as a callable tool
# that the LLM can invoke by name during the conversation.
# AutoGen automatically handles tool-call parsing and result injection.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.messages import TextMessage
from autogen_core import CancellationToken
from autogen_core.tools import tool
from autogen_ext.models.openai import OpenAIChatCompletionClient

@tool
def get_weather(city: str) -> str:
    # Return a mock weather report for the given city.
    return f"The weather in {city} is currently 22 degrees C and sunny."

@tool
def calculator(expression: str) -> str:
    # Safely evaluate a simple arithmetic expression and return the result.
    try:
        result = eval(expression, {"__builtins__": {}})
        return str(result)
    except Exception as e:
        return f"Error: {e}"

async def agent_with_tools():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")
    agent = AssistantAgent(
        name="tool_agent",
        model_client=model_client,
        tools=[get_weather, calculator],
        system_message="Use tools when appropriate to answer user questions.",
    )

    response = await agent.on_messages(
        [TextMessage(content="What is the weather in Paris and what is 42 * 7?", source="user")],
        cancellation_token=CancellationToken(),
    )
    print(response.chat_message.content)

asyncio.run(agent_with_tools())
```

---

## 7. FunctionTool Definition and Use

```python
# ---------------------------------------------------------------------------
# Example 7: FunctionTool Definition and Use
# ---------------------------------------------------------------------------
# FunctionTool wraps any Python callable into an AutoGen tool object,
# giving fine-grained control over the name and description exposed
# to the LLM — without using the @tool decorator.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.messages import TextMessage
from autogen_core import CancellationToken
from autogen_core.tools import FunctionTool
from autogen_ext.models.openai import OpenAIChatCompletionClient

def search_database(query: str, limit: int = 5) -> list:
    # Simulate a database search returning mock records.
    return [{"id": i, "title": f"Result {i} for '{query}'"} for i in range(1, limit + 1)]

async def function_tool_example():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    # Wrap the function manually with a custom description.
    db_tool = FunctionTool(
        func=search_database,
        name="search_database",
        description="Search the internal database. Provide a query string and optional limit.",
    )

    agent = AssistantAgent(
        name="researcher",
        model_client=model_client,
        tools=[db_tool],
    )

    response = await agent.on_messages(
        [TextMessage(content="Search the database for 'AutoGen tutorials'.", source="user")],
        cancellation_token=CancellationToken(),
    )
    print(response.chat_message.content)

asyncio.run(function_tool_example())
```

---

## 8. MaxMessageTermination

```python
# ---------------------------------------------------------------------------
# Example 8: MaxMessageTermination
# ---------------------------------------------------------------------------
# MaxMessageTermination stops the conversation after a fixed number of
# messages have been exchanged, preventing infinite loops.
# This is the simplest termination strategy and a good safety net.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def max_message_demo():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")
    agent1 = AssistantAgent(name="agent_a", model_client=model_client)
    agent2 = AssistantAgent(name="agent_b", model_client=model_client)

    # Stop after 4 total messages (including the initial task message).
    termination = MaxMessageTermination(max_messages=4)
    team = RoundRobinGroupChat([agent1, agent2], termination_condition=termination)

    result = await team.run(task="Discuss the pros and cons of microservices architecture.")
    print(f"Conversation ended after {len(result.messages)} messages.")

asyncio.run(max_message_demo())
```

---

## 9. TextMentionTermination

```python
# ---------------------------------------------------------------------------
# Example 9: TextMentionTermination
# ---------------------------------------------------------------------------
# TextMentionTermination stops the conversation when a specific phrase or
# keyword appears in any agent message.
# Common convention: agents say "TERMINATE" when they believe the task is done.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def text_mention_demo():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    solver = AssistantAgent(
        name="solver",
        model_client=model_client,
        system_message=(
            "Solve the given problem step by step. "
            "When confident the answer is correct, "
            "end your final message with the word TERMINATE."
        ),
    )

    termination = TextMentionTermination("TERMINATE")
    team = RoundRobinGroupChat([solver], termination_condition=termination)

    result = await team.run(task="What is the integral of x^2 with respect to x?")
    print(result.messages[-1].content)

asyncio.run(text_mention_demo())
```

---

## 10. GroupChat with 3 Agents

```python
# ---------------------------------------------------------------------------
# Example 10: GroupChat with 3 Agents
# ---------------------------------------------------------------------------
# A GroupChat allows multiple agents to collaborate in a shared conversation.
# Three specialised agents — planner, coder, and critic — work together
# on a software design task using RoundRobinGroupChat.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def three_agent_group_chat():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    planner = AssistantAgent(
        name="planner", model_client=client,
        system_message="You create high-level plans and break tasks into subtasks.",
    )
    coder = AssistantAgent(
        name="coder", model_client=client,
        system_message="You write clean, well-commented Python code based on the plan.",
    )
    critic = AssistantAgent(
        name="critic", model_client=client,
        system_message="You review plans and code for correctness, style, and edge cases.",
    )

    termination = MaxMessageTermination(max_messages=9)
    team = RoundRobinGroupChat([planner, coder, critic], termination_condition=termination)
    result = await team.run(task="Design and implement a simple LRU cache in Python.")

    for msg in result.messages:
        print(f"--- {msg.source} ---\n{msg.content}\n")

asyncio.run(three_agent_group_chat())
```

---

## 11. GroupChatManager Setup

```python
# ---------------------------------------------------------------------------
# Example 11: GroupChatManager Setup via SelectorGroupChat
# ---------------------------------------------------------------------------
# SelectorGroupChat is AutoGen's managed group-chat team where an LLM-based
# selector (the 'manager') chooses which agent speaks next.
# This enables dynamic, non-round-robin conversations.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import SelectorGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def selector_group_chat():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    researcher = AssistantAgent(
        name="researcher", model_client=client,
        system_message="You research topics and provide factual summaries.",
    )
    writer = AssistantAgent(
        name="writer", model_client=client,
        system_message="You turn research summaries into polished prose.",
    )
    editor = AssistantAgent(
        name="editor", model_client=client,
        system_message="You proofread and improve the writer's output.",
    )

    # SelectorGroupChat uses an LLM to pick the next speaker.
    termination = MaxMessageTermination(max_messages=8)
    team = SelectorGroupChat(
        participants=[researcher, writer, editor],
        model_client=client,
        termination_condition=termination,
    )

    result = await team.run(
        task="Write a short article about quantum computing for a general audience."
    )
    print(result.messages[-1].content)

asyncio.run(selector_group_chat())
```

---

## 12. Custom Speaker Selection Function

```python
# ---------------------------------------------------------------------------
# Example 12: Custom Speaker Selection Function
# ---------------------------------------------------------------------------
# SelectorGroupChat accepts a custom selector_func that overrides LLM-based
# selection. Implement any deterministic or rule-based routing logic here.
# The function receives the current message history and returns an agent name.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import SelectorGroupChat
from autogen_agentchat.base import ChatAgent
from autogen_agentchat.messages import AgentEvent, ChatMessage
from autogen_ext.models.openai import OpenAIChatCompletionClient
from typing import Sequence

def custom_selector(
    messages: Sequence[AgentEvent | ChatMessage],
    agents: list[ChatAgent],
) -> str | None:
    # Route: analyst first, then writer, then reviewer, cycling.
    order = ["analyst", "writer", "reviewer"]
    turn = max(0, len(messages) - 1)
    return order[turn % len(order)]

async def custom_speaker_selection():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    analyst  = AssistantAgent(name="analyst",  model_client=client,
                               system_message="Analyse data and identify key trends.")
    writer   = AssistantAgent(name="writer",   model_client=client,
                               system_message="Summarise findings in clear prose.")
    reviewer = AssistantAgent(name="reviewer", model_client=client,
                               system_message="Review and critique the output.")

    termination = MaxMessageTermination(max_messages=7)
    team = SelectorGroupChat(
        participants=[analyst, writer, reviewer],
        model_client=client,
        selector_func=custom_selector,
        termination_condition=termination,
    )

    result = await team.run(task="Analyse trends in cloud computing adoption.")
    for m in result.messages:
        print(f"[{m.source}]: {m.content[:120]}\n")

asyncio.run(custom_speaker_selection())
```

---

## 13. Custom BaseChatAgent Subclass

```python
# ---------------------------------------------------------------------------
# Example 13: Custom BaseChatAgent Subclass
# ---------------------------------------------------------------------------
# Subclass BaseChatAgent to create a fully custom agent with hand-written
# logic that does not call an LLM. Useful for deterministic agents such as
# validators, routers, mock services, or tool-execution nodes.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import BaseChatAgent
from autogen_agentchat.base import Response
from autogen_agentchat.messages import ChatMessage, TextMessage
from autogen_core import CancellationToken
from typing import AsyncGenerator, Sequence

class EchoAgent(BaseChatAgent):
    # A simple agent that echoes the last message back in uppercase.

    def __init__(self, name: str):
        super().__init__(name=name, description="Echoes messages in uppercase.")

    @property
    def produced_message_types(self) -> list:
        return [TextMessage]

    async def on_messages(
        self,
        messages: Sequence[ChatMessage],
        cancellation_token: CancellationToken,
    ) -> Response:
        last = messages[-1].content if messages else ""
        reply = TextMessage(content=last.upper(), source=self.name)
        return Response(chat_message=reply)

    async def on_messages_stream(
        self,
        messages: Sequence[ChatMessage],
        cancellation_token: CancellationToken,
    ) -> AsyncGenerator:
        response = await self.on_messages(messages, cancellation_token)
        yield response

    async def on_reset(self, cancellation_token: CancellationToken) -> None:
        pass  # No internal state to reset.

async def custom_agent_demo():
    agent = EchoAgent(name="echo")
    response = await agent.on_messages(
        [TextMessage(content="hello from autogen!", source="user")],
        CancellationToken(),
    )
    print(response.chat_message.content)  # => HELLO FROM AUTOGEN!

asyncio.run(custom_agent_demo())
```

---

## 14. Nested Chat Pattern

```python
# ---------------------------------------------------------------------------
# Example 14: Nested Chat Pattern
# ---------------------------------------------------------------------------
# A nested chat embeds one team's conversation inside another team's turn.
# An inner research team runs first; its output is fed to an outer writer agent.
# This pattern enables hierarchical, multi-stage agent workflows.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.messages import TextMessage
from autogen_core import CancellationToken
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def nested_chat():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    # --- Inner team: researcher + fact-checker ---
    researcher   = AssistantAgent(name="researcher",   model_client=client,
                                   system_message="Find key facts about the topic.")
    fact_checker = AssistantAgent(name="fact_checker", model_client=client,
                                   system_message="Verify and correct factual claims.")

    inner_team = RoundRobinGroupChat(
        [researcher, fact_checker],
        termination_condition=MaxMessageTermination(max_messages=4),
    )
    inner_result = await inner_team.run(
        task="What are the latest advancements in fusion energy?"
    )
    inner_summary = inner_result.messages[-1].content

    # --- Outer agent uses the inner result ---
    writer = AssistantAgent(
        name="writer", model_client=client,
        system_message="Write a concise blog post using the research provided.",
    )

    response = await writer.on_messages(
        [TextMessage(content=f"Research notes:\n{inner_summary}", source="user")],
        CancellationToken(),
    )
    print(response.chat_message.content)

asyncio.run(nested_chat())
```

---

## 15. Streaming Response with on_messages_stream()

```python
# ---------------------------------------------------------------------------
# Example 15: Streaming Response with on_messages_stream()
# ---------------------------------------------------------------------------
# on_messages_stream() yields tokens or partial messages as they arrive,
# enabling real-time display of agent output similar to ChatGPT streaming.
# Iterate the async generator to consume each chunk as it appears.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.base import Response
from autogen_agentchat.messages import TextMessage, ModelClientStreamingChunkEvent
from autogen_core import CancellationToken
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def streaming_demo():
    model_client = OpenAIChatCompletionClient(model="gpt-4o")
    agent = AssistantAgent(
        name="streamer",
        model_client=model_client,
        system_message="Explain concepts clearly and in detail.",
    )

    print("Streaming response:\n")
    async for event in agent.on_messages_stream(
        [TextMessage(content="Explain how transformers work in machine learning.", source="user")],
        cancellation_token=CancellationToken(),
    ):
        if isinstance(event, ModelClientStreamingChunkEvent):
            # Print each chunk without newline to show the streaming effect.
            print(event.content, end="", flush=True)
        elif isinstance(event, Response):
            print("\n\n[Stream complete]")

asyncio.run(streaming_demo())
```

---

## 16. save_state and load_state

```python
# ---------------------------------------------------------------------------
# Example 16: save_state and load_state
# ---------------------------------------------------------------------------
# save_state() serialises an agent's (or team's) full conversation history
# to a JSON-serialisable dict. load_state() restores it.
# Use this to pause/resume long-running workflows or to persist agent memory
# across process restarts.
# ---------------------------------------------------------------------------

import asyncio, json
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def state_persistence():
    client = OpenAIChatCompletionClient(model="gpt-4o")
    agent  = AssistantAgent(name="memory_agent", model_client=client)

    termination = MaxMessageTermination(max_messages=3)
    team = RoundRobinGroupChat([agent], termination_condition=termination)

    # First run — establishes context.
    await team.run(task="Remember that the project deadline is Friday.")

    # Persist state to disk.
    state = await team.save_state()
    with open("team_state.json", "w") as f:
        json.dump(state, f, indent=2)
    print("State saved.")

    # Restore state into a brand-new team instance.
    new_agent = AssistantAgent(name="memory_agent", model_client=client)
    new_team  = RoundRobinGroupChat([new_agent], termination_condition=MaxMessageTermination(3))
    with open("team_state.json") as f:
        saved = json.load(f)
    await new_team.load_state(saved)

    # Continue the conversation — the agent remembers the deadline.
    result = await new_team.run(task="What is the project deadline?")
    print(result.messages[-1].content)

asyncio.run(state_persistence())
```

---

## 17. CacheClient (DiskCacheClient) Usage

```python
# ---------------------------------------------------------------------------
# Example 17: CacheClient (DiskCacheClient) Usage
# ---------------------------------------------------------------------------
# DiskCacheClient wraps any model client and caches LLM responses to disk.
# Identical prompts return cached results instantly, saving API costs
# and speeding up development iteration.
# Requires: pip install diskcache autogen-ext[cache]
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.messages import TextMessage
from autogen_core import CancellationToken
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.models.cache import DiskCacheClient
import diskcache

async def cache_client_demo():
    base_client = OpenAIChatCompletionClient(model="gpt-4o")

    # Wrap the base client with a disk cache stored in ./llm_cache.
    cache = diskcache.Cache("./llm_cache")
    cached_client = DiskCacheClient(client=base_client, cache=cache)

    agent = AssistantAgent(
        name="cached_agent",
        model_client=cached_client,
        system_message="Answer questions concisely.",
    )

    # First call — hits the API.
    r1 = await agent.on_messages(
        [TextMessage(content="What is the capital of France?", source="user")],
        CancellationToken(),
    )
    print("First call:", r1.chat_message.content)

    # Second identical call — served from disk cache (no API round-trip).
    await agent.on_reset(CancellationToken())
    r2 = await agent.on_messages(
        [TextMessage(content="What is the capital of France?", source="user")],
        CancellationToken(),
    )
    print("Cached call:", r2.chat_message.content)

asyncio.run(cache_client_demo())
```

---

## 18. SocietyOfMindAgent

```python
# ---------------------------------------------------------------------------
# Example 18: SocietyOfMindAgent
# ---------------------------------------------------------------------------
# SocietyOfMindAgent wraps an entire inner team and exposes it as a single
# agent to an outer conversation. The inner team deliberates internally;
# only the final synthesised answer is surfaced to the outer team.
# Implements Minsky's 'Society of Mind' concept.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent, SocietyOfMindAgent
from autogen_agentchat.conditions import MaxMessageTermination, TextMentionTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def society_of_mind_demo():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    sub1 = AssistantAgent(name="domain_expert",  model_client=client,
                           system_message="Provide deep domain knowledge.")
    sub2 = AssistantAgent(name="devil_advocate", model_client=client,
                           system_message="Challenge assumptions critically.")
    sub3 = AssistantAgent(name="synthesiser",    model_client=client,
                           system_message="Combine perspectives into a unified answer. End with TERMINATE.")

    inner_team = RoundRobinGroupChat(
        [sub1, sub2, sub3],
        termination_condition=TextMentionTermination("TERMINATE"),
    )

    # Wrap the inner team as a single SocietyOfMindAgent.
    som_agent = SocietyOfMindAgent(
        name="society_agent",
        team=inner_team,
        model_client=client,
    )

    outer_team = RoundRobinGroupChat(
        [som_agent],
        termination_condition=MaxMessageTermination(max_messages=3),
    )
    result = await outer_team.run(task="Should companies adopt a four-day work week?")
    print(result.messages[-1].content)

asyncio.run(society_of_mind_demo())
```

---

## 19. Code Generation Agent

```python
# ---------------------------------------------------------------------------
# Example 19: Code Generation Agent
# ---------------------------------------------------------------------------
# A dedicated code-generation pipeline: one agent writes code, another
# executes it and reports results, a third reviews quality.
# The workflow terminates when the reviewer approves with the token LGTM.
# ---------------------------------------------------------------------------

import asyncio
from pathlib import Path
from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor

async def code_generation_agent():
    client   = OpenAIChatCompletionClient(model="gpt-4o")
    work_dir = Path("gen_code")
    work_dir.mkdir(exist_ok=True)

    generator = AssistantAgent(
        name="code_generator",
        model_client=client,
        system_message=(
            "You write clean, efficient Python code. "
            "Always wrap code in ```python ... ``` blocks."
        ),
    )
    executor = UserProxyAgent(
        name="code_executor",
        human_input_mode="NEVER",
        code_executor=LocalCommandLineCodeExecutor(work_dir=work_dir),
    )
    reviewer = AssistantAgent(
        name="code_reviewer",
        model_client=client,
        system_message=(
            "Review the generated code and execution results. "
            "If everything is correct and clean, reply with LGTM. "
            "Otherwise, suggest improvements."
        ),
    )

    termination = TextMentionTermination("LGTM")
    team = RoundRobinGroupChat([generator, executor, reviewer], termination_condition=termination)
    result = await team.run(task="Write a Python function that merges two sorted lists.")
    print(result.messages[-1].content)

asyncio.run(code_generation_agent())
```

---

## 20. Data Analysis Multi-Agent Team

```python
# ---------------------------------------------------------------------------
# Example 20: Data Analysis Multi-Agent Team
# ---------------------------------------------------------------------------
# A pipeline of specialised data agents: ingestion, analysis, visualisation,
# and reporting. Each agent hands off enriched context to the next.
# SelectorGroupChat routes based on conversation state via an LLM manager.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.teams import SelectorGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def data_analysis_team():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    data_loader = AssistantAgent(
        name="data_loader", model_client=client,
        system_message="Describe how to load and inspect a dataset. List column names and dtypes.",
    )
    analyst = AssistantAgent(
        name="analyst", model_client=client,
        system_message="Perform statistical analysis: mean, median, correlations, outlier detection.",
    )
    visualiser = AssistantAgent(
        name="visualiser", model_client=client,
        system_message="Suggest and write matplotlib/seaborn visualisation code for the analysis.",
    )
    reporter = AssistantAgent(
        name="reporter", model_client=client,
        system_message=(
            "Synthesise all findings into an executive summary. "
            "End with TERMINATE when the report is complete."
        ),
    )

    termination = TextMentionTermination("TERMINATE")
    team = SelectorGroupChat(
        participants=[data_loader, analyst, visualiser, reporter],
        model_client=client,
        termination_condition=termination,
    )
    result = await team.run(
        task="Analyse a sales dataset: load it, find top-performing products, visualise trends, report."
    )
    print(result.messages[-1].content)

asyncio.run(data_analysis_team())
```

---

## 21. Debate Agents (Pro/Con)

```python
# ---------------------------------------------------------------------------
# Example 21: Debate Agents (Pro/Con)
# ---------------------------------------------------------------------------
# Two agents argue opposite sides of a topic for a fixed number of rounds.
# A neutral judge evaluates the arguments and declares a winner.
# Demonstrates structured adversarial collaboration in AutoGen.
# ---------------------------------------------------------------------------

import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def debate_agents():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    pro_agent = AssistantAgent(
        name="pro", model_client=client,
        system_message=(
            "You argue IN FAVOUR of the motion. "
            "Present strong, evidence-based arguments. Be persuasive and concise."
        ),
    )
    con_agent = AssistantAgent(
        name="con", model_client=client,
        system_message=(
            "You argue AGAINST the motion. "
            "Counter the opposing arguments with logic and evidence."
        ),
    )
    judge = AssistantAgent(
        name="judge", model_client=client,
        system_message=(
            "You are a neutral judge. After the debate, evaluate both sides fairly "
            "and declare which argument was more convincing and why."
        ),
    )

    # 2 rounds of debate (pro -> con x2) then the judge evaluates.
    termination = MaxMessageTermination(max_messages=7)
    team = RoundRobinGroupChat([pro_agent, con_agent, judge], termination_condition=termination)

    motion = "Artificial intelligence will create more jobs than it destroys."
    result = await team.run(task=f"Motion: {motion}")

    for msg in result.messages[1:]:  # skip the task message
        print(f"=== {msg.source.upper()} ===\n{msg.content}\n")

asyncio.run(debate_agents())
```

---

*End of EXAMPLES.md — 21 annotated AutoGen code examples covering all major framework patterns.*