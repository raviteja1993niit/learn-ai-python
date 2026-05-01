# MCP Hands-On Practicals — Project-Based Learning Guide

## Overview

These 10 hands-on projects take you from beginner to production-ready MCP developer.
Each project includes prerequisites, step-by-step setup, a reference implementation,
testing instructions, and extension challenges.

Work through them in order — each builds on concepts from the previous one.

---

## Project 1: Filesystem MCP Server

**Goal**: Build a server that lets an LLM read files, write files, and list directories.

**Skills**: FastMCP basics, path safety, tool design

### Prerequisites
```
pip install mcp
```

### Step-by-Step

1. Create `filesystem_server.py`
2. Define an allowed root directory using an env variable:
   ```python
   import os
   ROOT = os.environ.get("FS_ROOT", os.path.expanduser("~/mcp-sandbox"))
   os.makedirs(ROOT, exist_ok=True)
   ```
3. Implement a `read_file(path)` tool — read relative paths under ROOT
4. Implement a `write_file(path, content)` tool — write files under ROOT
5. Implement a `list_directory(path)` tool — return entries as a list
6. Add path traversal protection:
   ```python
   full = os.path.realpath(os.path.join(ROOT, path))
   assert full.startswith(os.path.realpath(ROOT)), "Access denied"
   ```
7. Run with `python filesystem_server.py`
8. Test with `mcp dev filesystem_server.py`

### Testing
```
mcp dev filesystem_server.py
# In the MCP inspector UI:
# Call list_directory with path="."
# Call write_file with path="test.txt", content="Hello MCP!"
# Call read_file with path="test.txt"
```

### Extension Challenges
- Add a `delete_file` tool with a confirmation parameter
- Add a `search_files(pattern)` tool using glob matching
- Add file metadata (size, modified time) to list_directory output

---

## Project 2: ML Model Prediction MCP Server

**Goal**: Wrap a trained scikit-learn model as an MCP tool so an LLM can run predictions.

**Skills**: Pickling models, NumPy integration, async tools

### Prerequisites
```
pip install mcp scikit-learn numpy
```

### Step-by-Step

1. Train and save a model:
   ```python
   from sklearn.datasets import load_iris
   from sklearn.ensemble import RandomForestClassifier
   import pickle
   
   X, y = load_iris(return_X_y=True)
   model = RandomForestClassifier().fit(X, y)
   with open("iris_model.pkl", "wb") as f:
       pickle.dump(model, f)
   ```
2. Create `ml_server.py`
3. Load model at startup (module level, not inside the tool function)
4. Implement `predict(sepal_length, sepal_width, petal_length, petal_width)` tool
5. Return class name, confidence, and all class probabilities
6. Add input validation (all floats, positive values)
7. Map prediction integer to class label:
   ```python
   CLASSES = ["setosa", "versicolor", "virginica"]
   ```

### Testing
```bash
mcp dev ml_server.py
# Call predict with: sepal_length=5.1, sepal_width=3.5, petal_length=1.4, petal_width=0.2
# Expected: setosa with high confidence
```

### Extension Challenges
- Add a `batch_predict(samples: list[list[float]])` tool
- Load model path from environment variable
- Add a `get_model_info` tool returning model type, feature names, classes

---

## Project 3: Connect Custom MCP Server to Claude Desktop

**Goal**: Register your filesystem server from Project 1 in Claude Desktop and use it interactively.

**Skills**: Claude Desktop config, environment variables, troubleshooting

### Prerequisites
- Claude Desktop installed
- Project 1 server completed

### Step-by-Step

1. Find the config file:
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

2. Open or create the config file

3. Add your server:
   ```json
   {
     "mcpServers": {
       "my-filesystem": {
         "command": "python",
         "args": ["C:/full/path/to/filesystem_server.py"],
         "env": {
           "FS_ROOT": "C:/Users/yourname/mcp-sandbox"
         }
       }
     }
   }
   ```

4. Save and **restart Claude Desktop** (File > Quit, then reopen)

