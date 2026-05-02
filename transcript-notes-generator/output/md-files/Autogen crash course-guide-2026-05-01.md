# Autogen Crash Course — A Complete Guide

## Overview & Course Scope
---
### Course frame and goals
This guide synthesizes Mika Aarval’s 12-part Autogen crash course: "This tutorial is your ticket to mastering agentic AI with Autogen." The course covers (1–12): Installation; first Autogen agent (“hello world”); architecture deep dive; agent kinds; configure models / give the “brain” to agents; multimodal output; agent collaboration/teams; termination conditions & human-in-the-loop; tools; Autogen Studio GUI; end-to-end project (backend Autogen + frontend search/RF library); wrap-up/deployment.

> 💬 *"I'm absolutely thrilled to welcome you all into this Autogen crash course where we are going to dive deep into the world of Autogen."*

> 💬 *"By the end of this video, you will be able to build your own AI agents, automate your workflow like a pro, and also integrate them into your application with confidence."*

### Who this is for
- Developers who want to build agentic AI systems using Autogen v4+.
- Engineers who prefer a framework (code-first) over drag-and-drop tools.
- Teams building multi-agent orchestration, tool-enabled workflows, or multimodal agents.

> 💬 *"Do make sure to like this video share it with everyone whoever is going to start the journey in the AI world because I believe this is a proper uh way of getting it by mastering a framework instead of any drag and drop tool."*

---

## What Autogen Is & Versioning
---
### Core idea
Autogen is a Microsoft-origin framework for building agentic AI and AI automation — "think of agents as a digital human and nothing else." It has gained wide popularity (45K+ stars on GitHub).

> 💬 *"Autogen is here to stay and it has been gaining a lot of popularity with more than 45,000 plus stars on GitHub."*

### Versioning and related projects
- autogen.4 (v4+) is the maintained, recommended line: "autogen.4 is a framework for building multi-agent AI system with asynchronous eventdriven architecture."
- There is no v3. AG2 is a separate project (not affiliated): "This is the official project. We are not affiliated ... AG2 and Autogen now they are not related to each other."

### Packaging (modern split)
Modern Autogen is split into packages rather than a single pyautogen. The recommended installation pattern uses:
- autogen-agent-chat
- autogen-core
- autogen-ext

> 💬 *"Now the way to explain a way to install the same is by using this agent chat uh module of autogen."*

---

## Installation & Environment Setup
---
### Quick-start commands (verbatim as spoken)
Use a dedicated virtual environment and select it in your IDE / Jupyter kernel.

```bash
python - m v env autogen crash course
```

(Activate the venv in your shell; the speaker said: “I have activated this particular environment”.)

Use a requirements file and install:

```bash
pip install -r requirements
```

Correct package install phrasing (spoken):

> 💬 *"So I will do pip install agent chat uh sorry autogen agent chat right."*

### What NOT to do (examples of outdated/wrong installs)
Do NOT use old pyautogen imports or single-package installs — these are wrong/outdated and still appear in some examples:

```bash
# WRONG / outdated - do NOT use
pip install py autogen
# and the code that goes along with it (example import shown in old tutorials):
# from autogen import assistant agent user proxy agent
```

> 💬 *"Now this is what I wanted to show you. Since this is very new ... you will see this pip install py autogen and you will see from autogen import assistant agent user proxy agent. Well this is totally wrong right?"*

### Jupyter / kernel tips
- Select the correct kernel (named e.g., "autogen crash course").
- You may need to install ipykernel if using notebooks: the speaker said "I will have to install the IPY kernel".
- Notebooks can have issues running some async flows — the presenter avoided running some async demo code in Jupyter.

### API keys & secrets
- Load API keys from environment (.env) instead of embedding them in code: “always remember this API key is something which is needed.”
- OpenRouter: copy the API key immediately after creating it — “it will be gone if I don't copy it. You won't be able to see it again.”

---

## Architecture & Asynchronous Event-Driven Model
---
### Layered architecture (bottom → top)
- Core: asynchronous event-driven core; actor-like; base agent class.
- Agent Chat: high-level API; "agent chat is the recommended starting point"; handles ~80–90% of use cases.
- Extensions: plugins for external tools, model clients and connectors (OpenAI, Anthropic, Azure, Ollama, etc.).
- Developer tools: Studio (UI prototyping) and Bench (testing/building tool).

