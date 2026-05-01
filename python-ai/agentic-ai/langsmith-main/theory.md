# LangSmith Theory Guide

## 1. What is LangSmith? Why Observability Matters for LLM Apps

LangSmith is a platform developed by LangChain for debugging, testing, evaluating, and monitoring
large language model (LLM) applications. As LLM applications grow in complexity — spanning multiple
chains, agents, tools, and retrieval systems — understanding what happens inside them becomes critical.

### Why Observability Matters

Traditional software has deterministic behavior: given the same inputs, you get the same outputs.
LLM applications are probabilistic. The same prompt can yield different responses depending on
temperature, model version, or context window state. Without observability:

- You cannot diagnose why a chain produced a bad answer
- You cannot measure latency bottlenecks across complex pipelines
- You cannot track token costs at scale
- You cannot run systematic evaluations to detect regressions

LangSmith solves all of these by providing a unified tracing and evaluation layer that integrates
directly with LangChain and the broader LLM ecosystem.

### Core Value Propositions

- **Debugging**: Inspect every step of a chain or agent run, including inputs, outputs, and errors
- **Testing**: Create golden datasets and run automated evaluations
- **Monitoring**: Track latency, token usage, and error rates in production
- **Collaboration**: Share traces and datasets across teams via the LangSmith Hub

---

## 2. Tracing: Every LLM Call, Chain Step, and Tool Call Logged Automatically

Tracing is the foundation of LangSmith. When tracing is enabled, every operation in a LangChain
pipeline is automatically recorded as a "run" with full input/output capture.

### How Tracing Works

LangSmith uses a callback system under the hood. When you set the environment variable
`LANGCHAIN_TRACING_V2=true`, LangChain automatically injects a `LangChainTracer` callback into
every chain, LLM, tool, and retriever invocation. This callback sends structured data to the
LangSmith API in real time (or batched).

### What Gets Traced

- **LLM calls**: The exact prompt sent to the model, the response received, latency, token counts
- **Chain steps**: Each sub-chain in a `SequentialChain` or `RunnableSequence`
- **Tool invocations**: The tool name, input arguments, and return value
- **Retriever queries**: The query string and retrieved documents with scores
- **Embeddings**: Vectors generated during indexing or retrieval

### Trace Hierarchy

Traces are hierarchical. A single user request might produce:
```
Chain Run (root)
├── Retriever Run
│   └── Embedding Run
├── LLM Run
│   └── (prompt + response)
└── Tool Run
    └── (tool name + result)
```

Each node in the tree is called a "run". Child runs inherit the parent's trace ID.

### Latency Attribution

Because runs are nested and timestamped, you can immediately see which step accounts for the
majority of end-to-end latency — whether it's the retriever, the LLM call, or a slow tool.

---

## 3. Projects and Runs Organization

### Projects

In LangSmith, a **project** (formerly called a session) is a logical grouping of runs. You assign
runs to a project using the `LANGCHAIN_PROJECT` environment variable or programmatically.

Projects are useful for:
- Separating development, staging, and production traces
- Grouping runs by feature, team, or experiment
- Comparing behavior across different time periods

### Runs

A **run** is a single recorded execution of any LangChain component. Runs have:
- A unique ID (UUID)
- A run type (chain, llm, tool, retriever, embedding)
- Start and end timestamps
- Input and output data (serialized)
- Error information (if it failed)
- Tags and metadata (user-defined)
- Token usage and cost estimates
- Parent run ID (for nested runs)

### Organizing with Tags and Metadata

Beyond projects, you can add arbitrary tags (strings) and metadata (key-value pairs) to runs.
This enables powerful filtering:
- Tag runs by model version: `gpt-4`, `claude-3`
- Tag by feature: `rag-pipeline`, `summarizer`
- Add metadata like `user_id`, `session_id`, `experiment_name`

---

## 4. Run Types: Chain, LLM, Tool, Retriever, Embedding

LangSmith categorizes every run into one of five types:

### Chain
Represents a composite operation — a sequence of steps that processes an input and produces
an output. Chains can nest other chains. The root of most traces is a chain run.
Examples: `LLMChain`, `RetrievalQA`, `ConversationalRetrievalChain`, LCEL runnables.

### LLM
Represents a direct call to a language model. LLM runs capture:
- The list of messages or the prompt string sent to the model
- The model name and parameters (temperature, max_tokens, etc.)
- The generated response(s)
- Token counts (prompt tokens, completion tokens, total tokens)
- Latency (time to first token, total time)

### Tool
Represents the execution of a tool by an agent. Tool runs capture:
- The tool name
- The input string or structured input
- The output string or result
- Success or failure status

### Retriever
Represents a document retrieval step. Retriever runs capture:
- The query string
- The list of retrieved documents (content + metadata + relevance scores)
- The number of documents retrieved

