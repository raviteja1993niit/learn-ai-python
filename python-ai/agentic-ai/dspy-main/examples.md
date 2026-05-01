# DSPy Examples: Annotated Code Guide

This file contains 18+ annotated Python examples covering all major DSPy features.
Each example includes a comment block explaining what it demonstrates and why it matters.

---

## Example 1: Configure DSPy with OpenAI

```python
# ============================================================
# WHAT: Initialize DSPy with an OpenAI language model.
# WHY:  This is always the first step. dspy.configure sets the
#       global LM used by all modules unless overridden.
#       LiteLLM model strings make it easy to switch providers.
# ============================================================
import dspy

lm = dspy.LM(
    model="openai/gpt-4o-mini",
    api_key="sk-...",        # or set OPENAI_API_KEY env var
    max_tokens=1000,
    temperature=0.0          # deterministic for reproducibility
)
dspy.configure(lm=lm)

# Verify connection
response = lm("Hello, are you ready?")
print(response)
```

---

## Example 2: Simple Predict Module

```python
# ============================================================
# WHAT: Use dspy.Predict with an inline signature.
# WHY:  This is the most basic DSPy building block. Notice that
#       there is NO prompt string -- DSPy builds the prompt from
#       the signature automatically. The result is accessed as
#       an attribute matching the output field name.
# ============================================================
import dspy

qa = dspy.Predict("question -> answer")

result = qa(question="What is the chemical formula of water?")
print(result.answer)   # H2O

result2 = qa(question="Who wrote Hamlet?")
print(result2.answer)  # William Shakespeare
```

---

## Example 3: ChainOfThought for Reasoning

```python
# ============================================================
# WHAT: Use dspy.ChainOfThought to expose intermediate reasoning.
# WHY:  CoT improves accuracy on multi-step problems by forcing
#       the model to articulate its reasoning before answering.
#       DSPy adds the reasoning field automatically -- you don't
#       need to add "think step by step" to your prompts.
# ============================================================
import dspy

cot = dspy.ChainOfThought("context, question -> answer")

result = cot(
    context="A train leaves City A at 9am traveling 60mph. City B is 180 miles away.",
    question="At what time does the train arrive at City B?"
)

print("Reasoning:", result.reasoning)
print("Answer:", result.answer)
# Reasoning: 180 miles / 60 mph = 3 hours. 9am + 3 hours = 12pm.
# Answer: 12:00 PM (noon)
```

---

## Example 4: Class-Based Signature with Field Descriptions

```python
# ============================================================
# WHAT: Define a rich signature using a class with docstring
#       and per-field descriptions.
# WHY:  Class-based signatures give DSPy more information to
#       work with during optimization. The docstring becomes
#       the task instruction; desc fields guide output format.
#       Optimizers can improve these descriptions automatically.
# ============================================================
import dspy

class SummarizeArticle(dspy.Signature):
    """Produce a concise, informative summary of the given article."""

    article: str = dspy.InputField(
        desc="full text of the article to summarize"
    )
    audience: str = dspy.InputField(
        desc="target audience (e.g. 'expert', 'general public', 'children')"
    )
    summary: str = dspy.OutputField(
        desc="2-3 sentence summary appropriate for the specified audience"
    )
    key_points: list[str] = dspy.OutputField(
        desc="list of 3-5 most important points from the article"
    )

summarizer = dspy.ChainOfThought(SummarizeArticle)
result = summarizer(
    article="Quantum entanglement is a phenomenon where two particles...",
    audience="general public"
)
print(result.summary)
print(result.key_points)
```

---

## Example 5: ProgramOfThought for Math Problems

