"""
build_guide.py - Generates AI-LIBRARIES-GUIDE.md (2000+ lines)
Run: python build_guide.py
"""

import os

TARGET = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "content", "ai-libraries-guide.md")

sections = []

# ─────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────
sections.append("""# AI Libraries & Frameworks: Complete Developer Guide

> A comprehensive reference for building AI-powered applications with LangChain, LangGraph,
> CrewAI, AutoGen, LlamaIndex, Haystack, Semantic Kernel, DSPy, MCP, ACP and more.

---

## Table of Contents

1. [Part 1 – AI Library Reference](#part-1--ai-library-reference)
2. [Part 2 – App-by-App Improvement Guide](#part-2--app-by-app-improvement-guide)
3. [Part 3 – 12 New App Blueprints](#part-3--12-new-app-blueprints)
4. [Part 4 – Free & Paid Learning Resources](#part-4--free--paid-learning-resources)
5. [Part 5 – 10 Complete Code Recipes](#part-5--10-complete-code-recipes)

---
""")

# ─────────────────────────────────────────────
# PART 1 – AI LIBRARY REFERENCE
# ─────────────────────────────────────────────
sections.append("""## Part 1 – AI Library Reference

This section covers the most important AI orchestration libraries, their strengths, weaknesses,
and when to use them.

---

### 1.1 LangChain

**What it is:** The most popular LLM application framework. Provides chains, agents, tools,
memory, and retrieval components.

**Install:**
```bash
pip install langchain langchain-openai langchain-community
```

**Key concepts:**
- **Chains** – sequential pipelines of LLM calls and tools
- **Agents** – LLMs that decide which tools to call
- **Memory** – short/long-term conversation state
- **Retrievers** – fetch context from vector stores or search

**Strengths:**
- Huge ecosystem of integrations (100+ LLM providers, 50+ vector stores)
- Active community and documentation
- LCEL (LangChain Expression Language) for composable pipelines

**Weaknesses:**
- Can be verbose and over-abstracted for simple tasks
- Debugging complex chains is non-trivial
- Rapid API changes between versions

**When to use:**
- RAG (Retrieval-Augmented Generation) applications
- Chatbots with memory and tool use
- Document processing pipelines

**Minimal example:**
```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o-mini")
response = llm.invoke([HumanMessage(content="What is LangChain?")])
print(response.content)
```

**LCEL chain example:**
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_template("Explain {topic} in one sentence.")
llm = ChatOpenAI(model="gpt-4o-mini")
parser = StrOutputParser()

chain = prompt | llm | parser
result = chain.invoke({"topic": "vector embeddings"})
print(result)
```

---

### 1.2 LangGraph

**What it is:** A graph-based framework for building stateful, multi-step AI agents. Built on
top of LangChain. Uses nodes and edges to define agent workflows.

**Install:**
```bash
pip install langgraph langchain-openai
```

**Key concepts:**
- **StateGraph** – directed graph where nodes are functions and edges define transitions
- **State** – typed dict shared across all nodes
- **Conditional edges** – route execution based on state values
- **Human-in-the-loop** – pause graph for user input

**Strengths:**
- Explicit control flow (unlike ReAct agents)
- Built-in streaming and checkpointing
- Great for complex multi-step workflows
- Supports cycles (loops) unlike simple chains

**Weaknesses:**
- Steeper learning curve than basic LangChain
- Requires careful state schema design

**When to use:**
- Complex agents with branching logic
- Multi-agent workflows
- Long-running tasks that need checkpointing
- Agents that need to loop until a condition is met

**Basic graph example:**
```python
from typing import TypedDict
from langgraph.graph import StateGraph, END

class AgentState(TypedDict):
    question: str
    answer: str
    iterations: int

def researcher(state: AgentState) -> AgentState:
    # Simulate research step
    return {**state, "answer": f"Research answer for: {state['question']}", "iterations": state["iterations"] + 1}

def should_continue(state: AgentState) -> str:
    if state["iterations"] >= 2:
        return "end"
    return "continue"

graph = StateGraph(AgentState)
graph.add_node("researcher", researcher)
graph.set_entry_point("researcher")
graph.add_conditional_edges("researcher", should_continue, {"continue": "researcher", "end": END})

app = graph.compile()
result = app.invoke({"question": "What is AI?", "answer": "", "iterations": 0})
print(result["answer"])
```

---

### 1.3 CrewAI

**What it is:** A framework for orchestrating role-playing AI agents that collaborate on tasks.
Agents have roles, goals, backstories, and tools.

**Install:**
```bash
pip install crewai crewai-tools
```

**Key concepts:**
- **Agent** – has a role, goal, backstory, and optional tools
- **Task** – a specific job assigned to an agent
- **Crew** – a group of agents working together
- **Process** – sequential or hierarchical task execution

**Strengths:**
- Natural agent role definitions
- Easy to set up multi-agent teams
- Built-in task delegation
- Works well with custom tools

**Weaknesses:**
- Less control over individual LLM calls
- Can be expensive (many LLM calls per task)
- Limited support for async workflows

**When to use:**
- Content creation pipelines (researcher + writer + editor)
- Software development automation
- Business process automation with distinct roles

**Basic crew example:**
```python
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o-mini")

researcher = Agent(
    role="Senior Researcher",
    goal="Find accurate information on {topic}",
    backstory="Expert at finding and summarizing information.",
    llm=llm,
    verbose=False
)

writer = Agent(
    role="Content Writer",
    goal="Write a concise blog post about {topic}",
    backstory="Skilled technical writer.",
    llm=llm,
    verbose=False
)

research_task = Task(
    description="Research the topic: {topic}. Summarize key points.",
    expected_output="A bullet-point summary of key facts.",
    agent=researcher
)

write_task = Task(
    description="Write a 200-word blog post using the research provided.",
    expected_output="A complete blog post.",
    agent=writer
)

crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, write_task],
    process=Process.sequential
)

result = crew.kickoff(inputs={"topic": "LangGraph"})
print(result)
```

---

### 1.4 AutoGen

**What it is:** Microsoft's framework for multi-agent conversation systems. Agents can be
human-proxy agents, AI assistants, or custom agents that converse with each other.

**Install:**
```bash
pip install pyautogen
```

**Key concepts:**
- **ConversableAgent** – base class for all agents
- **AssistantAgent** – AI-powered agent
- **UserProxyAgent** – acts as a human proxy, can execute code
- **GroupChat** – multiple agents in one conversation

**Strengths:**
- Excellent for code generation and execution
- Built-in human-in-the-loop support
- Agents can run Python code automatically
- Strong Microsoft ecosystem integration

**Weaknesses:**
- Chat-based model can be inefficient for non-conversational tasks
- Less flexible than graph-based approaches for complex workflows

**When to use:**
- Code generation and automated testing
- Data analysis workflows
- Pair-programming simulations

**Basic AutoGen example:**
```python
import autogen

config_list = [{"model": "gpt-4o-mini", "api_key": "YOUR_API_KEY"}]

assistant = autogen.AssistantAgent(
    name="assistant",
    llm_config={"config_list": config_list}
)

user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=3,
    code_execution_config={"work_dir": "coding", "use_docker": False}
)

user_proxy.initiate_chat(
    assistant,
    message="Write a Python function to calculate fibonacci numbers and test it."
)
```

---

### 1.5 LlamaIndex

**What it is:** A data framework for connecting custom data sources to LLMs. Specializes in
ingestion, indexing, and querying of documents.

**Install:**
```bash
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai
```

**Key concepts:**
- **Document** – a piece of text with metadata
- **Index** – searchable representation of documents (vector, keyword, tree, etc.)
- **Query Engine** – answers questions over an index
- **Node** – chunk of a document

**Strengths:**
- Best-in-class RAG capabilities
- Many index types (vector, summary, keyword, knowledge graph)
- Rich metadata filtering
- Supports complex multi-document queries

**Weaknesses:**
- Can be complex for non-RAG use cases
- API changes frequently

**When to use:**
- Document Q&A systems
- Knowledge base chatbots
- Multi-document reasoning

**Basic LlamaIndex example:**
```python
from llama_index.core import VectorStoreIndex, Document
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings

Settings.llm = OpenAI(model="gpt-4o-mini")

documents = [
    Document(text="LlamaIndex is a data framework for LLM applications."),
    Document(text="It supports vector stores, keyword search, and knowledge graphs."),
]

index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine()

response = query_engine.query("What is LlamaIndex?")
print(response)
```

---

### 1.6 Haystack

**What it is:** An open-source NLP framework for building search and QA systems. Originally
focused on search, now supports full LLM pipelines.

**Install:**
```bash
pip install haystack-ai
```

**Key concepts:**
- **Pipeline** – directed graph of components
- **Component** – a processing unit (retriever, reader, embedder, etc.)
- **DocumentStore** – stores documents for retrieval
- **PromptBuilder** – builds prompts from templates

**Strengths:**
- Production-ready with strong evaluation tools
- Excellent hybrid search (BM25 + embeddings)
- Clean pipeline abstraction
- Great for enterprise search

**Weaknesses:**
- Less flexible than LangChain for non-search use cases
- Smaller community

**When to use:**
- Enterprise document search
- Customer support QA systems
- Hybrid retrieval pipelines

**Basic Haystack example:**
```python
from haystack import Document, Pipeline
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.document_stores.in_memory import InMemoryDocumentStore

store = InMemoryDocumentStore()
store.write_documents([
    Document(content="Haystack is an NLP framework for search and QA."),
    Document(content="It supports BM25 and semantic retrieval."),
])

prompt_template = \"\"\"
Given the context: {% for doc in documents %}{{ doc.content }}{% endfor %}
Answer: {{ question }}
\"\"\"

pipeline = Pipeline()
pipeline.add_component("retriever", InMemoryBM25Retriever(document_store=store))
pipeline.add_component("prompt_builder", PromptBuilder(template=prompt_template))
pipeline.add_component("llm", OpenAIGenerator(model="gpt-4o-mini"))

pipeline.connect("retriever", "prompt_builder.documents")
pipeline.connect("prompt_builder", "llm")

result = pipeline.run({"retriever": {"query": "What is Haystack?"}, "prompt_builder": {"question": "What is Haystack?"}})
print(result["llm"]["replies"][0])
```

---

### 1.7 Semantic Kernel

**What it is:** Microsoft's SDK for integrating AI models into applications. Available in
Python, C#, and Java. Supports plugins, planners, and memory.

**Install:**
```bash
pip install semantic-kernel
```

**Key concepts:**
- **Kernel** – central orchestrator
- **Plugin** – collection of functions the AI can call
- **Planner** – automatically creates plans to achieve goals
- **Memory** – semantic memory using embeddings

**Strengths:**
- Enterprise-grade with Microsoft backing
- Excellent C#/.NET support
- Strong Azure OpenAI integration
- Plugin system is clean and composable

**Weaknesses:**
- Python SDK lags behind C# in features
- Less flexible than LangChain

**When to use:**
- Enterprise applications on Azure
- .NET/C# AI applications
- Applications needing structured AI planning

**Basic Semantic Kernel example:**
```python
import asyncio
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion

async def main():
    kernel = Kernel()
    kernel.add_service(OpenAIChatCompletion(
        service_id="chat",
        ai_model_id="gpt-4o-mini"
    ))

    prompt = "Write a haiku about {{$topic}}"
    haiku_function = kernel.add_function(
        function_name="haiku",
        plugin_name="writer",
        prompt=prompt
    )

    result = await kernel.invoke(haiku_function, topic="artificial intelligence")
    print(result)

asyncio.run(main())
```

---

### 1.8 DSPy

**What it is:** Stanford's framework for programming—not prompting—language models.
Uses signatures, modules, and optimizers to automatically improve prompts.

**Install:**
```bash
pip install dspy-ai
```

**Key concepts:**
- **Signature** – defines input/output fields (like a type signature for prompts)
- **Module** – composable unit (Predict, ChainOfThought, ReAct, etc.)
- **Optimizer/Teleprompter** – automatically optimizes prompts with examples
- **Program** – a composition of modules

**Strengths:**
- Automatic prompt optimization (no manual prompt engineering)
- Highly composable
- Excellent for building robust, testable AI programs
- Can optimize for any metric

**Weaknesses:**
- Requires labeled examples for optimization
- More complex mental model than simple prompting
- Smaller community than LangChain

**When to use:**
- When you need reliable, optimized pipelines
- Classification and extraction tasks
- Multi-hop reasoning tasks
- When you want to treat prompts as code

**Basic DSPy example:**
```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class QA(dspy.Signature):
    '''Answer questions with short factoid answers.'''
    question: str = dspy.InputField()
    answer: str = dspy.OutputField(desc="often between 1 and 5 words")

predictor = dspy.Predict(QA)
result = predictor(question="What is the capital of France?")
print(result.answer)
```

**Chain-of-thought example:**
```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class Reasoning(dspy.Signature):
    '''Solve math problems step by step.'''
    problem: str = dspy.InputField()
    answer: str = dspy.OutputField()

cot = dspy.ChainOfThought(Reasoning)
result = cot(problem="If a train travels 60 mph for 2.5 hours, how far does it go?")
print(result.answer)
```

---

### 1.9 MCP (Model Context Protocol)

**What it is:** Anthropic's open protocol for connecting AI assistants to external data sources
and tools. Standardizes how models access context.

**Install:**
```bash
pip install mcp
```

**Key concepts:**
- **Server** – exposes resources, tools, and prompts
- **Client** – connects to servers (e.g., Claude Desktop)
- **Resource** – data the model can read (files, APIs, databases)
- **Tool** – function the model can call
- **Prompt** – reusable prompt templates

**Strengths:**
- Standardized protocol (works across AI clients)
- Separates data layer from AI layer
- Supports local and remote servers
- Growing ecosystem

**Weaknesses:**
- Still evolving standard
- Client support varies

**When to use:**
- Building AI tools for Claude Desktop
- Exposing internal tools to AI assistants
- Creating reusable tool servers

**Basic MCP server example:**
```python
from mcp.server import FastMCP

mcp = FastMCP("My AI Tools")

@mcp.tool()
def get_weather(city: str) -> str:
    \"\"\"Get current weather for a city.\"\"\"
    # In real use, call a weather API here
    return f"Weather in {city}: 72°F, sunny"

@mcp.resource("notes://latest")
def get_latest_notes() -> str:
    \"\"\"Get the latest notes.\"\"\"
    return "Latest notes: Meeting at 3pm, Review PR #42"

if __name__ == "__main__":
    mcp.run()
```

---

### 1.10 ACP (Agent Communication Protocol)

**What it is:** IBM's open protocol for agent-to-agent communication. Defines how AI agents
discover, communicate, and collaborate with each other.

**Install:**
```bash
pip install acp-sdk
```

**Key concepts:**
- **Agent** – an AI service that can receive and respond to messages
- **Message** – structured communication between agents
- **Run** – a single execution of an agent
- **Manifest** – describes agent capabilities

**Strengths:**
- Standardized agent interoperability
- Supports streaming responses
- Cloud-native design

**Weaknesses:**
- Very new standard (2024/2025)
- Limited tooling compared to LangChain

**When to use:**
- Building agent networks that need to interoperate
- Microservice-style AI architectures
- When multiple teams build different agents

**Basic ACP agent example:**
```python
from acp_sdk.server import Server
from acp_sdk.models import Message, MessagePart

app = Server()

@app.agent()
async def summarizer(input: list[Message], **kwargs):
    \"\"\"Summarizes the input text.\"\"\"
    text = input[0].parts[0].content
    # In real use, call an LLM here
    summary = f"Summary: {text[:100]}..."
    yield Message(parts=[MessagePart(content=summary)])

if __name__ == "__main__":
    app.run()
```

---
""")

