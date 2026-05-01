# DSPy Practicals: Hands-On Project Guide

Eight real-world projects to build expertise with DSPy. Each project includes:
Overview, Setup Steps, Key Code Patterns, Sample Data, and Expected Outcome.

---

## Project 1: Optimized Question Answering System

### Overview
Build a factual QA system and use BootstrapFewShot to automatically discover the best
few-shot demonstrations. Compare performance before and after optimization using a
hold-out test set. This project teaches the core DSPy workflow.

### Setup Steps
1. `pip install dspy-ai openai`
2. Set `OPENAI_API_KEY` environment variable
3. Prepare 50 QA pairs (use TriviaQA or SQuAD sample)
4. Split: 40 train / 10 test
5. Define exact-match metric
6. Compile and evaluate

### Key Code Patterns
```python
import dspy
from dspy.teleprompt import BootstrapFewShot
from dspy.evaluate import Evaluate

dspy.configure(lm=dspy.LM("openai/gpt-4o-mini"))

class QAProgram(dspy.Module):
    def __init__(self):
        self.predict = dspy.ChainOfThought("question -> answer")
    def forward(self, question):
        return self.predict(question=question)

def em_metric(gold, pred, trace=None):
    return gold.answer.strip().lower() == pred.answer.strip().lower()

# Baseline evaluation BEFORE optimization
baseline = QAProgram()
evaluator = Evaluate(devset=testset, metric=em_metric, num_threads=4)
baseline_score = evaluator(baseline)
print(f"Baseline: {baseline_score:.1%}")

# Optimize
optimizer = BootstrapFewShot(metric=em_metric, max_bootstrapped_demos=4)
compiled = optimizer.compile(QAProgram(), trainset=trainset)

# Post-optimization evaluation
compiled_score = evaluator(compiled)
print(f"Compiled: {compiled_score:.1%}")
print(f"Improvement: +{(compiled_score - baseline_score):.1%}")
```

### Sample Data
```python
trainset = [
    dspy.Example(question="What is the largest ocean?",
                 answer="Pacific Ocean").with_inputs("question"),
    dspy.Example(question="How many sides does a hexagon have?",
                 answer="Six").with_inputs("question"),
    dspy.Example(question="What gas do plants absorb?",
                 answer="Carbon dioxide").with_inputs("question"),
]
```

### Expected Outcome
- Baseline accuracy: ~65-75% on factual QA
- After BootstrapFewShot: +5-15% improvement
- Compiled program file saved to `qa_compiled.json`
- Visible few-shot examples in the compiled program

---

## Project 2: Multi-Hop Reasoning Program

### Overview
Implement a multi-hop QA system that chains 2-3 retrieval steps to answer complex
questions that require combining multiple facts. Use a mock retrieval function initially,
then replace with a real vector database. Optimize with BootstrapFewShot.

### Setup Steps
1. Install: `pip install dspy-ai chromadb sentence-transformers`
2. Build a small knowledge base (50-100 passages from Wikipedia)
3. Index passages in ChromaDB
4. Define multi-hop QA questions where answers require 2+ facts
5. Compile and evaluate on multi-hop test set

### Key Code Patterns
```python
class PlanNextHop(dspy.Signature):
    """Decide what to look up next to answer the question."""
    question: str = dspy.InputField()
    gathered_facts: str = dspy.InputField(desc="facts gathered in previous hops")
    search_query: str = dspy.OutputField(desc="specific factual query for next search")

class MultiHopProgram(dspy.Module):
    def __init__(self, hops=2):
        self.plan = [dspy.ChainOfThought(PlanNextHop) for _ in range(hops)]
        self.retrieve = dspy.Retrieve(k=3)
        self.answer = dspy.ChainOfThought("question, all_facts -> answer")

    def forward(self, question):
        all_facts = []
        for planner in self.plan:
            query = planner(
                question=question,
                gathered_facts=" | ".join(all_facts)
            ).search_query
            passages = self.retrieve(query=query).passages
            all_facts.extend(passages)
        return self.answer(question=question, all_facts="\n".join(all_facts))
```

### Sample Data
```python
multihop_examples = [
    dspy.Example(
        question="What country does the river that flows through Paris empty into?",
        answer="Atlantic Ocean (via the English Channel)"
    ).with_inputs("question"),
    dspy.Example(
        question="Who created the programming language that powers most web servers?",
        answer="Rasmus Lerdorf (PHP)"
    ).with_inputs("question"),
]
```

