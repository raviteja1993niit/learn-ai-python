# 🧠 Agent Memory Management — Persistent & Contextual Agent Memory

## What is Agent Memory Management?
Agent memory management is the set of techniques that give AI agents the ability to store, retrieve,
and forget information across turns, sessions, and tasks. Without explicit memory design, agents are
stateless — every call starts blank. Good memory architecture makes agents feel coherent, personalised,
and capable of long-horizon reasoning.

## Why Learn It?
- Stateless LLMs cannot maintain context beyond the context window — memory fixes this
- Different memory types (short-term, long-term, episodic) suit different use cases
- Vector store memory enables semantic recall of past conversations at scale
- MemGPT / mem0 patterns are increasingly common in production agent stacks
- Required for building personal assistants, autonomous research agents, and multi-session workflows

## Key Concepts
```python
# ── Memory Type Overview ───────────────────────────────────────────────────
# Sensory   → raw input buffer (current prompt tokens)
# Short-term → ConversationBufferMemory (last N turns in context)
# Long-term  → vector store (semantically searchable past knowledge)
# Episodic   → timestamped event log (what happened, when, in what order)

# ── 1. LangChain: Buffer vs Summary Memory ─────────────────────────────────
from langchain.memory import ConversationBufferMemory, ConversationSummaryMemory
from langchain_openai import ChatOpenAI
from langchain.chains import ConversationChain

llm = ChatOpenAI(model="gpt-4o-mini")

buffer_memory = ConversationBufferMemory()          # keeps full history
summary_memory = ConversationSummaryMemory(llm=llm) # compresses old turns

chain = ConversationChain(llm=llm, memory=summary_memory, verbose=True)
chain.predict(input="My name is Alice and I'm building a RAG pipeline.")
chain.predict(input="What was I working on?")   # agent recalls from summary

# ── 2. Vector Store Memory (FAISS) ─────────────────────────────────────────
from langchain.memory import VectorStoreRetrieverMemory
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_texts(["placeholder"], embeddings)
retriever = vectorstore.as_retriever(search_kwargs={"k": 3})
vector_memory = VectorStoreRetrieverMemory(retriever=retriever)

vector_memory.save_context(
    {"input": "I prefer concise answers"},
    {"output": "Got it, I'll keep responses short"},
)
relevant = vector_memory.load_memory_variables({"prompt": "How should you respond?"})

# ── 3. mem0 — Managed Memory Layer ────────────────────────────────────────
from mem0 import Memory

m = Memory()
user_id = "alice-001"

m.add("I am allergic to peanuts", user_id=user_id)
m.add("My favourite programming language is Python", user_id=user_id)

results = m.search("What does the user like?", user_id=user_id)
for r in results:
    print(r["memory"])

all_memories = m.get_all(user_id=user_id)

# ── 4. Redis Session Memory ────────────────────────────────────────────────
import redis, json

r = redis.Redis(host="localhost", port=6379, decode_responses=True)

def save_turn(session_id: str, role: str, content: str, max_turns: int = 20):
    key = f"session:{session_id}:history"
    r.rpush(key, json.dumps({"role": role, "content": content}))
    r.ltrim(key, -max_turns * 2, -1)   # keep only last N turns
    r.expire(key, 86400)               # TTL: 24 h

def load_history(session_id: str) -> list[dict]:
    key = f"session:{session_id}:history"
    return [json.loads(item) for item in r.lrange(key, 0, -1)]

# ── 5. Forgetting Strategy ─────────────────────────────────────────────────
def forget_old_memories(memory: list[dict], max_tokens: int = 2000) -> list[dict]:
    """Sliding-window forgetting: drop oldest turns when over budget."""
    total = sum(len(m["content"]) // 4 for m in memory)  # rough token estimate
    while total > max_tokens and memory:
        removed = memory.pop(0)
        total -= len(removed["content"]) // 4
    return memory
```

## Learning Path
1. Understand the 4 memory types and when each is appropriate
2. Build a chatbot with `ConversationBufferMemory` and observe context growth
3. Swap to `ConversationSummaryMemory` and compare quality vs. cost
4. Integrate FAISS vector memory for semantic recall across sessions
5. Explore mem0 for a managed, cross-session memory store
6. Implement Redis-backed session memory for stateless API deployments
7. Study MemGPT's archival memory and recursive summarisation patterns

## What to Build
- [ ] Chatbot that remembers user preferences across sessions using mem0
- [ ] Comparison script: BufferMemory vs SummaryMemory on a 30-turn conversation
- [ ] Agent that stores episodic logs (timestamped events) and queries them semantically
- [ ] Redis-backed multi-user session memory for a FastAPI chat endpoint
- [ ] Forgetting benchmark: measure recall accuracy vs. compression ratio

## Related Folders
- `agentic-ai/react-agent-pattern-main/` — add persistent memory to a ReAct loop
- `agentic-ai/a2a-protocol-main/` — share memory context across A2A agent networks
- `rag/` — vector store patterns are shared between RAG and vector memory