```python
# ============================================================
# WHAT: Use ProgramOfThought to solve quantitative problems
#       by generating and executing Python code.
# WHY:  LLMs make arithmetic errors. ProgramOfThought avoids
#       this by having the model write code, then running it.
#       The code execution produces the exact answer, not an
#       approximation from the model's parametric memory.
# ============================================================
import dspy

pot = dspy.ProgramOfThought("question -> answer")

result = pot(question=(
    "A company has 3 departments. Dept A has 12 employees at $85k/year. "
    "Dept B has 8 employees at $95k/year. Dept C has 5 employees at $120k/year. "
    "What is the total annual payroll?"
))
print(result.answer)
# Model generates: answer = 12*85000 + 8*95000 + 5*120000
# Python executes: 1020000 + 760000 + 600000 = 2380000
# Answer: 2380000
```

---

## Example 6: ReAct Agent with Tools

```python
# ============================================================
# WHAT: Build a ReAct agent that uses external tools to answer.
# WHY:  Some questions require real-time or specialized data
#       that the LLM doesn't have in its weights. ReAct lets
#       the model decide when and how to use tools, producing
#       factually grounded answers through tool observation.
# ============================================================
import dspy

def search_wikipedia(query: str) -> str:
    """Search Wikipedia and return the top paragraph about a topic."""
    # In practice, use wikipedia-api or requests
    return f"[Wikipedia result for '{query}']"

def calculate(expression: str) -> str:
    """Evaluate a mathematical expression and return the result."""
    try:
        return str(eval(expression, {"__builtins__": {}}, {}))
    except Exception as e:
        return f"Error: {e}"

agent = dspy.ReAct(
    "question -> answer",
    tools=[search_wikipedia, calculate]
)

result = agent(question="How many minutes are in one year?")
print(result.answer)
```

---

## Example 7: MultiChainComparison Module

```python
# ============================================================
# WHAT: Generate M independent reasoning chains and compare.
# WHY:  Ensemble methods reduce variance. By generating multiple
#       independent reasoning attempts and then judging them,
#       MultiChainComparison is more robust than a single CoT
#       pass. Useful when accuracy is critical and latency
#       budgets allow for the extra LLM calls.
# ============================================================
import dspy

mcc = dspy.MultiChainComparison(
    signature="question -> answer",
    M=3  # number of independent chains to generate
)

result = mcc(question="Is 2357 a prime number?")
print(result.answer)
# Generates 3 independent reasoning chains, then compares
# and selects the most consistent and correct answer
```

---

## Example 8: Custom Metric Function

```python
# ============================================================
# WHAT: Define a custom metric for DSPy optimization.
# WHY:  The metric tells DSPy what "correct" means for your
#       task. A good metric is the single most important factor
#       in getting useful optimization. Metrics can be simple
#       (exact match) or complex (LLM-as-judge for open-ended).
# ============================================================
import dspy

def answer_exactmatch(gold, pred, trace=None):
    """Return 1.0 if the predicted answer matches gold, else 0.0."""
    return float(gold.answer.strip().lower() == pred.answer.strip().lower())

def answer_f1(gold, pred, trace=None):
    """Token-level F1 between gold and predicted answers."""
    gold_tokens = set(gold.answer.lower().split())
    pred_tokens = set(pred.answer.lower().split())
    if not pred_tokens:
        return 0.0
    precision = len(gold_tokens & pred_tokens) / len(pred_tokens)
    recall = len(gold_tokens & pred_tokens) / len(gold_tokens) if gold_tokens else 0.0
    if precision + recall == 0:
        return 0.0
    return 2 * precision * recall / (precision + recall)

# LLM-as-judge metric for open-ended tasks
judge = dspy.Predict("question, gold_answer, predicted_answer -> is_correct: bool, explanation: str")

def llm_judge_metric(gold, pred, trace=None):
    result = judge(
        question=gold.question,
        gold_answer=gold.answer,
        predicted_answer=pred.answer
    )
    return float(result.is_correct)
```

---

## Example 9: BootstrapFewShot Optimization

