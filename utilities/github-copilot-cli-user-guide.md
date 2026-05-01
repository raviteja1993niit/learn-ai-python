# GitHub Copilot CLI — Complete User Guide

> Version: 2.0 | Generated: 2026-04-16 | Based on CLI v1.0.27

---

## 1. What Is GitHub Copilot CLI?

GitHub Copilot CLI brings the full power of GitHub Copilot's coding agent directly into your terminal. It is the same agentic engine that powers the GitHub Copilot cloud agent — running locally and synchronously, so you stay in control.

**Key capabilities:**
- Natural-language coding: build, edit, debug, refactor via chat
- Deep GitHub integration: issues, PRs, repositories — all via natural language
- Agentic task execution: multi-step planning and execution
- MCP-powered extensibility: connect any MCP server
- Full approval control: nothing runs without your confirmation

---

## 2. Prerequisites & Installation

### Prerequisites
- Active [GitHub Copilot subscription](https://github.com/features/copilot/plans)
- Windows: **PowerShell v6+** required

### Install

| Platform | Command |
|----------|---------|
| macOS/Linux (script) | `curl -fsSL https://gh.io/copilot-install \| bash` |
| macOS/Linux (Homebrew) | `brew install copilot-cli` |
| Windows (WinGet) | `winget install GitHub.Copilot` |
| All platforms (npm) | `npm install -g @github/copilot` |

**Install a specific version:**
```bash
curl -fsSL https://gh.io/copilot-install | VERSION="v0.0.369" PREFIX="$HOME/custom" bash
```

**Prerelease channel:**
```bash
brew install copilot-cli@prerelease
winget install GitHub.Copilot.Prerelease
npm install -g @github/copilot@prerelease
```

---

## 3. Authentication

### Option A — Interactive Login
On first launch, use the `/login` slash command and follow on-screen instructions.

### Option B — Personal Access Token (PAT)
1. Go to https://github.com/settings/personal-access-tokens/new
2. Under **Permissions**, add `Copilot Requests`
3. Generate the token
4. Set environment variable:
   ```bash
   export GH_TOKEN=<your-token>       # takes precedence
   export GITHUB_TOKEN=<your-token>   # fallback
   ```

To log out of an OAuth session:
```
/logout
```

---

## 4. Launching the CLI

Navigate to your project folder, then run:
```bash
copilot
```

On first launch you'll see the animated banner. To see it again later:
```bash
copilot --banner
```

You'll be asked to **trust the current directory** — choose:
1. **Yes, proceed** — trusted for this session only
2. **Yes, and remember this folder** — trusted for all future sessions
3. **No, exit (Esc)** — abort

> ⚠️ Do NOT launch from your home directory or any folder with sensitive/confidential data.

---

## 5. Interaction Modes

Cycle between modes with **Shift+Tab**:

| Mode | Description |
|------|-------------|
| **Normal (default)** | Conversational assistant + agentic coding |
| **Plan mode** | Collaborate on an implementation plan before any code is written |
| **Autopilot** *(experimental)* | Agent works until task is complete without approval at each step |

Switch to plan mode explicitly:
```
/plan
```

---

## 6. Writing Prompts

### Basic Chat
```
What does the AcquirerRequestHandler class do?
```

### Reference a Specific File
Prefix with `@`:
```
Explain @src/service/PaymentService.java
Fix the bug in @config/application.yml
```
Start typing the path and press **Tab** to autocomplete.

### Reference GitHub Issues / PRs
Use `#`:
```
Summarise the changes in #42
```

### Run a Shell Command Directly
Prefix with `!` to bypass the model entirely:
```bash
!git status
!mvn clean install -DskipTests
```

---

## 7. Tool Approval (Permissions)

When Copilot wants to run a tool that modifies or executes files, it asks for approval:

| Option | Meaning |
|--------|---------|
| **Yes** | Allow once; ask again next time |
| **Yes, approve for session** | Allow this tool without asking again this session |
| **No (Esc)** | Reject and await your next prompt; give inline feedback |

### Bulk Permission Flags (launch-time)

```bash
copilot --allow-all-tools                        # allow everything
copilot --allow-tool='shell(mvn)'                # allow specific command
copilot --deny-tool='shell(rm)'                  # block specific command
copilot --deny-tool='shell(git push)'            # block git push
copilot --allow-all-tools --deny-tool='shell(rm)' --deny-tool='shell(git push)'
copilot --allow-tool='My-MCP-Server' --deny-tool='My-MCP-Server(delete_record)'
```

### In-Session Permission Commands

| Command | Effect |
|---------|--------|
| `/allow-all` | Enable all permissions |
| `/add-dir /path` | Add a directory to the trusted list |
| `/list-dirs` | Show all trusted directories |
| `/reset-allowed-tools` | Reset all approved tools to default |

---

## 8. All Slash Commands — Full Reference with Options

---

### `/model` — Select AI Model

Opens an interactive picker to switch the active model. Selection is persisted to `~/.copilot/config.json`.

**Available models:**

| Model ID | Name | Speed | Best For |
|----------|------|-------|----------|
| `claude-sonnet-4.5` *(default)* | Claude Sonnet 4.5 | Fast | General coding, chat |
| `claude-sonnet-4.6` | Claude Sonnet 4.6 | Fast | General coding, chat |
| `claude-sonnet-4` | Claude Sonnet 4 | Fast | Standard tasks |
| `claude-haiku-4.5` | Claude Haiku 4.5 | Fastest | Quick lookups, low cost |
| `claude-opus-4.5` | Claude Opus 4.5 | Slower | Complex reasoning |
| `claude-opus-4.6` | Claude Opus 4.6 | Slower | Premium reasoning |
| `gpt-5.2` | GPT-5.2 | Standard | General tasks |
| `gpt-5.4` | GPT-5.4 | Standard | General tasks |
| `gpt-5.4-mini` | GPT-5.4 mini | Fast/cheap | High-volume tasks |
| `gpt-5-mini` | GPT-5 mini | Fast/cheap | Lightweight tasks |
| `gpt-4.1` | GPT-4.1 | Fast/cheap | Budget-friendly |
| `gpt-5.3-codex` | GPT-5.3-Codex | Standard | Code-focused |
| `gpt-5.2-codex` | GPT-5.2-Codex | Standard | Code-focused |

**Set model directly in config:**
```json
// ~/.copilot/config.json
{ "model": "claude-sonnet-4.6" }
```

**Set reasoning effort** (for models that support extended thinking):
```json
{ "effortLevel": "high" }   // "low" | "medium" | "high"
```

---

### `/agent` — Browse and Use Custom Agents

Opens an interactive list of available agents. Arrow keys to navigate, Enter to select.

**Built-in agents:**

| Agent | When to Use |
|-------|-------------|
| `explore` | Quick codebase Q&A without consuming main context |
| `task` | Run builds/tests; brief success summary, full failure output |
| `general-purpose` | Complex multi-step tasks in separate context window |
| `code-review` | Surfaces only genuine issues; ignores style noise |

**Invoke by name in prompt:**
```
Use the explore agent to find all usages of PaymentService
```

**Invoke via flag (programmatic):**
```bash
copilot --agent=code-review --prompt "Review changes in src/"
copilot --agent=explore     --prompt "Where is rate limiting implemented?"
copilot --agent=task        --prompt "Run all unit tests"
```

**Custom agent locations:**

| Level | Path | Scope |
|-------|------|-------|
| User | `~/.copilot/agents/*.agent.md` | All projects |
| Repository | `.github/agents/*.agent.md` | Current project |
| Org/Enterprise | `.github-private/agents/*.agent.md` | Whole org |

> Precedence: System > Repository > Organisation

---

### `/skills` — Manage Skills

Lists available skills, shows active status, allows toggling.

**Skill locations:**

| Level | Path |
|-------|------|
| User | `~/.copilot/skills/<name>/SKILL.md` |
| Repository | `.github/skills/<name>/SKILL.md` |

**Skill YAML frontmatter fields:**
```markdown
---
name: my-skill
description: What this skill does
triggers:
  - onFileWrite
  - onPhaseStart phase=4
---
```

---

### `/mcp` — Manage MCP Servers

| Subcommand | Description |
|-----------|-------------|
| `/mcp` | List all configured MCP servers and their connection status |
| `/mcp add` | Add a new MCP server interactively (Tab between fields, Ctrl+S to save) |

**Interactive add fields:**
- **Name** — unique identifier for the server
- **Type** — `local`, `stdio`, `http`, or `sse`
- **Command** — executable to run (local servers)
- **Args** — arguments array
- **Tools** — comma-separated tool allowlist (or `*` for all)
- **Env** — environment variable mappings

**Config stored at:** `~/.copilot/mcp-config.json`

**Allow/deny MCP tools at launch:**
```bash
copilot --allow-tool='my-server'                  # allow all tools from server
copilot --deny-tool='my-server(delete_record)'    # block one specific tool
```

---

### `/plugin` — Manage Plugins

| Subcommand | Description |
|-----------|-------------|
| `/plugin` | List installed plugins |
| `/plugin install <source>` | Install a plugin from marketplace or URL |
| `/plugin uninstall <name>` | Uninstall a plugin |
| `/plugin update` | Update all installed plugins |

**Plugin storage:** `~/.copilot/installed-plugins/`

---

### `/lsp` — Language Server Protocol

| Subcommand | Description |
|-----------|-------------|
| `/lsp` | List configured LSP servers and their running status |

**Config files:**

| Scope | Path |
|-------|------|
| User | `~/.copilot/lsp-config.json` |
| Repository | `.github/lsp.json` |

**Config schema:**
```json
{
  "lspServers": {
    "<language>": {
      "command": "<server-executable>",
      "args": ["--stdio"],
      "fileExtensions": {
        ".ext": "<language-id>"
      }
    }
  }
}
```

**Common language servers:**

| Language | Install Command | Server Executable |
|----------|----------------|-------------------|
| TypeScript/JS | `npm i -g typescript-language-server` | `typescript-language-server` |
| Python | `pip install python-lsp-server` | `pylsp` |
| Java | Download Eclipse JDT LS | `jdtls` |
| Go | `go install golang.org/x/tools/gopls@latest` | `gopls` |
| Rust | `rustup component add rust-analyzer` | `rust-analyzer` |

---

### `/theme` — Set Colour Theme

| Option | Description |
|--------|-------------|
| `/theme` | Show current theme and available options |
| `/theme auto` | Follow system light/dark preference |
| `/theme dark` | Force dark mode |
| `/theme light` | Force light mode |

**Persisted to config:**
```json
{ "theme": "auto" }
```

---

### `/share` — Share Session

| Option | Description |
|--------|-------------|
| `/share` | Interactive picker — choose output format |
| Markdown file | Saves `.md` file to current directory |
| HTML file | Saves styled `.html` file |
| GitHub Gist | Uploads session to your GitHub Gist (public or secret) |

---

### `/session` — View & Manage Sessions

| Subcommand | Description |
|-----------|-------------|
| `/session` | Show current session info (ID, duration, log path, working directory) |
| `/session list` | List all saved sessions |

---

### `/resume` — Resume a Session

| Usage | Description |
|-------|-------------|
| `/resume` | Interactive list of past sessions to resume |
| `/resume <session-id>` | Resume a specific session by ID |
| `/resume <task-id>` | Resume by cloud agent task ID |

**Launch-time equivalent:**
```bash
copilot --resume           # pick from list
copilot --continue         # resume most recently closed session
```

---

### `/context` — Token Usage Visualisation

Displays a visual bar showing:
- Total context window size
- Tokens used by conversation history
- Tokens used by instructions / system prompt
- Tokens used by tool results
- Remaining free tokens

---

### `/usage` — Session Metrics

Displays:
- Premium requests used in current session
- Session duration
- Total lines of code edited
- Token usage breakdown per model

---

### `/compact` — Compress Context

Summarises conversation history to free up context window space.
- Press **Esc** to cancel if triggered accidentally
- Auto-triggered at 95% of token limit

---

### `/instructions` — View Active Instructions

| Usage | Description |
|-------|-------------|
| `/instructions` | List all loaded instruction files with their status |
| `/instructions toggle <file>` | Enable or disable a specific instruction file |

---

### `/experimental` — Experimental Features

| Usage | Description |
|-------|-------------|
| `/experimental` | Show all available experimental features and their on/off status |
| `/experimental enable <feature>` | Enable a specific experimental feature |
| `/experimental disable <feature>` | Disable a specific experimental feature |

**Current experimental features:**
- `autopilot` — agent works to task completion without per-step approval

**Persist via launch flag:**
```bash
copilot --experimental
```

---

### `/changelog` — View Release Notes

| Usage | Description |
|-------|-------------|
| `/changelog` | Display raw changelog entries for recent versions |
| `/changelog summarize` | AI-generated plain-language summary of recent changes |

---

### `/feedback` — Submit Feedback

Opens a menu with three options:
1. **Private feedback survey** — confidential Copilot feedback form
2. **Bug report** — opens GitHub issue template
3. **Feature request** — opens GitHub discussion/feature request

---

### `/diff` — Review Staged Changes

Shows all file changes in the current working directory.  
Use before committing to review what Copilot has modified.

---

### `/pr` — Pull Request Operations

| Usage | Description |
|-------|-------------|
| `/pr` | Show PR options for the current branch |
| `/pr create` | Create a new PR for the current branch |
| `/pr view` | View the open PR for the current branch |
| `/pr merge` | Merge the PR for the current branch |

---

### `/review` — Run Code Review Agent

Launches the built-in `code-review` agent against the current diff.  
Surfaces only genuine issues — never style comments.

---

### `/plan` — Implementation Planning Mode

Copilot analyses your request, asks clarifying questions, and builds a structured plan before writing any code. Equivalent to pressing **Shift+Tab** into Plan mode.

---

### `/fleet` — Parallel Sub-Agent Execution

Launches multiple sub-agents running in parallel, each handling an independent part of the task.  
Useful for: parallel test runs, concurrent module reviews, simultaneous research threads.

---

### `/tasks` — Background Task Manager

| Usage | Description |
|-------|-------------|
| `/tasks` | List all active background tasks (sub-agents, shell sessions) |
| `/tasks <id>` | Focus on a specific task and view its output |

---

### `/delegate` — Hand Off to Cloud Agent

Sends the current session task to a GitHub-hosted cloud agent.  
The agent works asynchronously and opens a PR when done.  
Resume locally with `copilot --resume`.

---

### `/remote` — Remote Control

Enables control of your local CLI session from:
- GitHub web interface
- GitHub mobile app

---

### `/cwd` — Change Working Directory

| Usage | Description |
|-------|-------------|
| `/cwd` | Display current working directory |
| `/cwd /path/to/dir` | Switch working directory without restarting CLI |

Alias: `/cd`

---

### `/add-dir` — Trust a Directory

```
/add-dir /path/to/directory
```
Adds the path to the trusted list for file access this session.

---

### `/allow-all` — Enable All Permissions

Equivalent to launching with `--allow-all-tools --allow-all-paths --allow-all-urls`.  
Alias: `/yolo`

---

### `/env` — Show Loaded Environment

Displays all currently active:
- Instruction files
- MCP servers (and their available tools)
- Skills
- Custom agents
- Plugins
- LSP servers
- Extensions

---

### `/ask` — Quick Side Question

```
/ask What is the difference between OAuth and JWT?
```
Answer is shown but **not added to conversation history** — context is not consumed.

---

### `/research` — Deep Research

Runs a multi-step investigation using GitHub search and web sources.  
Returns a structured research report.  
Optionally share with `/share`.

---

### `/init` — Initialise Repository Instructions

Creates or updates `.github/copilot-instructions.md` in the current repository with a starter template based on your project type.

---

### `/ide` — Connect to IDE

| Usage | Description |
|-------|-------------|
| `/ide` | Show IDE connection status |
| `/ide connect` | Connect to a running VS Code workspace |

State stored in `~/.copilot/ide/`.

---

### `/login` / `/logout` — Authentication

| Command | Description |
|---------|-------------|
| `/login` | Authenticate via browser OAuth flow |
| `/logout` | Revoke the current OAuth session token |

Alternative: set `GH_TOKEN` or `GITHUB_TOKEN` env var (PAT with `Copilot Requests` permission).

---

### `/user` — GitHub User Management

| Usage | Description |
|-------|-------------|
| `/user` | Show currently authenticated GitHub user |
| `/user add` | Add an additional GitHub user account |
| `/user switch` | Switch between authenticated accounts |

---

### `/rename` — Rename Session

| Usage | Description |
|-------|-------------|
| `/rename <name>` | Rename current session to a custom name |
| `/rename` | Auto-generate a name from conversation content |

---

### `/update` — Update CLI

Checks for and downloads the latest version.  
Auto-update can be configured:
```json
{ "autoUpdate": true }
```

---

### `/version` — Version Info

Displays current CLI version and checks whether a newer version is available.

---

### `/terminal-setup` — Multiline Input

Configures the terminal to support **Shift+Enter** for multiline prompts.  
Required for some terminal emulators (e.g. Windows Terminal, iTerm2).

---

### `/copy` — Copy Response

Copies the last Copilot response to the system clipboard.

---

### `/rewind` / `/undo` — Revert Last Turn

Undoes the last conversational turn **and reverts all file changes** made in that turn.

---

### `/restart` — Restart CLI

Restarts the CLI process while preserving the current session state.  
Useful after updating or changing config.

---

### `/clear` — Abandon Session

Ends the current session and starts a fresh one.  
Previous session remains accessible via `/resume`.

---

### `/new` — New Conversation

Starts a new conversation within the same session (context is reset).

---

### `/streamer-mode` — Streaming Privacy

Toggles visibility of:
- Preview model names
- Quota and usage details

Useful when screen-sharing or streaming.

---

### `/help` — Help

| Usage | Description |
|-------|-------------|
| `/help` | Full interactive help with all commands |
| `?` | Same as `/help` (in prompt box) |

Terminal equivalents:
```bash
copilot help
copilot help config
copilot help environment
copilot help logging
copilot help permissions
```

---

## 9. Keyboard Shortcuts Reference

### Global
| Shortcut | Action |
|----------|--------|
| `Shift+Tab` | Cycle between modes (Normal → Plan → Autopilot) |
| `Ctrl+S` | Run command, preserve input |
| `Ctrl+C` | Cancel current operation |
| `Ctrl+C × 2` | Exit CLI |
| `Esc` | Cancel / reject tool approval |
| `Ctrl+D` | Shutdown |
| `Ctrl+L` | Clear screen |
| `Ctrl+O` / `Ctrl+E` | Expand all timeline |
| `Ctrl+T` | Toggle reasoning visibility (show/hide model's thinking) |
| `Ctrl+X → O` | Open most recent link |

### Input Editing
| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Go to line start |
| `Ctrl+E` | Go to line end |
| `Ctrl+H` | Delete previous character |
| `Ctrl+W` | Delete previous word |
| `Ctrl+U` | Delete from cursor to beginning of line |
| `Ctrl+K` | Delete from cursor to end of line |
| `Meta+←/→` | Move cursor by word |
| `Ctrl+G` | Edit prompt in `$EDITOR` |
| `Tab` | Autocomplete file path (after `@`) |

---

## 10. Launch-Time CLI Flags — Full Reference

These flags are passed when launching `copilot` from the terminal. They cannot be changed mid-session (use slash commands instead).

### Core Launch Flags

| Flag | Description |
|------|-------------|
| `copilot` | Start interactive session in current directory |
| `-p "<prompt>"` / `--prompt "<prompt>"` | Programmatic mode — run one prompt and exit |
| `--agent=<name>` | Start session with a specific custom agent |
| `--banner` | Show the animated splash banner on launch |
| `--experimental` | Enable experimental features (persisted to config) |
| `--config-dir <path>` | Override config directory (takes precedence over `COPILOT_HOME`) |

### Session Continuation

| Flag | Description |
|------|-------------|
| `--resume` | Pick a past session to resume (interactive list) |
| `--continue` | Resume the most recently closed local session |

### Tool Permissions

| Flag | Description |
|------|-------------|
| `--allow-all-tools` | Allow Copilot to use any tool without asking |
| `--allow-tool='shell(<cmd>)'` | Allow a specific shell command (e.g. `shell(mvn)`) |
| `--allow-tool='shell(git <sub>)'` | Allow a specific git subcommand (e.g. `shell(git commit)`) |
| `--allow-tool='write'` | Allow all file-write operations without asking |
| `--allow-tool='<MCP-SERVER>'` | Allow all tools from a named MCP server |
| `--allow-tool='<MCP-SERVER>(<tool>)'` | Allow a specific tool from an MCP server |
| `--deny-tool='shell(<cmd>)'` | Block a specific shell command (e.g. `shell(rm)`) |
| `--deny-tool='shell(git push)'` | Block `git push` |
| `--deny-tool='<MCP-SERVER>(<tool>)'` | Block a specific MCP server tool |
| `--available-tools='<list>'` | Restrict Copilot to **only** these tools |

> `--deny-tool` always takes precedence over `--allow-tool` and `--allow-all-tools`.

**Combining flags (common patterns):**
```bash
# Allow everything except destructive commands
copilot --allow-all-tools \
        --deny-tool='shell(rm)' \
        --deny-tool='shell(git push)' \
        --deny-tool='shell(git reset)'

# Allow only Maven and file writes — nothing else
copilot --allow-tool='shell(mvn)' \
        --allow-tool='write'

# Allow all tools from Atlassian MCP but block creating issues
copilot --allow-tool='atlassian' \
        --deny-tool='atlassian(create_issue)'
```

### Path Permissions

| Flag | Description |
|------|-------------|
| `--allow-all-paths` | Disable path verification — Copilot can access any path |
| `--disallow-temp-dir` | Block access to the system temp directory |

### URL Permissions

| Flag | Description |
|------|-------------|
| `--allow-all-urls` | Disable URL verification — Copilot can access any URL |
| `--allow-url=<domain>` | Pre-approve a specific domain (e.g. `--allow-url=github.com`) |
| `--deny-url=<domain>` | Block a specific domain |

> HTTP and HTTPS are treated as separate protocols — approve both if needed.

### Combined Permission Shortcut

| Flag | Equivalent To | Alias |
|------|-------------|-------|
| `--allow-all` | `--allow-all-tools` + `--allow-all-paths` + `--allow-all-urls` | `--yolo` |

### Programmatic Usage Examples

```bash
# Simple one-shot task, exit on completion
copilot -p "Summarise the last 10 commits"

# Allow specific tools for a CI pipeline step
copilot -p "Run tests and fix compilation errors" \
        --allow-tool='shell(mvn)' \
        --allow-tool='write' \
        --deny-tool='shell(git push)'

# Use a specific agent in headless mode
copilot --agent=code-review \
        --prompt "Review all changes in src/payment/" \
        --allow-tool='shell(git)'

# Pipe context from a script
./generate-context.sh | copilot

# Maximum autonomy in a sandboxed container
copilot --yolo -p "Implement the feature described in ISSUE.md"
```

---

Switch the active model at any time:
```
/model
```

Default: **Claude Sonnet 4.5**. Other available models: Claude Sonnet 4, GPT-5, and others shown in the `/model` picker.

Each prompt consumes one **premium request** from your monthly quota.  
View quota usage: `/usage`

---

## 11. Session Continuity

```bash
copilot --resume          # pick from list
copilot --continue        # resume the most recently closed local session
```
Or in-session:
```
/resume <session-id>
```

Share a session:
```
/share                    # choose: Markdown, HTML, or GitHub Gist
```

Remote control:
```
/remote                   # control your session from GitHub web and mobile
```

---

## 12. Context Management

| Tool | Description |
|------|-------------|
| `/context` | Visual overview of current token usage |
| `/usage` | Token breakdown per model, lines edited, premium requests used |
| `/compact` | Manually compress history to free context space |

> **Auto-compact**: CLI automatically compresses history at 95% token limit without interrupting your workflow.

---

## 13. Custom Instructions

Copilot auto-loads instructions from these locations (in precedence order):

| File / Pattern | Scope |
|----------------|-------|
| `AGENTS.md` (git root & cwd) | Repository-wide |
| `CLAUDE.md` | Repository-wide |
| `GEMINI.md` | Repository-wide |
| `.github/copilot-instructions.md` | Repository-wide |
| `.github/instructions/**/*.instructions.md` | Path-specific |
| `~/.copilot/copilot-instructions.md` | User-wide (all projects) |
| `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | Additional env-var directories |

> All matching instruction files are **combined**, not overridden by precedence.

Initialise instructions for a repo:
```
/init
```

View active instructions:
```
/instructions
```

### Path-Specific Instructions Example
`.github/instructions/java.instructions.md`:
```markdown
---
applyTo: '**/*.java'
---
Always use constructor injection. Never use field-level @Autowired.
Follow Mastercard PGS copyright header conventions.
```

---

## 14. Custom Agents

### Built-in Agents

| Agent | Description |
|-------|-------------|
| `explore` | Fast codebase analysis without consuming main context |
| `task` | Execute builds/tests; brief on success, full output on failure |
| `general-purpose` | Complex multi-step tasks in a separate context window |
| `code-review` | High-signal code review, surfaces only genuine issues |

### Using Custom Agents

```
/agent                                          # interactive picker
Use the security agent to scan the auth module  # natural language
copilot --agent=code-review --prompt "Review src/payment/"  # flag
```

### Agent File Locations

| Level | Location | Scope |
|-------|----------|-------|
| User | `~/.copilot/agents/` | All projects |
| Repository | `.github/agents/` | Current project |
| Org/Enterprise | `/agents/` in `.github-private` repo | All org projects |

> **Precedence**: System > Repository > Organisation

### Agent File Format
```markdown
---
name: security-auditor
description: Performs OWASP-aligned security review of Java files
tools:
  - read_file
  - grep_search
---
You are a security expert specialising in OWASP Top 10...
```

---

## 15. Skills

Skills extend Copilot's specialised abilities with instructions, scripts, and resources.

```
/skills
```

Skills live in `.github/skills/` or `~/.copilot/skills/`. Each skill is a directory containing a `SKILL.md` descriptor with YAML frontmatter and rule content.

---

## 16. Language Server Protocol (LSP)

LSP enables go-to-definition, hover info, and diagnostics inside the CLI.

### Install a Language Server
```bash
npm install -g typescript-language-server   # TypeScript
pip install python-lsp-server               # Python
```

### Configure

**User-level** (`~/.copilot/lsp-config.json`) or **repo-level** (`.github/lsp.json`):
```json
{
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "fileExtensions": {
        ".ts": "typescript",
        ".tsx": "typescript"
      }
    }
  }
}
```

View LSP status:
```
/lsp
```

---

## 17. Configuration

### Config Directory Structure (`~/.copilot/`)

| Path | Type | Description |
|------|------|-------------|
| `config.json` | File | Personal configuration settings |
| `mcp-config.json` | File | User-level MCP server definitions |
| `permissions-config.json` | File | Saved tool & directory permissions per project |
| `agents/` | Directory | Personal custom agent `.agent.md` files |
| `skills/` | Directory | Personal custom skill directories |
| `hooks/` | Directory | User-level hook scripts |
| `logs/` | Directory | Session log files |
| `session-state/` | Directory | Session history and workspace data |
| `session-store.db` | File | SQLite — cross-session data |
| `installed-plugins/` | Directory | Installed plugin files |
| `ide/` | Directory | IDE integration state |

### `config.json` Settings Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `model` | string | `"claude-sonnet-4.5"` | AI model ID |
| `effortLevel` | string | — | `"low"`, `"medium"`, `"high"` |
| `theme` | string | `"auto"` | `"auto"`, `"dark"`, `"light"` |
| `mouse` | boolean | `true` | Enable mouse support |
| `banner` | string | `"once"` | `"always"`, `"once"`, `"never"` |
| `renderMarkdown` | boolean | `true` | Render Markdown in responses |
| `screenReader` | boolean | `false` | Screen reader optimisations |
| `autoUpdate` | boolean | `true` | Auto-download CLI updates |
| `stream` | boolean | `true` | Stream responses token by token |
| `includeCoAuthoredBy` | boolean | `true` | Add `Co-authored-by:` to agent commits |
| `respectGitignore` | boolean | `true` | Exclude gitignored files from `@` picker |
| `trusted_folders` | string[] | `[]` | Permanently trusted folder paths |
| `allowed_urls` | string[] | `[]` | Pre-approved URL domains |
| `denied_urls` | string[] | `[]` | Always-blocked URL domains |
| `logLevel` | string | `"default"` | `"none"` `"error"` `"warning"` `"info"` `"debug"` `"all"` |
| `disableAllHooks` | boolean | `false` | Disable all lifecycle hooks |
| `hooks` | object | `{}` | Inline hook definitions |

**Example `config.json`:**
```jsonc
{
  "model": "claude-sonnet-4.6",
  "effortLevel": "high",
  "theme": "dark",
  "autoUpdate": true,
  "renderMarkdown": true,
  "trusted_folders": ["/Users/me/projects/myapp"],
  "allowed_urls": ["github.com", "api.mycompany.com"],
  "logLevel": "warning"
}
```

### Key Environment Variables

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | GitHub PAT (highest precedence) |
| `GITHUB_TOKEN` | GitHub PAT (fallback) |
| `COPILOT_HOME` | Override default `~/.copilot` directory |
| `COPILOT_CACHE_HOME` | Override cache directory separately |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | Additional instruction directories |

### Terminal Help Commands

```bash
copilot help config        # all config.json settings
copilot help environment   # all environment variables
copilot help logging       # logging levels
copilot help permissions   # permission flags reference
```

---

## 18. Experimental Mode & Autopilot

```bash
copilot --experimental    # enable at launch (persisted to config)
/experimental             # toggle in-session
```

**Autopilot**: press **Shift+Tab** twice to cycle into Autopilot mode — agent works to completion without per-step approval.

---

## 19. Delegating Work to the Cloud

```
/delegate
```
Sends the current session task to a GitHub cloud agent which creates a PR. Resume locally:
```bash
copilot --resume
```

---

## 20. Working Directory Management

```bash
/cwd                      # show current directory
/cwd /path/to/project     # change directory without restarting
/add-dir /other/path      # add another trusted directory
/list-dirs                # see all trusted directories
```

---

## 21. Help, Feedback & Updates

```
/help
/changelog [summarize]
/feedback
/update
/version
```

---

## 22. Quick Reference Card

```
copilot                        Start CLI in current directory
copilot --continue             Resume last session
copilot --allow-all-tools      Start with all permissions enabled
copilot --experimental         Start with experimental features
copilot -p "..." --allow-tool='shell(mvn)'   Programmatic / headless

