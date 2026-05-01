# AutoGen v0.4 — Comprehensive Theory Reference

## 1. AutoGen Overview
AutoGen is an open-source framework from Microsoft Research for building multi-agent AI applications.
It enables multiple AI agents to collaborate, communicate, and execute tasks together.
Version 0.4 introduced a fully redesigned architecture based on event-driven, actor-model principles.

## 2. AutoGen v0.4 Architecture: Event-Driven, Actor Model

### Event-Driven Design
- Agents communicate via messages (events) rather than direct function calls.
- Each agent runs an independent message loop, reacting to incoming events.
- Decoupled communication allows flexible topologies (chains, stars, meshes).
- Messages are typed Python dataclasses (TextMessage, ToolCallMessage, etc.).

### Actor Model
- Every agent is an independent actor with its own state and mailbox.
- Actors process one message at a time (no shared mutable state conflicts).
- The runtime dispatches messages between actors asynchronously.
- Inspired by Erlang/Akka actor systems for concurrency and fault tolerance.

### Runtime
- SingleThreadedAgentRuntime: for single-process applications (default).
- Agents are registered with the runtime and addressed by AgentId.
- The runtime manages message routing and agent lifecycle.

## 3. AgentChat API vs Core API

### AgentChat API (High-Level)
- Provides pre-built agent types: AssistantAgent, UserProxyAgent, CodeExecutorAgent.
- Designed for rapid prototyping and common multi-agent patterns.
- Handles message passing, conversation history, and termination automatically.
- Import path: autogen_agentchat.agents, autogen_agentchat.teams
- Best for: most applications, task automation, code execution workflows.

### Core API (Low-Level)
- Gives full control over agent behavior, messaging, and runtime.
- Define custom agents by subclassing BaseChatAgent or RoutedAgent.
- Directly interact with the runtime for message subscription and publishing.
- Import path: autogen_core
- Best for: advanced customization, non-standard workflows, framework extensions.

## 4. AssistantAgent

### Role
- The primary LLM-powered agent that reasons, responds, and uses tools.
- Maintains conversation history and responds to messages from other agents.

### Key Parameters
- name: unique identifier string for the agent.
- system_message: defines the agent's persona, role, and behavioral guidelines.
- tools: list of Tool objects (FunctionTool, etc.) the agent can invoke.
- model_client: the LLM backend (OpenAIChatCompletionClient, etc.).
- handoffs: list of agents this agent can transfer control to.
- description: used by GroupChatManager for speaker selection decisions.

### Behavior
- Receives TextMessage objects, processes with LLM, returns response.
- Automatically handles tool call/response cycles internally.
- Supports streaming responses via on_messages_stream().

## 5. UserProxyAgent

### Role
- Represents a human user in the conversation loop.
- Can optionally execute code blocks extracted from agent responses.
- Can prompt the actual human for input or operate autonomously.

### Key Parameters
- name: identifier string.
- human_input_mode: controls when human input is solicited.
  - NEVER: fully automated, no human prompts.
  - TERMINATE: prompt human only when termination condition is met.
  - ALWAYS: prompt human for every message (true human-in-the-loop).
- code_execution_config: dict configuring the code executor backend.
- is_termination_msg: callable that returns True to end conversation.
- default_auto_reply: text sent when human_input_mode=NEVER and no code to run.

## 6. CodeExecutorAgent

### Role
- Dedicated agent for executing code blocks extracted from messages.
- Separates code execution from LLM reasoning for cleaner architecture.

### Executors

#### DockerCommandLineCodeExecutor
- Runs code inside an isolated Docker container.
- Provides security: code cannot affect the host machine.
- Parameters: image, timeout, work_dir.
- Requires Docker daemon running.
- Best practice for production or untrusted code execution.

#### LocalCommandLineCodeExecutor
- Runs code directly on the local machine in a subprocess.
- Faster startup than Docker but less secure.
- Parameters: timeout, work_dir.
- Best for development/trusted environments.

## 7. GroupChat and GroupChatManager