```python
# ============================================================
# WHAT: Optimize a QA program using BootstrapFewShot.
# WHY:  BootstrapFewShot automatically discovers which training
#       examples, when shown as demonstrations, improve the
#       program's performance. You get few-shot prompting without
#       manually selecting or formatting examples.
# ============================================================
import dspy
from dspy.teleprompt import BootstrapFewShot

class SimpleQA(dspy.Module):
    def __init__(self):
        self.predict = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        return self.predict(question=question)

trainset = [
    dspy.Example(question="What is the boiling point of water?",
                 answer="100 degrees Celsius").with_inputs("question"),
    dspy.Example(question="Who painted the Mona Lisa?",
                 answer="Leonardo da Vinci").with_inputs("question"),
    dspy.Example(question="What is the speed of light?",
                 answer="approximately 299,792,458 meters per second").with_inputs("question"),
    dspy.Example(question="What year did WWII end?",
                 answer="1945").with_inputs("question"),
    dspy.Example(question="What element has atomic number 79?",
                 answer="Gold").with_inputs("question"),
]

def exact_match(gold, pred, trace=None):
    return gold.answer.lower() in pred.answer.lower()

optimizer = BootstrapFewShot(
    metric=exact_match,
    max_bootstrapped_demos=3,
    max_labeled_demos=4
)

program = SimpleQA()
compiled = optimizer.compile(program, trainset=trainset)

result = compiled(question="Who discovered penicillin?")
print(result.answer)
```

---

## Example 10: BootstrapFewShotWithRandomSearch

```python
# ============================================================
# WHAT: Use random search over configurations for better results.
# WHY:  BootstrapFewShotWithRandomSearch tries many different
#       subsets of bootstrapped demonstrations and evaluates
#       each on a validation set, then picks the best one.
#       This extra search step often improves over basic bootstrap.
# ============================================================
import dspy
from dspy.teleprompt import BootstrapFewShotWithRandomSearch

optimizer = BootstrapFewShotWithRandomSearch(
    metric=exact_match,
    max_bootstrapped_demos=4,
    max_labeled_demos=4,
    num_candidate_programs=10,  # number of random configs to try
    num_threads=4               # parallel evaluation threads
)

compiled = optimizer.compile(
    SimpleQA(),
    trainset=trainset[:40],
    valset=trainset[40:]  # separate validation set
)
```

---

## Example 11: MIPRO Optimization

```python
# ============================================================
# WHAT: Use MIPROv2 to optimize both instructions and few-shots.
# WHY:  MIPRO is the most powerful DSPy optimizer. It jointly
#       optimizes the natural language instruction in each module
#       AND the few-shot demonstrations. This usually achieves
#       the highest accuracy but requires more LLM calls.
#       Use when optimization budget allows.
# ============================================================
import dspy
from dspy.teleprompt import MIPROv2

optimizer = MIPROv2(
    metric=exact_match,
    auto="medium",       # "light", "medium", or "heavy" budget
    verbose=True
)

compiled = optimizer.compile(
    SimpleQA(),
    trainset=trainset,
    requires_permission_to_run=False  # skip interactive confirmation
)

# Inspect the learned instructions
for name, module in compiled.named_predictors():
    print(f"\n{name}:")
    print(f"  Instructions: {module.extended_signature.instructions}")
```

---

## Example 12: dspy.Assert Hard Constraint

```python
# ============================================================
# WHAT: Enforce a hard constraint on program output.
# WHY:  Assertions guarantee output properties that must always
#       hold. If violated, DSPy retries with backtracking up to
#       max_backtracks times. This is useful for format rules,
#       safety filters, or logical invariants.
# ============================================================
import dspy

class ConstrainedSummarizer(dspy.Module):
    def __init__(self):
        self.summarize = dspy.ChainOfThought("article -> summary")

    def forward(self, article):
        result = self.summarize(article=article)

        # Hard constraint: summary must be 50 words or fewer
        word_count = len(result.summary.split())
        dspy.Assert(
            word_count <= 50,
            f"Summary is {word_count} words but must be 50 or fewer. Write shorter."
        )

        # Hard constraint: must not start with "I"
        dspy.Assert(
            not result.summary.startswith("I "),
            "Summary must not start with 'I'. Rephrase to avoid first-person."
        )

        return result
```