5. Look for the hammer icon (🔨) in Claude's chat input — this indicates MCP tools are available

6. Ask Claude: "List the files in my sandbox directory"

### Troubleshooting
- Check Claude Desktop logs: `%APPDATA%\Claude\logs\` on Windows
- Ensure `python` is in your PATH (`python --version` in terminal)
- Use absolute paths for both command and args
- Test the server independently first: `python filesystem_server.py`

### Extension Challenges
- Register multiple servers (filesystem + weather + math)
- Use a virtual environment: set `command` to the venv python path
- Add a custom tool description that helps Claude know when to use it

---

## Project 4: Weather Data MCP Server

**Goal**: Build a real weather server using the Open-Meteo API (free, no API key needed).

**Skills**: Async HTTP with httpx, data formatting, optional parameters

### Prerequisites
```
pip install mcp httpx
```

### Step-by-Step

1. Create `weather_server.py`
2. Use the Open-Meteo free API:
   ```
   https://api.open-meteo.com/v1/forecast?latitude=51.5&longitude=-0.1&current_weather=true
   ```
3. Implement `get_weather_by_coords(latitude, longitude)` tool
4. Add a `geocode_city(city_name)` tool using the Open-Meteo geocoding API:
   ```
   https://geocoding-api.open-meteo.com/v1/search?name={city}&count=1
   ```
5. Chain them: `get_weather_by_city(city)` calls geocode then weather
6. Return temperature, wind speed, weather code, and time
7. Add a weather code interpretation table (WMO codes 0-99)

### Testing
```bash
mcp dev weather_server.py
# Test: get_weather_by_city with city="Tokyo"
# Test: get_weather_by_coords with latitude=48.85, longitude=2.35 (Paris)
```

### Extension Challenges
- Add hourly forecast for next 24 hours
- Add a `compare_weather(city1, city2)` tool
- Cache results for 10 minutes to avoid repeated API calls

---

## Project 5: SQLite Database MCP Server

**Goal**: Build a complete database access server for SQLite with safe query execution.

**Skills**: SQLite, parameterised queries, security, schema discovery

### Prerequisites
```
pip install mcp
```

### Step-by-Step

1. Create a sample database:
   ```python
   import sqlite3
   conn = sqlite3.connect("company.db")
   conn.execute("CREATE TABLE employees (id INTEGER PRIMARY KEY, name TEXT, dept TEXT, salary REAL)")
   conn.execute("INSERT INTO employees VALUES (1, 'Alice', 'Engineering', 95000)")
   conn.execute("INSERT INTO employees VALUES (2, 'Bob', 'Marketing', 72000)")
   conn.commit()
   conn.close()
   ```

2. Create `sqlite_server.py`

3. Implement these tools:
   - `list_tables()` — return all table names
   - `describe_table(table_name)` — return column info
   - `query(sql)` — execute SELECT only, return rows as list of dicts
   - `insert_row(table, data: dict)` — parameterised INSERT
   - `update_rows(table, set_data: dict, where: str)` — UPDATE with WHERE

4. Add SQL injection protection:
   - Only allow SELECT in `query()`
   - Use `?` placeholders, never f-strings for user data
   - Validate table names against `list_tables()` result

### Testing
```bash
mcp dev sqlite_server.py
# Call list_tables — should return ["employees"]
# Call query with sql="SELECT * FROM employees WHERE dept='Engineering'"
```

### Extension Challenges
- Add transaction support (begin/commit/rollback tools)
- Add a `export_csv(table_name)` tool
- Support multiple databases via environment variable

---

## Project 6: Web Scraping MCP Server

**Goal**: Build a server that can scrape web pages and extract structured data.

**Skills**: httpx, HTML parsing with BeautifulSoup, content safety

### Prerequisites
```
pip install mcp httpx beautifulsoup4 html2text
```

### Step-by-Step

1. Create `scraper_server.py`

2. Implement `fetch_page(url)` — fetch a URL and return as Markdown:
   ```python
   import httpx, html2text
   async with httpx.AsyncClient() as client:
       resp = await client.get(url, follow_redirects=True, timeout=15)
   h = html2text.HTML2Text()
   h.ignore_links = False
   return h.handle(resp.text)
   ```

3. Implement `extract_links(url)` — return all hyperlinks on a page

4. Implement `extract_tables(url)` — return tables as list of dicts using BeautifulSoup

5. Implement `get_page_title(url)` — fast single-field extractor

6. Add URL validation and block private IP ranges (security)

7. Set a reasonable User-Agent header to avoid blocks

### Testing
```bash
mcp dev scraper_server.py
# Call fetch_page with url="https://example.com"
# Call extract_links with url="https://news.ycombinator.com"
```

### Extension Challenges
- Add a `search_page(url, keyword)` tool that highlights matching sections
- Add rate limiting (max 10 requests per minute)
- Cache page content for 5 minutes

---

## Project 7: Connect MCP Server to LangChain Agent

**Goal**: Use your weather server (Project 4) as tools in a LangChain ReAct agent.

**Skills**: langchain-mcp-adapters, async agents, multi-step reasoning

### Prerequisites
```
pip install mcp langchain-mcp-adapters langchain-anthropic langgraph python-dotenv
```

### Step-by-Step

1. Create a `.env` file with your Anthropic API key:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```