> 💬 *"agent chat is the recommended starting point."*  
> 💬 *"it is built on top of autogen core."*

### Asynchronous philosophy
- Autogen v4 uses an event-driven asynchronous architecture: "With version.4 Four we have we are seeing something known as the eventdriven asynchronous architecture for autogen."
- Use Python 3.10+ and asyncio primitives. Example keywords preserved from the talk:

```python
# spoken keywords / idioms
async def
await asyncio.gather(...)
await agent.run(...)
# streaming:
run_stream / on_message_stream
```

### Synchronous vs Asynchronous analogies (preserved)
- Synchronous = microwave: “this is very akin to how you warm food in microwave.”
- Asynchronous = coffee + bagel parallel example: start both and overlap waiting — reduced total time. “In asynchronous programming when we make a call then we can continue working on the process A as well.”

---

## Agents: Concepts, Types, and API
---
### Agent as "digital human"
- An agent = name + description + brain (model_client) + optional tools + system_message + state.
- "Think of agents as a digital human and nothing else."

> 💬 *"think of agents as a digital human and nothing else."*

### Key attributes
- name: identifier (no spaces allowed as of version 6.1).
- description: optional one-line human-readable ID — "description is not something which agent takes into play when it is doing his job."
- system_prompt / system_message: separate argument used to define behavior/policies — "for that we have a separate overall argument which is known as system prompt."
- model_client / brain: the LLM client you supply. The speaker prefers calling it the "brain":
  > 💬 *"the brain is formerly known as model in autogen and model client is the argument which in which we have to provide which LLM we are going to use."*

- tools: callable integrations (web search, custom functions). In demos they are often mocked; in production they should be real services with safety/logging.
- statefulness: agents are stateful by default — "Agents are stateful by default in autogen and they will remember that." Caller should send only the new message, not the entire history: "you should not send the complete history just send the new message."

### Built-in agent types / presets
- assistant agent (typical, majority of use cases)
- user proxy agent (for human-in-the-loop during-run)
- code executor agent (executes/checks code; more complex to write)
- society-of-mind / inner-team agents (teams-of-agents constructs)
- message filter/conf agent, base chat agent

> 💬 *"assistant agent is not defined. Totally makes sense."*

### Agent runtime methods
- run: synchronous-looking single-call usage (await agent.run(...)) — easier, but production outputs are harder to interpret.
  > 💬 *"run method ... runs the agent given a string or list of messages."*
- run_stream / on_message_stream: streaming / event-driven — returns an iterator of intermediate message events followed by a task result. Recommended for clarity in production/multi-agent flows.
  > 💬 *"run_stream ... returns an iterator of messages that subclass base agent or base chat message followed by a task result."*

Example access patterns (as spoken):

```python
# example usage idioms (verbatim phrases preserved)
await agent.run(...)
# streaming:
async for msg in agent.run_stream(...):
    # handle intermediate events
# message access:
result["messages"][-1]["content"]
# or:
result.messages[-1]
```

---

## Message Types, Event Flow & Tool-Assisted Interactions
---
### Message/event types
- text message
- multimodal/image message (ag_image)
- chat message
- tool message
- task result (signals task concluded)

> 💬 *"task result ... that signals a task was completed/concluded."*

### Typical tool-assisted sequence
1. User text message → 2. Tool call request (agent issues function_call with function_call_id) → 3. Tool execution event (tool returns content) → 4. Tool call summary / Assistant final message.

> 💬 *"This function call ID. This is very important for your uh logging purposes because this ID will be same here as well."*

ASCII diagram of the flow:

```
[User Message]
      |
      v
   [Agent] --(function_call, function_call_id)--> [Tool/Integration]
      |                                              |
      |<-----------(tool execution result)-----------|
      |
      v
[Agent summarizes / task_result] --> [User Final Reply]
```

Practical production note: parse, validate, and log outputs — obtaining an agent response is not the end.

> 💬 *"You must make sense of outputs for production; obtaining an agent response is not the end — parse, validate, and log."*

