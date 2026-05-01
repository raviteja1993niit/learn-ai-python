# 🦙 Ollama — Local LLMs, Zero Cloud Dependency

## What is Ollama?
Ollama is a tool for running large language models locally on your machine with a single CLI command. It bundles model weights, a runtime, and a REST API server into one binary, letting you run Llama 3, Mistral, Phi-3, Gemma 2, and CodeLlama privately — no API keys, no usage costs, and no data leaving your machine.

## Why Learn It?
- Complete data privacy: sensitive documents never leave your local environment
- Zero API costs — run thousands of queries against powerful models for free
- Works offline: build and demo AI apps without an internet connection
- Drop-in LangChain integration via `OllamaLLM` and `OllamaEmbeddings`

## Key Concepts
```python
# --- CLI Quick Start ---
# ollama pull llama3          # download Llama 3 8B (~4.7GB)
# ollama pull mistral         # Mistral 7B — fast, great for coding
# ollama pull phi3            # Microsoft Phi-3 Mini — tiny but capable
# ollama pull gemma2          # Google Gemma 2 9B — strong reasoning
# ollama pull codellama       # Code-specialized Llama variant
# ollama run llama3           # interactive REPL
# ollama serve                # start REST API on localhost:11434

import ollama

# Generate a completion
response = ollama.generate(model="llama3", prompt="Explain attention mechanisms in 3 bullets.")
print(response["response"])

# Multi-turn chat
messages = [{"role": "user", "content": "What is RAG?"}]
response = ollama.chat(model="mistral", messages=messages)
print(response["message"]["content"])

# Streaming output
for chunk in ollama.chat(model="llama3", messages=messages, stream=True):
    print(chunk["message"]["content"], end="", flush=True)

# LangChain integration
from langchain_ollama import OllamaLLM, OllamaEmbeddings

llm = OllamaLLM(model="llama3", temperature=0.1)
print(llm.invoke("Summarize the transformer architecture in 2 sentences."))

embeddings = OllamaEmbeddings(model="nomic-embed-text")
vectors = embeddings.embed_documents(["Hello world", "Goodbye world"])
print(len(vectors[0]))   # 768

# Offline RAG with Ollama
from langchain_community.vectorstores import FAISS
from langchain.text_splitter import RecursiveCharacterTextSplitter

texts = ["LSTMs use gates to control memory.", "Transformers use self-attention."]
splitter = RecursiveCharacterTextSplitter(chunk_size=200)
docs = splitter.create_documents(texts)
vectorstore = FAISS.from_documents(docs, embeddings)
retriever = vectorstore.as_retriever()
context = retriever.invoke("How do transformers work?")
answer = llm.invoke(f"Context: {context}\n\nQuestion: How do transformers work?")
```

## Learning Path
1. `pip install ollama langchain-ollama langchain-community faiss-cpu` + install [Ollama binary](https://ollama.com)
2. Pull and run your first model: `ollama run phi3` (smallest/fastest to start)
3. Explore the REST API at `http://localhost:11434/api/generate` with curl or httpx
4. Swap a cloud LLM for `OllamaLLM` in an existing LangChain chain — verify identical behavior
5. Create a custom `Modelfile` to give your model a system prompt and personality

## What to Build
- [ ] Fully offline RAG over private company docs using Ollama + FAISS
- [ ] Local coding assistant with CodeLlama hooked into VS Code via Continue extension
- [ ] Modelfile-powered persona chatbot with a custom system prompt and temperature

## Related Folders
- `generative-ai/rag-advanced-patterns-main/` — build an offline RAG pipeline with Ollama embeddings
- `generative-ai/langchain-main/` — LangChain chains that swap cloud LLMs for OllamaLLM
- `generative-ai/llm-evaluation-ragas-main/` — evaluate Ollama model quality vs GPT-4o