2. Create `langchain_agent.py`:

   ```python
   import asyncio
   from dotenv import load_dotenv
   from mcp import ClientSession, StdioServerParameters
   from mcp.client.stdio import stdio_client
   from langchain_mcp_adapters.tools import load_mcp_tools
   from langchain_anthropic import ChatAnthropic
   from langgraph.prebuilt import create_react_agent
   
   load_dotenv()
   
   async def main():
       params = StdioServerParameters(command="python", args=["weather_server.py"])
       async with stdio_client(params) as (r, w):
           async with ClientSession(r, w) as session:
               await session.initialize()
               tools = await load_mcp_tools(session)
               model = ChatAnthropic(model="claude-3-5-sonnet-20241022")
               agent = create_react_agent(model, tools)
               result = await agent.ainvoke({
                   "messages": [{"role": "user", "content":
                       "Is it hotter in Tokyo or London right now?"}]
               })
               print(result["messages"][-1].content)
   
   asyncio.run(main())
   ```

3. Run: `python langchain_agent.py`

4. The agent should call the weather tools and compare temperatures

### Extension Challenges
- Pass multiple MCP servers to the agent (weather + filesystem + database)
- Add a system prompt that describes when to use each tool
- Stream the agent's reasoning steps to the console

---

## Project 8: API Gateway MCP Server

**Goal**: Build a unified MCP server that wraps multiple external REST APIs.

**Skills**: Environment-variable secrets, async HTTP, response normalisation

### Prerequisites
```
pip install mcp httpx python-dotenv
```

### Step-by-Step

1. Create `api_gateway_server.py`

2. Load API keys from environment:
   ```python
   import os
   from dotenv import load_dotenv
   load_dotenv()
   GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
   ```

3. Implement GitHub tools:
   - `github_search_repos(query, limit=5)` — search repositories
   - `github_get_readme(owner, repo)` — fetch README content
   - `github_list_issues(owner, repo, state="open")` — list issues

4. Normalise all responses to consistent dict shapes

5. Handle rate limiting with retry logic:
   ```python
   if response.status_code == 429:
       retry_after = int(response.headers.get("Retry-After", 60))
       raise RuntimeError(f"Rate limited. Retry after {retry_after}s")
   ```

6. Test: Register in Claude Desktop and ask about popular GitHub repos

### Extension Challenges
- Add a Jira integration tool
- Add a Slack message posting tool
- Add response caching with TTL

---

## Project 9: Code Execution MCP Server

**Goal**: Build a sandboxed code execution server that runs Python snippets safely.

**Skills**: Subprocess isolation, timeout enforcement, output capture

### Prerequisites
```
pip install mcp
```

### Step-by-Step

1. Create `code_executor_server.py`

