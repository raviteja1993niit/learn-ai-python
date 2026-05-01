# LangSmith Examples Guide

A collection of 15 annotated, working Python code examples covering all major LangSmith features.

---

## Example 1: Environment Setup and Initialization

Before using LangSmith, configure your environment. Use a `.env` file to keep credentials out of code.

```python
# .env file contents:
# LANGCHAIN_TRACING_V2=true
# LANGCHAIN_API_KEY=ls__your_key_here
# LANGCHAIN_PROJECT=my-langsmith-project

import os
from dotenv import load_dotenv
from langsmith import Client

# Load environment variables from .env
load_dotenv()

# Verify the variables are loaded
print("Tracing enabled:", os.getenv("LANGCHAIN_TRACING_V2"))
print("Project:", os.getenv("LANGCHAIN_PROJECT"))

# Create the LangSmith client
client = Client()

# Test connection by listing projects
projects = list(client.list_projects())
print(f"Found {len(projects)} projects")
for p in projects:
    print(f"  - {p.name}")
```

**Key Points:**
- `LANGCHAIN_TRACING_V2=true` activates automatic tracing for all LangChain operations
- `LANGCHAIN_API_KEY` authenticates with the LangSmith API
- `LANGCHAIN_PROJECT` sets the default project for all runs
- The `Client` object is the programmatic entry point for the LangSmith SDK

---

## Example 2: Basic Tracing of a Chain

With tracing enabled, all LangChain operations are automatically recorded.

```python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

load_dotenv()

# Build a simple LCEL chain
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant. Answer concisely."),
    ("human", "{question}")
])

llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)
parser = StrOutputParser()

chain = prompt | llm | parser

# Invoke the chain — this is automatically traced!
response = chain.invoke({"question": "What is LangSmith used for?"})
print(response)

# Every step (prompt formatting, LLM call, output parsing) appears
# as a nested run in the LangSmith UI under your project.
```

**Key Points:**
- No extra code needed — tracing is fully automatic when env vars are set
- The trace shows the prompt template, the formatted messages, the LLM response, and the parsed output
- Latency is recorded for each step
- Token counts are captured from the OpenAI response metadata

---

## Example 3: Adding Metadata to Runs

Metadata lets you attach contextual information to runs for filtering and analysis.

```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_template("Summarize this text: {text}")
llm = ChatOpenAI(model="gpt-3.5-turbo")
chain = prompt | llm | StrOutputParser()

# Pass metadata and tags via RunnableConfig
response = chain.invoke(
    {"text": "LangSmith is a platform for LLM observability and evaluation."},
    config={
        "tags": ["summarization", "v2-experiment"],
        "metadata": {
            "user_id": "user_42",
            "session_id": "sess_abc123",
            "content_type": "technical",
            "experiment": "prompt-v2"
        },
        "run_name": "summarize-technical-doc"
    }
)

print(response)
# In LangSmith UI: filter by tag "summarization" or metadata "user_id=user_42"
```

**Key Points:**
- `tags` is a list of strings — good for categorical grouping
- `metadata` is a dict — good for structured attributes like user/session IDs
- `run_name` overrides the default run name in the UI for clarity
- These fields are indexed and searchable in LangSmith

---

## Example 4: Creating a Dataset Manually

Datasets are collections of input/output pairs used for evaluation.

```python
from langsmith import Client

client = Client()

# Define your examples
examples = [
    {
        "inputs": {"question": "What is the capital of France?"},
        "outputs": {"answer": "Paris"}
    },
    {
        "inputs": {"question": "What is 2 + 2?"},
        "outputs": {"answer": "4"}
    },
    {
        "inputs": {"question": "Who wrote Hamlet?"},
        "outputs": {"answer": "William Shakespeare"}
    },
    {
        "inputs": {"question": "What is the speed of light?"},
        "outputs": {"answer": "299,792,458 meters per second"}
    },
]

# Create the dataset (or get existing)
dataset_name = "factual-qa-v1"

try:
    dataset = client.create_dataset(
        dataset_name=dataset_name,
        description="Factual Q&A examples for regression testing"
    )
    print(f"Created dataset: {dataset.id}")
except Exception:
    dataset = client.read_dataset(dataset_name=dataset_name)
    print(f"Using existing dataset: {dataset.id}")

# Add examples to the dataset
for ex in examples:
    client.create_example(
        inputs=ex["inputs"],
        outputs=ex["outputs"],
        dataset_id=dataset.id
    )

print(f"Added {len(examples)} examples to '{dataset_name}'")
```

