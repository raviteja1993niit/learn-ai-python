# Python AI / LLM Code Recipes

> **15 complete, runnable recipes** — each is self-contained, 50–100 lines, and ready to copy-paste.  
> GitHub Copilot free auth is used wherever an LLM call is required.

---

## GitHub Copilot Auth (reused in every LLM recipe)

```python
import subprocess
from openai import OpenAI

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)
```

---

## Recipe 1 — Streaming Chatbot with History

```python
# pip install openai
import subprocess
from openai import OpenAI
from collections import deque

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

class ConversationHistory:
    def __init__(self, system_prompt: str, max_turns: int = 10):
        self.system = {"role": "system", "content": system_prompt}
        self.turns: deque = deque(maxlen=max_turns * 2)  # user+assistant pairs

    def add(self, role: str, content: str):
        self.turns.append({"role": role, "content": content})

    def messages(self) -> list:
        return [self.system] + list(self.turns)


def stream_response(history: ConversationHistory, user_input: str) -> str:
    history.add("user", user_input)
    stream = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=history.messages(),
        stream=True,
    )
    full_reply = ""
    print("Assistant: ", end="", flush=True)
    for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        print(delta, end="", flush=True)
        full_reply += delta
    print()
    history.add("assistant", full_reply)
    return full_reply


def main():
    history = ConversationHistory(
        system_prompt="You are a concise Python tutor. Keep answers under 3 sentences.",
        max_turns=8,
    )
    print("Type 'quit' to exit.\n")
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in {"quit", "exit"}:
            break
        stream_response(history, user_input)


if __name__ == "__main__":
    main()
```

---

## Recipe 2 — Local RAG with FAISS (No API Needed)

```python
# pip install faiss-cpu sentence-transformers rank-bm25 numpy
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer
from rank_bm25 import BM25Okapi

DOCUMENTS = [
    "Python is a high-level, interpreted programming language known for its readability.",
    "LangChain is a framework for building applications powered by language models.",
    "FAISS is Facebook's library for efficient similarity search and clustering of dense vectors.",
    "RAG stands for Retrieval-Augmented Generation, combining retrieval with LLM generation.",
    "Sentence Transformers produce dense vector embeddings suitable for semantic search.",
    "BM25 is a classical probabilistic keyword-based ranking algorithm used in information retrieval.",
    "Hybrid search combines dense (semantic) and sparse (keyword) retrieval for better recall.",
    "Vector databases store embeddings and support approximate nearest-neighbour lookups.",
]

model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode(DOCUMENTS, convert_to_numpy=True).astype("float32")
faiss.normalize_L2(embeddings)

index = faiss.IndexFlatIP(embeddings.shape[1])
index.add(embeddings)

tokenized = [doc.lower().split() for doc in DOCUMENTS]
bm25 = BM25Okapi(tokenized)


def hybrid_search(query: str, top_k: int = 3, alpha: float = 0.5) -> list[dict]:
    q_emb = model.encode([query], convert_to_numpy=True).astype("float32")
    faiss.normalize_L2(q_emb)
    dense_scores, dense_ids = index.search(q_emb, len(DOCUMENTS))

    sparse_scores = bm25.get_scores(query.lower().split())
    sparse_scores = sparse_scores / (sparse_scores.max() + 1e-9)

    dense_norm = np.zeros(len(DOCUMENTS))
    for rank, idx in enumerate(dense_ids[0]):
        dense_norm[idx] = dense_scores[0][rank]

    combined = alpha * dense_norm + (1 - alpha) * sparse_scores
    top_ids = combined.argsort()[::-1][:top_k]
    return [{"doc": DOCUMENTS[i], "score": float(combined[i])} for i in top_ids]


if __name__ == "__main__":
    query = "What is semantic vector search?"
    results = hybrid_search(query)
    print(f"Query: {query}\n")
    for r in results:
        print(f"  [{r['score']:.3f}] {r['doc']}")
```

---

## Recipe 3 — LangChain Conversational RAG