@file.txt                      Include file in prompt
#42                            Reference issue/PR #42
!git status                    Run shell command directly

Shift+Tab                      Cycle modes (Normal → Plan → Autopilot)
Ctrl+C                         Cancel current operation
Ctrl+C × 2                    Exit
Esc                            Cancel / reject tool approval
Ctrl+T                         Toggle reasoning visibility
```

---

## 23. Real-World Usage Scenarios

### Scenario 1 — Fix a Bug From a GitHub Issue
```
I've been assigned this issue: https://github.com/org/repo/issues/1234.
Start working on it for me in a suitably named branch.
```

### Scenario 2 — Create a PR End-to-End
```
Add a health-check.js script that pings all service endpoints.
Create a pull request to add it to the repo on GitHub.
```

### Scenario 3 — Summarise This Week's Work
```
Show me this week's commits and summarise them for a status update
```

### Scenario 4 — Programmatic / Headless (CI-Friendly)
```bash
copilot -p "Run all tests and fix any compilation errors" \
        --allow-tool='shell(mvn)' \
        --deny-tool='shell(git push)'
```

### Scenario 5 — Pipe Options From a Script
```bash
./build-context.sh | copilot
```

### Scenario 6 — Code Review on a PR
```
Check the changes in PR https://github.com/org/repo/pull/57. Report any serious errors.
```
Or:
```
/review
```

### Scenario 7 — Multi-Step Feature (Plan Mode)
Press **Shift+Tab**, then:
```
Add rate limiting to the /payments endpoint using Resilience4j.
Include unit tests and update the OpenAPI spec.
```

### Scenario 8 — Scaffold a New App
```
Use create-next-app and Tailwind CSS to create a dashboard that tracks
build success rate and test pass rate from the GitHub API.
```

### Scenario 9 — Git Operations via Natural Language
```
Commit the changes to this repo with a conventional commit message
Revert the last commit, leaving the changes unstaged
Merge all open PRs I've created in org/repo
```

### Scenario 10 — Find Good First Issues for Onboarding
```
Use the GitHub MCP server to find good first issues for a new team member from org/repo
```

### Scenario 11 — Create a GitHub Actions Workflow
```
Create a GitHub Actions workflow that runs eslint on PRs, annotates errors
in the diff view, and fails the check if errors are found. Push to a new branch and create a PR.
```

### Scenario 12 — Autopilot for a Complete Migration Task
Enable experimental mode, switch to Autopilot (**Shift+Tab** × 2), then:
```
Migrate all usages of RestTemplate in this codebase to WebClient.
Run tests after each file change. Stop if tests fail.
```

---

## 24. MCP Server Integration (Deep Dive)

### What Is MCP?

**Model Context Protocol (MCP)** is an open standard that lets AI models securely connect to external data sources and tools. In Copilot CLI it means you can give the agent access to Jira, Sentry, Notion, Azure, Databases — anything with an MCP server.

```
Your Prompt
    │
    ▼
