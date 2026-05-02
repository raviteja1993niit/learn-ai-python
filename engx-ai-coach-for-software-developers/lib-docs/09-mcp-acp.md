# MCP & ACP Complete Guide
### Model Context Protocol + Agent Communication Protocol

---

## Table of Contents

**Part A — MCP (Model Context Protocol)**
1. [What is MCP?](#1-what-is-mcp)
2. [MCP Architecture](#2-mcp-architecture)
3. [Three Primitives](#3-three-primitives)
4. [Building an MCP Server (Python)](#4-building-an-mcp-server-python)
5. [Building an MCP Client (Python)](#5-building-an-mcp-client-python)
6. [MCP with FastMCP](#6-mcp-with-fastmcp)
7. [Popular MCP Servers](#7-popular-mcp-servers)
8. [MCP with LangChain](#8-mcp-with-langchain)
9. [MCP with LangGraph](#9-mcp-with-langgraph)
10. [MCP Security](#10-mcp-security)

**Part B — ACP (Agent Communication Protocol)**
11. [What is ACP?](#11-what-is-acp)
12. [ACP Core Concepts](#12-acp-core-concepts)
13. [Building an ACP Agent (Python)](#13-building-an-acp-agent-python)
14. [ACP Client — Calling Agents](#14-acp-client--calling-agents)
15. [Multi-Agent ACP Orchestration](#15-multi-agent-acp-orchestration)
16. [MCP + ACP Together](#16-mcp--acp-together)
17. [Interview Q&A (20 Questions)](#17-interview-qa-20-questions)
18. [Complete End-to-End Example](#18-complete-end-to-end-example)

---

# Part A — MCP (Model Context Protocol)

---

## 1. What is MCP?

**MCP (Model Context Protocol)** is Anthropic's open standard that gives LLMs a uniform way to
connect with external tools, data sources, and services. Announced in November 2024, it replaces
the ad-hoc, per-integration approach of traditional function calling with a single, reusable
protocol.

### Core Problem MCP Solves

Without MCP every AI application must write custom connectors for each tool. With MCP, any
compliant server works with any compliant host — the same GitHub MCP Server works in Claude
Desktop, Cursor, VS Code, or your own app.

```
Before MCP                         After MCP
─────────────────────────────────  ─────────────────────────────────
App  →  custom GitHub connector    App  →  MCP Client  →  GitHub MCP Server
App  →  custom Jira connector      App  →  MCP Client  →  Jira MCP Server
App  →  custom DB connector        App  →  MCP Client  →  Postgres MCP Server
  (N integrations × M apps)          (N servers, any app, one protocol)
```

### Transport Types

| Transport | Use Case | Notes |
|-----------|----------|-------|
| **stdio** | Local servers (CLI tools, filesystem) | Simplest; server is a child process |
| **SSE** (Server-Sent Events) | Remote HTTP servers, streaming | One-directional push from server |
| **WebSocket** | Bidirectional remote servers | Full duplex; best for high-frequency calls |

### MCP vs Traditional Function Calling

| Aspect | OpenAI Function Calling | MCP |
|--------|------------------------|-----|
| Scope | Single LLM provider | Open standard, multi-provider |
| Reuse | Per-app re-definition | Define once, use anywhere |
| Data access | No built-in resource model | Resources primitive |
| Prompt templates | No built-in support | Prompts primitive |
| Discovery | Static schema in API call | Dynamic via list requests |
| Transport | HTTP only | stdio, SSE, WebSocket |

---

## 2. MCP Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  MCP Host (Claude Desktop / Cursor / your app)               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  MCP Client (embedded)                                 │  │
│  │  • Maintains 1-to-1 connection with each MCP server    │  │
│  │  • Translates LLM tool calls ↔ MCP protocol messages   │  │
│  └───────────────┬────────────────────────────────────────┘  │
└──────────────────┼───────────────────────────────────────────┘
                   │  JSON-RPC 2.0 over stdio / SSE / WebSocket
        ┌──────────┼──────────┬──────────────┐
        ▼          ▼          ▼              ▼
  ┌──────────┐ ┌────────┐ ┌───────┐  ┌────────────┐
  │ Filesystem│ │ GitHub │ │ Jira  │  │  Custom    │
  │ MCP Server│ │  MCP   │ │  MCP  │  │  MCP Server│
  └──────────┘ └────────┘ └───────┘  └────────────┘
```

### Message Types (JSON-RPC 2.0)

| Type | Direction | Example |
|------|-----------|---------|
| **Request** | Client → Server | `tools/call`, `resources/read` |
| **Response** | Server → Client | Result or error for a request |
| **Notification** | Either direction | `notifications/progress`, `notifications/log` |

### Lifecycle

```
1. Host spawns / connects to MCP Server
2. Client sends initialize request (protocol version, capabilities)
3. Server responds with its capabilities (tools, resources, prompts)
4. Client sends initialized notification
5. Normal operation: requests / responses / notifications
6. Either side sends shutdown
```

---

## 3. Three Primitives

### Tools (Executable Functions)

Tools are functions the LLM can call. Each tool has:
- `name` — unique identifier
- `description` — natural-language description used by the LLM to decide when to call it
- `inputSchema` — JSON Schema for arguments

```
tools/list response:
{
  "tools": [
    {
      "name": "read_file",
      "description": "Read the contents of a file at the given path",
      "inputSchema": {
        "type": "object",
        "properties": {
          "path": { "type": "string", "description": "File path to read" }
        },
        "required": ["path"]
      }
    }
  ]
}
```

Tool execution flow:
```
LLM decides to call read_file(path="/etc/hosts")
  → MCP Client sends tools/call request
    → MCP Server executes the function
      → Returns content result
        → LLM receives result and continues
```

### Resources (Readable Data)

Resources expose data the LLM can read. They use a `resource://` URI scheme.

```
resources/list response:
{
  "resources": [
    {
      "uri": "resource://project/README.md",
      "name": "README",
      "description": "Project readme file",
      "mimeType": "text/markdown"
    },
    {
      "uri": "resource://db/schema",
      "name": "Database Schema",
      "mimeType": "application/json"
    }
  ]
}
```

**Static resource** — fixed URI, fixed content (e.g., a config file).  
**Dynamic resource** — URI template with parameters (e.g., `resource://repo/{owner}/{repo}`).

### Prompts (Reusable Templates)

Prompts are server-defined message templates the host can offer to users.

```
prompts/list response:
{
  "prompts": [
    {
      "name": "code_review",
      "description": "Review a pull request for quality issues",
      "arguments": [
        { "name": "diff", "description": "Git diff text", "required": true },
        { "name": "language", "description": "Programming language", "required": false }
      ]
    }
  ]
}
```

GetPrompt request → server returns fully-expanded messages array ready to send to LLM.

---

## 4. Building an MCP Server (Python)

```bash
pip install mcp
```

```python
# mcp_server.py — Full MCP server: filesystem + git + code analysis tools
import asyncio
import os
import subprocess
from pathlib import Path

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

app = Server("dev-tools-server")


# ─────────────────────────────────────────────
# TOOLS
# ─────────────────────────────────────────────

@app.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="read_file",
            description="Read the text content of a file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Absolute or relative file path"}
                },
                "required": ["path"],
            },
        ),
        types.Tool(
            name="list_directory",
            description="List files and directories at a given path",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Directory path"},
                    "recursive": {"type": "boolean", "default": False},
                },
                "required": ["path"],
            },
        ),
        types.Tool(
            name="git_log",
            description="Return last N git commits for the repo at the given path",
            inputSchema={
                "type": "object",
                "properties": {
                    "repo_path": {"type": "string"},
                    "n": {"type": "integer", "default": 10},
                },
                "required": ["repo_path"],
            },
        ),
        types.Tool(
            name="git_diff",
            description="Return git diff for the repo (staged or unstaged)",
            inputSchema={
                "type": "object",
                "properties": {
                    "repo_path": {"type": "string"},
                    "staged": {"type": "boolean", "default": False},
                },
                "required": ["repo_path"],
            },
        ),
        types.Tool(
            name="count_lines",
            description="Count lines of code in a file or directory (by extension)",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "extension": {"type": "string", "description": "e.g. .py", "default": ""},
                },
                "required": ["path"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "read_file":
        content = Path(arguments["path"]).read_text(encoding="utf-8", errors="replace")
        return [types.TextContent(type="text", text=content)]

    if name == "list_directory":
        p = Path(arguments["path"])
        recursive = arguments.get("recursive", False)
        if recursive:
            entries = [str(f) for f in p.rglob("*")]
        else:
            entries = [f.name for f in p.iterdir()]
        return [types.TextContent(type="text", text="\n".join(entries))]

    if name == "git_log":
        n = arguments.get("n", 10)
        result = subprocess.run(
            ["git", "log", f"--max-count={n}", "--oneline"],
            cwd=arguments["repo_path"],
            capture_output=True,
            text=True,
        )
        return [types.TextContent(type="text", text=result.stdout or result.stderr)]

    if name == "git_diff":
        cmd = ["git", "diff"]
        if arguments.get("staged", False):
            cmd.append("--cached")
        result = subprocess.run(
            cmd, cwd=arguments["repo_path"], capture_output=True, text=True
        )
        return [types.TextContent(type="text", text=result.stdout or "(no diff)")]

    if name == "count_lines":
        p = Path(arguments["path"])
        ext = arguments.get("extension", "")
        files = [p] if p.is_file() else list(p.rglob(f"*{ext}") if ext else p.rglob("*"))
        total = sum(
            len(f.read_text(encoding="utf-8", errors="replace").splitlines())
            for f in files
            if f.is_file()
        )
        return [types.TextContent(type="text", text=f"Total lines: {total}")]

    raise ValueError(f"Unknown tool: {name}")


# ─────────────────────────────────────────────
# RESOURCES
# ─────────────────────────────────────────────

@app.list_resources()
async def list_resources() -> list[types.Resource]:
    return [
        types.Resource(
            uri="resource://project/structure",
            name="Project Structure",
            description="Top-level directory listing of the current working directory",
            mimeType="text/plain",
        ),
        types.Resource(
            uri="resource://project/git-status",
            name="Git Status",
            description="Output of git status in the current directory",
            mimeType="text/plain",
        ),
    ]


@app.read_resource()
async def read_resource(uri: str) -> str:
    if uri == "resource://project/structure":
        entries = [p.name for p in Path(".").iterdir()]
        return "\n".join(entries)
    if uri == "resource://project/git-status":
        result = subprocess.run(["git", "status"], capture_output=True, text=True)
        return result.stdout
    raise ValueError(f"Unknown resource: {uri}")


# ─────────────────────────────────────────────
# PROMPTS
# ─────────────────────────────────────────────

@app.list_prompts()
async def list_prompts() -> list[types.Prompt]:
    return [
        types.Prompt(
            name="code_review",
            description="Review a code diff for bugs, style, and security issues",
            arguments=[
                types.PromptArgument(name="diff", description="Git diff text", required=True),
                types.PromptArgument(name="language", description="Language name", required=False),
            ],
        ),
    ]


@app.get_prompt()
async def get_prompt(name: str, arguments: dict) -> types.GetPromptResult:
    if name == "code_review":
        diff = arguments.get("diff", "")
        lang = arguments.get("language", "the code")
        return types.GetPromptResult(
            description="Code review prompt",
            messages=[
                types.PromptMessage(
                    role="user",
                    content=types.TextContent(
                        type="text",
                        text=(
                            f"Please review the following {lang} diff.\n"
                            "Identify bugs, security issues, and improvement suggestions.\n\n"
                            f"```diff\n{diff}\n```"
                        ),
                    ),
                )
            ],
        )
    raise ValueError(f"Unknown prompt: {name}")


# ─────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
```

Run the server standalone (stdio):
```bash
python mcp_server.py
```

---

## 5. Building an MCP Client (Python)

```python
# mcp_client.py — Full client connecting to the server from Section 4
import asyncio
from mcp import ClientSession
from mcp.client.stdio import stdio_client
from mcp import StdioServerParameters

SERVER_PARAMS = StdioServerParameters(
    command="python",
    args=["mcp_server.py"],   # path to your server script
    env=None,
)


async def main():
    async with stdio_client(SERVER_PARAMS) as (read, write):
        async with ClientSession(read, write) as session:
            # ── 1. Initialize ──────────────────────────────────────────
            await session.initialize()
            print("Connected to MCP server\n")

            # ── 2. List tools ──────────────────────────────────────────
            tools_result = await session.list_tools()
            print("=== Available Tools ===")
            for tool in tools_result.tools:
                print(f"  • {tool.name}: {tool.description}")

            # ── 3. Call a tool ─────────────────────────────────────────
            print("\n=== Calling list_directory ===")
            result = await session.call_tool("list_directory", {"path": "."})
            for content in result.content:
                print(content.text[:500])   # truncate for demo

            # ── 4. Call git_log tool ───────────────────────────────────
            print("\n=== Calling git_log ===")
            try:
                result = await session.call_tool("git_log", {"repo_path": ".", "n": 5})
                for content in result.content:
                    print(content.text)
            except Exception as e:
                print(f"(git_log failed — not a git repo?) {e}")

            # ── 5. List resources ──────────────────────────────────────
            print("\n=== Available Resources ===")
            resources_result = await session.list_resources()
            for resource in resources_result.resources:
                print(f"  • {resource.uri}: {resource.name}")

            # ── 6. Read a resource ─────────────────────────────────────
            print("\n=== Reading resource://project/structure ===")
            resource_result = await session.read_resource("resource://project/structure")
            for content in resource_result.contents:
                print(content.text[:300])

            # ── 7. List prompts ────────────────────────────────────────
            print("\n=== Available Prompts ===")
            prompts_result = await session.list_prompts()
            for prompt in prompts_result.prompts:
                print(f"  • {prompt.name}: {prompt.description}")

            # ── 8. Get a prompt ────────────────────────────────────────
            print("\n=== Getting code_review prompt ===")
            prompt_result = await session.get_prompt(
                "code_review",
                {"diff": "+def hello():\n+    print('hi')", "language": "Python"},
            )
            for msg in prompt_result.messages:
                print(msg.content.text[:400])


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 6. MCP with FastMCP

FastMCP offers a higher-level, decorator-first API and built-in HTTP/SSE transport.

```bash
pip install fastmcp
```

```python
# fastmcp_server.py — Simplified MCP server using FastMCP
from fastmcp import FastMCP
import subprocess
from pathlib import Path

mcp = FastMCP(
    name="FastDev Server",
    instructions="A developer assistant with file, git, and web tools.",
)


@mcp.tool()
def read_file(path: str) -> str:
    """Read the text content of a local file."""
    return Path(path).read_text(encoding="utf-8", errors="replace")


@mcp.tool()
def write_file(path: str, content: str) -> str:
    """Write content to a local file, creating it if necessary."""
    Path(path).write_text(content, encoding="utf-8")
    return f"Written {len(content)} bytes to {path}"


@mcp.tool()
def run_shell(command: str, cwd: str = ".") -> str:
    """Run a shell command and return stdout + stderr (max 4 KB)."""
    result = subprocess.run(
        command, shell=True, cwd=cwd, capture_output=True, text=True, timeout=30
    )
    output = result.stdout + result.stderr
    return output[:4096]


@mcp.resource("resource://config/{filename}")
def get_config(filename: str) -> str:
    """Return the content of a config file by name."""
    config_dir = Path("config")
    target = config_dir / filename
    if not target.exists():
        return f"Config file {filename} not found"
    return target.read_text()


@mcp.prompt()
def explain_error(error_message: str, language: str = "Python") -> str:
    """Build a prompt asking the LLM to explain an error."""
    return (
        f"Explain the following {language} error and suggest a fix:\n\n"
        f"```\n{error_message}\n```"
    )


# ── Run with HTTP/SSE (default port 8000) ──
# fastmcp run fastmcp_server.py
# OR programmatically:
if __name__ == "__main__":
    mcp.run(transport="stdio")   # switch to "sse" for HTTP
```

Connect a FastMCP client over SSE:
```python
# fastmcp_client.py
import asyncio
from fastmcp import Client

async def main():
    async with Client("http://localhost:8000/sse") as client:
        tools = await client.list_tools()
        print([t.name for t in tools])

        result = await client.call_tool("read_file", {"path": "README.md"})
        print(result[0].text[:500])

asyncio.run(main())
```

---

## 7. Popular MCP Servers

### GitHub MCP Server
```bash
npx @modelcontextprotocol/server-github
```
Capabilities: list repos, read files, create/merge PRs, open issues, search code.

### Filesystem MCP Server
```bash
npx @modelcontextprotocol/server-filesystem /allowed/path
```
Capabilities: read, write, list, move files within the allowed path.

### Slack MCP Server
```bash
npx @modelcontextprotocol/server-slack
```
Capabilities: list channels, post messages, read thread history.

### Jira MCP Server (Atlassian)
```bash
npx @atlassian/mcp-atlassian
```
Capabilities: search issues (JQL), create/update issues, list projects, add comments.

### Draw.io MCP Server
```bash
pip install drawio-mcp
```
Capabilities: create/edit diagrams, export to PNG/SVG, read existing `.drawio` files.

### Figma MCP Server
```bash
npx figma-mcp
```
Capabilities: read Figma files, list pages/frames, export assets.

### Postgres MCP Server
```bash
npx @modelcontextprotocol/server-postgres postgresql://user:pass@host/db
```
Capabilities: run read-only SQL queries, list tables and schemas.

### Claude Desktop Configuration

```json
// ~/Library/Application Support/Claude/claude_desktop_config.json  (macOS)
// %APPDATA%\Claude\claude_desktop_config.json  (Windows)
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/projects"],
      "env": {}
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..." }
    },
    "jira": {
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://myorg.atlassian.net",
        "JIRA_EMAIL": "me@example.com",
        "JIRA_API_TOKEN": "..."
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://user:pass@localhost/mydb"]
    }
  }
}
```

### Cursor Configuration (`~/.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..." }
    }
  }
}
```

---

## 8. MCP with LangChain

```bash
pip install langchain-mcp-adapters langchain-openai langgraph
```

```python
# langchain_mcp_agent.py — LangChain ReAct agent with GitHub MCP tools
import asyncio
from mcp import StdioServerParameters
from langchain_mcp_adapters.tools import load_mcp_tools
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

GITHUB_SERVER = StdioServerParameters(
    command="npx",
    args=["-y", "@modelcontextprotocol/server-github"],
    env={"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"},
)


async def main():
    # Load all tools exposed by the GitHub MCP server
    tools = await load_mcp_tools(GITHUB_SERVER)
    print(f"Loaded {len(tools)} MCP tools: {[t.name for t in tools]}\n")

    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
    agent = create_react_agent(llm, tools)

    # Run the agent
    response = await agent.ainvoke({
        "messages": [{
            "role": "user",
            "content": (
                "List the 3 most recently updated open issues in "
                "the modelcontextprotocol/servers repository on GitHub."
            ),
        }]
    })

    print("Agent response:")
    print(response["messages"][-1].content)


if __name__ == "__main__":
    asyncio.run(main())
```

### MCPToolkit (multi-server)

```python
# langchain_mcp_toolkit.py — Load tools from multiple MCP servers
import asyncio
from mcp import StdioServerParameters
from langchain_mcp_adapters.tools import load_mcp_tools
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

async def build_agent_with_multiple_servers():
    github_params = StdioServerParameters(
        command="npx",
        args=["-y", "@modelcontextprotocol/server-github"],
        env={"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."},
    )
    fs_params = StdioServerParameters(
        command="npx",
        args=["-y", "@modelcontextprotocol/server-filesystem", "."],
    )

    github_tools = await load_mcp_tools(github_params)
    fs_tools     = await load_mcp_tools(fs_params)
    all_tools    = github_tools + fs_tools

    llm   = ChatOpenAI(model="gpt-4o")
    agent = create_react_agent(llm, all_tools)
    return agent
```

---

## 9. MCP with LangGraph

```python
# langgraph_mcp_agent.py — LangGraph agent with filesystem + git MCP tools
import asyncio
from typing import Annotated
from typing_extensions import TypedDict

from mcp import StdioServerParameters
from langchain_mcp_adapters.tools import load_mcp_tools
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode

DEV_SERVER = StdioServerParameters(
    command="python",
    args=["mcp_server.py"],   # the server from Section 4
)


class AgentState(TypedDict):
    messages: Annotated[list, add_messages]


async def build_graph():
    tools = await load_mcp_tools(DEV_SERVER)
    llm   = ChatOpenAI(model="gpt-4o-mini").bind_tools(tools)

    def call_model(state: AgentState):
        response = llm.invoke(state["messages"])
        return {"messages": [response]}

    def should_continue(state: AgentState):
        last = state["messages"][-1]
        return "tools" if last.tool_calls else END

    tool_node = ToolNode(tools)

    graph = StateGraph(AgentState)
    graph.add_node("agent", call_model)
    graph.add_node("tools", tool_node)
    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", should_continue, {"tools": "tools", END: END})
    graph.add_edge("tools", "agent")

    return graph.compile()


async def main():
    agent = await build_graph()
    result = await agent.ainvoke({
        "messages": [{"role": "user", "content": "List all Python files in the current directory."}]
    })
    print(result["messages"][-1].content)


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 10. MCP Security

### Trust Model

```
Host process (Claude Desktop) ──owns──▶ MCP Client
MCP Client                    ──trusts──▶ MCP Server (within configured limits)
MCP Server                    ──must not──▶ escape allowed paths / execute arbitrary code
```

- MCP servers run as separate processes — they do **not** have access to the LLM context.
- The host is responsible for presenting server capabilities to the user before granting consent.
- Users approve which servers the host may connect to (same model as browser extensions).

### Input Sanitization

```python
# ✅ Safe: validate and restrict paths before file operations
import os
from pathlib import Path

ALLOWED_ROOT = Path("/home/user/projects").resolve()

def safe_read(path: str) -> str:
    target = (ALLOWED_ROOT / path).resolve()
    # Prevent path traversal attacks
    if not str(target).startswith(str(ALLOWED_ROOT)):
        raise PermissionError(f"Access denied: {path}")
    return target.read_text()
```

### Resource Access Control

```python
# Per-resource ACL on MCP server
RESOURCE_PERMISSIONS = {
    "resource://project/secrets": {"roles": ["admin"]},
    "resource://project/readme":  {"roles": ["admin", "user"]},
}

def check_access(uri: str, user_role: str) -> bool:
    perms = RESOURCE_PERMISSIONS.get(uri, {"roles": ["admin", "user"]})
    return user_role in perms["roles"]
```

### Authentication Patterns

```python
# Bearer token authentication for HTTP/SSE MCP servers (FastMCP)
from fastmcp import FastMCP
from fastmcp.server.auth import BearerAuthProvider

auth = BearerAuthProvider(
    public_key="-----BEGIN PUBLIC KEY-----\n...",
    issuer="https://auth.example.com",
    audience="mcp-server",
)
mcp = FastMCP(name="Secure Server", auth=auth)
```

### Security Checklist

| Check | Detail |
|-------|--------|
| Path traversal | Resolve and validate all file paths against an allowed root |
| Command injection | Never pass raw user input to `shell=True` subprocess calls |
| Secret management | Load tokens from env vars, never hard-code |
| Rate limiting | Limit tool calls per session to prevent abuse |
| Principle of least privilege | MCP server process runs as unprivileged user |
| Audit logging | Log every tool call with inputs for forensics |

---

# Part B — ACP (Agent Communication Protocol)

---

## 11. What is ACP?

**ACP (Agent Communication Protocol)** is an open REST-based protocol developed by IBM (BeeAI
project) for agent-to-agent communication. While MCP solves the tool connectivity problem,
ACP solves the **agent interoperability problem**: how do independently-built agents call each
other regardless of framework (LangGraph, CrewAI, AutoGen, custom)?

### ACP vs MCP

| Aspect | MCP | ACP |
|--------|-----|-----|
| Target | LLM ↔ Tools/Data | Agent ↔ Agent |
| By | Anthropic | IBM / BeeAI |
| Interface | JSON-RPC | REST (HTTP) |
| State | Stateless calls | Stateful Runs with lifecycle |
| Discovery | MCP server list | Agent registry |
| Streaming | Notifications | SSE streaming on Run |
| Best for | Tool connectivity | Multi-agent orchestration |

### ACP Specification Overview

ACP defines:
1. **Agent Registry** — discover available agents and their input/output schemas.
2. **Run lifecycle** — create, execute, poll, cancel, and stream runs.
3. **Message format** — parts-based messages (text, file, data).
4. **REST endpoints** — standardized paths every ACP server must implement.

---

## 12. ACP Core Concepts

### Agent Registration and Discovery

Each ACP server exposes `GET /agents` returning a list of agent manifests:

```json
{
  "agents": [
    {
      "name": "code-reviewer",
      "description": "Reviews code diffs for bugs and style issues",
      "metadata": { "framework": "langgraph", "version": "1.0.0" },
      "input_content_types":  ["text/plain"],
      "output_content_types": ["text/plain"]
    }
  ]
}
```

### Run Lifecycle

```
POST /runs           → Create a new run (returns run_id, status=created)
  ↓
  Agent executes
  ↓
GET  /runs/{run_id}  → Poll status: created | in_progress | completed | failed
  ↓
GET  /runs/{run_id}/output  → Retrieve final output (when completed)
```

### Synchronous vs Asynchronous Runs

- **Sync** (`await=true` query param or `POST /runs/sync`): blocks until complete, returns output directly.
- **Async** (default): returns immediately with `run_id`; client polls or streams.

### Message Format — Parts

```json
{
  "messages": [
    {
      "parts": [
        { "content_type": "text/plain", "content": "Review this code" },
        { "content_type": "text/plain", "content": "def foo():\n    pass" }
      ]
    }
  ]
}
```

Supported part types: `text/plain`, `application/json`, `image/*`, any MIME type.

---

## 13. Building an ACP Agent (Python)

```bash
pip install acp-sdk
```

```python
# acp_agent.py — Document summarizer ACP agent
import asyncio
from collections.abc import AsyncGenerator

from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server

app = Server()


@app.agent()
async def summarizer(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """
    Summarize a document passed in the first message part.
    Yields progress updates then the final summary.
    """
    # Extract the text from the first message
    text = ""
    for message in input:
        for part in message.parts:
            if hasattr(part, "content"):
                text += str(part.content) + "\n"

    yield RunYield(
        message=Message(parts=[MessagePart(content="Analyzing document...", content_type="text/plain")])
    )
    await asyncio.sleep(0.1)   # simulate work

    # Simple extractive summary: first 3 sentences
    sentences = [s.strip() for s in text.replace("\n", " ").split(".") if s.strip()]
    summary = ". ".join(sentences[:3]) + ("." if sentences else "")

    yield RunYield(
        message=Message(parts=[
            MessagePart(content=f"Summary:\n{summary}", content_type="text/plain")
        ])
    )


@app.agent()
async def code_reviewer(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """
    Review a code diff. Expects the diff text in the first message part.
    Streams feedback line by line.
    """
    diff_text = ""
    for message in input:
        for part in message.parts:
            if hasattr(part, "content"):
                diff_text += str(part.content)

    feedback_items = [
        "✅ Code structure looks clean.",
        "⚠️  Check for missing error handling on I/O operations.",
        "⚠️  Variable names could be more descriptive.",
        "✅ No obvious security vulnerabilities found.",
        "💡 Consider adding docstrings to public functions.",
    ]

    for item in feedback_items:
        yield RunYield(
            message=Message(parts=[MessagePart(content=item, content_type="text/plain")])
        )
        await asyncio.sleep(0.05)


# Run:  python acp_agent.py
# Starts HTTP server on http://localhost:8001 by default
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001)
```

---

## 14. ACP Client — Calling Agents

```python
# acp_client.py — Full client demonstrating sync, async, and streaming calls
import asyncio
from acp_sdk.client import Client
from acp_sdk.models import Message, MessagePart


async def demo_sync_call(client: Client) -> None:
    """Call an ACP agent synchronously (blocks until done)."""
    print("=== Synchronous run ===")
    run = await client.run_sync(
        agent="summarizer",
        input=[
            Message(parts=[
                MessagePart(
                    content=(
                        "Artificial intelligence is transforming software development. "
                        "Developers now use AI tools for code completion and review. "
                        "Automated testing and deployment are becoming AI-driven. "
                        "Security scanning is enhanced by machine learning models. "
                        "The future of engineering is human-AI collaboration."
                    ),
                    content_type="text/plain",
                )
            ])
        ],
    )
    for message in run.output:
        for part in message.parts:
            print(part.content)


async def demo_async_poll(client: Client) -> None:
    """Create a run then poll until completed."""
    print("\n=== Async run with polling ===")
    run = await client.run_async(
        agent="code_reviewer",
        input=[
            Message(parts=[
                MessagePart(
                    content="+def process(data):\n+    return data.strip()",
                    content_type="text/plain",
                )
            ])
        ],
    )
    print(f"Run created: {run.run_id}  status={run.status}")

    # Poll until complete
    completed_run = await client.run_async_await(run.run_id)
    for message in completed_run.output:
        for part in message.parts:
            print(part.content)


async def demo_streaming(client: Client) -> None:
    """Stream run output as it is produced."""
    print("\n=== Streaming run ===")
    async for event in client.run_stream(
        agent="code_reviewer",
        input=[
            Message(parts=[
                MessagePart(content="+x=1\n+print(x)", content_type="text/plain")
            ])
        ],
    ):
        # Each event is a RunYield with a partial message
        if hasattr(event, "message") and event.message:
            for part in event.message.parts:
                print(f"  [stream] {part.content}")


async def main():
    async with Client(base_url="http://localhost:8001") as client:
        # List available agents
        agents = await client.list_agents()
        print("Available agents:", [a.name for a in agents.agents])
        print()

        await demo_sync_call(client)
        await demo_async_poll(client)
        await demo_streaming(client)


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 15. Multi-Agent ACP Orchestration

### Orchestrator → Worker Pattern

```python
# acp_orchestrator.py — Orchestrator agent that delegates to worker agents
import asyncio
from collections.abc import AsyncGenerator

from acp_sdk.client import Client
from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server

app = Server()

# Addresses of worker ACP servers
WORKER_CODE_REVIEWER = "http://localhost:8001"
WORKER_DOC_WRITER    = "http://localhost:8002"


@app.agent()
async def orchestrator(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """
    Orchestrates a full PR analysis:
    1. Sends the diff to the code-reviewer agent
    2. Sends the result to the doc-writer agent
    3. Returns a combined report
    """
    diff_text = input[0].parts[0].content if input else ""

    yield RunYield(
        message=Message(parts=[MessagePart(content="Step 1: Sending diff to code-reviewer...", content_type="text/plain")])
    )

    # ── Call Worker 1: code reviewer ─────────────────────────────────
    async with Client(base_url=WORKER_CODE_REVIEWER) as client:
        review_run = await client.run_sync(
            agent="code_reviewer",
            input=[Message(parts=[MessagePart(content=diff_text, content_type="text/plain")])],
        )
    review_text = "\n".join(
        part.content
        for msg in review_run.output
        for part in msg.parts
    )

    yield RunYield(
        message=Message(parts=[MessagePart(content=f"Review complete:\n{review_text}", content_type="text/plain")])
    )

    yield RunYield(
        message=Message(parts=[MessagePart(content="Step 2: Generating documentation suggestions...", content_type="text/plain")])
    )

    # ── Call Worker 2: doc writer ─────────────────────────────────────
    async with Client(base_url=WORKER_DOC_WRITER) as client:
        doc_run = await client.run_sync(
            agent="summarizer",
            input=[Message(parts=[MessagePart(content=review_text, content_type="text/plain")])],
        )
    doc_text = "\n".join(
        part.content
        for msg in doc_run.output
        for part in msg.parts
    )

    yield RunYield(
        message=Message(parts=[MessagePart(
            content=f"=== Final Report ===\n{review_text}\n\n=== Doc Summary ===\n{doc_text}",
            content_type="text/plain",
        )])
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8003)
```

### LangGraph Agent Wrapped as ACP Endpoint

```python
# langgraph_as_acp.py — Expose a LangGraph agent through ACP
import asyncio
from collections.abc import AsyncGenerator

from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

app = Server()

# Build LangGraph agent once at startup
_llm   = ChatOpenAI(model="gpt-4o-mini")
_agent = create_react_agent(_llm, tools=[])   # add tools as needed


@app.agent()
async def langgraph_qa(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """ACP endpoint wrapping a LangGraph ReAct agent."""
    user_text = input[0].parts[0].content if input else ""

    yield RunYield(
        message=Message(parts=[MessagePart(content="LangGraph agent thinking...", content_type="text/plain")])
    )

    result = await _agent.ainvoke({
        "messages": [{"role": "user", "content": user_text}]
    })
    answer = result["messages"][-1].content

    yield RunYield(
        message=Message(parts=[MessagePart(content=answer, content_type="text/plain")])
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8004)
```

### CrewAI Crew Wrapped as ACP Endpoint

```python
# crewai_as_acp.py — Expose a CrewAI crew through ACP
# pip install crewai acp-sdk
import asyncio
from collections.abc import AsyncGenerator

from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server
from crewai import Agent, Crew, Task

app = Server()


def run_crew(topic: str) -> str:
    researcher = Agent(
        role="Researcher",
        goal=f"Research {topic} and summarize findings",
        backstory="Expert technical researcher",
        verbose=False,
    )
    task = Task(
        description=f"Research {topic} and provide a concise technical summary.",
        expected_output="A 3-paragraph technical summary",
        agent=researcher,
    )
    crew = Crew(agents=[researcher], tasks=[task], verbose=False)
    return str(crew.kickoff())


@app.agent()
async def crew_researcher(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """ACP endpoint wrapping a CrewAI research crew."""
    topic = input[0].parts[0].content if input else "AI trends"

    yield RunYield(
        message=Message(parts=[MessagePart(content=f"CrewAI researching: {topic}...", content_type="text/plain")])
    )

    loop   = asyncio.get_event_loop()
    result = await loop.run_in_executor(None, run_crew, topic)

    yield RunYield(
        message=Message(parts=[MessagePart(content=result, content_type="text/plain")])
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8005)
```

---

## 16. MCP + ACP Together

### Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  ACP Orchestrator (REST :8003)                                       │
│  • Receives user request via ACP Run                                 │
│  • Routes to specialist ACP agents                                   │
└─────────────────┬────────────────────────────────────────────────────┘
                  │  ACP calls (HTTP REST)
     ┌────────────┼────────────┐
     ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│  ACP    │  │  ACP    │  │  ACP    │
│ Agent 1 │  │ Agent 2 │  │ Agent 3 │
│ (:8001) │  │ (:8002) │  │ (:8004) │
│LangGraph│  │LangGraph│  │ CrewAI  │
└────┬────┘  └────┬────┘  └─────────┘
     │             │
     │  MCP calls (stdio/SSE)
     ▼             ▼
┌─────────┐  ┌─────────┐
│ GitHub  │  │  File   │
│   MCP   │  │ System  │
│ Server  │  │   MCP   │
└─────────┘  └─────────┘
```

**Rule of thumb:**
- Use **MCP** when an agent needs to call a *tool* (read a file, query a database, call an API).
- Use **ACP** when you want an *agent* (with its own reasoning loop) to be callable by other agents.

### Full Pattern: ACP Orchestrator → LangGraph Sub-Agent → MCP Tools

```python
# mcp_acp_combined.py — ACP agent that uses MCP tools internally
import asyncio
from collections.abc import AsyncGenerator

from mcp import StdioServerParameters
from langchain_mcp_adapters.tools import load_mcp_tools
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server

app = Server()

GITHUB_MCP = StdioServerParameters(
    command="npx",
    args=["-y", "@modelcontextprotocol/server-github"],
    env={"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN"},
)


@app.agent()
async def github_analyst(
    input: list[Message],
    **kwargs,
) -> AsyncGenerator[RunYield, RunYieldResume]:
    """
    ACP agent that uses GitHub MCP tools via a LangGraph ReAct agent
    to answer questions about GitHub repositories.
    """
    query = input[0].parts[0].content if input else ""

    yield RunYield(
        message=Message(parts=[MessagePart(content="Loading GitHub MCP tools...", content_type="text/plain")])
    )

    tools = await load_mcp_tools(GITHUB_MCP)
    llm   = ChatOpenAI(model="gpt-4o-mini")
    agent = create_react_agent(llm, tools)

    yield RunYield(
        message=Message(parts=[MessagePart(content=f"Running agent for: {query}", content_type="text/plain")])
    )

    result = await agent.ainvoke({
        "messages": [{"role": "user", "content": query}]
    })
    answer = result["messages"][-1].content

    yield RunYield(
        message=Message(parts=[MessagePart(content=answer, content_type="text/plain")])
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8006)
```

---

## 17. Interview Q&A (20 Questions)

### MCP Questions

**Q: What is MCP and what problem does it solve?**
> MCP (Model Context Protocol) is Anthropic's open standard for connecting LLMs to external tools
> and data sources. It solves the M×N integration problem: before MCP, every AI app had to write
> custom connectors for every tool. With MCP, you write one MCP server per tool and it works with
> any MCP-compatible host.

**Q: What are the three MCP primitives?**
> 1. **Tools** — executable functions the LLM can call (e.g., `read_file`, `search_github`).
> 2. **Resources** — readable data exposed via `resource://` URIs (e.g., config files, DB schemas).
> 3. **Prompts** — reusable, parameterized message templates the host can surface to users.

**Q: What is the difference between MCP Tools and Resources?**
> Tools are **actions** (they execute code and produce dynamic results). Resources are **data**
> (they expose readable content, similar to a REST GET endpoint). The LLM calls tools when it
> needs to *do* something; it reads resources when it needs *information* that doesn't require
> computation.

**Q: What transport protocols does MCP support?**
> Three transports: **stdio** (server is a child process, best for local tools), **SSE** (HTTP
> Server-Sent Events, best for remote servers with streaming), and **WebSocket** (bidirectional,
> best for high-frequency or interactive use cases).

**Q: How do you build a custom MCP server in Python?**
> Install `mcp`, create a `Server` instance, decorate handlers with `@app.list_tools()`,
> `@app.call_tool()`, `@app.list_resources()`, `@app.read_resource()`, then run it with
> `stdio_server()`. See Section 4 for a full working example.

**Q: How do you use MCP tools inside a LangChain agent?**
> Use `langchain-mcp-adapters`: call `load_mcp_tools(StdioServerParameters(...))` to get a list
> of LangChain-compatible `Tool` objects, then pass them to `create_react_agent(llm, tools)`.
> The adapter handles the JSON-RPC ↔ LangChain tool interface translation automatically.

**Q: What is FastMCP?**
> FastMCP is a higher-level Python library built on top of the official `mcp` SDK. It offers a
> simpler decorator API (`@mcp.tool()`, `@mcp.resource()`, `@mcp.prompt()`), automatic type
> inference from function signatures, and built-in HTTP/SSE transport — reducing boilerplate
> significantly compared to raw `mcp`.

**Q: How does MCP compare to traditional OpenAI function calling?**
> OpenAI function calling is provider-specific, defined per API call, has no resource or prompt
> primitives, and cannot be reused across apps. MCP is an open standard, supports dynamic
> discovery, provides three primitives (tools/resources/prompts), works across providers, and
> allows a single server to serve multiple hosts simultaneously.

**Q: What popular MCP servers exist for SDLC tools?**
> GitHub (repos, PRs, issues), Filesystem (file read/write), Jira/Confluence (Atlassian), Slack
> (channels, messages), Postgres (SQL queries), Figma (design files), Draw.io (diagrams), and
> many more from the official `modelcontextprotocol/servers` registry on GitHub.

**Q: What are the security considerations for MCP?**
> Key concerns: path traversal (validate all file paths against an allowed root), command
> injection (never use `shell=True` with user input), secret management (env vars not hard-coded),
> rate limiting (cap tool calls per session), least privilege (run server as unprivileged user),
> and audit logging (log all tool calls with inputs).

---

### ACP Questions

**Q: What is ACP and how does it differ from MCP?**
> ACP (Agent Communication Protocol) is IBM's open REST-based protocol for **agent-to-agent**
> communication. MCP connects LLMs to *tools*; ACP connects *agents* to other agents. MCP uses
> JSON-RPC; ACP uses REST. MCP calls are stateless; ACP has a stateful Run lifecycle with
> create/execute/complete states.

**Q: What does a Run in ACP represent?**
> A Run is a single execution of an agent. It has a lifecycle: `created → in_progress →
> completed | failed`. Each run has a unique `run_id`, an input (list of Messages), and an
> output (list of Messages). Runs can be synchronous (blocking) or asynchronous (polled or
> streamed).

**Q: How do you stream output from an ACP agent?**
> Use `RunYield` inside an `async generator` agent function. Each `yield RunYield(message=...)`
> emits a partial result to the client. On the client side, use `client.run_stream(...)` which
> returns an `AsyncGenerator` of events, each containing a partial message.

**Q: How can one ACP agent call another ACP agent?**
> Instantiate an `acp_sdk.client.Client` pointing to the target agent's base URL and call
> `await client.run_sync(agent="name", input=[...])`. This is exactly how the orchestrator
> pattern works — one ACP server contains agent logic that internally calls other ACP servers.

**Q: How do you wrap a LangGraph agent as an ACP endpoint?**
> Create an ACP `Server`, define an `@app.agent()` async generator, inside it call
> `await langgraph_agent.ainvoke({"messages": [...]})`, then `yield RunYield(message=...)` with
> the result. The ACP server handles the HTTP layer; the LangGraph agent handles the reasoning.

**Q: What message types does ACP support?**
> ACP messages are composed of **parts**, each with a `content_type` (MIME type) and `content`.
> Supported types include `text/plain`, `application/json`, `image/png`, `image/jpeg`, and any
> other MIME type. This makes ACP suitable for multi-modal agent communication.

**Q: How does ACP enable framework-agnostic multi-agent systems?**
> Because ACP is a REST standard, any agent — regardless of whether it's built with LangGraph,
> CrewAI, AutoGen, or pure Python — exposes the same HTTP interface. An orchestrator only needs
> to know the base URL and agent name; it does not need to import or know the internal framework.

**Q: What is the ACP agent registry?**
> The registry is the `GET /agents` endpoint that every ACP server must implement. It returns a
> list of agent manifests (name, description, input/output content types). Orchestrators use
> this endpoint to discover what agents are available before routing requests to them.

**Q: How do you handle authentication in ACP?**
> ACP is built on HTTP, so standard HTTP authentication applies: Bearer tokens (JWT), API keys
> in headers (`X-API-Key`), or mutual TLS. Add authentication middleware to the underlying
> ASGI/WSGI server (e.g., FastAPI middleware) that the ACP SDK uses under the hood.

**Q: When would you use ACP vs LangGraph supervisor pattern?**
> Use **LangGraph supervisor** when all agents are in the same Python process, same team, and
> same codebase — it's simpler and has lower latency. Use **ACP** when agents are in *different
> services*, built by *different teams* or *different frameworks*, or need to be independently
> deployed and scaled. ACP is the inter-service protocol; LangGraph supervisor is the
> intra-process pattern.

---

## 18. Complete End-to-End Example

Full system: **MCP Server** (GitHub tools) + **ACP Agent** (code reviewer) + **ACP Orchestrator**

```python
# ═══════════════════════════════════════════════════════════════════════
# end_to_end.py — MCP + ACP full system in ~110 lines
#
# Architecture:
#   ACP Orchestrator (:8010)
#     └─▶ ACP Code Reviewer Agent (:8011)
#           └─▶ GitHub MCP Server (stdio, npx)
#
# Run order:
#   1. python end_to_end.py server   # starts ACP code reviewer on :8011
#   2. python end_to_end.py orch     # starts ACP orchestrator  on :8010
#   3. python end_to_end.py client   # calls the orchestrator
# ═══════════════════════════════════════════════════════════════════════
import asyncio
import sys
from collections.abc import AsyncGenerator

from acp_sdk.client import Client
from acp_sdk.models import Message, MessagePart
from acp_sdk.server import RunYield, RunYieldResume, Server

# ── Shared helpers ──────────────────────────────────────────────────────

def make_message(text: str) -> Message:
    return Message(parts=[MessagePart(content=text, content_type="text/plain")])

def extract_text(messages: list[Message]) -> str:
    return "\n".join(
        part.content for msg in messages for part in msg.parts
        if hasattr(part, "content")
    )


# ══════════════════════════════════════════════════════════════════════
# SERVICE 1: ACP Code Reviewer Agent (port 8011)
# Uses GitHub MCP tools via LangChain + LangGraph
# ══════════════════════════════════════════════════════════════════════

def run_reviewer_server():
    from mcp import StdioServerParameters
    from langchain_mcp_adapters.tools import load_mcp_tools
    from langchain_openai import ChatOpenAI
    from langgraph.prebuilt import create_react_agent

    reviewer_app = Server()

    GITHUB_MCP = StdioServerParameters(
        command="npx",
        args=["-y", "@modelcontextprotocol/server-github"],
        env={"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"},
    )

    @reviewer_app.agent()
    async def code_reviewer(
        input: list[Message], **kwargs
    ) -> AsyncGenerator[RunYield, RunYieldResume]:
        """Review code using GitHub MCP tools and a LangGraph ReAct agent."""
        query = extract_text(input)

        yield RunYield(message=make_message("Loading GitHub MCP tools..."))
        tools = await load_mcp_tools(GITHUB_MCP)

        yield RunYield(message=make_message(f"Running code review for: {query[:80]}..."))
        llm   = ChatOpenAI(model="gpt-4o-mini", temperature=0)
        agent = create_react_agent(llm, tools)
        result = await agent.ainvoke({"messages": [{"role": "user", "content": query}]})
        answer = result["messages"][-1].content

        yield RunYield(message=make_message(f"Review Result:\n{answer}"))

    reviewer_app.run(host="0.0.0.0", port=8011)


# ══════════════════════════════════════════════════════════════════════
# SERVICE 2: ACP Orchestrator (port 8010)
# Accepts a GitHub PR URL, calls the reviewer agent, returns full report
# ══════════════════════════════════════════════════════════════════════

def run_orchestrator_server():
    orch_app = Server()

    @orch_app.agent()
    async def pr_analysis_orchestrator(
        input: list[Message], **kwargs
    ) -> AsyncGenerator[RunYield, RunYieldResume]:
        """
        Orchestrate a full PR analysis pipeline:
          1. Extract PR info from user message
          2. Delegate to code_reviewer ACP agent
          3. Return final report
        """
        user_request = extract_text(input)
        yield RunYield(message=make_message(f"Orchestrator received: {user_request[:100]}"))

        # Build reviewer query
        reviewer_query = (
            f"Please review the following GitHub PR request and provide detailed feedback:\n"
            f"{user_request}\n\n"
            f"Focus on: code quality, potential bugs, security issues, and best practices."
        )

        yield RunYield(message=make_message("Delegating to code_reviewer agent..."))
        async with Client(base_url="http://localhost:8011") as client:
            review_run = await client.run_sync(
                agent="code_reviewer",
                input=[make_message(reviewer_query)],
            )
        review_text = extract_text(review_run.output)

        final_report = (
            "═══════════════════════════════════\n"
            "        PR ANALYSIS REPORT\n"
            "═══════════════════════════════════\n"
            f"{review_text}\n"
            "═══════════════════════════════════\n"
            "Analysis complete. Report generated by MCP + ACP pipeline."
        )
        yield RunYield(message=make_message(final_report))

    orch_app.run(host="0.0.0.0", port=8010)


# ══════════════════════════════════════════════════════════════════════
# CLIENT: Submit a PR for analysis
# ══════════════════════════════════════════════════════════════════════

async def run_client():
    pr_request = (
        "Review the latest open PR in modelcontextprotocol/python-sdk. "
        "Check for code quality issues, missing tests, and security concerns."
    )
    print(f"Submitting PR analysis request:\n{pr_request}\n")

    async with Client(base_url="http://localhost:8010") as client:
        agents = await client.list_agents()
        print(f"Orchestrator agents: {[a.name for a in agents.agents]}\n")

        print("=== Streaming orchestrator output ===")
        async for event in client.run_stream(
            agent="pr_analysis_orchestrator",
            input=[make_message(pr_request)],
        ):
            if hasattr(event, "message") and event.message:
                for part in event.message.parts:
                    print(f"  {part.content}")


# ══════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "client"
    if mode == "server":
        run_reviewer_server()
    elif mode == "orch":
        run_orchestrator_server()
    else:
        asyncio.run(run_client())
```

### Running the Full System

```bash
# Terminal 1 — Start the ACP code reviewer agent (uses GitHub MCP internally)
python end_to_end.py server

# Terminal 2 — Start the ACP orchestrator
python end_to_end.py orch

# Terminal 3 — Submit a PR for analysis
python end_to_end.py client
```

### Dependencies

```bash
pip install mcp fastmcp langchain-mcp-adapters langchain-openai langgraph acp-sdk crewai
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-filesystem
```

---

## Quick Reference Card

### MCP

| Task | Code |
|------|------|
| Install | `pip install mcp fastmcp` |
| Define tool | `@app.list_tools()` + `@app.call_tool()` |
| Define resource | `@app.list_resources()` + `@app.read_resource()` |
| FastMCP tool | `@mcp.tool()` on a plain function |
| LangChain adapter | `load_mcp_tools(StdioServerParameters(...))` |
| Run stdio server | `async with stdio_server() as (r,w): await app.run(r,w,...)` |
| Client connect | `async with stdio_client(params) as (r,w): ClientSession(r,w)` |

### ACP

| Task | Code |
|------|------|
| Install | `pip install acp-sdk` |
| Define agent | `@app.agent()` async generator |
| Yield output | `yield RunYield(message=Message(...))` |
| Sync client call | `await client.run_sync(agent="name", input=[...])` |
| Async client call | `await client.run_async(...)` then `await client.run_async_await(run_id)` |
| Stream output | `async for event in client.run_stream(...): ...` |
| List agents | `await client.list_agents()` |
| Start server | `app.run(host="0.0.0.0", port=8001)` |

---

*Guide covers MCP SDK v1.x · FastMCP v2.x · ACP SDK v0.x (BeeAI) · LangChain v0.3+ · LangGraph v0.2+*