```python
# pip install langchain langchain-community langchain-huggingface faiss-cpu sentence-transformers pypdf openai
import subprocess
from pathlib import Path
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

# Use a sample text file for demo — replace with your PDF path
sample_path = Path("sample_doc.txt")
if not sample_path.exists():
    sample_path.write_text("Python was created by Guido van Rossum. "
                           "LangChain enables LLM-powered apps. "
                           "RAG improves accuracy with retrieval.")

loader = TextLoader(str(sample_path))
docs = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=300, chunk_overlap=50)
chunks = splitter.split_documents(docs)

embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vector_store = FAISS.from_documents(chunks, embeddings)
retriever = vector_store.as_retriever(search_kwargs={"k": 3})

llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer using the context below.\n\nContext: {context}"),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])

qa_chain = create_stuff_documents_chain(llm, prompt)
rag_chain = create_retrieval_chain(retriever, qa_chain)

store: dict = {}
def get_session_history(session_id: str):
    if session_id not in store:
        store[session_id] = InMemoryChatMessageHistory()
    return store[session_id]

conversational_rag = RunnableWithMessageHistory(
    rag_chain, get_session_history,
    input_messages_key="input",
    history_messages_key="chat_history",
    output_messages_key="answer",
)

if __name__ == "__main__":
    cfg = {"configurable": {"session_id": "demo"}}
    r1 = conversational_rag.invoke({"input": "Who created Python?"}, config=cfg)
    print("A1:", r1["answer"])
    r2 = conversational_rag.invoke({"input": "What else did you mention about it?"}, config=cfg)
    print("A2:", r2["answer"])
```

---

## Recipe 4 — LangGraph ReAct Agent with 3 Tools

```python
# pip install langgraph langchain-openai langchain-core openai aiofiles
import subprocess, math, urllib.request
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.sqlite import SqliteSaver

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

@tool
def calculator(expression: str) -> str:
    """Evaluate a safe mathematical expression, e.g. '2 ** 10 + sqrt(16)'."""
    allowed = {k: getattr(math, k) for k in dir(math) if not k.startswith("_")}
    try:
        return str(eval(expression, {"__builtins__": {}}, allowed))
    except Exception as e:
        return f"Error: {e}"

@tool
def file_reader(path: str) -> str:
    """Read the first 500 characters of a local text file."""
    try:
        return open(path).read(500)
    except Exception as e:
        return f"Error: {e}"

@tool
def web_snippet(url: str) -> str:
    """Fetch the first 600 characters of a webpage as plain text."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        html = urllib.request.urlopen(req, timeout=5).read(4000).decode("utf-8", errors="ignore")
        import re
        text = re.sub(r"<[^>]+>", " ", html)
        return " ".join(text.split())[:600]
    except Exception as e:
        return f"Error: {e}"

with SqliteSaver.from_conn_string("agent_memory.db") as memory:
    agent = create_react_agent(llm, [calculator, file_reader, web_snippet], checkpointer=memory)
    cfg = {"configurable": {"thread_id": "thread-1"}}
    result = agent.invoke(
        {"messages": [("user", "What is sqrt(144) + 2^8? Also calculate pi * 7^2.")]},
        config=cfg,
    )
    print(result["messages"][-1].content)
```

---

## Recipe 5 — CrewAI Content Creation Crew

```python
# pip install crewai crewai-tools pydantic openai
import subprocess
from pydantic import BaseModel
from crewai import Agent, Task, Crew, Process
from crewai_tools import tool as crew_tool
from langchain_openai import ChatOpenAI

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
llm = ChatOpenAI(
    model="gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

@crew_tool("DuckDuckGo Search")
def ddg_search(query: str) -> str:
    """Search the web using DuckDuckGo Lite and return a short summary."""
    import urllib.parse, urllib.request, re
    url = f"https://lite.duckduckgo.com/lite/?q={urllib.parse.quote(query)}"
    html = urllib.request.urlopen(url, timeout=6).read(5000).decode("utf-8", errors="ignore")
    return re.sub(r"<[^>]+>", " ", html)[:800]

class ArticleOutput(BaseModel):
    title: str
    summary: str
    body: str
    editor_notes: str

researcher = Agent(role="Researcher", goal="Find key facts on the topic",
                   backstory="Expert internet researcher.", tools=[ddg_search], llm=llm, verbose=False)
writer = Agent(role="Writer", goal="Write a 200-word article",
               backstory="Clear technical writer.", llm=llm, verbose=False)
editor = Agent(role="Editor", goal="Polish and add editor notes",
               backstory="Senior content editor.", llm=llm, verbose=False)

TOPIC = "LangGraph for building stateful AI agents"

t1 = Task(description=f"Research: {TOPIC}. Return 5 bullet facts.", expected_output="5 bullet points", agent=researcher)
t2 = Task(description="Write a concise article using the research.", expected_output="Article text", agent=writer)
t3 = Task(description="Edit the article and add editor_notes field.",
          expected_output="JSON with title, summary, body, editor_notes",
          agent=editor, output_pydantic=ArticleOutput)

crew = Crew(agents=[researcher, writer, editor], tasks=[t1, t2, t3], process=Process.sequential, verbose=False)

if __name__ == "__main__":
    result = crew.kickoff()
    print(result.pydantic)
```