### Embedding
Represents a call to an embedding model. Embedding runs capture:
- The input text(s)
- The resulting vector(s)
- The embedding model name
- Token usage

---

## 5. Datasets and Evaluation: Create Datasets, Run Evaluators

### Datasets

A **dataset** in LangSmith is a collection of examples, where each example has:
- An `inputs` dictionary (what you feed to your chain)
- An optional `outputs` dictionary (the expected or reference output)

Datasets serve as the ground truth for evaluation. They can be created:
- **Manually**: You define inputs and expected outputs yourself
- **From runs**: You promote interesting or representative production traces to a dataset
- **Programmatically**: Via the LangSmith Python SDK

### Running Evaluations

The `evaluate()` function (or `arun_on_dataset()` for async) runs your chain/function against
every example in a dataset and applies evaluators to score each result.

```
evaluate(
    target_function,
    data=dataset_name,
    evaluators=[evaluator1, evaluator2],
    experiment_prefix="my-experiment"
)
```

Results are stored in LangSmith as an experiment, letting you compare across runs visually.

---

## 6. Evaluators: Exact Match, Embedding Similarity, LLM-as-Judge

### Exact Match
The simplest evaluator. Compares the chain's output string to the reference output using
string equality. Best for structured outputs (JSON keys, specific codes, factual answers).

Score: 1 if output == reference, 0 otherwise.

### Embedding Similarity
Embeds both the output and the reference using a specified embedding model, then computes
cosine similarity between the two vectors. Useful for semantically correct but paraphrased answers.

Score: float between -1 and 1 (typically 0.7–1.0 for good answers).

### LLM-as-Judge
Uses a powerful LLM (like GPT-4) to evaluate the quality of an output with respect to criteria.
The judge LLM is given a rubric and the output+reference, then returns a score and reasoning.

Common criteria:
- **Correctness**: Is the answer factually correct?
- **Helpfulness**: Is the answer useful to the user?
- **Conciseness**: Is the answer appropriately brief?
- **Harmlessness**: Does the answer avoid harmful content?

LLM-as-judge is the most flexible evaluator but adds latency and cost per evaluation.

### Custom Evaluators
You can write Python functions that take `run` and `example` objects and return a score dict.
This lets you implement domain-specific logic (e.g., check if a SQL query is valid, verify
JSON schema compliance, measure BLEU/ROUGE scores).

---

## 7. Feedback: Human Feedback Collection

LangSmith supports collecting structured human feedback on individual runs. This is critical for:
- Building RLHF (Reinforcement Learning from Human Feedback) datasets
- Identifying problematic outputs for retraining
- Tracking user satisfaction over time

### Feedback Types

- **Score feedback**: A numeric rating (e.g., 1–5 stars, thumbs up/down as 0/1)
- **Comment feedback**: Free-text annotation explaining the rating
- **Correction feedback**: The correct answer for a run that produced a wrong answer

### Submitting Feedback via SDK

```python
client.create_feedback(
    run_id=run.id,
    key="user_rating",
    score=1,
    comment="This answer was accurate and well-structured"
)
```

### Feedback in Evaluation

You can also submit automated feedback from evaluators. Every evaluator result is stored as
a feedback item on the run with a key (e.g., `"correctness"`) and a score.

---

## 8. Monitoring Dashboards: Latency, Token Usage, Error Rates

LangSmith provides a built-in monitoring dashboard for production applications.

### Latency Metrics
- P50, P90, P99 latency per run type
- Latency breakdown by chain step
- Trends over time (hourly, daily, weekly)
- Slow run identification

### Token Usage
- Total tokens per run (prompt + completion)
- Token trends over time
- Per-model token breakdown
- Token budget alerts

### Error Rates
- Overall error rate percentage
- Error rate by run type
- Error message clustering
- Alert thresholds

### Cost Tracking
LangSmith estimates cost based on token counts and known model pricing. You can see:
- Cost per run
- Total cost per project per day/week
- Cost breakdown by model
- Cost trends and anomalies

---

## 9. LangSmith Hub Integration

The LangSmith Hub is a registry for sharing and discovering prompt templates. Teams can:
- **Publish prompts**: Share reusable prompt templates with version control
- **Pull prompts**: Load community or team prompts directly into your code
- **Version prompts**: Track changes to prompts over time like code
- **Evaluate prompts**: Link prompts to evaluation datasets

### Using Hub Prompts in Code

```python
from langchain import hub
prompt = hub.pull("rlm/rag-prompt")
```

Prompts pulled from the Hub are versioned by commit hash, ensuring reproducibility.

---

## 10. Environment Setup: LANGCHAIN_TRACING_V2, LANGCHAIN_API_KEY

### Required Environment Variables

