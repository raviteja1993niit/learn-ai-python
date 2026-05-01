# GitHub Copilot CLI — A Complete Guide
> *Based on: YouTube: "GitHub Copilot CLI — DevOps & Platform Engineering Perspective" (AI Command Line Series)*
> *Generated: 2026-04-28 | Audience: Intermediate — DevOps / Platform Engineers*

---

## 🧭 What This Guide Covers

This guide covers the GitHub Copilot CLI from a DevOps and platform engineering perspective — the terminal, where platform engineers actually spend most of their time. You will understand how to install, configure and run Copilot in the terminal; how to use context engineering, agents, skills, plan mode, and MCP; and why these concepts matter not just for this tool, but for any AI CLI you encounter.

> 💬 *"In this AI command line series, I want to cover many of the AI concepts in general using the terminal. Things like context engineering, agents, skills, planning mode, and MCP. These are the practical skills that engineers need right now."*

---

## 💡 The Big Picture

AI coding assistants have moved beyond the browser and the IDE. The terminal is where platform engineers actually live — it has direct access to your files, workspace, executables, local Kubernetes clusters, Docker engines and CI/CD pipelines. The GitHub Copilot CLI brings an AI agent directly into that environment.

> 💬 *"It is better to run AI in the command line. It has direct access to your files in your workspace. But not only that, it has access to executables running on your machine as well."*

The deeper insight the narrator draws throughout is that every CLI concept — agents, skills, context windows, MCP, plan mode — is not Copilot-specific. These are open standards that apply to Gemini CLI, Claude, OpenCode and any AI tool that follows them. The goal is to become **tool-agnostic**: learn the concepts once and carry them everywhere.

---

## 📚 Core Concepts

### What GitHub Copilot CLI Is

Copilot is an AI product by GitHub that runs everywhere — your IDE (VS Code), the GitHub platform itself, and importantly, your terminal. The CLI is essentially the **main agent**: a program that takes your prompts, manages your discussion and context window, and acts as a proxy to the underlying model (defaulting to Claude Haiku on the free tier).

> 💬 *"The CLI program is just an agent. An agent is a program that takes our prompts and passes it to the model. It manages our discussion and context window."*

**Why this matters:** Understanding the CLI as just an agent unlocks the entire mental model — agents, sub-agents, context windows, system prompts and skills all follow from this single framing.

### The Context Window

The context window is the model's **short-term memory** — the full conversation history sent to the model on every request. As you chat, the oldest prompts leave the context window first when it fills up.

> 💬 *"The longer you talk and the bigger the discussion, the more info actually gets lost. At the same time, the bigger the context window, the less accurate the model can be."*

You can inspect live context window usage with `/context`. This shows the model in use, token usage, loaded system prompts, tools, messages, free space and a visual buffer indicator. Every other advanced feature in Copilot exists to optimise what lives in this window.

**Why this matters:** Context engineering is the unifying concept. Agents, skills, init mode, plan mode and MCP are all mechanisms to get the right information into context at the right time, and keep noise out.

### Context Engineering and Init Mode

Context engineering is the practice of shaping the context window to give the model focus, accuracy and consistency — while wasting as few tokens as possible. The primary tool is the **system prompt**.

> 💬 *"Instead of having back and forth prompts, we can create a system prompt which guides the model. It gives the model some focus, guidance about any standards and conventions, tells the model what the repo is about without us having to go back and forth."*

The `/init` command analyses your repository — exploring structure, README files, conventions and architecture — and generates a `copilot-instructions.md` file under `.github/`. This file is auto-loaded into context every session, so any AI agent opening your repo immediately understands it.

The narrator also introduces `agents.md` as an **open standard** — a single readme-for-agents file readable by Gemini CLI (`gemini.md`), Claude (`claude.md`) and Copilot (`copilot-instructions.md`). One file, all tools, true tool-agnosticism.

### Agents and Sub-Agents

The CLI is the **main agent**. Custom **sub-agents** can be defined to specialise in a domain (Kubernetes, Terraform, DevOps). Each sub-agent gets its own system prompt and its own context window.