---

## Recipe 6 — AutoGen Code-Test-Fix Loop

```python
# pip install pyautogen openai
import subprocess, tempfile, os
from autogen import AssistantAgent, UserProxyAgent, config_list_from_json
from autogen.coding import LocalCommandLineCodeExecutor

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

llm_config = {
    "config_list": [{
        "model": "gpt-4o-mini",
        "api_key": token,
        "base_url": "https://models.inference.ai.azure.com",
    }],
    "temperature": 0,
}

work_dir = tempfile.mkdtemp(prefix="autogen_")
executor = LocalCommandLineCodeExecutor(work_dir=work_dir, timeout=30)

coder = AssistantAgent(
    name="Coder",
    system_message=(
        "You are an expert Python developer. Write code, run it, fix any errors. "
        "Always wrap code in ```python ... ``` blocks."
    ),
    llm_config=llm_config,
)

tester = UserProxyAgent(
    name="Tester",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=6,
    code_execution_config={"executor": executor},
    is_termination_msg=lambda m: "TERMINATE" in (m.get("content") or ""),
)

if __name__ == "__main__":
    task = (
        "Write a Python function `fibonacci(n)` that returns a list of the first n "
        "Fibonacci numbers. Then write a pytest test for it and run it. "
        "Fix any failures. When all tests pass, reply with TERMINATE."
    )
    tester.initiate_chat(coder, message=task)
```

---

## Recipe 7 — LlamaIndex SubQuestion Engine

```python
# pip install llama-index llama-index-llms-openai llama-index-embeddings-huggingface
import subprocess
from pathlib import Path
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.core.query_engine import SubQuestionQueryEngine
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.llms.openai import OpenAI as LlamaOpenAI
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

Settings.llm = LlamaOpenAI(
    model="gpt-4o-mini",
    api_base="https://models.inference.ai.azure.com",
    api_key=token,
)
Settings.embed_model = HuggingFaceEmbedding(model_name="all-MiniLM-L6-v2")

docs_dir = Path("llama_docs")
docs_dir.mkdir(exist_ok=True)
(docs_dir / "python.txt").write_text("Python was created by Guido van Rossum in 1991. It emphasises readability.")
(docs_dir / "langchain.txt").write_text("LangChain was founded in 2022. It provides chains and agents for LLM apps.")
(docs_dir / "faiss.txt").write_text("FAISS was developed by Facebook AI Research. It enables fast similarity search.")

sources = {
    "python": "python.txt",
    "langchain": "langchain.txt",
    "faiss": "faiss.txt",
}

tools = []
for name, filename in sources.items():
    docs = SimpleDirectoryReader(input_files=[str(docs_dir / filename)]).load_data()
    idx = VectorStoreIndex.from_documents(docs)
    tools.append(QueryEngineTool(
        query_engine=idx.as_query_engine(streaming=False),
        metadata=ToolMetadata(name=name, description=f"Information about {name}"),
    ))

engine = SubQuestionQueryEngine.from_defaults(query_engine_tools=tools, verbose=True)

if __name__ == "__main__":
    response = engine.query("Who created Python and when was LangChain founded?")
    print("\nFinal Answer:", response)
```

---

## Recipe 8 — Haystack Hybrid RAG Pipeline

