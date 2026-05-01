# 🔬 DSPy — Programming with Foundation Models

## What is DSPy?
DSPy (Declarative Self-improving Language Programs) by Stanford replaces
**manual prompt engineering** with **programmatic, optimizable LLM pipelines**.

## Why DSPy?
- Write LLM programs as Python code — not brittle prompt strings
- Automatically optimizes prompts and few-shot examples
- Composable: chain modules like neural network layers

## Key Concepts
```python
import dspy

# Define a signature (input → output contract)
class SentimentAnalysis(dspy.Signature):
    """Classify sentiment of a review."""
    review: str = dspy.InputField()
    sentiment: str = dspy.OutputField(desc="positive, negative, or neutral")

# Use a module
classify = dspy.Predict(SentimentAnalysis)

# Chain modules
class RAGPipeline(dspy.Module):
    def __init__(self):
        self.retrieve = dspy.Retrieve(k=3)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

# Compile / Optimize
teleprompter = dspy.BootstrapFewShot(metric=my_metric)
optimized = teleprompter.compile(RAGPipeline(), trainset=train_data)
```

## Learning Path
1. `pip install dspy-ai`
2. Basic Predict module
3. ChainOfThought reasoning
4. RAG pipeline with Retrieve
5. Optimize with BootstrapFewShot

## What to Build
- [ ] Self-optimizing QA system
- [ ] Automated RAG pipeline that improves itself
- [ ] Multi-hop reasoning agent

## Related Folders
- `agentic-ai/Prompt-Engineering-LangChain-main/` — manual prompt eng comparison
- `agentic-ai/RAG-Tutorials/` — RAG foundation