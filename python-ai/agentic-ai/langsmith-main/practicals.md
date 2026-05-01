# LangSmith Practicals Guide

Eight hands-on projects to build real LangSmith proficiency. Each project includes a description,
setup steps, implementation hints, and expected outcomes.

---

## Project 1: Instrument a RAG App with Full Tracing

### Objective
Take an existing Retrieval-Augmented Generation (RAG) pipeline and add complete LangSmith tracing
so every step — document retrieval, embedding, prompt formatting, LLM generation — is visible in
the LangSmith UI.

### Setup Steps

1. Install dependencies
   pip install langchain langchain-openai langchain-community faiss-cpu pypdf langsmith python-dotenv

2. Configure environment in .env:
   LANGCHAIN_TRACING_V2=true
   LANGCHAIN_API_KEY=ls__your_key
   LANGCHAIN_PROJECT=rag-tracing-demo
   OPENAI_API_KEY=sk-your_openai_key

3. Build the RAG pipeline

```python
from dotenv import load_dotenv
load_dotenv()

from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain.chains import RetrievalQA

loader = PyPDFLoader("your-document.pdf")
docs = loader.load_and_split()

embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_documents(docs, embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)
chain = RetrievalQA.from_chain_type(llm=llm, retriever=retriever)

result = chain.invoke(
    {"query": "What are the main findings?"},
    config={"tags": ["rag", "pdf-qa"], "metadata": {"doc": "your-document.pdf"}}
)
print(result["result"])
```

4. Inspect in LangSmith UI:
   - Open your project in LangSmith
   - Click on the trace to see the full run tree
   - Examine: retriever run, embedding run, LLM run

### Expected Outcomes
- Full trace hierarchy visible in LangSmith
- Retrieval latency clearly separated from LLM latency
- Retrieved document chunks visible in the trace

### Hints
- Use run_name in config for descriptive top-level run names
- Add user_id in metadata to track per-user queries
- Use the LangSmith Threads feature to group multi-turn conversations

---

## Project 2: Build an Evaluation Dataset for a Q&A Bot

### Objective
Create a comprehensive evaluation dataset by combining manually authored examples with
promoted production traces. Use this dataset to benchmark your Q&A bot.

### Setup Steps

1. Author seed examples manually

```python
from langsmith import Client
client = Client()

seed_examples = [
    {"inputs": {"question": "What is RAG?"},
     "outputs": {"answer": "Retrieval-Augmented Generation, combining retrieval with generation"}},
    {"inputs": {"question": "What is LangChain?"},
     "outputs": {"answer": "A framework for building LLM-powered applications"}},
    {"inputs": {"question": "What is a vector database?"},
     "outputs": {"answer": "A database optimized for storing and querying high-dimensional vectors"}},
]

dataset = client.create_dataset("qa-bot-eval-v1", description="Q&A bot evaluation set")
for ex in seed_examples:
    client.create_example(inputs=ex["inputs"], outputs=ex["outputs"], dataset_id=dataset.id)
print(f"Created dataset with {len(seed_examples)} examples")
```

2. Run your bot on real user queries for one day with tracing enabled

3. Promote good production traces to the dataset

```python
good_runs = client.list_runs(
    project_name="production",
    filter='has(tags, "reviewed-good")',
    limit=20
)
for run in good_runs:
    client.create_example(
        inputs=run.inputs,
        outputs=run.outputs,
        dataset_id=dataset.id,
        source_run_id=run.id
    )
```

4. Review and curate examples in the LangSmith UI

### Expected Outcomes
- A dataset with 20+ diverse examples
- Mix of easy, medium, and hard questions
- Reference answers that are ground-truth verified

### Hints
- Aim for variety: different question types, lengths, and topics
- Include edge cases: out-of-domain questions, ambiguous queries
- Version dataset names (v1, v2) to track evolution over time

---

## Project 3: LLM-as-Judge Quality Evaluator

### Objective
Build a multi-criteria LLM-as-judge evaluator that rates responses on correctness,
helpfulness, and conciseness. Deploy it against your Q&A dataset.

### Setup Steps

1. Define multi-criteria evaluators