```python
# pip install haystack-ai transformers torch sentence-transformers openai
import subprocess
from haystack import Document, Pipeline
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import (
    InMemoryBM25Retriever, InMemoryEmbeddingRetriever,
)
from haystack.components.joiners import DocumentJoiner
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.components.embedders import SentenceTransformersDocumentEmbedder, SentenceTransformersTextEmbedder
from haystack.components.builders import ChatPromptBuilder
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.dataclasses import ChatMessage

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

DOCS = [
    "Python supports multiple programming paradigms including procedural and object-oriented.",
    "LangChain integrates with many LLM providers and vector stores.",
    "FAISS supports both exact and approximate nearest-neighbour search.",
    "Haystack is an open-source NLP framework for building search and QA systems.",
    "Hybrid search combines BM25 keyword retrieval with dense semantic embeddings.",
]

store = InMemoryDocumentStore()
doc_embedder = SentenceTransformersDocumentEmbedder(model="all-MiniLM-L6-v2")
doc_embedder.warm_up()
docs_with_embs = doc_embedder.run(documents=[Document(content=d) for d in DOCS])["documents"]
store.write_documents(docs_with_embs)

text_embedder = SentenceTransformersTextEmbedder(model="all-MiniLM-L6-v2")
bm25 = InMemoryBM25Retriever(document_store=store, top_k=3)
emb_retriever = InMemoryEmbeddingRetriever(document_store=store, top_k=3)
joiner = DocumentJoiner()
ranker = TransformersSimilarityRanker(model="cross-encoder/ms-marco-MiniLM-L-6-v2", top_k=2)

template = [ChatMessage.from_user("Context: {{documents}}\n\nQuestion: {{query}}\n\nAnswer:")]
prompt_builder = ChatPromptBuilder(template=template)
generator = OpenAIChatGenerator(
    model="gpt-4o-mini",
    api_base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

pipe = Pipeline()
for name, comp in [("text_embedder", text_embedder), ("bm25", bm25),
                   ("emb_retriever", emb_retriever), ("joiner", joiner),
                   ("ranker", ranker), ("prompt_builder", prompt_builder), ("generator", generator)]:
    pipe.add_component(name, comp)

pipe.connect("text_embedder.embedding", "emb_retriever.query_embedding")
pipe.connect("bm25.documents", "joiner.documents")
pipe.connect("emb_retriever.documents", "joiner.documents")
pipe.connect("joiner.documents", "ranker.documents")
pipe.connect("ranker.documents", "prompt_builder.documents")
pipe.connect("prompt_builder.prompt", "generator.messages")

if __name__ == "__main__":
    query = "What is hybrid search?"
    result = pipe.run({"text_embedder": {"text": query}, "bm25": {"query": query},
                       "ranker": {"query": query}, "prompt_builder": {"query": query}})
    print(result["generator"]["replies"][0].content)
```

---

## Recipe 9 — DSPy Optimized Classifier

```python
# pip install dspy-ai openai
import subprocess, json
import dspy

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

lm = dspy.LM(
    model="openai/gpt-4o-mini",
    api_base="https://models.inference.ai.azure.com",
    api_key=token,
)
dspy.configure(lm=lm)

class SentimentSignature(dspy.Signature):
    """Classify the sentiment of the text as positive, negative, or neutral."""
    text: str = dspy.InputField()
    sentiment: str = dspy.OutputField(desc="positive | negative | neutral")

class SentimentClassifier(dspy.Module):
    def __init__(self):
        self.classify = dspy.Predict(SentimentSignature)

    def forward(self, text: str) -> dspy.Prediction:
        return self.classify(text=text)

trainset = [
    dspy.Example(text="I love this product!", sentiment="positive").with_inputs("text"),
    dspy.Example(text="Terrible experience, never again.", sentiment="negative").with_inputs("text"),
    dspy.Example(text="It was okay, nothing special.", sentiment="neutral").with_inputs("text"),
    dspy.Example(text="Absolutely fantastic service!", sentiment="positive").with_inputs("text"),
    dspy.Example(text="Very disappointed with the quality.", sentiment="negative").with_inputs("text"),
]

def accuracy_metric(example, pred, trace=None):
    return int(pred.sentiment.strip().lower() == example.sentiment.strip().lower())

optimizer = dspy.BootstrapFewShot(metric=accuracy_metric, max_bootstrapped_demos=3)
classifier = SentimentClassifier()
optimized = optimizer.compile(classifier, trainset=trainset)

eval_set = [
    dspy.Example(text="Best purchase I ever made!", sentiment="positive").with_inputs("text"),
    dspy.Example(text="Completely broken on arrival.", sentiment="negative").with_inputs("text"),
]

evaluator = dspy.Evaluate(devset=eval_set, metric=accuracy_metric, display_progress=False)
score = evaluator(optimized)
print(f"Accuracy: {score:.1%}")

optimized.save("optimized_classifier.json")
print("Saved to optimized_classifier.json")
```

---

## Recipe 10 — MCP Server + LangChain Client