### GroupChat
- Manages a shared conversation among multiple agents.
- Holds the list of participating agents and message history.
- Parameters: agents (list), messages (history), max_round.
- Speaker selection determines which agent responds next.

### GroupChatManager
- Orchestrates GroupChat by deciding which agent speaks next.
- Backed by an LLM that reads agent descriptions to select speakers.
- Parameters: groupchat, llm_config.

### speaker_selection_method
- "auto": LLM selects the next speaker (default).
- "round_robin": agents take turns in order.
- "random": randomly pick next speaker.
- Custom callable: function(last_speaker, groupchat) -> Agent.

## 8. Termination Conditions

### MaxMessageTermination
- Ends the conversation after a fixed number of messages.
- Parameter: max_messages (int).
- Prevents infinite loops in automated pipelines.

### TextMentionTermination
- Ends when a specific text string appears in any agent message.
- Parameter: text (str), e.g., "TERMINATE".
- Agents are prompted to say the termination text when done.

### StopMessageTermination
- Ends when an agent emits a StopMessage object.
- Programmatic termination from within agent logic.

### Combining Conditions
- Use | (OR): terminates if either condition is met.
- Use & (AND): terminates only when both conditions are met.
- Example: MaxMessageTermination(10) | TextMentionTermination("DONE")

## 9. Code Execution Deep Dive

### DockerCommandLineCodeExecutor
- Creates a fresh container per session (or reuses existing).
- Captures stdout/stderr and returns as CodeResult object.
- Supports multiple languages (Python, Bash, etc.).
- Stops container automatically when context manager exits.

### LocalCommandLineCodeExecutor
- Writes code to a file in work_dir, executes via subprocess.
- Returns exit code, stdout, stderr in CodeResult.
- Persistent working directory across code blocks in a session.

## 10. Tool Use in AutoGen Agents

### @tool Decorator (autogen_core)
- Marks a Python function as a tool callable by agents.
- Extracts name, description, and parameter schema from docstring and type hints.
- Example: @tool async def search(query: str) -> str: ...

### FunctionTool (autogen_agentchat)
- Wraps a Python callable into a Tool object for AssistantAgent.
- Parameters: func, name (optional), description (optional).
- Passed to AssistantAgent(tools=[my_tool]).

### Tool Execution Flow
1. LLM decides to call a tool — returns ToolCallMessage.
2. Agent extracts tool name and arguments from the message.
3. Agent executes the function locally.
4. Result is returned to LLM as ToolCallResultMessage.
5. LLM incorporates result into its next response.

## 11. Custom Agents

### Inheriting from BaseChatAgent
- Override on_messages() for handling incoming ChatMessage objects.
- Override on_reset() for clearing agent state between conversations.
- Must define metadata: name, description, produced_message_types.

### RoutedAgent (Core API)
- Subscribe to specific message types using @message_handler decorator.
- Runtime automatically routes messages to the correct handler method.
- Enables event-driven, reactive agent patterns.

## 12. Human Proxy Patterns

### NEVER Mode
- Fully automated: UserProxyAgent never asks for human input.
- Sends default_auto_reply when there is no code to execute.
- Used in CI/CD pipelines, autonomous agents.

### TERMINATE Mode
- Asks human only when the conversation should end.
- Human can continue the conversation or stop the session.
- Balance between automation and oversight.

### ALWAYS Mode
- Every message requires a human response.
- True human-in-the-loop scenario.
- Useful for interactive assistants and tutors.

## 13. Conversation Patterns

### Two-Agent Pattern
- Simplest pattern: AssistantAgent + UserProxyAgent.
- UserProxy initiates with a task, AssistantAgent responds.
- Continues until termination condition is met.
- Good for: code generation, Q&A, simple automation.

### Group Chat Pattern
- Three or more agents collaborate in a shared conversation.
- GroupChatManager orchestrates speaker order.
- Good for: software teams, review pipelines, debate formats.

### Nested Chat Pattern
- An agent internally spawns a sub-conversation with other agents.
- Outer agent receives the final result of the inner conversation.
- Good for: complex sub-tasks, parallel research, verification loops.