```python
from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langchain_openai import ChatOpenAI

judge_llm = ChatOpenAI(model="gpt-4", temperature=0)

criteria_evaluators = [
    LangChainStringEvaluator("criteria", config={
        "criteria": {"correctness": "Is the answer factually accurate?"},
        "llm": judge_llm
    }),
    LangChainStringEvaluator("criteria", config={
        "criteria": {"helpfulness": "Does the answer address the user's need clearly?"},
        "llm": judge_llm
    }),
    LangChainStringEvaluator("criteria", config={
        "criteria": {"conciseness": "Is the answer free of unnecessary verbosity?"},
        "llm": judge_llm
    }),
]
```

2. Define your chain and run evaluation

```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

def my_qa_chain(inputs: dict) -> dict:
    prompt = ChatPromptTemplate.from_template("Answer accurately: {question}")
    answer = (prompt | ChatOpenAI(model="gpt-3.5-turbo") | StrOutputParser()).invoke(inputs)
    return {"answer": answer}

results = evaluate(
    my_qa_chain,
    data="qa-bot-eval-v1",
    evaluators=criteria_evaluators,
    experiment_prefix="llm-judge-v1"
)
```

3. Analyze dimension scores in LangSmith UI

### Expected Outcomes
- Scores per dimension per example
- Ability to identify which dimension your bot struggles with most
- Baseline for future prompt optimization

### Hints
- Use GPT-4 not GPT-3.5 as the judge for better calibration
- Run evaluation before and after a prompt change to measure improvement
- Add prepare_data lambda to map run/example fields if needed

---

## Project 4: Compare Two Prompt Versions

### Objective
A/B test two prompt templates against the same dataset to determine which produces better outputs.

### Setup Steps

1. Define two prompt variants

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import StrOutputParser

prompt_v1 = ChatPromptTemplate.from_messages([
    ("system", "Answer questions accurately."),
    ("human", "{question}")
])

prompt_v2 = ChatPromptTemplate.from_messages([
    ("system", "You are an expert assistant. Provide accurate, detailed answers with examples."),
    ("human", "{question}")
])

llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)

def chain_v1(inputs):
    return {"answer": (prompt_v1 | llm | StrOutputParser()).invoke(inputs)}

def chain_v2(inputs):
    return {"answer": (prompt_v2 | llm | StrOutputParser()).invoke(inputs)}
```

2. Run both experiments against the same dataset

```python
from langsmith.evaluation import evaluate, LangChainStringEvaluator

evaluator = LangChainStringEvaluator("criteria", config={
    "criteria": {"correctness": "Is the answer correct?"}
})

exp_v1 = evaluate(chain_v1, data="qa-bot-eval-v1", evaluators=[evaluator],
                  experiment_prefix="prompt-v1")
exp_v2 = evaluate(chain_v2, data="qa-bot-eval-v1", evaluators=[evaluator],
                  experiment_prefix="prompt-v2")

print("Experiment A:", exp_v1.experiment_results_url)
print("Experiment B:", exp_v2.experiment_results_url)
```

3. Open LangSmith > Dataset > Compare Experiments, select both

### Expected Outcomes
- Clear winner between prompts based on correctness scores
- Per-example breakdown showing where each prompt wins/loses
- Data-driven prompt selection instead of guesswork

### Hints
- Keep everything else constant (model, temperature, dataset) to isolate the variable
- Check score variance, not just mean — consistent medium may beat inconsistent high

---

## Project 5: Set Up Automated Regression Testing

### Objective
Build a CI/CD quality gate that prevents deploying a change that degrades quality below a threshold.

### Setup Steps

1. Create tests/test_quality.py

```python
import sys
from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

QUALITY_THRESHOLD = 0.75

def production_chain(inputs: dict) -> dict:
    prompt = ChatPromptTemplate.from_template("{question}")
    answer = (prompt | ChatOpenAI(model="gpt-3.5-turbo", temperature=0) | StrOutputParser()).invoke(inputs)
    return {"answer": answer}

def test_quality_regression():
    evaluator = LangChainStringEvaluator("criteria", config={
        "criteria": {"correctness": "Is the answer correct?"}
    })
    results = evaluate(
        production_chain,
        data="factual-qa-v1",
        evaluators=[evaluator],
        experiment_prefix="ci-regression-test"
    )
    scores = [
        r["evaluation_results"]["results"][0].score
        for r in results if r.get("evaluation_results")
    ]
    avg = sum(scores) / len(scores) if scores else 0
    assert avg >= QUALITY_THRESHOLD, f"Quality regression: {avg:.2%} < {QUALITY_THRESHOLD:.2%}"
