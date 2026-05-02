# Semantic Kernel — Comprehensive Guide

> **Target audience:** Python developers building AI-powered applications with Microsoft's Semantic Kernel SDK.
> All code examples are self-contained and runnable.

---

## Table of Contents

1. [What is Semantic Kernel?](#1-what-is-semantic-kernel)
2. [Installation & Setup](#2-installation--setup)
3. [Kernel](#3-kernel)
4. [Plugins](#4-plugins)
5. [Function Calling & Auto-Invocation](#5-function-calling--auto-invocation)
6. [Chat Completion](#6-chat-completion)
7. [Planners](#7-planners)
8. [Memory & Embeddings](#8-memory--embeddings)
9. [Filters & Middleware](#9-filters--middleware)
10. [Dependency Injection](#10-dependency-injection)
11. [Processes (SK Process Framework)](#11-processes-sk-process-framework)
12. [Real-World SDLC Patterns](#12-real-world-sdlc-patterns)
13. [.NET vs Python Differences](#13-net-vs-python-differences)
14. [Interview Q&A](#14-interview-qa)
15. [Complete End-to-End Example](#15-complete-end-to-end-example)

---

## 1. What is Semantic Kernel?

Semantic Kernel (SK) is Microsoft's **open-source SDK** that lets you integrate Large Language Models (LLMs)
into applications using conventional programming patterns. Think of it as an orchestration layer between
your application code and AI models.

### Key Pillars

| Pillar | Description |
|---|---|
| **Kernel** | Central orchestrator — holds services, plugins, and settings |
| **Plugins** | Collections of AI or native functions the Kernel can invoke |
| **Planners** | Strategies for decomposing goals into sequences of function calls |
| **Memory** | Vector-store-backed semantic search over documents/data |
| **Filters** | Middleware hooks for logging, caching, safety, and telemetry |

### Multi-Language Support

- **Python** — `semantic-kernel` PyPI package (this guide)
- **C#** — `Microsoft.SemanticKernel` NuGet (most mature, production-first)
- **Java** — `com.microsoft.semantic-kernel` Maven artifact

### When to Use SK vs Alternatives

| Need | Best Tool |
|---|---|
| Enterprise .NET app + Azure OpenAI | **Semantic Kernel (C#)** |
| Python-first, many LLM providers, RAG pipelines | **LangChain** |
| Document indexing & retrieval | **LlamaIndex** |
| Agent loops with tool use, Python | **SK or LangChain Agents** |
| Tight Microsoft 365 / Copilot Studio integration | **Semantic Kernel** |

---

## 2. Installation & Setup

### Install the Package

```bash
pip install semantic-kernel          # core
pip install semantic-kernel[hugging_face]  # + HuggingFace
pip install semantic-kernel[chroma]        # + Chroma memory
```

### Option A — GitHub Copilot Free Auth (GitHub Models endpoint)

```python
import subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion

def get_kernel_via_github_copilot() -> Kernel:
    """Use `gh auth token` to authenticate against GitHub Models (free tier)."""
    token = subprocess.run(
        ["gh", "auth", "token"],
        capture_output=True, text=True
    ).stdout.strip()

    kernel = Kernel()
    kernel.add_service(
        OpenAIChatCompletion(
            ai_model_id="gpt-4o-mini",
            api_key=token,
            endpoint="https://models.inference.ai.azure.com",
        )
    )
    return kernel
```

### Option B — Standard OpenAI

```python
import os
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion

def get_kernel_openai() -> Kernel:
    kernel = Kernel()
    kernel.add_service(
        OpenAIChatCompletion(
            ai_model_id="gpt-4o",
            api_key=os.environ["OPENAI_API_KEY"],
        )
    )
    return kernel
```

### Option C — Azure OpenAI

```python
import os
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

def get_kernel_azure() -> Kernel:
    kernel = Kernel()
    kernel.add_service(
        AzureChatCompletion(
            deployment_name=os.environ["AZURE_OPENAI_DEPLOYMENT"],
            endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
        )
    )
    return kernel
```

### Option D — Local Model via Ollama

```python
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.ollama import OllamaChatCompletion

def get_kernel_ollama() -> Kernel:
    kernel = Kernel()
    kernel.add_service(
        OllamaChatCompletion(
            ai_model_id="llama3",   # model pulled via: ollama pull llama3
            host="http://localhost:11434",
        )
    )
    return kernel
```

---

## 3. Kernel

The `Kernel` is the central object. It wires together AI services, plugins, and execution settings.

### Creating & Configuring the Kernel

```python
import asyncio
import subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.connectors.ai.open_ai import OpenAIChatPromptExecutionSettings

# ── build kernel ──────────────────────────────────────────────────────────────
def build_kernel() -> Kernel:
    token = subprocess.run(
        ["gh", "auth", "token"], capture_output=True, text=True
    ).stdout.strip()

    kernel = Kernel()
    kernel.add_service(
        OpenAIChatCompletion(
            ai_model_id="gpt-4o-mini",
            api_key=token,
            endpoint="https://models.inference.ai.azure.com",
        )
    )
    return kernel

# ── invoke a plain prompt ─────────────────────────────────────────────────────
async def kernel_basics():
    kernel = build_kernel()

    # Create an inline prompt function
    summarize_fn = kernel.add_function(
        plugin_name="utils",
        function_name="summarize",
        prompt="Summarize this in one sentence: {{$input}}",
        prompt_execution_settings=OpenAIChatPromptExecutionSettings(
            temperature=0.3,
            max_tokens=100,
        ),
    )

    result = await kernel.invoke(
        summarize_fn,
        input="Semantic Kernel is an open-source SDK from Microsoft that helps developers "
              "integrate LLMs into their applications using plugins, planners, and memory.",
    )
    print(result)

asyncio.run(kernel_basics())
```

---

## 4. Plugins

Plugins are **named collections of functions**. SK ships two plugin flavours.

---

### 4.1 Semantic (Prompt) Plugins

Semantic plugins are LLM-backed functions defined by a prompt template.

#### Inline Definition

```python
import asyncio
import subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAIChatPromptExecutionSettings

async def semantic_plugin_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    settings = OpenAIChatPromptExecutionSettings(temperature=0.7, max_tokens=200)

    # {{$language}} and {{$code}} are template variables
    review_fn = kernel.add_function(
        plugin_name="CodeTools",
        function_name="review_snippet",
        prompt=(
            "You are a senior {{$language}} developer.\n"
            "Review the following code and list up to 3 improvements:\n\n"
            "```{{$language}}\n{{$code}}\n```"
        ),
        prompt_execution_settings=settings,
    )

    result = await kernel.invoke(
        review_fn,
        language="Python",
        code="def add(a,b):\n  return a+b",
    )
    print(result)

asyncio.run(semantic_plugin_demo())
```

#### Loading Plugins from a Directory

Directory layout:
```
plugins/
  WritingPlugin/
    Summarize/
      skprompt.txt      ← the prompt
      config.json       ← execution settings
```

`skprompt.txt`:
```
Summarize the following text in {{$sentences}} sentences:

{{$input}}
```

`config.json`:
```json
{
  "schema": 1,
  "description": "Summarize text",
  "execution_settings": {
    "default": { "max_tokens": 256, "temperature": 0.3 }
  },
  "input_variables": [
    { "name": "input",     "description": "Text to summarize", "required": true },
    { "name": "sentences", "description": "Target sentence count", "default": "3" }
  ]
}
```

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion

async def load_plugin_from_dir():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    # Load all plugins from a directory
    writing_plugin = kernel.add_plugin(
        parent_directory="./plugins",
        plugin_name="WritingPlugin",
    )
    result = await kernel.invoke(
        writing_plugin["Summarize"],
        input="Semantic Kernel enables developers to integrate AI into apps...",
        sentences="2",
    )
    print(result)
```

---

### 4.2 Native (Code) Plugins

Native plugins are plain Python classes decorated with `@kernel_function`.

```python
import asyncio, subprocess, math
from typing import Annotated
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.functions import kernel_function, KernelArguments

# ── define a native plugin ────────────────────────────────────────────────────
class MathPlugin:
    """Arithmetic helper functions exposed to the Kernel."""

    @kernel_function(name="sqrt", description="Return the square root of a number")
    def square_root(
        self,
        number: Annotated[float, "The number to take the square root of"],
    ) -> Annotated[float, "The square root result"]:
        return math.sqrt(number)

    @kernel_function(name="power", description="Raise base to the given exponent")
    def power(
        self,
        base: Annotated[float, "The base number"],
        exponent: Annotated[float, "The exponent"],
    ) -> Annotated[float, "base raised to exponent"]:
        return base ** exponent

    @kernel_function(name="summarize_stats", description="Return mean and max of a list")
    def summarize_stats(
        self,
        numbers: Annotated[str, "Comma-separated list of numbers e.g. '1,2,3'"],
    ) -> str:
        vals = [float(x.strip()) for x in numbers.split(",")]
        return f"mean={sum(vals)/len(vals):.2f}, max={max(vals):.2f}"


async def native_plugin_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    kernel.add_plugin(MathPlugin(), plugin_name="Math")

    # Direct invocation (no LLM hop)
    result = await kernel.invoke(
        kernel.plugins["Math"]["sqrt"],
        KernelArguments(number=144.0),
    )
    print(f"sqrt(144) = {result}")   # → 12.0

asyncio.run(native_plugin_demo())
```

---

## 5. Function Calling & Auto-Invocation

When `FunctionChoiceBehavior.Auto()` is set, the LLM decides **which plugin functions to call**
and SK executes them automatically.

```python
import asyncio, subprocess, datetime
from typing import Annotated
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import (
    OpenAIChatCompletion, OpenAIChatPromptExecutionSettings)
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function

# ── plugin with tools ─────────────────────────────────────────────────────────
class DevOpsPlugin:
    @kernel_function(description="Return the current UTC date and time")
    def get_current_time(self) -> str:
        return datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

    @kernel_function(description="List open pull requests for a repository")
    def list_open_prs(
        self,
        repo: Annotated[str, "Repository name in owner/repo format"],
    ) -> str:
        # Stub — replace with real GitHub API call
        return f"[stub] Open PRs for {repo}: #42 fix-login, #43 update-deps"

    @kernel_function(description="Get CI/CD status for a branch")
    def get_ci_status(
        self,
        repo: Annotated[str, "Repository name"],
        branch: Annotated[str, "Branch name"],
    ) -> str:
        return f"[stub] {repo}@{branch}: ✅ all checks passed"


async def auto_function_calling():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))
    kernel.add_plugin(DevOpsPlugin(), plugin_name="DevOps")

    settings = OpenAIChatPromptExecutionSettings(
        function_choice_behavior=FunctionChoiceBehavior.Auto(),  # ← key line
    )

    history = ChatHistory()
    history.add_user_message(
        "What time is it, and show me the open PRs for myorg/my-service?"
    )

    chat_service = kernel.get_service(type=OpenAIChatCompletion)
    response = await chat_service.get_chat_message_content(
        history, settings=settings, kernel=kernel
    )
    print(response)

asyncio.run(auto_function_calling())
```

---

## 6. Chat Completion

### Multi-Turn Chatbot with Streaming

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import (
    OpenAIChatCompletion, OpenAIChatPromptExecutionSettings)
from semantic_kernel.contents import ChatHistory

async def streaming_chatbot():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    service = OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com")
    kernel.add_service(service)

    history = ChatHistory()
    history.add_system_message(
        "You are a helpful software engineering assistant. "
        "Be concise. Format code in markdown fences."
    )

    settings = OpenAIChatPromptExecutionSettings(
        temperature=0.5, max_tokens=512,
        stream=True,
    )

    print("Chat started. Type 'exit' to quit.\n")
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in ("exit", "quit"):
            break

        history.add_user_message(user_input)

        print("Assistant: ", end="", flush=True)
        full_response = ""
        async for chunk in service.get_streaming_chat_message_content(
            history, settings=settings, kernel=kernel
        ):
            if chunk.content:
                print(chunk.content, end="", flush=True)
                full_response += chunk.content
        print()  # newline after streamed response

        history.add_assistant_message(full_response)

asyncio.run(streaming_chatbot())
```

### Non-Streaming Multi-Turn

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.contents import ChatHistory

async def simple_chatbot():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    service = OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com")
    kernel.add_service(service)

    history = ChatHistory()
    history.add_system_message("You are a helpful Python tutor.")

    for user_msg in [
        "What is a decorator in Python?",
        "Show me a simple example.",
    ]:
        history.add_user_message(user_msg)
        response = await service.get_chat_message_content(chat_history=history, kernel=kernel)
        history.add_assistant_message(str(response))
        print(f"User: {user_msg}\nAssistant: {response}\n")

asyncio.run(simple_chatbot())
```

---

## 7. Planners

### Evolution of SK Planners

| Era | Planner | Status |
|---|---|---|
| SK v0 | SequentialPlanner | ⚠️ Deprecated |
| SK v0 | StepwisePlanner | ⚠️ Deprecated |
| SK v1 | HandlebarsPlanner | ✅ Available |
| SK v1 | **Auto Function Calling** | ✅ Recommended |

### Handlebars Planner

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.planners.handlebars_planner import HandlebarsPlanner, HandlebarsPlannerOptions
from semantic_kernel.functions import kernel_function
from typing import Annotated

class ResearchPlugin:
    @kernel_function(description="Search the web for a given query")
    def web_search(self, query: Annotated[str, "Search query"]) -> str:
        return f"[stub] Search results for '{query}': ..."

    @kernel_function(description="Summarize a block of text")
    def summarize(self, text: Annotated[str, "Text to summarize"]) -> str:
        return f"[stub] Summary of: {text[:60]}..."

    @kernel_function(description="Save text to a file")
    def save_to_file(
        self,
        content: Annotated[str, "Content to save"],
        filename: Annotated[str, "Filename without extension"],
    ) -> str:
        return f"[stub] Saved {len(content)} chars to {filename}.txt"


async def handlebars_planner_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))
    kernel.add_plugin(ResearchPlugin(), plugin_name="Research")

    planner = HandlebarsPlanner(
        kernel,
        HandlebarsPlannerOptions(allow_loops=False, max_tokens=2048)
    )

    goal = (
        "Search for 'Semantic Kernel best practices', "
        "summarize the results, and save them to a file called 'sk_notes'."
    )
    plan = await planner.create_plan(goal)
    print("Generated plan:\n", plan.template)

    result = await plan.invoke(kernel)
    print("\nPlan result:", result)

asyncio.run(handlebars_planner_demo())
```

### Auto Function Calling as Modern Planner

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import (
    OpenAIChatCompletion, OpenAIChatPromptExecutionSettings)
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function
from typing import Annotated

class TaskPlugin:
    @kernel_function(description="Break a feature into subtasks")
    def decompose_feature(self, feature: Annotated[str, "Feature description"]) -> str:
        return "[stub] Subtasks: 1) write tests  2) implement  3) review  4) deploy"

    @kernel_function(description="Estimate effort in story points")
    def estimate_effort(self, task: Annotated[str, "Task description"]) -> str:
        return "[stub] Effort estimate: 3 story points"

async def auto_planner_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))
    kernel.add_plugin(TaskPlugin(), plugin_name="Tasks")

    settings = OpenAIChatPromptExecutionSettings(
        function_choice_behavior=FunctionChoiceBehavior.Auto(),
    )
    history = ChatHistory()
    history.add_user_message(
        "Decompose the feature 'user login with OAuth' and estimate each subtask."
    )
    service = kernel.get_service(type=OpenAIChatCompletion)
    result = await service.get_chat_message_content(history, settings=settings, kernel=kernel)
    print(result)

asyncio.run(auto_planner_demo())
```

---

## 8. Memory & Embeddings

### Volatile (In-Memory) Semantic Memory

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import (
    OpenAIChatCompletion, OpenAITextEmbedding)
from semantic_kernel.memory import SemanticTextMemory, VolatileMemoryStore
from semantic_kernel.core_plugins import TextMemoryPlugin

async def memory_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    # Embedding service for vectorising text
    embed_service = OpenAITextEmbedding(
        ai_model_id="text-embedding-3-small",
        api_key=token,
        endpoint="https://models.inference.ai.azure.com",
    )
    kernel.add_service(embed_service)

    memory = SemanticTextMemory(
        storage=VolatileMemoryStore(),
        embeddings_generator=embed_service,
    )
    kernel.add_plugin(TextMemoryPlugin(memory), plugin_name="memory")

    collection = "engineering_docs"

    # Store facts
    facts = [
        ("sk-intro",     "Semantic Kernel is Microsoft's open-source LLM SDK."),
        ("sk-plugins",   "Plugins are named collections of functions in Semantic Kernel."),
        ("sk-memory",    "SK memory uses vector embeddings to store and retrieve information."),
        ("sk-planners",  "Planners in SK orchestrate multi-step AI workflows."),
    ]
    for doc_id, text in facts:
        await memory.save_information(collection=collection, id=doc_id, text=text)

    # Semantic search
    query = "How does SK handle storage and retrieval?"
    results = await memory.search(collection=collection, query=query, limit=2)
    for r in results:
        print(f"  [{r.relevance:.2f}] {r.id}: {r.description or r.text[:80]}")

asyncio.run(memory_demo())
```

### Chroma Memory Store (persistent)

```python
# pip install semantic-kernel[chroma]
from semantic_kernel.connectors.memory.chroma import ChromaMemoryStore
from semantic_kernel.memory import SemanticTextMemory

def get_chroma_memory(embed_service) -> SemanticTextMemory:
    store = ChromaMemoryStore(persist_directory="./chroma_db")
    return SemanticTextMemory(storage=store, embeddings_generator=embed_service)
```

---

## 9. Filters & Middleware

Filters are hooks injected into the SK execution pipeline. Three filter interfaces exist:

| Filter | Trigger point |
|---|---|
| `IPromptRenderFilter` | Before prompt text is sent to the LLM |
| `IFunctionInvocationFilter` | Before/after any KernelFunction runs |
| `IAutoFunctionInvocationFilter` | Before/after automatic tool calls |

```python
import asyncio, subprocess, time, logging
from typing import Callable, Awaitable
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAIChatPromptExecutionSettings
from semantic_kernel.filters.functions.function_invocation_context import FunctionInvocationContext
from semantic_kernel.filters.prompts.prompt_render_context import PromptRenderContext
from semantic_kernel.filters import FilterTypes

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


# ── Logging filter: wraps every function call ─────────────────────────────────
class LoggingFunctionFilter:
    async def on_function_invocation(
        self,
        context: FunctionInvocationContext,
        next: Callable[[FunctionInvocationContext], Awaitable[None]],
    ) -> None:
        start = time.perf_counter()
        logger.info("→ Invoking %s.%s", context.function.plugin_name, context.function.name)
        await next(context)
        elapsed = (time.perf_counter() - start) * 1000
        logger.info("← Done %s.%s (%.1f ms)", context.function.plugin_name,
                    context.function.name, elapsed)


# ── Safety filter: block prompts containing PII keywords ─────────────────────
class SafetyPromptFilter:
    BLOCKED_KEYWORDS = {"password", "ssn", "credit card"}

    async def on_prompt_render(
        self,
        context: PromptRenderContext,
        next: Callable[[PromptRenderContext], Awaitable[None]],
    ) -> None:
        rendered = context.rendered_prompt or ""
        if any(kw in rendered.lower() for kw in self.BLOCKED_KEYWORDS):
            raise ValueError("Prompt blocked by safety filter: PII keyword detected.")
        await next(context)


async def filters_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    # Register filters
    kernel.add_filter(FilterTypes.FUNCTION_INVOCATION, LoggingFunctionFilter())
    kernel.add_filter(FilterTypes.PROMPT_RENDERING, SafetyPromptFilter())

    fn = kernel.add_function(
        plugin_name="demo",
        function_name="greet",
        prompt="Say hello to {{$name}} in a cheerful way.",
    )
    result = await kernel.invoke(fn, name="Alice")
    print(result)

asyncio.run(filters_demo())
```

---

## 10. Dependency Injection

The Kernel acts as a lightweight IoC container. Services registered on the Kernel are available
to all plugins and can be swapped per environment.

```python
import asyncio, subprocess, os
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, AzureChatCompletion
from semantic_kernel.connectors.ai.prompt_execution_settings import PromptExecutionSettings

# ── Service IDs allow named registration ─────────────────────────────────────
SERVICE_GITHUB = "github_models"
SERVICE_AZURE  = "azure_openai"

def build_multi_service_kernel() -> Kernel:
    kernel = Kernel()

    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

    # Primary: GitHub Models (free)
    kernel.add_service(
        OpenAIChatCompletion(
            service_id=SERVICE_GITHUB,
            ai_model_id="gpt-4o-mini",
            api_key=token,
            endpoint="https://models.inference.ai.azure.com",
        )
    )

    # Fallback: Azure OpenAI (only if env vars are set)
    if os.environ.get("AZURE_OPENAI_API_KEY"):
        kernel.add_service(
            AzureChatCompletion(
                service_id=SERVICE_AZURE,
                deployment_name=os.environ["AZURE_OPENAI_DEPLOYMENT"],
                endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
                api_key=os.environ["AZURE_OPENAI_API_KEY"],
            )
        )

    return kernel


async def di_demo():
    kernel = build_multi_service_kernel()

    # Explicitly request a service by ID
    service = kernel.get_service(service_id=SERVICE_GITHUB)
    print(f"Using service: {service.service_id}")

    fn = kernel.add_function(
        plugin_name="test",
        function_name="ping",
        prompt="Reply with exactly: pong",
    )
    result = await kernel.invoke(fn)
    print(result)

asyncio.run(di_demo())
```

---

## 11. Processes (SK Process Framework)

The Process Framework models **stateful, event-driven pipelines** as discrete steps connected by events.

```python
import asyncio, subprocess
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.processes.kernel_process import KernelProcess
from semantic_kernel.processes.process_builder import ProcessBuilder
from semantic_kernel.processes.local_runtime.local_kernel_process_context import LocalKernelProcessContext
from semantic_kernel.processes.process_step import KernelProcessStep
from semantic_kernel.processes.kernel_process_step_context import KernelProcessStepContext
from semantic_kernel.functions import kernel_function

# ── Step 1: Extract information from a raw document ──────────────────────────
class ExtractStep(KernelProcessStep):
    @kernel_function(name="extract")
    async def extract(self, context: KernelProcessStepContext, document: str) -> None:
        extracted = f"[Extracted] Title, Author, Date from: {document[:40]}..."
        print(f"  ExtractStep → {extracted}")
        await context.emit_event(process_event="extraction_done", data=extracted)


# ── Step 2: Summarise the extracted content ───────────────────────────────────
class SummarizeStep(KernelProcessStep):
    @kernel_function(name="summarize")
    async def summarize(self, context: KernelProcessStepContext, extracted: str) -> None:
        summary = f"[Summary] Key points from: {extracted[:50]}..."
        print(f"  SummarizeStep → {summary}")
        await context.emit_event(process_event="summary_done", data=summary)


# ── Step 3: Store the summary ─────────────────────────────────────────────────
class StoreStep(KernelProcessStep):
    @kernel_function(name="store")
    async def store(self, context: KernelProcessStepContext, summary: str) -> None:
        print(f"  StoreStep → Saved to DB: {summary[:60]}...")
        await context.emit_event(process_event="process_complete", data="done")


async def process_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    # ── wire the process ──────────────────────────────────────────────────────
    builder = ProcessBuilder(name="DocumentPipeline")

    extract_step   = builder.add_step(ExtractStep)
    summarize_step = builder.add_step(SummarizeStep)
    store_step     = builder.add_step(StoreStep)

    # Entry → Extract
    builder.on_input_event("start").send_event_to(
        target=extract_step, function_name="extract", parameter_name="document"
    )
    # Extract → Summarize
    extract_step.on_event("extraction_done").send_event_to(
        target=summarize_step, function_name="summarize", parameter_name="extracted"
    )
    # Summarize → Store
    summarize_step.on_event("summary_done").send_event_to(
        target=store_step, function_name="store", parameter_name="summary"
    )

    process: KernelProcess = builder.build()

    print("Running DocumentPipeline process...")
    async with LocalKernelProcessContext(process, kernel) as proc_ctx:
        await proc_ctx.start_with_event(
            process_event="start",
            data="Annual Report 2024: Revenue grew 42% year-over-year..."
        )

asyncio.run(process_demo())
```

---

## 12. Real-World SDLC Patterns

### Three SDLC Plugins

```python
import asyncio, subprocess
from typing import Annotated
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAIChatPromptExecutionSettings
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function

# ── Plugin 1: Code Review ─────────────────────────────────────────────────────
class CodeReviewPlugin:
    @kernel_function(description="Review Python code and return a list of issues")
    def review_code(
        self,
        code: Annotated[str, "Python source code to review"],
        focus: Annotated[str, "Review focus: security | performance | style"] = "style",
    ) -> str:
        # In production: call an AST linter or feed to LLM inline
        return (
            f"[CodeReview/{focus}]\n"
            "1. Missing type annotations on public functions.\n"
            "2. No error handling around I/O operations.\n"
            "3. Magic numbers should be named constants."
        )


# ── Plugin 2: Documentation Generator ────────────────────────────────────────
class DocGenPlugin:
    @kernel_function(description="Generate a NumPy-style docstring for a function signature")
    def generate_docstring(
        self,
        signature: Annotated[str, "Function signature e.g. def foo(x: int) -> str"],
        context: Annotated[str, "Brief description of what the function does"] = "",
    ) -> str:
        return (
            f'"""\n'
            f"{context or 'TODO: describe this function.'}\n\n"
            f"Parameters\n----------\nSee signature: {signature}\n\n"
            f"Returns\n-------\nstr\n"
            f'"""'
        )


# ── Plugin 3: Bug Triage ──────────────────────────────────────────────────────
class BugTriagePlugin:
    @kernel_function(description="Classify a bug report by severity and suggest owner")
    def triage_bug(
        self,
        title: Annotated[str, "Bug report title"],
        description: Annotated[str, "Bug description"],
    ) -> str:
        keywords_critical = {"crash", "data loss", "security", "outage"}
        severity = "CRITICAL" if any(k in description.lower() for k in keywords_critical) \
                   else "MEDIUM"
        return (
            f"Severity: {severity}\n"
            f"Suggested owner: @platform-team\n"
            f"Labels: bug, needs-repro\n"
            f"Priority: {'P0' if severity == 'CRITICAL' else 'P2'}"
        )


async def sdlc_demo():
    token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        ai_model_id="gpt-4o-mini", api_key=token,
        endpoint="https://models.inference.ai.azure.com"))

    kernel.add_plugin(CodeReviewPlugin(), plugin_name="CodeReview")
    kernel.add_plugin(DocGenPlugin(), plugin_name="DocGen")
    kernel.add_plugin(BugTriagePlugin(), plugin_name="BugTriage")

    settings = OpenAIChatPromptExecutionSettings(
        function_choice_behavior=FunctionChoiceBehavior.Auto(),
    )
    service = kernel.get_service(type=OpenAIChatCompletion)

    history = ChatHistory()
    history.add_system_message(
        "You are an SDLC assistant. Use available tools to help engineers."
    )

    for user_msg in [
        "Review this code for security issues:\ndef get_user(id):\n  return db.query(f'SELECT * FROM users WHERE id={id}')",
        "Generate a docstring for: def send_email(to: str, subject: str, body: str) -> bool",
        "Triage this bug: 'App crashes on login' — users report data loss after OAuth redirect fails.",
    ]:
        history.add_user_message(user_msg)
        response = await service.get_chat_message_content(
            history, settings=settings, kernel=kernel
        )
        history.add_assistant_message(str(response))
        print(f"User: {user_msg[:60]}...\nAssistant: {response}\n{'─'*60}")

asyncio.run(sdlc_demo())
```

---

## 13. .NET vs Python Differences

### Feature Parity Table (as of SK v1.x)

| Feature | C# | Python | Notes |
|---|---|---|---|
| Kernel core | ✅ | ✅ | Full parity |
| Semantic plugins | ✅ | ✅ | Full parity |
| Native plugins | ✅ | ✅ | Full parity |
| Auto Function Calling | ✅ | ✅ | Full parity |
| ChatHistory | ✅ | ✅ | Full parity |
| Streaming | ✅ | ✅ | Full parity |
| Handlebars Planner | ✅ | ✅ | Full parity |
| Process Framework | ✅ | ✅ | Beta in Python |
| Volatile Memory | ✅ | ✅ | Full parity |
| Chroma connector | ✅ | ✅ | Full parity |
| Qdrant connector | ✅ | ✅ | Full parity |
| Azure AI Search connector | ✅ | ✅ | Full parity |
| OpenAPI plugin import | ✅ | ✅ | Full parity |
| gRPC plugin | ✅ | ⚠️ Partial | C# ahead |
| Dependency Injection (MS DI) | ✅ Native | ❌ Manual | C# has MS.Extensions.DI |
| Copilot Studio integration | ✅ | ❌ | C# only |
| .NET Aspire observability | ✅ | ❌ | C# only |
| Blazor / ASP.NET integration | ✅ | ❌ | C# only |

### Python-Specific Notes

- **Async-first**: All SK Python I/O is `async/await` — design accordingly.
- **No built-in DI container**: Use a factory function or a framework like `dependency-injector`.
- **Process Framework in beta**: API surface may change between minor versions.
- **Plugin loading**: `kernel.add_plugin(parent_directory=…)` mirrors C# `ImportPluginFromPromptDirectory`.

### When to Choose C# SK

- You are building a production Microsoft 365 / Teams Copilot extension.
- You need tight Azure SDK integration (Key Vault, Service Bus, etc.).
- Your team is already in .NET and you want native DI + minimal-API hosting.
- You need Copilot Studio / Power Platform connectors.

---

## 14. Interview Q&A

**Q1: What is Semantic Kernel and how does it differ from LangChain?**
> Semantic Kernel (SK) is Microsoft's open-source SDK for integrating LLMs into applications using
> Plugins, Planners, and Memory. LangChain is a Python/JS framework with a broader ecosystem of
> integrations and a chain-based composition model. SK is preferred for enterprise .NET environments
> and Microsoft/Azure integration; LangChain is preferred for Python-first, provider-agnostic pipelines.

---

**Q2: What is a Plugin in Semantic Kernel?**
> A Plugin is a named collection of `KernelFunction` objects registered on the Kernel. Functions
> can be AI-backed (semantic) or plain Python (native). The LLM can automatically select and invoke
> plugin functions via Auto Function Calling.

---

**Q3: What is the difference between a Semantic Plugin and a Native Plugin?**
> A **Semantic Plugin** uses a prompt template and the LLM to produce output (e.g., `summarize`,
> `translate`). A **Native Plugin** is a Python class with `@kernel_function`-decorated methods that
> execute code directly — no LLM call required unless the code itself calls one.

---

**Q4: How does Auto Function Calling work in SK?**
> Set `FunctionChoiceBehavior.Auto()` in execution settings. SK serialises all registered plugin
> function schemas (name, description, parameters) and sends them to the LLM as tools. When the LLM
> emits a tool-call, SK intercepts it, invokes the function, appends the result, and sends everything
> back to the LLM for a final response — all transparently.

---

**Q5: What is ChatHistory and how is it managed?**
> `ChatHistory` is an ordered list of `ChatMessageContent` objects (system, user, assistant, tool).
> You manually append messages: `history.add_user_message(…)`, `history.add_assistant_message(…)`.
> It is passed to the chat completion service on every turn, giving the LLM full conversation context.

---

**Q6: What are Filters in Semantic Kernel?**
> Filters are middleware hooks that wrap the SK execution pipeline. Three types exist:
> `IFunctionInvocationFilter` (wraps every function call),
> `IPromptRenderFilter` (runs before the prompt is sent to the LLM), and
> `IAutoFunctionInvocationFilter` (wraps automatic tool calls). Common uses: logging, caching, safety, telemetry.

---

**Q7: How do you implement semantic memory in SK?**
> 1. Add an embedding service (e.g., `OpenAITextEmbedding`).
> 2. Create a `SemanticTextMemory` with a backing `MemoryStore` (e.g., `VolatileMemoryStore`, `ChromaMemoryStore`).
> 3. Register `TextMemoryPlugin(memory)` on the Kernel.
> 4. Call `await memory.save_information(collection, id, text)` to store.
> 5. Call `await memory.search(collection, query, limit)` to retrieve by semantic similarity.

---

**Q8: What is the SK Process Framework?**
> The Process Framework models event-driven, stateful workflows as `KernelProcessStep` subclasses
> connected via events. A `ProcessBuilder` wires steps together: each step emits events that trigger
> downstream steps. Useful for long-running document pipelines, approval workflows, and multi-agent
> orchestration.

---

**Q9: How do you use SK with Azure OpenAI vs OpenAI?**
> Replace `OpenAIChatCompletion` with `AzureChatCompletion` and supply
> `deployment_name`, `endpoint`, and `api_key`. Both implement the same `ChatCompletionClientBase`
> interface, so all Kernel code above that layer is unchanged.

---

**Q10: How do you add multiple AI services and switch between them?**
> Register each service with a unique `service_id`. Retrieve a specific one with
> `kernel.get_service(service_id="my_id")`. You can also set a default service by passing
> `service_id` first or relying on the first registered service as default.

---

**Q11: What is KernelArguments?**
> `KernelArguments` is a dict-like object that passes input values to a `KernelFunction`. It also
> holds `PromptExecutionSettings` for per-invocation overrides. Example:
> `KernelArguments(input="hello", settings=OpenAIChatPromptExecutionSettings(temperature=0.9))`.

---

**Q12: How do you stream responses in Semantic Kernel?**
> Call `service.get_streaming_chat_message_content(history, settings, kernel=kernel)` which
> returns an async generator. Set `stream=True` in execution settings and iterate with
> `async for chunk in …: print(chunk.content, end="")`.

---

**Q13: What happened to the old Planners (SequentialPlanner)?**
> `SequentialPlanner` and `StepwisePlanner` are deprecated in SK v1. The recommended replacement is
> **Auto Function Calling** with `FunctionChoiceBehavior.Auto()` — the LLM dynamically selects tools
> rather than a pre-planned sequence. `HandlebarsPlanner` remains available for deterministic plans.

---

**Q14: How does SK compare to LangChain for enterprise .NET applications?**
> SK is purpose-built for .NET with native Microsoft.Extensions.DependencyInjection, Azure SDK
> integration, and Copilot Studio connectors. LangChain has no mature .NET port. For .NET enterprise
> apps on Azure, SK is the clear choice; for Python-first or multi-cloud workloads, LangChain's
> broader integrations may be preferable.

---

**Q15: How do you create a plugin from an existing Python class?**
> Decorate methods with `@kernel_function(name="…", description="…")` and use
> `Annotated[type, "description"]` for parameter docs. Then:
> `kernel.add_plugin(MyClass(), plugin_name="MyPlugin")`. The Kernel introspects the class,
> wraps decorated methods as `KernelFunction` objects, and makes them available for direct
> invocation and LLM tool-calling.

---

## 15. Complete End-to-End Example

A fully working **SDLC Assistant** with three plugins, auto function calling, streaming output,
and a conversational loop — all in ~100 lines.

```python
"""
sdlc_assistant.py
─────────────────
SDLC AI assistant using Semantic Kernel with:
  - CodeReviewPlugin  : review code snippets
  - DocGenPlugin      : generate docstrings
  - TestSuggestPlugin : suggest unit tests
  - Auto Function Calling
  - Streaming chat output
  - Multi-turn ChatHistory

Run:  python sdlc_assistant.py
Requires: pip install semantic-kernel && gh auth login
"""
import asyncio
import subprocess
from typing import Annotated

from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import (
    OpenAIChatCompletion,
    OpenAIChatPromptExecutionSettings,
)
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function


# ── Plugin 1 ──────────────────────────────────────────────────────────────────
class CodeReviewPlugin:
    @kernel_function(description="Review Python code and return actionable feedback")
    def review(
        self,
        code: Annotated[str, "Python source code"],
        focus: Annotated[str, "Focus area: security | performance | readability"] = "readability",
    ) -> str:
        issues = {
            "security":     "• Potential SQL injection\n• Hard-coded credentials detected",
            "performance":  "• Avoid repeated DB calls in loops\n• Add caching layer",
            "readability":  "• Missing type hints\n• Long functions — consider splitting",
        }
        return f"[Review: {focus}]\n{issues.get(focus, 'No issues found.')}"


# ── Plugin 2 ──────────────────────────────────────────────────────────────────
class DocGenPlugin:
    @kernel_function(description="Generate a NumPy docstring for a Python function")
    def generate(
        self,
        signature: Annotated[str, "Function signature line"],
        purpose: Annotated[str, "One-line description of the function"] = "",
    ) -> str:
        return (
            f'"""\n{purpose or "TODO: add description."}\n\n'
            f"Parameters\n----------\nRefer to: {signature}\n\n"
            f"Returns\n-------\nSee return annotation.\n"
            f'"""'
        )


# ── Plugin 3 ──────────────────────────────────────────────────────────────────
class TestSuggestPlugin:
    @kernel_function(description="Suggest pytest unit tests for a Python function")
    def suggest_tests(
        self,
        function_name: Annotated[str, "Name of the function to test"],
        description: Annotated[str, "What the function does"],
    ) -> str:
        return (
            f"# Suggested tests for `{function_name}`\n"
            f"def test_{function_name}_happy_path(): ...\n"
            f"def test_{function_name}_empty_input(): ...\n"
            f"def test_{function_name}_invalid_type(): ...\n"
            f"def test_{function_name}_boundary_values(): ..."
        )


# ── Kernel factory ────────────────────────────────────────────────────────────
def build_kernel() -> Kernel:
    token = subprocess.run(
        ["gh", "auth", "token"], capture_output=True, text=True
    ).stdout.strip()
    kernel = Kernel()
    kernel.add_service(
        OpenAIChatCompletion(
            ai_model_id="gpt-4o-mini",
            api_key=token,
            endpoint="https://models.inference.ai.azure.com",
        )
    )
    kernel.add_plugin(CodeReviewPlugin(), plugin_name="CodeReview")
    kernel.add_plugin(DocGenPlugin(),     plugin_name="DocGen")
    kernel.add_plugin(TestSuggestPlugin(), plugin_name="TestSuggest")
    return kernel


# ── Main loop ─────────────────────────────────────────────────────────────────
async def main():
    kernel  = build_kernel()
    service = kernel.get_service(type=OpenAIChatCompletion)
    settings = OpenAIChatPromptExecutionSettings(
        function_choice_behavior=FunctionChoiceBehavior.Auto(),
        temperature=0.4,
        max_tokens=600,
    )

    history = ChatHistory()
    history.add_system_message(
        "You are an expert SDLC assistant. "
        "Use CodeReview, DocGen, and TestSuggest tools to help engineers. "
        "Be concise and actionable."
    )

    print("╔══════════════════════════════════════════╗")
    print("║       SDLC AI Assistant (SK + GPT)       ║")
    print("║  Type 'exit' to quit                     ║")
    print("╚══════════════════════════════════════════╝\n")

    while True:
        user_input = input("You: ").strip()
        if not user_input or user_input.lower() in ("exit", "quit"):
            print("Goodbye!")
            break

        history.add_user_message(user_input)
        print("\nAssistant: ", end="", flush=True)

        full_reply = ""
        async for chunk in service.get_streaming_chat_message_content(
            history, settings=settings, kernel=kernel
        ):
            if chunk.content:
                print(chunk.content, end="", flush=True)
                full_reply += chunk.content
        print("\n")

        history.add_assistant_message(full_reply)


if __name__ == "__main__":
    asyncio.run(main())
```

### Sample Session

```
You: Review this code for security: def login(user, pwd): return db.query(f"SELECT * FROM users WHERE user='{user}'")
Assistant: [Review: security]
• Potential SQL injection — never interpolate user input into SQL strings.
  Use parameterised queries: db.query("SELECT * FROM users WHERE user=?", (user,))
• Consider hashing passwords with bcrypt before comparison.

You: Suggest tests for the login function
Assistant: # Suggested tests for `login`
def test_login_happy_path(): ...
def test_login_empty_input(): ...
def test_login_invalid_type(): ...
def test_login_boundary_values(): ...

You: exit
Goodbye!
```

---

## Quick Reference

```python
# Kernel essentials
kernel = Kernel()
kernel.add_service(OpenAIChatCompletion(...))
kernel.add_plugin(MyPlugin(), plugin_name="MyPlugin")
result = await kernel.invoke(kernel.plugins["MyPlugin"]["my_fn"], arg="value")

# Auto function calling
settings = OpenAIChatPromptExecutionSettings(
    function_choice_behavior=FunctionChoiceBehavior.Auto()
)
response = await service.get_chat_message_content(history, settings=settings, kernel=kernel)

# Memory
memory = SemanticTextMemory(storage=VolatileMemoryStore(), embeddings_generator=embed_svc)
await memory.save_information(collection="docs", id="doc1", text="...")
results = await memory.search(collection="docs", query="...", limit=3)

# Filters
kernel.add_filter(FilterTypes.FUNCTION_INVOCATION, MyLoggingFilter())

# Streaming
async for chunk in service.get_streaming_chat_message_content(history, settings, kernel=kernel):
    print(chunk.content, end="")
```

---

*Generated with Semantic Kernel v1.x — Python SDK. For the latest API changes, see
[https://github.com/microsoft/semantic-kernel](https://github.com/microsoft/semantic-kernel).*
