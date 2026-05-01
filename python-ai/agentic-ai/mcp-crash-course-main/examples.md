# MCP Python Code Examples — Annotated Reference

## Example 1: Minimal FastMCP Server with One Tool

The simplest possible MCP server. One tool, one file.

```python
# minimal_server.py
from mcp.server.fastmcp import FastMCP

# Create a named MCP server instance
mcp = FastMCP("minimal-server")

@mcp.tool()
def say_hello(name: str) -> str:
    """Say hello to a person. Use this when greeted or asked to introduce."""
    return f"Hello, {name}! Welcome to MCP."

if __name__ == "__main__":
    # Run with stdio transport (default) — reads from stdin, writes to stdout
    mcp.run()
```

---

## Example 2: Math Server (add, subtract, multiply)

A server exposing multiple arithmetic tools.

```python
# math_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("math-server")

@mcp.tool()
def add(a: float, b: float) -> float:
    """Add two numbers together."""
    return a + b

@mcp.tool()
def subtract(a: float, b: float) -> float:
    """Subtract b from a."""
    return a - b

@mcp.tool()
def multiply(a: float, b: float) -> float:
    """Multiply two numbers."""
    return a * b

@mcp.tool()
def divide(a: float, b: float) -> float:
    """Divide a by b. Returns error if b is zero."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

if __name__ == "__main__":
    mcp.run()
```

---

## Example 3: Weather Tool (Mock API)

Simulates a weather API — replace with real HTTP call in production.

```python
# weather_server.py
from mcp.server.fastmcp import FastMCP
from typing import Optional

mcp = FastMCP("weather-server")

# Simulated weather data — in production, call openweathermap.org etc.
MOCK_WEATHER = {
    "london": {"temp_c": 15, "condition": "Cloudy", "humidity": 78},
    "new york": {"temp_c": 22, "condition": "Sunny", "humidity": 55},
    "tokyo": {"temp_c": 28, "condition": "Hot and humid", "humidity": 80},
}

@mcp.tool()
def get_weather(city: str, units: Optional[str] = "celsius") -> dict:
    """
    Get current weather for a city.
    
    Args:
        city: The city name (e.g., 'London', 'New York')
        units: Temperature units — 'celsius' or 'fahrenheit'
    
    Returns:
        Dictionary with temperature, condition, and humidity.
    """
    data = MOCK_WEATHER.get(city.lower())
    if not data:
        return {"error": f"No weather data for '{city}'"}
    
    temp = data["temp_c"]
    if units == "fahrenheit":
        temp = (temp * 9 / 5) + 32
    
    return {
        "city": city,
        "temperature": temp,
        "units": units,
        "condition": data["condition"],
        "humidity": data["humidity"],
    }

if __name__ == "__main__":
    mcp.run()
```

---

## Example 4: File Reader Tool

Safely read files within a permitted root directory.

```python
# file_reader_server.py
import os
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("file-reader")
ALLOWED_ROOT = os.path.expanduser("~/Documents/allowed")

@mcp.tool()
def read_file(path: str) -> str:
    """
    Read the contents of a text file.
    
    Args:
        path: Relative path inside the allowed root directory.
    
    Returns:
        File contents as a string.
    """
    # Security: resolve path and ensure it's within allowed root
    full_path = os.path.realpath(os.path.join(ALLOWED_ROOT, path))
    if not full_path.startswith(os.path.realpath(ALLOWED_ROOT)):
        raise PermissionError("Access denied: path is outside allowed root")
    
    if not os.path.isfile(full_path):
        raise FileNotFoundError(f"File not found: {path}")
    
    with open(full_path, "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    mcp.run()
```

---

## Example 5: File Writer Tool

Write content to files with path validation.