2. Implement `run_python(code: str, timeout: float = 5.0)`:
   ```python
   import subprocess, sys, textwrap
   
   result = subprocess.run(
       [sys.executable, "-c", code],
       capture_output=True,
       text=True,
       timeout=timeout,
   )
   return {
       "stdout": result.stdout[:2000],
       "stderr": result.stderr[:500],
       "returncode": result.returncode,
   }
   ```

3. Add a code safety filter — block imports of `os`, `sys`, `subprocess`, `socket`

4. Cap output at 2000 characters to prevent flooding

5. Set a hard timeout (raise TimeoutError if exceeded)

6. Log all executed code to a local file for auditing

### Security Warning
> **Never run this server with unrestricted imports in a production environment.**
> Always run inside a Docker container or VM with no network access.
> Consider using RestrictedPython or a WASM sandbox for safer execution.

### Testing
```bash
mcp dev code_executor_server.py
# Call run_python with code="print(sum(range(100)))"
# Should return: stdout="4950"
```

### Extension Challenges
- Add `run_bash(command)` tool (Linux/macOS only)
- Add a `pip_install_and_run(package, code)` tool that creates a temp venv
- Return execution time in milliseconds

---

## Project 10: SSE Remote MCP Server Deployment

**Goal**: Deploy an MCP server as a remote HTTPS service accessible over the internet.

**Skills**: SSE transport, Uvicorn, cloud deployment, authentication

### Prerequisites
```
pip install mcp uvicorn
# Optional: pip install gunicorn
```

### Step-by-Step

1. Create `remote_server.py` with SSE transport:
   ```python
   import os
   from mcp.server.fastmcp import FastMCP
   
   mcp = FastMCP("remote-server")
   API_KEY = os.environ.get("MCP_API_KEY", "dev-key")
   
   @mcp.tool()
   def get_status() -> dict:
       """Check server status."""
       return {"status": "ok", "server": "remote-mcp"}
   
   if __name__ == "__main__":
       mcp.run(transport="sse", host="0.0.0.0", port=8000)
   ```

2. Test locally:
   ```bash
   python remote_server.py
   # Server starts at http://localhost:8000
   ```

3. Deploy to a cloud VM (e.g., AWS EC2, DigitalOcean Droplet):
   ```bash
   # On server:
   pip install mcp uvicorn
   MCP_API_KEY=my-secret-key python remote_server.py
   ```

4. Set up HTTPS with Nginx + Let's Encrypt (certbot):
   ```nginx
   server {
       listen 443 ssl;
       server_name your-domain.com;
       ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Connection '';
           proxy_http_version 1.1;
           chunked_transfer_encoding on;
       }
   }
   ```

5. Connect a client to the remote server:
   ```python
   from mcp.client.sse import sse_client
   from mcp import ClientSession
   
   async with sse_client("https://your-domain.com/sse") as (r, w):
       async with ClientSession(r, w) as session:
           await session.initialize()
           result = await session.call_tool("get_status", {})
   ```

### Deployment Checklist
- [ ] HTTPS enabled (never deploy MCP over plain HTTP in production)
- [ ] API key authentication middleware added
- [ ] Rate limiting configured
- [ ] Logs are being collected
- [ ] Server auto-restarts on crash (systemd, supervisord, or PM2)
- [ ] Environment variables set (not hardcoded secrets)

### Extension Challenges
- Containerise with Docker and deploy to Fly.io or Railway
- Add Prometheus metrics endpoint
- Add request tracing with OpenTelemetry
- Implement WebSocket transport for lower latency

---

## Summary Checklist

After completing all 10 projects, you should be able to:

- [x] Build and run stdio and SSE MCP servers
- [x] Implement Tools, Resources, and Prompts primitives
- [x] Connect MCP servers to Claude Desktop and Cursor IDE
- [x] Integrate MCP tools with LangChain agents
- [x] Handle errors, authentication, and security properly
- [x] Deploy MCP servers to the cloud over HTTPS
- [x] Wrap real-world APIs (GitHub, weather, databases) as MCP tools
- [x] Build production-ready servers with logging, validation, and rate limiting