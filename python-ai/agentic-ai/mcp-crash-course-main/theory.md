# Model Context Protocol (MCP) — Comprehensive Theory Guide

## 1. What Is MCP and Why It Exists

The **Model Context Protocol (MCP)** is an open standard introduced by Anthropic in late 2024 to solve
a fundamental challenge in building LLM-powered applications: **how do AI models reliably and safely
interact with external tools, data sources, and services?**

Before MCP, every developer who wanted to give an LLM access to tools had to build custom integrations
from scratch — writing ad-hoc function-calling wrappers, managing prompt injection, handling retries,
and maintaining brittle one-off pipelines. The result was fragmented, hard to maintain, and impossible
to reuse across different AI frameworks.

MCP standardises this interaction by defining:
- A **protocol** (JSON-RPC 2.0 over configurable transports)
- A set of **primitives** (Tools, Resources, Prompts, Sampling)
- **Lifecycle rules** for how servers and clients negotiate capabilities

Think of MCP as the "USB standard for AI tools" — once a server implements MCP, any MCP-compatible
host (Claude Desktop, Cursor, a LangChain agent) can use it without bespoke glue code.

---

## 2. Core MCP Architecture

MCP uses a **three-layer architecture**:

`
┌─────────────────────────────────────────────────────┐
│                    HOST APPLICATION                  │
│  (Claude Desktop, Cursor IDE, LangChain Agent, etc.) │
│                                                      │
│  ┌──────────────┐      ┌──────────────┐              │
│  │  MCP Client  │      │  MCP Client  │  (one per    │
│  │  (Server A)  │      │  (Server B)  │   server)    │
│  └──────┬───────┘      └──────┬───────┘              │
└─────────┼────────────────────┼────────────────────────┘
          │ Transport           │ Transport
          ▼                     ▼
   ┌────────────┐        ┌────────────┐
   │  MCP       │        │  MCP       │
   │  Server A  │        │  Server B  │
   │ (filesystem│        │ (database) │
   └────────────┘        └────────────┘
`

### Host
The **Host** is the top-level application the user interacts with — Claude Desktop, Cursor IDE, or
a custom Python application. The host:
- Manages one or more MCP clients
- Decides which servers to connect to (via config files)
- Exposes server capabilities to the LLM at inference time
- Enforces security policies (user consent, sandboxing)

### Client
Each **MCP Client** is an in-process object inside the host. There is one client per server
connection. The client:
- Establishes and maintains the transport connection to a server
- Handles the MCP handshake (initialize / initialized)
- Routes requests from the host to the correct server
- Returns responses back to the host/LLM

### Server
An **MCP Server** is an independent process (or remote service) that exposes capabilities:
- It can be a local Python script, a Node.js process, a Docker container, or a remote HTTP service
- Implements the MCP specification (JSON-RPC message handling)
- Registers Tools, Resources, and/or Prompts
- Responds to requests from the client

---

## 3. Transport Types

MCP is **transport-agnostic** — the JSON-RPC messages can travel over different channels.

### 3.1 stdio Transport (Local / In-Process)

The most common transport for local development. The host **spawns a subprocess** for the server
and communicates over **stdin/stdout**.

`
Host Process
  └─ spawns ──► MCP Server Process
                  stdin  ◄── JSON-RPC requests
                  stdout ──► JSON-RPC responses
                  stderr ──► logs (ignored by protocol)
`

Advantages:
- Zero network setup; works offline
- Simple to configure (just a command + args)
- Process isolation — server crash doesn't kill host
- Works on Windows, macOS, Linux without firewall rules

Use when: building local tools, file system access, database access, running scripts.

### 3.2 SSE Transport (Remote / HTTP)

**Server-Sent Events (SSE)** transport uses HTTP for remote MCP servers.

`
MCP Client (HTTP)  ──POST /message──►  MCP Server (HTTP)
MCP Client (HTTP)  ◄──GET  /sse   ──   MCP Server (HTTP)
`

The client sends requests via HTTP POST and receives streaming responses via a persistent SSE
connection (GET /sse). This allows MCP servers to be deployed as web services accessible over a
network or the internet.

Advantages:
- Deployable to cloud (AWS, GCP, Azure, Fly.io, etc.)
- Accessible by multiple clients simultaneously
- Works through firewalls (standard HTTP/HTTPS)
- Enables shared, centralised MCP services for teams

Use when: building shared services, cloud deployment, multi-user access, remote APIs.

### 3.3 WebSocket Transport (Emerging)

Some implementations also support WebSocket for bidirectional streaming, though stdio and SSE
remain the primary transports in the Python SDK.

---

## 4. MCP Primitives

MCP defines four core primitives that servers can expose:

### 4.1 Tools

**Tools** are functions the LLM can invoke to perform actions or retrieve computed data.
They are the most commonly used primitive.

- Defined with a name, description, and JSON Schema for parameters
- The LLM decides when to call a tool based on the description
- The server executes the tool and returns a result
- Examples: search_web, xecute_sql, send_email, ead_file