```python
# pip install fastmcp langchain-mcp-adapters langchain-openai openai
# Run the server first: python recipe10_server.py
# Then run the client: python recipe10_client.py

# ── recipe10_server.py ───────────────────────────────────────────────────────
SERVER_CODE = '''
from fastmcp import FastMCP
import pathlib, ast

mcp = FastMCP("DevTools")

@mcp.tool()
def read_file(path: str) -> str:
    """Read a local file and return its contents (max 1000 chars)."""
    return pathlib.Path(path).read_text()[:1000]

@mcp.tool()
def write_file(path: str, content: str) -> str:
    """Write content to a local file."""
    pathlib.Path(path).write_text(content)
    return f"Written {len(content)} chars to {path}"

@mcp.tool()
def count_functions(code: str) -> dict:
    """Count the number of functions defined in a Python code string."""
    try:
        tree = ast.parse(code)
        n = sum(1 for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)))
        return {"function_count": n}
    except SyntaxError as e:
        return {"error": str(e)}

if __name__ == "__main__":
    mcp.run(transport="stdio")
'''

# ── recipe10_client.py ───────────────────────────────────────────────────────
CLIENT_CODE = '''
import subprocess, asyncio
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini",
                 base_url="https://models.inference.ai.azure.com", api_key=token)

async def main():
    async with MultiServerMCPClient({
        "devtools": {"command": "python", "args": ["recipe10_server.py"], "transport": "stdio"}
    }) as client:
        tools = client.get_tools()
        agent = create_react_agent(llm, tools)
        code_snippet = "def foo(): pass\\ndef bar(): pass\\nasync def baz(): pass"
        result = await agent.ainvoke({
            "messages": [("user", f"How many functions are in this code?\\n```python\\n{code_snippet}\\n```")]
        })
        print(result["messages"][-1].content)

asyncio.run(main())
'''

import pathlib
pathlib.Path("recipe10_server.py").write_text(SERVER_CODE.strip())
pathlib.Path("recipe10_client.py").write_text(CLIENT_CODE.strip())
print("Files written: recipe10_server.py  recipe10_client.py")
print("Run: python recipe10_server.py   (in one terminal)")
print("Run: python recipe10_client.py   (in another terminal)")
```

---

## Recipe 11 — Pydantic AI Structured Extractor

```python
# pip install pydantic-ai pydantic openai
import subprocess
from pydantic import BaseModel, field_validator
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIModel

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
model = OpenAIModel(
    "gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

class Invoice(BaseModel):
    vendor: str
    date: str
    total_amount: float
    currency: str
    line_items: list[str]

    @field_validator("total_amount")
    @classmethod
    def must_be_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("total_amount must be positive")
        return v

    @field_validator("currency")
    @classmethod
    def valid_currency(cls, v: str) -> str:
        if v.upper() not in {"USD", "EUR", "GBP", "JPY", "CAD", "AUD"}:
            raise ValueError(f"Unsupported currency: {v}")
        return v.upper()

agent: Agent[None, Invoice] = Agent(
    model,
    result_type=Invoice,
    system_prompt="Extract invoice data precisely from the provided text.",
)

INVOICES = [
    "Invoice from Acme Corp dated 2024-03-15. Items: Widget x2 ($25.00 each), Gadget x1 ($50.00). Total: $100.00 USD.",
    "Bill from TechSupplies Ltd, 12 Jan 2024. Keyboard £45.99, Mouse £19.99. Total: £65.98 GBP.",
    "Rechnung von DataGmbH, 2024-02-28. Lizenz €299.00, Support €50.00. Gesamt: €349.00 EUR.",
]

if __name__ == "__main__":
    for i, text in enumerate(INVOICES, 1):
        result = agent.run_sync(text)
        inv = result.data
        print(f"\nInvoice {i}: {inv.vendor} | {inv.date} | {inv.total_amount} {inv.currency}")
        print(f"  Items: {', '.join(inv.line_items)}")
```

---

## Recipe 12 — LangGraph Human-in-the-Loop Approver