**Key Points:**
- Datasets are versioned and immutable once examples are added
- `inputs` maps to what your chain receives; `outputs` is the reference/expected answer
- You can add examples incrementally over time
- Datasets survive across sessions and are shared with your team

---

## Example 5: Creating a Dataset from Runs

Promote interesting production traces directly to a dataset.

```python
from langsmith import Client
from datetime import datetime, timedelta

client = Client()

# List recent runs from production project
runs = client.list_runs(
    project_name="production",
    run_type="chain",
    start_time=datetime.utcnow() - timedelta(days=1),
    filter='eq(metadata_key["quality"], "high")',
    limit=50
)

# Create a new dataset
dataset = client.create_dataset(
    dataset_name="production-golden-set",
    description="High-quality production runs promoted to golden dataset"
)

# Add each run as a dataset example
added = 0
for run in runs:
    if run.outputs:  # Only add runs that have outputs
        client.create_example(
            inputs=run.inputs,
            outputs=run.outputs,
            dataset_id=dataset.id,
            source_run_id=run.id  # Links back to the original trace
        )
        added += 1

print(f"Added {added} examples from production runs")
```

**Key Points:**
- `source_run_id` links each example back to the original trace for audit trail
- Filtering by metadata lets you select only high-quality or manually reviewed runs
- This workflow is common for bootstrapping evaluation datasets from real usage

---

## Example 6: Running an Evaluation with Exact Match

Run systematic evaluation against a dataset using the exact match evaluator.

```python
from langsmith import Client
from langsmith.evaluation import evaluate, ExactMatchStringEvaluator

client = Client()

# Define the function to evaluate
def answer_question(inputs: dict) -> dict:
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.output_parsers import StrOutputParser

    prompt = ChatPromptTemplate.from_template(
        "Answer this question with a single short phrase: {question}"
    )
    chain = prompt | ChatOpenAI(model="gpt-3.5-turbo", temperature=0) | StrOutputParser()
    answer = chain.invoke({"question": inputs["question"]})
    return {"answer": answer.strip()}

# Run evaluation
results = evaluate(
    answer_question,
    data="factual-qa-v1",
    evaluators=[ExactMatchStringEvaluator()],
    experiment_prefix="exact-match-gpt35",
    metadata={"model": "gpt-3.5-turbo", "temperature": 0}
)

print(f"Experiment URL: {results.experiment_results_url}")
```

**Key Points:**
- `evaluate()` iterates over all dataset examples, runs your function, applies evaluators
- `ExactMatchStringEvaluator` does case-sensitive string comparison by default
- Results are stored in LangSmith as a named experiment for later comparison
- `experiment_prefix` helps you identify experiments in the UI

---

## Example 7: LLM-as-Judge Evaluator

Use GPT-4 to judge the correctness and helpfulness of your chain's outputs.

```python
from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langchain_openai import ChatOpenAI

# Create an LLM-as-judge evaluator for correctness
correctness_evaluator = LangChainStringEvaluator(
    "criteria",
    config={
        "criteria": {
            "correctness": "Is the answer factually correct and complete?"
        },
        "llm": ChatOpenAI(model="gpt-4", temperature=0)
    },
    prepare_data=lambda run, example: {
        "prediction": run.outputs.get("answer", ""),
        "reference": example.outputs.get("answer", ""),
        "input": example.inputs.get("question", "")
    }
)

# Create a helpfulness evaluator
helpfulness_evaluator = LangChainStringEvaluator(
    "criteria",
    config={
        "criteria": {
            "helpfulness": "Is the answer helpful and actionable for the user?"
        },
        "llm": ChatOpenAI(model="gpt-4", temperature=0)
    }
)

def my_chain(inputs: dict) -> dict:
    from langchain_openai import ChatOpenAI
    from langchain_core.output_parsers import StrOutputParser
    from langchain_core.prompts import ChatPromptTemplate
    prompt = ChatPromptTemplate.from_template("{question}")
    answer = (prompt | ChatOpenAI(model="gpt-3.5-turbo") | StrOutputParser()).invoke(inputs)
    return {"answer": answer}

results = evaluate(
    my_chain,
    data="factual-qa-v1",
    evaluators=[correctness_evaluator, helpfulness_evaluator],
    experiment_prefix="llm-judge-experiment"
)
```

