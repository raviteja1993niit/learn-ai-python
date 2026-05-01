# 🌾 Haystack — Open-Source NLP & AI Framework

## What is Haystack?
Haystack (by deepset) is an open-source framework for building **NLP-powered search,
Q&A, and RAG applications**. Strong alternative to LangChain for search-heavy apps.

## Haystack vs LangChain
| Feature | Haystack | LangChain |
|---------|----------|-----------|
| Primary focus | Document search/QA | General LLM chaining |
| Pipeline style | Component-based | Chain/graph |
| Evaluation | Built-in RAGAS-style | External |
| Document stores | Many built-in | Via integrations |
| Best for | Production RAG | Flexible agents |

## Key Components
```python
from haystack import Pipeline
from haystack.components.retrievers import InMemoryBM25Retriever
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import RAGPromptBuilder

# Build RAG pipeline
pipe = Pipeline()
pipe.add_component("retriever", InMemoryBM25Retriever(document_store=store))
pipe.add_component("prompt_builder", RAGPromptBuilder(template="..."))
pipe.add_component("llm", OpenAIGenerator(model="gpt-4o-mini"))

pipe.connect("retriever", "prompt_builder.documents")
pipe.connect("prompt_builder", "llm")

result = pipe.run({"retriever": {"query": "What is Python?"}})
```

## Learning Path
1. `pip install haystack-ai`
2. Basic document Q&A pipeline
3. Vector-based retrieval (FAISS/Weaviate)
4. Evaluate pipeline with built-in metrics
5. Compare with LangChain RAG

## What to Build
- [ ] Document search engine over PDF collection
- [ ] Enterprise Q&A system with evaluation
- [ ] Compare Haystack vs LangChain RAG quality

## Related Folders
- `agentic-ai/RAG-Tutorials/` — LangChain RAG comparison
- `agentic-ai/Llamindex-Projects-main/` — LlamaIndex comparison