# ─────────────────────────────────────────────
# PART 2 – APP-BY-APP IMPROVEMENT GUIDE
# ─────────────────────────────────────────────
sections.append("""## Part 2 – App-by-App Improvement Guide

This section shows how to upgrade each of the 6 existing apps using the AI libraries above.

---

### App 1: Simple Chatbot → Multi-turn Memory Chatbot

**Current state:** A basic chatbot that calls an LLM with a single message.

**Improvements:**
1. Add conversation memory using LangChain's `ConversationBufferMemory`
2. Add system prompt for persona
3. Add streaming responses
4. Persist conversation history to disk

**Upgrade code:**
```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
import json, os

HISTORY_FILE = "chat_history.json"

def load_history():
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE) as f:
            return json.load(f)
    return []

def save_history(history):
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2)

def build_chain():
    llm = ChatOpenAI(model="gpt-4o-mini", streaming=True)
    prompt = ChatPromptTemplate.from_messages([
        SystemMessage(content="You are a helpful AI assistant named Aria. Be concise and friendly."),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}")
    ])
    return prompt | llm | StrOutputParser()

def chat():
    chain = build_chain()
    raw_history = load_history()
    history = []
    for msg in raw_history:
        if msg["role"] == "human":
            history.append(HumanMessage(content=msg["content"]))
        else:
            history.append(AIMessage(content=msg["content"]))

    print("Chatbot ready. Type 'quit' to exit.")
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() == "quit":
            break
        print("Aria: ", end="", flush=True)
        response = ""
        for chunk in chain.stream({"input": user_input, "history": history}):
            print(chunk, end="", flush=True)
            response += chunk
        print()
        history.append(HumanMessage(content=user_input))
        history.append(AIMessage(content=response))
        raw_history.append({"role": "human", "content": user_input})
        raw_history.append({"role": "ai", "content": response})
        save_history(raw_history)

if __name__ == "__main__":
    chat()
```

---

### App 2: Document Q&A → Advanced RAG with Hybrid Search

**Current state:** A basic document Q&A using vector similarity search.

**Improvements:**
1. Add BM25 keyword search alongside vector search (hybrid retrieval)
2. Add metadata filtering
3. Add re-ranking step
4. Add citation tracking (show which document was used)

**Upgrade code:**
```python
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_community.retrievers import BM25Retriever
from langchain.retrievers import EnsembleRetriever
from langchain_community.document_loaders import DirectoryLoader, TextLoader

def build_hybrid_rag(docs_dir: str):
    loader = DirectoryLoader(docs_dir, glob="**/*.txt", loader_cls=TextLoader)
    docs = loader.load()

    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    chunks = splitter.split_documents(docs)

    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    vectorstore = Chroma.from_documents(chunks, embeddings)
    vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

    bm25_retriever = BM25Retriever.from_documents(chunks)
    bm25_retriever.k = 3

    hybrid_retriever = EnsembleRetriever(
        retrievers=[bm25_retriever, vector_retriever],
        weights=[0.4, 0.6]
    )

    prompt = ChatPromptTemplate.from_template(\"\"\"
Answer the question using ONLY the context below. If unsure, say "I don't know."
Cite the source file for each fact.

Context:
{context}

Question: {question}
Answer:\"\"\")

    llm = ChatOpenAI(model="gpt-4o-mini")

    def format_docs(docs):
        return "\\n\\n".join(
            f"[Source: {d.metadata.get('source', 'unknown')}]\\n{d.page_content}"
            for d in docs
        )

    chain = (
        {"context": hybrid_retriever | format_docs, "question": RunnablePassthrough()}
        | prompt
        | llm
        | StrOutputParser()
    )
    return chain

# Usage:
# chain = build_hybrid_rag("./docs")
# print(chain.invoke("What is the main topic of the documents?"))
```

---

### App 3: Code Assistant → LangGraph-Powered Code Agent

**Current state:** A simple code completion assistant.

**Improvements:**
1. Use LangGraph to create a multi-step agent
2. Add code execution capability
3. Add test generation step
4. Add fix loop (run → if error → fix → run again)

**Upgrade code:**
```python
from typing import TypedDict, Optional
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
import subprocess, sys

class CodeState(TypedDict):
    task: str
    code: str
    test_output: str
    error: str
    iterations: int
    done: bool

llm = ChatOpenAI(model="gpt-4o-mini")

def generate_code(state: CodeState) -> CodeState:
    prompt = f"Write Python code to: {state['task']}\\nReturn ONLY the code, no markdown."
    if state.get("error"):
        prompt = f"Fix this Python code that has error:\\n{state['code']}\\nError: {state['error']}\\nReturn ONLY fixed code."
    response = llm.invoke([HumanMessage(content=prompt)])
    code = response.content.strip()
    if code.startswith("```"):
        code = "\\n".join(code.split("\\n")[1:-1])
    return {**state, "code": code, "error": ""}

def run_code(state: CodeState) -> CodeState:
    try:
        result = subprocess.run(
            [sys.executable, "-c", state["code"]],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return {**state, "error": result.stderr, "iterations": state["iterations"] + 1}
        return {**state, "test_output": result.stdout, "done": True}
    except subprocess.TimeoutExpired:
        return {**state, "error": "Code timed out", "iterations": state["iterations"] + 1}

def should_retry(state: CodeState) -> str:
    if state["done"]:
        return "done"
    if state["iterations"] >= 3:
        return "done"
    return "fix"

graph = StateGraph(CodeState)
graph.add_node("generate", generate_code)
graph.add_node("run", run_code)
graph.set_entry_point("generate")
graph.add_edge("generate", "run")
graph.add_conditional_edges("run", should_retry, {"fix": "generate", "done": END})

code_agent = graph.compile()

def run_task(task: str):
    result = code_agent.invoke({
        "task": task, "code": "", "test_output": "",
        "error": "", "iterations": 0, "done": False
    })
    print("Generated Code:")
    print(result["code"])
    print("\\nOutput:", result["test_output"] or f"Error: {result['error']}")

# run_task("print the first 10 fibonacci numbers")
```

---

### App 4: Data Analyst → CrewAI Multi-Agent Analyst

**Current state:** A single-agent data analysis tool.

**Improvements:**
1. Use CrewAI to create a team: data collector, analyst, and report writer
2. Add tool use (CSV reader, statistics calculator)
3. Add structured output

**Upgrade code:**
```python
from crewai import Agent, Task, Crew, Process
from crewai.tools import tool
from langchain_openai import ChatOpenAI
import csv, statistics

llm = ChatOpenAI(model="gpt-4o-mini")

@tool("CSV Reader")
def read_csv_tool(filepath: str) -> str:
    \"\"\"Reads a CSV file and returns its contents as a string.\"\"\"
    try:
        with open(filepath, newline="") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
        return str(rows[:20])  # First 20 rows
    except Exception as e:
        return f"Error reading CSV: {e}"

@tool("Statistics Calculator")
def stats_tool(numbers: str) -> str:
    \"\"\"Calculate statistics for comma-separated numbers.\"\"\"
    try:
        nums = [float(x.strip()) for x in numbers.split(",")]
        return (f"Count: {len(nums)}, Mean: {statistics.mean(nums):.2f}, "
                f"Median: {statistics.median(nums):.2f}, "
                f"Stdev: {statistics.stdev(nums):.2f}")
    except Exception as e:
        return f"Error: {e}"

collector = Agent(role="Data Collector", goal="Load and describe the dataset",
                  backstory="Expert at loading and summarizing data.", llm=llm,
                  tools=[read_csv_tool], verbose=False)

analyst = Agent(role="Data Analyst", goal="Perform statistical analysis",
                backstory="Expert statistician.", llm=llm,
                tools=[stats_tool], verbose=False)

writer = Agent(role="Report Writer", goal="Write a clear analysis report",
               backstory="Expert technical writer.", llm=llm, verbose=False)

def analyze_data(filepath: str, question: str) -> str:
    collect_task = Task(
        description=f"Load data from {filepath} and describe its structure.",
        expected_output="Data description with column names and sample values.",
        agent=collector
    )
    analyze_task = Task(
        description=f"Analyze the data to answer: {question}",
        expected_output="Statistical findings with numbers.",
        agent=analyst
    )
    report_task = Task(
        description="Write a 3-paragraph report summarizing the findings.",
        expected_output="A professional analysis report.",
        agent=writer
    )
    crew = Crew(agents=[collector, analyst, writer],
                tasks=[collect_task, analyze_task, report_task],
                process=Process.sequential)
    return crew.kickoff(inputs={"filepath": filepath, "question": question})

# result = analyze_data("sales.csv", "What are the top performing months?")
```

---

### App 5: Email Assistant → DSPy-Optimized Email Classifier & Responder

**Current state:** A basic email responder using raw prompts.

**Improvements:**
1. Use DSPy signatures for classification and response generation
2. Add automatic prompt optimization
3. Add confidence scores
4. Add priority tagging

**Upgrade code:**
```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class EmailClassifier(dspy.Signature):
    \"\"\"Classify an email and determine its priority.\"\"\"
    email_subject: str = dspy.InputField()
    email_body: str = dspy.InputField()
    category: str = dspy.OutputField(desc="One of: support, sales, spam, internal, other")
    priority: str = dspy.OutputField(desc="One of: high, medium, low")
    requires_response: bool = dspy.OutputField(desc="True if email needs a response")

class EmailResponder(dspy.Signature):
    \"\"\"Write a professional email response.\"\"\"
    email_subject: str = dspy.InputField()
    email_body: str = dspy.InputField()
    category: str = dspy.InputField()
    response: str = dspy.OutputField(desc="Professional email response, 2-3 paragraphs")

class EmailPipeline(dspy.Module):
    def __init__(self):
        self.classify = dspy.Predict(EmailClassifier)
        self.respond = dspy.ChainOfThought(EmailResponder)

    def forward(self, subject: str, body: str):
        classification = self.classify(email_subject=subject, email_body=body)
        response = None
        if classification.requires_response:
            response = self.respond(
                email_subject=subject,
                email_body=body,
                category=classification.category
            )
        return dspy.Prediction(
            category=classification.category,
            priority=classification.priority,
            response=response.response if response else "No response needed"
        )

pipeline = EmailPipeline()

# result = pipeline(
#     subject="Urgent: Server down",
#     body="Our production server has been down for 30 minutes. Please help!"
# )
# print(f"Category: {result.category}, Priority: {result.priority}")
# print(f"Response: {result.response}")
```

---

### App 6: Search Assistant → LlamaIndex Knowledge Graph QA

**Current state:** A basic keyword search over documents.

**Improvements:**
1. Use LlamaIndex to build a knowledge graph index
2. Add entity extraction
3. Support multi-hop reasoning queries
4. Add source tracking

**Upgrade code:**
```python
from llama_index.core import KnowledgeGraphIndex, SimpleDirectoryReader, Settings
from llama_index.core.graph_stores import SimpleGraphStore
from llama_index.core import StorageContext
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

Settings.llm = OpenAI(model="gpt-4o-mini")
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

def build_kg_search(docs_dir: str):
    documents = SimpleDirectoryReader(docs_dir).load_data()

    graph_store = SimpleGraphStore()
    storage_context = StorageContext.from_defaults(graph_store=graph_store)

    index = KnowledgeGraphIndex.from_documents(
        documents,
        storage_context=storage_context,
        max_triplets_per_chunk=5,
        include_embeddings=True,
    )

    query_engine = index.as_query_engine(
        include_text=True,
        response_mode="tree_summarize",
        embedding_mode="hybrid",
        similarity_top_k=5,
    )
    return query_engine

# engine = build_kg_search("./docs")
# response = engine.query("How are LangChain and LlamaIndex related?")
# print(response)
# print("Sources:", [n.node.get_content()[:100] for n in response.source_nodes])
```

---
""")

