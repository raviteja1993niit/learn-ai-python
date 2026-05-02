# CrewAI — Comprehensive Guide for Software Developers

> **Version:** CrewAI ≥ 0.70 | **Python:** 3.10+
> Every code block is self-contained and runnable.

---

## Table of Contents

1. [What is CrewAI?](#1-what-is-crewai)
2. [Installation & Setup](#2-installation--setup)
3. [Core Components](#3-core-components)
4. [Process Types](#4-process-types)
5. [Tools](#5-tools)
6. [Memory System](#6-memory-system)
7. [Structured Output](#7-structured-output)
8. [Flows (CrewAI Flows)](#8-flows-crewai-flows)
9. [CrewAI CLI](#9-crewai-cli)
10. [Testing & Evaluation](#10-testing--evaluation)
11. [Real-World Use Cases](#11-real-world-use-cases)
12. [Performance & Cost Optimization](#12-performance--cost-optimization)
13. [Deployment](#13-deployment)
14. [Interview Q&A](#14-interview-qa)
15. [Complete End-to-End Example](#15-complete-end-to-end-example)

---

## 1. What is CrewAI?

CrewAI is a **role-based multi-agent orchestration framework** that lets you compose autonomous AI agents into collaborative crews. Each agent has a specialised role, goal, and backstory; agents share context through tasks and can delegate work to one another.

### Core Architecture

```
Crew
├── Agents      ← specialised AI workers (role + goal + backstory + tools)
├── Tasks       ← units of work assigned to an agent, with expected output
├── Tools       ← functions agents can call (search, read files, code, etc.)
└── Process     ← execution strategy (sequential / hierarchical / parallel)
```

### Process Modes

| Mode | Description | Use When |
|------|-------------|----------|
| **Sequential** | Tasks run one after another; output feeds into next | Ordered pipelines |
| **Hierarchical** | A manager LLM breaks down work and delegates to agents | Open-ended, complex goals |
| **Parallel (async)** | Independent tasks run concurrently | Independent sub-tasks |

### When to Use CrewAI vs LangGraph vs AutoGen

| Criterion | CrewAI | LangGraph | AutoGen |
|-----------|--------|-----------|---------|
| Primary abstraction | Role-based crews | Stateful DAG graphs | Conversational agents |
| Best for | Structured pipelines, content/research | Fine-grained state machines, loops | Back-and-forth LLM debates |
| Learning curve | Low — declarative YAML/Python | Medium — graph nodes/edges | Medium — agent conversations |
| Custom control flow | Flows + routers | Full graph control | Nested chats |
| Built-in tools | Rich tool ecosystem | LangChain tools | Plugin system |
| Verdict | Rapid prototyping, clear role separation | Complex stateful workflows | Multi-agent debates, research |

---

## 2. Installation & Setup

```bash
pip install crewai crewai-tools
# Optional extras
pip install crewai[tools]       # all built-in tools
pip install 'crewai[tools,agentops]'  # + observability
```

### LLM Configuration

#### Option A — OpenAI

```python
import os
os.environ["OPENAI_API_KEY"] = "sk-..."

from crewai import Agent
agent = Agent(role="Researcher", goal="Find facts", backstory="Expert researcher",
              llm="gpt-4o-mini")  # string shorthand
```

#### Option B — Local Ollama

```python
from crewai import Agent
from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3.2", base_url="http://localhost:11434")

agent = Agent(
    role="Local Researcher",
    goal="Answer questions using local model",
    backstory="Privacy-focused analyst",
    llm=llm,
)
```

#### Option C — GitHub Copilot Free Auth (recommended for dev/learning)

```python
"""
GitHub Copilot exposes an OpenAI-compatible endpoint.
Steps:
  1. gh auth login          (authenticate with GitHub CLI)
  2. gh auth token          (copy the token)
  3. Use endpoint: https://models.inference.ai.azure.com
"""
import os
from langchain_openai import ChatOpenAI

github_token = os.environ.get("GITHUB_TOKEN")  # set via: export GITHUB_TOKEN=$(gh auth token)

copilot_llm = ChatOpenAI(
    api_key=github_token,
    base_url="https://models.inference.ai.azure.com",
    model="gpt-4o-mini",   # or "gpt-4o", "o1-mini"
)

from crewai import Agent
agent = Agent(
    role="Researcher",
    goal="Research AI trends",
    backstory="Senior technology analyst",
    llm=copilot_llm,
    verbose=True,
)
```

---

## 3. Core Components

### 3.1 Agents

```python
from crewai import Agent
from langchain_openai import ChatOpenAI

cheap_llm  = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)
smart_llm  = ChatOpenAI(model="gpt-4o",      temperature=0.1)

researcher = Agent(
    # Identity
    role="Senior Research Analyst",
    goal="Uncover accurate, up-to-date information on {topic}",
    backstory=(
        "You are a meticulous analyst with 10 years of experience. "
        "You cite sources and avoid speculation."
    ),
    # Model
    llm=cheap_llm,
    # Behaviour
    verbose=True,          # print agent thoughts
    memory=True,           # enable short-term memory
    allow_delegation=True, # can hand off sub-tasks to other agents
    max_iter=5,            # max reasoning iterations before forced answer
    max_rpm=10,            # max requests per minute (rate limiting)
    # Tools assigned at agent level
    tools=[],              # populated in Section 5
)

writer = Agent(
    role="Content Writer",
    goal="Transform research into clear, engaging articles",
    backstory="Award-winning tech journalist with an eye for storytelling.",
    llm=smart_llm,
    verbose=True,
    allow_delegation=False,
)
```

### 3.2 Tasks

```python
from crewai import Task
from pydantic import BaseModel

class ResearchOutput(BaseModel):
    topic: str
    key_findings: list[str]
    sources: list[str]
    confidence_score: float

research_task = Task(
    description=(
        "Research the latest developments in {topic}. "
        "Find at least 5 key findings and cite your sources."
    ),
    expected_output="A structured report with findings and sources.",
    agent=researcher,
    output_pydantic=ResearchOutput,   # enforce typed output
)

write_task = Task(
    description=(
        "Using the research report, write a 500-word article for a developer audience. "
        "Make it engaging and technically accurate."
    ),
    expected_output="A polished 500-word article in markdown format.",
    agent=writer,
    context=[research_task],          # receives research_task output as context
    async_execution=False,            # set True to run concurrently with other async tasks
)

# Task with no specific agent — crew manager will assign in Hierarchical mode
unassigned_task = Task(
    description="Review the article for factual accuracy.",
    expected_output="A list of corrections or 'Approved' if accurate.",
)
```

### 3.3 Crew

```python
from crewai import Crew, Process

crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, write_task],
    process=Process.sequential,   # or Process.hierarchical
    verbose=True,
    memory=True,
    # manager_llm required for hierarchical (see Section 4)
)

# --- Execution modes ---

# 1. Standard kickoff with variable interpolation
result = crew.kickoff(inputs={"topic": "AI agents in 2025"})

# 2. Run the same crew over multiple inputs (batch)
results = crew.kickoff_for_each(inputs=[
    {"topic": "AI agents"},
    {"topic": "Vector databases"},
])

# 3. Async kickoff
import asyncio

async def run():
    return await crew.kickoff_async(inputs={"topic": "LLM fine-tuning"})

result = asyncio.run(run())

# --- Accessing output ---
print(result.raw)                  # plain string output
print(result.pydantic)             # typed Pydantic object (if output_pydantic set)
print(result.tasks_output)         # list of TaskOutput objects
print(result.token_usage)          # {"prompt_tokens": ..., "completion_tokens": ...}
for t in result.tasks_output:
    print(t.description, "->", t.raw[:80])
```

---

## 4. Process Types

### 4.1 Sequential Process

Tasks run in the order listed. Output of task N becomes available as context to task N+1 via `context=`.

```python
from crewai import Agent, Task, Crew, Process

analyst = Agent(role="Data Analyst",     goal="Analyse data",      backstory="Stats expert", llm="gpt-4o-mini")
writer  = Agent(role="Report Writer",    goal="Write clear reports",backstory="Writer",       llm="gpt-4o-mini")
editor  = Agent(role="Senior Editor",    goal="Polish prose",       backstory="Editor",       llm="gpt-4o-mini")

t1 = Task(description="Analyse Q1 sales data trends.", expected_output="Bullet-point analysis.", agent=analyst)
t2 = Task(description="Turn the analysis into a report.", expected_output="2-page report.", agent=writer, context=[t1])
t3 = Task(description="Edit the report for clarity.", expected_output="Polished report.", agent=editor, context=[t2])

sequential_crew = Crew(
    agents=[analyst, writer, editor],
    tasks=[t1, t2, t3],
    process=Process.sequential,
    verbose=True,
)

result = sequential_crew.kickoff()
print(result.raw)
```

### 4.2 Hierarchical Process

A **manager LLM** receives the goal and autonomously decides which agent to use and in what order. No need to pre-assign agents to tasks.

```python
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

manager_llm = ChatOpenAI(model="gpt-4o", temperature=0)

dev   = Agent(role="Developer",        goal="Write code",          backstory="Senior Python dev", llm="gpt-4o-mini")
qa    = Agent(role="QA Engineer",      goal="Test code",           backstory="QA specialist",     llm="gpt-4o-mini")
devop = Agent(role="DevOps Engineer",  goal="Deploy applications",  backstory="Cloud expert",      llm="gpt-4o-mini")

build_task  = Task(description="Build a REST API endpoint for user login.",  expected_output="Working FastAPI code.")
test_task   = Task(description="Write pytest tests for the login endpoint.", expected_output="pytest test file.")
deploy_task = Task(description="Write a Dockerfile for the API.",            expected_output="Dockerfile.")

hierarchical_crew = Crew(
    agents=[dev, qa, devop],
    tasks=[build_task, test_task, deploy_task],
    process=Process.hierarchical,
    manager_llm=manager_llm,   # required for hierarchical
    verbose=True,
)

result = hierarchical_crew.kickoff()
print(result.raw)
```

### 4.3 Parallel (Async) Process

Mark independent tasks with `async_execution=True`; they run concurrently. A final sync task collects their outputs via `context=`.

```python
from crewai import Agent, Task, Crew, Process

agent_a = Agent(role="Frontend Analyst", goal="Analyse UI",      backstory="UI expert", llm="gpt-4o-mini")
agent_b = Agent(role="Backend Analyst",  goal="Analyse API",     backstory="API expert",llm="gpt-4o-mini")
agent_c = Agent(role="Tech Lead",        goal="Summarise findings", backstory="Lead",   llm="gpt-4o-mini")

# These two run in parallel
ui_task  = Task(description="Audit the React frontend for performance issues.",
                expected_output="List of UI issues.", agent=agent_a, async_execution=True)
api_task = Task(description="Audit the FastAPI backend for bottlenecks.",
                expected_output="List of API issues.", agent=agent_b, async_execution=True)

# This runs after both complete
summary_task = Task(description="Summarise all audit findings into an action plan.",
                    expected_output="Prioritised action plan.", agent=agent_c,
                    context=[ui_task, api_task])  # depends on both async tasks

parallel_crew = Crew(
    agents=[agent_a, agent_b, agent_c],
    tasks=[ui_task, api_task, summary_task],
    process=Process.sequential,   # sequential process still supports async tasks
    verbose=True,
)

result = parallel_crew.kickoff()
print(result.raw)
```

---

## 5. Tools

### 5.1 Built-in Tools

```python
from crewai_tools import (
    SerperDevTool,         # Google search via Serper API
    ScrapeWebsiteTool,     # Scrape a URL
    FileReadTool,          # Read local files
    DirectoryReadTool,     # List directory contents
    CodeInterpreterTool,   # Execute Python code in sandbox
)
import os

os.environ["SERPER_API_KEY"] = "your-serper-key"

search_tool    = SerperDevTool()
scrape_tool    = ScrapeWebsiteTool()
file_tool      = FileReadTool()
dir_tool       = DirectoryReadTool(directory="./docs")
code_tool      = CodeInterpreterTool()

from crewai import Agent
agent = Agent(
    role="Researcher",
    goal="Gather and analyse information",
    backstory="Data-driven analyst",
    llm="gpt-4o-mini",
    tools=[search_tool, scrape_tool, file_tool],
)
```

### 5.2 Custom Tool — @tool Decorator

```python
from crewai.tools import tool

@tool("GitHub Repository Stats")
def get_repo_stats(repo: str) -> str:
    """
    Fetch star count and language for a GitHub repository.
    Input: 'owner/repo' string e.g. 'crewAIInc/crewAI'
    """
    import requests
    resp = requests.get(f"https://api.github.com/repos/{repo}", timeout=10)
    if resp.status_code != 200:
        return f"Error: {resp.status_code}"
    data = resp.json()
    return f"{repo}: {data['stargazers_count']} stars, language: {data['language']}"

# Attach to an agent
from crewai import Agent
dev_agent = Agent(
    role="Open Source Scout",
    goal="Evaluate GitHub repositories",
    backstory="OSS enthusiast",
    llm="gpt-4o-mini",
    tools=[get_repo_stats],
)
```

### 5.3 Custom Tool — BaseTool Class

```python
from crewai.tools import BaseTool
from pydantic import Field
import json, pathlib

class JSONReaderTool(BaseTool):
    name: str = "JSON File Reader"
    description: str = "Reads and parses a JSON file. Input: absolute file path."
    encoding: str = Field(default="utf-8")

    def _run(self, file_path: str) -> str:
        try:
            content = pathlib.Path(file_path).read_text(encoding=self.encoding)
            data = json.loads(content)
            return json.dumps(data, indent=2)
        except FileNotFoundError:
            return f"File not found: {file_path}"
        except json.JSONDecodeError as e:
            return f"Invalid JSON: {e}"

json_tool = JSONReaderTool(encoding="utf-8")
```

### 5.4 Tool Caching

```python
from crewai.tools import tool

@tool("Expensive API Call")
def expensive_lookup(query: str) -> str:
    """Expensive external API — results are cached."""
    import time
    time.sleep(2)   # simulate latency
    return f"Result for: {query}"

# Enable caching at the tool level (default: True)
# Each unique input is cached; subsequent calls return cached result
expensive_lookup.cache_function = lambda args, result: True  # always cache
# Or conditionally:
expensive_lookup.cache_function = lambda args, result: "error" not in result.lower()
```

### 5.5 Full Example — Research Crew with Web Search + File Tools

```python
import os
from crewai import Agent, Task, Crew, Process
from crewai_tools import SerperDevTool, FileReadTool
from crewai.tools import tool

os.environ["OPENAI_API_KEY"]  = os.getenv("OPENAI_API_KEY", "")
os.environ["SERPER_API_KEY"]  = os.getenv("SERPER_API_KEY", "")

search_tool = SerperDevTool()
file_tool   = FileReadTool()

@tool("Summarise Text")
def summarise(text: str) -> str:
    """Return first 500 characters of text as a quick summary."""
    return text[:500] + ("..." if len(text) > 500 else "")

researcher = Agent(
    role="Web Researcher",
    goal="Find the latest facts about {topic}",
    backstory="Diligent analyst who verifies every claim.",
    llm="gpt-4o-mini",
    tools=[search_tool, summarise],
    verbose=True,
)

archivist = Agent(
    role="Archivist",
    goal="Read and cross-reference local documentation",
    backstory="Detail-oriented librarian.",
    llm="gpt-4o-mini",
    tools=[file_tool],
    verbose=True,
)

research_task = Task(
    description="Search the web for key facts about {topic}. Summarise top 3 results.",
    expected_output="3-point summary with source URLs.",
    agent=researcher,
)

synthesis_task = Task(
    description="Combine the web research into a concise briefing document.",
    expected_output="One-page briefing in markdown.",
    agent=archivist,
    context=[research_task],
)

crew = Crew(
    agents=[researcher, archivist],
    tasks=[research_task, synthesis_task],
    process=Process.sequential,
    verbose=True,
)

if __name__ == "__main__":
    result = crew.kickoff(inputs={"topic": "CrewAI multi-agent framework"})
    print(result.raw)
```

---

## 6. Memory System

CrewAI offers four memory layers that agents use to retain and recall information.

| Memory Type | Storage | Scope | Use Case |
|-------------|---------|-------|----------|
| Short-term | In-memory RAG (ChromaDB) | Current session | Recent conversation context |
| Long-term | SQLite on disk | Cross-session | Remember past interactions |
| Entity | ChromaDB | Current session | Track people, companies, systems |
| Contextual | Combination of all three | Adaptive | General-purpose recall |

### 6.1 Enabling Default Memory

```python
from crewai import Crew, Process

crew = Crew(
    agents=[...],
    tasks=[...],
    process=Process.sequential,
    memory=True,           # enables short-term + long-term + entity memory
    verbose=True,
)
```

### 6.2 Custom Memory Configuration

```python
from crewai import Crew
from crewai.memory import (
    ShortTermMemory,
    LongTermMemory,
    EntityMemory,
)
from crewai.memory.storage.rag_storage import RAGStorage
from crewai.memory.storage.ltm_sqlite_storage import LTMSQLiteStorage

crew = Crew(
    agents=[...],
    tasks=[...],
    memory=True,
    short_term_memory=ShortTermMemory(
        storage=RAGStorage(
            embedder_config={
                "provider": "openai",
                "config": {"model": "text-embedding-3-small"},
            }
        )
    ),
    long_term_memory=LongTermMemory(
        storage=LTMSQLiteStorage(db_path="./my_crew_memory.db")
    ),
    entity_memory=EntityMemory(
        storage=RAGStorage(
            type="short_term",
            embedder_config={
                "provider": "openai",
                "config": {"model": "text-embedding-3-small"},
            },
        )
    ),
    verbose=True,
)
```

### 6.3 Agent-Level Memory

```python
from crewai import Agent

agent = Agent(
    role="Assistant",
    goal="Help users",
    backstory="Helpful AI",
    llm="gpt-4o-mini",
    memory=True,   # agent maintains its own conversation memory
)
```

---

## 7. Structured Output

### 7.1 Pydantic Output

```python
from pydantic import BaseModel, Field
from typing import Optional
from crewai import Agent, Task, Crew, Process

class CodeReviewReport(BaseModel):
    file_reviewed: str
    issues_found: list[str] = Field(description="List of code issues")
    severity: str            = Field(description="low | medium | high | critical")
    recommendations: list[str]
    approved: bool
    confidence: Optional[float] = None

reviewer = Agent(
    role="Code Reviewer",
    goal="Review Python code for quality and security",
    backstory="Expert Python engineer with security background.",
    llm="gpt-4o-mini",
    verbose=True,
)

review_task = Task(
    description="Review this Python function for issues:\n\n```python\ndef login(user, pwd):\n    query = f'SELECT * FROM users WHERE user={user} AND pwd={pwd}'\n    return db.execute(query)\n```",
    expected_output="A structured code review report.",
    agent=reviewer,
    output_pydantic=CodeReviewReport,   # enforce typed output
)

crew = Crew(agents=[reviewer], tasks=[review_task], process=Process.sequential)
result = crew.kickoff()

report: CodeReviewReport = result.pydantic
print(f"Approved: {report.approved}")
print(f"Severity: {report.severity}")
for issue in report.issues_found:
    print(f"  - {issue}")
```

### 7.2 JSON Output

```python
from crewai import Task

json_task = Task(
    description="Extract key metadata from the document.",
    expected_output="JSON with keys: title, author, date, summary.",
    agent=reviewer,
    output_json={
        "type": "object",
        "properties": {
            "title":   {"type": "string"},
            "author":  {"type": "string"},
            "date":    {"type": "string"},
            "summary": {"type": "string"},
        },
        "required": ["title", "author", "date", "summary"],
    },
)

result = crew.kickoff()
print(result.json_dict)   # parsed dict
```

### 7.3 Accessing tasks_output

```python
result = crew.kickoff()

for task_output in result.tasks_output:
    print("Task:", task_output.description[:60])
    print("Raw:", task_output.raw[:200])
    if task_output.pydantic:
        print("Typed:", task_output.pydantic)
    print("---")

print("Total tokens used:", result.token_usage)
```

---

## 8. Flows (CrewAI Flows)

Flows provide **imperative control** over how crews chain together. Use `@start`, `@listen`, and `@router` decorators to wire events between crews.

### 8.1 Basic Flow Decorators

```python
from crewai.flow.flow import Flow, listen, router, start
from pydantic import BaseModel

class ResearchState(BaseModel):
    topic: str = ""
    research: str = ""
    article: str = ""
    review_passed: bool = False

class ContentFlow(Flow[ResearchState]):

    @start()
    def set_topic(self):
        self.state.topic = "AI agents in 2025"
        print(f"Starting flow for topic: {self.state.topic}")

    @listen(set_topic)
    def run_research(self):
        from crewai import Agent, Task, Crew, Process
        researcher = Agent(role="Researcher", goal="Research {topic}",
                           backstory="Expert researcher", llm="gpt-4o-mini")
        task = Task(description=f"Research: {self.state.topic}",
                    expected_output="Key findings.", agent=researcher)
        crew = Crew(agents=[researcher], tasks=[task], process=Process.sequential)
        result = crew.kickoff()
        self.state.research = result.raw

    @listen(run_research)
    def write_article(self):
        from crewai import Agent, Task, Crew, Process
        writer = Agent(role="Writer", goal="Write articles",
                       backstory="Tech journalist", llm="gpt-4o-mini")
        task = Task(description=f"Write article based on: {self.state.research[:500]}",
                    expected_output="500-word article.", agent=writer)
        crew = Crew(agents=[writer], tasks=[task], process=Process.sequential)
        result = crew.kickoff()
        self.state.article = result.raw

    @router(write_article)
    def review_router(self):
        word_count = len(self.state.article.split())
        return "approve" if word_count >= 100 else "rewrite"

    @listen("approve")
    def publish(self):
        self.state.review_passed = True
        print("✅ Article approved and published!")
        print(self.state.article[:300])

    @listen("rewrite")
    def request_rewrite(self):
        print("⚠️  Article too short — requesting rewrite.")
        self.state.research += "\n[EXPAND: add more detail]"
        self.write_article()   # retry

if __name__ == "__main__":
    flow = ContentFlow()
    flow.kickoff()
    print("Review passed:", flow.state.review_passed)
```

### 8.2 Multi-Crew Flow Pipeline (Research → Write → Review)

```python
from crewai.flow.flow import Flow, listen, start
from crewai import Agent, Task, Crew, Process
from pydantic import BaseModel

def make_agent(role, goal, backstory):
    return Agent(role=role, goal=goal, backstory=backstory, llm="gpt-4o-mini")

class PipelineState(BaseModel):
    topic: str = "Python async programming"
    raw_research: str = ""
    draft_article: str = ""
    final_article: str = ""

class ArticlePipeline(Flow[PipelineState]):

    @start()
    def research_phase(self):
        agent = make_agent("Researcher", "Research {topic}", "Analyst")
        task  = Task(description=f"Research: {self.state.topic}",
                     expected_output="3 key findings.", agent=agent)
        result = Crew(agents=[agent], tasks=[task],
                      process=Process.sequential).kickoff()
        self.state.raw_research = result.raw

    @listen(research_phase)
    def write_phase(self):
        agent = make_agent("Writer", "Write articles", "Journalist")
        task  = Task(description=f"Write article from research:\n{self.state.raw_research}",
                     expected_output="400-word article.", agent=agent)
        result = Crew(agents=[agent], tasks=[task],
                      process=Process.sequential).kickoff()
        self.state.draft_article = result.raw

    @listen(write_phase)
    def review_phase(self):
        agent = make_agent("Editor", "Polish articles", "Senior editor")
        task  = Task(description=f"Edit and improve:\n{self.state.draft_article}",
                     expected_output="Polished article.", agent=agent)
        result = Crew(agents=[agent], tasks=[task],
                      process=Process.sequential).kickoff()
        self.state.final_article = result.raw
        print("\n=== FINAL ARTICLE ===")
        print(self.state.final_article)

if __name__ == "__main__":
    ArticlePipeline().kickoff()
```

---

## 9. CrewAI CLI

```bash
# Create a new project scaffold
crewai create crew my_research_project

# Project structure created:
# my_research_project/
# ├── src/
# │   └── my_research_project/
# │       ├── __init__.py
# │       ├── main.py          ← entry point
# │       ├── crew.py          ← Crew definition
# │       ├── config/
# │       │   ├── agents.yaml  ← agent definitions
# │       │   └── tasks.yaml   ← task definitions
# │       └── tools/
# │           └── custom_tool.py
# ├── .env
# └── pyproject.toml

# Run the crew
crewai run

# Train the crew (requires human feedback)
crewai train --n_iterations 5 --filename training_data.pkl

# Test the crew
crewai test --n_iterations 3 --model gpt-4o-mini

# Replay a specific task
crewai replay -t <task_id>
```

### agents.yaml Example

```yaml
researcher:
  role: "Senior Research Analyst"
  goal: "Uncover key trends in {topic}"
  backstory: >
    You are an experienced analyst who finds reliable, well-sourced information.
    You always verify claims before reporting them.

writer:
  role: "Content Writer"
  goal: "Write engaging articles about {topic}"
  backstory: >
    You transform technical research into clear, compelling narratives
    that developers love to read.
```

### tasks.yaml Example

```yaml
research_task:
  description: >
    Research the latest developments in {topic}.
    Find at least 5 data points from credible sources.
  expected_output: "Structured report with findings and sources."
  agent: researcher

write_task:
  description: >
    Using the research report, write a 500-word article.
    Target audience: software developers.
  expected_output: "Polished 500-word article in markdown."
  agent: writer
```

---

## 10. Testing & Evaluation

```python
from crewai import Crew, Process, Agent, Task

# Build your crew normally...
agent = Agent(role="Analyst", goal="Analyse data", backstory="Expert", llm="gpt-4o-mini")
task  = Task(description="Analyse {data}", expected_output="Insights.", agent=agent)
crew  = Crew(agents=[agent], tasks=[task], process=Process.sequential)

# --- crew.test() ---
# Runs the crew N times and uses an LLM judge to score output quality
crew.test(
    n_iterations=3,
    openai_model_name="gpt-4o",  # judge model
    inputs={"data": "Q1 sales: $1.2M, Q2: $1.5M, Q3: $1.1M"},
)

# --- crew.train() ---
# Interactively collects human feedback to improve agent behaviour
crew.train(
    n_iterations=2,
    filename="crew_training.pkl",
    inputs={"data": "Sample dataset"},
)
# After training, retrain your LLM with the saved feedback data.

# --- Manual evaluation pattern ---
import json

def evaluate_output(result, criteria: list[str]) -> dict:
    scores = {}
    text = result.raw.lower()
    for criterion in criteria:
        scores[criterion] = criterion.lower() in text
    return scores

result = crew.kickoff(inputs={"data": "test data"})
scores = evaluate_output(result, ["analysis", "trend", "recommendation"])
print(json.dumps(scores, indent=2))
```

---

## 11. Real-World Use Cases

### 11.1 Content Creation Crew

```python
import os
from crewai import Agent, Task, Crew, Process

os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY", "")

# Agents
researcher = Agent(
    role="Research Specialist",
    goal="Find accurate and current information about {topic}",
    backstory="Experienced journalist who fact-checks everything.",
    llm="gpt-4o-mini", verbose=True,
)

writer = Agent(
    role="Senior Technical Writer",
    goal="Create engaging, developer-friendly content",
    backstory="10-year veteran of developer documentation and blogs.",
    llm="gpt-4o-mini", verbose=True,
)

editor = Agent(
    role="Content Editor",
    goal="Ensure accuracy, clarity, and proper formatting",
    backstory="Perfectionist editor with a style guide in hand.",
    llm="gpt-4o-mini", verbose=True,
)

# Tasks
research = Task(
    description="Research {topic}: find 5 key facts, recent news, and use cases.",
    expected_output="Research brief with 5 facts and 3 use cases.",
    agent=researcher,
)

write = Task(
    description="Write a 600-word developer blog post about {topic}.",
    expected_output="Blog post in markdown with intro, body (3 sections), and conclusion.",
    agent=writer, context=[research],
)

edit = Task(
    description="Edit the blog post: fix grammar, improve clarity, add code examples if missing.",
    expected_output="Final polished blog post ready to publish.",
    agent=editor, context=[write],
)

content_crew = Crew(
    agents=[researcher, writer, editor],
    tasks=[research, write, edit],
    process=Process.sequential,
    verbose=True,
)

if __name__ == "__main__":
    result = content_crew.kickoff(inputs={"topic": "CrewAI multi-agent systems"})
    print(result.raw)
```

### 11.2 Code Review Crew (Sketch)

```python
from crewai import Agent, Task, Crew, Process

analyzer  = Agent(role="Code Analyzer",     goal="Find bugs and code smells",      backstory="Senior dev", llm="gpt-4o-mini")
security  = Agent(role="Security Auditor",  goal="Identify security vulnerabilities",backstory="AppSec expert",llm="gpt-4o-mini")
perf      = Agent(role="Performance Expert",goal="Find performance bottlenecks",    backstory="Perf engineer",llm="gpt-4o-mini")
doc_agent = Agent(role="Docs Reviewer",     goal="Ensure code is well documented",  backstory="Tech writer", llm="gpt-4o-mini")

code_snippet = """
def get_user(user_id):
    conn = sqlite3.connect('db.sqlite')
    query = f"SELECT * FROM users WHERE id = {user_id}"
    return conn.execute(query).fetchone()
"""

t_analyze  = Task(description=f"Analyse this code:\n{code_snippet}", expected_output="Code issues list.", agent=analyzer)
t_security = Task(description=f"Security audit:\n{code_snippet}",    expected_output="Security issues.",  agent=security)
t_perf     = Task(description=f"Performance review:\n{code_snippet}",expected_output="Perf issues.",      agent=perf)
t_docs     = Task(description=f"Docs check:\n{code_snippet}",        expected_output="Docs issues.",      agent=doc_agent)
t_summary  = Task(description="Combine all reviews into a priority-sorted action plan.",
                  expected_output="Sorted action plan.", agent=analyzer,
                  context=[t_analyze, t_security, t_perf, t_docs])

review_crew = Crew(agents=[analyzer, security, perf, doc_agent],
                   tasks=[t_analyze, t_security, t_perf, t_docs, t_summary],
                   process=Process.sequential, verbose=True)

result = review_crew.kickoff()
print(result.raw)
```

### 11.3 Customer Support Crew (Sketch)

```python
from crewai import Agent, Task, Crew, Process

classifier = Agent(role="Ticket Classifier", goal="Classify support tickets by type and urgency",
                   backstory="Support triage specialist.", llm="gpt-4o-mini")
resolver   = Agent(role="Support Agent",     goal="Resolve customer issues",
                   backstory="Experienced support engineer.", llm="gpt-4o-mini")
escalator  = Agent(role="Escalation Manager",goal="Handle tickets requiring human intervention",
                   backstory="Senior support manager.", llm="gpt-4o-mini")

ticket = "My payment was charged twice for order #1234 and I need a refund immediately!"

classify_task  = Task(description=f"Classify this ticket: {ticket}",
                      expected_output="Category and urgency (low/medium/high/critical).", agent=classifier)
resolve_task   = Task(description="Draft a resolution response for the ticket.",
                      expected_output="Customer response draft.", agent=resolver, context=[classify_task])
escalate_task  = Task(description="If urgency is high/critical, create an escalation memo.",
                      expected_output="Escalation memo or 'No escalation needed'.", agent=escalator,
                      context=[classify_task, resolve_task])

support_crew = Crew(agents=[classifier, resolver, escalator],
                    tasks=[classify_task, resolve_task, escalate_task],
                    process=Process.sequential, verbose=True)

result = support_crew.kickoff()
print(result.raw)
```

---

## 12. Performance & Cost Optimization

```python
from crewai import Agent, Task, Crew, Process

# 1. Use cheaper models for routine agents
cheap_agent = Agent(role="Formatter",   goal="Format output",   backstory="Formatter", llm="gpt-4o-mini")
smart_agent = Agent(role="Strategist",  goal="Make decisions",  backstory="Lead",      llm="gpt-4o")

# 2. Rate limiting — protect against API throttling
rate_limited_agent = Agent(
    role="Researcher", goal="Research topics", backstory="Analyst",
    llm="gpt-4o-mini",
    max_rpm=10,    # max 10 LLM requests per minute
    max_iter=3,    # max 3 reasoning iterations (reduces cost)
)

# 3. Cache tool results (see Section 5.4)
# 4. Run independent tasks in parallel (async_execution=True)
t1 = Task(description="Analyse front-end code.",  expected_output="Issues.", agent=cheap_agent, async_execution=True)
t2 = Task(description="Analyse back-end code.",   expected_output="Issues.", agent=cheap_agent, async_execution=True)
t3 = Task(description="Summarise all findings.",  expected_output="Report.", agent=smart_agent, context=[t1, t2])

# 5. Disable verbose in production
prod_crew = Crew(agents=[cheap_agent, smart_agent], tasks=[t1, t2, t3],
                 process=Process.sequential, verbose=False)

# 6. Track and log token usage
result = prod_crew.kickoff()
usage = result.token_usage
print(f"Prompt: {usage.get('prompt_tokens', 0)} | "
      f"Completion: {usage.get('completion_tokens', 0)} | "
      f"Total: {usage.get('total_tokens', 0)}")

# 7. LLM call caching (LangChain-level)
from langchain.globals import set_llm_cache
from langchain.cache import InMemoryCache, SQLiteCache

set_llm_cache(InMemoryCache())          # in-process cache
# set_llm_cache(SQLiteCache(".llm_cache.db"))  # persistent cache
```

---

## 13. Deployment

### 13.1 REST API with FastAPI

```python
# api.py
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
import uuid, asyncio
from crewai import Agent, Task, Crew, Process

app = FastAPI(title="CrewAI API")

jobs: dict = {}   # simple in-memory job store

class RunRequest(BaseModel):
    topic: str

class RunResponse(BaseModel):
    job_id: str
    status: str

def build_crew():
    agent = Agent(role="Researcher", goal="Research {topic}",
                  backstory="Analyst", llm="gpt-4o-mini")
    task  = Task(description="Research {topic} thoroughly.",
                 expected_output="Key findings.", agent=agent)
    return Crew(agents=[agent], tasks=[task], process=Process.sequential, verbose=False)

async def run_crew_async(job_id: str, topic: str):
    jobs[job_id] = {"status": "running", "result": None}
    try:
        crew = build_crew()
        result = await crew.kickoff_async(inputs={"topic": topic})
        jobs[job_id] = {"status": "done", "result": result.raw}
    except Exception as e:
        jobs[job_id] = {"status": "error", "result": str(e)}

@app.post("/run", response_model=RunResponse)
async def run_crew(req: RunRequest, bg: BackgroundTasks):
    job_id = str(uuid.uuid4())
    bg.add_task(run_crew_async, job_id, req.topic)
    return RunResponse(job_id=job_id, status="queued")

@app.get("/result/{job_id}")
async def get_result(job_id: str):
    return jobs.get(job_id, {"status": "not_found"})

# Run: uvicorn api:app --reload
```

### 13.2 Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir crewai crewai-tools fastapi uvicorn

COPY . .

ENV OPENAI_API_KEY=""
ENV SERPER_API_KEY=""

EXPOSE 8000
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
# Build and run
docker build -t crewai-app .
docker run -e OPENAI_API_KEY=sk-... -p 8000:8000 crewai-app

# docker-compose.yml
# version: "3.9"
# services:
#   crewai:
#     build: .
#     ports: ["8000:8000"]
#     environment:
#       - OPENAI_API_KEY=${OPENAI_API_KEY}
```

### 13.3 CrewAI Enterprise

CrewAI Enterprise provides:
- **CrewAI Studio** — visual crew builder (no code)
- **Managed execution** — scalable cloud runner
- **Observability** — traces, logs, replays
- **Webhooks & API** — trigger crews from any system
- **RBAC** — team access controls

```bash
# Connect local project to Enterprise
crewai login
crewai deploy
```

---

## 14. Interview Q&A

**Q1: What is a Crew in CrewAI and what are its components?**
> A `Crew` is the top-level orchestrator. Its components are: **Agents** (specialised AI workers with role/goal/backstory/tools), **Tasks** (units of work with description/expected_output/agent), a **Process** (sequential, hierarchical, or parallel), optional **Memory**, and optional **Tools**. You call `crew.kickoff()` to start execution.

---

**Q2: What is the difference between Sequential and Hierarchical process?**
> **Sequential**: tasks execute in declaration order; each task receives the previous task's output as context. Great for predictable pipelines.
> **Hierarchical**: a `manager_llm` dynamically decides which agent handles which task and in what order. No need to pre-assign agents to tasks. Best for open-ended, complex workflows where the decomposition strategy isn't known upfront.

---

**Q3: How do you create a custom tool in CrewAI?**
> Two ways:
> 1. `@tool` decorator — fastest for simple functions. The docstring becomes the tool description the LLM reads.
> 2. `BaseTool` subclass — for complex tools needing Pydantic fields, validation, or shared state.
> Both approaches attach to an agent via its `tools=[...]` list.

---

**Q4: How does memory work in CrewAI?**
> CrewAI has four memory layers: **Short-term** (in-memory RAG for current session), **Long-term** (SQLite persisted across sessions), **Entity** (ChromaDB tracks people, companies, systems), and **Contextual** (automatically blends all three). Enable with `memory=True` on the Crew. Agents query memory before responding and write to it after each task.

---

**Q5: What is context in a Task and how does it enable dependencies?**
> `context=[other_task]` passes the *output* of `other_task` as additional context to the current task's prompt. This is how you chain tasks without manually threading strings. The receiving task sees the previous task's `raw` output injected into its system prompt.

---

**Q6: How do you get structured output from a CrewAI crew?**
> Set `output_pydantic=MyModel` on a `Task`. CrewAI prompts the agent to return valid JSON matching the Pydantic schema, then parses it. Access via `result.pydantic` (returns a `MyModel` instance) or `result.tasks_output[i].pydantic`. For raw JSON dict use `output_json=schema_dict` and access `result.json_dict`.

---

**Q7: What is allow_delegation and when should you enable it?**
> `allow_delegation=True` lets an agent transfer a sub-task to another agent in the crew when it decides another agent is better suited. Enable it for general-purpose agents in hierarchical crews. Disable it for specialist agents in sequential pipelines (prevents unintended handoffs that add latency and cost).

---

**Q8: How do you run tasks in parallel in CrewAI?**
> Set `async_execution=True` on any tasks that are independent of each other. They will run concurrently. A downstream synchronising task uses `context=[async_task_1, async_task_2]` to wait for both and merge their outputs. The Crew still uses `Process.sequential` — the async flag is per-task, not per-crew.

---

**Q9: What are CrewAI Flows and how do they differ from a Crew?**
> A **Crew** is a single collaborative unit of agents working on related tasks. A **Flow** is a higher-level state machine that orchestrates *multiple* crews (or other logic) with `@start`, `@listen`, and `@router` decorators. Flows have typed shared state (Pydantic model), conditional branching, and event-driven wiring between phases. Use Flows when you need multi-crew pipelines, conditional reruns, or complex branching.

---

**Q10: How do you control which LLM each agent uses?**
> Pass the `llm=` parameter to each `Agent`. Accepts a string shorthand (`"gpt-4o-mini"`), a LangChain chat model instance, or any LiteLLM-compatible string (`"ollama/llama3.2"`). This lets you use cheap models for formatters and routing agents while reserving expensive models for reasoning-heavy agents.

---

**Q11: How do you test a CrewAI crew?**
> Use `crew.test(n_iterations=3, openai_model_name="gpt-4o")`. This runs the crew N times and uses a separate judge LLM to score output quality across criteria (relevance, accuracy, completeness). For training, use `crew.train()` to collect human-labelled feedback. For unit testing, mock the LLM and assert on `result.raw` content.

---

**Q12: What is the manager_llm in hierarchical process?**
> In `Process.hierarchical`, CrewAI automatically creates a *manager agent* that receives the overall goal, breaks it down into sub-tasks, and delegates them to the available agents. `manager_llm` specifies which LLM powers this manager. It should be a capable model (e.g., GPT-4o) since it drives the entire decomposition and delegation logic.

---

**Q13: How does CrewAI compare to LangGraph for multi-agent systems?**
> CrewAI is **declarative** — define agents, tasks, and process type; the framework handles orchestration. LangGraph is **imperative** — you build an explicit state machine with nodes and edges, giving full control over every transition. CrewAI is faster to build for structured pipelines; LangGraph is better for complex loops, conditional retries, and fine-grained state management.

---

**Q14: How do you handle errors and retries in CrewAI agents?**
> Set `max_iter=N` on an agent to limit reasoning loops. For task-level retries, wrap `crew.kickoff()` in a try/except and re-kickoff on failure. For tool errors, return an error string from the tool — the agent will see it and try an alternative approach. You can also subclass `BaseTool` and implement custom retry logic with `tenacity`.

```python
from tenacity import retry, stop_after_attempt, wait_exponential
from crewai.tools import BaseTool

class ResilientTool(BaseTool):
    name: str = "Resilient API"
    description: str = "Calls an external API with retries."

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    def _run(self, query: str) -> str:
        import requests
        resp = requests.get(f"https://api.example.com?q={query}", timeout=5)
        resp.raise_for_status()
        return resp.json().get("result", "No result")
```

---

**Q15: What are the token usage tracking capabilities?**
> After `crew.kickoff()`, access `result.token_usage` — a dict with `prompt_tokens`, `completion_tokens`, and `total_tokens`. Individual task token usage is available via `result.tasks_output[i].token_usage`. For production cost monitoring, integrate AgentOps (`pip install agentops`) which provides per-run dashboards, traces, and cost breakdowns.

```python
result = crew.kickoff(inputs={"topic": "AI"})
usage  = result.token_usage
cost   = (usage.get("prompt_tokens", 0) / 1000 * 0.00015 +
          usage.get("completion_tokens", 0) / 1000 * 0.0006)
print(f"Estimated cost (gpt-4o-mini): ${cost:.4f}")
```

---

## 15. Complete End-to-End Example

**SDLC Documentation Crew** — reads source code, writes API docs, reviews for completeness, and publishes to a markdown file.

```python
"""
SDLC Documentation Crew
========================
Agents:
  1. code_reader   — reads and understands source code
  2. doc_writer    — writes structured API documentation
  3. doc_reviewer  — reviews docs for accuracy and completeness
  4. publisher     — formats and writes final docs to a file

Usage:
  pip install crewai crewai-tools
  export OPENAI_API_KEY=sk-...
  python sdlc_docs_crew.py
"""

import os
import pathlib
from crewai import Agent, Task, Crew, Process
from crewai.tools import tool
from pydantic import BaseModel

# ---------- Structured output schema ----------
class DocumentationReport(BaseModel):
    module_name: str
    description: str
    functions: list[str]
    usage_examples: list[str]
    notes: list[str]

# ---------- Custom tools ----------
@tool("Read Source File")
def read_source(file_path: str) -> str:
    """Read a Python source file and return its contents."""
    try:
        return pathlib.Path(file_path).read_text(encoding="utf-8")
    except FileNotFoundError:
        return f"File not found: {file_path}"

@tool("Write Documentation File")
def write_docs(content: str) -> str:
    """Write documentation content to docs/output.md. Input: markdown string."""
    out = pathlib.Path("docs/output.md")
    out.parent.mkdir(exist_ok=True)
    out.write_text(content, encoding="utf-8")
    return f"Documentation written to {out.resolve()}"

# ---------- Source code to document ----------
SAMPLE_CODE = '''
def add(a: int, b: int) -> int:
    """Return the sum of a and b."""
    return a + b

def divide(a: float, b: float) -> float:
    """Divide a by b. Raises ZeroDivisionError if b is zero."""
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b

class Calculator:
    """Simple arithmetic calculator."""

    def __init__(self, precision: int = 2):
        self.precision = precision

    def compute(self, expr: str) -> float:
        """Evaluate a simple arithmetic expression string."""
        return round(eval(expr), self.precision)
'''

# Write sample code to a temp file for the crew to read
pathlib.Path("sample_module.py").write_text(SAMPLE_CODE, encoding="utf-8")

# ---------- Agents ----------
code_reader = Agent(
    role="Code Analyst",
    goal="Read and thoroughly understand Python source code",
    backstory=(
        "You are a senior Python developer who can read code and extract "
        "intent, parameters, return types, and potential issues."
    ),
    llm="gpt-4o-mini",
    tools=[read_source],
    verbose=True,
)

doc_writer = Agent(
    role="Technical Documentation Writer",
    goal="Write clear, complete API documentation from code analysis",
    backstory=(
        "You produce developer-grade documentation: function signatures, "
        "parameter descriptions, return types, and usage examples."
    ),
    llm="gpt-4o-mini",
    verbose=True,
)

doc_reviewer = Agent(
    role="Documentation Reviewer",
    goal="Ensure documentation is accurate, complete, and developer-friendly",
    backstory=(
        "You have an eye for gaps: missing edge cases, unclear descriptions, "
        "or missing examples. You return a pass/fail verdict with notes."
    ),
    llm="gpt-4o-mini",
    verbose=True,
)

publisher = Agent(
    role="Documentation Publisher",
    goal="Format and publish the final documentation to a markdown file",
    backstory=(
        "You format documentation in clean markdown and persist it to disk "
        "using the write tool."
    ),
    llm="gpt-4o-mini",
    tools=[write_docs],
    verbose=True,
)

# ---------- Tasks ----------
read_task = Task(
    description=(
        "Read the file 'sample_module.py' using your tool. "
        "Identify all functions and classes, their parameters, return types, "
        "docstrings, and any edge cases you notice."
    ),
    expected_output=(
        "A structured analysis listing every function/class with signature, "
        "purpose, parameters, return type, and edge cases."
    ),
    agent=code_reader,
)

write_task = Task(
    description=(
        "Using the code analysis, write complete API documentation in markdown. "
        "Include: module overview, each function/class with signature, "
        "parameter table, return value, and at least one usage example each."
    ),
    expected_output=(
        "Full markdown API documentation with sections for each function and class."
    ),
    agent=doc_writer,
    context=[read_task],
    output_pydantic=DocumentationReport,
)

review_task = Task(
    description=(
        "Review the API documentation draft. Check: "
        "(1) all functions/classes are documented, "
        "(2) examples are correct and runnable, "
        "(3) edge cases (like ZeroDivisionError) are mentioned. "
        "Return APPROVED with notes, or REVISION NEEDED with specific gaps."
    ),
    expected_output="Review verdict (APPROVED or REVISION NEEDED) with detailed notes.",
    agent=doc_reviewer,
    context=[write_task],
)

publish_task = Task(
    description=(
        "Take the reviewed documentation and write it to a markdown file "
        "using your write tool. Include a header, the review verdict, "
        "and the full documentation."
    ),
    expected_output="Confirmation message with the file path of the saved documentation.",
    agent=publisher,
    context=[write_task, review_task],
)

# ---------- Crew ----------
docs_crew = Crew(
    agents=[code_reader, doc_writer, doc_reviewer, publisher],
    tasks=[read_task, write_task, review_task, publish_task],
    process=Process.sequential,
    memory=False,
    verbose=True,
)

# ---------- Run ----------
if __name__ == "__main__":
    print("🚀 Starting SDLC Documentation Crew...\n")
    result = docs_crew.kickoff()

    print("\n" + "=" * 60)
    print("CREW COMPLETE")
    print("=" * 60)

    # Typed output from write_task
    for t in result.tasks_output:
        if t.pydantic:
            doc: DocumentationReport = t.pydantic
            print(f"\n📄 Module: {doc.module_name}")
            print(f"   Description: {doc.description}")
            print(f"   Functions documented: {len(doc.functions)}")

    # Token usage summary
    usage = result.token_usage
    print(f"\n🪙 Tokens — Prompt: {usage.get('prompt_tokens', 0)}, "
          f"Completion: {usage.get('completion_tokens', 0)}, "
          f"Total: {usage.get('total_tokens', 0)}")

    print("\n✅ Documentation saved to docs/output.md")

    # Cleanup temp file
    pathlib.Path("sample_module.py").unlink(missing_ok=True)
```

---

## Quick Reference

```python
# Minimal working crew
from crewai import Agent, Task, Crew, Process

agent  = Agent(role="Writer", goal="Write content", backstory="Expert", llm="gpt-4o-mini")
task   = Task(description="Write a haiku about Python.", expected_output="A haiku.", agent=agent)
result = Crew(agents=[agent], tasks=[task], process=Process.sequential).kickoff()
print(result.raw)
```

| Concept | Key Parameter | Purpose |
|---------|--------------|---------|
| `Agent` | `role`, `goal`, `backstory`, `llm`, `tools` | Define AI worker |
| `Task` | `description`, `expected_output`, `agent`, `context` | Define unit of work |
| `Crew` | `agents`, `tasks`, `process`, `memory` | Orchestrate execution |
| `Process.sequential` | — | Ordered pipeline |
| `Process.hierarchical` | `manager_llm` | Dynamic delegation |
| `async_execution=True` | Task flag | Run task in parallel |
| `output_pydantic=Model` | Task flag | Typed structured output |
| `memory=True` | Crew flag | Enable all memory layers |
| `allow_delegation=True` | Agent flag | Agent can hand off work |
| `max_iter`, `max_rpm` | Agent flags | Cost/rate control |

---

*Guide generated for CrewAI ≥ 0.70. For the latest API, see [docs.crewai.com](https://docs.crewai.com).*
