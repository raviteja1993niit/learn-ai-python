# 🧪 DeepEval — LLM Testing Framework

## What is DeepEval?
DeepEval is an open-source LLM evaluation framework that integrates with pytest to test AI outputs systematically. It provides built-in metrics for RAG pipelines, chatbots, and agents. Think of it as pytest for LLMs — run evals in CI/CD just like unit tests.

## Why Learn It?
- Catch regressions when swapping models or prompts
- Measure hallucination, faithfulness, and relevancy with one line of code
- Integrates into GitHub Actions / CI pipelines seamlessly
- Supports RAGAS-style RAG evaluation out of the box
- Custom metrics let you encode domain-specific quality standards

## Key Concepts
```python
import pytest
from deepeval import assert_test, evaluate
from deepeval.test_case import LLMTestCase
from deepeval.metrics import (
    AnswerRelevancyMetric,
    FaithfulnessMetric,
    HallucinationMetric,
    ContextualRecallMetric,
    ToxicityMetric,
)

# --- Single test case ---
test_case = LLMTestCase(
    input="What is the capital of France?",
    actual_output="Paris is the capital of France.",
    expected_output="Paris",
    retrieval_context=["France is a country in Western Europe. Its capital is Paris."],
)

relevancy = AnswerRelevancyMetric(threshold=0.7)
faithfulness = FaithfulnessMetric(threshold=0.8)

assert_test(test_case, [relevancy, faithfulness])

# --- Pytest parametrize integration ---
test_data = [
    ("Who wrote Hamlet?", "Shakespeare wrote Hamlet.", "Shakespeare"),
    ("What is 2+2?", "The answer is 4.", "4"),
]

@pytest.mark.parametrize("input,actual,expected", test_data)
def test_llm_output(input, actual, expected):
    tc = LLMTestCase(input=input, actual_output=actual, expected_output=expected)
    assert_test(tc, [AnswerRelevancyMetric(threshold=0.6)])

# --- Bulk evaluate (no pytest) ---
results = evaluate(
    test_cases=[test_case],
    metrics=[HallucinationMetric(threshold=0.5), ToxicityMetric(threshold=0.3)],
)

# --- Custom metric ---
from deepeval.metrics import BaseMetric

class LengthMetric(BaseMetric):
    def __init__(self, max_length: int = 200):
        self.threshold = max_length

    def measure(self, test_case: LLMTestCase) -> float:
        length = len(test_case.actual_output)
        self.score = 1.0 if length <= self.threshold else 0.0
        self.success = self.score == 1.0
        return self.score

    @property
    def __name__(self):
        return "LengthMetric"
```

## DeepEval vs RAGAS
| Feature              | DeepEval              | RAGAS                  |
|----------------------|-----------------------|------------------------|
| Pytest plugin        | ✅ Native             | ❌ Manual              |
| Custom metrics       | ✅ BaseMetric class   | ⚠️ Limited             |
| CI/CD ready          | ✅ Yes                | ⚠️ Needs wrapping      |
| RAG metrics          | ✅ Yes                | ✅ Yes (primary focus) |
| Non-RAG evals        | ✅ Yes                | ❌ Mostly RAG only     |

## Learning Path
1. Install: `pip install deepeval` and run `deepeval login`
2. Write your first `LLMTestCase` and run `pytest`
3. Add `FaithfulnessMetric` + `ContextualRecallMetric` to a RAG pipeline
4. Wire into GitHub Actions with `pytest --tb=short`
5. Build a custom `BaseMetric` for a domain-specific rule
6. Explore the DeepEval dashboard for metric trends over time

## What to Build
- [ ] Eval suite for a Q&A RAG chatbot (5+ test cases, 3+ metrics)
- [ ] GitHub Actions workflow that blocks merges on metric regression
- [ ] Custom metric that checks output language matches input language
- [ ] Benchmark two different LLM models on the same test suite
- [ ] Toxicity + hallucination report for a customer-facing chatbot

## Related Folders
- `generative-ai/rag-pipeline-main/` — primary system to evaluate with DeepEval
- `generative-ai/prompt-engineering-main/` — prompt changes that need regression testing
- `agentic-ai/agent-evaluation-main/` — agent-level evaluation (trajectory, tool calls)