```python
# pip install langgraph langchain-openai openai
import subprocess
from typing import Annotated
from typing_extensions import TypedDict
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph.message import add_messages
from langchain_core.messages import HumanMessage, AIMessage

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini",
                 base_url="https://models.inference.ai.azure.com", api_key=token)

class State(TypedDict):
    messages: Annotated[list, add_messages]
    proposed_action: str
    approved: bool

def plan_node(state: State) -> dict:
    last = state["messages"][-1].content
    response = llm.invoke([HumanMessage(content=f"Propose a one-sentence action plan for: {last}")])
    return {"proposed_action": response.content, "messages": [response]}

def human_review_node(state: State) -> dict:
    print(f"\n⚠ Proposed action: {state['proposed_action']}")
    choice = input("Approve? (y/n): ").strip().lower()
    return {"approved": choice == "y"}

def execute_node(state: State) -> dict:
    if state["approved"]:
        result = llm.invoke([HumanMessage(content=f"Execute: {state['proposed_action']}")])
        return {"messages": [AIMessage(content=f"✅ Executed: {result.content}")]}
    return {"messages": [AIMessage(content="❌ Action rejected by human reviewer.")]}

builder = StateGraph(State)
builder.add_node("plan", plan_node)
builder.add_node("human_review", human_review_node)
builder.add_node("execute", execute_node)
builder.set_entry_point("plan")
builder.add_edge("plan", "human_review")
builder.add_edge("human_review", "execute")
builder.add_edge("execute", END)

with SqliteSaver.from_conn_string("hitl_memory.db") as memory:
    graph = builder.compile(checkpointer=memory, interrupt_before=["execute"])
    cfg = {"configurable": {"thread_id": "hitl-1"}}

    init_state = {"messages": [HumanMessage(content="Deploy the new API version to production")], "approved": False, "proposed_action": ""}
    snapshot = graph.invoke(init_state, config=cfg)
    print("Proposed:", snapshot["proposed_action"])

    approved = input("Approve execution? (y/n): ").strip().lower() == "y"
    graph.update_state(cfg, {"approved": approved})
    final = graph.invoke(None, config=cfg)
    print(final["messages"][-1].content)
```

---

## Recipe 13 — Async Parallel LLM Calls

```python
# pip install aiohttp openai
import asyncio, subprocess, time
from openai import AsyncOpenAI

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
async_client = AsyncOpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=token,
)

QUESTIONS = [
    "What is Python?", "Explain RAG in one sentence.", "What is a vector database?",
    "Define LLM.", "What is LangChain?", "Explain tokenization briefly.",
    "What is fine-tuning?", "Define prompt engineering.", "What is FAISS?",
    "Explain embeddings in NLP.",
]

CONCURRENCY_LIMIT = 4
semaphore = asyncio.Semaphore(CONCURRENCY_LIMIT)

async def ask_llm(idx: int, question: str) -> dict:
    async with semaphore:
        response = await async_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": question}],
            max_tokens=60,
        )
        answer = response.choices[0].message.content.strip()
        return {"idx": idx, "question": question, "answer": answer}

async def main():
    start = time.perf_counter()
    tasks = [ask_llm(i, q) for i, q in enumerate(QUESTIONS)]
    results = await asyncio.gather(*tasks)
    elapsed = time.perf_counter() - start

    for r in sorted(results, key=lambda x: x["idx"]):
        print(f"[{r['idx']+1:02d}] Q: {r['question']}")
        print(f"      A: {r['answer'][:120]}\n")

    print(f"✅ {len(results)} calls in {elapsed:.2f}s "
          f"(concurrency={CONCURRENCY_LIMIT})")

if __name__ == "__main__":
    asyncio.run(main())
```

---

## Recipe 14 — Semantic Kernel SDLC Plugin

```python
# pip install semantic-kernel openai
import subprocess, asyncio
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.connectors.ai.open_ai import OpenAIChatPromptExecutionSettings
from semantic_kernel.functions import kernel_function
from semantic_kernel.contents.chat_history import ChatHistory
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()

kernel = Kernel()
kernel.add_service(OpenAIChatCompletion(
    ai_model_id="gpt-4o-mini",
    api_key=token,
    base_url="https://models.inference.ai.azure.com",
    service_id="copilot",
))

class SDLCPlugin:
    @kernel_function(name="code_review", description="Review Python code and return improvement suggestions.")
    def code_review(self, code: str) -> str:
        return (f"Code Review for snippet ({len(code)} chars):\n"
                "1. Add type hints to all function parameters.\n"
                "2. Include docstrings for public functions.\n"
                "3. Handle potential exceptions explicitly.\n"
                "4. Consider extracting repeated logic into helpers.")

    @kernel_function(name="generate_docs", description="Generate markdown documentation for a Python function.")
    def generate_docs(self, function_signature: str) -> str:
        return (f"## `{function_signature}`\n\n"
                "**Description:** Performs the specified operation.\n\n"
                "**Parameters:**\n- `input`: Input value to process.\n\n"
                "**Returns:** Processed result.\n\n"
                "**Example:**\n```python\nresult = my_function(input_value)\n```")

    @kernel_function(name="suggest_tests", description="Suggest unit test cases for a given function name.")
    def suggest_tests(self, function_name: str) -> str:
        return (f"Suggested tests for `{function_name}`:\n"
                f"1. `test_{function_name}_happy_path` — normal input\n"
                f"2. `test_{function_name}_empty_input` — empty/None input\n"
                f"3. `test_{function_name}_boundary_values` — edge values\n"
                f"4. `test_{function_name}_invalid_type` — wrong type raises TypeError\n"
                f"5. `test_{function_name}_large_input` — performance check")

kernel.add_plugin(SDLCPlugin(), plugin_name="sdlc")

async def main():
    chat = kernel.get_service("copilot")
    settings = OpenAIChatPromptExecutionSettings(
        function_choice_behavior=FunctionChoiceBehavior.Auto(),
        max_tokens=512,
    )
    history = ChatHistory()
    history.add_system_message("You are an SDLC assistant. Use your tools to help developers.")

    prompts = [
        "Review this code: `def add(a, b): return a + b`",
        "Generate docs for: `def process_data(df, threshold=0.5) -> pd.DataFrame`",
        "Suggest tests for the function `calculate_discount`",
    ]

    for prompt in prompts:
        history.add_user_message(prompt)
        response = await chat.get_chat_message_contents(history, settings=settings, kernel=kernel)
        reply = response[0].content
        history.add_assistant_message(reply)
        print(f"User: {prompt}\nAssistant: {reply}\n{'-'*60}")

if __name__ == "__main__":
    asyncio.run(main())
```

