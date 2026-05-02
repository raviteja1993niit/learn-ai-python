# DSPy — Complete Developer Guide

> **Declarative Self-improving Language Programs**
> *Compile prompts instead of writing them.*

---

## Table of Contents

1. [What is DSPy?](#1-what-is-dspy)
2. [Installation & Setup](#2-installation--setup)
3. [Core Concepts](#3-core-concepts)
4. [Signatures](#4-signatures)
5. [Built-in Modules](#5-built-in-modules)
6. [Building Programs (Pipelines)](#6-building-programs-pipelines)
7. [Retrieval & RAG](#7-retrieval--rag)
8. [Optimizers (Teleprompters)](#8-optimizers-teleprompters)
9. [Evaluation & Metrics](#9-evaluation--metrics)
10. [Assertions & Constraints](#10-assertions--constraints)
11. [Saving & Loading](#11-saving--loading)
12. [Real-World Use Cases](#12-real-world-use-cases)
13. [DSPy vs Traditional Prompting](#13-dspy-vs-traditional-prompting)
14. [Interview Q&A](#14-interview-qa)
15. [Complete End-to-End Example](#15-complete-end-to-end-example)

---

## 1. What is DSPy?

**DSPy** (Declarative Self-improving Python) is a framework from Stanford that treats language model pipelines as *programs* rather than *prompt templates*. Instead of hand-crafting prompts, you declare what your program should do and let DSPy's **optimizers** automatically discover the best prompts and few-shot examples.

### The Core Philosophy: "Compile Prompts, Don't Write Them"

In traditional LLM development you spend hours tweaking prompt strings:

```
"You are a helpful assistant. Given a question, answer it concisely.
Question: {question}
Answer:"
```

In DSPy you declare the *contract* — inputs, outputs, and reasoning style — and the optimizer finds the prompt text automatically.

### DSPy vs LangChain

| Dimension | DSPy | LangChain |
|---|---|---|
| **Mental model** | Programming (like PyTorch) | Prompting (like LEGO chains) |
| **Prompt authorship** | Optimizer writes prompts | Developer writes prompts |
| **Iteration loop** | Compile → evaluate → recompile | Edit prompt → test → repeat |
| **Reproducibility** | Systematic via metrics | Manual and fragile |
| **Best for** | NLP tasks with measurable quality | Rapid prototyping, tool chains |
| **Learning curve** | Higher (new abstractions) | Lower (familiar chains) |

### When to Use DSPy

- ✅ You have a **measurable quality metric** (accuracy, F1, BLEU)
- ✅ You need **consistent, reliable outputs** across many inputs
- ✅ You are building multi-step reasoning pipelines
- ✅ You want **automatic few-shot** example selection
- ✅ You need structured / typed outputs
- ❌ One-off scripts or demos where prompt quality is not critical
- ❌ When you have no labeled examples to evaluate against

---

## 2. Installation & Setup

```bash
pip install dspy-ai
# Optional: retrieval backends
pip install faiss-cpu chromadb
```

### GitHub Copilot Free Auth (Azure inference endpoint)

GitHub Copilot subscribers get free access to `gpt-4o-mini` via the GitHub Models endpoint.

```python
import subprocess
import dspy

# Grab the token that `gh auth login` already stored
token = subprocess.run(
    ["gh", "auth", "token"],
    capture_output=True,
    text=True
).stdout.strip()

lm = dspy.LM(
    "openai/gpt-4o-mini",
    api_key=token,
    api_base="https://models.inference.ai.azure.com",
)
dspy.configure(lm=lm)

# Quick smoke-test
response = dspy.Predict("question -> answer")(question="What is 2+2?")
print(response.answer)  # "4"
```

### OpenAI Direct

```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini", api_key="sk-...")
dspy.configure(lm=lm)
```

### Local Model with Ollama

```python
import dspy

# Make sure Ollama is running: `ollama serve`
# Pull a model first:  `ollama pull llama3`
lm = dspy.LM(
    "ollama/llama3",
    api_base="http://localhost:11434",
    api_key="ollama",   # any non-empty string
)
dspy.configure(lm=lm)

result = dspy.Predict("question -> answer")(question="Name a planet.")
print(result.answer)
```

### Using Multiple Models

```python
import dspy

fast_lm  = dspy.LM("openai/gpt-4o-mini", api_key="sk-...")
smart_lm = dspy.LM("openai/gpt-4o",      api_key="sk-...")

dspy.configure(lm=fast_lm)  # default

# Override per-module
class SmartModule(dspy.Module):
    def __init__(self):
        self.reason = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        with dspy.context(lm=smart_lm):       # use the bigger model here
            return self.reason(question=question)
```

---

## 3. Core Concepts

DSPy has five building blocks. Learn these and everything else falls into place.

```
┌─────────────────────────────────────────────────────────────┐
│                        DSPy Program                         │
│                                                             │
│  Signature  →  Module  →  Module  →  Module                 │
│  (contract)    (unit)     (unit)     (unit)                 │
│                    ↑                                        │
│              Optimizer auto-fills prompts & examples        │
│                    ↑                                        │
│              Metric  (tells optimizer what "good" means)    │
└─────────────────────────────────────────────────────────────┘
```

### Signature

A **Signature** is a declarative input/output specification — it says *what* to do, not *how*. DSPy uses it to construct the actual LLM prompt.

```python
"question -> answer"                        # inline string signature
"context, question -> answer"               # multiple inputs
"document -> summary, keywords"             # multiple outputs
```

### Module

A **Module** wraps an LLM call (or a chain of them) and is composable — just like `nn.Module` in PyTorch. Every module has a `forward()` method.

```python
class MyModule(dspy.Module):
    def __init__(self):
        self.predict = dspy.Predict("question -> answer")

    def forward(self, question):
        return self.predict(question=question)
```

### Program

A **Program** is a module whose `forward()` chains other modules together. There is no special `Program` class — any `dspy.Module` subclass with multiple child modules is a program.

### Optimizer (Teleprompter)

An **Optimizer** (historically called a *teleprompter*) takes your program + training data + metric and automatically:

1. Generates candidate demonstrations (few-shot examples)
2. Evaluates each candidate with your metric
3. Selects the best prompt configuration

```python
from dspy.teleprompt import BootstrapFewShot

optimizer = BootstrapFewShot(metric=my_metric)
compiled_program = optimizer.compile(my_program, trainset=train_data)
```

### Metric

A **Metric** is a Python function `(example, prediction, trace=None) -> float | bool`. It is the optimizer's objective.

```python
def my_metric(example, pred, trace=None):
    return pred.answer.lower() == example.answer.lower()
```

---

## 4. Signatures

### 4.1 Inline String Signatures

The fastest way to define a signature. Fields separated by commas on each side of `->`.

```python
import dspy

dspy.configure(lm=dspy.LM("openai/gpt-4o-mini", api_key="sk-..."))

# Single input, single output
qa = dspy.Predict("question -> answer")
result = qa(question="What is the boiling point of water?")
print(result.answer)

# Multiple inputs
summarize = dspy.Predict("title, body -> summary")
result = summarize(title="AI News", body="OpenAI released GPT-5...")
print(result.summary)

# Multiple outputs
extract = dspy.Predict("article -> headline, sentiment, keywords")
result = extract(article="DSPy wins best framework award...")
print(result.headline, result.sentiment, result.keywords)
```

### 4.2 Class-Based Signatures

Use class-based signatures when you need **docstrings** (task instructions) and **field descriptions**.

```python
import dspy

class SentimentClassifier(dspy.Signature):
    """Classify the sentiment of a product review."""

    review: str = dspy.InputField(desc="The raw customer review text")
    sentiment: str = dspy.OutputField(
        desc="One of: positive, negative, neutral"
    )
    confidence: float = dspy.OutputField(
        desc="Confidence score between 0.0 and 1.0"
    )

classify = dspy.Predict(SentimentClassifier)
result = classify(review="This product is absolutely amazing!")
print(result.sentiment)    # "positive"
print(result.confidence)   # 0.95
```

### 4.3 Typed Outputs with Annotations

DSPy respects Python type hints and will coerce / validate outputs.

```python
import dspy
from typing import Literal, List

class EmailRouter(dspy.Signature):
    """Route a support email to the correct department."""

    email_subject: str = dspy.InputField()
    email_body:    str = dspy.InputField()

    department: Literal["billing", "technical", "general"] = dspy.OutputField(
        desc="The department that should handle this email"
    )
    priority: Literal["low", "medium", "high"] = dspy.OutputField(
        desc="Urgency level of the email"
    )
    action_items: List[str] = dspy.OutputField(
        desc="List of specific actions the department should take"
    )

router = dspy.Predict(EmailRouter)
result = router(
    email_subject="Server is down!",
    email_body="Our production API has been unreachable for 30 minutes."
)
print(result.department)    # "technical"
print(result.priority)      # "high"
print(result.action_items)  # ["Check server logs", "Restart service", ...]
```

---

## 5. Built-in Modules

### 5.1 `dspy.Predict` — Basic LM Call

The foundation module. One LLM call, no added reasoning.

```python
import dspy

predict = dspy.Predict("question -> answer")
result = predict(question="Who wrote Hamlet?")
print(result.answer)  # "William Shakespeare"
```

### 5.2 `dspy.ChainOfThought` — Adds Reasoning Steps

Automatically prepends a `reasoning` field, prompting the LLM to think step-by-step before answering. Dramatically improves accuracy on complex tasks.

```python
import dspy

cot = dspy.ChainOfThought("question -> answer")
result = cot(question="If a train travels 60 mph for 2.5 hours, how far does it go?")
print(result.reasoning)  # "Speed × time = 60 × 2.5 = 150 miles"
print(result.answer)     # "150 miles"
```

### 5.3 `dspy.ChainOfThoughtWithHint` — Guided Reasoning

Like CoT but you can supply a hint to steer the reasoning.

```python
import dspy

cot_hint = dspy.ChainOfThoughtWithHint("question -> answer")
result = cot_hint(
    question="What is the capital of the largest country by area?",
    hint="Think about which country occupies the most land mass."
)
print(result.reasoning)
print(result.answer)  # "Moscow"
```

### 5.4 `dspy.ReAct` — Tool-Calling Agent

Implements the ReAct (Reason + Act) loop. Define tools as Python functions and ReAct will decide when to call them.

```python
import dspy
import math

def calculator(expression: str) -> str:
    """Evaluate a mathematical expression safely."""
    try:
        return str(eval(expression, {"__builtins__": {}}, vars(math)))
    except Exception as e:
        return f"Error: {e}"

def web_search(query: str) -> str:
    """Simulate a web search (replace with real search in production)."""
    results = {
        "DSPy author": "DSPy was created by Omar Khattab at Stanford.",
        "Python version": "The latest Python version is 3.12.",
    }
    return results.get(query, "No results found.")

react = dspy.ReAct(
    "question -> answer",
    tools=[calculator, web_search]
)

result = react(question="What is sqrt(144) + 10?")
print(result.answer)  # "22"
```

### 5.5 `dspy.MultiChainComparison` — Ensemble Reasoning

Runs multiple chain-of-thought attempts and synthesizes the best answer.

```python
import dspy

# MultiChainComparison requires a class-based signature
class MathSolver(dspy.Signature):
    """Solve the math problem step by step."""
    problem: str = dspy.InputField()
    answer:  str = dspy.OutputField()

# Runs N independent CoT chains and picks the most consistent answer
multi = dspy.MultiChainComparison(MathSolver, M=3)
result = multi(problem="What is 17 × 23?")
print(result.answer)  # "391"
```

### 5.6 `dspy.ProgramOfThought` — Generates and Executes Code

The LLM writes Python code to solve the problem, which is then executed and the result is returned.

```python
import dspy

class DataQuestion(dspy.Signature):
    """Answer numerical questions by writing and executing Python code."""
    question: str = dspy.InputField()
    answer:   str = dspy.OutputField()

pot = dspy.ProgramOfThought(DataQuestion)
result = pot(
    question="What is the sum of all even numbers from 1 to 100?"
)
print(result.answer)  # "2550"
```

---

## 6. Building Programs (Pipelines)

### 6.1 Composing Modules

```python
import dspy

class ResearchAssistant(dspy.Module):
    def __init__(self):
        # Declare all sub-modules in __init__
        self.decompose  = dspy.ChainOfThought("complex_question -> sub_questions")
        self.answer_sub = dspy.ChainOfThought("sub_question -> sub_answer")
        self.synthesize = dspy.ChainOfThought(
            "complex_question, sub_answers -> final_answer"
        )

    def forward(self, complex_question: str):
        # Step 1: break the question into parts
        decomposed = self.decompose(complex_question=complex_question)
        # sub_questions is a string; split on newlines
        sub_qs = [q.strip() for q in decomposed.sub_questions.split("\n") if q.strip()]

        # Step 2: answer each sub-question
        sub_answers = []
        for sq in sub_qs[:3]:   # limit to 3 to avoid excessive API calls
            ans = self.answer_sub(sub_question=sq)
            sub_answers.append(f"Q: {sq}\nA: {ans.sub_answer}")

        # Step 3: synthesize into a final answer
        combined = "\n\n".join(sub_answers)
        result = self.synthesize(
            complex_question=complex_question,
            sub_answers=combined
        )
        return result

assistant = ResearchAssistant()
out = assistant(
    complex_question="How did the invention of the printing press affect the Renaissance?"
)
print(out.final_answer)
```

### 6.2 Branching and Conditional Logic

```python
import dspy

class SmartQA(dspy.Module):
    """Uses CoT for hard questions, Predict for easy ones."""

    def __init__(self):
        self.classify = dspy.Predict("question -> difficulty")   # easy / hard
        self.simple   = dspy.Predict("question -> answer")
        self.deep     = dspy.ChainOfThought("question -> answer")

    def forward(self, question: str):
        diff = self.classify(question=question)

        if "hard" in diff.difficulty.lower():
            return self.deep(question=question)
        else:
            return self.simple(question=question)

smart = SmartQA()
print(smart(question="What is 2+2?").answer)
print(smart(question="Explain the implications of Gödel's incompleteness theorems.").answer)
```

### 6.3 Full Example — RAG Program (Retrieve → Synthesize → Verify)

```python
import dspy

class RAGSignature(dspy.Signature):
    """Answer a question using retrieved context passages."""
    context:  str = dspy.InputField(desc="Retrieved passages from a knowledge base")
    question: str = dspy.InputField()
    answer:   str = dspy.OutputField(desc="Concise factual answer grounded in context")

class VerifySignature(dspy.Signature):
    """Verify whether an answer is fully supported by the context."""
    context:  str  = dspy.InputField()
    question: str  = dspy.InputField()
    answer:   str  = dspy.InputField()
    supported: str = dspy.OutputField(desc="yes or no")
    correction: str = dspy.OutputField(desc="Corrected answer if not supported, else empty")

class RAGPipeline(dspy.Module):
    def __init__(self, num_passages: int = 3):
        self.retrieve  = dspy.Retrieve(k=num_passages)
        self.synthesize = dspy.ChainOfThought(RAGSignature)
        self.verify    = dspy.Predict(VerifySignature)

    def forward(self, question: str):
        passages  = self.retrieve(question).passages
        context   = "\n\n".join(passages)
        synthesis = self.synthesize(context=context, question=question)

        verification = self.verify(
            context=context,
            question=question,
            answer=synthesis.answer
        )

        final_answer = synthesis.answer
        if verification.supported.lower() == "no" and verification.correction:
            final_answer = verification.correction

        return dspy.Prediction(answer=final_answer, context=context)
```

---

## 7. Retrieval & RAG

### 7.1 ColBERTv2 Retriever

```python
import dspy
from dspy.retrieve.colbertv2 import ColBERTv2

# Point to a hosted ColBERT index
colbert = ColBERTv2(url="http://20.102.90.50:2017/wiki17_abstracts")
dspy.configure(rm=colbert)

retrieve = dspy.Retrieve(k=3)
results = retrieve("What is photosynthesis?")
for p in results.passages:
    print(p[:120])
```

### 7.2 Custom Retriever

Implement any retrieval backend by subclassing `dspy.Retrieve`.

```python
import dspy
from typing import List

class MyVectorRetriever(dspy.Retrieve):
    """Example custom retriever backed by a list of documents."""

    def __init__(self, corpus: List[str], k: int = 3):
        super().__init__(k=k)
        self.corpus = corpus

    def forward(self, query: str, k: int = None) -> dspy.Prediction:
        k = k or self.k
        # Naive keyword match — replace with real vector search
        scored = [
            (doc, sum(w in doc.lower() for w in query.lower().split()))
            for doc in self.corpus
        ]
        scored.sort(key=lambda x: x[1], reverse=True)
        passages = [doc for doc, _ in scored[:k]]
        return dspy.Prediction(passages=passages)

corpus = [
    "Paris is the capital of France.",
    "The Eiffel Tower is in Paris.",
    "London is the capital of the United Kingdom.",
    "Berlin is the capital of Germany.",
]

retriever = MyVectorRetriever(corpus=corpus, k=2)
dspy.configure(rm=retriever)

rag = RAGPipeline()  # from section 6.3
# result = rag(question="What is the capital of France?")
```

### 7.3 Full DSPy RAG Program with Evaluation

```python
import dspy
from dspy.evaluate import Evaluate

# ----- Data -----
qa_pairs = [
    dspy.Example(
        question="What is photosynthesis?",
        answer="The process by which plants convert sunlight into food."
    ).with_inputs("question"),
    dspy.Example(
        question="What is the powerhouse of the cell?",
        answer="The mitochondria."
    ).with_inputs("question"),
]

trainset = qa_pairs[:1]
devset   = qa_pairs[1:]

# ----- Metric -----
def answer_match(example, pred, trace=None):
    gold  = example.answer.lower().strip()
    given = pred.answer.lower().strip()
    return gold in given or given in gold

# ----- Evaluate -----
evaluate = Evaluate(devset=devset, metric=answer_match, num_threads=1)

class SimpleRAG(dspy.Module):
    def __init__(self):
        self.generate = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        return self.generate(question=question)

rag = SimpleRAG()
score = evaluate(rag, devset=devset)
print(f"Baseline score: {score:.1%}")
```

---

## 8. Optimizers (Teleprompters)

Optimizers search for the best prompt configuration automatically. They all share the same API: `optimizer.compile(program, trainset=..., valset=...)`.

### 8.1 BootstrapFewShot

The simplest optimizer. Generates few-shot demonstrations from the training set by running the program and keeping examples where the metric passes.

```python
import dspy
from dspy.teleprompt import BootstrapFewShot

class QAProgram(dspy.Module):
    def __init__(self):
        self.predict = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        return self.predict(question=question)

# Training data
trainset = [
    dspy.Example(question="What is DNA?",
                 answer="Deoxyribonucleic acid, the molecule carrying genetic information").with_inputs("question"),
    dspy.Example(question="What is the speed of light?",
                 answer="Approximately 299,792,458 meters per second").with_inputs("question"),
    dspy.Example(question="Who invented the telephone?",
                 answer="Alexander Graham Bell").with_inputs("question"),
]

def exact_match(example, pred, trace=None):
    return example.answer.lower() in pred.answer.lower()

optimizer = BootstrapFewShot(
    metric=exact_match,
    max_bootstrapped_demos=3,
    max_labeled_demos=2,
)

compiled_qa = optimizer.compile(QAProgram(), trainset=trainset)
result = compiled_qa(question="What is the formula for water?")
print(result.answer)
```

### 8.2 BootstrapFewShotWithRandomSearch

Runs multiple random configurations and picks the one with the best dev-set score.

```python
from dspy.teleprompt import BootstrapFewShotWithRandomSearch

optimizer = BootstrapFewShotWithRandomSearch(
    metric=exact_match,
    max_bootstrapped_demos=4,
    max_labeled_demos=4,
    num_candidate_programs=8,  # try 8 configurations
    num_threads=4,
)

compiled_qa = optimizer.compile(
    QAProgram(),
    trainset=trainset,
    valset=trainset[-1:],  # use a validation subset
)
```

### 8.3 MIPRO — Most Powerful Optimizer

MIPRO (Multi-prompt Instruction PRoposal Optimizer) uses a meta-LLM to *propose and refine prompt instructions* in addition to selecting demonstrations.

```python
from dspy.teleprompt import MIPROv2

optimizer = MIPROv2(
    metric=exact_match,
    auto="medium",          # "light", "medium", or "heavy" budget
    num_threads=4,
)

compiled_qa = optimizer.compile(
    QAProgram(),
    trainset=trainset,
    num_batches=10,         # optimization iterations
    max_bootstrapped_demos=3,
    max_labeled_demos=4,
    requires_permission_to_run=False,
)
```

### 8.4 LabeledFewShot

Uses your manually curated examples directly — no bootstrapping.

```python
from dspy.teleprompt import LabeledFewShot

optimizer = LabeledFewShot(k=3)   # use 3 labeled examples
compiled_qa = optimizer.compile(QAProgram(), trainset=trainset)
```

### 8.5 How Optimization Works (Conceptual)

```
trainset  ──►  Run program forward()  ──►  Check metric()
                                              │
                                    Pass?  ──► Keep as demonstration
                                    Fail?  ──► Discard
                                              │
                             Select best N demonstrations
                                              │
                             Inject into each module's prompt
                                              │
                             (MIPRO also proposes new instructions)
                                              │
                             Evaluate on valset  ──►  Store best config
```

---

## 9. Evaluation & Metrics

### 9.1 Built-in Metrics

```python
from dspy.evaluate.metrics import answer_exact_match, answer_passage_match

# answer_exact_match: checks if pred.answer == example.answer (normalized)
# answer_passage_match: checks if any passage contains the answer
```

### 9.2 Custom Metric Function

```python
import dspy

def f1_metric(example, pred, trace=None) -> float:
    """Token-level F1 score between gold and predicted answer."""
    gold_tokens  = set(example.answer.lower().split())
    pred_tokens  = set(pred.answer.lower().split())

    if not gold_tokens or not pred_tokens:
        return 0.0

    common    = gold_tokens & pred_tokens
    precision = len(common) / len(pred_tokens)
    recall    = len(common) / len(gold_tokens)

    if precision + recall == 0:
        return 0.0
    return 2 * precision * recall / (precision + recall)


def strict_and_relevant(example, pred, trace=None) -> bool:
    """Answer must be correct AND not too long."""
    correct    = example.answer.lower() in pred.answer.lower()
    not_too_long = len(pred.answer.split()) <= 50
    return correct and not_too_long
```

### 9.3 `dspy.Evaluate` Pipeline

```python
import dspy
from dspy.evaluate import Evaluate

devset = [
    dspy.Example(question="What is the boiling point of water?",
                 answer="100 degrees Celsius").with_inputs("question"),
    dspy.Example(question="Who invented the printing press?",
                 answer="Johannes Gutenberg").with_inputs("question"),
    dspy.Example(question="What is the largest planet?",
                 answer="Jupiter").with_inputs("question"),
]

def answer_contains(example, pred, trace=None):
    return example.answer.lower() in pred.answer.lower()

evaluator = Evaluate(
    devset=devset,
    metric=answer_contains,
    num_threads=2,         # parallel evaluation
    display_progress=True,
    display_table=5,       # print first 5 rows
)

qa_program = QAProgram()
score = evaluator(qa_program)
print(f"Score: {score:.1%}")

# Compare before vs after optimization
compiled = BootstrapFewShot(metric=answer_contains).compile(
    QAProgram(), trainset=devset[:2]
)
compiled_score = evaluator(compiled)
print(f"Optimized score: {compiled_score:.1%}")
```

---

## 10. Assertions & Constraints

DSPy lets you declare constraints on outputs. Violations trigger automatic retries.

### 10.1 `dspy.Assert` — Hard Constraint

If violated, the module retries with the constraint added to the context. Raises `AssertionError` after `max_backtracks` attempts.

```python
import dspy

class ConstrainedSentiment(dspy.Module):
    def __init__(self):
        self.classify = dspy.Predict("review -> sentiment")

    def forward(self, review: str):
        result = self.classify(review=review)

        # Hard constraint: must be one of three valid labels
        dspy.Assert(
            result.sentiment.lower() in {"positive", "negative", "neutral"},
            f"Sentiment must be positive/negative/neutral, got: {result.sentiment}"
        )
        return result

module = ConstrainedSentiment()
out = module(review="This was an average experience, nothing special.")
print(out.sentiment)  # "neutral"
```

### 10.2 `dspy.Suggest` — Soft Constraint

A soft nudge: violation is logged and added to context but does NOT raise an error.

```python
import dspy

class BriefSummary(dspy.Module):
    def __init__(self):
        self.summarize = dspy.ChainOfThought("document -> summary")

    def forward(self, document: str):
        result = self.summarize(document=document)

        # Soft constraint: prefer short summaries
        dspy.Suggest(
            len(result.summary.split()) <= 30,
            "Keep the summary under 30 words."
        )
        return result
```

### 10.3 Full Constrained Validation Example

```python
import dspy
import re

class StructuredEmailReply(dspy.Module):
    """Generate a customer service reply that meets format requirements."""

    def __init__(self):
        self.reply = dspy.ChainOfThought(
            "customer_email, tone -> reply"
        )

    def forward(self, customer_email: str, tone: str = "professional"):
        result = self.reply(customer_email=customer_email, tone=tone)
        reply  = result.reply

        # Hard: must start with a greeting
        dspy.Assert(
            reply.lower().startswith(("dear", "hello", "hi", "greetings")),
            "Email reply must start with a greeting (Dear/Hello/Hi/Greetings)."
        )

        # Hard: must contain an apology or acknowledgement for complaints
        if "problem" in customer_email.lower() or "issue" in customer_email.lower():
            dspy.Assert(
                any(w in reply.lower() for w in ["sorry", "apologize", "understand", "acknowledge"]),
                "Reply to a complaint must include an acknowledgement or apology."
            )

        # Soft: encourage a call-to-action
        dspy.Suggest(
            any(w in reply.lower() for w in ["contact", "reach out", "let us know", "please"]),
            "Include a call-to-action encouraging the customer to follow up."
        )

        return result

email_module = StructuredEmailReply()
out = email_module(
    customer_email="I have a problem with my order, it arrived damaged.",
    tone="empathetic"
)
print(out.reply)
```

---

## 11. Saving & Loading

After optimization, save the compiled program so you don't re-run expensive optimization later.

### 11.1 Save

```python
import dspy
from dspy.teleprompt import BootstrapFewShot

# Assume compiled_qa is an optimized program from section 8
compiled_qa.save("optimized_qa.json")
print("Program saved to optimized_qa.json")
```

### 11.2 Load

```python
import dspy

# Recreate the program skeleton (same architecture as when saved)
loaded_qa = QAProgram()
loaded_qa.load("optimized_qa.json")

result = loaded_qa(question="What is the capital of Japan?")
print(result.answer)  # "Tokyo"
```

### 11.3 What Gets Saved

The JSON file stores all optimized prompt configurations including:

- Instructions added to each module
- Few-shot demonstrations selected by the optimizer
- Any metadata about the optimization run

```json
{
  "predict": {
    "signature": "...",
    "demos": [
      {"question": "...", "reasoning": "...", "answer": "..."},
      {"question": "...", "reasoning": "...", "answer": "..."}
    ],
    "instructions": "..."
  }
}
```

### 11.4 Save / Load Pattern for Production

```python
import dspy
import os

MODEL_PATH = "models/qa_v1.json"

def get_qa_program():
    program = QAProgram()
    if os.path.exists(MODEL_PATH):
        program.load(MODEL_PATH)
        print("Loaded pre-optimized program.")
    else:
        print("No saved program found — running optimization...")
        optimizer = BootstrapFewShot(metric=exact_match)
        program = optimizer.compile(program, trainset=trainset)
        os.makedirs("models", exist_ok=True)
        program.save(MODEL_PATH)
        print(f"Optimized program saved to {MODEL_PATH}")
    return program

qa = get_qa_program()
```

---

## 12. Real-World Use Cases

### 12.1 Automated Email Classification and Response

```python
import dspy
from typing import Literal

class EmailClassification(dspy.Signature):
    """Classify and prioritize incoming support emails."""
    subject: str  = dspy.InputField()
    body:    str  = dspy.InputField()
    category: Literal["billing", "technical", "account", "general"] = dspy.OutputField()
    priority: Literal["urgent", "normal", "low"]                    = dspy.OutputField()
    summary:  str = dspy.OutputField(desc="One sentence summary")

class EmailResponse(dspy.Signature):
    """Draft a professional support response."""
    category: str = dspy.InputField()
    summary:  str = dspy.InputField()
    response: str = dspy.OutputField(desc="Complete email response text")

class EmailPipeline(dspy.Module):
    def __init__(self):
        self.classify = dspy.Predict(EmailClassification)
        self.respond  = dspy.ChainOfThought(EmailResponse)

    def forward(self, subject: str, body: str):
        classification = self.classify(subject=subject, body=body)
        response = self.respond(
            category=classification.category,
            summary=classification.summary,
        )
        return dspy.Prediction(
            category=classification.category,
            priority=classification.priority,
            response=response.response
        )

pipeline = EmailPipeline()
result = pipeline(
    subject="Cannot login to my account",
    body="I've been trying to login for 2 hours and keep getting 'invalid credentials'."
)
print(f"Category: {result.category}")
print(f"Priority: {result.priority}")
print(f"Response:\n{result.response}")
```

### 12.2 Code Generation with Correctness Verification

```python
import dspy
import subprocess
import sys

class CodeGenerationSignature(dspy.Signature):
    """Generate Python code to solve the described problem."""
    problem:     str = dspy.InputField(desc="Description of what the code should do")
    test_input:  str = dspy.InputField(desc="Sample input to test the code")
    expected:    str = dspy.InputField(desc="Expected output for the test input")
    code:        str = dspy.OutputField(desc="Complete, runnable Python code")
    explanation: str = dspy.OutputField(desc="Brief explanation of the approach")

class VerifiedCodeGen(dspy.Module):
    def __init__(self):
        self.generate = dspy.ChainOfThought(CodeGenerationSignature)

    def _run_code(self, code: str, test_input: str) -> tuple[bool, str]:
        """Execute generated code and return (success, output)."""
        full_code = f"{code}\nprint(solution({test_input}))"
        try:
            result = subprocess.run(
                [sys.executable, "-c", full_code],
                capture_output=True, text=True, timeout=5
            )
            return result.returncode == 0, result.stdout.strip()
        except subprocess.TimeoutExpired:
            return False, "Timeout"

    def forward(self, problem: str, test_input: str, expected: str):
        result = self.generate(
            problem=problem, test_input=test_input, expected=expected
        )
        success, output = self._run_code(result.code, test_input)
        correct = success and output == expected.strip()

        dspy.Assert(correct, f"Code produced {output!r} but expected {expected!r}")
        return result

gen = VerifiedCodeGen()
out = gen(
    problem="Write a function called `solution` that returns the sum of a list of numbers",
    test_input="[1, 2, 3, 4, 5]",
    expected="15"
)
print(out.code)
```

### 12.3 Full Classifier Example with Optimization

```python
import dspy
from dspy.teleprompt import BootstrapFewShot
from dspy.evaluate import Evaluate

# --- Data ---
train_data = [
    dspy.Example(text="My order never arrived!", label="complaint").with_inputs("text"),
    dspy.Example(text="Great service, very happy!", label="praise").with_inputs("text"),
    dspy.Example(text="How do I reset my password?", label="inquiry").with_inputs("text"),
    dspy.Example(text="I was charged twice for one item", label="complaint").with_inputs("text"),
    dspy.Example(text="Your team was incredibly helpful", label="praise").with_inputs("text"),
    dspy.Example(text="What are your business hours?", label="inquiry").with_inputs("text"),
]

dev_data = [
    dspy.Example(text="The product broke after one day", label="complaint").with_inputs("text"),
    dspy.Example(text="Five stars, would recommend!", label="praise").with_inputs("text"),
    dspy.Example(text="Do you ship internationally?", label="inquiry").with_inputs("text"),
]

# --- Program ---
class TextClassifier(dspy.Module):
    def __init__(self):
        self.classify = dspy.ChainOfThought(
            "text -> label"
        )

    def forward(self, text: str):
        result = self.classify(text=text)
        dspy.Assert(
            result.label.lower() in {"complaint", "praise", "inquiry"},
            "Label must be: complaint, praise, or inquiry"
        )
        return result

# --- Metric ---
def label_match(example, pred, trace=None):
    return example.label.lower() == pred.label.lower()

# --- Optimize ---
optimizer = BootstrapFewShot(metric=label_match, max_bootstrapped_demos=3)
compiled_classifier = optimizer.compile(TextClassifier(), trainset=train_data)

# --- Evaluate ---
evaluator = Evaluate(devset=dev_data, metric=label_match, num_threads=1)
score = evaluator(compiled_classifier)
print(f"Classification accuracy: {score:.1%}")

# --- Inference ---
result = compiled_classifier(text="This is the worst experience I've ever had.")
print(f"Label: {result.label}")
```

---

## 13. DSPy vs Traditional Prompting

### Side-by-Side Comparison

**Traditional Prompting**

```python
# You write and maintain this manually
PROMPT_TEMPLATE = """You are a helpful customer support agent.
Classify the following customer message into exactly one of these categories:
- complaint: customer has a problem or is unhappy
- praise: customer is happy and complimenting
- inquiry: customer is asking a question

Rules:
- Only output one word: complaint, praise, or inquiry
- Do not add punctuation
- Think carefully about the intent

Customer message: {text}

Category:"""

def classify_traditional(text: str) -> str:
    response = openai.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": PROMPT_TEMPLATE.format(text=text)}]
    )
    label = response.choices[0].message.content.strip().lower()
    if label not in {"complaint", "praise", "inquiry"}:
        return "inquiry"  # fallback
    return label
```

**DSPy Approach**

```python
# DSPy writes and optimizes the prompt for you
classifier = BootstrapFewShot(metric=label_match).compile(
    TextClassifier(), trainset=train_data
)
result = classifier(text=text)
```

### When Hand-Written Prompts Win

| Scenario | Reason |
|---|---|
| Single, stable, well-understood task | Prompt iteration is fast and cheap |
| No labeled evaluation data available | DSPy needs examples to optimize |
| Rapid prototype / demo | Setup overhead not worth it |
| Cost-sensitive with tiny dataset | Optimization calls add up |
| Creative tasks (poetry, stories) | No clear metric to optimize for |

### When DSPy Optimization Wins

| Scenario | Reason |
|---|---|
| Large production pipeline with SLA | Systematic quality improvement |
| Multi-step reasoning tasks | Coordinates prompts across modules |
| Structured / typed outputs needed | Enforces contracts automatically |
| Dataset of labeled examples exists | Optimizer has signal to work with |
| Switching LLM providers or models | Re-compile adapts to new model |

### Cost and Time Tradeoffs

```
Traditional Prompting
  Initial setup:    2–8 hrs  (writing/testing prompt)
  Per improvement:  1–3 hrs  (manual iteration)
  API cost:         $0       (for prompt development)

DSPy Optimization
  Initial setup:    1–2 hrs  (defining signatures & metrics)
  Per optimization: automatic (but uses API calls)
  API cost (train): $1–$20   (BootstrapFewShot on small dataset)
  API cost (MIPRO): $10–$100 (on larger datasets)
  Ongoing benefit:  compounding — re-compile when model changes
```

---

## 14. Interview Q&A

**Q1: What is a DSPy Signature and how does it differ from a prompt template?**

A **Signature** declares the input/output *contract* of an LLM call — it says *what* to do. A prompt template is hand-written text describing *how* to do it. DSPy's optimizer fills in the "how" automatically based on the signature and your metric. Signatures are composable, typed, and model-agnostic; prompt templates are brittle string literals.

---

**Q2: What is a DSPy Module and how is it similar to a neural network module?**

A `dspy.Module` is the composable unit of a DSPy program — it has a `forward()` method and can contain child modules (just like `nn.Module` in PyTorch). Parameters (demonstrations, instructions) are stored inside modules and can be updated by an optimizer, analogous to how gradient descent updates neural network weights.

---

**Q3: What is BootstrapFewShot and how does it work?**

`BootstrapFewShot` is DSPy's simplest optimizer. It:
1. Runs the compiled program on training examples
2. Checks each output against the metric
3. Keeps examples that *pass* as demonstrations
4. Injects those demonstrations into each module's prompt

It's called "bootstrap" because the program generates its own training signal.

---

**Q4: What is the difference between `dspy.Predict` and `dspy.ChainOfThought`?**

`dspy.Predict` makes a direct LLM call with the signature's input/output fields. `dspy.ChainOfThought` automatically adds a `reasoning` output field before the answer field, prompting the model to think step by step. CoT significantly improves accuracy on complex tasks at the cost of more tokens.

---

**Q5: How does MIPRO optimizer work?**

MIPRO (Multi-prompt Instruction PRoposal Optimizer) goes beyond few-shot selection. It uses a meta-LLM to:
1. **Analyze** the task and current program behavior
2. **Propose** new instruction candidates for each module
3. **Search** over combinations of instructions × demonstrations
4. **Select** the configuration with the best validation score using Bayesian optimization

It is the most powerful but also most expensive DSPy optimizer.

---

**Q6: How do you evaluate a DSPy program?**

Use `dspy.Evaluate`:
```python
from dspy.evaluate import Evaluate
evaluator = Evaluate(devset=devset, metric=my_metric, num_threads=4)
score = evaluator(my_program)
```
The metric is a function `(example, prediction, trace=None) -> float | bool`. Built-in metrics include `answer_exact_match` and `answer_passage_match`.

---

**Q7: What is `dspy.Assert` and when should you use it?**

`dspy.Assert` is a hard constraint on a module's output. If violated, the framework retries the LLM call with the violated constraint added to context. Use it when outputs must satisfy a strict rule (valid enum value, minimum length, JSON parseable, etc.). Use `dspy.Suggest` for softer preferences that shouldn't cause retries.

---

**Q8: How do you implement RAG in DSPy?**

```python
class RAG(dspy.Module):
    def __init__(self):
        self.retrieve  = dspy.Retrieve(k=3)       # configured via dspy.configure(rm=...)
        self.generate  = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = "\n".join(self.retrieve(question).passages)
        return self.generate(context=context, question=question)
```
Configure the retriever with `dspy.configure(rm=ColBERTv2(...))`.

---

**Q9: How do you save and reload an optimized DSPy program?**

```python
# Save
compiled_program.save("program_v1.json")

# Load (must recreate the same class structure first)
program = MyProgram()
program.load("program_v1.json")
```
The JSON stores instructions and demonstrations but NOT model weights.

---

**Q10: When would you choose DSPy over LangChain?**

Choose DSPy when you have **measurable quality requirements** (a metric function) and **labeled examples**. DSPy systematically improves prompt quality through optimization. Choose LangChain for rapid prototyping, tool-chain assembly, or when you need its broad ecosystem of integrations without a formal quality loop.

---

**Q11: How do you write a custom metric for DSPy evaluation?**

```python
def my_metric(example, pred, trace=None) -> float:
    # example: a dspy.Example with gold labels
    # pred:    the program's dspy.Prediction
    # trace:   optional trace for advanced metrics
    score = some_score_function(example.answer, pred.answer)
    return score   # float in [0,1] or bool
```
The metric doubles as the optimizer's objective, so it must be fast and deterministic.

---

**Q12: What is ProgramOfThought?**

`dspy.ProgramOfThought` is a module that instructs the LLM to write Python code to solve a problem, then *executes that code* and returns the runtime result as the answer. It's powerful for math, data processing, and algorithmic tasks where code execution is more reliable than token generation.

---

**Q13: How do you use DSPy with local models?**

```python
lm = dspy.LM(
    "ollama/llama3",
    api_base="http://localhost:11434",
    api_key="ollama",
)
dspy.configure(lm=lm)
```
DSPy uses LiteLLM under the hood, so any LiteLLM-compatible model string works (HuggingFace, vLLM, LM Studio, etc.).

---

**Q14: What is the train/dev split in DSPy optimization?**

- **trainset**: Examples used by the optimizer to *generate* demonstrations. The optimizer runs the program on these and keeps successful traces.
- **devset (valset)**: Examples used to *evaluate* candidate configurations. The optimizer scores each configuration on devset and picks the best one.

Rule of thumb: 70% train, 30% dev. Even 20–50 examples can produce meaningful optimization.

---

**Q15: How does DSPy handle multi-hop reasoning?**

By chaining modules in `forward()`, each building on prior results:
```python
class MultiHopQA(dspy.Module):
    def __init__(self, hops=3):
        self.retrieve  = dspy.Retrieve(k=2)
        self.generate  = [dspy.ChainOfThought("context, question -> next_query, answer")
                          for _ in range(hops)]

    def forward(self, question):
        context, query = "", question
        for module in self.generate:
            passages = self.retrieve(query).passages
            context += "\n".join(passages)
            pred   = module(context=context, question=query)
            query  = pred.next_query
        return pred
```
Each hop refines the query based on previous retrieved evidence.

---

## 15. Complete End-to-End Example

A fully working, optimized RAG pipeline: load data → define program → optimize with BootstrapFewShot → evaluate → save.

```python
"""
DSPy End-to-End RAG Pipeline
============================================================
Steps:
  1. Configure LM (GitHub Copilot free endpoint or OpenAI)
  2. Build a small QA dataset
  3. Define a RAG program (retrieve → chain-of-thought → verify)
  4. Evaluate the baseline (no optimization)
  5. Optimize with BootstrapFewShot
  6. Evaluate the optimized program
  7. Save the optimized program
  8. Reload and run inference

Run: python e2e_rag_pipeline.py
"""

import subprocess
import os
import dspy
from dspy.teleprompt import BootstrapFewShot
from dspy.evaluate import Evaluate

# ── 1. Configure the LM ──────────────────────────────────────
def configure_lm():
    """Use GitHub Copilot free auth if available, else fall back to env var."""
    try:
        token = subprocess.run(
            ["gh", "auth", "token"], capture_output=True, text=True
        ).stdout.strip()
        if token:
            lm = dspy.LM(
                "openai/gpt-4o-mini",
                api_key=token,
                api_base="https://models.inference.ai.azure.com",
            )
            print("Using GitHub Copilot endpoint.")
            return lm
    except FileNotFoundError:
        pass

    api_key = os.getenv("OPENAI_API_KEY", "")
    if not api_key:
        raise ValueError("Set OPENAI_API_KEY or run `gh auth login`.")
    print("Using OpenAI endpoint.")
    return dspy.LM("openai/gpt-4o-mini", api_key=api_key)

lm = configure_lm()
dspy.configure(lm=lm)

# ── 2. Dataset ────────────────────────────────────────────────
ALL_DATA = [
    dspy.Example(
        question="What gas do plants absorb during photosynthesis?",
        answer="Carbon dioxide"
    ).with_inputs("question"),
    dspy.Example(
        question="What is the powerhouse of the cell?",
        answer="The mitochondria"
    ).with_inputs("question"),
    dspy.Example(
        question="What planet is closest to the Sun?",
        answer="Mercury"
    ).with_inputs("question"),
    dspy.Example(
        question="What is the chemical symbol for gold?",
        answer="Au"
    ).with_inputs("question"),
    dspy.Example(
        question="How many bones are in the adult human body?",
        answer="206"
    ).with_inputs("question"),
    dspy.Example(
        question="What is the speed of light in a vacuum?",
        answer="Approximately 299,792,458 meters per second"
    ).with_inputs("question"),
]

trainset = ALL_DATA[:4]
devset   = ALL_DATA[4:]

# ── 3. Define the RAG Program ─────────────────────────────────
class RAGAnswerSignature(dspy.Signature):
    """Answer the question accurately and concisely."""
    question: str = dspy.InputField()
    answer:   str = dspy.OutputField(desc="Short factual answer, 1–2 sentences max")

class SimpleQARAG(dspy.Module):
    """
    Lightweight RAG: no external retriever needed for this demo.
    In production, swap self.generate for a retrieve → generate chain.
    """
    def __init__(self):
        self.generate = dspy.ChainOfThought(RAGAnswerSignature)

    def forward(self, question: str):
        result = self.generate(question=question)
        dspy.Suggest(
            len(result.answer.split()) <= 30,
            "Keep the answer concise — under 30 words."
        )
        return result

# ── 4. Baseline Evaluation ────────────────────────────────────
def answer_contains(example, pred, trace=None) -> bool:
    gold  = example.answer.lower().strip()
    given = pred.answer.lower().strip()
    return gold in given or any(w in given for w in gold.split() if len(w) > 3)

print("\n── Baseline Evaluation ──")
baseline = SimpleQARAG()
evaluator = Evaluate(devset=devset, metric=answer_contains, num_threads=1, display_progress=True)
baseline_score = evaluator(baseline)
print(f"Baseline accuracy: {baseline_score:.1%}")

# ── 5. Optimization ───────────────────────────────────────────
print("\n── Optimizing with BootstrapFewShot ──")
optimizer = BootstrapFewShot(
    metric=answer_contains,
    max_bootstrapped_demos=3,
    max_labeled_demos=2,
)
compiled_rag = optimizer.compile(SimpleQARAG(), trainset=trainset)

# ── 6. Optimized Evaluation ───────────────────────────────────
print("\n── Optimized Evaluation ──")
optimized_score = evaluator(compiled_rag)
print(f"Optimized accuracy: {optimized_score:.1%}")
print(f"Improvement:        +{optimized_score - baseline_score:.1%}")

# ── 7. Save ───────────────────────────────────────────────────
SAVE_PATH = "optimized_rag.json"
compiled_rag.save(SAVE_PATH)
print(f"\nProgram saved to {SAVE_PATH}")

# ── 8. Reload and Inference ───────────────────────────────────
print("\n── Loading saved program ──")
loaded_rag = SimpleQARAG()
loaded_rag.load(SAVE_PATH)

test_questions = [
    "What is the largest planet in our solar system?",
    "What element has the atomic number 1?",
    "Who wrote Romeo and Juliet?",
]

print("\n── Inference with loaded program ──")
for q in test_questions:
    result = loaded_rag(question=q)
    print(f"Q: {q}")
    print(f"A: {result.answer}")
    print(f"   (reasoning: {result.reasoning[:80]}...)\n")
```

---

## Quick Reference Card

```
dspy.configure(lm=..., rm=...)          # Global LM + retriever config

# Signatures
dspy.Predict("q -> a")                  # Inline
class Sig(dspy.Signature): ...          # Class-based

# Modules
dspy.Predict(sig)                       # Direct call
dspy.ChainOfThought(sig)                # + reasoning field
dspy.ReAct(sig, tools=[...])            # Tool-calling agent
dspy.Retrieve(k=3)                      # Vector retrieval
dspy.ProgramOfThought(sig)              # Code generation + execution

# Optimizers
BootstrapFewShot(metric=f)              # Simple demo selection
BootstrapFewShotWithRandomSearch(...)   # + random search
MIPROv2(metric=f, auto="medium")        # Instruction + demo opt
LabeledFewShot(k=N)                     # Manual examples

# Constraints
dspy.Assert(condition, message)         # Hard — retries on fail
dspy.Suggest(condition, message)        # Soft — logs and continues

# Evaluate
Evaluate(devset=..., metric=f)(program) # Returns score in [0,1]

# Persist
program.save("path.json")
program.load("path.json")
```

---

*Guide covers DSPy 2.x · Last updated 2025*