# ─────────────────────────────────────────────
# PART 3 – 12 NEW APP BLUEPRINTS
# ─────────────────────────────────────────────
sections.append("""## Part 3 – 12 New App Blueprints

Full architectural blueprints for 12 new AI-powered applications.

---

### Blueprint 1: AI Research Assistant

**Purpose:** Automate research by searching the web, summarizing sources, and generating reports.

**Stack:** LangGraph + Tavily Search + LangChain

**Architecture:**
```
User Query → [Search Agent] → [Summary Agent] → [Report Writer] → Markdown Report
```

**Key components:**
- `TavilySearchResults` tool for web search
- LangGraph for multi-step workflow
- `MarkdownExporter` for final output

**Skeleton code:**
```python
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

search = TavilySearchResults(max_results=5)
llm = ChatOpenAI(model="gpt-4o-mini")

research_agent = create_react_agent(llm, tools=[search])

def research(query: str) -> str:
    result = research_agent.invoke({
        "messages": [{"role": "user", "content": f"Research this topic and write a summary: {query}"}]
    })
    return result["messages"][-1].content

# report = research("Latest advances in quantum computing 2024")
```

**Extensions:**
- Add PDF export using `reportlab`
- Add citation management
- Add multi-query synthesis

---

### Blueprint 2: Autonomous Code Reviewer

**Purpose:** Automatically review PRs and suggest improvements.

**Stack:** LangGraph + GitHub API + DSPy

**Architecture:**
```
PR Diff → [Code Parser] → [Security Checker] → [Style Checker] → [Review Writer]
```

**Skeleton code:**
```python
import dspy
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class CodeReview(dspy.Signature):
    \"\"\"Review code changes and provide constructive feedback.\"\"\"
    code_diff: str = dspy.InputField(desc="Git diff of the code change")
    review: str = dspy.OutputField(desc="Detailed code review with specific suggestions")
    severity: str = dspy.OutputField(desc="One of: critical, major, minor, cosmetic")
    approved: bool = dspy.OutputField(desc="True if code is ready to merge")

reviewer = dspy.ChainOfThought(CodeReview)

def review_pr(diff: str) -> dict:
    result = reviewer(code_diff=diff)
    return {
        "review": result.review,
        "severity": result.severity,
        "approved": result.approved
    }
```

---

### Blueprint 3: Personal Finance AI

**Purpose:** Analyze spending, categorize transactions, and give financial advice.

**Stack:** LlamaIndex + Pandas + LangChain

**Architecture:**
```
Bank CSV → [Transaction Parser] → [Categorizer] → [Analyzer] → [Advisor Agent]
```

**Skeleton code:**
```python
import pandas as pd
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser

llm = ChatOpenAI(model="gpt-4o-mini")

def categorize_transaction(description: str) -> dict:
    prompt = ChatPromptTemplate.from_template(\"\"\"
Categorize this bank transaction. Return JSON with keys: category, subcategory, is_essential.
Categories: Food, Transport, Entertainment, Bills, Shopping, Health, Income, Other.

Transaction: {description}
JSON:\"\"\")
    chain = prompt | llm | JsonOutputParser()
    return chain.invoke({"description": description})

def analyze_spending(csv_path: str) -> str:
    df = pd.read_csv(csv_path)
    # Categorize each transaction
    df["category"] = df["description"].apply(
        lambda x: categorize_transaction(x).get("category", "Other")
    )
    summary = df.groupby("category")["amount"].sum().to_dict()

    advice_prompt = f"Given this monthly spending summary: {summary}\\nProvide 3 specific money-saving tips."
    return llm.invoke([{"role": "user", "content": advice_prompt}]).content
```

---

### Blueprint 4: AI Meeting Summarizer

**Purpose:** Transcribe and summarize meetings, extract action items, assign owners.

**Stack:** Whisper + LangChain + DSPy

**Architecture:**
```
Audio File → [Whisper Transcription] → [Speaker Diarization] → [Summarizer] → [Action Item Extractor]
```

**Skeleton code:**
```python
import whisper
import dspy

model = whisper.load_model("base")
lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class MeetingSummary(dspy.Signature):
    \"\"\"Summarize a meeting transcript and extract action items.\"\"\"
    transcript: str = dspy.InputField()
    summary: str = dspy.OutputField(desc="2-3 paragraph meeting summary")
    action_items: str = dspy.OutputField(desc="Bullet list of action items with owners")
    decisions: str = dspy.OutputField(desc="Key decisions made in the meeting")

summarizer = dspy.ChainOfThought(MeetingSummary)

def process_meeting(audio_path: str) -> dict:
    result = model.transcribe(audio_path)
    transcript = result["text"]
    summary = summarizer(transcript=transcript)
    return {
        "transcript": transcript,
        "summary": summary.summary,
        "action_items": summary.action_items,
        "decisions": summary.decisions
    }
```

---

### Blueprint 5: AI Customer Support Bot

**Purpose:** Handle customer inquiries with knowledge base lookup and escalation.

**Stack:** Haystack + LangGraph + FastAPI

**Architecture:**
```
Customer Message → [Intent Classifier] → [KB Search] → [Response Generator] → [Escalation Check]
```

**Skeleton code:**
```python
from fastapi import FastAPI
from pydantic import BaseModel
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator

app = FastAPI()
store = InMemoryDocumentStore()

# Load KB documents
kb_docs = [
    Document(content="Return policy: Items can be returned within 30 days with receipt."),
    Document(content="Shipping: Free shipping on orders over $50. Standard delivery 3-5 days."),
    Document(content="Contact: support@example.com or call 1-800-HELP"),
]
store.write_documents(kb_docs)

prompt_template = \"\"\"
You are a helpful customer support agent. Use the context to answer the question.
If you cannot answer, say "I'll escalate this to a human agent."

Context: {% for doc in documents %}{{ doc.content }} {% endfor %}
Question: {{ question }}
Answer:\"\"\".strip()

pipeline = Pipeline()
pipeline.add_component("retriever", InMemoryBM25Retriever(document_store=store))
pipeline.add_component("prompt", PromptBuilder(template=prompt_template))
pipeline.add_component("llm", OpenAIGenerator(model="gpt-4o-mini"))
pipeline.connect("retriever", "prompt.documents")
pipeline.connect("prompt", "llm")

class Query(BaseModel):
    message: str

@app.post("/support")
def support(query: Query):
    result = pipeline.run({
        "retriever": {"query": query.message},
        "prompt": {"question": query.message}
    })
    response = result["llm"]["replies"][0]
    needs_escalation = "escalate" in response.lower()
    return {"response": response, "escalate": needs_escalation}
```

---

### Blueprint 6: AI Content Calendar

**Purpose:** Plan and generate social media content for a month.

**Stack:** CrewAI + LangChain + Pydantic

**Architecture:**
```
Brand Brief → [Strategist Agent] → [Content Planner] → [Writer Agent] → [Editor Agent] → Calendar
```

**Skeleton code:**
```python
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI
from pydantic import BaseModel
from typing import List

llm = ChatOpenAI(model="gpt-4o-mini")

class ContentPost(BaseModel):
    date: str
    platform: str
    content: str
    hashtags: List[str]

strategist = Agent(role="Content Strategist",
    goal="Create a monthly content strategy",
    backstory="Expert in social media strategy and brand voice.",
    llm=llm, verbose=False)

writer = Agent(role="Content Writer",
    goal="Write engaging social media posts",
    backstory="Creative copywriter with 10 years experience.",
    llm=llm, verbose=False)

def generate_calendar(brand: str, audience: str, month: str) -> str:
    strategy_task = Task(
        description=f"Create a content strategy for {brand} targeting {audience} for {month}.",
        expected_output="A content strategy with 4 weekly themes.",
        agent=strategist
    )
    write_task = Task(
        description="Write 12 social media posts (3 per week) following the strategy.",
        expected_output="12 complete posts with dates, platforms, and hashtags.",
        agent=writer
    )
    crew = Crew(agents=[strategist, writer], tasks=[strategy_task, write_task],
                process=Process.sequential)
    return crew.kickoff(inputs={"brand": brand, "audience": audience, "month": month})
```

---

### Blueprint 7: AI Legal Document Analyzer

**Purpose:** Extract clauses, identify risks, and summarize legal documents.

**Stack:** LlamaIndex + DSPy + LangChain

**Architecture:**
```
PDF/DOCX → [Document Parser] → [Clause Extractor] → [Risk Analyzer] → [Summary Generator]
```

**Skeleton code:**
```python
import dspy
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

Settings.llm = OpenAI(model="gpt-4o-mini")
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

class ClauseExtractor(dspy.Signature):
    \"\"\"Extract important clauses from a legal document excerpt.\"\"\"
    text: str = dspy.InputField()
    clauses: str = dspy.OutputField(desc="Bullet list of important clauses")
    risks: str = dspy.OutputField(desc="Potential risks or red flags")
    plain_summary: str = dspy.OutputField(desc="Plain English summary")

extractor = dspy.ChainOfThought(ClauseExtractor)

def analyze_document(docs_dir: str, query: str) -> dict:
    docs = SimpleDirectoryReader(docs_dir).load_data()
    index = VectorStoreIndex.from_documents(docs)
    engine = index.as_query_engine(similarity_top_k=5)

    relevant_text = str(engine.query(query))
    analysis = extractor(text=relevant_text)
    return {
        "clauses": analysis.clauses,
        "risks": analysis.risks,
        "summary": analysis.plain_summary
    }
```

---

### Blueprint 8: AI Tutoring System

**Purpose:** Personalized tutoring that adapts to student knowledge level.

**Stack:** LangGraph + LangChain + SQLite

**Architecture:**
```
Student Input → [Knowledge Assessment] → [Lesson Generator] → [Quiz Generator] → [Progress Tracker]
```

**Skeleton code:**
```python
from typing import TypedDict, List
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
import sqlite3

llm = ChatOpenAI(model="gpt-4o-mini")

class TutorState(TypedDict):
    student_id: str
    topic: str
    skill_level: str
    lesson: str
    quiz_question: str
    student_answer: str
    is_correct: bool
    score: int

def assess_level(state: TutorState) -> TutorState:
    prompt = f"For a student learning {state['topic']}, what questions assess {state['skill_level']} level understanding? Give one question."
    response = llm.invoke([HumanMessage(content=prompt)])
    return {**state, "quiz_question": response.content}

def generate_lesson(state: TutorState) -> TutorState:
    prompt = f"Teach {state['topic']} to a {state['skill_level']} level student in 3 bullet points. Be concise."
    response = llm.invoke([HumanMessage(content=prompt)])
    return {**state, "lesson": response.content}

def check_answer(state: TutorState) -> TutorState:
    prompt = f"Question: {state['quiz_question']}\\nStudent answer: {state['student_answer']}\\nIs this correct? Reply YES or NO and explain briefly."
    response = llm.invoke([HumanMessage(content=prompt)])
    is_correct = response.content.strip().upper().startswith("YES")
    score = state["score"] + (10 if is_correct else 0)
    return {**state, "is_correct": is_correct, "score": score}

graph = StateGraph(TutorState)
graph.add_node("lesson", generate_lesson)
graph.add_node("quiz", assess_level)
graph.add_node("check", check_answer)
graph.set_entry_point("lesson")
graph.add_edge("lesson", "quiz")
graph.add_edge("quiz", "check")
graph.add_edge("check", END)

tutor = graph.compile()
```

---

### Blueprint 9: AI Health & Wellness Coach

**Purpose:** Track health metrics and provide personalized wellness advice.

**Stack:** LangChain + SQLite + Pydantic

**Architecture:**
```
User Input → [Metric Tracker] → [Trend Analyzer] → [Recommendation Engine] → [Goal Setter]
```

**Skeleton code:**
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel
from typing import List
import sqlite3, datetime

class HealthMetric(BaseModel):
    date: str
    steps: int
    sleep_hours: float
    water_glasses: int
    mood: int  # 1-10

def save_metric(metric: HealthMetric):
    conn = sqlite3.connect("health.db")
    conn.execute(\"\"\"CREATE TABLE IF NOT EXISTS metrics
        (date TEXT, steps INT, sleep REAL, water INT, mood INT)\"\"\")
    conn.execute("INSERT INTO metrics VALUES (?,?,?,?,?)",
        (metric.date, metric.steps, metric.sleep_hours, metric.water_glasses, metric.mood))
    conn.commit()
    conn.close()

def get_weekly_summary() -> List[dict]:
    conn = sqlite3.connect("health.db")
    rows = conn.execute(\"\"\"SELECT * FROM metrics
        WHERE date >= date('now', '-7 days') ORDER BY date\"\"\").fetchall()
    conn.close()
    return [{"date": r[0], "steps": r[1], "sleep": r[2], "water": r[3], "mood": r[4]} for r in rows]

llm = ChatOpenAI(model="gpt-4o-mini")
coach_prompt = ChatPromptTemplate.from_template(\"\"\"
You are a health coach. Based on this week's data, provide 3 specific recommendations.
Data: {data}
Focus on: {focus_area}
Recommendations:\"\"\")

def get_recommendations(focus: str = "overall wellness") -> str:
    data = get_weekly_summary()
    chain = coach_prompt | llm
    return chain.invoke({"data": str(data), "focus_area": focus}).content
```

---

### Blueprint 10: AI News Aggregator & Analyst

**Purpose:** Collect news from multiple sources, cluster by topic, and generate briefings.

**Stack:** LangChain + Tavily + CrewAI

**Architecture:**
```
Topics List → [News Fetcher] → [Deduplicator] → [Cluster Agent] → [Briefing Writer]
```

**Skeleton code:**
```python
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from typing import List

search = TavilySearchResults(max_results=10)
llm = ChatOpenAI(model="gpt-4o-mini")

def fetch_news(topics: List[str]) -> List[dict]:
    all_articles = []
    for topic in topics:
        results = search.invoke(f"latest news {topic} today")
        all_articles.extend(results)
    return all_articles

briefing_prompt = ChatPromptTemplate.from_template(\"\"\"
You are a news analyst. Create a concise briefing from these articles.
Group by topic, highlight key developments, note conflicting reports.

Articles: {articles}

Daily Briefing:\"\"\")

def generate_briefing(topics: List[str]) -> str:
    articles = fetch_news(topics)
    chain = briefing_prompt | llm | StrOutputParser()
    return chain.invoke({"articles": str(articles[:15])})  # Limit to 15 articles

# briefing = generate_briefing(["AI", "technology", "climate"])
```

---

### Blueprint 11: AI Code Documentation Generator

**Purpose:** Automatically generate docstrings, README files, and API docs for codebases.

**Stack:** LangChain + AST + LlamaIndex

**Architecture:**
```
Python Files → [AST Parser] → [Function Extractor] → [Docstring Generator] → [README Writer]
```

**Skeleton code:**
```python
import ast
from pathlib import Path
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = ChatOpenAI(model="gpt-4o-mini")

def extract_functions(filepath: str) -> List[dict]:
    with open(filepath) as f:
        tree = ast.parse(f.read())
    functions = []
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            functions.append({
                "name": node.name,
                "args": [a.arg for a in node.args.args],
                "body": ast.unparse(node)
            })
    return functions

docstring_prompt = ChatPromptTemplate.from_template(\"\"\"
Generate a Google-style Python docstring for this function.
Function: {function_code}
Return ONLY the docstring text (no quotes).\"\"\")

def generate_docstring(func_code: str) -> str:
    chain = docstring_prompt | llm | StrOutputParser()
    return chain.invoke({"function_code": func_code})

def document_file(filepath: str) -> str:
    functions = extract_functions(filepath)
    documented = []
    for func in functions:
        docstring = generate_docstring(func["body"])
        documented.append(f"### `{func['name']}({', '.join(func['args'])})`\\n\\n{docstring}")
    return "\\n\\n".join(documented)

# docs = document_file("my_module.py")
```

**Note:** Add `from typing import List` import for the `List` type hint.

---

### Blueprint 12: AI Competitive Intelligence Tool

**Purpose:** Monitor competitors, analyze their moves, and generate strategic reports.

**Stack:** CrewAI + Tavily + LangGraph

**Architecture:**
```
Competitor List → [Web Scraper Agent] → [Analyst Agent] → [Strategist Agent] → [Report]
```

**Skeleton code:**
```python
from crewai import Agent, Task, Crew, Process
from crewai.tools import tool
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_openai import ChatOpenAI
from typing import List

llm = ChatOpenAI(model="gpt-4o-mini")
search_tool = TavilySearchResults(max_results=5)

@tool("Competitor Research")
def research_competitor(company: str) -> str:
    \"\"\"Research a competitor's recent activities and news.\"\"\"
    results = search_tool.invoke(f"{company} news product launch strategy 2024 2025")
    return str(results[:3])

scout = Agent(role="Intelligence Scout",
    goal="Gather information about competitors",
    backstory="Expert at finding business intelligence online.",
    tools=[research_competitor], llm=llm, verbose=False)

analyst = Agent(role="Business Analyst",
    goal="Analyze competitor strategies and identify threats/opportunities",
    backstory="MBA with 10 years of competitive analysis experience.",
    llm=llm, verbose=False)

def analyze_competitors(competitors: List[str], your_company: str) -> str:
    gather = Task(
        description=f"Research these competitors: {', '.join(competitors)}. Find recent news and product launches.",
        expected_output="Detailed findings for each competitor.",
        agent=scout
    )
    analyze = Task(
        description=f"Analyze the findings and identify threats and opportunities for {your_company}.",
        expected_output="Strategic analysis with SWOT insights.",
        agent=analyst
    )
    crew = Crew(agents=[scout, analyst], tasks=[gather, analyze], process=Process.sequential)
    return crew.kickoff(inputs={"competitors": str(competitors), "company": your_company})
```

---
""")

