# DSPy Theory: The Complete Guide

## 1. DSPy Philosophy: Replace Prompts with Programs

DSPy (Declarative Self-improving Python) is a framework that fundamentally rethinks how
developers interact with large language models (LLMs). The core insight is simple but
profound: **instead of writing prompts, you write programs**.

Traditional LLM applications are built around carefully crafted prompt strings. These prompts
are brittle, hard to maintain, and require manual iteration every time you change your model,
data, or task. DSPy replaces this paradigm with a programmatic approach: you declare *what*
you want (the signature), build composable *modules* that implement logic, and let an
*optimizer* automatically discover the best prompts, instructions, and few-shot examples.

At its core, DSPy treats prompt engineering as a machine learning problem. Just as you would
not manually tune the weights of a neural network, DSPy argues you should not manually tune
prompts. Instead, define your metric, supply training data, and compile your program with an
optimizer that finds the best configuration for your specific task and model.

This shift has several important consequences:
- Programs are **modular**: individual components can be reused, composed, and tested independently.
- Programs are **portable**: the same DSPy program can be compiled for GPT-4, Claude, or a
  local Llama model -- the optimizer finds model-specific optimal prompts for each.
- Programs are **improvable**: as you collect more data or refine your metric, you can
  recompile and your program automatically improves.
- Programs are **maintainable**: logic lives in Python code, not in sprawling prompt strings
  scattered across configuration files.

DSPy was created at Stanford and is grounded in research on automatic prompt optimization,
retrieval-augmented generation, and neural program synthesis.

---

## 2. Why DSPy? Problems with Manual Prompting

Manual prompt engineering is the dominant practice today, but it suffers from serious flaws
that DSPy is designed to solve.

### Brittleness
Hand-written prompts are extremely sensitive to small changes. Changing a model version,
switching from GPT-4 to Claude, or adding a new input field often requires rewriting prompts
from scratch. There is no principled way to know *why* a prompt works or predict how it will
behave after minor changes.

### Lack of Optimization
Human intuition about what makes a good prompt is unreliable. Research consistently shows
that automatically optimized prompts -- even ones that look strange to humans -- frequently
outperform hand-written ones. Manual iteration is slow, expensive, and bounded by human
cognitive limits.

### Non-Reusability
A prompt written for one task cannot easily be reused for a related task. The logic embedded
in prompt strings is not composable. You cannot unit-test a prompt string; you can only
eyeball outputs.

### Pipeline Fragility
Complex LLM pipelines (RAG, multi-hop QA, agents) require multiple coordinated prompts.
Each prompt affects downstream inputs. Manual tuning of multi-step pipelines is
combinatorially difficult: changing prompt 1 can break prompts 2 and 3 downstream.

### DSPy's Answer
DSPy addresses all these problems by separating the **structure** of your program (modules,
signatures, control flow) from the **instructions** that guide the LLM. The structure is
written by the developer; the instructions are found by the optimizer. This separation of
concerns is the key architectural insight.

---

## 3. Signatures: Input/Output Field Contracts

A **signature** in DSPy is a declarative specification of what a module should do. It defines
input fields, output fields, and optional descriptions that guide the LLM. Signatures are the
*interface contract* between your Python code and the language model.

### Basic Inline Syntax

The simplest signature is a string: `"input_field -> output_field"`.

Examples:
- `"question -> answer"`
- `"context, question -> answer"`
- `"document -> summary, keywords"`
- `"english_text -> french_translation"`

Multiple inputs are comma-separated on the left; multiple outputs on the right.
DSPy parses these strings and constructs the appropriate input/output schema.

### Class-Based Signatures

For richer control, inherit from `dspy.Signature`:

```python
class GenerateAnswer(dspy.Signature):
    """Answer questions with short factoid answers."""
    context: str = dspy.InputField(desc="relevant facts from a knowledge base")
    question: str = dspy.InputField(desc="a factual question to answer")
    answer: str = dspy.OutputField(desc="often between 1 and 5 words")
```

The class docstring becomes the **task instruction**. Each field has:
- A Python type annotation
- A `dspy.InputField` or `dspy.OutputField` marker
- An optional `desc` string describing what the field should contain

The `desc` fields are critical: they guide the LLM and are also targets for optimization.
Optimizers can learn better descriptions by observing what leads to correct outputs.

### Why Signatures Matter
Signatures decouple the *what* from the *how*. When you define a signature, you are not yet
specifying how the LLM should reason -- that is the module's job. Signatures also enable
automatic prompt construction: DSPy builds prompts from signatures, so you never have to
write "You are given a context and a question. Please answer..." manually.