```python
# file_writer_server.py
import os
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("file-writer")
WRITE_ROOT = os.path.expanduser("~/Documents/output")
os.makedirs(WRITE_ROOT, exist_ok=True)

@mcp.tool()
def write_file(path: str, content: str, overwrite: bool = False) -> str:
    """
    Write text content to a file.
    
    Args:
        path: Relative file path within the output directory.
        content: Text content to write.
        overwrite: If False, raises error if file already exists.
    
    Returns:
        Confirmation message with file size.
    """
    full_path = os.path.realpath(os.path.join(WRITE_ROOT, path))
    if not full_path.startswith(os.path.realpath(WRITE_ROOT)):
        raise PermissionError("Path outside allowed write root")
    
    if os.path.exists(full_path) and not overwrite:
        raise FileExistsError(f"File already exists: {path}. Set overwrite=True to replace.")
    
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    return f"Written {len(content)} characters to {path}"

if __name__ == "__main__":
    mcp.run()
```

---

## Example 6: Directory Lister as a Resource

Expose directory listings as MCP Resources (URI-addressable data).

```python
# directory_resource_server.py
import os
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("directory-server")
BASE_DIR = os.path.expanduser("~/Documents")

@mcp.resource("dir://{path}")
def list_directory(path: str) -> str:
    """
    List files in a directory. Access via URI: dir://path/to/folder
    
    Returns a formatted directory listing as text.
    """
    full_path = os.path.join(BASE_DIR, path)
    if not os.path.isdir(full_path):
        return f"Not a directory: {path}"
    
    entries = os.listdir(full_path)
    lines = [f"Directory: {path}", f"Total: {len(entries)} items", "---"]
    for entry in sorted(entries):
        entry_path = os.path.join(full_path, entry)
        kind = "DIR " if os.path.isdir(entry_path) else "FILE"
        size = os.path.getsize(entry_path) if os.path.isfile(entry_path) else "-"
        lines.append(f"{kind}  {entry}  ({size} bytes)")
    
    return "\n".join(lines)

if __name__ == "__main__":
    mcp.run()
```

---

## Example 7: Database Query Resource

Expose SQLite database tables as readable resources.

```python
# database_resource_server.py
import sqlite3
import json
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("sqlite-server")
DB_PATH = "mydb.sqlite"

@mcp.resource("sqlite://table/{table_name}")
def read_table(table_name: str) -> str:
    """Read all rows from a SQLite table. URI: sqlite://table/users"""
    # Whitelist table names to prevent injection
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get column names
    cursor.execute(f"PRAGMA table_info({table_name})")  # noqa: S608
    cols = [row[1] for row in cursor.fetchall()]
    
    # Fetch rows
    cursor.execute(f"SELECT * FROM {table_name} LIMIT 100")  # noqa: S608
    rows = cursor.fetchall()
    conn.close()
    
    result = {"table": table_name, "columns": cols, "rows": rows, "count": len(rows)}
    return json.dumps(result, indent=2)

@mcp.tool()
def query_database(sql: str) -> str:
    """Execute a SELECT query on the database. Only SELECT statements allowed."""
    if not sql.strip().upper().startswith("SELECT"):
        raise ValueError("Only SELECT queries are permitted")
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    cols = [desc[0] for desc in cursor.description]
    conn.close()
    
    return json.dumps({"columns": cols, "rows": rows}, indent=2)

if __name__ == "__main__":
    mcp.run()
```

---

## Example 8: Reusable Prompt Template

Define a prompt template the host can retrieve and use.

```python
# prompt_server.py
from mcp.server.fastmcp import FastMCP
from mcp.types import PromptMessage, TextContent

mcp = FastMCP("prompt-server")

@mcp.prompt()
def code_review_prompt(code: str, language: str = "python") -> list[PromptMessage]:
    """
    Generate a thorough code review prompt for the given code snippet.
    
    Args:
        code: The source code to review.
        language: Programming language of the code.
    """
    return [
        PromptMessage(
            role="user",
            content=TextContent(
                type="text",
                text=f"""Please review the following {language} code thoroughly:

```{language}
{code}
```

Focus on:
1. Correctness and logic errors
2. Security vulnerabilities
3. Performance issues
4. Code style and readability
5. Missing error handling

Provide specific, actionable feedback."""
            )
        )
    ]

if __name__ == "__main__":
    mcp.run()
```