**Key Points:**
- LLM-as-judge is flexible but adds latency and cost per evaluation
- GPT-4 is recommended as judge; it has better instruction following than GPT-3.5
- `prepare_data` maps run/example fields to prediction/reference/input
- Each judge produces a score (1=pass, 0=fail) and a reasoning string

---

## Example 8: Embedding Similarity Evaluator

Measure semantic similarity between outputs and references using embeddings.

```python
from langsmith.evaluation import evaluate
from langchain.evaluation import load_evaluator
from langchain_openai import OpenAIEmbeddings

# Load embedding similarity evaluator
embedding_evaluator = load_evaluator(
    "embedding_distance",
    embeddings=OpenAIEmbeddings(),
    distance_metric="cosine"
)

def wrap_for_langsmith(run, example):
    return embedding_evaluator.evaluate_strings(
        prediction=run.outputs.get("answer", ""),
        reference=example.outputs.get("answer", "")
    )

from langsmith.evaluation import evaluate, EvaluationResult

def my_embedding_evaluator(run, example):
    result = wrap_for_langsmith(run, example)
    return EvaluationResult(
        key="embedding_similarity",
        score=1 - result["score"],  # Convert distance to similarity
        comment=f"Cosine distance: {result['score']:.4f}"
    )

def my_chain(inputs: dict) -> dict:
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.output_parsers import StrOutputParser
    prompt = ChatPromptTemplate.from_template("Answer briefly: {question}")
    answer = (prompt | ChatOpenAI(model="gpt-3.5-turbo") | StrOutputParser()).invoke(inputs)
    return {"answer": answer}

results = evaluate(
    my_chain,
    data="factual-qa-v1",
    evaluators=[my_embedding_evaluator],
    experiment_prefix="embedding-sim-test"
)
```

**Key Points:**
- Cosine distance of 0 means identical vectors; 1 means orthogonal
- Good threshold: similarity > 0.85 for semantically correct answers
- Embedding similarity is cheaper than LLM-as-judge but less nuanced
- Combine with exact match for a balanced evaluation suite

---

## Example 9: Human Feedback Submission

Attach human ratings and corrections to runs programmatically.

```python
from langsmith import Client
from datetime import datetime, timedelta

client = Client()

# Retrieve recent runs to review
runs = list(client.list_runs(
    project_name="production",
    run_type="chain",
    start_time=datetime.utcnow() - timedelta(hours=1),
    limit=5
))

if runs:
    run = runs[0]
    print(f"Reviewing run: {run.id}")
    print(f"Input: {run.inputs}")
    print(f"Output: {run.outputs}")

    # Submit a thumbs-up rating
    client.create_feedback(
        run_id=run.id,
        key="user_rating",
        score=1,        # 1 = positive, 0 = negative
        comment="The answer was accurate and well-explained."
    )

    # Submit a correction if the answer was wrong
    client.create_feedback(
        run_id=run.id,
        key="correction",
        value="The correct answer should be: Paris, France (the full name)",
        score=0
    )

    # Submit a relevance score (numeric scale)
    client.create_feedback(
        run_id=run.id,
        key="relevance",
        score=0.9,
        comment="Highly relevant, slightly off-topic at the end"
    )

    print("Feedback submitted successfully")
```

**Key Points:**
- Feedback keys are user-defined strings — use consistent naming across your team
- `score` is a float; use 0/1 for binary or 0.0–1.0 for continuous ratings
- `value` is a string for free-text feedback (corrections, notes)
- Feedback is searchable and aggregatable in the LangSmith dashboard

---

## Example 10: Custom Evaluator Function

Write a domain-specific evaluator using pure Python logic.