# ─────────────────────────────────────────────
# PART 4 – FREE & PAID RESOURCES
# ─────────────────────────────────────────────
sections.append("""## Part 4 – Free & Paid Learning Resources

### Free Resources

#### Official Documentation
| Library | Documentation URL |
|---------|------------------|
| LangChain | https://python.langchain.com/docs/introduction/ |
| LangGraph | https://langchain-ai.github.io/langgraph/ |
| CrewAI | https://docs.crewai.com/ |
| AutoGen | https://microsoft.github.io/autogen/ |
| LlamaIndex | https://docs.llamaindex.ai/ |
| Haystack | https://docs.haystack.deepset.ai/ |
| Semantic Kernel | https://learn.microsoft.com/en-us/semantic-kernel/ |
| DSPy | https://dspy.ai/ |
| MCP | https://modelcontextprotocol.io/ |
| ACP | https://agentcommunicationprotocol.dev/ |

#### Free Courses & Tutorials
- **DeepLearning.AI Short Courses** (free): https://learn.deeplearning.ai/
  - LangChain for LLM Application Development
  - Building Systems with the ChatGPT API
  - LangGraph: Build Agentic AI
  - Multi AI Agent Systems with CrewAI

- **LangChain Academy** (free): https://academy.langchain.com/
  - Introduction to LangGraph
  - Building RAG Applications

- **Hugging Face Learn** (free): https://huggingface.co/learn
  - NLP Course
  - Deep RL Course
  - Audio ML Course

- **Fast.ai** (free): https://www.fast.ai/
  - Practical Deep Learning for Coders

- **YouTube Channels:**
  - **AI Jason** – LangChain, LangGraph tutorials
  - **Sam Witteveen** – LLM application development
  - **1littlecoder** – Practical AI implementations
  - **Andrej Karpathy** – Deep learning fundamentals

#### GitHub Repositories to Study
```bash
# LangChain templates and examples
git clone https://github.com/langchain-ai/langchain

# LangGraph examples
git clone https://github.com/langchain-ai/langgraph-example

# CrewAI examples
git clone https://github.com/joaomdmoura/crewai-examples

# AutoGen examples
git clone https://github.com/microsoft/autogen

# DSPy examples
git clone https://github.com/stanfordnlp/dspy
```

#### Free API Access
- **OpenAI**: $5 free credit for new accounts
- **Anthropic Claude**: Free tier with rate limits
- **Google Gemini**: Free tier via Google AI Studio
- **Groq**: Free tier with fast inference (LLaMA, Mixtral)
- **Together AI**: $25 free credit
- **Hugging Face Inference API**: Free for many models

---

### Paid Resources

#### Premium Courses
| Course | Platform | Price | Rating |
|--------|----------|-------|--------|
| LangChain & Vector Databases in Production | Activeloop | $299 | ⭐⭐⭐⭐⭐ |
| Building LLM Apps with LangChain | Udemy | $15-30 | ⭐⭐⭐⭐ |
| AI Engineering Bootcamp | Maven | $1500 | ⭐⭐⭐⭐⭐ |
| Generative AI Fundamentals | Databricks Academy | $200 | ⭐⭐⭐⭐ |
| LLMOps | Full Stack LLM | $500 | ⭐⭐⭐⭐⭐ |

#### Books
- **"Building LLM Apps"** by Valentina Alto (Packt, ~$35)
- **"Developing Apps with GPT-4 and ChatGPT"** by O'Reilly (~$50)
- **"Hands-On Large Language Models"** by Jay Alammar (O'Reilly, ~$60)
- **"AI Engineering"** by Chip Huyen (O'Reilly, ~$60)

#### Certifications
- **AWS Certified Machine Learning Specialty** (~$300)
- **Google Professional ML Engineer** (~$200)
- **Microsoft Azure AI Engineer Associate** (~$165)
- **Databricks Generative AI Engineer Associate** (~$200)

#### Tools & Platforms (Paid Tiers)
| Tool | Purpose | Cost |
|------|---------|------|
| LangSmith | LLM observability & debugging | $39/mo |
| Weights & Biases | ML experiment tracking | $50/mo |
| Pinecone | Managed vector database | $70/mo |
| Weaviate Cloud | Vector database | Custom |
| Modal | Serverless AI compute | Pay per use |
| Replicate | Model hosting | Pay per use |

---

### Community Resources
- **Discord servers:**
  - LangChain Discord: https://discord.gg/langchain
  - Hugging Face Discord: https://discord.gg/huggingface
  - AI Engineers Discord: https://discord.gg/ai-engineers

- **Forums & Communities:**
  - r/LangChain on Reddit
  - LlamaIndex community forum
  - Hacker News (search: LLM, RAG, agents)

---
""")

