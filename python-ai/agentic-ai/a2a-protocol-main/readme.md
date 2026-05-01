# 🤝 A2A Protocol — Agent-to-Agent Communication

## What is A2A?
A2A (Agent-to-Agent) is an open protocol introduced by Google in 2025 that defines how AI agents
discover, communicate, and delegate tasks to each other across different frameworks and vendors.
It standardises the Agent Card, Task lifecycle, and JSON-RPC 2.0 transport so heterogeneous agents
can interoperate without custom glue code.

## Why Learn It?
- Industry-standard protocol for multi-agent systems (backed by Google, LangChain, Vertex AI)
- Enables true agent marketplaces — plug any compliant agent into your orchestration graph
- Pairs with MCP (tool access) to give agents both skills and peers
- Streaming SSE support makes it suitable for long-running agentic tasks
- Essential for building production multi-agent pipelines in 2025+

## Key Concepts
```python
# ── 1. Agent Card (served at /.well-known/agent.json) ──────────────────────
AGENT_CARD = {
    "name": "ResearchAgent",
    "description": "Searches the web and summarises findings",
    "url": "http://localhost:8001",
    "version": "1.0.0",
    "capabilities": {"streaming": True},
    "skills": [
        {
            "id": "web_search",
            "name": "Web Search",
            "description": "Search the web and return a summary",
            "inputModes": ["text"],
            "outputModes": ["text"],
        }
    ],
}

# ── 2. FastAPI A2A-compliant agent server ──────────────────────────────────
from fastapi import FastAPI
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
import uuid, json, asyncio

app = FastAPI()

class TaskRequest(BaseModel):
    id: str
    message: dict           # A2A Message object
    sessionId: str | None = None

@app.get("/.well-known/agent.json")
async def agent_card():
    return JSONResponse(AGENT_CARD)

@app.post("/tasks/send")
async def send_task(req: TaskRequest):
    user_text = req.message["parts"][0]["text"]
    result = f"[ResearchAgent] Summary for: {user_text}"   # replace with real logic
    return {
        "id": req.id,
        "status": {"state": "completed"},
        "artifacts": [{"parts": [{"type": "text", "text": result}]}],
    }

@app.post("/tasks/sendSubscribe")
async def send_subscribe(req: TaskRequest):
    """Streaming SSE response for long-running tasks."""
    user_text = req.message["parts"][0]["text"]

    async def event_stream():
        for chunk in [f"Searching for {user_text}...", "Analysing results...", "Done."]:
            await asyncio.sleep(0.5)
            event = {"id": req.id, "status": {"state": "working"}, "artifact": {"parts": [{"type": "text", "text": chunk}]}}
            yield f"data: {json.dumps(event)}\n\n"
        final = {"id": req.id, "status": {"state": "completed"}}
        yield f"data: {json.dumps(final)}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")

# ── 3. A2A Client — calling another agent ─────────────────────────────────
import httpx

async def call_agent(agent_url: str, text: str) -> str:
    task_id = str(uuid.uuid4())
    payload = {
        "id": task_id,
        "message": {"role": "user", "parts": [{"type": "text", "text": text}]},
    }
    async with httpx.AsyncClient() as client:
        r = await client.post(f"{agent_url}/tasks/send", json=payload)
        data = r.json()
        return data["artifacts"][0]["parts"][0]["text"]

# ── 4. A2A vs MCP comparison ───────────────────────────────────────────────
# | Dimension        | MCP                      | A2A                        |
# |------------------|--------------------------|----------------------------|
# | Purpose          | Agent ↔ Tool             | Agent ↔ Agent              |
# | Transport        | stdio / HTTP+SSE         | HTTP+SSE / JSON-RPC 2.0    |
# | Discovery        | Server manifest          | Agent Card (well-known URL) |
# | Streaming        | Yes                      | Yes                        |
# | Task lifecycle   | Request/response         | submitted→working→done     |
```

## Learning Path
1. Read the A2A specification at [google.github.io/A2A](https://google.github.io/A2A)
2. Run the official Python sample server and client
3. Build a minimal FastAPI A2A server (Agent Card + `/tasks/send`)
4. Add streaming SSE via `/tasks/sendSubscribe`
5. Orchestrate two agents: a ResearchAgent calling a SummaryAgent
6. Explore `a2a-sdk` Python package for boilerplate reduction
7. Compare with MCP and decide when to use each

## What to Build
- [ ] Minimal A2A server with FastAPI serving a valid Agent Card
- [ ] Two-agent pipeline: OrchestratorAgent delegates to ResearchAgent via A2A
- [ ] Streaming A2A response visualised in the terminal with rich
- [ ] Agent registry that discovers agents by querying their `/.well-known/agent.json`
- [ ] A2A + MCP hybrid: agent exposes A2A interface but calls tools via MCP

## Related Folders
- `agentic-ai/react-agent-pattern-main/` — ReAct agents are natural A2A skill implementors
- `agentic-ai/agent-memory-management-main/` — share memory across agents in an A2A network
- `agentic-ai/mcp-model-context-protocol-main/` — MCP for tools, A2A for agent peers