```python
from langsmith.evaluation import evaluate, EvaluationResult
import json
import re

def json_validity_evaluator(run, example) -> EvaluationResult:
    """Checks if the model output is valid JSON."""
    output = run.outputs.get("answer", "") if run.outputs else ""

    # Try to extract JSON from the output
    json_match = re.search(r'\{.*\}', output, re.DOTALL)
    if json_match:
        try:
            parsed = json.loads(json_match.group())
            return EvaluationResult(
                key="json_valid",
                score=1,
                comment=f"Valid JSON with keys: {list(parsed.keys())}"
            )
        except json.JSONDecodeError as e:
            return EvaluationResult(
                key="json_valid",
                score=0,
                comment=f"Invalid JSON: {str(e)}"
            )
    else:
        return EvaluationResult(
            key="json_valid",
            score=0,
            comment="No JSON object found in output"
        )

def json_chain(inputs: dict) -> dict:
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.output_parsers import StrOutputParser
    prompt = ChatPromptTemplate.from_template(
        "Return a JSON object with 'name' and 'value' keys for: {item}"
    )
    result = (prompt | ChatOpenAI(model="gpt-3.5-turbo") | StrOutputParser()).invoke(inputs)
    return {"answer": result}

results = evaluate(
    json_chain,
    data="my-json-dataset",
    evaluators=[json_validity_evaluator],
    experiment_prefix="json-output-test"
)
```

---

## Example 11: Tagging Runs

Apply tags at invocation time for later filtering.

```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

chain = (
    ChatPromptTemplate.from_template("{input}")
    | ChatOpenAI(model="gpt-3.5-turbo")
    | StrOutputParser()
)

# Tag by model version and feature
result_v1 = chain.invoke(
    {"input": "Explain neural networks"},
    config={"tags": ["model-v1", "education", "neural-networks"]}
)

# Tag for A/B testing
result_v2 = chain.invoke(
    {"input": "Explain neural networks"},
    config={"tags": ["model-v2", "education", "neural-networks", "ab-test-B"]}
)

print("V1:", result_v1[:100])
print("V2:", result_v2[:100])
# Filter by "ab-test-B" in LangSmith UI to see variant B traces only
```

---

## Example 12: Filtering Runs by Tag/Metadata

Query runs programmatically using the SDK filter language.

```python
from langsmith import Client
from datetime import datetime, timedelta

client = Client()

# Filter runs tagged with "production" from the last 7 days
prod_runs = list(client.list_runs(
    project_name="my-project",
    filter='has(tags, "production")',
    start_time=datetime.utcnow() - timedelta(days=7),
    run_type="chain",
    limit=100
))
print(f"Production runs (last 7d): {len(prod_runs)}")

# Filter by metadata key-value
user_runs = list(client.list_runs(
    project_name="my-project",
    filter='eq(metadata_key["user_id"], "user_42")',
    limit=50
))
print(f"Runs for user_42: {len(user_runs)}")

# Filter failed runs
error_runs = list(client.list_runs(
    project_name="my-project",
    filter='eq(error, "true")',
    start_time=datetime.utcnow() - timedelta(days=1)
))
print(f"Failed runs (last 24h): {len(error_runs)}")
for r in error_runs[:3]:
    print(f"  Run {r.id}: {r.error[:80] if r.error else 'unknown'}")
```

---

## Example 13: Comparing Experiment Results

Run the same dataset twice with different configurations and compare.

```python
from langsmith.evaluation import evaluate, ExactMatchStringEvaluator
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

def make_chain(model: str, temperature: float):
    prompt = ChatPromptTemplate.from_template(
        "Answer this question accurately and briefly: {question}"
    )
    return prompt | ChatOpenAI(model=model, temperature=temperature) | StrOutputParser()

def run_experiment(model: str, temperature: float, prefix: str):
    chain = make_chain(model, temperature)
    def predict(inputs):
        return {"answer": chain.invoke(inputs)}
    return evaluate(
        predict,
        data="factual-qa-v1",
        evaluators=[ExactMatchStringEvaluator()],
        experiment_prefix=prefix,
        metadata={"model": model, "temperature": temperature}
    )

# Run two experiments
results_a = run_experiment("gpt-3.5-turbo", 0.0, "gpt35-temp0")
results_b = run_experiment("gpt-4", 0.0, "gpt4-temp0")

print("Experiment A URL:", results_a.experiment_results_url)
print("Experiment B URL:", results_b.experiment_results_url)
print("Open LangSmith and use 'Compare' to see side-by-side results")
```