### Sequential Chat
- Agents are chained: output of one becomes input of next.
- Linear workflow with clear data flow.
- Good for: ETL pipelines, multi-stage processing.

## 14. Streaming Responses

### Token Streaming
- on_messages_stream() yields ModelStreamEvent objects as tokens arrive.
- Reduces perceived latency in user-facing applications.
- Supported by OpenAIChatCompletionClient and compatible backends.

### Streaming in Team Chat
- RoundRobinGroupChat.run_stream() yields TaskResult events incrementally.
- Each agent's streaming output is surfaced to the caller in real time.

## 15. State Management and Resume

### save_state()
- Serializes agent state to a JSON-compatible dict.
- Includes: conversation history, tool call history, custom state.
- Use case: pause a long-running workflow and persist to disk.

### load_state()
- Restores agent from a previously saved state dict.
- Enables resumable workflows across process restarts.

### Team State
- RoundRobinGroupChat.save_state() / load_state() saves entire team state.
- Preserves all agent states and the full message history.

## 16. AutoGen Studio

### Overview
- No-code web UI for designing and testing multi-agent workflows.
- Drag-and-drop interface for composing agents and teams.
- Built on top of the AgentChat API.

### Features
- Define agents with custom system messages and tools via GUI.
- Build team configurations (GroupChat, RoundRobin, etc.) visually.
- Run conversations and inspect message logs in real-time.
- Export workflow configurations as JSON for use in Python code.

### Use Cases
- Rapid prototyping without writing Python.
- Demos and stakeholder presentations.
- Non-developer team members configuring AI workflows.

## 17. SocietyOfMindAgent

### Concept
- An agent that internally delegates to a team of sub-agents.
- From the outside, behaves like a single agent in a conversation.
- Internally runs a full GroupChat or RoundRobin to produce its response.

### Use Cases
- Hide complexity of multi-agent reasoning from outer conversation.
- Build hierarchical agent architectures with clear interfaces.
- Nested deliberation (multiple agents debate, one speaks for the group).

## 18. CacheClient for Cost Reduction

### Overview
- Caches LLM API responses keyed by prompt content.
- If the same prompt is sent again, returns cached response instantly.
- Reduces API costs and latency during development and testing.

### Types
- DiskCacheClient: persists cache to disk (survives restarts).
- InMemoryCacheClient: cache in RAM only (cleared on restart).

### Usage
- Pass as cache argument to model_client constructor.
- Completely transparent to agents — no agent code changes needed.

## 19. Summary of Key Classes

| Class                       | Package              | Purpose                            |
|-----------------------------|----------------------|------------------------------------|
| AssistantAgent              | autogen_agentchat    | LLM-powered reasoning agent        |
| UserProxyAgent              | autogen_agentchat    | Human proxy / code executor        |
| CodeExecutorAgent           | autogen_agentchat    | Dedicated code execution agent     |
| GroupChat                   | autogen_agentchat    | Multi-agent shared conversation    |
| GroupChatManager            | autogen_agentchat    | Orchestrates GroupChat speakers    |
| RoundRobinGroupChat         | autogen_agentchat    | Round-robin ordered team           |
| SocietyOfMindAgent          | autogen_agentchat    | Agent wrapping an inner team       |
| FunctionTool                | autogen_agentchat    | Wraps Python function as tool      |
| BaseChatAgent               | autogen_agentchat    | Base class for custom agents       |
| SingleThreadedAgentRuntime  | autogen_core         | Default single-process runtime     |
| MaxMessageTermination       | autogen_agentchat    | Terminate after N messages         |
| TextMentionTermination      | autogen_agentchat    | Terminate on keyword mention       |
| OpenAIChatCompletionClient  | autogen_ext          | OpenAI LLM client                  |
| DiskCacheClient             | autogen_ext          | Disk-based LLM response cache      |

## 20. Installation and Setup

Install packages:
  pip install autogen-agentchat autogen-ext[openai] autogen-studio

Set environment variable:
  OPENAI_API_KEY=your-api-key

Launch AutoGen Studio:
  autogenstudio ui --port 8081

Verify installation:
  python -c "import autogen_agentchat; print('OK')"