```
LANGCHAIN_TRACING_V2=true        # Enables automatic tracing
LANGCHAIN_API_KEY=ls__...        # Your LangSmith API key
LANGCHAIN_PROJECT=my-project     # Project name (optional, defaults to "default")
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com  # API endpoint (default)
```

### Getting Your API Key

1. Sign up at https://smith.langchain.com
2. Go to Settings > API Keys
3. Create a new API key and copy it

### Python dotenv Setup

```python
from dotenv import load_dotenv
load_dotenv()  # Loads from .env file
```

### Verifying Setup

```python
from langsmith import Client
client = Client()
print(client.list_projects())  # Should print your projects
```

---

## 11. Custom Metadata and Tags on Runs

Tags and metadata allow fine-grained run organization beyond project grouping.

### Tags
- Flat list of string labels on a run
- Good for categorical filtering: `["production", "v2", "rag"]`
- Can be added at chain invocation time

### Metadata
- Key-value pairs attached to a run
- Good for structured context: `{"user_id": "u123", "session": "s456"}`
- Searchable in the LangSmith UI

### Adding via RunnableConfig

```python
chain.invoke(
    {"question": "What is AI?"},
    config={
        "tags": ["experiment-v2"],
        "metadata": {"user_id": "u123", "ab_group": "B"}
    }
)
```

---

## 12. Filtering and Searching Runs

The LangSmith UI and SDK provide powerful filtering capabilities.

### UI Filters
- Filter by project, date range, run type
- Filter by tag, metadata key/value
- Filter by error status
- Full-text search on inputs/outputs

### SDK Filtering

```python
runs = client.list_runs(
    project_name="my-project",
    filter='has(tags, "production")',
    start_time=datetime(2024, 1, 1),
)
```

### OTEL-style Filter Expressions
LangSmith supports filter expressions for complex queries:
- `eq(metadata_key, "value")` — metadata equality
- `has(tags, "tag-name")` — tag presence
- `gt(latency, 5.0)` — latency threshold
- `and(...)`, `or(...)` — logical combinators

---

## 13. Comparing Runs Across Experiments

LangSmith's experiment comparison view lets you place multiple experiment results side by side.

### How to Compare
1. Run your chain against the same dataset with different configurations
2. Each run creates a named experiment (via `experiment_prefix`)
3. Open the dataset in LangSmith and click "Compare Experiments"
4. Select two or more experiments to compare their scores

### What You Can Compare
- Aggregate scores (mean, median, pass rate) per evaluator
- Individual example results (which examples each experiment got right/wrong)
- Latency distributions per experiment
- Cost per experiment

### Typical Workflow
```
Experiment A: gpt-3.5-turbo, temperature=0.7
Experiment B: gpt-4, temperature=0.2
→ Compare correctness scores across 100 dataset examples
```

---

## 14. CI/CD Testing with LangSmith Datasets

LangSmith integrates into CI/CD pipelines (GitHub Actions, Jenkins, etc.) as a quality gate.

### Workflow
1. Create a golden dataset of representative examples with expected outputs
2. Write a test script that runs your chain against the dataset
3. Apply evaluators and collect aggregate scores
4. Fail the CI job if scores fall below thresholds

### Pass/Fail Logic

```python
results = evaluate(chain, data="golden-dataset", evaluators=[correctness])
avg_score = sum(r["results"][0]["score"] for r in results) / len(results)
assert avg_score >= 0.85, f"Quality regression: {avg_score}"
```

### Benefits
- Prevents deploying regressions
- Tracks quality trends over time
- Makes LLM behavior testable like traditional software

---

## 15. Cost Tracking Per Run

LangSmith automatically estimates cost for OpenAI and Anthropic models based on token counts.

### How Cost Is Calculated
- LangSmith stores token counts from the model's response metadata
- It applies known per-token pricing (e.g., GPT-4: $0.03/1K prompt tokens)
- Cost is shown per run and aggregated per project/time window

### Viewing Costs
- In the UI: Project dashboard → Cost tab
- In the SDK: `run.total_cost` (if available)

### Custom Cost Tracking
For custom or private models, you can add cost as metadata:

```python
with langsmith.trace("my-run") as run:
    result = my_model(prompt)
    run.metadata["estimated_cost_usd"] = calculate_cost(tokens_used)
```

### Cost Optimization Workflow
1. Identify high-cost runs via the dashboard
2. Examine their token counts and prompts
3. Optimize prompts to reduce token usage
4. Re-evaluate quality to confirm the optimization didn't hurt accuracy

---

## Summary

LangSmith is the observability backbone for production LLM applications. Its tracing, evaluation,
feedback, and monitoring capabilities transform LLM development from a guesswork exercise into
a disciplined engineering practice. Whether you are debugging a one-off failure, running systematic
evaluations before a release, or monitoring a live system, LangSmith provides the tools to
understand and improve your LLM applications at every stage of their lifecycle.