---

## Example 14: CI/CD Dataset Test

Use LangSmith datasets as quality gates in your CI pipeline.

```python
"""
ci_test.py - Run this in GitHub Actions or any CI system.
Exit code 0 = pass, exit code 1 = quality regression detected.
"""
import sys
from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

PASS_THRESHOLD = 0.80  # 80% correctness required

def production_chain(inputs: dict) -> dict:
    prompt = ChatPromptTemplate.from_template(
        "You are a helpful assistant. Answer accurately: {question}"
    )
    answer = (
        prompt
        | ChatOpenAI(model="gpt-3.5-turbo", temperature=0)
        | StrOutputParser()
    ).invoke(inputs)
    return {"answer": answer}

evaluator = LangChainStringEvaluator(
    "criteria",
    config={"criteria": {"correctness": "Is the answer factually correct?"}}
)

results = evaluate(
    production_chain,
    data="factual-qa-v1",
    evaluators=[evaluator],
    experiment_prefix="ci-run"
)

# Collect scores
scores = [
    r["evaluation_results"]["results"][0].score
    for r in results
    if r.get("evaluation_results")
]

if scores:
    avg_score = sum(scores) / len(scores)
    print(f"Average correctness: {avg_score:.2%}")
    if avg_score < PASS_THRESHOLD:
        print(f"FAIL: Score {avg_score:.2%} below threshold {PASS_THRESHOLD:.2%}")
        sys.exit(1)
    else:
        print(f"PASS: Score {avg_score:.2%} meets threshold")
        sys.exit(0)
else:
    print("WARNING: No scores returned")
    sys.exit(1)
```

---

## Example 15: Cost Tracking Example

Monitor and estimate costs per run using token metadata.

```python
from langsmith import Client
from datetime import datetime, timedelta

client = Client()

# Model pricing (USD per 1000 tokens)
PRICING = {
    "gpt-4": {"input": 0.03, "output": 0.06},
    "gpt-3.5-turbo": {"input": 0.001, "output": 0.002},
    "gpt-4-turbo": {"input": 0.01, "output": 0.03},
}

def estimate_cost(run) -> float:
    """Estimate USD cost of a single LLM run from its token usage."""
    if run.run_type != "llm" or not run.prompt_tokens:
        return 0.0
    model = "gpt-3.5-turbo"  # default
    if run.extra and "invocation_params" in run.extra:
        model = run.extra["invocation_params"].get("model_name", model)
    pricing = PRICING.get(model, {"input": 0.002, "output": 0.002})
    input_cost = (run.prompt_tokens / 1000) * pricing["input"]
    output_cost = (run.completion_tokens or 0) / 1000 * pricing["output"]
    return input_cost + output_cost

# Analyze costs for the past 24 hours
runs = list(client.list_runs(
    project_name="production",
    run_type="llm",
    start_time=datetime.utcnow() - timedelta(hours=24),
    limit=500
))

total_cost = sum(estimate_cost(r) for r in runs)
total_tokens = sum((r.prompt_tokens or 0) + (r.completion_tokens or 0) for r in runs)

print(f"LLM runs analyzed: {len(runs)}")
print(f"Total tokens used: {total_tokens:,}")
print(f"Estimated total cost: ${total_cost:.4f} USD")
print(f"Average cost per run: ${total_cost/len(runs):.6f} USD" if runs else "No runs found")

# Find top 5 most expensive runs
runs_with_cost = [(r, estimate_cost(r)) for r in runs]
runs_with_cost.sort(key=lambda x: x[1], reverse=True)
print("\nTop 5 most expensive runs:")
for run, cost in runs_with_cost[:5]:
    print(f"  Run {str(run.id)[:8]}... | ${cost:.4f} | {run.prompt_tokens}+{run.completion_tokens} tokens")
```

**Key Points:**
- Token counts come from the model API response metadata stored in the run
- Pricing tables need to be maintained manually as model prices change
- LangSmith's dashboard also shows built-in cost estimates for OpenAI/Anthropic models
- Use this data to identify expensive runs and optimize prompts for token efficiency