---

## Example 9: Server with Multiple Tool Categories

A comprehensive server combining multiple tool domains.

```python
# multi_tool_server.py
import os, json, datetime
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("multi-tool-server")

# --- System Tools ---
@mcp.tool()
def get_current_time(timezone: str = "UTC") -> str:
    """Get the current date and time."""
    return datetime.datetime.now().isoformat()

@mcp.tool()
def get_env_variable(name: str) -> str:
    """Read an environment variable by name."""
    val = os.environ.get(name)
    if val is None:
        raise KeyError(f"Environment variable '{name}' not set")
    return val

# --- Text Tools ---
@mcp.tool()
def count_words(text: str) -> dict:
    """Count words, characters, and lines in text."""
    return {
        "words": len(text.split()),
        "characters": len(text),
        "lines": len(text.splitlines()),
    }

@mcp.tool()
def format_json(json_string: str) -> str:
    """Pretty-print a JSON string with 2-space indentation."""
    parsed = json.loads(json_string)
    return json.dumps(parsed, indent=2)

if __name__ == "__main__":
    mcp.run()
```

---

## Example 10: stdio Transport Server (Explicit)

Showing explicit stdio configuration for clarity.

```python
# stdio_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("stdio-demo", description="Explicit stdio transport demo")

@mcp.tool()
def echo(message: str) -> str:
    """Echo a message back. Used to test connectivity."""
    return f"Echo: {message}"

if __name__ == "__main__":
    # transport="stdio" is the default but shown explicitly for clarity
    # Communicates via process stdin/stdout — used when launched by a host
    mcp.run(transport="stdio")
```

---

## Example 11: SSE Transport Server

Run MCP server as an HTTP service using Server-Sent Events.

```python
# sse_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("sse-demo", description="Remote SSE transport server")

@mcp.tool()
def get_server_info() -> dict:
    """Return info about this MCP server."""
    return {
        "name": "sse-demo",
        "transport": "sse",
        "version": "1.0.0",
        "status": "running",
    }

@mcp.tool()
def reverse_string(text: str) -> str:
    """Reverse a string character by character."""
    return text[::-1]

if __name__ == "__main__":
    # Starts HTTP server on port 8000
    # Client connects to: http://localhost:8000/sse
    mcp.run(transport="sse", host="0.0.0.0", port=8000)
```

---

## Example 12: MCP Client Connecting to stdio Server

Connect programmatically to a stdio MCP server.

```python
# client_connect.py
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def connect_to_server():
    # Define how to launch the server process
    server_params = StdioServerParameters(
        command="python",
        args=["math_server.py"],
        env=None  # inherit parent environment
    )
    
    # stdio_client context manager spawns the process and manages streams
    async with stdio_client(server_params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            # Perform MCP handshake
            await session.initialize()
            print("Connected to server!")
            return session  # use within context

asyncio.run(connect_to_server())
```

---

## Example 13: MCP Client Listing Tools

Discover available tools from a connected server.

```python
# client_list_tools.py
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def list_server_tools():
    params = StdioServerParameters(command="python", args=["math_server.py"])
    
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # List all available tools
            tools_response = await session.list_tools()
            
            print(f"Found {len(tools_response.tools)} tools:")
            for tool in tools_response.tools:
                print(f"  - {tool.name}: {tool.description}")
                if tool.inputSchema:
                    props = tool.inputSchema.get("properties", {})
                    for param, schema in props.items():
                        print(f"      param: {param} ({schema.get('type', 'any')})")

asyncio.run(list_server_tools())
```

---

## Example 14: MCP Client Calling a Tool

Invoke a specific tool and handle the result.

