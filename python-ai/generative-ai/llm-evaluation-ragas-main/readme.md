# 📊 RAGAS & LLM Evaluation — Measuring RAG Pipeline Quality

## What is RAGAS?
RAGAS (Retrieval Augmented Generation Assessment) is an evaluation framework that scores RAG pipelines across four complementary metrics — faithfulness, answer relevancy, context precision, and context recall — using LLMs as judges without requiring human-labeled ground truth. It turns the opaque quality of RAG systems into actionable, reproducible numbers.

## Why Learn It?
- You can't improve what you can't measure — RAGAS makes RAG quality quantifiable
- Catches hallucinations (faithfulness < 1.0) and poor retrieval (context recall ≈ 0) separately
- Integrates with LangSmith and CI/CD pipelines for automated regression testing
- Enables data-driven decisions: which chunking strategy, which model, which retriever is best?

## Key Concepts
```python
from ragas import evaluate, EvaluationDataset
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall,
)
from datasets import Dataset

# Build an evaluation dataset
eval_data = {
    "question": [
        "What is the capital of France?",
        "How does LSTM solve vanishing gradients?",
    ],
    "answer": [
        "The capital of France is Paris.",
        "LSTM uses forget, input, and output gates to control gradient flow.",
    ],
    "contexts": [
        ["France is a country in Western Europe. Its capital city is Paris."],
        ["LSTMs introduce gating mechanisms. The forget gate decides what to drop from cell state."],
    ],
    "ground_truth": [
        "Paris is the capital of France.",
        "LSTM gates regulate information flow, preventing vanishing gradients.",
    ],
}

dataset = EvaluationDataset.from_dict(eval_data)

# Run evaluation
results = evaluate(
    dataset=dataset,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
)
print(results)
# {'faithfulness': 0.96, 'answer_relevancy': 0.91, 'context_precision': 0.88, 'context_recall': 0.84}

df = results.to_pandas()
print(df[["question", "faithfulness", "answer_relevancy"]])

# Custom metric: response conciseness
from ragas.metrics.base import MetricWithLLM
from ragas import SingleTurnSample
from ragas.metrics import BleuScore
bleu = BleuScore()

# LangSmith integration for experiment tracking
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = "rag-evaluation"
# All evaluate() calls now log to LangSmith automatically

# Hallucination detection via faithfulness score
low_faith = df[df["faithfulness"] < 0.7]
print(f"Potentially hallucinated answers:\n{low_faith[['question', 'answer', 'faithfulness']]}")
```

## Learning Path
1. `pip install ragas langchain-openai datasets`
2. Understand the four core metrics: faithfulness (grounded?), answer_relevancy (on-topic?), context_precision (retrieved right docs?), context_recall (retrieved enough?)
3. Build a 20-sample golden evaluation dataset for your RAG app
4. Run `evaluate()` as a baseline before making any pipeline changes
5. Wire RAGAS into a CI/CD step: fail the build if faithfulness drops below a threshold

## What to Build
- [ ] Evaluation harness comparing naive RAG vs advanced RAG on the same 50 questions
- [ ] LangSmith dashboard tracking RAGAS scores across pipeline versions
- [ ] CI/CD evaluation gate: GitHub Action that runs RAGAS and blocks merge if scores regress

## Related Folders
- `generative-ai/rag-advanced-patterns-main/` — the pipeline you are evaluating
- `generative-ai/langchain-main/` — chain orchestration used to build the RAG being tested
- `generative-ai/langsmith-main/` — experiment tracking and tracing platform for LLM apps