### Expected Outcome
- Ability to answer 2-hop questions that single-hop retrieval fails on
- Retrieved passage chains visible in `dspy.settings.trace`
- Performance improvement when compiled vs. uncompiled

---

## Project 3: RAG with DSPy Optimization

### Overview
Build a production-quality RAG pipeline with citation support, optimize it end-to-end
with MIPRO, and measure faithfulness and answer accuracy. This project shows how
DSPy optimizes the retrieval query generation, not just the final answer.

### Setup Steps
1. Install: `pip install dspy-ai chromadb openai`
2. Ingest a document corpus (e.g., company FAQ, technical docs)
3. Build ChromaDB vector store with text-embedding-3-small
4. Configure DSPy with both LM and RM
5. Define faithfulness metric using an LLM judge
6. Optimize with MIPROv2

### Key Code Patterns
```python
from dspy.teleprompt import MIPROv2

class FaithfulRAG(dspy.Module):
    def __init__(self):
        self.retrieve = dspy.Retrieve(k=5)
        self.rerank = dspy.Predict("question, passages -> top3_passages: list[str]")
        self.answer = dspy.ChainOfThought(
            "context, question -> answer, supporting_quote: str"
        )

    def forward(self, question):
        raw = self.retrieve(query=question).passages
        reranked = self.rerank(question=question, passages=raw).top3_passages
        return self.answer(context="\n".join(reranked), question=question)

judge = dspy.ChainOfThought("context, answer -> is_faithful: bool, reason: str")

def faithfulness_metric(gold, pred, trace=None):
    result = judge(context=gold.context, answer=pred.answer)
    accuracy = float(gold.answer.lower() in pred.answer.lower())
    faithfulness = float(result.is_faithful)
    return 0.5 * accuracy + 0.5 * faithfulness

optimizer = MIPROv2(metric=faithfulness_metric, auto="medium")
compiled_rag = optimizer.compile(FaithfulRAG(), trainset=rag_trainset)
```

### Sample Data
```python
rag_trainset = [
    dspy.Example(
        question="What is the return policy?",
        answer="30 days with receipt",
        context="Our policy allows returns within 30 days of purchase with original receipt."
    ).with_inputs("question"),
]
```

### Expected Outcome
- RAG answers grounded in retrieved passages (faithfulness > 80%)
- Optimized retrieval queries that find more relevant passages
- Compiled program deployable as a REST API

---

## Project 4: Code Generation with Assertions

### Overview
Build a Python code generator that uses `dspy.Assert` to enforce that generated code
is syntactically valid, passes basic tests, and meets style requirements. Demonstrates
how assertions make code generation more reliable through auto-retry.

### Setup Steps
1. Prepare 30 coding problem descriptions with reference solutions
2. Define validators: syntax check, test execution, style lint
3. Implement assert-guarded code generator
4. Compare output quality with and without assertions

### Key Code Patterns
```python
import ast
import dspy

class CodeGenerator(dspy.Module):
    def __init__(self):
        self.generate = dspy.ChainOfThought(
            "problem_description -> python_code, explanation"
        )

    def forward(self, problem_description):
        result = self.generate(problem_description=problem_description)
        code = result.python_code

        # Hard assertion: code must be syntactically valid Python
        try:
            ast.parse(code)
            syntax_ok = True
        except SyntaxError:
            syntax_ok = False
        dspy.Assert(syntax_ok, "Generated code has syntax errors. Write valid Python.")

        # Soft suggestion: avoid overly long lines
        long_lines = [l for l in code.split("\n") if len(l) > 100]
        dspy.Suggest(
            len(long_lines) == 0,
            "Keep lines under 100 characters for readability."
        )

        return result
```

### Sample Data
```python
problems = [
    "Write a function that returns the nth Fibonacci number using dynamic programming.",
    "Implement binary search that returns the index of a target in a sorted list.",
    "Write a function that checks if a string is a valid palindrome ignoring spaces.",
]
```

### Expected Outcome
- 100% syntactically valid code (assertions enforce this via retry)
- Measurable style improvement from Suggest feedback
- Retry traces showing how assertions guide re-generation

---

## Project 5: Text Classification with DSPy

### Overview
Build a multi-class text classifier using DSPy signatures and TypedPredictor. Optimize
with BootstrapFewShot and compare against a zero-shot baseline. Demonstrates DSPy's
value for classification tasks with structured output requirements.

