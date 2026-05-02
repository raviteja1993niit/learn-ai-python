# Part 3 — Library Reference (Additional Libraries)

> **Author:** Raviteja Thota | EngX AI Coach Program
> **Extends:** AI-LIBRARIES-GUIDE.md Part 3 (LangChain, LangGraph, CrewAI, AutoGen, LlamaIndex, DSPy, MCP, ACP, Pydantic AI, Smolagents, Instructor)
> **Purpose:** Complete reference for Haystack, Semantic Kernel, Flowise, n8n + AI, Dify, Agno, Marvin, Guidance

---

## Table of Contents

- [3.12 Haystack (deepset)](#312-haystack-deepset)
- [3.13 Semantic Kernel (Microsoft)](#313-semantic-kernel-microsoft)
- [3.14 Flowise](#314-flowise)
- [3.15 n8n + AI](#315-n8n--ai)
- [3.16 Dify](#316-dify)
- [3.17 Agno (formerly Phidata)](#317-agno-formerly-phidata)
- [3.18 Marvin](#318-marvin)
- [3.19 Guidance (Microsoft)](#319-guidance-microsoft)
- [Comparison Tables](#comparison-tables)

---

## 3.12 Haystack (deepset)

### What is Haystack

Haystack (by deepset) is an open-source LLM framework built around **composable Pipelines**. It excels at document-centric workflows: Retrieval-Augmented Generation (RAG), question answering over document corpora, and pipeline evaluation. Haystack's differentiator is its first-class support for **pipeline evaluation** (answer correctness, faithfulness, context recall) and its mature **DocumentStore** abstraction that supports 15+ vector databases with a single interface.

**When to choose Haystack vs alternatives:**

| Scenario | Haystack | LangChain | LlamaIndex |
|----------|----------|-----------|------------|
| Production RAG with evaluation | ✅ Best | Good | Good |
| Complex retrieval (hybrid + rerank) | ✅ Best | Good | Good |
| Multi-agent workflows | Limited | ✅ Best | Good |
| Knowledge graphs | Poor | Limited | ✅ Best |
| Visual pipeline debugging | ✅ Good | LangSmith | Limited |

### Installation

```bash
pip install haystack-ai
# Document stores (choose one or more)
pip install farm-haystack[opensearch]   # OpenSearch
pip install haystack-ai qdrant-haystack  # Qdrant
pip install haystack-ai chroma-haystack  # ChromaDB
# Evaluation
pip install haystack-experimental
```

### Core Concepts

#### 1. Component — the atomic unit

A Component is a Python class decorated with `@component` that declares typed inputs/outputs. Haystack validates types at pipeline build time.

```python
from haystack import component
from haystack.dataclasses import Document
from typing import List

@component
class ToggleExtractor:
    """Extract toggle names from Java source code."""

    @component.output_types(toggles=List[str], document_count=int)
    def run(self, documents: List[Document]) -> dict:
        toggles = []
        for doc in documents:
            # Simple pattern — replace with regex in production
            for line in doc.content.splitlines():
                if "toggleService.isEnabled(" in line:
                    name = line.split('"')[1] if '"' in line else "unknown"
                    toggles.append(name)
        return {"toggles": list(set(toggles)), "document_count": len(documents)}
```

#### 2. Pipeline — connects Components with typed edges

```python
from haystack import Pipeline
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder

pipe = Pipeline()
pipe.add_component("retriever", InMemoryBM25Retriever(document_store=store))
pipe.add_component("prompt",    PromptBuilder(template="Context: {% for d in documents %}{{d.content}}{% endfor %}\nQuestion: {{question}}\nAnswer:"))
pipe.add_component("llm",       OpenAIGenerator(model="gpt-4o-mini"))

pipe.connect("retriever.documents", "prompt.documents")  # typed connections
pipe.connect("prompt.prompt",       "llm.prompt")

result = pipe.run({"retriever": {"query": "what does Enable-CIT do?"}, "prompt": {"question": "what does Enable-CIT do?"}})
```

#### 3. DocumentStore — unified vector DB interface

```python
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
from haystack_integrations.document_stores.opensearch import OpenSearchDocumentStore

# In-memory (dev/test)
store = InMemoryDocumentStore()

# Qdrant (production, free self-hosted)
store = QdrantDocumentStore(url="http://localhost:6333", index="docs", embedding_dim=384)

# OpenSearch (enterprise)
store = OpenSearchDocumentStore(hosts=["http://localhost:9200"], index="haystack")

# Write documents
from haystack.dataclasses import Document
docs = [Document(content="Feature toggle Enable-CIT controls CIT payment flow", meta={"source": "wiki"})]
store.write_documents(docs)
```

#### 4. Evaluators — built-in RAG evaluation

```python
from haystack.components.evaluators import (
    AnswerExactnessEvaluator,
    FaithfulnessEvaluator,
    ContextRelevanceEvaluator,
    SASEvaluator,              # Semantic Answer Similarity
)

faithfulness = FaithfulnessEvaluator(api="openai", api_key=Secret.from_env_var("OPENAI_API_KEY"))
result = faithfulness.run(
    questions=["What does Enable-CIT do?"],
    contexts=[["CIT toggle controls conditional payment routing."]],
    responses=["Enable-CIT routes payments through the CIT pathway."]
)
print(result["score"])  # 0.0 – 1.0
```

#### 5. Serialization — YAML pipeline export

```python
# Save pipeline (shareable, deployable)
yaml_str = pipe.dumps()
with open("rag_pipeline.yaml", "w") as f:
    f.write(yaml_str)

# Load pipeline from YAML
loaded = Pipeline.loads(open("rag_pipeline.yaml").read())
```

### Example 1 — Basic: Document Q&A in 20 Lines

```python
# pip install haystack-ai
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder
import os

# 1. Document store + sample docs
store = InMemoryDocumentStore()
store.write_documents([
    Document(content="LangChain is an LLM orchestration framework for building chains and agents."),
    Document(content="Haystack excels at RAG pipelines and document Q&A with built-in evaluation."),
    Document(content="CrewAI is designed for role-based multi-agent collaboration."),
])

# 2. Build pipeline
pipe = Pipeline()
pipe.add_component("retriever", InMemoryBM25Retriever(document_store=store, top_k=2))
pipe.add_component("prompt", PromptBuilder(
    template="""Use the documents below to answer the question.
Documents: {% for doc in documents %}{{ doc.content }} {% endfor %}
Question: {{ question }}
Answer:"""
))
pipe.add_component("llm", OpenAIGenerator(
    model="gpt-4o-mini",
    api_base_url="https://models.inference.ai.azure.com",
    api_key=os.environ["GITHUB_TOKEN"]
))
pipe.connect("retriever.documents", "prompt.documents")
pipe.connect("prompt.prompt",       "llm.prompt")

# 3. Run
result = pipe.run({"retriever": {"query": "best for RAG pipelines"},
                   "prompt":    {"question": "Which library is best for RAG pipelines?"}})
print(result["llm"]["replies"][0])
```

### Example 2 — Intermediate: Hybrid Retrieval + Reranking RAG

```python
# pip install haystack-ai sentence-transformers
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever, InMemoryEmbeddingRetriever
from haystack.components.embedders import SentenceTransformersTextEmbedder, SentenceTransformersDocumentEmbedder
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.components.joiners import DocumentJoiner
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder

EMBED_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

# Prepare store with embeddings
store = InMemoryDocumentStore()
doc_embedder = SentenceTransformersDocumentEmbedder(model=EMBED_MODEL)
doc_embedder.warm_up()

raw_docs = [
    Document(content="Enable-CIT routes transactions through the CIT payment gateway when enabled."),
    Document(content="The CIT gateway has lower fees for European cards but higher latency."),
    Document(content="Feature toggles are controlled via the ToggleService in Spring Boot."),
    Document(content="Disabling Enable-CIT falls back to the legacy payment provider."),
]
docs_with_embeddings = doc_embedder.run(raw_docs)["documents"]
store.write_documents(docs_with_embeddings)

# Build hybrid (BM25 + vector) + rerank pipeline
pipe = Pipeline()
pipe.add_component("query_embedder",  SentenceTransformersTextEmbedder(model=EMBED_MODEL))
pipe.add_component("vector_retriever", InMemoryEmbeddingRetriever(document_store=store, top_k=5))
pipe.add_component("bm25_retriever",   InMemoryBM25Retriever(document_store=store, top_k=5))
pipe.add_component("joiner",           DocumentJoiner(join_mode="reciprocal_rank_fusion"))
pipe.add_component("reranker",         TransformersSimilarityRanker(model="cross-encoder/ms-marco-MiniLM-L-6-v2", top_k=3))
pipe.add_component("prompt",           PromptBuilder(template="""
Context documents:
{% for doc in documents %}{{ loop.index }}. {{ doc.content }}
{% endfor %}
Question: {{ question }}
Provide a detailed answer citing which documents support your answer:"""))
pipe.add_component("llm", OpenAIGenerator(
    model="gpt-4o-mini",
    api_base_url="https://models.inference.ai.azure.com",
    api_key=os.environ["GITHUB_TOKEN"]
))

pipe.connect("query_embedder.embedding",        "vector_retriever.query_embedding")
pipe.connect("vector_retriever.documents",      "joiner.documents")
pipe.connect("bm25_retriever.documents",        "joiner.documents")
pipe.connect("joiner.documents",                "reranker.documents")
pipe.connect("reranker.documents",              "prompt.documents")
pipe.connect("prompt.prompt",                   "llm.prompt")

result = pipe.run({
    "query_embedder":  {"text": "what happens when Enable-CIT is turned off?"},
    "bm25_retriever":  {"query": "what happens when Enable-CIT is turned off?"},
    "reranker":        {"query": "what happens when Enable-CIT is turned off?"},
    "prompt":          {"question": "what happens when Enable-CIT is turned off?"}
})
print(result["llm"]["replies"][0])
```

### Example 3 — Advanced: RAG Pipeline with Automated Evaluation

```python
# pip install haystack-ai haystack-experimental sentence-transformers
import os
from haystack import Pipeline, Document
from haystack.document_stores.in_memory import InMemoryDocumentStore
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder
from haystack.components.evaluators import FaithfulnessEvaluator, ContextRelevanceEvaluator
from haystack.utils import Secret

OPENAI_CFG = {
    "model": "gpt-4o-mini",
    "api_base_url": "https://models.inference.ai.azure.com",
    "api_key": Secret.from_env_var("GITHUB_TOKEN")
}

# Dataset
qa_pairs = [
    {"question": "What does Enable-CIT toggle do?",
     "ground_truth": "Routes payments through CIT gateway when enabled."},
    {"question": "What is the fallback when CIT is disabled?",
     "ground_truth": "Payments fall back to legacy provider."},
]
store = InMemoryDocumentStore()
store.write_documents([
    Document(content="Enable-CIT routes transactions through the CIT payment gateway when enabled."),
    Document(content="Disabling Enable-CIT falls back to the legacy payment provider."),
    Document(content="The CIT gateway has lower fees but higher latency than legacy."),
])

# RAG pipeline
rag = Pipeline()
rag.add_component("retriever", InMemoryBM25Retriever(document_store=store, top_k=3))
rag.add_component("prompt",    PromptBuilder(template="Context: {% for d in documents %}{{d.content}} {% endfor %}\nQuestion: {{question}}\nAnswer:"))
rag.add_component("llm",       OpenAIGenerator(**OPENAI_CFG))
rag.connect("retriever.documents", "prompt.documents")
rag.connect("prompt.prompt",       "llm.prompt")

# Collect RAG outputs
questions, contexts, answers = [], [], []
for qa in qa_pairs:
    result = rag.run({"retriever": {"query": qa["question"]}, "prompt": {"question": qa["question"]}})
    questions.append(qa["question"])
    answers.append(result["llm"]["replies"][0])
    contexts.append([d.content for d in store.filter_documents()])  # simplified

# Evaluate: Faithfulness measures if answer is grounded in context
faithfulness_eval = FaithfulnessEvaluator(api="openai", api_key=Secret.from_env_var("GITHUB_TOKEN"),
                                          api_base_url="https://models.inference.ai.azure.com")
faith_result = faithfulness_eval.run(questions=questions, contexts=contexts, responses=answers)

# Evaluate: Context Relevance measures if retrieved docs match question
ctx_eval = ContextRelevanceEvaluator(api="openai", api_key=Secret.from_env_var("GITHUB_TOKEN"),
                                     api_base_url="https://models.inference.ai.azure.com")
ctx_result = ctx_eval.run(questions=questions, contexts=contexts)

print(f"Faithfulness Score:      {faith_result['score']:.2f}")
print(f"Context Relevance Score: {ctx_result['score']:.2f}")
print("Individual scores:")
for q, fs, cs in zip(questions, faith_result["individual_scores"], ctx_result["individual_scores"]):
    print(f"  Q: {q[:60]}... | Faithfulness={fs:.2f} | CtxRelevance={cs:.2f}")
```

### Free Tier / Pricing

- **Haystack (open-source):** 100% free, MIT license
- **deepset Cloud (managed):** Free tier with limited pipelines; Pro from ~$99/month
- **Hayhooks (REST API server):** Free, open-source

### Best Use Case for SDLC Automation

**Document Intelligence Platform:** Index your entire engineering knowledge base (Confluence, Jira, GitHub wikis, ADRs) with hybrid retrieval, and expose a Q&A API with built-in faithfulness evaluation to detect hallucinated answers before they reach developers.

---

## 3.13 Semantic Kernel (Microsoft)

### What is Semantic Kernel

Semantic Kernel (SK) is Microsoft's open-source SDK for integrating LLMs into applications. It uses a **plugin + planner** model: you define plugins (collections of functions, either native code or prompt-based), and a planner automatically chains them to accomplish user goals. SK supports Python, C#, and Java, making it the top choice for .NET/enterprise teams.

**When to choose SK vs alternatives:**

| Scenario | Semantic Kernel | LangChain | AutoGen |
|----------|----------------|-----------|---------|
| .NET / C# integration | ✅ Best | Poor | Poor |
| Azure OpenAI + local models | ✅ Best | Good | Good |
| Enterprise plugin registry | ✅ Best | Toolkits | Limited |
| Complex multi-agent graphs | Limited | LangGraph | ✅ Best |
| Prompt template management | ✅ Best | Good | Limited |

### Installation

```bash
pip install semantic-kernel
# Optional integrations
pip install semantic-kernel[azure]          # Azure OpenAI + Azure AI Search
pip install semantic-kernel[hugging_face]   # HuggingFace models
pip install semantic-kernel[ollama]         # Ollama local models
```

### Core Concepts

#### 1. Kernel — the central orchestrator

```python
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.connectors.ai.ollama import OllamaChatCompletion
import os

# Create kernel
kernel = sk.Kernel()

# Add OpenAI service (GitHub Models — free)
kernel.add_service(OpenAIChatCompletion(
    service_id="gpt4o-mini",
    ai_model_id="gpt-4o-mini",
    async_client=None,  # uses OPENAI_API_KEY env var
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ["GITHUB_TOKEN"]
))

# Add Ollama (fully local — free)
kernel.add_service(OllamaChatCompletion(
    service_id="llama3",
    ai_model_id="llama3.2",
    host="http://localhost:11434"
))
```

#### 2. Plugins — reusable function collections

```python
from semantic_kernel.functions import kernel_function
from semantic_kernel.plugin_definition import kernel_plugin

# Native Plugin (regular Python functions decorated for SK)
class CodeReviewPlugin:
    @kernel_function(name="check_security", description="Check code for security vulnerabilities")
    def check_security(self, code: str) -> str:
        """Perform static security analysis."""
        issues = []
        if "eval(" in code:        issues.append("Dangerous eval() usage")
        if "os.system(" in code:   issues.append("Shell injection risk via os.system()")
        if "password" in code.lower() and '="' in code:
            issues.append("Possible hardcoded password")
        return "\n".join(issues) if issues else "No obvious security issues found"

    @kernel_function(name="estimate_complexity", description="Estimate cyclomatic complexity")
    def estimate_complexity(self, code: str) -> str:
        branches = code.count("if ") + code.count("elif ") + code.count("for ") + code.count("while ")
        level = "LOW" if branches < 5 else "MEDIUM" if branches < 10 else "HIGH"
        return f"Estimated complexity: {level} ({branches} branches)"

# Register plugin on kernel
kernel.add_plugin(CodeReviewPlugin(), plugin_name="CodeReview")
```

#### 3. Prompt Templates — SK's inline prompting system

```python
from semantic_kernel.prompt_template import PromptTemplateConfig
from semantic_kernel.functions import KernelFunctionFromPrompt

# Define a prompt function
summarize_fn = KernelFunctionFromPrompt(
    function_name="summarize_code",
    plugin_name="Documentation",
    prompt="""You are an expert software documentation writer.
Summarize the following {{$language}} code in 3 bullet points for a non-technical audience:
{{$code}}

Bullet Summary:""",
    template_format="semantic-kernel",
    prompt_template_config=PromptTemplateConfig(
        execution_settings={"gpt4o-mini": {"max_tokens": 300, "temperature": 0.3}}
    )
)
kernel.add_function(plugin_name="Documentation", function=summarize_fn)
```

#### 4. Planners — auto-orchestrate plugins to achieve a goal

```python
from semantic_kernel.planners.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.connectors.ai.open_ai import OpenAIChatPromptExecutionSettings
from semantic_kernel.contents import ChatHistory

# Auto function calling — SK automatically picks and chains plugins
execution_settings = OpenAIChatPromptExecutionSettings(
    service_id="gpt4o-mini",
    function_choice_behavior=FunctionChoiceBehavior.Auto(),  # let LLM pick functions
    max_tokens=1000
)

chat_history = ChatHistory()
chat_history.add_user_message(
    "Review this Python code for security issues and estimate its complexity:\n"
    "import os\npassword='abc123'\neval(input())"
)

# Kernel automatically calls CodeReview.check_security and CodeReview.estimate_complexity
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
chat_service = kernel.get_service("gpt4o-mini")
result = await chat_service.get_chat_message_content(
    chat_history=chat_history,
    settings=execution_settings,
    kernel=kernel  # gives LLM access to all registered plugins
)
print(result)
```

#### 5. Memory / Vector Search

```python
from semantic_kernel.memory import SemanticTextMemory
from semantic_kernel.connectors.memory.chroma import ChromaMemoryStore
from semantic_kernel.connectors.ai.open_ai import OpenAITextEmbedding

# Setup memory with ChromaDB + embeddings
memory_store = ChromaMemoryStore(persist_directory="./sk_memory")
embedding_service = OpenAITextEmbedding(
    service_id="embedder",
    ai_model_id="text-embedding-3-small",
    api_key=os.environ["GITHUB_TOKEN"],
    base_url="https://models.inference.ai.azure.com"
)
memory = SemanticTextMemory(storage=memory_store, embeddings_generator=embedding_service)
kernel.add_plugin(sk.core_plugins.TextMemoryPlugin(memory), "memory")

# Save to memory
await memory.save_information("toggles", id="cit-toggle",
    text="Enable-CIT routes payments through CIT gateway. Risk: MEDIUM.")

# Query memory
results = await memory.search("toggles", "what is the CIT toggle?", limit=3)
for r in results: print(r.text, f"relevance={r.relevance:.2f}")
```

### Example 1 — Basic: Code Review Plugin with Auto Planner

```python
# pip install semantic-kernel
import asyncio, os
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAIChatPromptExecutionSettings
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function

class CodeQualityPlugin:
    @kernel_function(description="Check Python code for common bugs and style issues")
    def review_code(self, code: str) -> str:
        issues = []
        if "print(" in code and "logging" not in code:
            issues.append("Using print() instead of logging module")
        if "except:" in code:
            issues.append("Bare except clause — specify exception types")
        if "TODO" in code:
            issues.append("Unresolved TODO comment found")
        return "Issues: " + "; ".join(issues) if issues else "Code looks clean"

    @kernel_function(description="Generate a docstring for a Python function")
    def generate_docstring(self, function_code: str) -> str:
        # In real use, this would call an LLM
        return f'"""Auto-generated: {function_code.split("def ")[1].split("(")[0]} function."""'

async def main():
    kernel = sk.Kernel()
    kernel.add_service(OpenAIChatCompletion(
        service_id="chat",
        ai_model_id="gpt-4o-mini",
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ["GITHUB_TOKEN"]
    ))
    kernel.add_plugin(CodeQualityPlugin(), "CodeQuality")

    chat = ChatHistory()
    chat.add_user_message(
        "Please review this code and generate a docstring for the main function:\n\n"
        "def process_payment(amount):\n"
        "    # TODO: add validation\n"
        "    print('Processing...')\n"
        "    try:\n        return amount * 1.1\n    except:\n        return 0"
    )

    response = await kernel.get_service("chat").get_chat_message_content(
        chat_history=chat,
        settings=OpenAIChatPromptExecutionSettings(
            service_id="chat",
            function_choice_behavior=FunctionChoiceBehavior.Auto(),
            max_tokens=500
        ),
        kernel=kernel
    )
    print(response)

asyncio.run(main())
```

### Example 2 — Intermediate: Multi-Service RAG (OpenAI + Local Ollama Fallback)

```python
# pip install semantic-kernel
import asyncio, os
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion
from semantic_kernel.connectors.ai.ollama import OllamaChatCompletion
from semantic_kernel.functions import KernelFunctionFromPrompt
from semantic_kernel.prompt_template import PromptTemplateConfig

async def main():
    kernel = sk.Kernel()

    # Primary: GitHub Models (free, cloud)
    kernel.add_service(OpenAIChatCompletion(
        service_id="primary",
        ai_model_id="gpt-4o-mini",
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ.get("GITHUB_TOKEN", "")
    ))

    # Fallback: Ollama (free, local) — comment out if not installed
    # kernel.add_service(OllamaChatCompletion(service_id="fallback", ai_model_id="llama3.2"))

    knowledge_base = {
        "Enable-CIT": "Routes payments through CIT gateway. Reduces fees 15%. Latency +200ms.",
        "EnableNewUI": "Activates React-based checkout. A/B tested to +8% conversion.",
        "BypassFraudCheck": "DANGER: Skips fraud detection. Only for internal test accounts.",
    }

    rag_prompt = KernelFunctionFromPrompt(
        function_name="answer_toggle_question",
        plugin_name="KnowledgeBase",
        prompt="""You are a feature toggle expert. Use only the provided context.
Context: {{$context}}
Question: {{$question}}
If the answer is not in the context, say "I don't have information about that toggle."
Answer:""",
        prompt_template_config=PromptTemplateConfig(
            execution_settings={"primary": {"max_tokens": 400, "temperature": 0}}
        )
    )
    kernel.add_function(plugin_name="KnowledgeBase", function=rag_prompt)

    questions = [
        "What does Enable-CIT do and what are its trade-offs?",
        "Is BypassFraudCheck safe to enable in production?",
        "What is the EnablePayPal toggle?",
    ]

    for q in questions:
        context = "\n".join([f"{k}: {v}" for k, v in knowledge_base.items()])
        result = await kernel.invoke(
            kernel.get_function("KnowledgeBase", "answer_toggle_question"),
            context=context, question=q
        )
        print(f"Q: {q}\nA: {result}\n{'—'*60}")

asyncio.run(main())
```

### Example 3 — Advanced: SDLC Automation Pipeline with Plugins + Memory

```python
# pip install semantic-kernel chromadb
import asyncio, os, json
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAIChatPromptExecutionSettings
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.contents import ChatHistory
from semantic_kernel.functions import kernel_function

class SDLCAutomationPlugin:
    """Plugin covering full SDLC automation: requirements, testing, deployment."""

    def __init__(self):
        self.requirements_db = {}
        self.test_registry = {}

    @kernel_function(description="Store a user story in the requirements database")
    def save_requirement(self, story_id: str, title: str, acceptance_criteria: str) -> str:
        self.requirements_db[story_id] = {"title": title, "ac": acceptance_criteria, "status": "NEW"}
        return f"Saved requirement {story_id}: {title}"

    @kernel_function(description="Generate BDD test scenarios from acceptance criteria")
    def generate_bdd_tests(self, story_id: str) -> str:
        if story_id not in self.requirements_db:
            return f"Story {story_id} not found"
        req = self.requirements_db[story_id]
        # In production this calls LLM; here we return template
        return f"""Feature: {req['title']}
  Scenario: Happy path
    Given the system is in default state
    When the action described in "{req['ac'][:50]}..." is performed
    Then the expected outcome should be verified

  Scenario: Error case
    Given an invalid input
    When the action is performed
    Then an appropriate error response is returned"""

    @kernel_function(description="Check deployment readiness: tests, coverage, security")
    def check_deployment_readiness(self, service_name: str) -> str:
        # In production: query CI/CD APIs (Jenkins, GitHub Actions, SonarQube)
        checks = {
            "unit_tests":    "PASS (247/247)",
            "coverage":      "PASS (87%)",
            "security_scan": "PASS (0 critical CVEs)",
            "perf_test":     "WARN (P99 latency 450ms, threshold 400ms)",
            "approval":      "PENDING (needs 2 approvals, have 1)"
        }
        failed = [k for k, v in checks.items() if v.startswith(("FAIL", "PENDING"))]
        status = "READY" if not failed else f"NOT READY — blocked by: {', '.join(failed)}"
        details = "\n".join(f"  {k}: {v}" for k, v in checks.items())
        return f"Deployment status for {service_name}: {status}\n{details}"

    @kernel_function(description="Generate release notes from merged PRs")
    def generate_release_notes(self, version: str, pr_list: str) -> str:
        prs = json.loads(pr_list)
        features  = [p for p in prs if p.get("type") == "feature"]
        bugfixes  = [p for p in prs if p.get("type") == "bugfix"]
        breaking  = [p for p in prs if p.get("breaking", False)]
        notes = [f"# Release Notes — v{version}\n"]
        if breaking: notes.append("## ⚠️ Breaking Changes\n" + "\n".join(f"- {p['title']}" for p in breaking))
        if features: notes.append("## ✨ New Features\n" + "\n".join(f"- {p['title']}" for p in features))
        if bugfixes: notes.append("## 🐛 Bug Fixes\n" + "\n".join(f"- {p['title']}" for p in bugfixes))
        return "\n\n".join(notes)

async def main():
    kernel = sk.Kernel()
    kernel.add_service(OpenAIChatCompletion(
        service_id="chat",
        ai_model_id="gpt-4o-mini",
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ["GITHUB_TOKEN"]
    ))
    sdlc_plugin = SDLCAutomationPlugin()
    kernel.add_plugin(sdlc_plugin, "SDLC")

    # Simulate an SDLC conversation
    chat = ChatHistory()
    chat.add_system_message(
        "You are an SDLC automation assistant. Use SDLC plugins to help the team. "
        "Always use the available functions when asked about requirements, tests, or deployment."
    )

    interactions = [
        "Save requirement US-101: title='Enable CIT payment toggle', ac='Given a CIT-eligible transaction, when Enable-CIT is ON, then route to CIT gateway and return gateway reference ID'",
        "Generate BDD tests for US-101",
        "Check if payment-service is ready to deploy",
        "Generate release notes for version 2.4.0 with PRs: [{\"title\": \"Add Enable-CIT toggle\", \"type\": \"feature\"}, {\"title\": \"Fix NPE in PaymentProcessor\", \"type\": \"bugfix\"}, {\"title\": \"Remove legacy PayPal API v1\", \"type\": \"feature\", \"breaking\": true}]",
    ]

    settings = OpenAIChatPromptExecutionSettings(
        service_id="chat",
        function_choice_behavior=FunctionChoiceBehavior.Auto(),
        max_tokens=800
    )

    for user_msg in interactions:
        chat.add_user_message(user_msg)
        response = await kernel.get_service("chat").get_chat_message_content(
            chat_history=chat, settings=settings, kernel=kernel
        )
        print(f"\nUser: {user_msg[:80]}...")
        print(f"SK: {response}\n{'='*70}")
        chat.add_assistant_message(str(response))

asyncio.run(main())
```

### Free Tier / Pricing

- **Semantic Kernel SDK:** 100% free, MIT license (Python, C#, Java)
- **Azure OpenAI:** Pay-per-token; free tier via GitHub Models (gpt-4o-mini, unlimited)
- **Azure AI Search (for vector memory):** Free tier: 1 index, 50MB storage

### Best Use Case for SDLC Automation

**Enterprise .NET Teams:** SK is the natural choice for teams already using Azure DevOps and .NET. Build a Copilot-style assistant that calls Azure DevOps APIs as plugins (create sprint, close ticket, deploy pipeline), uses Azure OpenAI, and respects existing Active Directory permissions.

---

## 3.14 Flowise

### What is Flowise

Flowise is an open-source **drag-and-drop UI** for building LLM workflows. You compose LangChain/LlamaIndex components visually in a browser, and Flowise exposes each flow as a REST API endpoint. No Python required for basic flows. Ideal for non-developers, rapid prototyping, and letting business teams build their own AI tools.

**When to choose Flowise vs alternatives:**

| Scenario | Flowise | n8n | Dify |
|----------|---------|-----|------|
| Non-developer audience | ✅ Best | Good | Good |
| LangChain component access | ✅ Best | Limited | Limited |
| REST API auto-generation | ✅ Best | Good | Good |
| Business process automation | Limited | ✅ Best | Good |
| White-label / embed | ✅ Built-in | Limited | Good |

### Installation

```bash
# Option 1: npm (recommended)
npm install -g flowise
flowise start
# Runs at http://localhost:3000

# Option 2: Docker
docker run -d -p 3000:3000 \
  -v ~/.flowise:/root/.flowise \
  --name flowise flowiseai/flowise

# Option 3: pip (Python wrapper)
pip install flowise
```

### Core Concepts

#### 1. Chatflow — visual pipeline = REST API

Each Chatflow you build in the UI is automatically available as:
```
POST http://localhost:3000/api/v1/prediction/{chatflow-id}
```

#### 2. REST API Integration

```python
# pip install requests
import requests, json

FLOWISE_URL = "http://localhost:3000"
CHATFLOW_ID = "your-chatflow-id-from-ui"  # copy from Flowise UI

def ask_flowise(question: str, session_id: str = "default") -> str:
    """Call any Flowise chatflow as a REST API."""
    response = requests.post(
        f"{FLOWISE_URL}/api/v1/prediction/{CHATFLOW_ID}",
        json={
            "question": question,
            "overrideConfig": {
                "sessionId": session_id,   # maintains conversation history
                "temperature": 0.3,
            }
        },
        headers={"Authorization": f"Bearer {FLOWISE_API_KEY}"},  # if auth enabled
        timeout=60
    )
    response.raise_for_status()
    return response.json()["text"]

# Usage
answer = ask_flowise("What does Enable-CIT toggle do?", session_id="user-123")
print(answer)
```

#### 3. Upsert API — populate vector stores from code

```python
import requests

def upload_documents_to_flowise(document_store_id: str, texts: list[str], metadata: list[dict]) -> dict:
    """Push documents into a Flowise Document Store via API."""
    response = requests.post(
        f"{FLOWISE_URL}/api/v1/document-store/upsert/{document_store_id}",
        json={
            "docs": [
                {"pageContent": text, "metadata": meta}
                for text, meta in zip(texts, metadata)
            ]
        }
    )
    return response.json()

# Upsert your toggle documentation
result = upload_documents_to_flowise(
    document_store_id="abc-123",
    texts=[
        "Enable-CIT routes payments through CIT gateway with 15% lower fees.",
        "BypassFraudCheck skips fraud detection. Never enable in production.",
    ],
    metadata=[
        {"source": "toggle-registry", "toggle": "Enable-CIT"},
        {"source": "toggle-registry", "toggle": "BypassFraudCheck"},
    ]
)
print(result)
```

#### 4. Streaming API

```python
import requests, json

def stream_flowise(question: str, chatflow_id: str):
    """Stream tokens from a Flowise chatflow."""
    with requests.post(
        f"{FLOWISE_URL}/api/v1/prediction/{chatflow_id}",
        json={"question": question, "streaming": True},
        stream=True,
        timeout=120
    ) as response:
        for line in response.iter_lines():
            if line:
                decoded = line.decode("utf-8")
                if decoded.startswith("data: "):
                    data = decoded[6:]
                    if data != "[DONE]":
                        try:
                            chunk = json.loads(data)
                            print(chunk.get("token", ""), end="", flush=True)
                        except json.JSONDecodeError:
                            pass
        print()

stream_flowise("Explain the architecture of our payment service", chatflow_id=CHATFLOW_ID)
```

### Example 1 — Basic: Call Flowise from CI/CD Pipeline

```python
# Use in GitHub Actions, Jenkins, or any CI/CD tool
# pip install requests
import requests, sys, os

def analyze_pr_with_flowise(pr_diff: str, chatflow_id: str) -> dict:
    """Send a PR diff to a Flowise code review chatflow."""
    flowise_url = os.environ.get("FLOWISE_URL", "http://localhost:3000")
    api_key     = os.environ.get("FLOWISE_API_KEY", "")

    payload = {
        "question": f"Review this PR diff and identify issues:\n\n```diff\n{pr_diff}\n```\n\nProvide: severity, issue description, line number, fix suggestion.",
        "overrideConfig": {"temperature": 0}
    }

    resp = requests.post(
        f"{flowise_url}/api/v1/prediction/{chatflow_id}",
        json=payload,
        headers={"Authorization": f"Bearer {api_key}"} if api_key else {},
        timeout=90
    )
    resp.raise_for_status()
    return resp.json()

# Example usage in CI/CD
sample_diff = """+def process_payment(amount, user_id):
+    query = f"SELECT * FROM accounts WHERE id={user_id}"  # SQL injection!
+    password = "hardcoded_secret_123"                      # Hardcoded secret
+    eval(open("config.py").read())                         # Code injection
+    return amount * 1.1"""

if __name__ == "__main__":
    chatflow_id = os.environ.get("CODE_REVIEW_CHATFLOW_ID", "demo-id")
    result = analyze_pr_with_flowise(sample_diff, chatflow_id)
    print("Code Review Result:")
    print(result.get("text", result))
    # Exit 1 if critical issues found (for CI/CD blocking)
    if "CRITICAL" in result.get("text", "").upper():
        sys.exit(1)
```

### Example 2 — Intermediate: Flowise Embedded Chatbot in Web App

```html
<!-- Add Flowise chatbot widget to any HTML page -->
<!DOCTYPE html>
<html>
<head><title>Toggle Knowledge Base</title></head>
<body>
  <h1>Feature Toggle Assistant</h1>
  <p>Ask any question about our feature toggles.</p>

  <!-- Flowise full-page chat -->
  <flowise-fullchatbot></flowise-fullchatbot>

  <script type="module">
    import Chatbot from "https://cdn.jsdelivr.net/npm/flowise-embed/dist/web.js";
    Chatbot.initFull({
      chatflowid: "your-chatflow-id",
      apiHost: "http://localhost:3000",
      chatflowConfig: {
        sessionId: crypto.randomUUID(),    // unique session per user
        temperature: 0.2,
        systemMessage: "You are a feature toggle expert for our payment system."
      },
      theme: {
        button: { backgroundColor: "#0d47a1", right: 20, bottom: 20 },
        chatWindow: {
          title: "Toggle Assistant",
          welcomeMessage: "Hello! Ask me anything about our feature toggles.",
          backgroundColor: "#ffffff",
          height: 700, width: 450,
          fontSize: 14,
          poweredByTextColor: "#999",
          botMessage: { backgroundColor: "#f0f0f0", textColor: "#222" },
          userMessage: { backgroundColor: "#0d47a1", textColor: "#fff" },
        }
      }
    });
  </script>
</body>
</html>
```

### Example 3 — Advanced: Flowise API Gateway with Authentication + Rate Limiting

```python
# pip install requests fastapi uvicorn pydantic
"""
Production wrapper: adds auth, rate limiting, logging, and fallback
around a Flowise chatflow endpoint.
"""
from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests, time, os, json
from collections import defaultdict
from datetime import datetime

app = FastAPI(title="Toggle Assistant API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["POST"])

FLOWISE_URL   = os.environ.get("FLOWISE_URL", "http://localhost:3000")
CHATFLOW_ID   = os.environ.get("CHATFLOW_ID", "")
VALID_API_KEYS = set(os.environ.get("VALID_API_KEYS", "demo-key-123").split(","))
rate_limit_store: dict[str, list[float]] = defaultdict(list)  # key -> timestamps

class QuestionRequest(BaseModel):
    question: str
    session_id: str = "default"
    max_tokens: int = 500

class AnswerResponse(BaseModel):
    answer: str
    session_id: str
    latency_ms: float
    timestamp: str

def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key not in VALID_API_KEYS:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key

def check_rate_limit(api_key: str, max_per_minute: int = 10):
    now = time.time()
    calls = [t for t in rate_limit_store[api_key] if now - t < 60]
    rate_limit_store[api_key] = calls
    if len(calls) >= max_per_minute:
        raise HTTPException(status_code=429, detail=f"Rate limit: {max_per_minute} requests/minute")
    rate_limit_store[api_key].append(now)

@app.post("/ask", response_model=AnswerResponse)
async def ask(req: QuestionRequest, api_key: str = Depends(verify_api_key)):
    check_rate_limit(api_key)
    start = time.time()
    try:
        resp = requests.post(
            f"{FLOWISE_URL}/api/v1/prediction/{CHATFLOW_ID}",
            json={"question": req.question, "overrideConfig": {
                "sessionId": req.session_id,
                "maxTokens": req.max_tokens
            }},
            timeout=60
        )
        resp.raise_for_status()
        answer = resp.json().get("text", "No answer returned")
    except requests.exceptions.Timeout:
        raise HTTPException(status_code=504, detail="Flowise timeout — try again")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Flowise error: {e}")

    return AnswerResponse(
        answer=answer,
        session_id=req.session_id,
        latency_ms=round((time.time() - start) * 1000, 2),
        timestamp=datetime.utcnow().isoformat()
    )

# Run: uvicorn filename:app --port 8080
```

### Free Tier / Pricing

- **Flowise (self-hosted):** 100% free, Apache 2.0 license
- **Flowise Cloud:** Free tier (limited flows); Pro from $35/month
- **Docker deployment:** Free, unlimited flows and users

### Best Use Case for SDLC Automation

**No-Code Tooling for QA/BA Teams:** Let QA engineers build their own "test case generator" chatflows by connecting Confluence loader → GPT → output, without writing Python. Business analysts can create requirement extraction flows. IT teams expose these as REST APIs consumed by existing tools.

---

## 3.15 n8n + AI

### What is n8n + AI

n8n is an open-source workflow automation platform (like Zapier/Make, but self-hostable). Its **AI nodes** (LangChain-powered) let you embed LLMs, vector stores, and agents directly into business workflows alongside 400+ integrations (Slack, GitHub, Jira, databases, APIs). Unlike pure AI frameworks, n8n excels when you need AI _inside_ existing business processes with webhook triggers, schedules, and error handling.

**When to choose n8n vs alternatives:**

| Scenario | n8n | Flowise | LangChain |
|----------|-----|---------|-----------|
| Integrate AI into existing biz workflows | ✅ Best | Limited | Code only |
| Webhook/schedule triggers | ✅ Best | Limited | Code only |
| Non-developer automation | ✅ Best | ✅ Best | Poor |
| Complex LLM pipelines | Limited | Good | ✅ Best |
| 400+ app integrations | ✅ Best | Limited | Limited |

### Installation

```bash
# Option 1: npx (quickest)
npx n8n
# Runs at http://localhost:5678

# Option 2: Docker
docker run -d -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  --name n8n n8nio/n8n

# Option 3: npm global
npm install -g n8n && n8n start
```

### Core Concepts

#### 1. Workflows — triggers + nodes + connections

An n8n workflow is JSON. You can export/import/version-control it.

#### 2. AI Agent Node

The AI Agent node (powered by LangChain) accepts:
- **System Prompt:** defines agent behavior
- **Tools:** other n8n nodes exposed as tools (HTTP Request, Jira, Slack, etc.)
- **Memory:** window buffer, summary, vector store
- **Model:** any OpenAI-compatible endpoint

#### 3. REST API — trigger workflows from code

```python
import requests, os

N8N_URL     = os.environ.get("N8N_URL", "http://localhost:5678")
WEBHOOK_URL = f"{N8N_URL}/webhook/code-review"   # set in n8n webhook node

def trigger_n8n_code_review(pr_number: int, repo: str, diff: str) -> dict:
    """Trigger n8n AI workflow from Python code."""
    resp = requests.post(
        WEBHOOK_URL,
        json={"pr_number": pr_number, "repo": repo, "diff": diff},
        headers={"Content-Type": "application/json"},
        timeout=120
    )
    resp.raise_for_status()
    return resp.json()

result = trigger_n8n_code_review(
    pr_number=42,
    repo="org/payment-service",
    diff="+def calculate(a, b):\n+    return eval(f'{a}+{b}')  # unsafe!"
)
print(result)
```

#### 4. n8n Public API — manage workflows programmatically

```python
import requests, os

N8N_API_KEY = os.environ["N8N_API_KEY"]
N8N_URL     = os.environ.get("N8N_URL", "http://localhost:5678")
HEADERS     = {"X-N8N-API-KEY": N8N_API_KEY, "Content-Type": "application/json"}

def list_workflows() -> list:
    return requests.get(f"{N8N_URL}/api/v1/workflows", headers=HEADERS).json()["data"]

def execute_workflow(workflow_id: str, data: dict) -> dict:
    return requests.post(
        f"{N8N_URL}/api/v1/workflows/{workflow_id}/run",
        json={"startNodes": [], "runData": {}, "pinData": {}, "workflowData": data},
        headers=HEADERS
    ).json()

def get_execution_result(execution_id: str) -> dict:
    return requests.get(
        f"{N8N_URL}/api/v1/executions/{execution_id}",
        headers=HEADERS
    ).json()
```

### Example 1 — Basic: Export an n8n AI Workflow as JSON (ready to import)

```json
{
  "name": "PR Code Review AI",
  "nodes": [
    {
      "id": "1",
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "position": [200, 300],
      "parameters": {
        "path": "code-review",
        "httpMethod": "POST",
        "responseMode": "responseNode"
      }
    },
    {
      "id": "2",
      "name": "AI Agent",
      "type": "@n8n/n8n-nodes-langchain.agent",
      "position": [450, 300],
      "parameters": {
        "systemMessage": "You are an expert code reviewer. Analyze the PR diff provided. Return JSON: {issues: [{severity, description, line, fix}], overall_score: 1-10, approve: boolean}",
        "promptType": "define",
        "text": "=Review this PR diff from repo {{ $json.repo }}, PR #{{ $json.pr_number }}:\n\n{{ $json.diff }}"
      }
    },
    {
      "id": "3",
      "name": "Post to Slack",
      "type": "n8n-nodes-base.slack",
      "position": [700, 300],
      "parameters": {
        "operation": "post",
        "channel": "#code-reviews",
        "text": "=PR #{{ $('Webhook Trigger').item.json.pr_number }} Review:\n{{ $json.output }}"
      }
    }
  ],
  "connections": {
    "Webhook Trigger": {"main": [[{"node": "AI Agent", "type": "main", "index": 0}]]},
    "AI Agent": {"main": [[{"node": "Post to Slack", "type": "main", "index": 0}]]}
  }
}
```

### Example 2 — Intermediate: Python Client for n8n SDLC Automation

```python
# pip install requests
"""
Programmatic interface to n8n workflows for SDLC automation.
Assumes these workflows are already configured in n8n:
  - /webhook/standup-summary     (AI node → Slack)
  - /webhook/jira-ticket-create  (AI node → Jira)
  - /webhook/deploy-approval     (AI node → approval → deploy)
"""
import requests, os, time
from dataclasses import dataclass

N8N_URL = os.environ.get("N8N_URL", "http://localhost:5678")

@dataclass
class N8NWorkflowClient:
    base_url: str
    timeout: int = 120

    def _post(self, path: str, data: dict) -> dict:
        resp = requests.post(f"{self.base_url}/webhook/{path}", json=data, timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def summarize_standup(self, channel: str, hours: int = 24) -> str:
        """Trigger n8n workflow: fetch Slack messages → AI summary → post to channel."""
        result = self._post("standup-summary", {"channel": channel, "hours": hours})
        return result.get("summary", "No summary generated")

    def create_jira_ticket(self, title: str, description: str, priority: str = "Medium") -> str:
        """Trigger n8n workflow: AI refines ticket → create in Jira → return ticket ID."""
        result = self._post("jira-ticket-create", {
            "title": title, "description": description, "priority": priority
        })
        return result.get("ticket_id", "Unknown")

    def request_deployment(self, service: str, version: str, environment: str) -> dict:
        """Trigger n8n deployment approval workflow."""
        result = self._post("deploy-approval", {
            "service": service, "version": version, "environment": environment,
            "requestor": os.environ.get("USER", "ci-bot")
        })
        return result

# Usage
client = N8NWorkflowClient(base_url=N8N_URL)

# Daily standup summary
summary = client.summarize_standup(channel="standup", hours=24)
print(f"Today's standup summary:\n{summary}")

# Create a ticket from a bug report
ticket_id = client.create_jira_ticket(
    title="Payment service NPE on null amount",
    description="NullPointerException thrown in PaymentProcessor.calculate() when amount is null. "
                "Stack trace: ...",
    priority="High"
)
print(f"Created Jira ticket: {ticket_id}")

# Request deployment
deploy_result = client.request_deployment(
    service="payment-service", version="2.4.0", environment="staging"
)
print(f"Deployment request: {deploy_result}")
```

### Example 3 — Advanced: n8n Workflow Definition via API (Infrastructure as Code)

```python
# pip install requests
"""
Create n8n workflows programmatically — treat n8n config as code.
This creates a complete CI/CD AI review workflow via API.
"""
import requests, os, json

N8N_URL     = os.environ.get("N8N_URL", "http://localhost:5678")
N8N_API_KEY = os.environ.get("N8N_API_KEY", "")
HEADERS     = {"X-N8N-API-KEY": N8N_API_KEY, "Content-Type": "application/json"}

SDLC_WORKFLOW = {
    "name": "SDLC AI Automation Suite",
    "active": True,
    "settings": {"executionOrder": "v1"},
    "nodes": [
        {
            "id": "trigger",
            "name": "GitHub PR Webhook",
            "type": "n8n-nodes-base.githubTrigger",
            "parameters": {
                "owner": os.environ.get("GITHUB_ORG", "my-org"),
                "repository": "payment-service",
                "events": ["pull_request"],
                "filters": {"action": ["opened", "synchronize"]}
            },
            "position": [100, 300]
        },
        {
            "id": "fetch_diff",
            "name": "Fetch PR Diff",
            "type": "n8n-nodes-base.httpRequest",
            "parameters": {
                "method": "GET",
                "url": "=https://api.github.com/repos/{{ $json.repository.full_name }}/pulls/{{ $json.number }}/files",
                "authentication": "genericCredentialType",
                "genericAuthType": "httpHeaderAuth"
            },
            "position": [300, 300]
        },
        {
            "id": "ai_review",
            "name": "AI Code Review",
            "type": "@n8n/n8n-nodes-langchain.agent",
            "parameters": {
                "systemMessage": """You are a senior software engineer performing code review.
Analyze the changed files and return a JSON report:
{
  "approved": boolean,
  "score": 1-10,
  "critical_issues": [{"file", "line", "issue", "fix"}],
  "suggestions": ["..."],
  "security_concerns": ["..."],
  "summary": "one-line summary"
}""",
                "text": "=Review these file changes:\n{{ JSON.stringify($json) }}"
            },
            "position": [550, 300]
        },
        {
            "id": "post_comment",
            "name": "Post GitHub Comment",
            "type": "n8n-nodes-base.github",
            "parameters": {
                "operation": "createComment",
                "owner": "={{ $('GitHub PR Webhook').item.json.repository.owner.login }}",
                "repository": "={{ $('GitHub PR Webhook').item.json.repository.name }}",
                "issueNumber": "={{ $('GitHub PR Webhook').item.json.number }}",
                "body": "=## 🤖 AI Code Review\n\n**Score:** {{ JSON.parse($json.output).score }}/10\n**Decision:** {{ JSON.parse($json.output).approved ? '✅ Approved' : '❌ Changes Requested' }}\n\n{{ $json.output }}"
            },
            "position": [800, 300]
        }
    ],
    "connections": {
        "GitHub PR Webhook": {"main": [[{"node": "Fetch PR Diff", "type": "main", "index": 0}]]},
        "Fetch PR Diff":     {"main": [[{"node": "AI Code Review", "type": "main", "index": 0}]]},
        "AI Code Review":    {"main": [[{"node": "Post GitHub Comment", "type": "main", "index": 0}]]}
    }
}

def deploy_workflow(workflow: dict) -> str:
    """Create a new workflow in n8n via API."""
    resp = requests.post(f"{N8N_URL}/api/v1/workflows", json=workflow, headers=HEADERS)
    resp.raise_for_status()
    workflow_id = resp.json()["id"]
    # Activate it
    requests.patch(f"{N8N_URL}/api/v1/workflows/{workflow_id}", json={"active": True}, headers=HEADERS)
    return workflow_id

workflow_id = deploy_workflow(SDLC_WORKFLOW)
print(f"Deployed workflow: {N8N_URL}/workflow/{workflow_id}")
```

### Free Tier / Pricing

- **n8n Community (self-hosted):** Free, unlimited workflows and executions
- **n8n Cloud:** Free tier (5 workflows, 5 executions/month); Starter $24/month
- **AI nodes:** Require your own LLM API keys (no additional cost)

### Best Use Case for SDLC Automation

**GitHub Actions Complement:** n8n excels at the cross-system glue code: when a GitHub PR is opened, trigger AI review, post result to Jira, notify Slack, update Confluence, and schedule a deployment — all without writing custom integration code.

---

## 3.16 Dify

### What is Dify

Dify is an open-source **LLMOps platform** that combines workflow automation, RAG pipelines, app builder, and API management in one UI. Like Flowise but more production-oriented: it has built-in observability, versioning, A/B testing of prompts, and a production-grade API layer. Teams use it to build and manage LLM apps without deep ML expertise.

**When to choose Dify vs alternatives:**

| Scenario | Dify | Flowise | Langfuse |
|----------|------|---------|----------|
| Full LLMOps platform | ✅ Best | Limited | Observability only |
| Prompt versioning + A/B test | ✅ Best | Limited | ✅ Good |
| Built-in RAG + annotation | ✅ Best | Limited | No |
| API + SDK for custom apps | ✅ Best | Good | No |
| Visual workflow builder | ✅ Best | ✅ Best | No |

### Installation

```bash
# Docker Compose (recommended — includes all services)
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env
docker compose up -d
# Access at http://localhost/

# pip SDK for calling Dify APIs from Python
pip install dify-client
```

### Core Concepts

#### 1. Applications — 4 app types

- **Chatbot:** conversational interface with memory
- **Text Generator:** single-turn input → output
- **Agent:** tool-calling with internet/API access
- **Workflow:** multi-step pipeline (like n8n for LLMs)

#### 2. Knowledge Base — built-in RAG

```python
# pip install dify-client
from dify_client import DifyClient

client = DifyClient(api_key=os.environ["DIFY_API_KEY"], base_url="http://localhost/v1")

# Chat with a Dify app (chatbot)
response = client.chat_message(
    inputs={},
    query="What does the Enable-CIT toggle do?",
    user="developer-1",
    conversation_id=None,    # None = new conversation
    response_mode="blocking"
)
print(response["answer"])
conversation_id = response["conversation_id"]  # use for follow-ups

# Continue conversation
follow_up = client.chat_message(
    inputs={}, query="What is the risk level?",
    user="developer-1", conversation_id=conversation_id
)
```

#### 3. Workflow API — text generation apps

```python
from dify_client import DifyClient
import os

client = DifyClient(api_key=os.environ["DIFY_WORKFLOW_KEY"], base_url="http://localhost/v1")

# Run a workflow (e.g., "Generate Test Cases" workflow)
result = client.run_workflow(
    inputs={
        "code": """def calculate_interest(principal, rate, years):
    if years <= 0: raise ValueError("Years must be positive")
    return principal * (1 + rate) ** years""",
        "language": "python",
        "test_framework": "pytest"
    },
    user="ci-bot",
    response_mode="blocking"
)
print(result["data"]["outputs"]["test_code"])
```

#### 4. Streaming Response

```python
from dify_client import DifyClient

client = DifyClient(api_key=os.environ["DIFY_API_KEY"], base_url="http://localhost/v1")

# Stream tokens for real-time display
for chunk in client.chat_message(
    inputs={},
    query="Explain the payment service architecture",
    user="dev-1",
    response_mode="streaming"
):
    if chunk.get("event") == "message":
        print(chunk.get("answer", ""), end="", flush=True)
    elif chunk.get("event") == "message_end":
        print(f"\n[Usage: {chunk.get('metadata', {}).get('usage', {})}]")
```

### Example 1 — Basic: Document Q&A via Dify API

```python
# pip install dify-client requests
"""
Query a Dify knowledge base app from Python.
Prerequisite: create a Chatbot app in Dify UI, connect a Knowledge Base dataset.
"""
import os
from dify_client import DifyClient

DIFY_URL = os.environ.get("DIFY_URL", "http://localhost/v1")
DIFY_KEY = os.environ["DIFY_APP_API_KEY"]

client = DifyClient(api_key=DIFY_KEY, base_url=DIFY_URL)

def query_knowledge_base(question: str, user_id: str = "dev") -> str:
    response = client.chat_message(
        inputs={},
        query=question,
        user=user_id,
        response_mode="blocking",
        conversation_id=None
    )
    answer = response.get("answer", "No answer")
    sources = response.get("metadata", {}).get("retriever_resources", [])
    if sources:
        answer += f"\n\nSources: {', '.join(s['document_name'] for s in sources[:3])}"
    return answer

# SDLC use cases
questions = [
    "What is our definition of done?",
    "How do we handle hotfix deployments?",
    "What is the SLA for P1 incidents?",
]
for q in questions:
    print(f"Q: {q}")
    print(f"A: {query_knowledge_base(q)}\n")
```

### Example 2 — Intermediate: Dify Workflow for Code Generation + Testing

```python
# pip install dify-client
"""
Uses a Dify Workflow app that:
1. Takes code description as input
2. Generates implementation code (LLM node)
3. Generates unit tests (LLM node)
4. Runs code quality checks (code executor node)
5. Returns formatted output
"""
import os, json
from dify_client import DifyClient

client = DifyClient(
    api_key=os.environ["DIFY_WORKFLOW_API_KEY"],
    base_url=os.environ.get("DIFY_URL", "http://localhost/v1")
)

def generate_feature(description: str, language: str = "python") -> dict:
    """Call Dify workflow to generate code + tests from a feature description."""
    result = client.run_workflow(
        inputs={
            "feature_description": description,
            "programming_language": language,
            "coding_standards": "PEP8 for Python, include type hints, docstrings, error handling"
        },
        user="code-gen-bot",
        response_mode="blocking"
    )

    if result.get("data", {}).get("status") != "succeeded":
        raise RuntimeError(f"Workflow failed: {result}")

    outputs = result["data"]["outputs"]
    return {
        "implementation": outputs.get("implementation_code", ""),
        "tests":          outputs.get("test_code", ""),
        "review_notes":   outputs.get("review_notes", ""),
        "token_usage":    result["data"].get("total_tokens", 0)
    }

# Generate a feature
feature = generate_feature(
    description="Create a retry decorator that retries a function up to N times with exponential backoff on specified exceptions",
    language="python"
)
print("=== Implementation ===")
print(feature["implementation"])
print("\n=== Tests ===")
print(feature["tests"])
print(f"\nTokens used: {feature['token_usage']}")
```

### Example 3 — Advanced: Dify Dataset Management + App Factory

```python
# pip install requests
"""
Build a multi-tenant LLM app factory using Dify's admin API:
- Create datasets (knowledge bases) per team
- Upload documents programmatically
- Create chatbot apps bound to team datasets
- Generate API keys per team
"""
import requests, os, json, time

DIFY_CONSOLE_URL = os.environ.get("DIFY_CONSOLE_URL", "http://localhost")
EMAIL    = os.environ["DIFY_ADMIN_EMAIL"]
PASSWORD = os.environ["DIFY_ADMIN_PASSWORD"]

def get_dify_token() -> str:
    """Get admin session token."""
    resp = requests.post(f"{DIFY_CONSOLE_URL}/console/api/login",
                         json={"email": EMAIL, "password": PASSWORD, "remember_me": True})
    resp.raise_for_status()
    return resp.json()["data"]["access_token"]

def create_dataset(token: str, name: str, description: str) -> str:
    """Create a new knowledge base dataset."""
    resp = requests.post(
        f"{DIFY_CONSOLE_URL}/console/api/datasets",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": name, "description": description, "indexing_technique": "high_quality"}
    )
    resp.raise_for_status()
    return resp.json()["id"]

def upload_document(token: str, dataset_id: str, content: str, doc_name: str) -> str:
    """Upload a text document to a dataset."""
    resp = requests.post(
        f"{DIFY_CONSOLE_URL}/console/api/datasets/{dataset_id}/document/create_by_text",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": doc_name,
            "text": content,
            "indexing_technique": "high_quality",
            "process_rule": {"mode": "automatic"}
        }
    )
    resp.raise_for_status()
    return resp.json()["document"]["id"]

def provision_team_kb(team_name: str, documents: list[dict]) -> dict:
    """Provision a full knowledge base for a team."""
    token = get_dify_token()
    dataset_id = create_dataset(token, f"{team_name}-knowledge-base",
                                f"Knowledge base for {team_name} team")
    doc_ids = []
    for doc in documents:
        doc_id = upload_document(token, dataset_id, doc["content"], doc["name"])
        doc_ids.append(doc_id)
        time.sleep(1)  # rate limit

    return {"team": team_name, "dataset_id": dataset_id, "document_count": len(doc_ids)}

# Provision knowledge bases for multiple teams
teams = [
    {
        "name": "payments-team",
        "documents": [
            {"name": "Toggle Registry", "content": "Enable-CIT: routes to CIT gateway. Risk: MEDIUM."},
            {"name": "Runbook", "content": "For P1 incidents: page on-call via PagerDuty first."},
        ]
    },
    {
        "name": "platform-team",
        "documents": [
            {"name": "Architecture ADR", "content": "All services must expose /health and /metrics endpoints."},
        ]
    }
]

for team in teams:
    result = provision_team_kb(team["name"], team["documents"])
    print(f"Provisioned: {result}")
```

### Free Tier / Pricing

- **Dify Community (self-hosted):** Free, all features, unlimited apps
- **Dify Cloud:** Free tier (200 msg/day, limited knowledge base); Pro $59/month
- **Enterprise:** Custom pricing with SSO, audit logs, dedicated support

### Best Use Case for SDLC Automation

**Team-Specific AI Assistants:** Each engineering team gets their own Dify app with knowledge base fed from their Confluence space, Jira project, and GitHub repos. PMs use the chatbot to ask about sprint status; devs query architecture decisions; QA finds test patterns.

---

## 3.17 Agno (formerly Phidata)

### What is Agno

Agno (rebranded from Phidata in 2024) is a Python framework for building **multi-modal, knowledge-aware agents**. Its standout features: native support for structured outputs, built-in knowledge bases with multiple storage backends, team-based multi-agent orchestration, and first-class support for images/audio/video alongside text. Agno agents are designed to be simple to define yet powerful.

**When to choose Agno vs alternatives:**

| Scenario | Agno | CrewAI | LangGraph |
|----------|------|--------|-----------|
| Multi-modal agents (images/video) | ✅ Best | Limited | Limited |
| Simple team orchestration | ✅ Best | Good | Complex |
| Built-in knowledge + storage | ✅ Best | Manual | Manual |
| Complex state machines | Limited | Limited | ✅ Best |
| Structured output + Pydantic | ✅ Best | Good | Good |

### Installation

```bash
pip install agno
# Storage backends
pip install agno[pgvector]    # PostgreSQL + pgvector
pip install agno[qdrant]      # Qdrant vector DB
pip install agno[lancedb]     # LanceDB (embedded, fast)
# Models
pip install agno openai anthropic groq
```

### Core Concepts

#### 1. Agent — the core unit

```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools.duckduckgo import DuckDuckGoTools
import os

agent = Agent(
    model=OpenAIChat(
        id="gpt-4o-mini",
        base_url="https://models.inference.ai.azure.com",
        api_key=os.environ["GITHUB_TOKEN"]
    ),
    description="You are a senior software engineer specialising in payment systems.",
    instructions=[
        "Always cite sources when referencing external information",
        "Provide code examples when explaining technical concepts",
        "Flag security concerns with ⚠️ SECURITY",
    ],
    tools=[DuckDuckGoTools()],
    show_tool_calls=True,
    markdown=True,
)
agent.print_response("What are best practices for feature toggle cleanup?")
```

#### 2. Knowledge Base — connects agents to documents

```python
from agno.agent import Agent
from agno.knowledge.pdf import PDFKnowledgeBase
from agno.knowledge.text import TextKnowledgeBase
from agno.vectordb.lancedb import LanceDb, SearchType
from agno.models.openai import OpenAIChat
from agno.embedder.openai import OpenAIEmbedder

# LanceDB-backed knowledge base (fast, embedded, no server needed)
kb = TextKnowledgeBase(
    path="./docs",    # directory of .txt files
    vector_db=LanceDb(
        uri="./lance_db",
        table_name="toggle_docs",
        search_type=SearchType.hybrid,
        embedder=OpenAIEmbedder(id="text-embedding-3-small",
                                base_url="https://models.inference.ai.azure.com",
                                api_key=os.environ["GITHUB_TOKEN"])
    ),
    num_documents=5
)

agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini", base_url="https://models.inference.ai.azure.com",
                     api_key=os.environ["GITHUB_TOKEN"]),
    knowledge=kb,   # agent auto-searches KB on every query
    search_knowledge=True,
    description="Feature toggle expert with access to our toggle documentation"
)
# Load docs into KB (first run only)
kb.load(recreate=False)
agent.print_response("What are all the payment-related toggles?")
```

#### 3. Storage — persistent agent memory

```python
from agno.storage.sqlite import SqliteStorage
from agno.agent import Agent

# SQLite storage — persists sessions across runs
storage = SqliteStorage(table_name="agent_sessions", db_file="agent_memory.db")

agent = Agent(
    model=...,
    storage=storage,
    add_history_to_messages=True,   # inject past messages
    num_history_responses=5,        # how many past exchanges to include
    session_id="dev-team-session-1"  # shared session across team
)
```

#### 4. Structured Outputs

```python
from agno.agent import Agent
from pydantic import BaseModel, Field
from typing import List

class SecurityIssue(BaseModel):
    severity:    str = Field(description="CRITICAL, HIGH, MEDIUM, LOW")
    type:        str = Field(description="e.g., SQL Injection, XSS, Hardcoded Secret")
    file_path:   str
    line_number: int
    description: str
    fix:         str = Field(description="Recommended fix")

class SecurityReport(BaseModel):
    overall_risk: str = Field(description="CRITICAL, HIGH, MEDIUM, LOW, CLEAN")
    issues: List[SecurityIssue]
    summary: str
    approve_for_merge: bool

agent = Agent(
    model=...,
    response_model=SecurityReport,    # enforces Pydantic output schema
    structured_outputs=True,
)

code = "password = 'abc123'\nquery = f'SELECT * FROM users WHERE id={user_id}'"
result: SecurityReport = agent.run(f"Security review this code:\n{code}")
print(f"Risk: {result.content.overall_risk}")
print(f"Issues: {len(result.content.issues)}")
print(f"Approve: {result.content.approve_for_merge}")
```

#### 5. Teams — multi-agent orchestration

```python
from agno.agent import Agent
from agno.team import Team

researcher = Agent(name="Researcher", role="Research current best practices",
                   tools=[DuckDuckGoTools()], model=...)
analyst    = Agent(name="Analyst",    role="Analyze findings and identify patterns", model=...)
writer     = Agent(name="Writer",     role="Write clear, actionable documentation", model=...)

team = Team(
    name="Documentation Team",
    agents=[researcher, analyst, writer],
    mode="coordinate",     # "coordinate" (supervisor), "collaborate" (all agents respond), "route" (pick best agent)
    model=...,             # supervisor model
    markdown=True,
    show_tool_calls=True,
)
team.print_response("Create a developer guide for feature toggle best practices")
```

### Example 1 — Basic: Agent with Custom Tools

```python
# pip install agno openai
import os
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools import tool

@tool
def get_toggle_status(toggle_name: str) -> str:
    """Get the current status of a feature toggle from the registry."""
    registry = {
        "Enable-CIT":       {"status": "ON",  "env": "production", "risk": "MEDIUM"},
        "EnableNewUI":      {"status": "ON",  "env": "staging",    "risk": "LOW"},
        "BypassFraudCheck": {"status": "OFF", "env": "all",        "risk": "CRITICAL"},
    }
    info = registry.get(toggle_name, {"status": "UNKNOWN", "env": "N/A", "risk": "N/A"})
    return f"{toggle_name}: status={info['status']}, env={info['env']}, risk={info['risk']}"

@tool
def list_high_risk_toggles() -> str:
    """List all toggles with HIGH or CRITICAL risk level."""
    return "HIGH/CRITICAL toggles: BypassFraudCheck (CRITICAL, OFF), Enable-DirectDebit (HIGH, ON)"

agent = Agent(
    model=OpenAIChat(id="gpt-4o-mini",
                     base_url="https://models.inference.ai.azure.com",
                     api_key=os.environ["GITHUB_TOKEN"]),
    tools=[get_toggle_status, list_high_risk_toggles],
    description="Feature toggle management assistant for payment systems",
    instructions=["Always check risk level before recommending a toggle change",
                  "Never recommend enabling CRITICAL risk toggles in production"],
    show_tool_calls=True,
    markdown=True,
)

agent.print_response("What is the status of Enable-CIT? Is it safe to turn it off?")
agent.print_response("Show me all high-risk toggles and give me a risk summary")
```

### Example 2 — Intermediate: Multi-Modal Agent (Code + Image Analysis)

```python
# pip install agno openai
import os, base64
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.media import Image

agent = Agent(
    model=OpenAIChat(id="gpt-4o",    # GPT-4o supports vision
                     base_url="https://models.inference.ai.azure.com",
                     api_key=os.environ["GITHUB_TOKEN"]),
    description="Full-stack developer who can analyze both code and architecture diagrams",
    markdown=True,
)

# Analyze an architecture diagram (local file or URL)
# agent.print_response(
#     "Analyze this architecture diagram and identify potential bottlenecks",
#     images=[Image(filepath="./architecture.png")]
# )

# Analyze code with context
agent.print_response("""
Review this payment service class and suggest improvements:

```java
public class PaymentProcessor {
    private static final String DB_URL = "jdbc:mysql://prod-db:3306/payments";
    private static final String PASSWORD = "payment_secret_123";

    public boolean processPayment(String userId, double amount) {
        String query = "SELECT * FROM accounts WHERE id=" + userId;
        // ... execute query
        return amount > 0;
    }
}
```

Focus on: security vulnerabilities, code quality, and missing validations.
""")
```

### Example 3 — Advanced: Agno Team for Full SDLC Cycle

```python
# pip install agno openai
import os
from agno.agent import Agent
from agno.team import Team
from agno.models.openai import OpenAIChat
from agno.storage.sqlite import SqliteStorage
from agno.tools import tool
from pydantic import BaseModel, Field
from typing import List

MODEL = OpenAIChat(id="gpt-4o-mini",
                   base_url="https://models.inference.ai.azure.com",
                   api_key=os.environ["GITHUB_TOKEN"])
STORAGE = SqliteStorage(table_name="sdlc_team", db_file="sdlc_sessions.db")

class AcceptanceCriteria(BaseModel):
    criteria: List[str] = Field(description="List of testable acceptance criteria")
    definition_of_done: List[str]
    out_of_scope: List[str]

class TestPlan(BaseModel):
    unit_tests:        List[str] = Field(description="Unit test descriptions")
    integration_tests: List[str]
    edge_cases:        List[str]
    estimated_coverage: str

@tool
def search_existing_patterns(feature_type: str) -> str:
    """Search existing codebase patterns for similar features."""
    patterns = {
        "payment":  "PaymentProcessor, PaymentGateway, TransactionService — all in com.company.payments",
        "toggle":   "ToggleService.isEnabled() — feature flag pattern used in 23 classes",
        "api":      "REST controllers extend BaseController, use @Valid for input validation",
    }
    return patterns.get(feature_type.lower(), "No existing patterns found")

# Specialist agents
requirements_agent = Agent(
    name="Requirements Analyst",
    role="Write clear, testable acceptance criteria and definition of done",
    model=MODEL, storage=STORAGE,
    response_model=AcceptanceCriteria,
    structured_outputs=True,
    tools=[search_existing_patterns],
)

test_planning_agent = Agent(
    name="QA Engineer",
    role="Create comprehensive test plans covering unit, integration, and edge cases",
    model=MODEL, storage=STORAGE,
    response_model=TestPlan,
    structured_outputs=True,
)

code_review_agent = Agent(
    name="Senior Developer",
    role="Review code for quality, security, and adherence to patterns",
    model=MODEL, storage=STORAGE,
    markdown=True,
)

# SDLC Team
sdlc_team = Team(
    name="SDLC Automation Team",
    agents=[requirements_agent, test_planning_agent, code_review_agent],
    mode="coordinate",
    model=MODEL,
    storage=STORAGE,
    markdown=True,
    session_id="sdlc-sprint-42",
    show_tool_calls=True,
)

# Run a full SDLC workflow
sdlc_team.print_response(
    """Process this user story through the full SDLC cycle:
    
    STORY: As a payment system user, I want the Enable-CIT toggle to be automatically 
    disabled when the CIT gateway error rate exceeds 5% in the last 5 minutes, 
    so that payments automatically fall back to the legacy provider.
    
    Please:
    1. Write acceptance criteria and definition of done
    2. Create a test plan
    3. Review the conceptual implementation and flag any concerns"""
)
```

### Free Tier / Pricing

- **Agno (open-source):** 100% free, MIT license
- **Agno Cloud (agno.com):** Managed agents, free tier; Pro pricing TBD
- **Storage backends:** Use free options (SQLite, LanceDB) or paid cloud DBs

### Best Use Case for SDLC Automation

**Structured Output Pipelines:** When you need agents that produce guaranteed-valid Pydantic models (security reports, test plans, architecture reviews), Agno's `response_model` parameter is the cleanest solution — no output parsing errors, no prompt engineering for JSON formatting.

---

## 3.18 Marvin

### What is Marvin

Marvin (by Prefect) is a Python toolkit that turns LLMs into **typed Python functions**. Instead of managing prompts and parsers, you decorate regular functions with `@ai_fn`, `@classifier`, `@extractor`, or `@ai_model`. Marvin infers the prompt from your function signature and docstring. Output is always a valid Python type enforced by Pydantic — no JSON parsing failures.

**When to choose Marvin vs alternatives:**

| Scenario | Marvin | Instructor | Pydantic AI |
|----------|--------|------------|-------------|
| Simplest typed AI functions | ✅ Best | Good | Good |
| Multi-model orchestration | Limited | Limited | ✅ Best |
| Classification tasks | ✅ Best | Manual | Manual |
| Data extraction pipelines | ✅ Best | ✅ Best | Good |
| Complex agent workflows | Limited | Limited | ✅ Best |

### Installation

```bash
pip install marvin
# Set API key
export OPENAI_API_KEY="your-key"
# Or use with other models
pip install marvin[anthropic]
```

### Core Concepts

#### 1. `cast` — transform any input to any Python type

```python
import marvin

# Cast free text to typed Python object
result = marvin.cast("the payment failed due to insufficient funds", target=str)
# Or cast to complex types:
from enum import Enum

class PaymentStatus(Enum):
    SUCCESS   = "success"
    FAILED    = "failed"
    PENDING   = "pending"
    REFUNDED  = "refunded"

status = marvin.cast("transaction declined at gateway", target=PaymentStatus)
print(status)  # PaymentStatus.FAILED
```

#### 2. `classify` — categorize into labels

```python
import marvin
from typing import Literal

# Classify into fixed labels
severity = marvin.classify(
    "System is down, 100% error rate on all payment endpoints",
    labels=["P1-Critical", "P2-High", "P3-Medium", "P4-Low"]
)
print(severity)  # "P1-Critical"

# Classify with instructions
sentiment = marvin.classify(
    "The deploy broke prod again! Why does this keep happening?!",
    labels=Literal["positive", "neutral", "frustrated", "urgent"],
    instructions="Focus on the emotional tone, not the content"
)
```

#### 3. `extract` — pull structured data from text

```python
import marvin
from pydantic import BaseModel
from typing import List

class ToggleMention(BaseModel):
    toggle_name: str
    action: str        # "enabled", "disabled", "checked", "unknown"
    context: str       # surrounding context

# Extract all toggle mentions from a Slack message
mentions = marvin.extract(
    """Team update: we enabled Enable-CIT in production today after QA sign-off.
    Also disabled BypassFraudCheck in staging. No issues so far.""",
    target=list[ToggleMention],
    instructions="Extract all feature toggle operations mentioned"
)
for m in mentions:
    print(f"Toggle: {m.toggle_name} | Action: {m.action} | Context: {m.context}")
```

#### 4. `@ai_fn` — AI-powered functions

```python
import marvin
from typing import List

@marvin.fn
def suggest_test_cases(function_signature: str, docstring: str) -> List[str]:
    """Generate comprehensive test case descriptions for a Python function.
    Include: happy path, boundary values, error cases, type edge cases."""

@marvin.fn
def estimate_story_points(user_story: str, team_velocity: int) -> int:
    """Estimate story points (1,2,3,5,8,13,21) for a user story.
    Consider: complexity, uncertainty, effort. Use team velocity as calibration."""

@marvin.fn
def generate_commit_message(diff: str) -> str:
    """Generate a conventional commit message (type(scope): description) from a git diff.
    Types: feat, fix, refactor, test, docs, chore, ci"""
```

#### 5. `@ai_model` — self-populating Pydantic models

```python
import marvin
from pydantic import BaseModel
from typing import List, Optional

@marvin.ai_model
class PRReview(BaseModel):
    """AI-powered PR review model. Extracts review data from PR description and diff."""
    title:           str
    type:            str   # feat/fix/refactor/etc
    breaking_change: bool
    risk_level:      str   # LOW/MEDIUM/HIGH/CRITICAL
    areas_changed:   List[str]
    requires_migration: bool
    suggested_reviewers: List[str]

review = PRReview("Add Enable-CIT toggle to route European card payments through CIT gateway. Changes PaymentProcessor.java, ToggleService.java. New behavior: CIT cards route to different endpoint.")
print(review.risk_level)       # "MEDIUM"
print(review.breaking_change)  # False
```

### Example 1 — Basic: Typed Classifiers for SDLC

```python
# pip install marvin
import marvin
from typing import Literal
from pydantic import BaseModel
from enum import Enum

class TicketPriority(str, Enum):
    CRITICAL = "P1-Critical"
    HIGH     = "P2-High"
    MEDIUM   = "P3-Medium"
    LOW      = "P4-Low"

class TicketCategory(str, Enum):
    BUG          = "bug"
    FEATURE      = "feature"
    TECH_DEBT    = "tech-debt"
    SECURITY     = "security"
    PERFORMANCE  = "performance"
    DOCUMENTATION = "documentation"

# Test tickets
tickets = [
    "Login page crashes when password contains special characters",
    "Add dark mode to the developer portal",
    "The payment service's database queries have no index on user_id column",
    "CVE-2024-1234 affects our version of log4j",
    "P99 latency on /api/checkout is 4.2s, SLA is 2s",
]

print("Ticket Analysis:")
print(f"{'Ticket':<60} {'Priority':<15} {'Category'}")
print("-" * 95)
for ticket in tickets:
    priority = marvin.classify(ticket, labels=TicketPriority)
    category = marvin.classify(ticket, labels=TicketCategory)
    print(f"{ticket[:58]:<60} {priority.value:<15} {category.value}")
```

### Example 2 — Intermediate: Data Extraction Pipeline for Code Reviews

```python
# pip install marvin
import marvin
from pydantic import BaseModel, Field
from typing import List, Optional

class CodeIssue(BaseModel):
    severity:       str = Field(description="CRITICAL, HIGH, MEDIUM, LOW, INFO")
    category:       str = Field(description="security, performance, correctness, style, maintainability")
    description:    str
    line_hint:      Optional[str] = Field(description="Code snippet near the issue")
    fix:            str = Field(description="Concrete fix recommendation")
    owasp_category: Optional[str] = Field(description="OWASP Top 10 category if applicable")

class CodeReviewReport(BaseModel):
    language:          str
    overall_quality:   int = Field(ge=1, le=10, description="Code quality score 1-10")
    approve:           bool
    issues:            List[CodeIssue]
    positive_aspects:  List[str]
    refactoring_notes: Optional[str]

# Extract structured review from unstructured code
code_snippet = """
import os
import subprocess

class UserService:
    DB_PASS = "production_db_pass_2024"  # hardcoded!

    def get_user(self, user_id):
        query = "SELECT * FROM users WHERE id=" + str(user_id)  # SQL injection
        result = os.popen(f"echo {query}").read()               # command injection
        return result

    def run_report(self, report_name):
        subprocess.call(["report_runner", report_name], shell=True)  # shell=True risk
        return True
"""

report = marvin.extract(
    f"Perform a security-focused code review of this Python code:\n\n```python\n{code_snippet}\n```",
    target=CodeReviewReport,
    instructions="Be thorough. This code handles user authentication — any security issue is critical."
)

print(f"Quality Score: {report[0].overall_quality}/10")
print(f"Approve: {'✅' if report[0].approve else '❌'}")
print(f"\nIssues found: {len(report[0].issues)}")
for issue in report[0].issues:
    print(f"  [{issue.severity}] {issue.category}: {issue.description}")
    if issue.owasp_category:
        print(f"    OWASP: {issue.owasp_category}")
    print(f"    Fix: {issue.fix}")
```

### Example 3 — Advanced: AI Functions Pipeline for Full Story Processing

```python
# pip install marvin
import marvin
from pydantic import BaseModel, Field
from typing import List, Optional

# ── Model definitions ─────────────────────────────────────────────────────────

class AcceptanceCriteria(BaseModel):
    scenario: str
    given:    str
    when:     str
    then:     str

class UserStoryAnalysis(BaseModel):
    title:               str
    story_points:        int = Field(ge=1, le=21)
    risk_level:          str
    acceptance_criteria: List[AcceptanceCriteria]
    technical_tasks:     List[str]
    dependencies:        List[str]
    questions:           List[str] = Field(description="Clarification questions for the PO")

class SprintPlan(BaseModel):
    sprint_goal:    str
    stories:        List[str]
    capacity_used:  int
    at_risk:        List[str]
    recommendations: List[str]

# ── AI Functions ──────────────────────────────────────────────────────────────

@marvin.fn
def analyze_user_story(story: str, team_context: str) -> UserStoryAnalysis:
    """Analyze a user story: estimate points, write acceptance criteria in Gherkin,
    identify technical tasks and dependencies. Use team context for calibration."""

@marvin.fn
def detect_story_smells(story: str) -> List[str]:
    """Detect common user story problems: too large (epic), vague acceptance criteria,
    missing non-functional requirements, technical debt hidden as features, etc."""

@marvin.fn
def plan_sprint(stories: List[str], team_capacity_points: int) -> SprintPlan:
    """Create a sprint plan from a backlog. Balance risk, dependencies, and capacity.
    Return which stories to include and which are at risk."""

@marvin.fn
def write_commit_message(diff_summary: str, jira_ticket: Optional[str] = None) -> str:
    """Write a conventional commit message. Format: type(scope): description
    Types: feat, fix, refactor, test, docs, chore, ci, perf
    Include JIRA ticket if provided: 'feat(payments): add CIT routing [PAY-123]'"""

# ── Pipeline execution ────────────────────────────────────────────────────────

stories = [
    "As a payment ops engineer, I want Enable-CIT to auto-disable when error rate > 5% for 5 minutes, so that payments automatically fall back to legacy provider.",
    "As a developer, I want a dashboard showing all toggle states across environments, so that I can quickly identify configuration drift.",
]

print("=" * 70)
print("SPRINT PLANNING ANALYSIS")
print("=" * 70)

analyses = []
for story in stories:
    # Detect problems first
    smells = detect_story_smells(story)
    if smells:
        print(f"\n⚠️  Story smells detected:")
        for smell in smells:
            print(f"   - {smell}")

    # Full analysis
    analysis = analyze_user_story(
        story=story,
        team_context="Java/Spring Boot team, 5 devs, 80 points/sprint average"
    )
    analyses.append(analysis)
    print(f"\n📋 {analysis.title}")
    print(f"   Points: {analysis.story_points} | Risk: {analysis.risk_level}")
    print(f"   ACs: {len(analysis.acceptance_criteria)}")
    for ac in analysis.acceptance_criteria:
        print(f"     Scenario: {ac.scenario}")
        print(f"     Given {ac.given} | When {ac.when} | Then {ac.then}")
    if analysis.questions:
        print(f"   ❓ Questions for PO:")
        for q in analysis.questions:
            print(f"     - {q}")

# Sprint planning
story_titles = [a.title for a in analyses]
sprint = plan_sprint(stories=story_titles, team_capacity_points=80)
print(f"\n🚀 Sprint Goal: {sprint.sprint_goal}")
print(f"   Capacity Used: {sprint.capacity_used}/80 points")
if sprint.at_risk:
    print(f"   ⚠️  At Risk: {', '.join(sprint.at_risk)}")

# Generate commit message for a hypothetical implementation
commit_msg = write_commit_message(
    diff_summary="Added CircuitBreakerToggleService that monitors CIT error rate and disables toggle after threshold",
    jira_ticket="PAY-456"
)
print(f"\n💾 Commit: {commit_msg}")
```

### Free Tier / Pricing

- **Marvin (open-source):** 100% free, Apache 2.0 license
- **Requires:** Your own OpenAI/Anthropic API key (pay-per-token)
- **With GitHub Models:** Free via `GITHUB_TOKEN` and compatible `base_url`

### Best Use Case for SDLC Automation

**Automated Ticket Enrichment:** As tickets are created in Jira, pipe them through Marvin classifiers (priority, category) and extractors (acceptance criteria, story points) to auto-populate fields. No prompt engineering needed — just Python types.

---

## 3.19 Guidance (Microsoft)

### What is Guidance

Guidance (Microsoft Research) is a framework for **constrained generation** — it controls LLM output at the token level using a handlebars-like template syntax. Instead of hoping the LLM returns valid JSON, Guidance *forces* the model to produce output that matches your template structure. It supports regex constraints, grammar constraints, few-shot examples, and interleaves code + generation. Ideal for structured data extraction where reliability > flexibility.

**When to choose Guidance vs alternatives:**

| Scenario | Guidance | Instructor | Marvin |
|----------|----------|------------|--------|
| Guarantee valid structured output | ✅ Best | Good | Good |
| Token-level output control | ✅ Best | No | No |
| Constrained generation (regex/grammar) | ✅ Best | No | No |
| Simplest API | Limited | ✅ Best | ✅ Best |
| Local models (Llama, Mistral) | ✅ Best | Limited | Limited |

### Installation

```bash
pip install guidance
# GPU acceleration (optional)
pip install guidance[transformers]
# OpenAI models
pip install guidance openai
```

### Core Concepts

#### 1. Programs — template syntax with generation blocks

```python
import guidance
from guidance import models, gen, select, system, user, assistant

# Connect to model
lm = models.OpenAI("gpt-4o-mini",
                   base_url="https://models.inference.ai.azure.com",
                   api_key=os.environ["GITHUB_TOKEN"])

# Or local model
# lm = models.Transformers("microsoft/phi-3-mini-4k-instruct", echo=False)
```

#### 2. `gen()` — constrained generation

```python
import guidance, os
from guidance import models, gen

lm = models.OpenAI("gpt-4o-mini",
                   base_url="https://models.inference.ai.azure.com",
                   api_key=os.environ["GITHUB_TOKEN"])

# Constrain output with regex
result = lm + "The risk level is: " + gen("risk", regex="(LOW|MEDIUM|HIGH|CRITICAL)")
print(result["risk"])  # guaranteed to be one of the 4 options

# Constrain by max tokens
result = lm + "Summary in 10 words: " + gen("summary", max_tokens=15, stop=".")
print(result["summary"])
```

#### 3. `select()` — choose from a list of options

```python
from guidance import select

result = (
    lm +
    "PR Review decision: " +
    select(["APPROVE", "REQUEST_CHANGES", "COMMENT"], name="decision") +
    "\nReason: " +
    gen("reason", max_tokens=100, stop="\n")
)
print(f"Decision: {result['decision']}")
print(f"Reason: {result['reason']}")
```

#### 4. Chat model templates

```python
from guidance import system, user, assistant

with system():
    lm += "You are a senior code reviewer. Be precise and concise."

with user():
    lm += f"Review this function and classify each issue:\n\n```python\n{code}\n```"

with assistant():
    lm += "Issues found:\n"
    for i in range(3):  # generate up to 3 issues
        lm += f"{i+1}. [" + select(["CRITICAL", "HIGH", "MEDIUM", "LOW"], name=f"severity_{i}") + "] "
        lm += gen(f"issue_{i}", max_tokens=80, stop="\n") + "\n"
```

#### 5. Grammar constraints for complex structures

```python
import guidance
from guidance import models, gen

# Force JSON output using grammar constraint
# Guidance uses lark grammar syntax
JSON_GRAMMAR = r"""
start: object
object: "{" pair ("," pair)* "}"
pair: ESCAPED_STRING ":" value
value: ESCAPED_STRING | NUMBER | "true" | "false" | "null" | object | array
array: "[" value ("," value)* "]" | "[]"
%import common.ESCAPED_STRING
%import common.NUMBER
%import common.WS
%ignore WS
"""

@guidance(stateless=True)
def json_object(lm, schema: str):
    """Force the LLM to generate valid JSON matching a description."""
    return lm + gen(name="json_output", max_tokens=500, stop_regex=r"}\s*$")
```

### Example 1 — Basic: Constrained Code Classification

```python
# pip install guidance openai
import os
import guidance
from guidance import models, gen, select, system, user, assistant

lm = models.OpenAI(
    "gpt-4o-mini",
    base_url="https://models.inference.ai.azure.com",
    api_key=os.environ["GITHUB_TOKEN"]
)

def classify_code_issue(code_snippet: str) -> dict:
    """Classify a code issue with guaranteed structured output."""
    result = (
        lm +
        system("You are a code quality expert. Classify the given code issue precisely.") +
        user(f"Classify this code issue:\n\n```\n{code_snippet}\n```") +
        assistant(
            "Category: " +
            select(["security", "performance", "correctness", "maintainability", "style"],
                   name="category") +
            "\nSeverity: " +
            select(["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"], name="severity") +
            "\nFix required: " +
            select(["yes", "no"], name="fix_required") +
            "\nOne-line description: " +
            gen("description", max_tokens=80, stop="\n") +
            "\nRecommended fix: " +
            gen("fix", max_tokens=120, stop="\n")
        )
    )

    return {
        "category":     result["category"],
        "severity":     result["severity"],
        "fix_required": result["fix_required"],
        "description":  result["description"].strip(),
        "fix":          result["fix"].strip(),
    }

# Test with problematic code patterns
issues = [
    'password = "hardcoded_secret_abc123"',
    'for i in range(len(items)): print(items[i])',
    'result = eval(user_input)',
    'SELECT * FROM users WHERE id=' + "'" + user_id + "'",
]

for code in issues:
    result = classify_code_issue(code)
    print(f"Code: {code[:50]}")
    print(f"  [{result['severity']}] {result['category']}: {result['description']}")
    print(f"  Fix: {result['fix']}\n")
```

### Example 2 — Intermediate: Structured PR Review with Repeated Generation

```python
# pip install guidance openai
import os
from guidance import models, gen, select, system, user, assistant

lm = models.OpenAI("gpt-4o-mini",
                   base_url="https://models.inference.ai.azure.com",
                   api_key=os.environ["GITHUB_TOKEN"])

def structured_pr_review(pr_diff: str, max_issues: int = 5) -> dict:
    """
    Generate a fully structured PR review using Guidance constrained generation.
    Every field is guaranteed to be valid — no JSON parsing errors.
    """
    result = (
        lm +
        system("You are a senior engineer doing a thorough code review. Be specific and constructive.") +
        user(f"Review this PR diff:\n\n```diff\n{pr_diff}\n```\n\nProvide a structured review.") +
        assistant(
            "Overall quality score (1-10): " +
            select([str(i) for i in range(1, 11)], name="quality_score") +
            "\nApprove PR: " +
            select(["yes", "no", "needs-changes"], name="decision") +
            "\nSummary: " +
            gen("summary", max_tokens=150, stop="\n") +
            "\n\nIssues:\n"
        )
    )

    # Collect issues through repeated generation
    issues = []
    current_lm = result
    for i in range(max_issues):
        issue_result = (
            current_lm +
            f"{i+1}. [" +
            select(["CRITICAL", "HIGH", "MEDIUM", "LOW"], name=f"sev_{i}") +
            "] " +
            gen(f"issue_{i}", max_tokens=100, stop="\n") +
            "\n"
        )
        issue_text = issue_result[f"issue_{i}"].strip()
        if not issue_text or issue_text.lower().startswith("no more"):
            break
        issues.append({
            "severity": issue_result[f"sev_{i}"],
            "description": issue_text
        })
        current_lm = issue_result

    return {
        "quality_score": int(result["quality_score"]),
        "decision":      result["decision"],
        "summary":       result["summary"].strip(),
        "issues":        issues
    }

# Example PR diff
diff = """
-def get_user(user_id):
-    return db.query(f"SELECT * FROM users WHERE id='{user_id}'")
+def get_user(user_id: int) -> Optional[User]:
+    password = "admin123"  # temp debug password
+    stmt = text("SELECT * FROM users WHERE id=:uid")
+    return db.execute(stmt, {"uid": user_id}).fetchone()
"""

review = structured_pr_review(diff, max_issues=4)
print(f"Quality: {review['quality_score']}/10 | Decision: {review['decision'].upper()}")
print(f"Summary: {review['summary']}")
print(f"\nIssues ({len(review['issues'])}):")
for issue in review["issues"]:
    print(f"  [{issue['severity']}] {issue['description']}")
```

### Example 3 — Advanced: Local Model Constrained Generation for Offline SDLC

```python
# pip install guidance transformers torch
# Use local Phi-3 model — no API keys, fully offline, free
"""
Production use case: air-gapped environments, sensitive codebases,
or when API costs are prohibitive for high-volume SDLC automation.
"""
import re
import guidance
from guidance import models, gen, select, system, user, assistant
from pydantic import BaseModel
from typing import List

# Uncomment for real usage (downloads ~2GB model on first run):
# lm = models.Transformers("microsoft/Phi-3-mini-4k-instruct", echo=False)

# For demonstration, using OpenAI-compatible endpoint
import os
lm = models.OpenAI("gpt-4o-mini",
                   base_url="https://models.inference.ai.azure.com",
                   api_key=os.environ["GITHUB_TOKEN"])

COMMIT_TYPES = ["feat", "fix", "refactor", "test", "docs", "chore", "ci", "perf", "style"]
SCOPES = ["payments", "auth", "api", "db", "ui", "config", "tests", "infra", "toggles"]

def generate_conventional_commit(diff_summary: str) -> str:
    """
    Generate a conventional commit message with guaranteed format:
    type(scope): description
    
    Uses Guidance to constrain each part of the commit message separately.
    """
    result = (
        lm +
        system("You are an expert at writing conventional commit messages. "
               "Be concise and specific. Never use generic words like 'update' or 'change'.") +
        user(f"Generate a conventional commit for this change:\n{diff_summary}") +
        assistant(
            gen("type",   options=COMMIT_TYPES) +   # constrain type
            "(" +
            gen("scope",  options=SCOPES) +           # constrain scope
            "): " +
            gen("desc",   max_tokens=60, stop="\n")   # free-form description
        )
    )
    return f"{result['type']}({result['scope']}): {result['desc'].strip()}"

def generate_test_assertions(function_code: str, num_assertions: int = 4) -> List[str]:
    """Generate test assertions with constrained structure."""
    assertions = []
    base = (
        lm +
        system("Generate pytest assertions for Python functions. Be specific with expected values.") +
        user(f"Write {num_assertions} pytest assertions for:\n\n{function_code}") +
        assistant("Assertions:\n")
    )

    for i in range(num_assertions):
        result = (
            base +
            "    assert " +
            gen(f"assertion_{i}", max_tokens=80, stop="\n") +
            "\n"
        )
        assertions.append(f"assert {result[f'assertion_{i}'].strip()}")
        base = result

    return assertions

def estimate_effort(user_story: str) -> dict:
    """Estimate effort with guaranteed Fibonacci story points."""
    fibonacci = ["1", "2", "3", "5", "8", "13", "21"]
    result = (
        lm +
        system("You are an experienced agile coach estimating story complexity.") +
        user(f"Estimate this story:\n{user_story}") +
        assistant(
            "Complexity: " +
            select(["trivial", "simple", "moderate", "complex", "very-complex"], name="complexity") +
            "\nUncertainty: " +
            select(["low", "medium", "high"], name="uncertainty") +
            "\nStory points: " +
            select(fibonacci, name="points") +
            "\nRationale: " +
            gen("rationale", max_tokens=100, stop="\n")
        )
    )
    return {
        "complexity":   result["complexity"],
        "uncertainty":  result["uncertainty"],
        "points":       int(result["points"]),
        "rationale":    result["rationale"].strip()
    }

# ── Run the pipeline ──────────────────────────────────────────────────────────

print("=== Conventional Commit Generation ===")
commit = generate_conventional_commit(
    "Added circuit breaker that monitors CIT gateway error rate and disables Enable-CIT toggle when it exceeds 5% over 5 minutes"
)
print(f"Commit: {commit}\n")

print("=== Test Assertion Generation ===")
function_code = """
def calculate_compound_interest(principal: float, rate: float, years: int) -> float:
    if years <= 0: raise ValueError("Years must be positive")
    if rate < 0:   raise ValueError("Rate cannot be negative")
    return round(principal * (1 + rate) ** years, 2)
"""
assertions = generate_test_assertions(function_code, num_assertions=4)
print("Generated assertions:")
for a in assertions:
    print(f"    {a}")

print("\n=== Story Point Estimation ===")
story = "As a payment ops engineer, I want Enable-CIT to auto-disable when error rate > 5% for 5 minutes, with automatic re-enable after 15 minutes of healthy responses"
estimate = estimate_effort(story)
print(f"Story: {story[:80]}...")
print(f"Complexity: {estimate['complexity']} | Uncertainty: {estimate['uncertainty']}")
print(f"Points: {estimate['points']} | Rationale: {estimate['rationale']}")
```

### Free Tier / Pricing

- **Guidance (open-source):** 100% free, MIT license
- **Local models (Phi-3, Llama):** Free — runs on GPU/CPU locally
- **Cloud models:** Pay-per-token (your API key); free via GitHub Models

### Best Use Case for SDLC Automation

**High-Volume, High-Reliability Extraction:** When you're processing thousands of code reviews, tickets, or PRs per day and *cannot* tolerate JSON parsing errors or malformed outputs, Guidance's constrained generation guarantees every output matches your schema — even with smaller, cheaper, or local models.

---

## Comparison Tables

### Library Selection Guide

| Library | Type | Best For | LLM Integration | Learning Curve | Self-Hostable |
|---------|------|----------|-----------------|----------------|---------------|
| **Haystack** | RAG/Pipeline | Document Q&A, Evaluation | 20+ LLMs | Medium | ✅ Yes |
| **Semantic Kernel** | Agent SDK | .NET/Enterprise, Plugin registry | Azure + OpenAI + Local | Medium | ✅ Yes |
| **Flowise** | Visual Builder | No-code RAG, REST API gen | 20+ via UI | Low | ✅ Yes |
| **n8n + AI** | Workflow Automation | Biz process + AI | OpenAI + custom | Low | ✅ Yes |
| **Dify** | LLMOps Platform | Team AI apps, Prompt mgmt | 20+ LLMs | Low-Medium | ✅ Yes |
| **Agno** | Agent Framework | Multi-modal, Structured output | OpenAI + Anthropic + Groq | Low | ✅ Yes |
| **Marvin** | Typed AI Functions | Classifiers, Extractors | OpenAI + Anthropic | Low | ✅ Yes |
| **Guidance** | Constrained Gen | Guaranteed structured output | OpenAI + Local | Medium-High | ✅ Yes |

### RAG Pipeline Comparison

| Feature | Haystack | LangChain | LlamaIndex | Dify |
|---------|----------|-----------|------------|------|
| Pipeline evaluation (faithfulness/relevance) | ✅ Built-in | LangSmith (paid) | ✅ Built-in | Limited |
| Hybrid retrieval (BM25 + vector) | ✅ Native | EnsembleRetriever | ✅ Native | Via UI |
| Reranking | ✅ Native | Manual | ✅ Native | Limited |
| Visual pipeline editor | Haystack Studio | No | No | ✅ Yes |
| Production API server | Hayhooks (free) | LangServe | llama-deploy | ✅ Built-in |
| Pipeline as YAML | ✅ Yes | No | No | ✅ Yes |

### Structured Output Comparison

| Feature | Guidance | Instructor | Marvin | Pydantic AI |
|---------|----------|------------|--------|-------------|
| Token-level constraints | ✅ Yes | No | No | No |
| Regex/grammar constraints | ✅ Yes | No | No | No |
| Pydantic schema enforcement | Via gen | ✅ Native | ✅ Native | ✅ Native |
| Works with local models | ✅ Best | Limited | Limited | Good |
| API simplicity | Complex | Simple | Simplest | Simple |
| Retry on validation failure | Manual | ✅ Auto | ✅ Auto | ✅ Auto |

### Platform vs Code Comparison

| Tool | Code Required | Non-Dev Friendly | API Exposed | Version Control | Cost |
|------|--------------|-----------------|-------------|----------------|------|
| **Flowise** | Optional | ✅ Yes | ✅ Auto REST | JSON export | Free OSS |
| **n8n** | Optional | ✅ Yes | ✅ Webhook | JSON export | Free OSS |
| **Dify** | Optional | ✅ Yes | ✅ Built-in | Built-in | Free OSS |
| **LangChain** | Required | No | Manual | Git | Free |
| **Haystack** | Required | No | Hayhooks | Git | Free |
| **Agno** | Required | No | Manual | Git | Free |
| **Marvin** | Required | No | Manual | Git | Free |
| **Guidance** | Required | No | Manual | Git | Free |

### SDLC Automation Fit Matrix

| SDLC Activity | Best Library | Alternative | Notes |
|---------------|-------------|-------------|-------|
| Document Q&A (Confluence, Jira) | Haystack | LlamaIndex | Haystack adds evaluation |
| Code review automation | Guidance / Marvin | Instructor | Constrained output = no parse errors |
| Sprint planning (ticket classification) | Marvin | Pydantic AI | Typed classifiers, zero boilerplate |
| Multi-agent workflows | Agno / CrewAI | LangGraph | Agno simpler; LangGraph more control |
| Business process automation | n8n | Flowise | n8n has 400+ integrations |
| Enterprise .NET CI/CD pipelines | Semantic Kernel | LangChain | SK native in C# / Azure DevOps |
| No-code team tools | Dify / Flowise | n8n | Teams build own tools without devs |
| Local / air-gapped environments | Guidance + Phi-3 | Ollama + LangChain | Guidance ensures valid output locally |

---

*End of Part 3 — Library Reference (Additional Libraries)*
*See AI-LIBRARIES-GUIDE.md for: LangChain, LangGraph, CrewAI, AutoGen, LlamaIndex, DSPy, MCP, ACP, Pydantic AI, Smolagents, Instructor*