> 💬 *"Each agent can have its own system prompts which means it can be guided and focused. So if we ask our CLI agent here for a question about Kubernetes, it can direct and guide that prompt to a Kubernetes agent."*

The Kubernetes agent does not need the full repo readme — it receives only a tailored instruction set. This achieves three things simultaneously: less context pollution, more focused responses, and lower token costs.

Agents are defined as markdown files under `.github/agents/` (repo-scoped) or `~/.copilot/agents/` (user-scoped). The filename is the agent name. The YAML frontmatter provides `name` and `description`; everything below `---` is the system prompt.

### Agent Skills

Skills are **modular capability files** for agents. Instead of loading one giant agent markdown file entirely into context on every request, skills are only loaded when activated.

> 💬 *"Instead of jamming every single capability of my agent into one giant MD file and loading all of it into the context, I can divide it up and having a skill as a file."*

A skill is a folder containing a `SKILL.md` file (must be uppercase, never `skills.md`). The SKILL.md has a YAML header with `name` and `description`. Only the metadata loads at startup — the body loads only when the skill is activated.

Skills can also bundle **scripts and resources**. The narrator's Kubernetes provisioning skill includes pre-tested shell scripts for installing `kubectl`, `kind`, `docker` and `curl` and creating a cluster. This means the LLM never has to guess OS-specific commands or package versions — it just runs the scripts. The result: a predictable, repeatable outcome every time.

### Model Context Protocol (MCP)

MCP lets you interact with external systems using natural language instead of raw CLI syntax.

> 💬 *"Rather than saying kubectl get pods or select star from database and writing syntax in the command line, we can just use natural English to say show me all the pods in the default namespace."*

From a platform engineering perspective, an MCP server is just a library — an executable. It can run locally, be deployed behind a web server, hosted in a Kubernetes cluster, or fronted by a gateway API. It is effectively an API that AI agents call, which means **you need to think about web security** when hosting MCP servers.

MCP servers are added via `/mcp add` and stored in `~/.copilot/config.json` under a `mcpServers` section. Thousands of community MCP servers exist for cloud platforms, databases and developer tools.

### Plan Mode

By default, when you give Copilot a task it immediately attempts a solution — making assumptions, filling up the context window and potentially implementing the wrong approach before you have a chance to steer.

> 💬 *"Getting to this point means you have got to waste a lot of tokens and fill up the context window unnecessarily. This increases cost. This is why Copilot and many of these AI CLIs have a plan mode which allows you to plan before you build and steer as you go."*

Enter plan mode with `/plan <prompt>`. Copilot collaboratively works through the approach, catches misunderstandings early, and outputs a markdown plan file. You then exit plan mode and hand the plan back for implementation. You can also **switch models** between planning and implementation — use an expensive reasoning model to plan and a cheaper one to build.

---

## ⚙️ How It Works — Under the Hood

When Copilot starts, it loads into the context window in this order:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        CONTEXT WINDOW                           │
│  [System Prompt]  [Tool Definitions]  [Messages]  [Free Space]  │
└─────────────────────────────────────────────────────────────────┘
         ↕  proxied to the underlying model (e.g. Claude Haiku)
┌───────────────────────────────────────────────────────┐
│              Main Agent (Copilot CLI)                 │
│  ┌──────────────────┐   ┌────────────────────────┐    │
│  │  Kubernetes Agent │   │   Technical Writer      │    │
│  │  (own context)   │   │   Agent (own context)   │    │
│  └──────────────────┘   └────────────────────────┘    │
└───────────────────────────────────────────────────────┘
         ↕  tool calls via MCP
┌──────────────────────────────────────────────────────┐
│  MCP Servers  (kubectl, postgres, GitHub API, ...)   │
└──────────────────────────────────────────────────────┘
```

The agent routes incoming prompts to the relevant sub-agent based on the sub-agent's `description` field. This delegation is **automatic** — you do not need to explicitly invoke the agent if your prompt matches its description clearly enough.

Skills sit outside this hierarchy. They are loaded on-demand by agents when the activation trigger in the skill's `description` matches the task at hand. Scripts bundled inside skills are never loaded into context — only the skill metadata and instructions are.

---

## 🔧 Practical Usage & Implementation

### Installation

```bash
# npm — all platforms
npm install -g @github/copilot-cli