### Setup Steps
1. Choose a classification dataset (emotion detection, topic classification, etc.)
2. Prepare 100 labeled examples; split 80/20
3. Define classification signature with label constraints
4. Implement TypedPredictor for structured output
5. Evaluate with weighted F1 metric

### Key Code Patterns
```python
from typing import Literal
import dspy
from dspy.teleprompt import BootstrapFewShot

CATEGORIES = Literal["technology", "sports", "politics", "entertainment", "science"]

class ClassifyArticle(dspy.Signature):
    """Classify the news article into exactly one category."""
    article_headline: str = dspy.InputField()
    article_snippet: str = dspy.InputField(desc="first 100 words of article")
    category: CATEGORIES = dspy.OutputField()
    confidence: float = dspy.OutputField(desc="confidence from 0.0 to 1.0")

def classification_metric(gold, pred, trace=None):
    correct = gold.category == pred.category
    return float(correct) * min(getattr(pred, "confidence", 0.5), 1.0)

optimizer = BootstrapFewShot(metric=classification_metric, max_bootstrapped_demos=5)
compiled_classifier = optimizer.compile(
    dspy.TypedPredictor(ClassifyArticle),
    trainset=train_examples
)
```

### Sample Data
```python
examples = [
    dspy.Example(
        article_headline="SpaceX Launches 60 Starlink Satellites",
        article_snippet="SpaceX successfully launched another batch of...",
        category="technology"
    ).with_inputs("article_headline", "article_snippet"),
    dspy.Example(
        article_headline="Lakers Win Championship in Game 7 Thriller",
        article_snippet="The Los Angeles Lakers captured their 18th title...",
        category="sports"
    ).with_inputs("article_headline", "article_snippet"),
]
```

### Expected Outcome
- Classification accuracy > 85% on 5-class problem
- TypedPredictor eliminates label formatting errors
- F1 scores per category showing where the model is weakest

---

## Project 6: Custom Metric and Evaluation Pipeline

### Overview
Build a comprehensive evaluation pipeline using an LLM-as-judge metric covering three
quality dimensions: correctness, completeness, and conciseness. This is the foundation
for any serious DSPy project -- a good metric is essential for useful optimization.

### Setup Steps
1. Define 3 quality dimensions: correctness, completeness, conciseness
2. Implement an LLM judge for each dimension
3. Combine into a weighted composite metric
4. Run evaluation across 3 program variants
5. Produce a comparison table with per-dimension scores

### Key Code Patterns
```python
import dspy
from dspy.evaluate import Evaluate

correctness_judge = dspy.ChainOfThought(
    "question, gold_answer, predicted_answer -> score: float, reason: str"
)
completeness_judge = dspy.ChainOfThought(
    "question, gold_answer, predicted_answer -> completeness_score: float"
)
conciseness_judge = dspy.Predict(
    "answer -> conciseness_score: float"
)

def composite_metric(gold, pred, trace=None, weights=(0.6, 0.2, 0.2)):
    w_correct, w_complete, w_concise = weights
    correctness = correctness_judge(
        question=gold.question,
        gold_answer=gold.answer,
        predicted_answer=pred.answer
    ).score
    completeness = completeness_judge(
        question=gold.question,
        gold_answer=gold.answer,
        predicted_answer=pred.answer
    ).completeness_score
    conciseness = conciseness_judge(answer=pred.answer).conciseness_score
    return w_correct * correctness + w_complete * completeness + w_concise * conciseness

evaluator = Evaluate(devset=testset, metric=composite_metric, num_threads=4)
scores = {}
for name, program in [("baseline", baseline_qa), ("bootstrapped", compiled_qa)]:
    scores[name] = evaluator(program)
    print(f"{name}: {scores[name]:.3f}")
```

### Expected Outcome
- Multi-dimensional evaluation revealing trade-offs between programs
- Composite score that correlates with human judgment
- Reusable metric module for future DSPy projects

---

## Project 7: MIPRO Prompt Optimization Experiment

### Overview
Run a controlled experiment comparing zero-shot, BootstrapFewShot, and MIPROv2 on the
same task. Measure accuracy and LLM call costs for each approach. This experiment
shows when the extra optimization investment is worth it.

### Setup Steps
1. Choose a benchmark task (HotpotQA subset, GSM8K subset)
2. Prepare 100 examples (70 train, 30 test)
3. Run all three optimization strategies
4. Record accuracy, number of LLM calls, final prompt length
5. Produce a cost vs. accuracy trade-off table