---

## Example 13: dspy.Suggest Soft Constraint

```python
# ============================================================
# WHAT: Apply a soft (non-blocking) constraint on output.
# WHY:  Suggests nudge the model towards better behavior without
#       failing hard if the constraint can't be satisfied.
#       Use for quality guidelines, style recommendations, or
#       checks where partial compliance is acceptable.
# ============================================================
import dspy

class GuidedAnswerer(dspy.Module):
    def __init__(self):
        self.answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, context, question):
        result = self.answer(context=context, question=question)

        # Soft constraint: answer should cite the context
        context_words = set(context.lower().split())
        answer_words = set(result.answer.lower().split())
        overlap = len(context_words & answer_words)

        dspy.Suggest(
            overlap >= 3,
            "The answer should use specific words from the context."
        )

        # Soft constraint: answer should not be too short
        dspy.Suggest(
            len(result.answer) >= 20,
            "Provide a more detailed answer with at least a sentence."
        )

        return result
```

---

## Example 14: RAG Program with dspy.Retrieve

```python
# ============================================================
# WHAT: Build a Retrieval-Augmented Generation pipeline.
# WHY:  RAG grounds LLM answers in retrieved facts, reducing
#       hallucination and enabling use of proprietary knowledge.
#       DSPy's Retrieve module integrates seamlessly with the
#       rest of the program and can be optimized end-to-end.
# ============================================================
import dspy

class GenerateWithCitations(dspy.Signature):
    """Answer the question using only the provided context."""
    context: list[str] = dspy.InputField(desc="retrieved passages")
    question: str = dspy.InputField()
    answer: str = dspy.OutputField(desc="factual answer grounded in context")

class RAG(dspy.Module):
    def __init__(self, k=3):
        self.retrieve = dspy.Retrieve(k=k)
        self.generate = dspy.ChainOfThought(GenerateWithCitations)

    def forward(self, question):
        docs = self.retrieve(query=question).passages
        return self.generate(context=docs, question=question)

rag = RAG(k=5)
result = rag(question="What are the main causes of inflation?")
print(result.answer)
```

---

## Example 15: TypedPredictor with Pydantic Model

```python
# ============================================================
# WHAT: Use TypedPredictor to get structured, validated output.
# WHY:  TypedPredictor ensures outputs conform to a Pydantic
#       schema, making it safe to access fields programmatically.
#       It auto-retries on malformed JSON, dramatically reducing
#       production parsing errors compared to manual parsing.
# ============================================================
import dspy
from pydantic import BaseModel, Field
from typing import Literal

class MovieReview(BaseModel):
    title: str = Field(description="movie title")
    rating: float = Field(ge=0.0, le=10.0, description="rating from 0-10")
    sentiment: Literal["positive", "negative", "mixed"]
    strengths: list[str] = Field(description="what the movie does well")
    weaknesses: list[str] = Field(description="what the movie does poorly")
    recommended: bool

class ReviewAnalyzer(dspy.Signature):
    """Analyze a movie review and extract structured information."""
    review_text: str = dspy.InputField()
    analysis: MovieReview = dspy.OutputField()

analyzer = dspy.TypedPredictor(ReviewAnalyzer)
result = analyzer(review_text="Inception is a mind-bending thriller with stunning visuals...")
print(result.analysis.rating)       # float
print(result.analysis.recommended)  # bool
print(result.analysis.strengths)    # list[str]
```

---

## Example 16: TypedChainOfThought

