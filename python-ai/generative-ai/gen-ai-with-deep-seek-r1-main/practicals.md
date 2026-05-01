# DeepSeek R1 — Practical Projects (10 Projects)

```bash
pip install openai groq python-dotenv numpy streamlit
ollama pull deepseek-r1:7b
```

---

## Project 1 — Interactive Math Problem Solver
**Goal**: CLI tool that solves math problems step-by-step showing reasoning.
**Features**: parse and display thinking separately from answer, LaTeX formatting, problem history
**Key concepts**: reasoning_content, parse_r1(), temperature=0.6
**Hint**:
```python
while True:
    problem = input("Math problem: ")
    r = client.chat.completions.create(
        model="deepseek-reasoner", temperature=0.6,
        messages=[{"role":"user","content":problem}]
    )
    msg = r.choices[0].message
    print(f"\nThinking: {getattr(msg,'reasoning_content','')[:500]}")
    print(f"\nAnswer: {msg.content}")
```
**Extension**: Log all problems + solutions to a markdown file.

---

## Project 2 — AI Code Debugger
**Goal**: Paste buggy code + error; get root cause analysis and fixed code.
**Features**: language detection, side-by-side diff, test suggestions, batch file processing
**Key concepts**: DeepSeek R1 reasoning for debugging, structured output
**Hint**: Prompt = "Analyse this {language} code. Error: {error}. Provide: 1) Root cause, 2) Fixed code, 3) Explanation, 4) How to test the fix."
**Extension**: Watch a directory for new .py files and auto-debug them.

---

## Project 3 — Research Paper Summariser
**Goal**: Summarise academic papers (PDF or text) into structured reports.
**Features**: key hypothesis, methodology, findings, limitations, implications
**Key concepts**: long-context, RAG, structured prompting
**Hint**: Chunk large papers; summarise each section; combine with a reduce step using DeepSeek for final synthesis
**Expected output**: Structured markdown report with all sections

---

## Project 4 — RAG Chatbot with DeepSeek
**Goal**: Chat over a custom knowledge base using DeepSeek R1 for reasoning.
**Features**: document indexing, semantic search, cited answers, multi-turn memory
**Key concepts**: embeddings (OpenAI or Sentence Transformers), cosine similarity, context injection
**Architecture**:
```
User Query → Embed → Vector Search → Top-3 Chunks → DeepSeek R1 → Cited Answer
```
**Hint**: Store embeddings in a JSON or SQLite file to avoid re-computing

---

## Project 5 — Local Reasoning Assistant (Ollama)
**Goal**: Fully offline reasoning assistant using Ollama + deepseek-r1:7b.
**Features**: no API key needed, thinking display toggle, conversation history, markdown output
**Key concepts**: Ollama OpenAI-compatible API, local inference
**Hint**: Start Ollama server with `ollama serve`; connect at http://localhost:11434/v1
**Requirements**: 8GB+ RAM (7B model), or 16GB+ for 14B

---

## Project 6 — Coding Interview Practice Tool
**Goal**: Practice coding problems with AI feedback using DeepSeek's coding strength.
**Features**: problem generator by difficulty, submit solution for review, hints on demand, optimal solution comparison
**Key concepts**: structured prompting, multi-turn conversation, code evaluation
**Hint**: System prompt: "You are a Google/FAANG interviewer. Present a coding problem, evaluate solutions, provide feedback, and reveal optimal solution."

---

## Project 7 — Proof Verifier
**Goal**: Verify mathematical proofs for correctness and completeness.
**Features**: step-by-step verification, identify logical gaps, suggest improvements
**Key concepts**: DeepSeek R1's mathematical reasoning strength, structured output
**Hint**:
```python
prompt = f"Verify this mathematical proof step by step. For each step: state if it is VALID/INVALID and why.\n\nProof:\n{proof_text}"
```
**Extension**: Grade proofs on a scale of 0-100 with detailed feedback.

---

## Project 8 — Multi-step Planning Agent
**Goal**: Given a complex goal, DeepSeek R1 creates and executes a plan.
**Tools**: web_search (mock), file_read, file_write, calculate, summarise
**Features**: plan generation, sequential execution, progress tracking, result report
**Key concepts**: agentic loop, function calling, DeepSeek reasoning for planning
**Hint**: First call generates a numbered plan; subsequent calls execute each step; feed results back as context

---

## Project 9 — Technical Interview Coach
**Goal**: Simulate a technical interview and provide detailed feedback.
**Features**: behavioural + technical questions, STAR method evaluation, coding challenges
**Key concepts**: multi-turn conversation, structured evaluation
**Hint**: System prompt: "You are a senior engineer conducting a technical interview. Ask progressively harder questions. After each answer, provide specific feedback on what was good and what was missing."

---

## Project 10 — Groq-Powered Real-time Reasoner
**Goal**: Fast reasoning app using Groq (free tier) for near-instant answers.
**Features**: benchmarks time vs DeepSeek API, reasoning toggle, API cost tracker
**Key concepts**: Groq client, parse_r1(), streaming, performance comparison
**Hint**:
```python
import time
from groq import Groq
groq_client = Groq()
start = time.time()
r = groq_client.chat.completions.create(
    model="deepseek-r1-distill-llama-70b",
    messages=[{"role":"user","content":question}],
    temperature=0.6
)
elapsed = time.time() - start
print(f"Time: {elapsed:.2f}s | Tokens: {r.usage.total_tokens}")
print(parse_r1(r.choices[0].message.content)["answer"])
```
**Extension**: Build a simple leaderboard comparing accuracy on a fixed set of math problems.