### Key Code Patterns
```python
import time
import dspy
from dspy.teleprompt import BootstrapFewShot, MIPROv2
from dspy.evaluate import Evaluate

evaluator = Evaluate(devset=testset, metric=my_metric, num_threads=4)
results = {}

# Strategy 1: Zero-shot (no optimization)
baseline = MyProgram()
results["zero_shot"] = {"score": evaluator(baseline), "time_seconds": 0}

# Strategy 2: BootstrapFewShot
t0 = time.time()
bfs = BootstrapFewShot(metric=my_metric, max_bootstrapped_demos=4)
compiled_bfs = bfs.compile(MyProgram(), trainset=trainset)
results["bootstrap"] = {
    "score": evaluator(compiled_bfs),
    "time_seconds": time.time() - t0
}

# Strategy 3: MIPROv2
t0 = time.time()
mipro = MIPROv2(metric=my_metric, auto="medium")
compiled_mipro = mipro.compile(
    MyProgram(), trainset=trainset, requires_permission_to_run=False
)
results["mipro"] = {
    "score": evaluator(compiled_mipro),
    "time_seconds": time.time() - t0
}

print(f"{'Strategy':<20} {'Score':>10} {'Time (s)':>12}")
print("-" * 45)
for name, data in results.items():
    print(f"{name:<20} {data['score']:>10.3f} {data['time_seconds']:>12.0f}")
```

### Expected Outcome
- Zero-shot: baseline accuracy
- BootstrapFewShot: +5-10% in minutes
- MIPRO: +10-20% in 1-2 hours (depending on budget)
- Clear cost-benefit curve for choosing optimization strategy

---

## Project 8: DSPy vs Manual Prompting Benchmark

### Overview
A head-to-head comparison between a manually engineered prompt and a DSPy-compiled
program on the same task. Convincingly demonstrates DSPy's value proposition. Track
both accuracy and the engineering effort required for each approach.

### Setup Steps
1. Write your best manual prompt for the task (spend 30+ minutes on it)
2. Implement the equivalent DSPy program (no manual prompt engineering)
3. Compile DSPy program with BootstrapFewShot
4. Evaluate both on identical 50-example test set
5. Document findings: where does each approach succeed and fail?

### Key Code Patterns
```python
import dspy
from dspy.teleprompt import BootstrapFewShot

# --- Manual Prompting Baseline ---
MANUAL_PROMPT = """You are an expert at answering factual questions.
Think carefully, then provide a concise and accurate answer in 1-3 sentences.

Question: {question}
Answer:"""

def manual_predict(question):
    response = lm(MANUAL_PROMPT.format(question=question))
    return response[0] if isinstance(response, list) else response

# --- DSPy Program (no manual prompt engineering) ---
class DSPyQA(dspy.Module):
    def __init__(self):
        self.predict = dspy.ChainOfThought("question -> answer")
    def forward(self, question):
        return self.predict(question=question)

optimizer = BootstrapFewShot(metric=em_metric, max_bootstrapped_demos=4)
compiled_dspy = optimizer.compile(DSPyQA(), trainset=trainset)

# --- Compare ---
manual_scores, dspy_scores = [], []
for example in testset:
    manual_answer = manual_predict(example.question)
    manual_scores.append(em_metric(example, type("P", (), {"answer": manual_answer})()))
    dspy_result = compiled_dspy(question=example.question)
    dspy_scores.append(em_metric(example, dspy_result))

manual_acc = sum(manual_scores) / len(manual_scores)
dspy_acc = sum(dspy_scores) / len(dspy_scores)
print(f"Manual prompting accuracy:  {manual_acc:.1%}")
print(f"DSPy compiled accuracy:     {dspy_acc:.1%}")
print(f"DSPy advantage:             +{(dspy_acc - manual_acc):.1%}")
```

### Sample Data
Use a standard benchmark for fair comparison:
```python
# Use first 100 examples from TriviaQA validation set
# Key: use the SAME examples for both approaches
testset = load_trivia_qa_sample(n=50, split="validation")
trainset = load_trivia_qa_sample(n=50, split="train")
```

### Expected Outcome
- DSPy compiled program outperforms manual prompting by 5-20%
- DSPy advantage grows on harder questions requiring multi-step reasoning
- Manual prompt requires 30+ minutes of human work; DSPy requires 0 minutes of prompt work
- DSPy advantage is larger when switching to a different model (portability wins)

---

*For theoretical background, see THEORY.md. For annotated code examples, see EXAMPLES.md.*