---

## Tools & Integrations
---
### What tools are
- Tools = "special powers." They are code or APIs that an agent can call to extend capabilities: calculators, web search, HTTP APIs, Python executor, Docker CLI, MCP, LangChain adapters, etc.

> 💬 *"tools are like special powers"*

> 💬 *"A tool can be simple function as an calculator or an API call to a third party service such as stock price lookup."*

### Tool categories
- Custom tools: user-defined functions (e.g., reverse_string)
- Inbuilt tools: Python execution tool, local/global search tools (RAG), Docker CLI executor, MCP server tool (WIP), HTTP tool, LangChain adapter
- Third-party tools: LangChain/community tools (e.g., Serper API)

> 💬 *"function tool class uses description and type annotations to inform the LLM when and how to use a given function."*

### FunctionTool & best practices
- Wrap functions with FunctionTool and include type annotations and docstrings so the LLM understands how/when to use them.
- Use reflect_on_tool_use to have the agent summarize/explain tool outputs rather than just echo them: "reflect on the output which has been given by tool."

### HTTP tool & schema validation
- Configure scheme/host/port/path/method/responseType and a JSON schema for responses (helps LLM and runtime validate).
- Example (note: fields described in transcript; preserved names):

```json
{
  "scheme": "https",
  "host": "catfact.ninja",
  "port": 443,
  "path": "/fact",
  "method": "GET",
  "response_schema": {
    "type": "object",
    "properties": {
      "fact": { "type": "string" },
      "length": { "type": "integer" }
    },
    "required": ["fact", "length"]
  }
}
```

Validation errors commonly seen when schema mismatches:
- "validation error dynamic model fact field missing input value function call"
- "input should be a valid integer"

### Tool call flow (summary)
1. Model decides to call tool (function call).
2. Agent sends focused inputs (not the full user query) to the tool.
3. Tool executes and returns result with same call ID.
4. Agent processes the tool result (optionally reflecting/explaining) and returns final message.

> 💬 *"this is the way it runs"*

---

## Models, Clients & Multimodal Support
---
### Model "brain" options
- Cloud providers: OpenAI GPT‑4, Azure OpenAI, Anthropic / Claude, Google Gemini (via OpenAI compatibility).
- Local hosting: Ollama / local Llama (Llama 3.2 mentioned) and LM Studio GUI for local models (privacy/offline/no-credit-card).
- Gateways: OpenRouter (single key to many providers; free models available but with limits).

> 💬 *"I will be showing you two awesome ways through which you can run it for totally free."*  
> 💬 *"it is totally free and it is uh not asking you for any money"*

### Comparison (hosted vs local vs gateway)
| Hosting option | Pros | Cons |
|---|---:|---|
| Paid cloud LLMs (OpenAI, Anthropic, Azure) | Powerful, reliable multimodal support | Cost; requires API keys |
| Local models (Ollama, LM Studio, Llama) | Private, offline, no cloud cost | Requires capable hardware; port/process issues |
| OpenRouter gateway | One key for many providers; access to free models | Rate limits; free models limited; paid models cost money |

### Multimodal / images
- Autogen supports multimodal inputs: agents/models can accept images (ag_image wrapper) so agents can "see" and describe images: "it should be multimodel input."
- Supported multimodal models (examples): GPT‑4 family, DeepS v3 (via OpenRouter). Do NOT expect multimodal support from smaller models like GPT‑3.5 Turbo or tiny LLaMA variants.

> 💬 *"this brain part which I believe is the biggest bottleneck whenever you're trying to learn AI."*

### OpenRouter notes
- Create account -> Keys -> create key (example name: "autogen in crash course") -> copy key immediately ("it will be gone if I don't copy it. You won't be able to see it again.")
- OpenRouter offers free models and a unified gateway.

---

## Multimodal Input & Structured Output
---
### Sending an image to an agent (steps)
1. Fetch an image (use a reproducible provider like picsum.photos with fixed IDs).
2. Convert the image to bytes.
3. Wrap in ag_image with source='user'.
4. Call agent.run(...) and handle the response (may be raw text or JSON).

> 💬 *"it should be multimodel input"*

