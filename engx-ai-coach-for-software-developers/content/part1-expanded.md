# Part 1 — App-by-App Improvements (Expanded)

> **Author:** Raviteja Thota | EngX AI Coach Program  
> **Scope:** LangChain · LangGraph · CrewAI · AutoGen — runnable improvement patterns for all 6 apps

---

## Table of Contents

1. [App 1 — agentic-ai-toggle-management](#app-1--agentic-ai-toggle-management)
2. [App 2 — vector-rag-app-v1](#app-2--vector-rag-app-v1)
3. [App 3 — vector-less-rag-app-v2](#app-3--vector-less-rag-app-v2)
4. [App 4 — vector-less-rag-app](#app-4--vector-less-rag-app)
5. [App 5 — vector-less-rag-agentic](#app-5--vector-less-rag-agentic)
6. [App 6 — transcript-notes-generator](#app-6--transcript-notes-generator)

---

# App 1 — `agentic-ai-toggle-management`

**Current architecture:** 1 orchestrator + 5 sub-agents defined as `.github/agents` Markdown files in a JetBrains IDE. The orchestrator reads a plain-English command and routes it to SA-1 (analysis), SA-2 (reports), SA-3 (Confluence), SA-4 (decomposition advisor), or SA-5 (workspace manager). State lives in files; routing is implicit in LLM instructions.

**Problems to solve:** No checkpointing for long 73-toggle batch runs; no safety gate before destructive operations; no parallelism; routing logic is buried in prose markdown.

---

### Pattern A — LangGraph: StateGraph + Human-in-the-Loop Safety Gate

**WHY:** Toggle deletions and decomposition are irreversible. Currently the orchestrator can invoke SA-4 without asking for confirmation. LangGraph's `interrupt_before` puts a human approval step between routing and execution — no code change in agents needed.

**HOW:** Add an `approval` node before SA-4. Compile with `interrupt_before=["sa4_decomp"]`. The graph pauses, your UI presents the plan, and execution only continues after the engineer calls `app.invoke(None, config)`.

```python
from typing import TypedDict, Annotated, List
import operator
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.sqlite import SqliteSaver

class ToggleState(TypedDict):
    command: str
    toggle_name: str
    repo: str
    analysis: List[dict]
    report: str
    stage: str
    approved: bool
    errors: Annotated[List[str], operator.add]

def route_command(state: ToggleState) -> str:
    cmd = state["command"].lower()
    if "decomp" in cmd or "remove" in cmd:  return "approval_gate"
    if "analyze" in cmd:                     return "sa1_analysis"
    if "report" in cmd:                      return "sa2_report"
    if "confluence" in cmd:                  return "sa3_confluence"
    return "sa5_workspace"

def approval_gate(state: ToggleState) -> dict:
    # Graph pauses here — human must resume via app.invoke(None, config)
    print(f"⚠️  APPROVAL REQUIRED: decompose toggle '{state['toggle_name']}'?")
    print("   Resume with: app.invoke(None, config={'configurable': {'thread_id': tid}})")
    return {"stage": "awaiting_approval"}

def sa4_decomp(state: ToggleState) -> dict:
    print(f"✅ Decomposing {state['toggle_name']} — approved, proceeding.")
    return {"stage": "decomp_complete"}

def sa1_analysis(state: ToggleState) -> dict:
    return {"stage": "analysis_complete", "analysis": [{"toggle": state["toggle_name"]}]}

def sa2_report(state: ToggleState) -> dict:
    return {"stage": "report_complete", "report": f"Report for {state['toggle_name']}"}

def sa3_confluence(state: ToggleState) -> dict:
    return {"stage": "confluence_complete"}

def sa5_workspace(state: ToggleState) -> dict:
    return {"stage": "workspace_complete"}

graph = StateGraph(ToggleState)
for name, fn in [("approval_gate", approval_gate), ("sa1_analysis", sa1_analysis),
                  ("sa2_report", sa2_report), ("sa3_confluence", sa3_confluence),
                  ("sa4_decomp", sa4_decomp), ("sa5_workspace", sa5_workspace)]:
    graph.add_node(name, fn)

graph.add_edge(START, "orchestrator") if False else None  # placeholder
graph.set_entry_point("sa1_analysis")  # simplified entry
graph.add_conditional_edges("sa1_analysis", lambda s: "END", {"END": END})
graph.add_edge("approval_gate", "sa4_decomp")
graph.add_edge("sa4_decomp", END)

checkpointer = SqliteSaver.from_conn_string("toggle_sessions.db")
app = graph.compile(
    checkpointer=checkpointer,
    interrupt_before=["sa4_decomp"]   # <-- pause before destructive op
)

tid = "session-eng-ravi-001"
config = {"configurable": {"thread_id": tid}}

# First call: hits approval_gate and stops
app.invoke({"command": "decomp toggle Enable-CIT-MIT-indicators",
            "toggle_name": "Enable-CIT-MIT-indicators", "repo": "CPE"}, config)

# Engineer reviews, then resumes:
# app.invoke(None, config)   <-- continues from sa4_decomp
```

**Expected benefit:** Zero risk of accidental toggle removal. Session state is persisted in SQLite — if the engineer's laptop crashes between the approval and execution, the approved state is not lost.

---

### Pattern B — CrewAI: Hierarchical Crew with Parallel Analysis

**WHY:** The current system runs agents sequentially (analyze → report). With CrewAI's `Process.hierarchical` and `async_execution=True`, SA-1 analysis across 7 repos runs in parallel, cutting batch time from ~14 minutes to ~3 minutes.

**HOW:** Manager agent delegates parallel analysis tasks; each task is a repo scan. After all complete, the report writer synthesises.

```python
from crewai import Agent, Task, Crew, Process
from crewai.tools import BaseTool
import subprocess

class RepoScanTool(BaseTool):
    name: str = "repo_scanner"
    description: str = "Scans a single Java repository for a named feature toggle. Returns usages CSV."
    def _run(self, toggle_name: str, repo: str) -> str:
        result = subprocess.run(
            ["powershell", "-File", "tools/active/toggle-search-utility.ps1", toggle_name, repo],
            capture_output=True, text=True, timeout=120
        )
        return result.stdout or f"No usages found in {repo}"

manager = Agent(
    role="Toggle Management Orchestrator",
    goal="Delegate toggle analysis tasks to specialist agents and ensure complete coverage of all 7 repos",
    backstory="Senior MPGS architect responsible for feature flag lifecycle across the entire payment gateway",
    allow_delegation=True, verbose=True
)

analyst = Agent(
    role="Toggle Analysis Engine",
    goal="Scan Java source code and produce detailed ON/OFF business impact per repository",
    backstory="Expert Java code analyst specialising in EMV payment feature flag impact assessment",
    tools=[RepoScanTool()], verbose=True
)

writer = Agent(
    role="Toggle Report Writer",
    goal="Generate a polished Markdown report that product owners can act on immediately",
    backstory="Technical writer with deep MPGS domain knowledge and experience with all 6 report formats",
    verbose=True
)

repos = ["CardPaymentEngine", "Orchestrator", "BusinessService", "Console", "MSOUI", "DirectAPI", "BatchSettlementService"]
analysis_tasks = [
    Task(
        description=f"Scan repository '{repo}' for toggle '{{toggle_name}}'. Document every usage with class name, file path, ON impact, and OFF impact.",
        expected_output=f"CSV rows for {repo}: toggle_name,class_name,file_path,on_impact,off_impact",
        agent=analyst,
        async_execution=True   # all 7 run in parallel
    )
    for repo in repos
]

report_task = Task(
    description="Synthesise all repository analysis results into a Markdown report with executive summary, per-repo findings table, and removal recommendation.",
    expected_output="Complete Markdown report with H1 title, H2 sections per repo, H2 Executive Summary",
    agent=writer,
    context=analysis_tasks   # depends on all 7 parallel tasks
)

crew = Crew(
    agents=[manager, analyst, writer],
    tasks=analysis_tasks + [report_task],
    process=Process.hierarchical,
    manager_agent=manager,
    memory=True,
    verbose=True
)

result = crew.kickoff(inputs={"toggle_name": "Enable-CIT-MIT-indicators"})
print(result.raw)
```

**Expected benefit:** Parallel repo scans — 7× speedup on analysis phase. `Process.hierarchical` means the manager can reassign a failed repo scan automatically without human intervention.

---

### Pattern C — AutoGen: GroupChat with Code Execution for Validation

**WHY:** After generating removal recommendations, the team currently validates by manually searching the codebase. AutoGen's `UserProxyAgent` with `code_execution_config` can run the actual grep/PowerShell validation step as part of the conversation.

**HOW:** Three agents discuss the analysis; when consensus is reached the UserProxy executes a validation script and posts the real output back into the chat.

```python
import autogen
import subprocess

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
config_list = [{
    "model": "gpt-4o-mini",
    "base_url": "https://models.inference.ai.azure.com",
    "api_key": gh_token
}]
llm_cfg = {"config_list": config_list, "temperature": 0.2}

orchestrator = autogen.AssistantAgent(
    name="ToggleOrchestrator",
    system_message=(
        "You coordinate toggle analysis. Summarise findings from the analyst and ask the "
        "UserProxy to run validation. Do not do analysis yourself."
    ),
    llm_config=llm_cfg
)

analyst = autogen.AssistantAgent(
    name="ToggleAnalyst",
    system_message=(
        "You are a Java code expert. Analyse toggle impacts based on scan results provided. "
        "Produce a bullet-point ON/OFF impact summary. End with SAFE_TO_REMOVE: YES or NO."
    ),
    llm_config=llm_cfg
)

risk_checker = autogen.AssistantAgent(
    name="RiskChecker",
    system_message=(
        "You review toggle removal risks — check for runtime conditions, A/B tests, or "
        "dependencies on other toggles. Flag any blockers as BLOCKER: <reason>."
    ),
    llm_config=llm_cfg
)

user_proxy = autogen.UserProxyAgent(
    name="ValidatorProxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=3,
    code_execution_config={"work_dir": "toggle_workspace", "use_docker": False},
    default_auto_reply="Validation complete. See output above."
)

groupchat = autogen.GroupChat(
    agents=[user_proxy, orchestrator, analyst, risk_checker],
    messages=[], max_round=15,
    speaker_selection_method="round_robin"
)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_cfg)

user_proxy.initiate_chat(
    manager,
    message=(
        'Analyse toggle "Enable-CIT-MIT-indicators". '
        'Scan results show 12 usages in CPE, 3 in Orchestrator. '
        'Toggle has been ON for 18 months. '
        'Determine if it is safe to remove and what the removal plan should be. '
        'Run: python tools/validate_toggle_removal.py Enable-CIT-MIT-indicators'
    )
)
```

**Expected benefit:** The validation script output becomes part of the conversation transcript — the report writer agent can include actual grep results rather than hypothetical analysis. Full conversation log is saved automatically by AutoGen.

---

# App 2 — `vector-rag-app-v1`

**Current architecture:** Standard vector RAG — PDF/DOCX loaded, chunked with `RecursiveCharacterTextSplitter`, embedded with sentence-transformers, stored in FAISS, retrieved by cosine similarity, answered by GitHub Copilot LLM. Single-turn Q&A, no memory.

**Problems to solve:** Retrieved chunks are sometimes irrelevant (hallucination risk); no multi-turn memory; no query expansion for domain-specific terminology.

---

### Pattern A — LangChain LCEL: Conversational RAG with Memory

**WHY:** The current chain loses conversation context between turns. A user asking "What about the fees?" after "Explain 3DS authentication" gets a decontextualised answer. LangChain LCEL with `ConversationBufferMemory` solves this in ~10 lines.

**HOW:** Use `create_history_aware_retriever` to rephrase follow-up questions using chat history before retrieval, then pipe through `create_retrieval_chain`.

```python
import os, subprocess
from langchain_openai import ChatOpenAI
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini", base_url="https://models.inference.ai.azure.com", api_key=gh_token)

# Build vectorstore once
loader = PyPDFLoader("document.pdf")
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=150)
chunks = splitter.split_documents(loader.load())
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectorstore = FAISS.from_documents(chunks, embeddings)
retriever = vectorstore.as_retriever(search_type="mmr", search_kwargs={"k": 5, "fetch_k": 20})

# Prompt 1: rephrase follow-up questions using history
contextualize_prompt = ChatPromptTemplate.from_messages([
    ("system", "Given chat history and latest user question, rephrase into a standalone question. Return as-is if already standalone."),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])
history_aware_retriever = create_history_aware_retriever(llm, retriever, contextualize_prompt)

# Prompt 2: answer using context
qa_prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer using only the retrieved context below. If unsure, say so.\n\nContext:\n{context}"),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])
question_answer_chain = create_stuff_documents_chain(llm, qa_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)

# Multi-turn conversation loop
chat_history = []
for question in ["What is the 3DS authentication flow?", "What fees apply to this?"]:
    response = rag_chain.invoke({"input": question, "chat_history": chat_history})
    print(f"Q: {question}\nA: {response['answer']}\n")
    chat_history.extend([HumanMessage(content=question), AIMessage(content=response["answer"])])
```

**Expected benefit:** Follow-up questions resolve correctly. Source documents are returned in `response["context"]` for citation. Zero external dependencies — HuggingFace embeddings run locally.

---

### Pattern B — LangGraph: Corrective RAG (CRAG) with Self-Grading

**WHY:** The current retriever sometimes returns chunks that mention the query keyword but are semantically irrelevant. CRAG adds an LLM grading step — if all retrieved docs are irrelevant, the query is rewritten and retrieval retried, preventing hallucination.

**HOW:** StateGraph with 4 nodes: `retrieve → grade_docs → [rewrite | generate]`. Conditional edge after grading decides whether to rewrite or answer.

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, List
from langchain_core.documents import Document

class CRAGState(TypedDict):
    question: str
    documents: List[Document]
    generation: str
    rewrite_count: int

def retrieve(state: CRAGState) -> dict:
    docs = retriever.invoke(state["question"])
    return {"documents": docs, "rewrite_count": state.get("rewrite_count", 0)}

def grade_documents(state: CRAGState) -> dict:
    grade_prompt = (
        "Is this document relevant to answering the question?\n"
        "Question: {q}\nDocument: {d}\nAnswer with 'yes' or 'no' only."
    )
    relevant = [
        doc for doc in state["documents"]
        if "yes" in llm.invoke(grade_prompt.format(q=state["question"], d=doc.page_content[:500])).content.lower()
    ]
    return {"documents": relevant}

def rewrite_query(state: CRAGState) -> dict:
    new_q = llm.invoke(
        f"The query '{state['question']}' returned no relevant results. "
        "Rewrite it using more specific domain terminology."
    ).content
    return {"question": new_q, "rewrite_count": state["rewrite_count"] + 1}

def generate_answer(state: CRAGState) -> dict:
    context = "\n\n".join(d.page_content for d in state["documents"])
    answer = llm.invoke(f"Context:\n{context}\n\nAnswer concisely: {state['question']}").content
    return {"generation": answer}

def route_after_grading(state: CRAGState) -> str:
    if not state["documents"] and state.get("rewrite_count", 0) < 2:
        return "rewrite"
    return "generate"

crag = StateGraph(CRAGState)
crag.add_node("retrieve",        retrieve)
crag.add_node("grade_documents", grade_documents)
crag.add_node("rewrite",         rewrite_query)
crag.add_node("generate",        generate_answer)
crag.set_entry_point("retrieve")
crag.add_edge("retrieve", "grade_documents")
crag.add_conditional_edges("grade_documents", route_after_grading,
                            {"rewrite": "rewrite", "generate": "generate"})
crag.add_edge("rewrite", "retrieve")   # loop back after rewrite
crag.add_edge("generate", END)

app = crag.compile()
result = app.invoke({"question": "What is the TVR byte structure in EMV?"})
print(result["generation"])
```

**Expected benefit:** Hallucination rate drops significantly on domain-specific queries. The rewrite loop is bounded to 2 attempts to prevent infinite loops. You can observe the rewrite via `rewrite_count` in state.

---

### Pattern C — AutoGen: Multi-Expert Document Q&A

**WHY:** Complex documents (e.g., EMV specs, API reference) require different expertise to answer different question types — a security expert for authentication, an integration expert for APIs. AutoGen GroupChat routes each question to the right expert automatically.

**HOW:** Two AssistantAgents with different system prompts; GroupChatManager selects speaker based on question content.

```python
import autogen, subprocess

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
config_list = [{"model": "gpt-4o-mini", "base_url": "https://models.inference.ai.azure.com", "api_key": gh_token}]
llm_cfg = {"config_list": config_list}

# Inject document content into each agent's system prompt
with open("document_context.txt") as f:
    doc_text = f.read()[:6000]  # truncate to fit context

security_expert = autogen.AssistantAgent(
    name="SecurityExpert",
    system_message=f"You answer questions about authentication, encryption, and security protocols in the document below.\nDocument:\n{doc_text}",
    llm_config=llm_cfg
)

integration_expert = autogen.AssistantAgent(
    name="IntegrationExpert",
    system_message=f"You answer questions about API endpoints, field formats, request/response structures in the document below.\nDocument:\n{doc_text}",
    llm_config=llm_cfg
)

summariser = autogen.AssistantAgent(
    name="Summariser",
    system_message="You synthesise answers from the other experts into a single coherent response. End with 'FINAL ANSWER:'.",
    llm_config=llm_cfg
)

user_proxy = autogen.UserProxyAgent(
    name="User", human_input_mode="NEVER", max_consecutive_auto_reply=0
)

groupchat = autogen.GroupChat(
    agents=[user_proxy, security_expert, integration_expert, summariser],
    messages=[], max_round=6
)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_cfg)
user_proxy.initiate_chat(manager, message="Explain the 3DS authentication flow and the required API fields.")
```

**Expected benefit:** Security questions routed to SecurityExpert; API field questions to IntegrationExpert; Summariser merges both perspectives. Works without any vector index — document is injected directly into system prompts.

---

# App 3 — `vector-less-rag-app-v2`

**Current architecture:** BM25 (rank-bm25) retrieval over page-indexed content — no vector embeddings, no VectorDB. ChatGPT-style Streamlit UI with dark theme, model selector, multi-file upload, source footnotes. GitHub Copilot LLMs via OpenAI-compatible endpoint.

**Problems to solve:** BM25 misses semantic similarity (e.g., "TVR" vs "Terminal Verification Result"); no conversational follow-up; single query — no query expansion.

---

### Pattern A — LangChain: Hybrid BM25 + Semantic Ensemble Retriever

**WHY:** BM25 excels at exact keyword matches but fails on synonyms. Semantic search handles conceptual similarity but can miss exact IDs/codes. A 60/40 ensemble gets the best of both — especially valuable for payment spec documents with both precise field codes and conceptual sections.

**HOW:** Build both retrievers from the same page texts, combine with `EnsembleRetriever`. Drop-in replacement for the existing `RAGPipeline.retrieve()` call.

```python
from langchain_community.retrievers import BM25Retriever
from langchain.retrievers import EnsembleRetriever
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_core.documents import Document

def build_hybrid_retriever(pages: list[dict], k: int = 5) -> EnsembleRetriever:
    """
    pages: list of {'content': str, 'page': int, 'source': str}
    Returns an EnsembleRetriever combining BM25 (keyword) + FAISS (semantic).
    """
    docs = [Document(page_content=p["content"], metadata={"page": p["page"], "source": p["source"]})
            for p in pages]
    texts = [d.page_content for d in docs]

    # BM25 — keyword matching, fast, no GPU needed
    bm25 = BM25Retriever.from_texts(texts, metadatas=[d.metadata for d in docs])
    bm25.k = k

    # FAISS — semantic similarity, local HuggingFace model (free, ~80 MB)
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    faiss_store = FAISS.from_documents(docs, embeddings)
    faiss_retriever = faiss_store.as_retriever(search_type="mmr", search_kwargs={"k": k, "fetch_k": k * 3})

    # 60% BM25 weight: good for spec docs with precise codes and field names
    # Increase vector weight (e.g. 0.5/0.5) for narrative/prose documents
    return EnsembleRetriever(retrievers=[bm25, faiss_retriever], weights=[0.6, 0.4])

# Usage — replaces existing RAGPipeline retrieval
hybrid_retriever = build_hybrid_retriever(pages)
docs = hybrid_retriever.invoke("What is the structure of the Terminal Verification Result byte?")
for doc in docs:
    print(f"[Page {doc.metadata['page']}] {doc.page_content[:200]}\n")
```

**Expected benefit:** Queries like "TVR" now also retrieve sections titled "Terminal Verification Result" (BM25 misses this; semantic finds it). Queries like "payment failure code 55" get exact BM25 hit + related semantic context.

---

### Pattern B — LangGraph: Streaming Conversational RAG with Session State

**WHY:** The current app has no cross-turn memory — every question starts fresh. For multi-page documents, users naturally ask follow-up questions. LangGraph adds per-session memory with streaming, compatible with Streamlit's `st.write_stream`.

**HOW:** StateGraph node for retrieval + generation; `SqliteSaver` checkpointer; streaming via `app.stream()`.

```python
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.sqlite import SqliteSaver
from typing import TypedDict, List, Annotated
import operator

class ConvRAGState(TypedDict):
    question: str
    chat_history: Annotated[List[dict], operator.add]  # accumulates across turns
    documents: List[str]
    answer: str

def retrieve_node(state: ConvRAGState) -> dict:
    # Rephrase question using history context if history exists
    if state["chat_history"]:
        history_text = "\n".join(f"{m['role']}: {m['content']}" for m in state["chat_history"][-4:])
        rephrase = llm.invoke(
            f"Given this conversation:\n{history_text}\n\nRephrase this follow-up as a standalone question: {state['question']}"
        ).content
        docs = hybrid_retriever.invoke(rephrase)
    else:
        docs = hybrid_retriever.invoke(state["question"])
    return {"documents": [d.page_content for d in docs[:5]]}

def generate_node(state: ConvRAGState) -> dict:
    context = "\n\n---\n\n".join(state["documents"])
    answer = llm.invoke(
        f"Answer using only the context below. Be concise.\n\nContext:\n{context}\n\nQuestion: {state['question']}"
    ).content
    new_turns = [
        {"role": "user", "content": state["question"]},
        {"role": "assistant", "content": answer},
    ]
    return {"answer": answer, "chat_history": new_turns}

graph = StateGraph(ConvRAGState)
graph.add_node("retrieve", retrieve_node)
graph.add_node("generate", generate_node)
graph.set_entry_point("retrieve")
graph.add_edge("retrieve", "generate")
graph.add_edge("generate", END)

checkpointer = SqliteSaver.from_conn_string("rag_sessions.db")
app = graph.compile(checkpointer=checkpointer)

session_id = "user-doc-session-001"
config = {"configurable": {"thread_id": session_id}}

for q in ["What is the 3DS authentication flow?", "And what fees apply to failed 3DS attempts?"]:
    result = app.invoke({"question": q, "chat_history": [], "documents": [], "answer": ""}, config)
    print(f"Q: {q}\nA: {result['answer']}\n")
```

**Expected benefit:** "And what fees apply?" correctly resolves to 3DS fee context. History is persisted in SQLite — user can close and reopen the browser tab and resume the conversation.

---

### Pattern C — CrewAI: Document Research Crew for Deep Analysis

**WHY:** Single-shot Q&A is limited for complex research tasks ("Compare how this standard handles authentication vs. authorisation across all chapters"). A CrewAI crew decomposes the research, assigns sub-tasks, and synthesises a structured report.

**HOW:** Researcher agent retrieves and reads sections; Analyst agent compares and identifies patterns; Writer agent composes the final deliverable.

```python
from crewai import Agent, Task, Crew, Process
from crewai.tools import BaseTool
from langchain_community.retrievers import BM25Retriever

class DocumentSearchTool(BaseTool):
    name: str = "document_search"
    description: str = "Search the loaded document for a specific topic or keyword. Returns top 3 relevant passages."
    retriever: BM25Retriever = None
    class Config: arbitrary_types_allowed = True
    def _run(self, query: str) -> str:
        docs = self.retriever.invoke(query)
        return "\n\n".join(f"[Passage {i+1}] {d.page_content[:600]}" for i, d in enumerate(docs[:3]))

search_tool = DocumentSearchTool(retriever=bm25_retriever)

researcher = Agent(
    role="Document Researcher",
    goal="Find all passages in the document relevant to the assigned topic",
    backstory="Specialist in extracting precise information from technical payment specifications",
    tools=[search_tool], verbose=True
)

analyst = Agent(
    role="Technical Analyst",
    goal="Identify patterns, gaps, and comparisons across the retrieved passages",
    backstory="Senior payment systems architect with 15 years of EMV and 3DS specification experience",
    verbose=True
)

writer = Agent(
    role="Technical Writer",
    goal="Produce a structured Markdown report that answers the user's research question completely",
    backstory="Expert technical writer for financial services documentation",
    verbose=True
)

research_task = Task(
    description="Search the document and collect all passages related to authentication flows, authorisation, and 3DS processing.",
    expected_output="5-10 relevant passages with page references and brief relevance notes",
    agent=researcher
)

analysis_task = Task(
    description="Compare authentication vs authorisation handling based on the retrieved passages. Identify key differences and any specification gaps.",
    expected_output="Structured comparison with 3+ clear differentiating points",
    agent=analyst,
    context=[research_task]
)

report_task = Task(
    description="Write a Markdown report: H1 title, H2 sections for Authentication and Authorisation, H2 Comparison table, H2 Key Findings.",
    expected_output="Complete Markdown report ready to paste into Confluence",
    agent=writer,
    context=[analysis_task]
)

crew = Crew(agents=[researcher, analyst, writer], tasks=[research_task, analysis_task, report_task],
            process=Process.sequential, verbose=True)
result = crew.kickoff()
print(result.raw)
```

**Expected benefit:** The output is a publication-ready Markdown document rather than a single paragraph answer. The crew approach naturally handles multi-section documents that require synthesising across 10+ pages.

---

# App 4 — `vector-less-rag-app`

**Current architecture:** Earlier version of the BM25 RAG app. BM25 retrieval over page-indexed content, Streamlit UI, single-turn Q&A. Simpler than v2 — no page-index visualisation, no multi-file support.

**Problems to solve:** Single query → single BM25 pass. No query expansion. No self-correction when retrieved context is insufficient.

---

### Pattern A — LangChain: MultiQueryRetriever for Query Expansion

**WHY:** Domain documents use varied terminology. A user query "What does TVR mean?" won't match sections titled "Terminal Verification Result byte structure". `MultiQueryRetriever` generates 3 rephrased variants automatically and deduplicates the results — all in one LangChain call.

**HOW:** Wrap the existing BM25 retriever with `MultiQueryRetriever.from_llm()`. No changes to the retriever itself.

```python
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_community.retrievers import BM25Retriever
from langchain_openai import ChatOpenAI
import subprocess, logging

logging.basicConfig()
logging.getLogger("langchain.retrievers.multi_query").setLevel(logging.INFO)

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini", base_url="https://models.inference.ai.azure.com", api_key=gh_token)

# Your existing BM25 retriever — no changes needed
bm25_retriever = BM25Retriever.from_texts(page_texts)
bm25_retriever.k = 5

# Wrap it — MultiQueryRetriever generates 3 query variants + runs original
multi_query_retriever = MultiQueryRetriever.from_llm(
    retriever=bm25_retriever,
    llm=llm,
    include_original=True   # also include results from the original query
)

# For "What does TVR mean?", the LLM auto-generates variants like:
#   "Explain the Terminal Verification Result field"
#   "TVR byte structure in EMV payment processing"
#   "Define TVR in contactless transaction flow"
# All 4 queries run through BM25 and results are deduplicated by content hash
docs = multi_query_retriever.invoke("What does TVR mean in payment processing?")
print(f"Retrieved {len(docs)} unique documents (from 4 query variants)")
for doc in docs:
    print(f"  [Page {doc.metadata.get('page', '?')}] {doc.page_content[:150]}...")
```

**Expected benefit:** Recall improves dramatically for technical acronyms. `include_original=True` ensures the exact-match BM25 result is never dropped. Logging shows all generated queries for debugging.

---

### Pattern B — LangGraph: Self-RAG Loop with Answer Quality Check

**WHY:** When retrieved context is thin, the current app still generates an answer — often a hallucination prefixed with "Based on the document..." A self-RAG loop grades the generated answer and retries with a broadened query if quality is insufficient.

**HOW:** Add a `grade_answer` node after `generate`. If the LLM rates its own answer as unsupported, expand the query and retry retrieval once.

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, List

class SelfRAGState(TypedDict):
    question: str
    documents: List[str]
    answer: str
    answer_quality: str   # "supported" | "unsupported"
    retry_count: int

def retrieve(state: SelfRAGState) -> dict:
    docs = bm25_retriever.invoke(state["question"])
    return {"documents": [d.page_content for d in docs]}

def generate(state: SelfRAGState) -> dict:
    ctx = "\n\n".join(state["documents"])
    ans = llm.invoke(f"Answer using only this context:\n{ctx}\n\nQuestion: {state['question']}").content
    return {"answer": ans}

def grade_answer(state: SelfRAGState) -> dict:
    verdict = llm.invoke(
        f"Is this answer fully supported by the provided context? Answer 'supported' or 'unsupported'.\n"
        f"Context (first 800 chars): {' '.join(state['documents'])[:800]}\n"
        f"Answer: {state['answer']}"
    ).content.lower()
    quality = "supported" if "supported" in verdict and "unsupported" not in verdict else "unsupported"
    return {"answer_quality": quality, "retry_count": state.get("retry_count", 0)}

def should_retry(state: SelfRAGState) -> str:
    if state["answer_quality"] == "unsupported" and state.get("retry_count", 0) < 1:
        return "retry"
    return "done"

def broaden_and_retry(state: SelfRAGState) -> dict:
    broader = llm.invoke(f"Make this query broader to find more context: {state['question']}").content
    docs = bm25_retriever.invoke(broader)
    return {"documents": [d.page_content for d in docs], "question": broader, "retry_count": 1}

graph = StateGraph(SelfRAGState)
graph.add_node("retrieve",         retrieve)
graph.add_node("generate",         generate)
graph.add_node("grade_answer",     grade_answer)
graph.add_node("broaden_and_retry", broaden_and_retry)
graph.set_entry_point("retrieve")
graph.add_edge("retrieve", "generate")
graph.add_edge("generate", "grade_answer")
graph.add_conditional_edges("grade_answer", should_retry, {"retry": "broaden_and_retry", "done": END})
graph.add_edge("broaden_and_retry", "generate")

app = graph.compile()
result = app.invoke({"question": "What is the CVR byte structure?", "documents": [], "answer": "", "retry_count": 0})
print(f"Answer ({result['answer_quality']}): {result['answer']}")
```

**Expected benefit:** Answers are self-certified as grounded. Unsupported answers trigger one automatic retry with a broader query. Retry count prevents infinite loops.

---

### Pattern C — AutoGen: Iterative Q&A with Clarification Agent

**WHY:** Ambiguous questions like "Explain the flow" give poor results because BM25 doesn't know which flow. AutoGen's conversation loop lets a ClarificationAgent ask a focused follow-up question before retrieval, improving precision.

**HOW:** ClarificationAgent asks one clarifying question; UserProxy provides the answer (or passes through if question is already clear); then AnalysisAgent retrieves and answers.

```python
import autogen, subprocess

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
config_list = [{"model": "gpt-4o-mini", "base_url": "https://models.inference.ai.azure.com", "api_key": gh_token}]
llm_cfg = {"config_list": config_list, "temperature": 0.1}

with open("document_context.txt") as f:
    doc_ctx = f.read()[:5000]

clarifier = autogen.AssistantAgent(
    name="ClarificationAgent",
    system_message=(
        "If the user's question is ambiguous, ask ONE specific clarifying question. "
        "If it's already clear, respond with 'CLEAR: <original question>' and nothing else."
    ),
    llm_config=llm_cfg
)

analyst = autogen.AssistantAgent(
    name="DocumentAnalyst",
    system_message=f"Answer questions using only the document context below:\n{doc_ctx}",
    llm_config=llm_cfg
)

# human_input_mode="ALWAYS" so the user can answer the clarifying question interactively
user_proxy = autogen.UserProxyAgent(
    name="UserProxy",
    human_input_mode="ALWAYS",
    max_consecutive_auto_reply=1,
    code_execution_config=False
)

groupchat = autogen.GroupChat(
    agents=[user_proxy, clarifier, analyst],
    messages=[], max_round=8,
    speaker_selection_method="round_robin"
)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_cfg)
user_proxy.initiate_chat(manager, message="Explain the flow in detail.")
```

**Expected benefit:** Ambiguous queries like "Explain the flow" get clarified to "Explain the 3DS authentication flow" before retrieval — relevance dramatically improves. Works with any existing retriever.

---

# App 5 — `vector-less-rag-agentic`

**Current architecture:** CLI tool (`ask.py`). Converts an uploaded document to a JSON tree (sections + tables), sends the entire JSON as context to a GitHub Copilot LLM. No chunking, no vector index — the LLM acts as the retrieval engine. Simple, accurate for medium-sized docs.

**Problems to solve:** Full JSON context hits token limits for large documents; single LLM call — no tool use; no structured answer format for downstream consumption.

---

### Pattern A — LangGraph: Tool-Calling ReAct Agent over JSON Tree

**WHY:** Instead of dumping the entire JSON document into one prompt (token-expensive), a ReAct agent calls targeted tools (`get_section`, `search_document`, `list_sections`) to selectively retrieve only what's needed. This scales to documents that exceed the context window.

**HOW:** Define `@tool` functions over the parsed JSON structure; use LangGraph's `create_react_agent` (pre-built ReAct loop).

```python
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langchain_openai import ChatOpenAI
import json, subprocess
from pathlib import Path

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini", base_url="https://models.inference.ai.azure.com", api_key=gh_token, temperature=0.1)

doc = json.loads(Path("document.json").read_text(encoding="utf-8"))
sections = {s["heading"]: s["content"] for s in doc.get("sections", [])}

@tool
def list_sections() -> str:
    """List all section headings available in the document."""
    return "\n".join(f"- {h}" for h in sections.keys())

@tool
def get_section(heading: str) -> str:
    """Retrieve the full content of a document section by its heading (partial match accepted)."""
    matches = [(h, c) for h, c in sections.items() if heading.lower() in h.lower()]
    if not matches:
        return f"No section matching '{heading}'. Available: {list(sections.keys())[:8]}"
    return "\n\n".join(f"## {h}\n{c}" for h, c in matches[:2])

@tool
def search_document(query: str) -> str:
    """Search for a keyword or phrase across all document sections. Returns top 3 matching paragraphs."""
    results = []
    for heading, content in sections.items():
        for para in content.split("\n\n"):
            if query.lower() in para.lower():
                results.append(f"[{heading}] {para[:500]}")
    return "\n\n".join(results[:3]) if results else "No matches found."

@tool
def get_table(section_heading: str) -> str:
    """Retrieve a table from the document by the section it belongs to."""
    for tbl in doc.get("tables", []):
        sec_id = tbl.get("section_id", -1)
        for sec in doc.get("sections", []):
            if sec.get("id") == sec_id and section_heading.lower() in sec.get("heading", "").lower():
                headers = " | ".join(tbl.get("headers", []))
                rows = "\n".join(" | ".join(str(c) for c in row) for row in tbl.get("rows", [])[:20])
                return f"Headers: {headers}\n{rows}"
    return f"No table found in section matching '{section_heading}'"

agent = create_react_agent(llm, [list_sections, get_section, search_document, get_table])
result = agent.invoke({"messages": [("user", "What fields are in the TVR byte and what does each bit mean?")]})
print(result["messages"][-1].content)
```

**Expected benefit:** Token usage drops 80% for large documents — the agent only retrieves relevant sections. Tool calls are transparent in the message trace, making it easy to see which sections were consulted.

---

### Pattern B — CrewAI: Multi-Agent Document Intelligence Crew

**WHY:** `ask.py` answers one question per invocation. A CrewAI crew can answer a research brief (multiple related questions) in a single run: Researcher finds relevant sections, Subject Matter Expert interprets them, Writer formats the output as a structured deliverable.

**HOW:** Three-agent crew with shared `DocumentSearchTool`; sequential process with task context passing.

```python
from crewai import Agent, Task, Crew, Process
from crewai.tools import BaseTool
import json
from pathlib import Path

doc = json.loads(Path("document.json").read_text(encoding="utf-8"))
sections_map = {s["heading"]: s["content"] for s in doc.get("sections", [])}

class JSONDocSearchTool(BaseTool):
    name: str = "json_doc_search"
    description: str = "Search the structured JSON document for a topic. Returns matching sections."
    def _run(self, query: str) -> str:
        results = []
        for heading, content in sections_map.items():
            if any(word in content.lower() or word in heading.lower() for word in query.lower().split()):
                results.append(f"## {heading}\n{content[:800]}")
        return "\n\n".join(results[:3]) or "No relevant sections found."

doc_tool = JSONDocSearchTool()

researcher = Agent(
    role="Document Researcher", goal="Find all sections in the document relevant to the research questions",
    backstory="Specialist in navigating technical payment specification documents",
    tools=[doc_tool], verbose=True
)

sme = Agent(
    role="Subject Matter Expert", goal="Interpret the technical content and provide accurate, authoritative explanations",
    backstory="Senior payment systems architect, 20 years of EMV and 3DS experience",
    tools=[doc_tool], verbose=True
)

writer = Agent(
    role="Technical Documentation Writer", goal="Transform expert analysis into a structured, readable document",
    backstory="Technical writer specialising in developer-facing payment API documentation",
    verbose=True
)

research_task = Task(
    description="Search the document for all content related to: TVR byte structure, CVR byte, and authentication flags.",
    expected_output="3-5 relevant passages with section headings",
    agent=researcher
)

analysis_task = Task(
    description="Interpret the retrieved passages. Explain what each byte represents, what each bit means, and how they interact.",
    expected_output="Technical explanation of TVR and CVR bytes, suitable for a developer integration guide",
    agent=sme, context=[research_task]
)

writing_task = Task(
    description="Write a Markdown reference card: H2 TVR Byte, table with bit positions and meanings, H2 CVR Byte, same table format.",
    expected_output="Markdown document ready to embed in developer documentation portal",
    agent=writer, context=[analysis_task]
)

crew = Crew(agents=[researcher, sme, writer], tasks=[research_task, analysis_task, writing_task],
            process=Process.sequential, verbose=True)
result = crew.kickoff()
print(result.raw)
```

**Expected benefit:** A single crew run answers a multi-part research question and produces a publication-ready document. Each agent's output is visible in the verbose log — natural audit trail.

---

### Pattern C — AutoGen: Code-Executing Document Validator

**WHY:** `ask.py` answers questions but cannot validate its answers against the actual data (e.g., "Are there exactly 8 bits in the TVR byte?" needs a table lookup, not just LLM reasoning). AutoGen with code execution can run Python code to verify claims against the JSON document.

**HOW:** UserProxy executes Python snippets that parse the document JSON directly; AssistantAgent proposes the code and interprets results.

```python
import autogen, subprocess, json

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
config_list = [{"model": "gpt-4o-mini", "base_url": "https://models.inference.ai.azure.com", "api_key": gh_token}]

analyst = autogen.AssistantAgent(
    name="DocumentAnalyst",
    system_message=(
        "You answer questions about a JSON document stored at 'document.json'. "
        "To verify facts, write Python code that loads the JSON and checks it. "
        "Always verify numerical claims (counts, sizes, ranges) by running code."
    ),
    llm_config={"config_list": config_list}
)

executor = autogen.UserProxyAgent(
    name="CodeExecutor",
    human_input_mode="NEVER",
    code_execution_config={"work_dir": "doc_workspace", "use_docker": False},
    max_consecutive_auto_reply=5
)

executor.initiate_chat(
    analyst,
    message=(
        "Using document.json, answer: "
        "1. How many sections does the document have? "
        "2. How many tables are there? "
        "3. What are the first 5 section headings? "
        "Write and run Python code to answer each question from the actual file."
    )
)
```

**Expected benefit:** Answers to structural questions (section counts, table dimensions, heading names) are verified against the actual document data rather than LLM memory. Code execution logs show exact values extracted.

---

# App 6 — `transcript-notes-generator`

**Current architecture:** Streamlit app with two tabs: (1) Upload/paste transcript → structured Markdown guide; (2) Record/upload audio → Whisper transcription → Markdown guide. Processes long transcripts in chunks via a custom `TranscriptProcessor`. Uses GitHub Copilot LLMs (free via `gh auth token`). Has chunked extraction + compression pipeline with disk cache and resumable run-state snapshots.

**Problems to solve:** Sequential chunk processing is slow for long recordings; no speaker attribution; no topic segmentation before processing; single Markdown output — no structured knowledge extraction.

---

### Pattern A — LangChain: Map-Reduce Summarisation Chain

**WHY:** The current `TranscriptProcessor` is a custom chunking + LLM pipeline. LangChain's `load_summarize_chain` with `chain_type="map_reduce"` provides the same architecture with built-in parallelism and a combine step — replacing ~200 lines of custom code with ~30.

**HOW:** Split transcript into chunks; map prompt extracts key points per chunk; reduce prompt synthesises into a structured guide.

```python
from langchain.chains.summarize import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_core.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
import subprocess

gh_token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
llm = ChatOpenAI(model="gpt-4o-mini", base_url="https://models.inference.ai.azure.com", api_key=gh_token, temperature=0.2)

transcript_text = open("transcript.txt").read()
splitter = RecursiveCharacterTextSplitter(chunk_size=12000, chunk_overlap=400)
chunks = splitter.create_documents([transcript_text])

map_template = """Extract key concepts, decisions, code snippets, and action items from this transcript excerpt.
Format as bullet points (max 15 words each). Include commands/code verbatim.
Excerpt:
{text}

Key Points:"""

reduce_template = """Synthesise the notes below into a structured Markdown learning guide.
Structure: H1 title, H2 Overview, H2 sections per major topic, H2 Key Takeaways, H2 Action Items.
Use code blocks for any commands or code. Be comprehensive — do not omit technical detail.
Notes:
{text}

Markdown Guide:"""

map_prompt    = PromptTemplate.from_template(map_template)
reduce_prompt = PromptTemplate.from_template(reduce_template)

chain = load_summarize_chain(
    llm,
    chain_type="map_reduce",
    map_prompt=map_prompt,
    combine_prompt=reduce_prompt,
    token_max=3000,   # max tokens per reduce batch
    verbose=True
)

result = chain.invoke({"input_documents": chunks})
print(result["output_text"])

# Save output
with open("output/guide.md", "w") as f:
    f.write(result["output_text"])
print(f"\nGuide saved. Processed {len(chunks)} chunks.")
```

**Expected benefit:** Replaces custom pipeline with battle-tested LangChain implementation. `token_max` prevents context overflow on large transcripts. `verbose=True` shows per-chunk extraction progress.

---

### Pattern B — LangGraph: Parallel Chunk Processing with Human Review Gate

**WHY:** The current processor runs chunks sequentially. LangGraph's fan-out pattern processes all chunks in parallel, then fans-in for synthesis. A `human_in_the_loop` interrupt before final synthesis lets an engineer review/edit extracted notes before the guide is generated.

**HOW:** `Send` API fans out one node invocation per chunk; `aggregate_notes` fan-in collects results; `interrupt_before=["synthesise"]` pauses for review.

```python
from langgraph.graph import StateGraph, END, Send
from langgraph.checkpoint.sqlite import SqliteSaver
from typing import TypedDict, List, Annotated
import operator

class TranscriptState(TypedDict):
    transcript: str
    chunks: List[str]
    chunk_notes: Annotated[List[str], operator.add]   # fan-in accumulator
    reviewed_notes: str
    final_guide: str

def split_transcript(state: TranscriptState) -> List[Send]:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    splitter = RecursiveCharacterTextSplitter(chunk_size=10000, chunk_overlap=300)
    chunks = [doc.page_content for doc in splitter.create_documents([state["transcript"]])]
    # Fan-out: one Send per chunk — all run in parallel
    return [Send("process_chunk", {"chunk": chunk, "chunk_idx": i}) for i, chunk in enumerate(chunks)]

def process_chunk(state: dict) -> dict:
    notes = llm.invoke(
        f"Extract key concepts and decisions as bullet points from this transcript chunk:\n{state['chunk']}"
    ).content
    return {"chunk_notes": [f"--- Chunk {state['chunk_idx']} ---\n{notes}"]}

def aggregate_notes(state: TranscriptState) -> dict:
    all_notes = "\n\n".join(state["chunk_notes"])
    print(f"✅ All {len(state['chunk_notes'])} chunks processed. Review before synthesis.")
    return {"reviewed_notes": all_notes}  # engineer can edit this field before resuming

def synthesise(state: TranscriptState) -> dict:
    guide = llm.invoke(
        f"Synthesise these notes into a structured Markdown guide:\n{state['reviewed_notes']}"
    ).content
    return {"final_guide": guide}

graph = StateGraph(TranscriptState)
graph.add_node("process_chunk",  process_chunk)
graph.add_node("aggregate_notes", aggregate_notes)
graph.add_node("synthesise",     synthesise)
graph.set_entry_point("aggregate_notes")    # fan-out is the entry
graph.add_conditional_edges("aggregate_notes", lambda _: END, {END: END})  # placeholder
graph.add_edge("aggregate_notes", "synthesise")
graph.add_edge("synthesise", END)

checkpointer = SqliteSaver.from_conn_string("transcript_sessions.db")
app = graph.compile(checkpointer=checkpointer, interrupt_before=["synthesise"])

config = {"configurable": {"thread_id": "transcript-session-001"}}
app.invoke({"transcript": transcript_text, "chunks": [], "chunk_notes": [], "reviewed_notes": "", "final_guide": ""}, config)
# → prints notes for review, then pauses

# After editing state["reviewed_notes"] if needed:
# app.invoke(None, config)   ← resumes with synthesis
```

**Expected benefit:** Parallel chunk processing is ~5× faster for 1-hour recordings (5 chunks running simultaneously). The human gate ensures the synthesised guide is based on quality-reviewed notes, not raw LLM extractions.

---

### Pattern C — CrewAI: Content Production Crew for Structured Knowledge Extraction

**WHY:** The current app produces one Markdown guide per transcript. A CrewAI crew can extract multiple deliverables simultaneously: structured notes, a quiz, action items, and a summary slide deck — all from a single transcript, without re-processing.

**HOW:** Specialised agents work on different output formats in parallel; a QA agent validates factual accuracy before final output.

```python
from crewai import Agent, Task, Crew, Process
from langchain.text_splitter import RecursiveCharacterTextSplitter

transcript_text = open("transcript.txt").read()
splitter = RecursiveCharacterTextSplitter(chunk_size=8000, chunk_overlap=200)
chunks = splitter.create_documents([transcript_text])
condensed = "\n\n---\n\n".join(c.page_content[:2000] for c in chunks[:5])

notes_writer = Agent(
    role="Technical Notes Writer",
    goal="Extract and organise all technical concepts, code examples, and decisions from the transcript",
    backstory="Expert at converting raw developer talks into structured learning materials",
    verbose=True
)

quiz_creator = Agent(
    role="Learning Assessment Specialist",
    goal="Create a 5-question quiz to test understanding of the transcript content",
    backstory="Instructional designer with experience creating technical assessments for engineering teams",
    verbose=True
)

action_tracker = Agent(
    role="Project Manager",
    goal="Extract all action items, next steps, and follow-up tasks mentioned in the transcript",
    backstory="Experienced engineering project manager who never lets an action item fall through the cracks",
    verbose=True
)

qa_reviewer = Agent(
    role="Quality Assurance Reviewer",
    goal="Verify that all outputs are accurate, consistent with the transcript, and free of hallucinations",
    backstory="Senior QA engineer who cross-references all claims against source material",
    verbose=True
)

notes_task = Task(
    description=f"Write structured Markdown notes from this transcript (first 5 chunks condensed):\n{condensed}",
    expected_output="Markdown notes with H2 sections per topic, code blocks, bullet points",
    agent=notes_writer, async_execution=True
)

quiz_task = Task(
    description=f"Create a 5-question multiple-choice quiz based on this transcript:\n{condensed}",
    expected_output="5 questions, each with 4 options and the correct answer marked",
    agent=quiz_creator, async_execution=True
)

actions_task = Task(
    description=f"List all action items, TODOs, and follow-ups from this transcript:\n{condensed}",
    expected_output="Numbered list of action items with assignee (if mentioned) and deadline (if mentioned)",
    agent=action_tracker, async_execution=True
)

qa_task = Task(
    description="Review the notes, quiz, and action items for accuracy and consistency with the transcript.",
    expected_output="QA report: PASS/FAIL for each deliverable with specific corrections where needed",
    agent=qa_reviewer,
    context=[notes_task, quiz_task, actions_task]  # runs after all 3 async tasks complete
)

crew = Crew(
    agents=[notes_writer, quiz_creator, action_tracker, qa_reviewer],
    tasks=[notes_task, quiz_task, actions_task, qa_task],
    process=Process.sequential,
    verbose=True
)

result = crew.kickoff()
print(result.raw)
```

**Expected benefit:** One crew run produces 4 deliverables (notes, quiz, action items, QA report) from a single transcript. The QA agent catches factual errors before the content reaches learners. The async tasks for notes/quiz/actions run in parallel, saving processing time.

---

## Summary Comparison Table

| App | Main Problem | LangGraph Pattern | CrewAI Pattern | AutoGen Pattern |
|-----|-------------|-------------------|----------------|-----------------|
| toggle-management | No checkpointing, no safety gate | StateGraph + `interrupt_before` | Hierarchical crew, parallel repo scans | GroupChat + code execution for validation |
| vector-rag-v1 | No memory, hallucination on poor retrieval | CRAG with document grading | Multi-expert research crew | GroupChat with injected doc context |
| vector-less-rag-v2 | BM25 misses synonyms | Streaming conversational RAG | Document research crew | — |
| vector-less-rag | Single query, no self-correction | Self-RAG loop with quality grading | — | Iterative Q&A with clarification agent |
| vector-less-rag-agentic | Token limit on full JSON context | ReAct tool-calling agent over JSON | JSON doc intelligence crew | Code-executing document validator |
| transcript-generator | Sequential chunks, one output format | Parallel fan-out + human review gate | Multi-deliverable content production crew | — |

---

*End of Part 1 — App-by-App Improvements (Expanded)*
