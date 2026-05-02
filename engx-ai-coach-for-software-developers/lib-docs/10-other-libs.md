# Additional AI Libraries — Comprehensive Guide

> **Auth note (used throughout):** Every example that calls an LLM uses **GitHub Copilot free tier** via the OpenAI-compatible endpoint unless stated otherwise.
> ```python
> import openai
> client = openai.OpenAI(
>     base_url="https://models.inference.ai.azure.com",
>     api_key="<YOUR_GITHUB_TOKEN>",   # free at github.com/settings/tokens
> )
> MODEL = "gpt-4o-mini"
> ```

---

## Table of Contents
1. [Pydantic AI](#1-pydantic-ai)
2. [Smolagents (HuggingFace)](#2-smolagents-huggingface)
3. [Instructor](#3-instructor)
4. [Agno (formerly Phidata)](#4-agno-formerly-phidata)
5. [Marvin](#5-marvin)
6. [Guidance (Microsoft)](#6-guidance-microsoft)
7. [LangSmith (Observability)](#7-langsmith-observability)
8. [Flowise & n8n (No-Code/Low-Code)](#8-flowise--n8n-no-codelow-code)
9. [Quick Comparison Tables](#9-quick-comparison-tables)

---

## 1. Pydantic AI

### What It Is
Pydantic AI is a **type-safe, production-ready agent framework** built by the Pydantic team. It wraps LLM calls with full Pydantic validation, dependency injection, and structured output — making agents feel like ordinary Python functions.

```bash
pip install pydantic-ai
```

### Core Concepts

#### Agent
```python
from pydantic_ai import Agent

agent = Agent(
    model="openai:gpt-4o-mini",          # or "anthropic:claude-3-haiku"
    system_prompt="You are a helpful assistant.",
)

result = agent.run_sync("What is 2 + 2?")
print(result.data)   # "4"
```

#### Structured Output with Pydantic Models
```python
from pydantic import BaseModel
from pydantic_ai import Agent

class WeatherReport(BaseModel):
    city: str
    temperature_c: float
    condition: str
    humidity_percent: int

weather_agent = Agent(
    model="openai:gpt-4o-mini",
    result_type=WeatherReport,          # forces structured JSON output
    system_prompt="Return weather data as structured JSON.",
)

result = weather_agent.run_sync("Weather in Tokyo today?")
report: WeatherReport = result.data
print(f"{report.city}: {report.temperature_c}°C, {report.condition}")
```

#### RunContext and Dependency Injection
```python
from dataclasses import dataclass
from pydantic_ai import Agent, RunContext

@dataclass
class AppDeps:
    user_id: str
    db_connection: str   # mock

agent = Agent(
    model="openai:gpt-4o-mini",
    deps_type=AppDeps,
    system_prompt="Greet the user by their ID.",
)

@agent.system_prompt
def dynamic_prompt(ctx: RunContext[AppDeps]) -> str:
    return f"The current user ID is: {ctx.deps.user_id}"

deps = AppDeps(user_id="usr_42", db_connection="sqlite:///app.db")
result = agent.run_sync("Hello!", deps=deps)
print(result.data)
```

#### Tools
```python
from pydantic_ai import Agent, RunContext, Tool

def multiply(a: float, b: float) -> float:
    """Multiply two numbers."""
    return a * b

def lookup_price(ctx: RunContext[None], ticker: str) -> str:
    """Fake stock price lookup."""
    prices = {"AAPL": 189.5, "GOOG": 141.3}
    return str(prices.get(ticker.upper(), "unknown"))

calc_agent = Agent(
    model="openai:gpt-4o-mini",
    tools=[multiply, lookup_price],
    system_prompt="You are a financial calculator.",
)

result = calc_agent.run_sync("What is AAPL price times 100 shares?")
print(result.data)
```

#### ModelRetry
```python
from pydantic_ai import Agent, ModelRetry
from pydantic import BaseModel, field_validator

class PositiveInt(BaseModel):
    value: int

    @field_validator("value")
    @classmethod
    def must_be_positive(cls, v: int) -> int:
        if v <= 0:
            raise ModelRetry("Value must be positive. Try again with a positive integer.")
        return v

agent = Agent(model="openai:gpt-4o-mini", result_type=PositiveInt)
result = agent.run_sync("Give me the number negative five.")
print(result.data)  # agent will retry until it returns a positive int
```

#### Streaming Responses
```python
import asyncio
from pydantic_ai import Agent

stream_agent = Agent(
    model="openai:gpt-4o-mini",
    system_prompt="Write detailed technical explanations.",
)

async def stream_response():
    async with stream_agent.run_stream("Explain async/await in Python.") as resp:
        async for chunk in resp.stream_text():
            print(chunk, end="", flush=True)
    print()

asyncio.run(stream_response())
```

#### Testing with TestModel
```python
from pydantic_ai import Agent
from pydantic_ai.models.test import TestModel

agent = Agent("openai:gpt-4o-mini", system_prompt="Be helpful.")

def test_agent_response():
    with agent.override(model=TestModel()):
        result = agent.run_sync("Hello")
        assert isinstance(result.data, str)
        assert len(result.data) > 0
    print("Test passed!")

test_agent_response()
```

#### GitHub Copilot Free Auth Setup
```python
import os
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIModel
from openai import AsyncOpenAI

copilot_client = AsyncOpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ["GITHUB_TOKEN"],
)

model = OpenAIModel("gpt-4o-mini", openai_client=copilot_client)
agent = Agent(model=model, system_prompt="You are a helpful assistant.")
result = agent.run_sync("Summarize what Pydantic AI is.")
print(result.data)
```

### Full Example — Structured Invoice Extraction Agent
```python
"""
Invoice extraction agent using Pydantic AI with GitHub Copilot free auth.
Run: pip install pydantic-ai openai
"""
import os
from typing import List, Optional
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.models.openai import OpenAIModel
from openai import AsyncOpenAI

# ── Models ──────────────────────────────────────────────────────────────────
class LineItem(BaseModel):
    description: str
    quantity: float
    unit_price: float
    total: float

class Invoice(BaseModel):
    invoice_number: str
    vendor: str
    date: str
    line_items: List[LineItem]
    subtotal: float
    tax_rate_percent: float
    tax_amount: float
    total_due: float
    currency: str = Field(default="USD")
    notes: Optional[str] = None

# ── Auth ─────────────────────────────────────────────────────────────────────
client = AsyncOpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)
model = OpenAIModel("gpt-4o-mini", openai_client=client)

# ── Agent ─────────────────────────────────────────────────────────────────────
invoice_agent = Agent(
    model=model,
    result_type=Invoice,
    system_prompt=(
        "You are an expert invoice parser. Extract all invoice data precisely. "
        "Calculate totals if missing. Return structured JSON matching the schema."
    ),
)

SAMPLE_INVOICE = """
INVOICE #INV-2024-0892
Vendor: TechSupplies Co.
Date: 2024-11-15

Items:
- 3x USB-C Hub @ $29.99 each
- 1x Mechanical Keyboard @ $89.00
- 5x HDMI Cable 2m @ $12.50 each

Subtotal: $269.47
Tax (8%): $21.56
TOTAL DUE: $291.03

Note: Payment due within 30 days.
"""

def extract_invoice(raw_text: str) -> Invoice:
    result = invoice_agent.run_sync(f"Parse this invoice:\n\n{raw_text}")
    return result.data

if __name__ == "__main__":
    invoice = extract_invoice(SAMPLE_INVOICE)
    print(f"Invoice #: {invoice.invoice_number}")
    print(f"Vendor:    {invoice.vendor}")
    print(f"Items:     {len(invoice.line_items)}")
    for item in invoice.line_items:
        print(f"  - {item.description}: {item.quantity} × ${item.unit_price:.2f} = ${item.total:.2f}")
    print(f"Total Due: ${invoice.total_due:.2f} {invoice.currency}")
```

### Interview Q&A

**Q1: What makes Pydantic AI different from LangChain agents?**
A: Pydantic AI is type-safe by design — `result_type` forces the LLM to return a validated Pydantic model. LangChain uses string-based output parsers that can fail silently. Pydantic AI also has built-in dependency injection via `deps_type`, making unit testing trivial with `TestModel`.

**Q2: How does `ModelRetry` work?**
A: If a validator raises `ModelRetry("message")`, Pydantic AI sends the message back to the LLM and retries the call. This is used for self-healing loops where the LLM corrects its output until validation passes.

**Q3: What is `RunContext` used for?**
A: `RunContext[DepsType]` provides tools and system-prompt functions access to injected dependencies (database connections, config, user info) without polluting function signatures with global state.

**Q4: How do you test agents without making real API calls?**
A: Use `agent.override(model=TestModel())` as a context manager. `TestModel` returns canned responses and records all tool calls, enabling assertions without API costs.

**Q5: Can Pydantic AI stream structured outputs?**
A: Yes, via `run_stream()`. For structured types, use `stream_structured()` to get partial model updates as the JSON is streamed.

**Q6: How does `deps_type` enable dependency injection?**
A: You declare `deps_type=MyDeps` on the Agent. At call time you pass `deps=MyDeps(...)`. Tools and system prompts receive a `RunContext` whose `.deps` attribute is the injected object — clean inversion-of-control.

**Q7: What LLM providers does Pydantic AI support natively?**
A: OpenAI, Anthropic, Google Gemini, Groq, Mistral, Ollama (local), and any OpenAI-compatible endpoint (e.g., GitHub Copilot Models).

**Q8: How do you chain multiple Pydantic AI agents?**
A: Call `agent_b.run_sync(result_a.data.field)` or pass one agent's structured output as a tool call in another. For complex pipelines, use async and `asyncio.gather` for parallel execution.

---

## 2. Smolagents (HuggingFace)

### What It Is
Smolagents is a **minimal, code-first agent framework** from HuggingFace. Its flagship `CodeAgent` doesn't call tools by name — it *writes and executes Python code* to solve tasks, making it extremely flexible.

```bash
pip install smolagents
```

### CodeAgent vs ToolCallingAgent

| Feature | `CodeAgent` | `ToolCallingAgent` |
|---|---|---|
| Action format | Python code snippets | JSON tool calls |
| Flexibility | Very high | Standard |
| Security | Sandboxed execution | N/A |
| Best for | Complex multi-step tasks | Structured workflows |

```python
from smolagents import CodeAgent, HfApiModel

model = HfApiModel()   # uses HF Inference API; set HF_TOKEN env var

agent = CodeAgent(tools=[], model=model)
result = agent.run("Calculate the 15th Fibonacci number and return it.")
print(result)
```

### Built-in Tools
```python
from smolagents import CodeAgent, HfApiModel, DuckDuckGoSearchTool, PythonInterpreterTool

agent = CodeAgent(
    tools=[DuckDuckGoSearchTool(), PythonInterpreterTool()],
    model=HfApiModel(),
    max_steps=5,
)

result = agent.run("Search for the latest Python release and tell me what's new.")
print(result)
```

### Custom Tool
```python
from smolagents import CodeAgent, HfApiModel, tool

@tool
def word_count(text: str) -> int:
    """Count the number of words in a text string.
    
    Args:
        text: The input text to count words in.
    Returns:
        Integer count of words.
    """
    return len(text.split())

agent = CodeAgent(tools=[word_count], model=HfApiModel())
result = agent.run("How many words are in 'The quick brown fox jumps over the lazy dog'?")
print(result)
```

### Model Options
```python
from smolagents import HfApiModel, LiteLLMModel

# HuggingFace Inference API
hf_model = HfApiModel(model_id="Qwen/Qwen2.5-Coder-32B-Instruct")

# LiteLLM (supports 100+ providers including OpenAI-compatible)
litellm_model = LiteLLMModel(
    model_id="openai/gpt-4o-mini",
    api_base="https://models.inference.ai.azure.com",
    api_key="YOUR_GITHUB_TOKEN",
)
```

### Multi-Agent Orchestration with ManagedAgent
```python
from smolagents import CodeAgent, HfApiModel, ManagedAgent, DuckDuckGoSearchTool

model = HfApiModel()

# Specialist sub-agent
search_agent = CodeAgent(tools=[DuckDuckGoSearchTool()], model=model)
managed_searcher = ManagedAgent(
    agent=search_agent,
    name="web_searcher",
    description="Searches the web and returns summarized results.",
)

# Orchestrator that delegates to sub-agents
orchestrator = CodeAgent(
    tools=[managed_searcher],
    model=model,
    max_steps=8,
)

result = orchestrator.run(
    "Find the top 3 Python web frameworks by GitHub stars and compare them."
)
print(result)
```

### Full Example — CodeAgent Analyzing a CSV Dataset
```python
"""
CodeAgent that performs data analysis on a CSV dataset.
Run: pip install smolagents pandas
"""
import os
import textwrap
from smolagents import CodeAgent, LiteLLMModel, PythonInterpreterTool, tool

# ── Model (GitHub Copilot free auth via LiteLLM) ─────────────────────────────
model = LiteLLMModel(
    model_id="openai/gpt-4o-mini",
    api_base="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)

# ── Tool: create a sample CSV in memory ──────────────────────────────────────
@tool
def get_sales_csv() -> str:
    """Return a CSV string containing monthly sales data for analysis.
    
    Returns:
        CSV string with columns: month, product, units_sold, revenue_usd
    """
    return textwrap.dedent("""
        month,product,units_sold,revenue_usd
        Jan,Widget A,120,2400
        Jan,Widget B,85,4250
        Feb,Widget A,145,2900
        Feb,Widget B,92,4600
        Mar,Widget A,200,4000
        Mar,Widget B,78,3900
        Apr,Widget A,180,3600
        Apr,Widget B,110,5500
        May,Widget A,220,4400
        May,Widget B,130,6500
    """).strip()

# ── Agent ─────────────────────────────────────────────────────────────────────
agent = CodeAgent(
    tools=[get_sales_csv, PythonInterpreterTool()],
    model=model,
    max_steps=6,
    additional_authorized_imports=["pandas", "io"],
)

TASK = """
Using the sales CSV from get_sales_csv():
1. Load it into a pandas DataFrame
2. Calculate total revenue per product
3. Find the best-selling month by units sold
4. Calculate month-over-month growth rate for Widget A
5. Return a summary report as a formatted string
"""

if __name__ == "__main__":
    report = agent.run(TASK)
    print("=" * 60)
    print("SALES ANALYSIS REPORT")
    print("=" * 60)
    print(report)
```

### Interview Q&A

**Q1: How does `CodeAgent` differ from tool-calling agents?**
A: Instead of selecting a named tool from a list, `CodeAgent` writes Python code that can import libraries, loop, and compose operations. The code runs in a sandboxed interpreter. This gives it far more problem-solving flexibility.

**Q2: What security measures does smolagents' sandboxed execution provide?**
A: The `PythonInterpreterTool` restricts available modules to a whitelist (`additional_authorized_imports`). Dangerous builtins are blocked. For production, you can run in a Docker container or E2B sandbox.

**Q3: When would you choose `ToolCallingAgent` over `CodeAgent`?**
A: When you need predictable, auditable tool invocations (e.g., regulated environments), when tools have side effects you want to control precisely, or when the LLM isn't strong enough to reliably write correct Python.

**Q4: How does `ManagedAgent` enable multi-agent systems?**
A: A `ManagedAgent` wraps a sub-agent and exposes it as a *tool* to an orchestrator agent. The orchestrator calls it by name with a task string, and the sub-agent executes independently and returns results.

**Q5: What is `HfApiModel` and when is it free?**
A: It calls the HuggingFace Inference API. Free tier allows limited calls to many open-source models (Qwen, Mistral, etc.) with a free `HF_TOKEN`. For production scale, use paid HF Inference Endpoints.

**Q6: How do you write a valid `@tool` function?**
A: The docstring is mandatory — smolagents parses it to generate the tool description. The function signature types are also required. Return types should be primitives or serializable objects.

**Q7: Can smolagents handle vision/multimodal inputs?**
A: Yes. Pass `PIL.Image` objects or URLs in the task. Some models (LLaVA, Idefics) support vision natively, and smolagents passes image data through the message pipeline.

**Q8: How does smolagents compare to OpenAI Assistants API?**
A: Smolagents is model-agnostic and runs locally/open-source. OpenAI Assistants is proprietary. Smolagents' CodeAgent is more powerful for data tasks; Assistants has better file handling and persistent threads.

---

## 3. Instructor

### What It Is
Instructor is the most popular library for **structured LLM outputs** — it patches any OpenAI-compatible client to return validated Pydantic models instead of raw strings.

```bash
pip install instructor
```

### Patching the Client
```python
import instructor
import openai
import os

# Patch an existing client
raw_client = openai.OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)
client = instructor.from_openai(raw_client)   # or instructor.patch(raw_client)
```

### Pydantic Model Extraction
```python
from pydantic import BaseModel
from typing import List

class Person(BaseModel):
    name: str
    age: int
    email: str

person = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=Person,
    messages=[{"role": "user", "content": "Extract: John Doe, 34, john@example.com"}],
)
print(person.name, person.age, person.email)
```

### Partial Streaming
```python
from instructor import Partial
import instructor, openai, os

client = instructor.from_openai(
    openai.OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
    )
)

class Article(BaseModel):
    title: str
    summary: str
    keywords: List[str]

for partial_article in client.chat.completions.create_partial(
    model="gpt-4o-mini",
    response_model=Article,
    messages=[{"role": "user", "content": "Write an article about Python 3.13 features."}],
):
    print(f"\r{partial_article}", end="", flush=True)
```

### Validation and Retry
```python
from pydantic import BaseModel, field_validator
import instructor, openai, os

client = instructor.from_openai(
    openai.OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
    ),
    max_retries=3,   # auto-retry on validation failure
)

class ProductCode(BaseModel):
    code: str

    @field_validator("code")
    @classmethod
    def must_be_uppercase(cls, v: str) -> str:
        if not v.isupper():
            raise ValueError(f"Product code '{v}' must be uppercase. E.g. ABC-123")
        return v

product = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=ProductCode,
    messages=[{"role": "user", "content": "Create a product code for 'blue widget'"}],
)
print(product.code)   # guaranteed uppercase after retries
```

### Batch Extraction
```python
from pydantic import BaseModel
from typing import List

class Company(BaseModel):
    name: str
    industry: str
    founded_year: int

TEXT = """
Apple was founded in 1976 and operates in consumer electronics.
Google, a tech search company, started in 1998.
Tesla disrupted automotive in 2003.
"""

companies = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=List[Company],
    messages=[{"role": "user", "content": f"Extract all companies from:\n{TEXT}"}],
)
for c in companies:
    print(f"{c.name} ({c.industry}, {c.founded_year})")
```

### Full Example — Invoice Parser
```python
"""
Invoice parser using Instructor with GitHub Copilot free auth.
Run: pip install instructor openai pydantic
"""
import os
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator
import instructor
import openai

# ── Client ───────────────────────────────────────────────────────────────────
raw = openai.OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)
client = instructor.from_openai(raw, max_retries=2)

# ── Schema ────────────────────────────────────────────────────────────────────
class LineItem(BaseModel):
    description: str
    quantity: float = Field(gt=0)
    unit_price: float = Field(gt=0)
    total: float

    @field_validator("total")
    @classmethod
    def total_matches(cls, v: float, info) -> float:
        expected = info.data.get("quantity", 0) * info.data.get("unit_price", 0)
        if abs(v - expected) > 0.05:
            raise ValueError(f"Total {v} ≠ qty×price {expected:.2f}")
        return round(expected, 2)

class ParsedInvoice(BaseModel):
    invoice_id: str
    vendor_name: str
    invoice_date: str
    line_items: List[LineItem]
    subtotal: float
    tax_pct: float = Field(ge=0, le=100)
    total_due: float
    currency: str = "USD"
    payment_terms: Optional[str] = None

# ── Parser function ───────────────────────────────────────────────────────────
def parse_invoice(raw_text: str) -> ParsedInvoice:
    return client.chat.completions.create(
        model="gpt-4o-mini",
        response_model=ParsedInvoice,
        messages=[
            {"role": "system", "content": "Extract invoice data precisely. Validate all math."},
            {"role": "user", "content": f"Parse this invoice:\n\n{raw_text}"},
        ],
    )

RAW_INVOICE = """
INVOICE #2024-0555  |  Date: 2024-10-22
From: CloudHost Pro

Services:
- Compute Instance (t3.medium) x1 month  $48.00
- Storage 500GB SSD x1 month             $25.00
- Bandwidth 1TB                          $12.00
- Support (Standard) x1                  $15.00

Subtotal: $100.00
Tax (10%): $10.00
TOTAL: $110.00
Terms: Net 30
"""

if __name__ == "__main__":
    inv = parse_invoice(RAW_INVOICE)
    print(f"Invoice: {inv.invoice_id}")
    print(f"Vendor:  {inv.vendor_name}")
    print(f"Date:    {inv.invoice_date}")
    print(f"Items ({len(inv.line_items)}):")
    for item in inv.line_items:
        print(f"  {item.description:<40} ${item.total:>8.2f}")
    print(f"{'Subtotal':<42} ${inv.subtotal:>8.2f}")
    print(f"{'Tax (' + str(inv.tax_pct) + '%)':<42} ${inv.total_due - inv.subtotal:>8.2f}")
    print(f"{'TOTAL DUE':<42} ${inv.total_due:>8.2f} {inv.currency}")
    print(f"Terms: {inv.payment_terms}")
```

### Interview Q&A

**Q1: What does `instructor.from_openai()` actually do?**
A: It wraps the client to intercept `chat.completions.create()` calls. When `response_model` is provided, it injects a function-calling schema, parses the JSON response, instantiates the Pydantic model, runs validators, and retries on failure.

**Q2: How does `max_retries` interact with Pydantic validators?**
A: If a validator raises `ValueError`, Instructor catches it, formats the error message, and appends it to the conversation as a user message asking the LLM to fix the output. It retries up to `max_retries` times.

**Q3: What is `Partial[Model]` used for in streaming?**
A: `Partial[Model]` makes all fields `Optional` internally. As the LLM streams JSON tokens, Instructor yields partially-filled model instances. This lets UIs show progressive results before completion.

**Q4: Can Instructor work with non-OpenAI LLMs?**
A: Yes. `instructor.from_anthropic()`, `instructor.from_gemini()`, `instructor.from_litellm()`, and any OpenAI-compatible endpoint via `from_openai()`.

**Q5: How does Instructor differ from just asking the LLM to return JSON?**
A: Raw JSON prompting fails ~15-30% of the time. Instructor uses function-calling (or tool-use) mode which forces JSON schema compliance at the API level. Validators provide a second layer of guarantee with automatic retry.

**Q6: How do you extract a list of objects with Instructor?**
A: Set `response_model=List[MyModel]`. Instructor wraps it in a container schema and returns a Python list.

**Q7: What modes does Instructor support?**
A: `TOOLS` (default, function-calling), `JSON` (JSON mode), `MD_JSON` (markdown JSON), `FUNCTIONS` (legacy), `PARALLEL_TOOLS`. Choose based on model support.

**Q8: When should you use Instructor vs Pydantic AI?**
A: Use Instructor when you want structured outputs with minimal framework overhead — just patch your existing client. Use Pydantic AI when you need full agents with tools, dependency injection, and multi-turn conversations.

---

## 4. Agno (formerly Phidata)

### What It Is
Agno is a **multi-modal, batteries-included agent framework** with built-in knowledge bases, persistent storage, memory, and a team-of-agents architecture. Previously known as Phidata.

```bash
pip install agno
```

### Basic Agent
```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat

agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini"),
    instructions=["Be concise", "Use bullet points"],
    show_tool_calls=True,
    markdown=True,
)
agent.print_response("What are the SOLID principles?")
```

### Built-in Tools
```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools.duckduckgo import DuckDuckGoTools
from agno.tools.yfinance import YFinanceTools
from agno.tools.python import PythonTools

finance_agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini"),
    tools=[
        DuckDuckGoTools(),
        YFinanceTools(stock_price=True, analyst_recommendations=True),
        PythonTools(),
    ],
    instructions=["Provide data-backed financial analysis."],
    show_tool_calls=True,
)

finance_agent.print_response("Analyze AAPL stock performance this quarter.")
```

### Knowledge Bases
```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.knowledge.pdf import PDFKnowledgeBase
from agno.vectordb.pgvector import PgVector

knowledge = PDFKnowledgeBase(
    path="docs/",                  # directory of PDFs
    vector_db=PgVector(
        table_name="knowledge",
        db_url="postgresql://user:pass@localhost/agno",
    ),
)
knowledge.load(recreate=False)     # idempotent; only indexes new files

agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini"),
    knowledge=knowledge,
    search_knowledge=True,         # agent can query the KB
    instructions=["Answer from the knowledge base only."],
)
agent.print_response("Summarize the onboarding document.")
```

### Storage (Persistent Memory)
```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.storage.sqlite import SqliteStorage

agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini"),
    storage=SqliteStorage(table_name="sessions", db_file="agent.db"),
    add_history_to_messages=True,  # multi-turn memory
    num_history_responses=5,
    session_id="user-123",         # persist per user
)

agent.print_response("My name is Alice.")
agent.print_response("What is my name?")   # remembers "Alice"
```

### Team of Agents
```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools.duckduckgo import DuckDuckGoTools
from agno.tools.yfinance import YFinanceTools

researcher = Agent(
    name="Researcher",
    role="Search the web for latest news and trends",
    model=OpenAIChat(id="gpt-4o-mini"),
    tools=[DuckDuckGoTools()],
)

analyst = Agent(
    name="Analyst",
    role="Analyze financial data and provide investment insights",
    model=OpenAIChat(id="gpt-4o-mini"),
    tools=[YFinanceTools(stock_price=True, stock_fundamentals=True)],
)

team = Agent(
    team=[researcher, analyst],
    model=OpenAIChat(id="gpt-4o-mini"),
    instructions=["Coordinate the team to answer the query."],
)

team.print_response("Should I invest in NVDA given recent AI news?")
```

### Full Example — Financial Research Agent
```python
"""
Financial research agent with knowledge base using Agno.
Run: pip install agno yfinance duckduckgo-search
"""
import os
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools.duckduckgo import DuckDuckGoTools
from agno.tools.yfinance import YFinanceTools
from agno.tools.python import PythonTools
from agno.storage.sqlite import SqliteStorage

# ── Configure OpenAI-compatible client for GitHub Copilot ────────────────────
import openai
openai.base_url = "https://models.inference.ai.azure.com"
openai.api_key = os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN")

# ── Build the research agent ──────────────────────────────────────────────────
research_agent = Agent(
    name="FinResearch",
    model=OpenAIChat(id="gpt-4o-mini"),
    tools=[
        DuckDuckGoTools(),
        YFinanceTools(
            stock_price=True,
            analyst_recommendations=True,
            company_info=True,
            stock_fundamentals=True,
        ),
        PythonTools(),
    ],
    storage=SqliteStorage(table_name="fin_sessions", db_file="finance.db"),
    add_history_to_messages=True,
    instructions=[
        "Always search for latest news before providing analysis.",
        "Include P/E ratio, revenue growth, and analyst sentiment.",
        "Format output with clear sections: Summary, Financials, Risks.",
        "Never provide direct investment advice.",
    ],
    show_tool_calls=True,
    markdown=True,
)

QUERIES = [
    "Give me an overview of Microsoft's current financial health.",
    "What are the key risks facing MSFT in the next 12 months?",
    "Compare MSFT vs GOOGL on revenue growth.",
]

if __name__ == "__main__":
    for query in QUERIES:
        print(f"\n{'='*60}\nQuery: {query}\n{'='*60}")
        research_agent.print_response(query)
```

### Interview Q&A

**Q1: What was Phidata and why was it renamed to Agno?**
A: Phidata was the original name of the framework. It was rebranded to Agno to reflect its evolution beyond simple agents into a full agentic OS with multi-modal, multi-agent, and knowledge capabilities.

**Q2: How does Agno's `knowledge` parameter work?**
A: You attach a `KnowledgeBase` (PDF, website, text, Arxiv, etc.) backed by a vector store. When `search_knowledge=True`, the agent automatically queries the vector store before answering, enabling RAG without manual retrieval code.

**Q3: What is `SqliteStorage` used for in Agno?**
A: It persists agent sessions (conversation history, memory) to SQLite. Combined with a fixed `session_id`, the agent remembers context across application restarts — useful for long-running assistants.

**Q4: How does the team-of-agents pattern work in Agno?**
A: A coordinator `Agent` has `team=[agent_a, agent_b, ...]`. It routes sub-tasks to specialists and aggregates results. Each sub-agent runs independently and returns to the coordinator.

**Q5: What vector databases does Agno support?**
A: PgVector (PostgreSQL), LanceDB, Qdrant, Chroma, Pinecone, Weaviate, and SingleStore. LanceDB is preferred for local development (no server needed).

**Q6: How does Agno handle multi-modal inputs?**
A: Pass `images=["path.jpg"]` or `audio=["file.mp3"]` to `agent.print_response()`. The model processes them alongside the text prompt if the underlying model supports vision/audio.

**Q7: What is the difference between `add_history_to_messages` and `memory`?**
A: `add_history_to_messages` prepends recent conversation turns to the context window. `memory` is a semantic memory system that summarizes and retrieves relevant past facts — better for long-running agents.

**Q8: Can Agno agents run asynchronously?**
A: Yes, use `await agent.arun("prompt")` or `agent.aprint_response()` in async contexts. Parallel agent execution in teams is also supported.

---

## 5. Marvin

### What It Is
Marvin is a **Pythonic AI toolkit** that exposes LLM capabilities as clean Python functions: `cast`, `classify`, `extract`, `generate`. It feels like adding AI to a function call.

```bash
pip install marvin
```

### `marvin.cast()` — Type Conversion
```python
import marvin

result = marvin.cast("three hundred and forty-two dollars", target=float)
print(result)   # 342.0

from datetime import date
d = marvin.cast("last Friday", target=date)
print(d)        # actual date object
```

### `marvin.classify()` — Classification
```python
from enum import Enum
import marvin

class Sentiment(Enum):
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"

texts = [
    "I absolutely love this product!",
    "It's okay, nothing special.",
    "Terrible experience, would not recommend.",
]

for text in texts:
    label = marvin.classify(text, labels=Sentiment)
    print(f"{label.value:<10} | {text}")
```

### `marvin.extract()` — Entity Extraction
```python
from pydantic import BaseModel
from typing import List
import marvin

class Person(BaseModel):
    name: str
    role: str

text = """
The meeting was attended by Alice Johnson (CTO), Bob Smith (Lead Engineer),
and Carol White (Product Manager). Alice presented the Q3 roadmap.
"""

people: List[Person] = marvin.extract(text, target=Person)
for p in people:
    print(f"{p.name} — {p.role}")
```

### `marvin.generate()` — List Generation
```python
import marvin
from pydantic import BaseModel

class TestCase(BaseModel):
    scenario: str
    input_data: str
    expected_output: str

cases = marvin.generate(
    target=TestCase,
    n=5,
    instructions="Generate unit test cases for a function that validates email addresses.",
)
for i, case in enumerate(cases, 1):
    print(f"Test {i}: {case.scenario}")
    print(f"  Input:    {case.input_data}")
    print(f"  Expected: {case.expected_output}")
```

### `@marvin.fn` Decorator
```python
import marvin
from typing import List

@marvin.fn
def suggest_variable_names(description: str, style: str = "snake_case") -> List[str]:
    """Suggest 5 appropriate variable names for the given description in the specified style."""

names = suggest_variable_names("a counter that tracks how many retries have occurred")
print(names)   # ['retry_count', 'retry_attempts', 'num_retries', ...]
```

### `@marvin.model` for Pydantic AI Models
```python
import marvin
from pydantic import BaseModel

@marvin.model
class CodeReview(BaseModel):
    """Extract a code review from developer feedback text."""
    issues_found: int
    severity: str     # low | medium | high | critical
    suggested_refactors: list[str]
    overall_score: float  # 0.0 to 10.0

review = CodeReview("This PR has 3 null pointer issues, one critical SQL injection. Refactor the DB layer.")
print(review.severity)        # critical
print(review.issues_found)    # 3
```

### GitHub Copilot Free Auth
```python
import marvin
import marvin.settings

marvin.settings.openai.api_key = "YOUR_GITHUB_TOKEN"
marvin.settings.openai.base_url = "https://models.inference.ai.azure.com"
marvin.settings.openai.chat_completions_model = "gpt-4o-mini"
```

### Full Example — Complete Text Analysis Pipeline
```python
"""
Full text analysis pipeline: classify → extract → generate → summarize.
Run: pip install marvin
"""
import marvin
import marvin.settings
import os
from enum import Enum
from pydantic import BaseModel
from typing import List

# ── Auth ─────────────────────────────────────────────────────────────────────
marvin.settings.openai.api_key = os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN")
marvin.settings.openai.base_url = "https://models.inference.ai.azure.com"
marvin.settings.openai.chat_completions_model = "gpt-4o-mini"

# ── Schema ────────────────────────────────────────────────────────────────────
class Category(Enum):
    BUG_REPORT = "bug_report"
    FEATURE_REQUEST = "feature_request"
    QUESTION = "question"
    COMPLAINT = "complaint"
    PRAISE = "praise"

class Urgency(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class Entity(BaseModel):
    text: str
    entity_type: str  # person | product | version | component

class ActionItem(BaseModel):
    task: str
    assignee_role: str
    priority: str

# ── Pipeline ──────────────────────────────────────────────────────────────────
def analyze_ticket(ticket_text: str) -> dict:
    print("📋 Classifying ticket...")
    category = marvin.classify(ticket_text, labels=Category)
    urgency = marvin.classify(ticket_text, labels=Urgency)

    print("🔍 Extracting entities...")
    entities: List[Entity] = marvin.extract(ticket_text, target=Entity)

    print("📝 Generating action items...")
    actions: List[ActionItem] = marvin.generate(
        target=ActionItem,
        n=3,
        instructions=f"Generate action items for this {category.value}: {ticket_text}",
    )

    print("✨ Generating summary...")
    @marvin.fn
    def summarize_ticket(text: str, cat: str, urg: str) -> str:
        """Write a 2-sentence executive summary of a support ticket."""
    
    summary = summarize_ticket(ticket_text, category.value, urgency.value)

    return {
        "category": category.value,
        "urgency": urgency.value,
        "entities": [{"text": e.text, "type": e.entity_type} for e in entities],
        "actions": [{"task": a.task, "role": a.assignee_role} for a in actions],
        "summary": summary,
    }

TICKET = """
Hi team — our production deployment of version 2.4.1 is crashing on startup
in the authentication module. Users including John from Acme Corp are completely
locked out. The error appears in the JWT validation component. We need an 
emergency patch ASAP as this is impacting 500+ enterprise customers.
"""

if __name__ == "__main__":
    result = analyze_ticket(TICKET)
    print("\n" + "="*60)
    print(f"Category: {result['category'].upper()}")
    print(f"Urgency:  {result['urgency'].upper()}")
    print(f"\nEntities found ({len(result['entities'])}):")
    for e in result["entities"]:
        print(f"  [{e['type']}] {e['text']}")
    print(f"\nAction Items:")
    for i, a in enumerate(result["actions"], 1):
        print(f"  {i}. [{a['role']}] {a['task']}")
    print(f"\nSummary:\n{result['summary']}")
```

### Interview Q&A

**Q1: What is the difference between `marvin.cast()` and `marvin.extract()`?**
A: `cast()` converts a single value to a target type (like Python's built-in `cast`). `extract()` finds *multiple instances* of a structured type within a larger text — it returns a list.

**Q2: How does `@marvin.fn` work under the hood?**
A: It sends the function's docstring, signature, and arguments as a prompt to the LLM and parses the return value to match the annotated return type. The function body is irrelevant; only the signature and docstring matter.

**Q3: When would you use `marvin.generate()` vs `marvin.extract()`?**
A: `extract()` finds things that *exist* in text. `generate()` *creates* new instances of a type based on instructions. Use `generate()` for synthetic data, test cases, or creative content.

**Q4: How does `@marvin.model` differ from a plain Pydantic model?**
A: A `@marvin.model` class becomes callable — passing text to the constructor populates all fields via LLM extraction. Plain Pydantic models require explicit field assignment.

**Q5: What LLM backends does Marvin support?**
A: Marvin uses Instructor + OpenAI by default, but supports any OpenAI-compatible endpoint. Set `marvin.settings.openai.base_url` to point to Anthropic/Groq/local models via LiteLLM.

**Q6: How do you use `marvin.classify()` with string labels instead of Enums?**
A: Pass a list: `marvin.classify(text, labels=["sports", "politics", "tech"])`. Marvin returns one of the list items as a string.

**Q7: Can Marvin functions be async?**
A: Yes. `amarvin.cast()`, `amarvin.classify()`, etc. are async variants. `@marvin.fn` with an `async def` also works.

**Q8: How would you use Marvin in a CI/CD pipeline?**
A: Use `marvin.classify()` to auto-label PRs, `marvin.extract()` to pull JIRA keys from commit messages, `marvin.generate()` to create changelog entries, and `@marvin.fn` to summarize diffs for Slack notifications.

---

## 6. Guidance (Microsoft)

### What It Is
Guidance is Microsoft's library for **constrained LLM generation** — you interleave prompts and generation directives in a single template, controlling exactly what the model outputs character-by-character.

```bash
pip install guidance
```

### Basic Generation
```python
import guidance
from guidance import models, gen, select

# OpenAI backend
lm = models.OpenAI("gpt-4o-mini")

# gen() generates constrained text inline
result = lm + "The capital of France is " + gen("capital", max_tokens=5, stop=".")
print(result["capital"])   # Paris
```

### `select()` for Enumerated Choices
```python
import guidance
from guidance import models, select, gen

lm = models.OpenAI("gpt-4o-mini")

sentiment_template = lm + (
    "Review: 'This laptop is incredibly fast and the battery lasts all day.'\n"
    "Sentiment: " + select(["positive", "negative", "neutral"], name="sentiment") + "\n"
    "Score (1-10): " + gen("score", regex=r"[1-9]|10", max_tokens=2) + "\n"
)

print(sentiment_template["sentiment"])  # positive
print(sentiment_template["score"])      # e.g. 9
```

### Regex-Constrained Generation
```python
from guidance import models, gen

lm = models.OpenAI("gpt-4o-mini")

# Generate a date in ISO format only
result = lm + "Today's date is: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}")
print(result["date"])   # guaranteed format: 2024-11-15

# Generate a valid IP address
result2 = lm + "Server IP: " + gen("ip", regex=r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
print(result2["ip"])
```

### Handlebars-Style Templates
```python
from guidance import models, gen, select, system, user, assistant

lm = models.OpenAI("gpt-4o-mini")

with system():
    lm += "You are a code review assistant that produces structured reports."

with user():
    lm += "Review this Python function:\n```python\ndef add(a, b):\n    return a + b\n```"

with assistant():
    lm += (
        "**Review Report**\n"
        "Quality: " + select(["excellent", "good", "needs_improvement", "poor"], name="quality") + "\n"
        "Issues Found: " + gen("issue_count", regex=r"\d+", max_tokens=2) + "\n"
        "Comments: " + gen("comments", max_tokens=100, stop="\n\n") + "\n"
        "Approved: " + select(["yes", "no"], name="approved")
    )

print(f"Quality: {lm['quality']}")
print(f"Issues:  {lm['issue_count']}")
print(f"Comment: {lm['comments']}")
print(f"Approved:{lm['approved']}")
```

### Local Models with LlamaCpp
```python
from guidance import models, gen, select

# Load a local GGUF model
lm = models.LlamaCpp("./models/mistral-7b-instruct.gguf", n_gpu_layers=-1)

result = (
    lm
    + "Classify the bug severity:\n"
    + "Bug: 'App crashes on null input'\n"
    + "Severity: " + select(["low", "medium", "high", "critical"], name="sev")
)
print(result["sev"])
```

### Full Example — Structured Code Review Report
```python
"""
Guidance-powered structured code review report generator.
Run: pip install guidance openai
"""
import os
import guidance
from guidance import models, gen, select, system, user, assistant

os.environ["OPENAI_API_KEY"] = os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN")
os.environ["OPENAI_BASE_URL"] = "https://models.inference.ai.azure.com"

lm = models.OpenAI("gpt-4o-mini")

CODE_TO_REVIEW = """
def process_user_data(user_id, db):
    query = f"SELECT * FROM users WHERE id = {user_id}"
    result = db.execute(query)
    password = result['password']
    return {'user': result, 'pass': password}
"""

def generate_code_review(code: str) -> dict:
    with system():
        lm2 = lm + "You are a senior security-focused code reviewer."

    with user():
        lm2 = lm2 + f"Review this code for security, quality, and best practices:\n```python\n{code}\n```"

    with assistant():
        lm2 = lm2 + (
            "## Code Review Report\n\n"
            "**Overall Rating:** "
            + select(["A", "B", "C", "D", "F"], name="rating") + "\n"
            "**Security Risk:** "
            + select(["none", "low", "medium", "high", "critical"], name="security") + "\n"
            "**Issues Count:** "
            + gen("issue_count", regex=r"\d+", max_tokens=2) + "\n\n"
            "**Primary Issue:** " + gen("primary_issue", max_tokens=80, stop="\n") + "\n"
            "**Recommendation:** "
            + select(["approve", "request_changes", "reject"], name="action") + "\n\n"
            "**Detailed Feedback:**\n"
            + gen("feedback", max_tokens=200, stop="##")
        )

    return {
        "rating": lm2["rating"],
        "security_risk": lm2["security"],
        "issues": lm2["issue_count"],
        "primary_issue": lm2["primary_issue"],
        "action": lm2["action"],
        "feedback": lm2["feedback"].strip(),
    }

if __name__ == "__main__":
    review = generate_code_review(CODE_TO_REVIEW)
    print(f"Rating:       {review['rating']}")
    print(f"Security:     {review['security_risk'].upper()}")
    print(f"Issues:       {review['issues']}")
    print(f"Action:       {review['action'].upper()}")
    print(f"Primary Issue:{review['primary_issue']}")
    print(f"\nFeedback:\n{review['feedback']}")
```

### Interview Q&A

**Q1: What is the core innovation of Guidance vs other frameworks?**
A: Guidance interleaves generation *within* a prompt template. You write `lm + "text" + gen("var")` and execution happens left-to-right, with each `gen()` filling exactly that slot. This eliminates post-processing and guarantees output structure.

**Q2: How does `select()` constrain the LLM output?**
A: It uses token-level logit masking — only tokens that could start valid choices are allowed at each position. This is enforced at the model level, making it impossible for the LLM to output an invalid choice.

**Q3: When is `regex=` constraint useful?**
A: For enforcing formats like dates (`\d{4}-\d{2}-\d{2}`), version numbers, phone numbers, or any structured pattern. The regex is compiled to a finite automaton and applied as a token mask during generation.

**Q4: Can Guidance be used with open-source local models?**
A: Yes, via `models.LlamaCpp()` with any GGUF model. Token-level constraints work natively with llama.cpp. This is Guidance's strongest use case — free, offline, fully constrained generation.

**Q5: What is the difference between `gen()` and `select()`?**
A: `gen()` produces free-form text (optionally constrained by `regex`, `max_tokens`, `stop`). `select()` forces the model to pick from a finite list of strings.

**Q6: How does Guidance handle chat models (system/user/assistant)?**
A: Use context managers: `with system(): lm += "..."`, `with user(): lm += "..."`, `with assistant(): lm += gen(...)`. These map to the appropriate chat message roles.

**Q7: How does Guidance compare to JSON mode in OpenAI?**
A: JSON mode forces valid JSON but doesn't constrain *values* within the JSON. Guidance can constrain specific field values to enums, regexes, or numeric ranges — more granular control.

**Q8: What are the performance implications of constrained generation?**
A: Token masking adds minimal overhead (~5ms per token). The real benefit is eliminating retry loops — one pass instead of multiple retries for format compliance.

---

## 7. LangSmith (Observability)

### What It Is
LangSmith is LangChain's **LLM observability, tracing, evaluation, and dataset management** platform. It works with any Python code — not just LangChain.

```bash
pip install langsmith
```

### Setup
```python
import os
os.environ["LANGCHAIN_API_KEY"] = "ls__your_api_key"   # langsmith.com
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = "my-ai-app"
```

### `@traceable` Decorator
```python
from langsmith import traceable
import openai

client = openai.OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)

@traceable(name="llm_call", run_type="llm")
def call_llm(prompt: str, model: str = "gpt-4o-mini") -> str:
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content

@traceable(name="retriever", run_type="retriever")
def retrieve_docs(query: str) -> list[str]:
    # Mock retrieval
    return [f"Relevant doc about: {query}", "Another related document."]

@traceable(name="rag_pipeline", run_type="chain")
def rag_answer(question: str) -> str:
    docs = retrieve_docs(question)
    context = "\n".join(docs)
    prompt = f"Answer based on context:\n{context}\n\nQuestion: {question}"
    return call_llm(prompt)

answer = rag_answer("What is gradient descent?")
print(answer)
# All calls appear as nested traces in LangSmith UI
```

### RunTree for Manual Tracing
```python
from langsmith.run_trees import RunTree

root = RunTree(
    name="batch_processing",
    run_type="chain",
    inputs={"batch_size": 10},
)

child = root.create_child(
    name="process_item",
    run_type="tool",
    inputs={"item_id": "item_001"},
)
child.end(outputs={"result": "processed"})
child.post()

root.end(outputs={"processed": 10, "failed": 0})
root.post()
```

### Datasets and Evaluators
```python
from langsmith import Client

ls_client = Client()

# Create a dataset
dataset = ls_client.create_dataset("qa-benchmark", description="QA test cases")
ls_client.create_examples(
    inputs=[
        {"question": "What is 2+2?"},
        {"question": "Capital of France?"},
    ],
    outputs=[
        {"answer": "4"},
        {"answer": "Paris"},
    ],
    dataset_id=dataset.id,
)

# Define evaluator
def exact_match(run, example) -> dict:
    prediction = run.outputs.get("output", "").strip().lower()
    reference = example.outputs.get("answer", "").strip().lower()
    return {"key": "exact_match", "score": int(prediction == reference)}

# Run evaluation
from langsmith.evaluation import evaluate

results = evaluate(
    lambda inputs: {"output": call_llm(inputs["question"])},
    data=dataset.name,
    evaluators=[exact_match],
    experiment_prefix="baseline",
)
print(results.to_pandas()[["input", "output", "feedback.exact_match"]])
```

### Full Tracing Example — RAG Pipeline
```python
"""
Full LangSmith-traced RAG pipeline.
Run: pip install langsmith openai
Set: LANGCHAIN_API_KEY, LANGCHAIN_TRACING_V2=true
"""
import os
from langsmith import traceable, Client
from langsmith.wrappers import wrap_openai
import openai

os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
os.environ.setdefault("LANGCHAIN_PROJECT", "rag-demo")

# Wrapping auto-traces all OpenAI calls
raw_client = openai.OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ.get("GITHUB_TOKEN", "YOUR_TOKEN"),
)
client = wrap_openai(raw_client)   # auto-traces every completion

KNOWLEDGE_BASE = {
    "python": "Python is a high-level, interpreted programming language known for readability.",
    "langsmith": "LangSmith is an observability platform for LLM applications by LangChain.",
    "rag": "RAG (Retrieval-Augmented Generation) combines retrieval systems with LLMs.",
}

@traceable(name="vector_search", run_type="retriever")
def retrieve(query: str, top_k: int = 2) -> list[dict]:
    query_lower = query.lower()
    results = []
    for key, text in KNOWLEDGE_BASE.items():
        if any(word in query_lower for word in key.split()):
            results.append({"id": key, "content": text, "score": 0.95})
    return results[:top_k] or [{"id": "fallback", "content": "No relevant docs found.", "score": 0.1}]

@traceable(name="augment_prompt", run_type="chain")
def build_prompt(question: str, docs: list[dict]) -> str:
    context = "\n".join(f"[{d['id']}]: {d['content']}" for d in docs)
    return f"Context:\n{context}\n\nQuestion: {question}\nAnswer concisely:"

@traceable(name="generate_answer", run_type="llm")
def generate(prompt: str) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=150,
    )
    return resp.choices[0].message.content

@traceable(name="full_rag_pipeline", run_type="chain")
def rag(question: str) -> str:
    docs = retrieve(question)
    prompt = build_prompt(question, docs)
    return generate(prompt)

if __name__ == "__main__":
    questions = [
        "What is RAG and how does it work?",
        "Tell me about LangSmith's purpose.",
        "Why use Python for AI development?",
    ]
    for q in questions:
        print(f"Q: {q}")
        print(f"A: {rag(q)}\n")
    print("Check traces at: https://smith.langchain.com")
```

---

## 8. Flowise & n8n (No-Code/Low-Code)

### Flowise — Visual LLM Flow Builder

Flowise lets you build LLM pipelines visually and exposes them as REST APIs.

```bash
# Install & run
npm install -g flowise
npx flowise start --PORT=3000
# Open http://localhost:3000
```

#### REST API Integration from Python
```python
import requests
import os

FLOWISE_URL = "http://localhost:3000"
CHATFLOW_ID = "your-chatflow-uuid-here"

def ask_flowise(question: str, session_id: str = "default") -> str:
    """Send a question to a Flowise chatflow via REST API."""
    response = requests.post(
        f"{FLOWISE_URL}/api/v1/prediction/{CHATFLOW_ID}",
        json={
            "question": question,
            "overrideConfig": {
                "sessionId": session_id,
            },
        },
        headers={"Authorization": f"Bearer {os.environ.get('FLOWISE_API_KEY', '')}"},
        timeout=60,
    )
    response.raise_for_status()
    return response.json()["text"]

# Usage
answer = ask_flowise("Explain what RAG is in simple terms.")
print(answer)
```

#### Streaming Chat Endpoint
```python
import requests
import json

def stream_flowise(question: str, chatflow_id: str) -> None:
    """Stream a response from a Flowise chatflow."""
    with requests.post(
        f"http://localhost:3000/api/v1/prediction/{chatflow_id}",
        json={"question": question, "streaming": True},
        stream=True,
        timeout=120,
    ) as response:
        for line in response.iter_lines():
            if line:
                decoded = line.decode("utf-8")
                if decoded.startswith("data:"):
                    data = decoded[5:].strip()
                    if data and data != "[DONE]":
                        try:
                            chunk = json.loads(data)
                            print(chunk.get("token", ""), end="", flush=True)
                        except json.JSONDecodeError:
                            pass
    print()

stream_flowise("Write a Python function to sort a list of dicts by key.", "your-chatflow-id")
```

#### Embedding in Web Apps
```html
<!-- Add to any HTML page — no API key exposed in frontend -->
<script type="module">
  import Chatbot from "https://cdn.jsdelivr.net/npm/flowise-embed/dist/web.js"
  Chatbot.init({
    chatflowid: "your-chatflow-uuid",
    apiHost: "http://localhost:3000",
    theme: {
      button: { backgroundColor: "#007bff" },
      chatWindow: { title: "AI Assistant" }
    }
  })
</script>
```

---

### n8n — Workflow Automation with AI Nodes

n8n is a visual workflow automation tool with built-in AI Agent, OpenAI, and LangChain nodes.

```bash
# Docker (recommended)
docker run -it --rm -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n
# Open http://localhost:5678
```

#### Python Script to Trigger an n8n Workflow via Webhook
```python
import requests
import json
from typing import Any

N8N_WEBHOOK_URL = "http://localhost:5678/webhook/your-webhook-id"

def trigger_n8n_workflow(payload: dict[str, Any]) -> dict:
    """Trigger an n8n workflow via webhook and return the result."""
    response = requests.post(
        N8N_WEBHOOK_URL,
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()

# Example: trigger a workflow that processes a support ticket
result = trigger_n8n_workflow({
    "ticket_id": "TKT-4521",
    "subject": "Login page broken in production",
    "body": "Users cannot login since the 2pm deployment. Error: 500.",
    "priority": "high",
    "source": "python_app",
})
print(json.dumps(result, indent=2))
```

#### n8n AI Agent + HTTP Request Pattern (Workflow JSON excerpt)
```json
{
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": { "httpMethod": "POST", "path": "process-ticket" }
    },
    {
      "name": "AI Agent",
      "type": "@n8n/n8n-nodes-langchain.agent",
      "parameters": {
        "text": "={{ $json.body }}",
        "systemMessage": "Classify and summarize support tickets. Return JSON with: category, urgency, summary, next_action."
      }
    },
    {
      "name": "Send to Slack",
      "type": "n8n-nodes-base.slack",
      "parameters": {
        "channel": "#engineering-alerts",
        "text": "={{ $json.output }}"
      }
    }
  ]
}
```

#### Using n8n REST API from Python
```python
import requests

N8N_URL = "http://localhost:5678"
N8N_API_KEY = "your-n8n-api-key"   # Settings → API → Create API Key

headers = {"X-N8N-API-KEY": N8N_API_KEY}

def list_workflows() -> list:
    r = requests.get(f"{N8N_URL}/api/v1/workflows", headers=headers)
    return r.json()["data"]

def execute_workflow(workflow_id: str, input_data: dict) -> dict:
    r = requests.post(
        f"{N8N_URL}/api/v1/workflows/{workflow_id}/execute",
        headers=headers,
        json={"workflowData": {"nodes": [], "connections": {}}, "inputData": input_data},
    )
    return r.json()

workflows = list_workflows()
for wf in workflows:
    print(f"  [{wf['id']}] {wf['name']} — {'active' if wf['active'] else 'inactive'}")
```

---

## 9. Quick Comparison Tables

### All Libraries — Overview

| Library | Category | Complexity | Free Tier | Best For |
|---|---|---|---|---|
| **Pydantic AI** | Agent Framework | Medium | Via any free LLM | Type-safe production agents |
| **Smolagents** | Agent Framework | Low-Medium | HF free tier | Code-executing agents, data tasks |
| **Instructor** | Structured Output | Low | Via any free LLM | Extracting structured data from text |
| **Agno** | Agent Framework | Medium-High | Via any free LLM | Multi-modal agents with KB + storage |
| **Marvin** | AI Toolkit | Very Low | Via any free LLM | Pythonic AI helpers in existing apps |
| **Guidance** | Constrained Gen | Medium | Local + free LLMs | Guaranteed output format, local models |
| **LangSmith** | Observability | Low | 5k traces/month | Tracing, eval, debugging LLM apps |
| **Flowise** | No-Code Builder | Very Low | Self-hosted free | Visual flow building, non-developers |
| **n8n** | Workflow Automation | Low | Self-hosted free | LLM in business process automation |

---

### Structured Output Comparison

| Feature | Instructor | Pydantic AI | Marvin | DSPy |
|---|---|---|---|---|
| **Mechanism** | Function calling | Result type schema | Function calling | Signature + optimizer |
| **Retry on failure** | ✅ Auto (max_retries) | ✅ ModelRetry | ✅ Implicit | ✅ Assert |
| **Streaming partial** | ✅ Partial[Model] | ✅ stream_structured | ❌ | ❌ |
| **Validation layer** | Pydantic validators | Pydantic validators | Pydantic validators | DSPy assertions |
| **Learning/few-shot** | ❌ Manual | ❌ Manual | ❌ Manual | ✅ Core feature |
| **Overhead** | Minimal (patch client) | Full framework | Minimal | Full framework |
| **Multi-provider** | ✅ 10+ providers | ✅ 8+ providers | ✅ Via settings | ✅ Via LiteLLM |
| **Best for** | Drop-in extraction | Production agents | Quick helpers | Optimized pipelines |

---

### Agent Framework Comparison

| Feature | Pydantic AI | Smolagents | Agno | LangChain | AutoGen |
|---|---|---|---|---|---|
| **Action type** | Tool calls | Code execution | Tool calls | Tool calls | Code + calls |
| **Type safety** | ✅ Native Pydantic | ❌ | Partial | ❌ | ❌ |
| **Built-in KB/RAG** | ❌ | ❌ | ✅ | Via loaders | ❌ |
| **Persistent memory** | ❌ | ❌ | ✅ SqliteStorage | Via memory | Partial |
| **Multi-agent** | Compose manually | ManagedAgent | Team | LCEL chains | ✅ Core feature |
| **Local LLMs** | ✅ Ollama | ✅ TransformersModel | ✅ Ollama | ✅ | ✅ |
| **Testing support** | ✅ TestModel | Mock tools | Mock tools | ❌ Built-in | ❌ |
| **Complexity** | Low-Medium | Low | Medium | High | High |
| **Best for** | Production, type-safe | Data + code tasks | Full-stack agents | Ecosystem breadth | Autonomous systems |

---

### When to Use Each — SDLC Automation

| SDLC Stage | Recommended Library | Use Case |
|---|---|---|
| **Requirements** | Marvin | Extract user stories from emails; classify feature requests |
| **Design** | Instructor | Generate structured architecture docs from requirements |
| **Coding** | Smolagents CodeAgent | Write utility scripts, analyze codebases, refactor tasks |
| **Code Review** | Guidance | Structured review reports with guaranteed rating format |
| **Testing** | Pydantic AI | Generate typed test cases; validate test output schemas |
| **CI/CD** | n8n | Automate PR labeling, deploy notifications, runbook execution |
| **Monitoring** | LangSmith | Trace LLM calls in prod; alert on quality regressions |
| **Documentation** | Agno | Knowledge base over codebase; answer "how does X work?" |
| **Incident Response** | Flowise | Visual runbook chatbot for on-call engineers |
| **Retrospectives** | Marvin | Classify action items; extract commitments from meeting notes |

---

*Guide generated for EngX AI Coach — covering Pydantic AI, Smolagents, Instructor, Agno, Marvin, Guidance, LangSmith, Flowise, and n8n with full runnable examples and interview preparation.*