### ag_image
- ag_image wraps image bytes + metadata (e.g., source="user").
- Convert to bytes before sending.

### Structured outputs: use response formats (Pydantic)
- Enforce desired schema with Pydantic BaseModel rather than relying on prompt-only JSON requests.
- Speaker warned against misspelling and unreliable prompting: use correct "Pydantic" library and enforce schema.

Example (as concept in transcript):

```python
from pydantic import BaseModel

class PlanetInfo(BaseModel):
    name: str
    color: str
    distance_miles: int
```

> 💬 *"always return an answer in JSON."* (instruction example from transcript)  
> 💬 *"Please make sure that you don't do this. This is totally totally wrong."* (warning about bad install/prompting)

### Parsing and validation
- Model outputs may be strings — be prepared to parse to JSON and validate against schema.
- Even with enforced schema, models can still err; validate outputs.

---

## Teams, Multi-Agent Patterns & Orchestration
---
### What is a team?
- "A team is group of agent that work together to achieve a common goal."
- Teams allow role division (writer, reviewer, editor; backend dev, frontend dev, product manager, code executor, etc.) and shared context.

> 💬 *"teams are where any framework and autogen especially shines"*

### When to use teams
- Use teams for complex, multi-part tasks.
- Avoid overhead for simple tasks where a single LLM suffices.

> 💬 *"If you are a pro programmer you will love this thing a lot about autogen because you can jump onto the core."*

### Team types & presets
- Round-robin group chat: participants take turns in sequence (first → second → third), optionally looping.
  > 💬 *"Round robin group chat. A team that runs on a group chart with participant taking turns in roundrobin fashion."*
- Selector group chat: a selector/"brain" routes tasks to the most appropriate agent by reading agent names/descriptions and using a model client to decide who should answer.
- Targeted single-responder: only a specific agent answers.

### Participant heterogeneity & tools
- Agents in a team can use different model clients and different toolsets.
- Each agent can have its own tools (planning, web search, data analyst, code executor).

### run vs run_stream for teams
- run returns the final result after full execution.
- run_stream yields outputs as agents finish (streaming view).

### Reentrant workflows & single-agent teams
- Teams can loop outputs back to earlier agents (reentrant).
- A "single-agent team" can be used to iterate a role by running multiple turns.

### Selector-specific caveats
- Give good agent names/descriptions so selector routing works: "name and description become a lot important"
- allow_repeated_speaker controls whether the same agent can speak repeatedly.

> 💬 *"allow_repeated_speaker" flag: controls whether the same agent can speak repeatedly in selector teams; set False to prevent a generic agent dominating.*

### max_turns meaning & caveats
- "max_turns means number of time it agents will kind of executed. First execution, second execution, third execution."
- max_turns is supported by specific team classes (e.g., round-robin, selector group chat, swarm) with termination conditions.
- Default is None; forgetting to set termination can lead to runaway costs.

> 💬 *"it will keep on running unfortunately because it don't have any max turns it is none by default. So yeah it will happen it will just be running indefinitely and charging you a lot."*

---

## Termination Conditions & Human-in-the-Loop (HITL)
---
### Termination condition overview
- A termination condition is a callable evaluated during the run and can be stateful during a run (auto-reset after run).
- They can be combined with logical and/or.
- Common built-ins:
  - MaxMessageTermination (counts agent + task messages)
  - TextMentionTermination (stop when a message contains a keyword, e.g., "approve")
  - Token-usage termination
  - Handoff termination (stop when handed off to a specific agent)
  - External/source termination (stop button)
  - Function-call / stop-message termination

> 💬 *"A termination condition is a callable..."*  
> 💬 *"They can be combined using and and or."*

### Max-message caveat
- Counts include the initial user/task message and all agent and task messages: "Max message termination stops after a specified number of messages have been produced including both agent and task message."

### Example composition
- Run for 10 turns OR stop on "approve" (text mention termination).

> 💬 *"So I can have say a text mention termination. I can either make them run for 10 turns or text mention when one of them say approve."*

### Custom termination & reusability
- You can supply custom functions for bespoke stopping logic (e.g., final greeting triggers stop).
- Termination conditions reset automatically after each run.