# winget — Windows
winget install GitHub.CopilotCLI

# Homebrew — Mac / Linux
brew install gh-copilot

# Portable Docker container (no install)
docker run -it --rm -v ~/.copilot:/root/.copilot ghcr.io/github/copilot-cli
```

The CLI releases are also available as static binaries on the GitHub Releases page — download, extract to `/usr/local/bin`, and `chmod +x`.

### Key Commands Reference

| Command | What It Does |
|---------|-------------|
| `copilot --help` | List all options and commands |
| `/login` | Sign in with GitHub account |
| `/logout` | Sign out |
| `/models` | Browse and select available models |
| `/context` | View live token usage and context contents |
| `/init` | Analyse repo and generate `copilot-instructions.md` |
| `/agent <name>` | Invoke a custom sub-agent interactively |
| `/skills list` | List loaded skills |
| `/skills reload` | Reload skills after adding new files |
| `/plan <prompt>` | Enter collaborative planning mode |
| `/mcp add` | Register a new MCP server |
| `/resume` | Resume a past conversation by session ID |
| `/theme` | Switch UI colour theme |
| `!<command>` | Run a shell command in shell mode without leaving Copilot |

### Referencing Files in Context

```text
Is this Kubernetes manifest valid? @manifests/deployment.yaml
```

Type `@` and autocomplete shows matching files from your working directory. The file content is read by the CLI tool and added to context inline.

### Creating a Custom Agent

```yaml
---
name: kubernetes-agent
description: >-
  Specialist in Kubernetes tasks. Use when asked about cluster management,
  manifests, deployments, scaling or kubectl syntax.
tools:
  - read_file
  - run_command
---

You are a Kubernetes operations specialist. Prioritise production-safe
kubectl syntax and best practices. Always verify resource existence
before modifying.
```

Save this as `.github/agents/kubernetes-agent.md`. Invoke with `/agent kubernetes-agent` or let Copilot auto-delegate based on the description.

### Creating a Skill with Bundled Scripts

```
.github/agents/k8s-provisioner/
├── SKILL.md
└── scripts/
    ├── install-kubectl.sh
    ├── install-kind.sh
    ├── install-docker.sh
    └── create-cluster.sh
```

```yaml
---
name: k8s-provisioner
description: >-
  Use this skill to provision a local Kubernetes cluster.
  Activate when the user asks to set up, create or provision a local cluster.
---

## Prerequisites
Required tools: curl, kind, kubectl, docker CLI.
If any tool is missing, use the provided install scripts from the scripts/ folder.
Do NOT attempt to install tools using apt, brew or any package manager directly.