---

## Recipe 15 — Full RAG Evaluation Pipeline

```python
# pip install langchain langchain-community langchain-huggingface faiss-cpu sentence-transformers openai pandas
import subprocess, csv, json
from pathlib import Path
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_openai import ChatOpenAI
from langchain.chains import RetrievalQA

token = subprocess.run(["gh","auth","token"],capture_output=True,text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini",
                 base_url="https://models.inference.ai.azure.com", api_key=token)

CORPUS = [
    "Python was created by Guido van Rossum and first released in 1991.",
    "LangChain is a framework for building LLM-powered applications, founded in 2022.",
    "FAISS (Facebook AI Similarity Search) enables efficient similarity search over dense vectors.",
    "RAG combines a retrieval system with a generative model for grounded answers.",
    "Embeddings are numerical representations of text that capture semantic meaning.",
    "Sentence Transformers is a Python library to compute dense embeddings for sentences.",
    "BM25 is a probabilistic retrieval function used in classic information retrieval.",
]

GOLDEN_QA = [
    {"question": "Who created Python?", "answer": "Guido van Rossum"},
    {"question": "When was LangChain founded?", "answer": "2022"},
    {"question": "What does FAISS stand for?", "answer": "Facebook AI Similarity Search"},
    {"question": "What does RAG combine?", "answer": "retrieval system with a generative model"},
    {"question": "What are embeddings?", "answer": "numerical representations of text"},
]

splitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=20)
docs = splitter.split_documents([Document(page_content=c) for c in CORPUS])
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vector_store = FAISS.from_documents(docs, embeddings)
retriever = vector_store.as_retriever(search_kwargs={"k": 3})
qa_chain = RetrievalQA.from_chain_type(llm=llm, retriever=retriever, return_source_documents=True)

def score_faithfulness(answer: str, contexts: list[str]) -> float:
    combined = " ".join(contexts).lower()
    words = [w for w in answer.lower().split() if len(w) > 3]
    if not words:
        return 0.0
    return sum(1 for w in words if w in combined) / len(words)

def score_answer_correctness(predicted: str, gold: str) -> float:
    pred_words = set(predicted.lower().split())
    gold_words = set(gold.lower().split())
    if not gold_words:
        return 0.0
    return len(pred_words & gold_words) / len(gold_words)

results = []
for item in GOLDEN_QA:
    output = qa_chain.invoke({"query": item["question"]})
    predicted = output["result"]
    contexts = [d.page_content for d in output["source_documents"]]

    faith = score_faithfulness(predicted, contexts)
    correctness = score_answer_correctness(predicted, item["answer"])
    ctx_relevance = score_faithfulness(item["question"], contexts)

    results.append({
        "question": item["question"],
        "gold_answer": item["answer"],
        "predicted_answer": predicted,
        "faithfulness": round(faith, 3),
        "context_relevance": round(ctx_relevance, 3),
        "answer_correctness": round(correctness, 3),
        "avg_score": round((faith + correctness + ctx_relevance) / 3, 3),
    })

output_csv = Path("rag_evaluation_results.csv")
with output_csv.open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=results[0].keys())
    writer.writeheader()
    writer.writerows(results)

print(f"\n{'Question':<45} {'Faith':>6} {'CtxRel':>7} {'Corr':>6} {'Avg':>6}")
print("-" * 72)
for r in results:
    print(f"{r['question']:<45} {r['faithfulness']:>6.3f} {r['context_relevance']:>7.3f} "
          f"{r['answer_correctness']:>6.3f} {r['avg_score']:>6.3f}")

avg_all = sum(r["avg_score"] for r in results) / len(results)
print(f"\n{'Overall Average':<45} {'':>6} {'':>7} {'':>6} {avg_all:>6.3f}")
print(f"\n✅ Results saved to {output_csv}")
```