### Human-in-the-loop approaches
- During-run blocking: use UserProxyAgent which blocks the team and waits for human input (default input()) — "user proxy agent".
- Post-run continuation: save team state and resume later with human feedback.
- team.save_state() and agent.save_state() allow persistence to file/DB; use team.reset() to clear context.

> 💬 *"Type exit to stop feedback. Strip exit."*  
> 💬 *"the team should maintain the state."*  
> 💬 *"save_state function on the agents as well as on the team."*

### Practical HITL patterns
- Pre-answer approval: pause mid-flow for a human to approve or modify.
- Post-answer feedback: run autonomously, then a human loads state and provides corrections, then re-run.

---

## Studio, Bench, Pre-built Apps & Prototyping
---
### Autogen Studio (low-code builder)
- Studio provides: Playground (session runs, inspect flow/tokens/why it ended), Builder (drag-and-drop agents, tools, models, termination conditions), Gallery (templates), Settings.
- Studio is low-code, not production-ready: "it is not meant to be production ready app. Developers are encouraged to use autogen framework to build their own application implement authentication security and other features required for deployed application."

> 💬 *"this is the builder everyone where you can drag and drop things"*

- UI actions: download team as JSON, import from URL, run Autogen Studio UI on port 8081: "autogen studio UI - port 8081".

### Bench & reference apps
- Bench is a testing/building tool.
- Pre-built multi-agent app example: Magnetic One (Microsoft multi-agent reference implementation).

### Versioning / dependency caveats with Studio
- Pip installing requirements can downgrade autogen packages (e.g., "I am on 0.6.1 ... it is going to downgrade it to ... 0.5.7."); use separate virtualenvs to avoid breaking other projects.

> 💬 *"it is going to downgrade your autogen agent chat library ... I am on 0.6.1 ... it is going to downgrade it to ... 0.5.7."*

---

## End-to-End Patterns, Examples & Frontend Integration
---
### Literature-review multi-agent pattern (example)
- Search agent: crafts queries and fetches candidate papers (recommend fetching ~5x requested_count to down-select).
  > 💬 *"Always fetch five times the paper requested so that you can down select the most relevant ones."*
- Summarizer agent: writes markdown summaries and returns concise JSON with fields like title, authors, published, summary, PDF URL.
- Orchestrator coroutine: expose run_lit or run_literature_review which calls run_stream to drive the two-agent team.
  > 💬 *"It exposes a single public C routine run lit uh literature review that drives a two agent team"*

### Analyzer app example
- The speaker built an "analyzer GBD / analyzer GPD" app that visualizes and "has done the work of a data analyst":
  > 💬 *"So I call this app as our analyzer GPD."*  
  > 💬 *"See analyzer GBD digital data analyzer and it has tell us many nice things in the graph."*  
  > 💬 *"It has done the work of a data analyst. So yeah bye-bye data analyst."*

### Streamlit frontend & CLI testing
- Recommended flow: test the backend via CLI (generator outputs) then integrate into Streamlit UI which consumes the generator to stream results.
  > 💬 *"The reason we are yielding it here because it's a generator it is returning that back."*

- Streamlit tips:
  - Use st.set_page_config, input widgets, st.button to trigger runs, and a container/placeholder for streaming output.
  - Be aware Streamlit uses its own event loop; which streamlit and venv mismatches are common pitfalls: "Always make sure that you do this which streamllet." and "I actually wasted an R one day on this particular issue... installed that library maybe 10 times".

### Docker/runtime considerations
- Ensure dependencies are installed inside container; agents may detect and install missing packages at runtime (demo: agent installed pandas).

---

## Warnings, Gotchas & Best Practices
---
### Installation & environment
- Use Autogen v4+ packages (agent-chat, core, ext); do not use pyautogen/old imports.
- Create & activate a venv; select the right Jupyter kernel; pip install -r requirements.
- Ensure Python 3.10+ and install ipykernel if using notebooks.
- Be cautious with pip install -r requirements that may silently downgrade packages.

> 💬 *"Always make sure that you are selecting the right environment so that you don't face any problem here."*