# ─────────────────────────────────────────────
# PART 5 – 10 COMPLETE CODE RECIPES
# ─────────────────────────────────────────────
sections.append("""## Part 5 – 10 Complete Code Recipes

Ready-to-run Python scripts. Each recipe is self-contained and runnable.

---

### Recipe 1: Streaming Chatbot with Conversation History

**Requirements:** `pip install langchain-openai langchain-core`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 1: Streaming chatbot with persistent conversation history.
Usage: python recipe_01_chatbot.py
\"\"\"
import os
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser

def create_chatbot(model: str = "gpt-4o-mini", persona: str = "helpful assistant"):
    llm = ChatOpenAI(model=model, streaming=True)
    prompt = ChatPromptTemplate.from_messages([
        ("system", f"You are a {persona}. Be concise and helpful."),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}")
    ])
    chain = prompt | llm | StrOutputParser()
    return chain

def run_chatbot():
    chain = create_chatbot(persona="friendly Python tutor")
    history = []
    print("Python Tutor Chat (type 'exit' to quit)\\n")

    while True:
        user_input = input("You: ").strip()
        if not user_input or user_input.lower() in ("exit", "quit"):
            print("Goodbye!")
            break

        print("Tutor: ", end="", flush=True)
        response = ""

        for chunk in chain.stream({"input": user_input, "history": history}):
            print(chunk, end="", flush=True)
            response += chunk
        print()

        history.append(HumanMessage(content=user_input))
        history.append(AIMessage(content=response))

        # Keep last 10 exchanges to avoid token limit
        if len(history) > 20:
            history = history[-20:]

if __name__ == "__main__":
    run_chatbot()
```

---

### Recipe 2: RAG System with ChromaDB

**Requirements:** `pip install langchain-openai langchain-community chromadb`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 2: Complete RAG system with ChromaDB vector store.
Usage: python recipe_02_rag.py
\"\"\"
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_core.documents import Document

# Sample documents (replace with real docs)
SAMPLE_DOCS = [
    Document(page_content="Python is a high-level programming language known for its simplicity and readability.", metadata={"source": "python_intro.txt"}),
    Document(page_content="Python was created by Guido van Rossum and first released in 1991.", metadata={"source": "python_history.txt"}),
    Document(page_content="Python supports multiple programming paradigms including procedural, OOP, and functional.", metadata={"source": "python_paradigms.txt"}),
    Document(page_content="Popular Python libraries include NumPy, Pandas, TensorFlow, and PyTorch for data science.", metadata={"source": "python_libs.txt"}),
    Document(page_content="Python is widely used in web development with frameworks like Django and FastAPI.", metadata={"source": "python_web.txt"}),
]

def build_rag_chain():
    # Split documents
    splitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=20)
    chunks = splitter.split_documents(SAMPLE_DOCS)

    # Create vector store
    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    vectorstore = Chroma.from_documents(chunks, embeddings, persist_directory="./chroma_db")
    retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

    # Build chain
    prompt = ChatPromptTemplate.from_template(\"\"\"
Answer the question based only on the following context:
{context}

Question: {question}
Answer (cite the source when possible):\"\"\")

    llm = ChatOpenAI(model="gpt-4o-mini")

    chain = (
        {"context": retriever | format_docs, "question": RunnablePassthrough()}
        | prompt
        | llm
        | StrOutputParser()
    )
    return chain

def format_docs(docs):
    return "\\n\\n".join(f"[{d.metadata.get('source', '?')}] {d.page_content}" for d in docs)

def main():
    print("Building RAG system...")
    chain = build_rag_chain()

    questions = [
        "Who created Python?",
        "What is Python used for in web development?",
        "What data science libraries does Python have?",
    ]

    for q in questions:
        print(f"\\nQ: {q}")
        answer = chain.invoke(q)
        print(f"A: {answer}")

if __name__ == "__main__":
    main()
```

---

### Recipe 3: LangGraph ReAct Agent with Tools

**Requirements:** `pip install langgraph langchain-openai`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 3: ReAct agent with custom tools using LangGraph.
Usage: python recipe_03_react_agent.py
\"\"\"
import math
import json
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent

@tool
def calculator(expression: str) -> str:
    \"\"\"Evaluate a mathematical expression. Example: '2 + 2' or 'math.sqrt(16)'.\"\"\"
    try:
        # Safe eval with only math functions
        allowed = {name: getattr(math, name) for name in dir(math) if not name.startswith("_")}
        result = eval(expression, {"__builtins__": {}}, allowed)
        return str(result)
    except Exception as e:
        return f"Error: {e}"

@tool
def word_counter(text: str) -> str:
    \"\"\"Count words, characters, and sentences in text.\"\"\"
    words = len(text.split())
    chars = len(text)
    sentences = text.count(".") + text.count("!") + text.count("?")
    return json.dumps({"words": words, "characters": chars, "sentences": max(1, sentences)})

@tool
def unit_converter(value: float, from_unit: str, to_unit: str) -> str:
    \"\"\"Convert between common units. Supports: km/miles, kg/lbs, celsius/fahrenheit.\"\"\"
    conversions = {
        ("km", "miles"): lambda x: x * 0.621371,
        ("miles", "km"): lambda x: x * 1.60934,
        ("kg", "lbs"): lambda x: x * 2.20462,
        ("lbs", "kg"): lambda x: x / 2.20462,
        ("celsius", "fahrenheit"): lambda x: x * 9/5 + 32,
        ("fahrenheit", "celsius"): lambda x: (x - 32) * 5/9,
    }
    key = (from_unit.lower(), to_unit.lower())
    if key in conversions:
        result = conversions[key](value)
        return f"{value} {from_unit} = {result:.4f} {to_unit}"
    return f"Conversion from {from_unit} to {to_unit} not supported."

def main():
    llm = ChatOpenAI(model="gpt-4o-mini")
    tools = [calculator, word_counter, unit_converter]
    agent = create_react_agent(llm, tools)

    queries = [
        "What is the square root of 144, and what is 15.5 km in miles?",
        "Count the words in this text: 'The quick brown fox jumps over the lazy dog.' Then calculate 7 factorial.",
        "Convert 100 celsius to fahrenheit and 50 kg to lbs.",
    ]

    for query in queries:
        print(f"\\nQuery: {query}")
        result = agent.invoke({"messages": [{"role": "user", "content": query}]})
        print(f"Answer: {result['messages'][-1].content}")

if __name__ == "__main__":
    main()
```

---

### Recipe 4: Multi-Agent CrewAI Blog Writer

**Requirements:** `pip install crewai langchain-openai`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 4: Multi-agent blog writing system with CrewAI.
Usage: python recipe_04_crew_writer.py
\"\"\"
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

def create_blog_crew(topic: str, audience: str = "developers") -> str:
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.7)

    researcher = Agent(
        role="Research Specialist",
        goal=f"Research {topic} thoroughly",
        backstory="Expert researcher with deep knowledge of technology trends.",
        llm=llm,
        verbose=False
    )

    writer = Agent(
        role="Technical Writer",
        goal=f"Write an engaging blog post about {topic}",
        backstory="Experienced technical writer who makes complex topics accessible.",
        llm=llm,
        verbose=False
    )

    editor = Agent(
        role="Senior Editor",
        goal="Polish the blog post for clarity and engagement",
        backstory="Editor with 15 years of experience in tech publishing.",
        llm=llm,
        verbose=False
    )

    research_task = Task(
        description=f"Research {topic}. Find 5 key facts, 2 use cases, and current trends. Target audience: {audience}.",
        expected_output="A structured research brief with facts, use cases, and trends.",
        agent=researcher
    )

    write_task = Task(
        description=f"Write a 400-word blog post about {topic} for {audience}. Include intro, 3 sections, and conclusion.",
        expected_output="Complete blog post with title, intro, body sections, and conclusion.",
        agent=writer,
        context=[research_task]
    )

    edit_task = Task(
        description="Review and improve the blog post. Fix any errors, improve clarity, add engaging elements.",
        expected_output="Final polished blog post ready for publication.",
        agent=editor,
        context=[write_task]
    )

    crew = Crew(
        agents=[researcher, writer, editor],
        tasks=[research_task, write_task, edit_task],
        process=Process.sequential,
        verbose=False
    )

    result = crew.kickoff(inputs={"topic": topic, "audience": audience})
    return str(result)

def main():
    topics = [
        ("LangGraph for building AI agents", "Python developers"),
        ("Vector databases explained", "software engineers"),
    ]

    for topic, audience in topics:
        print(f"\\n{'='*60}")
        print(f"Writing blog post: {topic}")
        print("="*60)
        blog = create_blog_crew(topic, audience)
        print(blog[:500] + "..." if len(blog) > 500 else blog)

if __name__ == "__main__":
    main()
```

---

### Recipe 5: DSPy Text Classifier with Optimization

**Requirements:** `pip install dspy-ai`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 5: DSPy text classifier with automatic optimization.
Usage: python recipe_05_dspy_classifier.py
\"\"\"
import dspy
from dspy.teleprompt import LabeledFewShot

def setup_dspy():
    lm = dspy.LM("openai/gpt-4o-mini", temperature=0)
    dspy.configure(lm=lm)

class SentimentClassifier(dspy.Signature):
    \"\"\"Classify the sentiment of the given text.\"\"\"
    text: str = dspy.InputField(desc="Text to classify")
    sentiment: str = dspy.OutputField(desc="One of: positive, negative, neutral")
    confidence: str = dspy.OutputField(desc="One of: high, medium, low")
    reasoning: str = dspy.OutputField(desc="Brief explanation of the classification")

class TopicClassifier(dspy.Signature):
    \"\"\"Identify the main topic of the given text.\"\"\"
    text: str = dspy.InputField()
    topic: str = dspy.OutputField(desc="One of: technology, sports, politics, entertainment, science, business, other")
    subtopic: str = dspy.OutputField(desc="More specific topic within the main category")

class TextAnalysisPipeline(dspy.Module):
    def __init__(self):
        self.sentiment = dspy.ChainOfThought(SentimentClassifier)
        self.topic = dspy.Predict(TopicClassifier)

    def forward(self, text: str) -> dspy.Prediction:
        sentiment_result = self.sentiment(text=text)
        topic_result = self.topic(text=text)
        return dspy.Prediction(
            text=text,
            sentiment=sentiment_result.sentiment,
            confidence=sentiment_result.confidence,
            reasoning=sentiment_result.reasoning,
            topic=topic_result.topic,
            subtopic=topic_result.subtopic
        )

def main():
    setup_dspy()
    pipeline = TextAnalysisPipeline()

    test_texts = [
        "The new iPhone 16 has incredible camera features and battery life. I love it!",
        "The stock market crashed today due to rising inflation concerns.",
        "The team won the championship after a thrilling overtime victory.",
        "Scientists discovered a new exoplanet that might support life.",
        "The weather today was cloudy with a chance of rain.",
    ]

    print("Text Analysis Results")
    print("=" * 60)

    for text in test_texts:
        result = pipeline(text=text)
        print(f"\\nText: {text[:60]}...")
        print(f"  Sentiment: {result.sentiment} ({result.confidence} confidence)")
        print(f"  Topic: {result.topic} > {result.subtopic}")
        print(f"  Reasoning: {result.reasoning[:80]}...")

if __name__ == "__main__":
    main()
```

---

### Recipe 6: LlamaIndex Document Chat System

**Requirements:** `pip install llama-index llama-index-llms-openai llama-index-embeddings-openai`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 6: Chat with your documents using LlamaIndex.
Usage: python recipe_06_doc_chat.py
\"\"\"
import os
from llama_index.core import VectorStoreIndex, Document, Settings, StorageContext
from llama_index.core import load_index_from_storage
from llama_index.core.memory import ChatMemoryBuffer
from llama_index.core.chat_engine import CondensePlusContextChatEngine
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0.1)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

PERSIST_DIR = "./doc_index"

SAMPLE_DOCUMENTS = [
    Document(text=\"\"\"
LangChain is a framework for developing applications powered by language models.
It provides tools for chaining LLM calls, managing prompts, and integrating with
external data sources. Key features include chains, agents, memory, and retrievers.
The framework supports dozens of LLM providers and vector databases.
    \"\"\", metadata={"title": "LangChain Overview", "category": "frameworks"}),

    Document(text=\"\"\"
LangGraph extends LangChain with graph-based workflows for complex agents.
It allows you to build stateful agents with conditional branching, loops, and
human-in-the-loop interactions. Nodes represent processing steps, edges define
transitions. It supports streaming and checkpointing for long-running tasks.
    \"\"\", metadata={"title": "LangGraph Guide", "category": "frameworks"}),

    Document(text=\"\"\"
CrewAI is a framework for orchestrating multiple AI agents as a team.
Each agent has a role, goal, and backstory. Tasks are assigned to specific agents.
The crew can run tasks sequentially or in parallel. Agents can delegate to each other.
CrewAI is great for content creation, research, and analysis workflows.
    \"\"\", metadata={"title": "CrewAI Overview", "category": "frameworks"}),
]

def build_or_load_index():
    if os.path.exists(PERSIST_DIR):
        print("Loading existing index...")
        storage_context = StorageContext.from_defaults(persist_dir=PERSIST_DIR)
        return load_index_from_storage(storage_context)

    print("Building new index...")
    index = VectorStoreIndex.from_documents(SAMPLE_DOCUMENTS)
    index.storage_context.persist(persist_dir=PERSIST_DIR)
    return index

def create_chat_engine(index):
    memory = ChatMemoryBuffer.from_defaults(token_limit=3000)
    return index.as_chat_engine(
        chat_mode="condense_plus_context",
        memory=memory,
        system_prompt=(
            "You are an expert on AI frameworks. "
            "Answer questions based on the documents provided. "
            "Be specific and cite information from the documents."
        )
    )

def main():
    index = build_or_load_index()
    chat_engine = create_chat_engine(index)

    print("\\nDocument Chat System (type 'exit' to quit)")
    print("-" * 50)

    questions = [
        "What is LangChain and what are its key features?",
        "How does LangGraph differ from LangChain?",
        "Which framework would you use for content creation workflows?",
        "Can you compare all three frameworks?"
    ]

    for question in questions:
        print(f"\\nQ: {question}")
        response = chat_engine.chat(question)
        print(f"A: {response.response}")

if __name__ == "__main__":
    main()
```

---

### Recipe 7: MCP Server for Developer Tools

**Requirements:** `pip install mcp`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 7: MCP server exposing developer tools.
Usage: python recipe_07_mcp_server.py
Connect with Claude Desktop or any MCP client.
\"\"\"
import subprocess
import sys
import os
import ast
from mcp.server import FastMCP

mcp = FastMCP("Developer Tools")

@mcp.tool()
def run_python(code: str) -> str:
    \"\"\"Execute Python code and return the output.\"\"\"
    try:
        result = subprocess.run(
            [sys.executable, "-c", code],
            capture_output=True, text=True, timeout=15
        )
        output = result.stdout
        if result.stderr:
            output += f"\\nSTDERR: {result.stderr}"
        return output or "(no output)"
    except subprocess.TimeoutExpired:
        return "Error: Code execution timed out (15s limit)"
    except Exception as e:
        return f"Error: {e}"

@mcp.tool()
def analyze_python_code(code: str) -> str:
    \"\"\"Analyze Python code for issues and provide statistics.\"\"\"
    try:
        tree = ast.parse(code)
        functions = [n.name for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]
        classes = [n.name for n in ast.walk(tree) if isinstance(n, ast.ClassDef)]
        imports = [ast.unparse(n) for n in ast.walk(tree) if isinstance(n, (ast.Import, ast.ImportFrom))]
        lines = code.strip().split("\\n")
        return (
            f"Lines: {len(lines)}\\n"
            f"Functions: {functions}\\n"
            f"Classes: {classes}\\n"
            f"Imports: {imports}\\n"
            f"Syntax: Valid"
        )
    except SyntaxError as e:
        return f"Syntax Error: {e}"

@mcp.tool()
def list_directory(path: str = ".") -> str:
    \"\"\"List files and directories at the given path.\"\"\"
    try:
        items = os.listdir(path)
        files = [f for f in items if os.path.isfile(os.path.join(path, f))]
        dirs = [d for d in items if os.path.isdir(os.path.join(path, d))]
        return f"Directories: {sorted(dirs)}\\nFiles: {sorted(files)}"
    except Exception as e:
        return f"Error: {e}"

@mcp.resource("env://python-version")
def get_python_version() -> str:
    \"\"\"Get current Python version.\"\"\"
    return f"Python {sys.version}"

@mcp.resource("env://working-directory")
def get_working_directory() -> str:
    \"\"\"Get current working directory.\"\"\"
    return os.getcwd()

if __name__ == "__main__":
    print("Starting MCP server...")
    mcp.run()
```

---

### Recipe 8: Autonomous Web Research Agent

**Requirements:** `pip install langchain-openai langchain-community tavily-python`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 8: Autonomous research agent with web search.
Usage: python recipe_08_research_agent.py
Requires: TAVILY_API_KEY environment variable
\"\"\"
from langchain_openai import ChatOpenAI
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_core.tools import tool
from langchain_core.messages import HumanMessage
from langgraph.prebuilt import create_react_agent
import json

@tool
def format_as_report(findings: str, topic: str) -> str:
    \"\"\"Format research findings as a structured markdown report.\"\"\"
    return f\"\"\"# Research Report: {topic}

## Executive Summary
{findings[:300]}

## Detailed Findings
{findings}

## Sources
(Sources cited above from search results)

---
*Generated by AI Research Agent*
\"\"\"

def create_research_agent():
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)
    search = TavilySearchResults(max_results=8, include_raw_content=False)
    tools = [search, format_as_report]
    return create_react_agent(llm, tools)

def research_topic(topic: str, depth: str = "comprehensive") -> str:
    agent = create_research_agent()
    prompt = f\"\"\"Research the following topic and create a {depth} report:
Topic: {topic}

Instructions:
1. Search for the latest information on this topic
2. Look for multiple perspectives and sources
3. Identify key facts, trends, and important points
4. Format your findings as a structured report using the format_as_report tool
5. Include specific data and examples where available

Produce a thorough research report.\"\"\"

    result = agent.invoke({"messages": [HumanMessage(content=prompt)]})
    return result["messages"][-1].content

def main():
    topics = [
        "Latest developments in AI agents 2024-2025",
    ]

    for topic in topics:
        print(f"\\nResearching: {topic}")
        print("=" * 60)
        report = research_topic(topic)
        print(report[:1000])
        print("..." if len(report) > 1000 else "")

if __name__ == "__main__":
    main()
```

---

### Recipe 9: Haystack Production RAG Pipeline

**Requirements:** `pip install haystack-ai sentence-transformers`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 9: Production-ready RAG pipeline with Haystack.
Usage: python recipe_09_haystack_rag.py
\"\"\"
from haystack import Document, Pipeline
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.components.preprocessors import DocumentSplitter
from haystack.components.writers import DocumentWriter

KNOWLEDGE_BASE = [
    Document(content=\"\"\"
Retrieval-Augmented Generation (RAG) is a technique that enhances LLM responses
by retrieving relevant documents before generating answers. It reduces hallucinations
and allows LLMs to access up-to-date information beyond their training data.
Key components: document store, retriever, and generator.
    \"\"\", meta={"source": "rag_overview.txt", "category": "concepts"}),

    Document(content=\"\"\"
Vector databases store high-dimensional embeddings for semantic search.
Popular options include Chroma (local), Pinecone (managed), Weaviate (hybrid),
Qdrant (high-performance), and pgvector (PostgreSQL extension).
Choose based on: scale, latency requirements, and infrastructure.
    \"\"\", meta={"source": "vector_dbs.txt", "category": "infrastructure"}),

    Document(content=\"\"\"
Prompt engineering techniques include: few-shot prompting (examples in prompt),
chain-of-thought (step by step reasoning), ReAct (reasoning + acting), and
structured output (JSON/XML formatted responses). Always version your prompts.
    \"\"\", meta={"source": "prompting.txt", "category": "techniques"}),

    Document(content=\"\"\"
LLM evaluation metrics: RAGAS (RAG-specific), BLEU (n-gram overlap),
ROUGE (recall-oriented), BERTScore (semantic similarity), and human evaluation.
For RAG: measure faithfulness, answer relevancy, and context precision.
    \"\"\", meta={"source": "evaluation.txt", "category": "evaluation"}),
]

def build_indexing_pipeline(document_store):
    indexing = Pipeline()
    indexing.add_component("splitter", DocumentSplitter(split_by="sentence", split_length=5))
    indexing.add_component("writer", DocumentWriter(document_store=document_store))
    indexing.connect("splitter", "writer")
    return indexing

def build_rag_pipeline(document_store):
    prompt_template = \"\"\"
You are a knowledgeable AI assistant. Answer the question using the provided context.
Be accurate, concise, and cite the source document when relevant.

Context:
{% for doc in documents %}
[{{ doc.meta.source }}] {{ doc.content }}
{% endfor %}

Question: {{ question }}

Answer:\"\"\".strip()

    rag = Pipeline()
    rag.add_component("retriever", InMemoryBM25Retriever(document_store=document_store, top_k=3))
    rag.add_component("prompt_builder", PromptBuilder(template=prompt_template))
    rag.add_component("llm", OpenAIGenerator(model="gpt-4o-mini", generation_kwargs={"temperature": 0}))
    rag.connect("retriever", "prompt_builder.documents")
    rag.connect("prompt_builder", "llm")
    return rag

def main():
    # Setup
    store = InMemoryDocumentStore()
    indexing = build_indexing_pipeline(store)
    indexing.run({"splitter": {"documents": KNOWLEDGE_BASE}})
    print(f"Indexed {store.count_documents()} document chunks")

    rag = build_rag_pipeline(store)

    # Test queries
    queries = [
        "What is RAG and why is it useful?",
        "Which vector database should I choose for a high-performance application?",
        "How should I evaluate my RAG system?",
        "What prompting techniques are available?",
    ]

    print("\\nRAG Pipeline Q&A")
    print("=" * 60)

    for query in queries:
        result = rag.run({
            "retriever": {"query": query},
            "prompt_builder": {"question": query}
        })
        answer = result["llm"]["replies"][0]
        print(f"\\nQ: {query}")
        print(f"A: {answer}")

if __name__ == "__main__":
    main()
```

---

### Recipe 10: Complete LangGraph Multi-Agent System

**Requirements:** `pip install langgraph langchain-openai`

```python
#!/usr/bin/env python3
\"\"\"
Recipe 10: Complete multi-agent system with LangGraph.
Agents: Coordinator, Researcher, Writer, Critic.
Usage: python recipe_10_multi_agent.py
\"\"\"
from typing import TypedDict, List, Annotated
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage
import operator

class ProjectState(TypedDict):
    task: str
    research: str
    draft: str
    critique: str
    final_output: str
    revision_count: int
    approved: bool

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.3)
creative_llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.7)

def coordinator(state: ProjectState) -> ProjectState:
    \"\"\"Breaks down the task and initiates the workflow.\"\"\"
    response = llm.invoke([HumanMessage(content=
        f"Break down this task into research needs and writing goals: {state['task']}"
    )])
    return {**state, "research": f"Research plan: {response.content}"}

def researcher(state: ProjectState) -> ProjectState:
    \"\"\"Conducts research on the topic.\"\"\"
    response = llm.invoke([HumanMessage(content=
        f"Based on this plan, provide key facts and insights:\\n{state['research']}"
    )])
    return {**state, "research": response.content}

def writer(state: ProjectState) -> ProjectState:
    \"\"\"Writes the initial draft.\"\"\"
    prompt = f\"\"\"Write a high-quality piece based on:
Task: {state['task']}
Research: {state['research']}

{('Address this critique: ' + state['critique']) if state['critique'] else 'Write the initial version.'}

Produce a complete, polished output.\"\"\"
    response = creative_llm.invoke([HumanMessage(content=prompt)])
    return {**state, "draft": response.content, "revision_count": state["revision_count"] + 1}

def critic(state: ProjectState) -> ProjectState:
    \"\"\"Reviews the draft and provides feedback.\"\"\"
    prompt = f\"\"\"Review this draft critically:
{state['draft']}

Task was: {state['task']}

Is this draft: (a) ready to publish, or (b) needs revision?
If (b), provide specific, actionable feedback.
Start your response with APPROVED or NEEDS_REVISION.\"\"\"
    response = llm.invoke([HumanMessage(content=prompt)])
    critique = response.content
    approved = critique.strip().upper().startswith("APPROVED") or state["revision_count"] >= 3
    final = state["draft"] if approved else state.get("final_output", "")
    return {**state, "critique": critique, "approved": approved, "final_output": final}

def route_after_critic(state: ProjectState) -> str:
    if state["approved"]:
        return "done"
    return "revise"

# Build the graph
graph = StateGraph(ProjectState)
graph.add_node("coordinator", coordinator)
graph.add_node("researcher", researcher)
graph.add_node("writer", writer)
graph.add_node("critic", critic)

graph.set_entry_point("coordinator")
graph.add_edge("coordinator", "researcher")
graph.add_edge("researcher", "writer")
graph.add_edge("writer", "critic")
graph.add_conditional_edges(
    "critic",
    route_after_critic,
    {"revise": "writer", "done": END}
)

multi_agent = graph.compile()

def run_project(task: str) -> dict:
    initial_state = ProjectState(
        task=task,
        research="",
        draft="",
        critique="",
        final_output="",
        revision_count=0,
        approved=False
    )
    result = multi_agent.invoke(initial_state)
    return {
        "task": result["task"],
        "final_output": result["final_output"] or result["draft"],
        "revisions": result["revision_count"],
        "approved": result["approved"]
    }

def main():
    tasks = [
        "Write a 200-word explanation of why RAG is better than fine-tuning for most use cases.",
        "Create a quick-start guide for LangGraph in 5 bullet points.",
    ]

    for task in tasks:
        print(f"\\nTask: {task}")
        print("-" * 60)
        result = run_project(task)
        print(f"Revisions: {result['revisions']} | Approved: {result['approved']}")
        print(f"\\nOutput:\\n{result['final_output']}")
        print("=" * 60)

if __name__ == "__main__":
    main()
```

---
""")