Tools follow a request/response pattern — the LLM calls the tool, waits for the result,
then incorporates it into its response.

### 4.2 Resources

**Resources** expose data that the LLM can read — similar to GET endpoints in a REST API.
They are identified by a URI.

- URIs follow a scheme: ile:///path/to/doc, db://table/rows, pi://endpoint
- Resources can be static (files) or dynamic (live database queries, API responses)
- The LLM (or host) decides when to read a resource
- Unlike tools, resources are intended for data retrieval, not actions

Examples: ile:///home/user/notes.txt, sqlite:///mydb/users, github://repo/README.md

### 4.3 Prompts

**Prompts** are reusable, parameterised prompt templates stored on the server. They allow
server authors to define best-practice prompts that clients can discover and use.

- Defined with a name, description, and optional arguments
- The host can list available prompts and present them to the user
- Arguments can be filled in dynamically
- Useful for standardising how the LLM is instructed to use server capabilities

Examples: "Summarise this document", "Write SQL for this question", "Review this code"

### 4.4 Sampling

**Sampling** is a special primitive that allows an MCP server to ask the HOST to make an LLM
inference call on the server's behalf. This enables:

- Servers that use AI themselves (agentic servers)
- Human-in-the-loop workflows
- Servers that chain LLM calls

This is more advanced and less commonly used than Tools/Resources/Prompts.

---

## 5. The MCP Python SDK

The official Python SDK (mcp) provides two levels of API:

### 5.1 FastMCP (High-Level)

FastMCP is the recommended, decorator-based API for building MCP servers quickly.
It handles all protocol boilerplate automatically.

`python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("my-server")

@mcp.tool()
def my_tool(param: str) -> str:
    return f"Result: {param}"
`

FastMCP automatically:
- Extracts parameter names and types from the function signature
- Generates JSON Schema from type hints
- Uses the docstring as the tool description
- Handles serialisation and error wrapping

### 5.2 Low-Level SDK

The low-level SDK gives full control over protocol handling, useful for advanced use cases:

`python
from mcp.server import Server
from mcp.server.models import InitializationOptions
server = Server("my-server")
`

---

## 6. Server Lifecycle

Every MCP session follows this lifecycle:

`
Client                          Server
  │                               │
  │──── initialize ──────────────►│  (send client info + capabilities)
  │◄─── initialize result ────────│  (server info + capabilities)
  │──── initialized ─────────────►│  (notification: ready)
  │                               │
  │──── tools/list ──────────────►│  (request available tools)
  │◄─── tools/list result ────────│  (array of tool definitions)
  │                               │
  │──── tools/call ──────────────►│  (call a specific tool)
  │◄─── tools/call result ────────│  (tool execution result)
  │                               │
  │──── (session continues) ──────│
`

1. **initialize**: Client sends its protocol version and capabilities. Server responds with its
   version and what it supports (tools, resources, prompts, sampling).
2. **initialized**: Client confirms it's ready to proceed.
3. **list**: Client can request lists of available tools, resources, or prompts.
4. **call/read/get**: Client executes tools, reads resources, or retrieves prompts.

---

## 7. Building a stdio MCP Server

A minimal stdio server with FastMCP:

`python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def greet(name: str) -> str:
    """Greet a person by name."""
    return f"Hello, {name}!"

if __name__ == "__main__":
    mcp.run()  # default transport is stdio
`

Run with: python server.py

The mcp.run() call starts an event loop that reads JSON-RPC messages from stdin and writes
responses to stdout. The server blocks until the client disconnects.

---

## 8. Building an SSE MCP Server

For remote/HTTP deployment:

`python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("remote-server")

@mcp.tool()
def ping() -> str:
    """Check if server is alive."""
    return "pong"

if __name__ == "__main__":
    mcp.run(transport="sse", host="0.0.0.0", port=8000)
`

The server starts an HTTP server (built on Starlette/Uvicorn) with:
- GET /sse — SSE stream for the client to receive responses
- POST /message — endpoint for the client to send requests

---

## 9. MCP Client in Python

You can programmatically connect to an MCP server from Python:

`python
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def main():
    params = StdioServerParameters(command="python", args=["server.py"])
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            result = await session.call_tool("greet", {"name": "Alice"})
`

---

## 10. LangChain MCP Integration

LangChain provides langchain-mcp-adapters to bridge MCP servers and LangChain agents.

### MCPToolkit

`python
from langchain_mcp_adapters.tools import load_mcp_tools
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async with stdio_client(StdioServerParameters(command="python", args=["server.py"])) as (r, w):
    async with ClientSession(r, w) as session:
        await session.initialize()
        tools = await load_mcp_tools(session)
        # tools is a list of LangChain BaseTool objects
`

### Using with LangChain Agent

`python
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic

model = ChatAnthropic(model="claude-3-5-sonnet-20241022")
agent = create_react_agent(model, tools)
result = await agent.ainvoke({"messages": [{"role": "user", "content": "Use the tool"}]})
`