Copilot CLI Agent
    │
    ├── GitHub MCP (built-in) ──► GitHub.com: PRs, Issues, Actions
    ├── Your MCP Server A      ──► Jira / Confluence
    ├── Your MCP Server B      ──► Sentry / DataDog
    └── Your MCP Server C      ──► Internal API / Database
```

### Managing MCP Servers In-Session

```
/mcp               # List configured servers and their status
/mcp add           # Add a new server interactively (Tab between fields, Ctrl+S to save)
/env               # Show all loaded MCP servers + their tools
```

### MCP Configuration File

Default: `~/.copilot/mcp-config.json` | Override: `export COPILOT_HOME=/your/path`

```json
{
  "mcpServers": {
    "<server-name>": {
      "type": "local | stdio | http | sse",
      "command": "<executable>",
      "args": ["<arg1>", "<arg2>"],
      "tools": ["tool_a", "tool_b"],
      "env": {
        "API_KEY": "$COPILOT_MCP_MY_API_KEY"
      }
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | ✅ | `local`/`stdio` for process-based; `http`/`sse` for remote |
| `command` | ✅ local | Executable to launch the server |
| `args` | ✅ local | Arguments passed to `command` |
| `url` | ✅ remote | URL for `http`/`sse` server |
| `tools` | ✅ | Allowlisted tools — use `["*"]` for all |
| `env` | Optional | Env vars (use `COPILOT_MCP_` prefix for secrets) |
| `headers` | Optional | HTTP headers for remote servers |

### Variable Substitution

Secrets must have names prefixed `COPILOT_MCP_`:

| Syntax | Example |
|--------|---------|
| `$VAR` | `$COPILOT_MCP_API_KEY` |
| `${VAR}` | `${COPILOT_MCP_API_KEY}` |
| `${VAR:-default}` | `${COPILOT_MCP_KEY:-fallback}` |

### Ready-to-Use MCP Server Examples

#### GitHub (Built-in — no setup needed)
Pre-configured. Enables PR management, issue search, Actions queries.

#### Atlassian (Jira + Confluence)
```json
{
  "mcpServers": {
    "atlassian": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-server"],
      "tools": ["get_issue", "search_issues", "create_issue", "get_page"],
      "env": {
        "ATLASSIAN_API_TOKEN": "$COPILOT_MCP_ATLASSIAN_API_TOKEN",
        "ATLASSIAN_BASE_URL": "https://yourorg.atlassian.net"
      }
    }
  }
}
```
**Usage:** `List all open Jira bugs assigned to me in project G1198`

#### Sentry (Error Monitoring)
```json
{
  "mcpServers": {
    "sentry": {
      "type": "local",
      "command": "npx",
      "args": ["@sentry/mcp-server@latest", "--host=$SENTRY_HOST"],
      "tools": ["get_issue_details", "get_issue_summary"],
      "env": {
        "SENTRY_HOST": "https://yourorg.sentry.io",
        "SENTRY_ACCESS_TOKEN": "$COPILOT_MCP_SENTRY_ACCESS_TOKEN"
      }
    }
  }
}
```
**Usage:** `Show me the top 5 unresolved Sentry errors from the last 24 hours`

#### Azure (Cloud Resources)
```json
{
  "mcpServers": {
    "azure": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "tools": ["*"]
    }
  }
}
```

#### Cloudflare (Remote / SSE)
```json
{
  "mcpServers": {
    "cloudflare": {
      "type": "sse",
      "url": "https://docs.mcp.cloudflare.com/sse",
      "tools": ["*"]
    }
  }
}
```

#### Custom Internal API
```json
{
  "mcpServers": {
    "internal-payments-api": {
      "type": "http",
      "url": "https://api.internal.yourcompany.com/mcp",
      "headers": {
        "Authorization": "Bearer $COPILOT_MCP_INTERNAL_TOKEN"
      },
      "tools": ["get_transaction", "list_settlements", "search_disputes"]
    }
  }
}
```

### Controlling MCP Tool Permissions

```bash
copilot --allow-tool='atlassian'                              # allow all tools from server
copilot --deny-tool='atlassian(create_issue)'                 # block specific tool
copilot --allow-all-tools --deny-tool='shell(rm)'             # allow all except rm
copilot --allow-tool='My-MCP-Server' --deny-tool='My-MCP-Server(delete_record)'
```

> ⚠️ MCP tools run **without per-call approval** once allowed. Only allowlist tools you need — avoid `["*"]` for write-access servers.

---

## 25. ACP (Agent Communication Protocol) — Multi-Agent Coordination

**ACP** is an emerging open standard for agent-to-agent communication. In Copilot CLI, multi-agent coordination is achieved through these patterns today:

### Pattern A — Fleet Mode (Parallel Sub-agents)
```
/fleet
```
Launches multiple Copilot sub-agents in parallel — e.g. one reviews security, one writes tests, one updates docs.

### Pattern B — Custom Agent Delegation (Sequential)
```
Use the planning agent to analyse the requirements for story G1198-123,
then use the code-development agent to implement the plan.
```

### Pattern C — Delegate to Cloud Agent (`/delegate`)
```
/delegate
```
Hands task to a GitHub-hosted cloud agent asynchronously. You receive a PR on completion. Resume locally:
```bash
copilot --resume
```

### Pattern D — Programmatic Agent Chaining (Shell Script)
```bash
#!/bin/bash
# Chain agents sequentially via programmatic mode
copilot --agent=planning \
        --prompt "Analyse story G1198-123 and write plan.md" \
        --allow-tool='write' > /dev/null

copilot --agent=code-development \
        --prompt "Implement the plan in plan.md" \
        --allow-tool='shell(mvn)' \
        --allow-tool='write' \
        --deny-tool='shell(git push)'
```

---

## 26. Security Best Practices

| Practice | Why |
|----------|-----|
| Never launch from `~/` (home dir) | Exposes all personal files to Copilot's read access |
| Use `--deny-tool='shell(rm)'` in automation | Prevents accidental file deletion in headless mode |
| Scope `tools` arrays tightly (avoid `["*"]` on write servers) | MCP tools run without per-call approval |
| Use `COPILOT_MCP_` prefix for all secrets | Ensures only explicitly prefixed vars are passed to MCP servers |
| Run headless CI in a container | Mitigates risk when using `--allow-all-tools` |
| Review `/diff` before committing | Verify all changes before pushing |

---

*Official documentation: https://docs.github.com/copilot/concepts/agents/about-copilot-cli*  
*MCP integration: https://docs.github.com/copilot/how-tos/use-copilot-agents/cloud-agent/extend-cloud-agent-with-mcp*