```

2. Create .github/workflows/quality.yml

```yaml
name: Quality Gate
on: [pull_request]
jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - run: pytest tests/test_quality.py -v
        env:
          LANGCHAIN_TRACING_V2: "true"
          LANGCHAIN_API_KEY: ${{ secrets.LANGCHAIN_API_KEY }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

### Expected Outcomes
- CI fails automatically when quality drops below threshold
- Each CI run creates a new LangSmith experiment
- Quality trend visible over time across commits

### Hints
- Start with a permissive threshold (0.5) and raise it over time
- Use a fast, small dataset (10-20 examples) for CI to keep runtime under 2 minutes
- Store thresholds in environment variables to adjust without code changes

---

## Project 6: Monitor Production Latency and Cost

### Objective
Set up a monitoring script that queries LangSmith daily for latency and cost metrics,
and alerts when thresholds are exceeded.

### Setup Steps

1. Write monitor.py

```python
from langsmith import Client
from datetime import datetime, timedelta
import statistics

client = Client()
PRICING = {
    "gpt-4": {"input": 0.03, "output": 0.06},
    "gpt-3.5-turbo": {"input": 0.001, "output": 0.002},
}

runs = list(client.list_runs(
    project_name="production",
    run_type="chain",
    start_time=datetime.utcnow() - timedelta(days=1),
    limit=1000
))

latencies = [
    (r.end_time - r.start_time).total_seconds()
    for r in runs if r.end_time and r.start_time
]

errors = [r for r in runs if r.error]
error_rate = len(errors) / len(runs) if runs else 0

print(f"Runs last 24h:    {len(runs)}")
print(f"Avg latency:      {statistics.mean(latencies):.2f}s")
print(f"P95 latency:      {sorted(latencies)[int(len(latencies)*0.95)]:.2f}s")
print(f"Error rate:       {error_rate:.1%}")

LATENCY_ALERT = 10.0
ERROR_ALERT = 0.05
if statistics.mean(latencies) > LATENCY_ALERT:
    print(f"ALERT: Latency {statistics.mean(latencies):.1f}s exceeds {LATENCY_ALERT}s")
if error_rate > ERROR_ALERT:
    print(f"ALERT: Error rate {error_rate:.1%} exceeds {ERROR_ALERT:.1%}")
```

2. Schedule with cron (Linux) or Task Scheduler (Windows)
3. Pipe output to Slack or email using webhooks

### Expected Outcomes
- Daily health report with latency, error rate, and cost summary
- Automatic alerts when metrics exceed thresholds
- Historical trend data stored in LangSmith for deeper analysis

### Hints
- Cache the run list locally if you query multiple times per day
- Add token-based cost estimation per model using pricing tables
- Use LangSmith's native dashboard for real-time monitoring between scheduled runs

---

## Project 7: Collect and Analyze Human Feedback

### Objective
Build a feedback collection loop where end-users rate responses, and you analyze feedback
in bulk to identify systematic problems.

### Setup Steps

1. Integrate feedback collection into your app

```python
from langsmith import Client

client = Client()

def submit_user_feedback(run_id: str, rating: int, comment: str = ""):
    """Call this after the user rates a response. rating: 1-5."""
    client.create_feedback(
        run_id=run_id,
        key="user_rating",
        score=rating / 5.0,
        comment=comment
    )

def flag_bad_response(run_id: str, correct_answer: str):
    """Call this when a user reports an incorrect answer."""
    client.create_feedback(
        run_id=run_id,
        key="correction",
        score=0,
        value=correct_answer
    )
```

2. Analyze feedback in bulk

```python
from langsmith import Client
import statistics

client = Client()
feedbacks = list(client.list_feedback(
    project_name="production",
    feedback_key=["user_rating"],
    limit=500
))

scores = [f.score for f in feedbacks if f.score is not None]
print(f"Total feedback:    {len(scores)}")
print(f"Average rating:    {statistics.mean(scores):.3f}")
print(f"Positive (>=0.6):  {sum(1 for s in scores if s >= 0.6)/len(scores):.1%}")
print(f"Negative (<0.4):   {sum(1 for s in scores if s < 0.4)/len(scores):.1%}")
```

3. Dig into low-rated runs to find patterns

```python
low_rated = [f for f in feedbacks if f.score is not None and f.score < 0.4]
print(f"Low-rated runs: {len(low_rated)}")
for fb in low_rated[:5]:
    run = client.read_run(str(fb.run_id))
    print(f"Input: {run.inputs}")
    print(f"Output: {str(run.outputs)[:80]}")
    print(f"Comment: {fb.comment}")
    print("---")
```

### Expected Outcomes
- Quantitative view of user satisfaction
- Identification of run patterns correlated with low ratings
- Correction examples ready to add to evaluation dataset

---

## Project 8: Build a CI/CD Pipeline with Dataset Tests

### Objective
Create a complete end-to-end CI/CD workflow where every pull request is tested against a
LangSmith dataset before merging, with the experiment URL posted as a PR comment.

### Setup Steps

1. Create src/evaluate_pr.py

```python
import sys
import os
from langsmith.evaluation import evaluate, ExactMatchStringEvaluator, LangChainStringEvaluator
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

PR_NUMBER = os.getenv("PR_NUMBER", "unknown")
COMMIT_SHA = os.getenv("COMMIT_SHA", "unknown")[:7]
THRESHOLD = float(os.getenv("QUALITY_THRESHOLD", "0.7"))

def build_chain():
    prompt = ChatPromptTemplate.from_template("You are a helpful assistant. {question}")
    return prompt | ChatOpenAI(model="gpt-3.5-turbo", temperature=0) | StrOutputParser()

def predict(inputs: dict) -> dict:
    return {"answer": build_chain().invoke(inputs)}

results = evaluate(
    predict,
    data="factual-qa-v1",
    evaluators=[
        ExactMatchStringEvaluator(),
        LangChainStringEvaluator("criteria", config={
            "criteria": {"correctness": "Is the answer factually correct?"}
        })
    ],
    experiment_prefix=f"pr-{PR_NUMBER}-{COMMIT_SHA}"
)

print(f"Results URL: {results.experiment_results_url}")

scores = [
    r["evaluation_results"]["results"][0].score
    for r in results if r.get("evaluation_results")
]
avg = sum(scores) / len(scores) if scores else 0
print(f"Average score: {avg:.2%}")

if avg < THRESHOLD:
    print(f"FAIL: {avg:.2%} below threshold {THRESHOLD:.0%}")
    sys.exit(1)

print(f"PASS: {avg:.2%} meets threshold {THRESHOLD:.0%}")
sys.exit(0)
```

2. Create .github/workflows/eval.yml

```yaml
name: LangSmith Evaluation
on:
  pull_request:
    branches: [main]
jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with: { python-version: "3.11" }
      - run: pip install langsmith langchain langchain-openai python-dotenv
      - name: Run LangSmith evaluation
        run: python src/evaluate_pr.py
        env:
          PR_NUMBER: ${{ github.event.number }}
          COMMIT_SHA: ${{ github.sha }}
          QUALITY_THRESHOLD: "0.70"
          LANGCHAIN_TRACING_V2: "true"
          LANGCHAIN_API_KEY: ${{ secrets.LANGCHAIN_API_KEY }}
          LANGCHAIN_PROJECT: ci-evaluations
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

3. Set as required status check:
   GitHub repo > Settings > Branches > Branch protection rules > Add status check

### Expected Outcomes
- Every PR triggers an automatic LangSmith evaluation
- PR cannot be merged if evaluation fails the quality threshold
- Each PR run creates a uniquely named experiment in LangSmith
- Quality history tracked across all commits and PRs

### Hints
- Start with threshold 0.5 and increase as your dataset matures
- Cache pip dependencies in GitHub Actions to speed up CI runs
- Use the GitHub API to post the LangSmith experiment URL as a PR comment
- Add the experiment name pattern pr-{number}-{sha} for easy traceability

---

## Summary

These eight projects cover the full LangSmith lifecycle: from basic instrumentation and dataset
creation, through systematic evaluation and prompt comparison, to production monitoring, feedback
collection, and CI/CD integration. Completing all projects gives you a solid foundation for
maintaining high-quality LLM applications in production.

Each project builds on the previous ones. Start with Project 1 to establish tracing, use
Project 2 to build a dataset, then apply Projects 3-5 for evaluation and testing. Finally,
Projects 6-8 close the loop with production monitoring and automated quality enforcement.