---

## Bonus: Quick Reference Card

### Install One-Liners

```bash
# Core LLM SDKs
pip install openai anthropic google-generativeai

# LangChain ecosystem
pip install langchain langchain-community langchain-openai langchain-huggingface langgraph

# Vector stores & embeddings
pip install faiss-cpu chromadb qdrant-client sentence-transformers

# Agent frameworks
pip install crewai pyautogen pydantic-ai semantic-kernel

# RAG & search
pip install llama-index haystack-ai rank-bm25 pypdf

# DSPy & evaluation
pip install dspy-ai ragas deepeval

# MCP
pip install fastmcp langchain-mcp-adapters

# Utilities
pip install aiohttp pandas pydantic
```

### Minimal Working Examples

```python
# OpenAI (1 line)
from openai import OpenAI; c = OpenAI(); print(c.chat.completions.create(model="gpt-4o-mini", messages=[{"role":"user","content":"Hi"}]).choices[0].message.content)

# LangChain chain (2 lines)
from langchain_openai import ChatOpenAI; from langchain_core.messages import HumanMessage
print(ChatOpenAI(model="gpt-4o-mini").invoke([HumanMessage(content="What is 2+2?")]).content)

# FAISS similarity search (3 lines)
from sentence_transformers import SentenceTransformer; import faiss, numpy as np
m = SentenceTransformer("all-MiniLM-L6-v2"); embs = m.encode(["hello world","goodbye world"]).astype("float32")
idx = faiss.IndexFlatL2(embs.shape[1]); idx.add(embs); print(idx.search(m.encode(["hi there"]).astype("float32"),1))

# LlamaIndex (3 lines)
from llama_index.core import VectorStoreIndex, Document
idx = VectorStoreIndex.from_documents([Document(text="Python is great for AI.")])
print(idx.as_query_engine().query("What is Python good for?"))

# Pydantic AI (3 lines)
from pydantic import BaseModel; from pydantic_ai import Agent
class City(BaseModel): name: str; population: int
print(Agent("openai:gpt-4o-mini", result_type=City).run_sync("Describe Tokyo").data)
```

### LLM Provider Cheatsheet

| Provider | Base URL | Auth env var |
|---|---|---|
| GitHub Copilot | `https://models.inference.ai.azure.com` | `gh auth token` |
| OpenAI | `https://api.openai.com/v1` | `OPENAI_API_KEY` |
| Azure OpenAI | `https://<resource>.openai.azure.com/` | `AZURE_OPENAI_API_KEY` |
| Anthropic | *(use anthropic SDK)* | `ANTHROPIC_API_KEY` |
| Groq | `https://api.groq.com/openai/v1` | `GROQ_API_KEY` |
| Ollama (local) | `http://localhost:11434/v1` | `"ollama"` (any string) |
| LM Studio | `http://localhost:1234/v1` | `"lm-studio"` |

### GitHub Copilot Auth (canonical snippet)

```python
import subprocess
from openai import OpenAI

token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
client = OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)

resp = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(resp.choices[0].message.content)
```

### Common Error Fixes

| Error | Cause | Fix |
|---|---|---|
| `AuthenticationError` | Bad or missing API key | Run `gh auth login` then re-fetch token |
| `RateLimitError` | Too many requests | Add `asyncio.Semaphore` or `time.sleep(1)` |
| `ContextWindowExceededError` | Prompt too long | Trim history or use `max_tokens` |
| `ModuleNotFoundError` | Missing package | `pip install <package>` |
| `FAISS index empty` | Forgot to call `.add()` | Call `index.add(embeddings)` before search |
| `pydantic ValidationError` | LLM returned wrong format | Add `ModelRetry` or stricter prompt |
| `LangGraph thread not found` | Wrong thread_id | Use consistent `configurable.thread_id` |
| `asyncio.run() inside Jupyter` | Event loop conflict | Use `await main()` or `nest_asyncio` |
| `HuggingFace model download slow` | First run caches model | Wait once; subsequent runs are fast |
| `DSPy no examples compiled` | Empty trainset | Provide ≥3 labelled examples |

---

*Generated for the EngX AI Coach for Software Developers programme.*