---

## 11. Claude Desktop Configuration

Claude Desktop reads MCP server configs from:
- **macOS**: ~/Library/Application Support/Claude/claude_desktop_config.json
- **Windows**: %APPDATA%\Claude\claude_desktop_config.json

### Config format:

`json
{
  "mcpServers": {
    "my-server": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
`

Each entry under mcpServers defines:
- **key**: the name shown in Claude's UI
- **command**: the executable to run
- **args**: command-line arguments (path to server script)
- **env**: optional environment variables injected into the server process

After editing the config, restart Claude Desktop to pick up changes.

---

## 12. Cursor IDE MCP Configuration

Cursor supports MCP via its settings. Add servers in .cursor/mcp.json (project-level) or
in Cursor's global settings UI.

`json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
    },
    "custom-server": {
      "command": "python",
      "args": ["mcp_server.py"]
    }
  }
}
`

Cursor automatically discovers tools from registered servers and makes them available
to the AI assistant during code generation and chat sessions.

---

## 13. Security Considerations

MCP introduces powerful capabilities, and with that comes responsibility:

### 13.1 Principle of Least Privilege
- Only expose tools and resources the server genuinely needs
- Restrict file system access to specific directories
- Use read-only database connections where writes aren't needed

### 13.2 Input Validation
- Always validate and sanitise tool inputs before using them
- Use parameterised queries for SQL, never string interpolation
- Validate file paths to prevent directory traversal attacks

### 13.3 Authentication
- For SSE servers, implement API key or Bearer token authentication
- Validate auth headers in every request handler
- Use HTTPS in production (never plain HTTP for sensitive data)

### 13.4 Rate Limiting
- Implement rate limiting on SSE servers to prevent abuse
- Log all tool invocations for auditing

### 13.5 Secrets Management
- Never hardcode API keys in server code
- Use environment variables (injected via the nv field in config)
- Consider using secret managers (AWS Secrets Manager, HashiCorp Vault)

### 13.6 Sandboxing
- Run MCP servers in Docker containers or VMs for isolation
- Use OS-level sandboxing (seccomp, AppArmor) for code execution servers
- Disable network access for file-only servers

---

## 14. Popular MCP Servers (Ecosystem)

The MCP ecosystem is growing rapidly. Notable official and community servers:

### Official Anthropic Servers
- **filesystem**: Read/write local files with configurable root directories
- **git**: Git repository operations (log, diff, blame, show)
- **sqlite**: Query and modify SQLite databases
- **fetch**: Fetch web URLs and convert HTML to Markdown
- **memory**: Persistent key-value memory across sessions
- **sequential-thinking**: Step-by-step reasoning tool

### Community Servers
- **browserbase**: Cloud browser automation
- **github**: GitHub API (repos, issues, PRs, code search)
- **postgres**: PostgreSQL database access
- **slack**: Slack workspace integration
- **google-maps**: Location search, directions, geocoding
- **brave-search**: Web search via Brave Search API
- **puppeteer**: Local browser automation
- **aws-kb-retrieval**: AWS Bedrock Knowledge Base queries
- **linear**: Linear project management integration
- **notion**: Notion workspace access

---

## 15. MCP vs Function Calling vs RAG

Understanding where MCP fits:

| Aspect          | Raw Function Calling | RAG                | MCP                        |
|-----------------|---------------------|---------------------|----------------------------|
| Standardisation | None (ad hoc)       | Varies by framework | Fully standardised protocol|
| Reusability     | Low (tightly coupled)| Medium             | High (any host can use it) |
| Transport       | In-process          | In-process          | stdio, SSE, WebSocket      |
| Discovery       | Manual              | Manual              | Automatic (list/*)         |
| Data vs Actions | Actions only        | Data retrieval      | Both (Tools + Resources)   |
| Ecosystem       | Fragmented          | Framework-specific  | Growing standard ecosystem |

MCP is best thought of as the **transport and discovery layer** on top of function calling —
it doesn't replace the LLM's tool-use capability, it standardises how tools are exposed and invoked.

---

## 16. Summary

MCP addresses the "integration tax" problem in AI development. Instead of building N×M custom
integrations (N models × M tools), developers build M MCP servers and N MCP hosts, and any
combination works automatically.

Key takeaways:
1. MCP = JSON-RPC 2.0 protocol for LLM ↔ tool communication
2. Architecture: Host → Client → Server (one client per server)
3. Transports: stdio (local subprocess) and SSE (remote HTTP)
4. Primitives: Tools (actions), Resources (data), Prompts (templates), Sampling (LLM calls)
5. Python SDK: FastMCP makes building servers fast and easy
6. Integrates with Claude Desktop, Cursor, LangChain, and more
7. Always consider security: validate inputs, authenticate SSE servers, least privilege

MCP is rapidly becoming the de facto standard for connecting LLMs to the external world.