---

## 4. Modules: The Building Blocks of DSPy Programs

A **module** in DSPy is a composable unit of LLM behavior. Modules are similar to PyTorch
`nn.Module` objects: they have parameters (instructions, examples) that can be optimized,
and they can be composed into larger programs.

### dspy.Predict

`dspy.Predict` is the simplest module. It takes a signature and directly calls the LLM
to produce the output fields.

```python
predictor = dspy.Predict("question -> answer")
result = predictor(question="What is the capital of France?")
print(result.answer)
```

Internally, Predict constructs a prompt from the signature, any few-shot examples it has
learned, and the input values, then calls the configured LLM and parses the output.

### dspy.ChainOfThought

`dspy.ChainOfThought` extends Predict by automatically inserting a `reasoning` field before
the answer. This implements chain-of-thought prompting without requiring you to add
"Think step by step" manually.

```python
cot = dspy.ChainOfThought("context, question -> answer")
result = cot(context="Paris is in France.", question="Where is Paris?")
print(result.reasoning)  # automatic reasoning trace
print(result.answer)
```

ChainOfThought is often more accurate on complex tasks because the model's intermediate
reasoning steps are visible and can be used in few-shot examples.

### dspy.ProgramOfThought

`dspy.ProgramOfThought` takes a different approach: it instructs the LLM to generate
Python code to solve the problem, then *executes* that code to produce the answer.
This is particularly powerful for math, data analysis, and algorithmic tasks.

```python
pot = dspy.ProgramOfThought("question -> answer")
result = pot(question="What is 17 * 23?")
# LLM generates: answer = 17 * 23, then Python executes it
print(result.answer)  # 391
```

### dspy.ReAct

`dspy.ReAct` implements the Reason+Act agent loop. The model iteratively reasons about
what to do, calls a tool, observes the result, and continues until it has enough information
to answer. You provide the available tools as a list of Python functions with docstrings.

```python
def search(query: str) -> str:
    """Search Wikipedia for information."""
    ...

agent = dspy.ReAct("question -> answer", tools=[search])
result = agent(question="Who invented the transistor?")
```

ReAct agents can call tools multiple times, with each iteration informed by previous results.

### dspy.MultiChainComparison

`dspy.MultiChainComparison` generates multiple independent reasoning chains and then
asks the model to compare them and select the best answer. This ensemble approach reduces
errors caused by a single flawed reasoning path.

```python
mcc = dspy.MultiChainComparison("question -> answer", M=3)
result = mcc(question="What causes rainbows?")
```

---

## 5. Optimizers (Teleprompters)

Optimizers -- historically called "teleprompters" in the DSPy codebase -- are the algorithms
that compile a DSPy program by finding optimal prompts, instructions, and few-shot examples.
They are the engine of DSPy's self-improving capability.

### BootstrapFewShot

The simplest optimizer. Given a training set and a metric, it runs the program forward on
training examples, keeps the examples where the program succeeds (according to the metric),
and uses those successful traces as few-shot examples in the compiled program.

```python
from dspy.teleprompt import BootstrapFewShot

optimizer = BootstrapFewShot(metric=my_metric, max_bootstrapped_demos=4)
compiled_program = optimizer.compile(my_program, trainset=trainset)
```

### BootstrapFewShotWithRandomSearch

Extends BootstrapFewShot by running many random configurations and selecting the best one
on a validation set. More thorough than basic bootstrap but requires more LLM calls.

```python
from dspy.teleprompt import BootstrapFewShotWithRandomSearch

optimizer = BootstrapFewShotWithRandomSearch(
    metric=my_metric,
    max_bootstrapped_demos=4,
    num_candidate_programs=8
)
compiled_program = optimizer.compile(my_program, trainset=trainset, valset=valset)
```

### MIPRO

**M**ulti-prompt **I**nstruction **PRO**posal. MIPRO jointly optimizes both the few-shot
examples and the natural language instructions in each module. It uses a Bayesian optimizer
(Tree-structured Parzen Estimator) to efficiently search the combined space.

MIPRO is the recommended optimizer for most production use cases when you want maximum
performance and have enough budget for optimization.

```python
from dspy.teleprompt import MIPROv2

optimizer = MIPROv2(metric=my_metric, auto="medium")
compiled_program = optimizer.compile(
    my_program,
    trainset=trainset,
    requires_permission_to_run=False
)
```

### COPRO

**CO**ordinate Ascent **PRO**mpt Optimization. COPRO optimizes instructions using coordinate
ascent: it iteratively improves the instruction for each module while holding the others
fixed. Simpler than MIPRO but can still find significant improvements.