## Steps
1. Check installed versions using the shell tool
2. Install missing tools by running the relevant scripts/install-*.sh
3. Create the cluster: scripts/create-cluster.sh
4. Verify: kubectl get nodes
```

### Configuring MCP Servers

```json
{
  "mcpServers": {
    "kubernetes": {
      "type": "local",
      "command": "node /usr/local/lib/node_modules/mcp-server-kubernetes/index.js"
    },
    "remote-api": {
      "type": "http",
      "url": "https://mcp.internal.company.com"
    }
  }
}
```

Config lives at `~/.copilot/config.json`. Add via `/mcp add` or edit directly.

---

## ⚠️ Gotchas & Common Mistakes

| Gotcha | Why It Happens | Narrator's Advice |
|--------|---------------|-------------------|
| **Filling context with repeated back-and-forth prompts** | Every message consumes tokens; oldest messages drop out first | Run `/init` before starting work — the system prompt replaces repetitive explanation |
| **Putting all capabilities in one giant agent markdown file** | Feels organised but loads every instruction on every request | Split into skills — only the activated skill's content loads |
| **Skipping plan mode on complex tasks** | Agent immediately implements and makes wrong assumptions | Use `/plan` first; agree on tech stack and approach before any code is written |
| **Vague or missing skill `description`** | Agent cannot decide when to activate the skill | Write an explicit trigger: "Use this when asked to provision a local Kubernetes cluster" |
| **Putting the activation trigger in the skill body, not the YAML** | The body only loads after activation — never read at decision time | Always place the activation description in the YAML frontmatter `description` field |
| **Letting the LLM generate shell commands on the fly** | Model may produce outdated or OS-wrong syntax | Bundle pre-tested scripts in the skill `scripts/` folder; the LLM runs them, not invents them |
| **Burning free-tier requests on exploration** | 50 agent/chat requests per month goes fast | Use `/plan` and skills to reduce turns; use cheaper models during implementation |
| **Hosting MCP servers without security consideration** | MCP servers are just web APIs — easy to overlook | Apply gateway API, ingress, and authentication before exposing MCP servers |

---

## 🔗 How It Connects to Other Concepts

The narrator explicitly frames this entire video as being about **AI CLI concepts** — not just Copilot:

- **Context engineering** is the master concept. Agents, skills, init mode, plan mode and MCP are all mechanisms to control what goes into the context window and when.
- **`agents.md`** is an open standard. Gemini uses `gemini.md`, Claude uses `claude.md`, Copilot uses `copilot-instructions.md`. One `agents.md` file works across all tools.
- **MCP** is a protocol, not a product. Claude Desktop, Gemini CLI, Cursor and Copilot can all connect to the same MCP server.
- **Skills** follow the same open SKILL.md format adopted by multiple CLIs — not a GitHub-exclusive feature.
- **Plan mode** exists in Gemini CLI, Claude and others under different names. The concept is universal: separate reasoning from execution.

> 💬 *"Context engineering is all about optimizing the context to give our agent more focus and accuracy and consistency."*

---

## 🎯 Key Takeaways

- **The CLI is just an agent.** Everything else — context windows, sub-agents, skills, MCP — follows from this.
- **Context engineering is everything.** Every advanced feature exists to control what goes into the context window.
- **Use `/init` before you start work** on any repository. One system prompt replaces dozens of repeated explanations.
- **Skills are not just instructions — they are scripts.** Pre-tested scripts give predictable, OS-safe, version-correct outcomes that the LLM cannot guess.
- **Plan before you build.** Use `/plan` to align on approach before the agent writes a line of code — it saves tokens, time and frustration.
- **MCP = natural language API gateway.** Interact with Kubernetes, databases and cloud APIs in plain English — but host MCP servers with the same security mindset as any web API.
- **Learn once, apply everywhere.** The free tier is enough. The concepts carry to Gemini, Claude, OpenCode and any future AI CLI.

---

## 📖 Narrator's Own Words

> *"AI and coding assistants are everywhere right now. From chat bots in the browser to code assistants in the code editor, but what about the terminal? This is where platform engineers actually spend most of their time."*

> *"If you are crazy like me, you can just build a Docker file, use something like curl, and then just use curl to download the tar file directly from the GitHub releases page, extract it to use a local bin, give it chod execution permission, and run it in a Docker container."*

> *"The longer you talk and the bigger the discussion, the more info actually gets lost. At the same time, the bigger the context window, the less accurate the model can be. So context engineering is quite a topic to get into."*

> *"Skills are only loaded when they are needed. So if I am using my agent to purely work on a guide, I do not need to add all of the instructions on spinning up a Kubernetes cluster. And that helps me save the context window and save token usage."*

> *"The LLM does not have to guess what operating system I am running. Maybe it gets an outdated command, maybe it gives me an outdated version of Docker. Whereas these scripts are fixed and they have been tested. This means my agent will behave in a predictable precise way and give me a fixed outcome every time."*

---

*Guide synthesised from: YouTube: "GitHub Copilot CLI — DevOps & Platform Engineering Perspective" | Agent: transcript-guide v1.0.0 | Validated: 2026-04-28*