```python
# ============================================================
# WHAT: Combine CoT reasoning with structured typed output.
# WHY:  TypedChainOfThought gets the best of both worlds:
#       explicit reasoning traces improve accuracy while Pydantic
#       validation ensures the output is well-structured and safe
#       to consume programmatically in downstream code.
# ============================================================
import dspy
from pydantic import BaseModel

class MedicalExtraction(BaseModel):
    patient_age: int
    diagnosis: str
    medications: list[str]
    follow_up_days: int
    urgent: bool

class ExtractMedicalInfo(dspy.Signature):
    """Extract structured medical information from clinical notes."""
    clinical_note: str = dspy.InputField()
    extracted: MedicalExtraction = dspy.OutputField()

extractor = dspy.TypedChainOfThought(ExtractMedicalInfo)

result = extractor(clinical_note=(
    "67-year-old male presents with hypertension. "
    "Prescribed lisinopril 10mg and amlodipine 5mg. "
    "Follow up in 14 days. No acute concerns."
))
print(result.extracted.patient_age)     # 67
print(result.extracted.medications)    # ["lisinopril 10mg", "amlodipine 5mg"]
print(result.extracted.follow_up_days) # 14
```

---

## Example 17: Saving and Loading Compiled Programs

```python
# ============================================================
# WHAT: Persist a compiled DSPy program to disk and reload it.
# WHY:  Optimization is expensive (many LLM calls). Once a
#       program is compiled, you want to save and reuse it
#       without rerunning optimization every time. Saved files
#       are JSON -- human-readable and version-controllable.
# ============================================================
import dspy

# After compilation...
compiled_rag = optimizer.compile(rag, trainset=trainset)

# Save to disk
compiled_rag.save("compiled_rag_v1.json")

# Later: load without rerunning optimization
fresh_rag = RAG()  # create a fresh instance with same architecture
fresh_rag.load("compiled_rag_v1.json")

# Verify it works
result = fresh_rag(question="What is photosynthesis?")
print(result.answer)

# Inspect what was learned
import json
with open("compiled_rag_v1.json") as f:
    saved_state = json.load(f)
# Shows optimized instructions and few-shot demos for each module
```

---

## Example 18: Multi-Hop Question Answering

```python
# ============================================================
# WHAT: Build a multi-hop QA system that chains retrieval steps.
# WHY:  Some questions require multiple retrieval hops: e.g.,
#       "Who directed the film starring the actor born in X city?"
#       requires finding the actor, then the film, then director.
#       DSPy's module composition makes this natural to express,
#       and optimizers learn which query strategies work best.
# ============================================================
import dspy
from dspy.teleprompt import BootstrapFewShot

class GenerateSearchQuery(dspy.Signature):
    """Generate a targeted search query to find the next needed fact."""
    gathered_context: str = dspy.InputField(desc="facts gathered so far")
    original_question: str = dspy.InputField()
    next_query: str = dspy.OutputField(desc="a specific search query for the next hop")

class MultiHopQA(dspy.Module):
    def __init__(self, num_hops=3):
        self.generate_query = dspy.ChainOfThought(GenerateSearchQuery)
        self.retrieve = dspy.Retrieve(k=2)
        self.generate_answer = dspy.ChainOfThought(
            "context, question -> answer"
        )
        self.num_hops = num_hops

    def forward(self, question):
        context = []
        for hop in range(self.num_hops):
            query_result = self.generate_query(
                gathered_context="\n".join(context),
                original_question=question
            )
            passages = self.retrieve(query=query_result.next_query).passages
            context.extend(passages)
        return self.generate_answer(
            context="\n---\n".join(context),
            question=question
        )

multihop_trainset = [
    dspy.Example(
        question="Who was the mentor of the person who invented the telephone?",
        answer="Joseph Henry"
    ).with_inputs("question"),
]

def answer_metric(gold, pred, trace=None):
    return gold.answer.lower() in pred.answer.lower()

optimizer = BootstrapFewShot(metric=answer_metric, max_bootstrapped_demos=2)
compiled_multihop = optimizer.compile(MultiHopQA(num_hops=3), trainset=multihop_trainset)

result = compiled_multihop(
    question="In what city was the inventor of the World Wide Web born?"
)
print(result.answer)
```

---

*See THEORY.md for conceptual depth and PRACTICALS.md for hands-on project guides.*