```python
# client_call_tool.py
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def call_tool_example():
    params = StdioServerParameters(command="python", args=["math_server.py"])
    
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Call the 'add' tool with arguments
            result = await session.call_tool(
                name="add",
                arguments={"a": 42.0, "b": 58.0}
            )
            
            # Result contains a list of content blocks
            for content in result.content:
                if content.type == "text":
                    print(f"Result: {content.text}")
            
            # Check for errors
            if result.isError:
                print("Tool returned an error!")

asyncio.run(call_tool_example())
```

---

## Example 15: LangChain MCPToolkit Integration

Load MCP tools as LangChain-compatible tool objects.

```python
# langchain_toolkit.py
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from langchain_mcp_adapters.tools import load_mcp_tools

async def get_langchain_tools():
    params = StdioServerParameters(command="python", args=["math_server.py"])
    
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Convert MCP tools to LangChain BaseTool objects
            tools = await load_mcp_tools(session)
            
            for tool in tools:
                print(f"LangChain tool: {tool.name}")
                print(f"  Description: {tool.description}")
                print(f"  Args schema: {tool.args_schema.schema()}")
            
            return tools

asyncio.run(get_langchain_tools())
```

---

## Example 16: Using MCP Tools with a LangChain ReAct Agent

Wire MCP tools into a full LangChain agent loop.

```python
# langchain_agent.py
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from langchain_mcp_adapters.tools import load_mcp_tools
from langchain_anthropic import ChatAnthropic
from langgraph.prebuilt import create_react_agent

async def run_agent_with_mcp():
    params = StdioServerParameters(command="python", args=["math_server.py"])
    
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await load_mcp_tools(session)
    
    # Create the LLM (Claude)
    model = ChatAnthropic(model="claude-3-5-sonnet-20241022")
    
    # Create a ReAct agent with the MCP tools
    agent = create_react_agent(model, tools)
    
    # Run the agent
    response = await agent.ainvoke({
        "messages": [{"role": "user", "content": "What is 127 + 456?"}]
    })
    
    # Print final answer
    print(response["messages"][-1].content)

asyncio.run(run_agent_with_mcp())
```

---

## Example 17: Claude Desktop JSON Configuration

`claude_desktop_config.json` with multiple servers:

```json
{
  "mcpServers": {
    "math": {
      "command": "python",
      "args": ["C:/projects/mcp/math_server.py"],
      "env": {}
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:/Users/myuser/Documents"
      ]
    },
    "weather": {
      "command": "python",
      "args": ["C:/projects/mcp/weather_server.py"],
      "env": {
        "OPENWEATHER_API_KEY": "your-api-key-here"
      }
    },
    "sqlite": {
      "command": "python",
      "args": ["C:/projects/mcp/database_resource_server.py"],
      "env": {
        "DB_PATH": "C:/data/mydb.sqlite"
      }
    }
  }
}
```

---

## Example 18: Cursor IDE JSON Configuration

`.cursor/mcp.json` for project-level MCP servers in Cursor:

```json
{
  "mcpServers": {
    "project-tools": {
      "command": "python",
      "args": ["./mcp_server.py"],
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_yourtoken"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

---

## Example 19: Error Handling in MCP Server

Proper error handling with custom error types.

```python
# error_handling_server.py
from mcp.server.fastmcp import FastMCP
from typing import Optional
import httpx

mcp = FastMCP("robust-server")

class ExternalAPIError(Exception):
    """Raised when an external API call fails."""
    pass

@mcp.tool()
def safe_divide(numerator: float, denominator: float) -> float:
    """
    Safely divide numerator by denominator.
    Raises ValueError if denominator is zero.
    """
    if denominator == 0:
        # FastMCP converts unhandled exceptions to MCP error responses
        raise ValueError("Division by zero is not allowed")
    return numerator / denominator