---

## 6. Metrics: Defining "Good"

A **metric** is a Python function that takes a `gold` example (ground truth) and a
`prediction` (program output) and returns a score -- typically a float between 0 and 1,
or a boolean.

```python
def my_metric(gold, pred, trace=None):
    return gold.answer.lower() == pred.answer.lower()
```

The `trace` parameter is passed during optimization and can be used to apply different
strictness during training vs. evaluation. Metrics can be simple exact-match functions or
complex LLM-as-judge pipelines.

Custom metrics enable DSPy to optimize for exactly what *you* care about, not just a generic
accuracy measure. For example, you might optimize for answer faithfulness, citation quality,
response brevity, or task-specific F1 score.

---

## 7. Training Data: dspy.Example Objects

Training data is provided as a list of `dspy.Example` objects:

```python
trainset = [
    dspy.Example(question="What is 2+2?", answer="4").with_inputs("question"),
    dspy.Example(question="Capital of Japan?", answer="Tokyo").with_inputs("question"),
]
```

`with_inputs()` marks which fields are inputs (vs. labels). DSPy uses this distinction
during optimization: inputs are passed to the program, labels are used to evaluate outputs.
Training sets can be small (as few as 10-20 examples) -- DSPy is designed to work with
limited data by using the LLM itself to generate demonstrations.

---

## 8. dspy.Assert: Hard Constraints

`dspy.Assert` enforces hard constraints on intermediate or final outputs. If the constraint
is violated, DSPy raises an exception and retries with backtracking (up to a configured limit).

```python
dspy.Assert(
    len(answer.split()) <= 10,
    "Answer must be at most 10 words"
)
```

Assertions are useful for enforcing format requirements, length constraints, or logical
invariants that must always hold. They participate in DSPy's automatic retry mechanism.

---

## 9. dspy.Suggest: Soft Constraints

`dspy.Suggest` is like Assert but non-blocking. If the condition is false, DSPy logs a
warning and provides feedback to the LLM for retry, but does not raise an exception
if the constraint cannot be satisfied within the retry budget.

```python
dspy.Suggest(
    answer_is_factual(answer),
    "The answer should be grounded in the provided context"
)
```

Suggests are useful for style guidelines or soft quality checks where you want to nudge
the model but not fail hard if it cannot comply.

---

## 10. Retrieval Modules and RAG

`dspy.Retrieve` is a module that queries a retrieval system (vector database, BM25, etc.)
and returns top-k passages. Combined with other modules, it enables building
Retrieval-Augmented Generation (RAG) pipelines entirely within DSPy's framework.

```python
retrieve = dspy.Retrieve(k=3)
result = retrieve(query="history of transistors")
print(result.passages)
```

DSPy supports many retrieval backends: ColBERT, Qdrant, Weaviate, Pinecone, ChromaDB,
FAISS, and more. The retriever can itself be optimized: BootstrapFewShot can learn
which retrieval queries lead to better final answers.

### RAG Program Pattern

```python
class RAG(dspy.Module):
    def __init__(self):
        self.retrieve = dspy.Retrieve(k=3)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        docs = self.retrieve(query=question).passages
        context = " ".join(docs)
        return self.generate(context=context, question=question)
```

---

## 11. Typed Predictors with Pydantic

`dspy.TypedPredictor` and `dspy.TypedChainOfThought` enforce that outputs conform to
Pydantic models, providing structured, validated outputs.

```python
from pydantic import BaseModel

class Answer(BaseModel):
    value: str
    confidence: float
    sources: list[str]

predictor = dspy.TypedPredictor("question -> answer: Answer")
result = predictor(question="What is quantum entanglement?")
print(result.answer.confidence)  # typed float
```

Typed predictors automatically retry if the LLM produces malformed JSON, dramatically
reducing output parsing errors in production.

---

## 12. Streaming Responses

DSPy supports streaming LLM responses for real-time output in user-facing applications:

```python
import dspy

lm = dspy.LM("openai/gpt-4o", stream=True)
dspy.configure(lm=lm)

predictor = dspy.Predict("question -> answer")
for chunk in predictor.stream(question="Explain quantum computing"):
    print(chunk, end="", flush=True)
```

Streaming is transparent to DSPy's optimization pipeline -- compiled programs retain
their streaming capability.

---

## 13. Caching: Automatic LLM Call Caching

DSPy automatically caches all LLM calls to disk during development. Repeated calls with
identical prompts return cached results instantly, dramatically speeding up the
compile-test-iterate loop.

Caching is controlled via the `cache` parameter:

```python
lm = dspy.LM("openai/gpt-4o", cache=True)   # default: True
lm = dspy.LM("openai/gpt-4o", cache=False)  # disable for production freshness
```

The cache lives in `~/.dspy_cache/` by default. During optimization runs, caching ensures
that if you re-run with the same training data and model, previously seen LLM calls are
not repeated, saving significant cost.

---

## 14. dspy.configure: Global Language Model

`dspy.configure(lm=...)` sets the global language model used by all modules. This is
the primary entry point for initializing DSPy.

```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini", api_key="sk-...")
dspy.configure(lm=lm)
```

Supported model strings follow LiteLLM conventions:
- `"openai/gpt-4o"`, `"openai/gpt-4o-mini"`
- `"anthropic/claude-3-5-sonnet-20241022"`
- `"together_ai/meta-llama/Llama-3-70b-chat-hf"`
- `"ollama/llama3"` for local models

You can also configure a retrieval model: `dspy.configure(lm=lm, rm=retriever)`.

---

## 15. Compiling Programs: The optimizer.compile() Workflow

The full optimization workflow:

1. **Define your program** using modules and signatures
2. **Prepare training data** as `dspy.Example` objects
3. **Define your metric** as a Python function
4. **Choose an optimizer** appropriate for your budget and needs
5. **Compile**: `compiled = optimizer.compile(program, trainset=trainset)`
6. **Evaluate**: test compiled program on a held-out dev set
7. **Save**: persist the compiled program to disk

This workflow is analogous to the ML training loop: define model, prepare data, define loss,
train, evaluate, save.

---

## 16. Saving and Loading Compiled Programs

After compilation, save the program's learned parameters:

```python
compiled_program.save("my_compiled_rag.json")
```

Load it later without rerunning optimization:

```python
fresh_program = MyRAG()  # create a fresh instance with the same architecture
fresh_program.load("my_compiled_rag.json")
```

Saved files are JSON and contain the optimized instructions and few-shot demonstrations for
each module. They are human-readable and can be version-controlled.

---

## 17. DSPy vs LangChain

| Aspect               | DSPy                                     | LangChain                               |
|----------------------|------------------------------------------|-----------------------------------------|
| Core abstraction     | Compiled programs                        | Chains and prompt templates             |
| Prompt management    | Automated via optimizers                 | Manual (written by developer)           |
| Optimization         | First-class, built-in                    | Not built-in                            |
| Portability          | Recompile for new model                  | Prompts often model-specific            |
| Structured outputs   | TypedPredictor with Pydantic             | Output parsers                          |
| Agents               | ReAct module                             | AgentExecutor, various agent types      |
| RAG                  | dspy.Retrieve + RAG module pattern       | Retrieval chains                        |
| Learning curve       | Higher (new paradigm)                    | Lower (familiar chain metaphor)         |
| Best for             | Performance-critical, optimized systems  | Rapid prototyping, broad ecosystem      |

DSPy and LangChain are complementary: LangChain excels at connecting components quickly;
DSPy excels at optimizing them for maximum performance.

---

## 18. Multi-Hop Question Answering with DSPy

Multi-hop QA requires retrieving multiple pieces of information and reasoning across them.
This is one of DSPy's showcase use cases.

```python
class HopSignature(dspy.Signature):
    """Generate a search query to find the next piece of needed information."""
    context: str = dspy.InputField(desc="gathered context so far")
    question: str = dspy.InputField()
    query: str = dspy.OutputField(desc="search query for next hop")

class MultiHopQA(dspy.Module):
    def __init__(self, num_hops=3):
        self.generate_query = dspy.ChainOfThought(HopSignature)
        self.retrieve = dspy.Retrieve(k=2)
        self.generate_answer = dspy.ChainOfThought("context, question -> answer")
        self.num_hops = num_hops

    def forward(self, question):
        context = []
        for _ in range(self.num_hops):
            query = self.generate_query(
                context="\n".join(context), question=question
            ).query
            passages = self.retrieve(query=query).passages
            context.extend(passages)
        return self.generate_answer(
            context="\n".join(context), question=question
        )
```

When compiled with BootstrapFewShot or MIPRO, DSPy automatically learns:
- Which intermediate queries lead to successful final answers
- How to phrase retrieval queries for the specific retrieval system
- How to synthesize multi-hop context into a coherent answer

This is difficult to hand-tune because the quality of hop 1 affects hop 2, creating
combinatorial complexity that DSPy's optimizer handles systematically.

---

*This document covers the core theoretical foundations of DSPy. See EXAMPLES.md for
annotated code samples and PRACTICALS.md for hands-on project guides.*