### Security & keys
- Load API keys from env/.env; avoid hardcoding. "If you want you can provide it directly as well but of course that is not suggested because of safety reason."
- OpenRouter: copy key immediately after creation — "it will be gone if I don't copy it. You won't be able to see it again."

### Runtime & cost
- Prefer run_stream / on_message_stream for production/evented clarity; run (non-stream) outputs are harder to interpret.
- Configure termination conditions (max_turns / max_message / text-mention / handoff / external stop) to avoid runaway costs.
- Use short prompts in demos to control token usage.

> 💬 *"it will keep on running unfortunately because it don't have any max turns it is none by default. So yeah it will happen it will just be running indefinitely and charging you a lot."*

### Agents, teams & selectors
- Agents are stateful; callers should send only new messages (not full history).
- Description does NOT control behavior — system_prompt does.
- For selector teams, good agent names/descriptions are critical for routing.
- Use UserProxyAgent for during-run human approvals; use save_state/load for post-run human continuation.

### Tools & schemas
- Always include type annotations/docstrings for FunctionTool wrappers.
- Enforce structured outputs using Pydantic/response formats rather than relying purely on prompting.
- Choose models that support multimodal inputs when sending images.
- Validate HTTP / tool response schemas to avoid runtime validation errors ("validation error dynamic model fact field missing input value function call").

> 💬 *"tools are code that can be executed by an agent or perform action."*

### Documentation & examples caution
- Many samples and AI-generated code snippets on the web are outdated or reference old module paths (langchain.experimental, pyautogen, etc.). Consult official docs/GitHub and migration guides.

> 💬 *"lang chain experimental is old but that is the example... this has been depreciated."*

---

## Practical Snippets & References (verbatim phrases preserved)
---
### Spoken command / code fragments
```bash
python - m v env autogen crash course
pip install -r requirements
# WRONG:
pip install py autogen
# spoken install:
pip install agent chat uh sorry autogen agent chat right
```

```python
# async idioms from the talk
async def
await asyncio.gather(...)
await agent.run(...)
# streaming:
run_stream / on_message_stream
```

```python
# Pydantic conceptual example from transcript
from pydantic import BaseModel

class PlanetInfo(BaseModel):
    name: str
    color: str
    distance_miles: int
```

```python
# imports mentioned in transcript (verbatim references)
from autogen.agent.chat.base import task_result
from autogen.agent_chat.conditions import max_message_termination
```

### Example prompts quoted
> 💬 *"What is the capital of France?"*  
> 💬 *"Find information about labrad.riever"*  
> 💬 *"always return an answer in JSON."*  
> 💬 *"use tools to solve task"*

---

## 🎯 Key Takeaways
- I'm summarizing in the narrator's voice: Autogen v4+ is an event-driven async framework that makes building agentic AI systems straightforward; "This tutorial is your ticket to mastering agentic AI with Autogen."  
- Use the agent-chat high-level API for most cases; drop to autogen-core only for advanced/custom actor-like implementations.  
- Create and activate a dedicated venv, select the right kernel, and pip install the modern packages (agent-chat, core, ext) — do NOT use outdated pyautogen imports.  
- Prefer run_stream / on_message_stream for production to see intermediate events (tool calls, tool results, summaries) and to log function_call_id for auditing.  
- Model choice matters: pick LLMs that support the capabilities you need (multimodal/image support when sending ag_image). OpenRouter and local runtimes are good alternatives for free/no-credit workflows.  
- Treat tools as first-class: wrap functions with FunctionTool, include types/docstrings, validate HTTP/tool responses via schemas, and use reflect_on_tool_use when helpful.  
- Use teams when tasks require division of labor (writers, reviewers, code executors). Configure termination conditions and human-in-the-loop (UserProxyAgent or save/load state) to avoid runaway costs and to allow safe approvals.  
- Enforce structured outputs using Pydantic/response-formats rather than begging in prompts; always parse and validate model outputs.  
- Use Studio/Bench for rapid prototyping but build production systems with the Autogen framework, custom auth, security and deployment practices.  
- "If you have any doubts, please ask the same with the time stamp and I will be happily clear that as soon as possible." Keep learning, share your work, and iterate with saved state and human feedback.