@mcp.tool()
async def fetch_url(url: str, timeout: Optional[float] = 10.0) -> str:
    """
    Fetch content from a URL.
    
    Args:
        url: The URL to fetch.
        timeout: Request timeout in seconds.
    """
    if not url.startswith(("http://", "https://")):
        raise ValueError("URL must start with http:// or https://")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, timeout=timeout)
            response.raise_for_status()
            return response.text[:5000]  # cap response size
    except httpx.HTTPStatusError as e:
        raise ExternalAPIError(f"HTTP {e.response.status_code}: {e.request.url}") from e
    except httpx.TimeoutException:
        raise ExternalAPIError(f"Request timed out after {timeout}s")

if __name__ == "__main__":
    mcp.run()
```

---

## Example 20: Authentication / Security Header Check (SSE)

Add API key validation to an SSE server.

```python
# auth_sse_server.py
import os
from mcp.server.fastmcp import FastMCP
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

mcp = FastMCP("secure-server")
API_KEY = os.environ.get("MCP_API_KEY", "changeme")

class ApiKeyMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer ") or auth_header[7:] != API_KEY:
            return Response("Unauthorized", status_code=401)
        return await call_next(request)

@mcp.tool()
def sensitive_operation(query: str) -> str:
    """A tool that requires authentication to call."""
    return f"Authenticated result for: {query}"

if __name__ == "__main__":
    app = mcp.sse_app()
    app.add_middleware(ApiKeyMiddleware)
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## Example 21: ML Model Prediction Tool

Expose a scikit-learn model as an MCP tool.

```python
# ml_server.py
import json
import pickle
import numpy as np
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ml-server")

# Load a pre-trained model (e.g., trained with scikit-learn)
with open("model.pkl", "rb") as f:
    MODEL = pickle.load(f)

@mcp.tool()
def predict(features: list[float]) -> dict:
    """
    Run inference with the ML model.
    
    Args:
        features: Input feature vector as a list of floats.
    
    Returns:
        Prediction result with class label and confidence score.
    """
    X = np.array(features).reshape(1, -1)
    prediction = MODEL.predict(X)[0]
    probabilities = MODEL.predict_proba(X)[0].tolist()
    
    return {
        "prediction": int(prediction),
        "confidence": max(probabilities),
        "class_probabilities": probabilities,
    }

if __name__ == "__main__":
    mcp.run()
```

---

## Example 22: News Search Tool

Search for news articles using an external API.

```python
# news_server.py
import os
import httpx
from mcp.server.fastmcp import FastMCP
from typing import Optional

mcp = FastMCP("news-server")
NEWS_API_KEY = os.environ["NEWS_API_KEY"]
BASE_URL = "https://newsapi.org/v2/everything"

@mcp.tool()
async def search_news(
    query: str,
    max_results: Optional[int] = 5,
    language: Optional[str] = "en"
) -> list[dict]:
    """
    Search for recent news articles.
    
    Args:
        query: Search terms (e.g., 'AI research 2024')
        max_results: Maximum number of articles to return (1-20)
        language: Language code (en, fr, de, es, etc.)
    
    Returns:
        List of articles with title, description, url, and publishedAt.
    """
    max_results = min(max(1, max_results), 20)  # clamp to [1, 20]
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(BASE_URL, params={
            "q": query,
            "pageSize": max_results,
            "language": language,
            "apiKey": NEWS_API_KEY,
        })
        resp.raise_for_status()
        data = resp.json()
    
    return [
        {
            "title": a["title"],
            "description": a["description"],
            "url": a["url"],
            "published": a["publishedAt"],
            "source": a["source"]["name"],
        }
        for a in data.get("articles", [])
    ]

if __name__ == "__main__":
    mcp.run()
```

---

## Quick Reference: Installing MCP SDK

```bash
# Install the MCP Python SDK
pip install mcp

# Install with CLI extras (for testing servers from command line)
pip install "mcp[cli]"

# Install LangChain MCP adapters
pip install langchain-mcp-adapters

# Test a server from the command line
mcp dev server.py

# Install a server into Claude Desktop automatically
mcp install server.py --name "my-server"
```