# ─────────────────────────────────────────────
# FOOTER
# ─────────────────────────────────────────────
sections.append("""## Quick Reference: When to Use Which Library

| Use Case | Recommended Library |
|----------|-------------------|
| Simple chatbot | LangChain |
| Complex multi-step agent | LangGraph |
| Multi-agent team | CrewAI or AutoGen |
| RAG / document QA | LlamaIndex or LangChain |
| Enterprise search | Haystack |
| Code generation agent | AutoGen |
| Enterprise / Azure | Semantic Kernel |
| Auto-optimized pipelines | DSPy |
| Tool exposure for Claude | MCP |
| Agent interoperability | ACP |

---

## Environment Setup Cheatsheet

```bash
# Create virtual environment
python -m venv ai-env
source ai-env/bin/activate  # Unix
ai-env\\Scripts\\activate    # Windows

# Install all libraries
pip install langchain langchain-openai langchain-community
pip install langgraph
pip install crewai crewai-tools
pip install pyautogen
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai
pip install haystack-ai
pip install semantic-kernel
pip install dspy-ai
pip install mcp
pip install acp-sdk

# Set API keys
export OPENAI_API_KEY="sk-..."
export TAVILY_API_KEY="tvly-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## Troubleshooting Common Issues

### Issue: `RateLimitError` from OpenAI
```python
from langchain_openai import ChatOpenAI
from tenacity import retry, wait_exponential, stop_after_attempt

@retry(wait=wait_exponential(min=1, max=60), stop=stop_after_attempt(3))
def call_llm(prompt: str) -> str:
    llm = ChatOpenAI(model="gpt-4o-mini")
    return llm.invoke(prompt).content
```

### Issue: Vector store search returns irrelevant results
- Increase chunk overlap: `chunk_overlap=100` instead of `50`
- Use smaller chunk sizes: `chunk_size=300` instead of `1000`
- Switch to `text-embedding-3-large` for better embeddings
- Add metadata filtering for domain-specific content

### Issue: Agent loops indefinitely
```python
# Add iteration limit to LangGraph
from langgraph.graph import StateGraph

def should_stop(state):
    if state["iterations"] > 10:
        return "force_stop"
    return "continue"
```

### Issue: CrewAI agents give incomplete results
- Make task `expected_output` more specific
- Add `max_iter=5` to Agent constructor
- Use `Process.hierarchical` for complex workflows
- Add tools to agents for concrete actions

---

*Generated by build_guide.py | AI Libraries & Frameworks Complete Developer Guide*
*Last updated: 2025*
""")

# ─────────────────────────────────────────────
# WRITE FILE
# ─────────────────────────────────────────────
content = "\n".join(sections)

with open(TARGET, "w", encoding="utf-8") as f:
    f.write(content)

line_count = content.count("\n") + 1
print(f"✅ Generated: {TARGET}")
print(f"📄 Lines: {line_count}")
print(f"📦 Size: {len(content):,} bytes ({len(content)//1024} KB)")
