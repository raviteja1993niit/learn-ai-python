# CrewAI Theory & Concepts

## 1. CrewAI Philosophy

CrewAI is a framework for orchestrating role-playing, autonomous AI agents. The core
philosophy mirrors a real company org chart: you define specialized agents (like employees),
assign them tasks (like job duties), and let a crew (like a team or department) coordinate
execution toward a shared goal.

Instead of one monolithic LLM prompt, CrewAI decomposes complex problems into focused
sub-tasks handled by agents with distinct roles, goals, and backstories. This specialization
improves output quality because each agent is primed to think and respond in a narrow domain.

Key philosophical pillars:
- **Role-Based Specialization**: Agents act as experts (researcher, writer, coder, analyst).
- **Collaborative Intelligence**: Agents share context and build on each other's outputs.
- **Structured Autonomy**: The framework provides guardrails while agents make decisions.
- **Composability**: Crews can be nested, flows can chain crews, tools extend capabilities.

---

## 2. Key Components Overview

| Component | Purpose |
|-----------|---------|
| Agent     | An autonomous LLM-powered entity with a role, goal, and backstory |
| Task      | A unit of work assigned to an agent with description and expected output |
| Crew      | A collection of agents and tasks orchestrated together |
| Tool      | A capability an agent can invoke (search, file I/O, code execution, APIs) |
| Process   | The execution strategy: sequential or hierarchical |
| Flow      | A higher-level pipeline that chains crews and logic together |

---

## 3. Agent Anatomy

An Agent is the fundamental actor in CrewAI. It wraps an LLM with a persona and capabilities.

### Constructor Parameters

| Parameter          | Type       | Description |
|--------------------|------------|-------------|
| role               | str        | Job title / function (e.g., "Senior Research Analyst") |
| goal               | str        | What this agent is trying to achieve |
| backstory          | str        | Narrative context that shapes how the agent thinks |
| tools              | list       | Tools the agent can invoke |
| llm                | LLM obj    | Language model instance (default: ChatOpenAI gpt-4) |
| verbose            | bool       | Print agent reasoning steps |
| allow_delegation   | bool       | Whether agent can delegate tasks to other agents |
| max_iter           | int        | Max reasoning iterations before forced answer |
| memory             | bool       | Enable agent-level memory |
| step_callback      | callable   | Hook called after each agent step |
| cache              | bool       | Cache tool call results |

### role
The role is a concise job title. It sets the agent's professional identity and influences
how the LLM frames its reasoning. A good role is specific: "Senior Python Developer" beats
"Developer". It appears in the system prompt as the agent's persona.

### goal
The goal is a single sentence describing what the agent is ultimately trying to accomplish.
It aligns the agent's decision-making during task execution. Keep it action-oriented:
"Find accurate, up-to-date information and synthesize it into clear summaries."

### backstory
The backstory is the richest context field. It gives the agent a professional history,
personality, and working style. A detailed backstory significantly improves output quality
because the LLM generates responses consistent with the persona's experience and perspective.

Example backstory:
"You are a veteran investigative journalist with 15 years at The Financial Times. You have
a talent for distilling complex economic data into compelling narratives. You always verify
facts from multiple sources before drawing conclusions."

### tools
A list of Tool objects the agent can call during task execution. Tools extend the agent
beyond pure text generation, enabling web searches, file operations, API calls, and more.

### allow_delegation
When True, the agent can hand off sub-tasks to other agents in the crew. This is essential
in hierarchical processes where a manager agent orchestrates specialists.

### verbose
When True, CrewAI prints the agent's chain-of-thought to stdout. Useful for debugging and
understanding agent behavior during development.

---

## 4. Task Anatomy

A Task defines a discrete unit of work: what to do, what output is expected, and which
agent should do it.

### Constructor Parameters

| Parameter       | Type       | Description |
|-----------------|------------|-------------|
| description     | str        | What the agent should do |
| expected_output | str        | Format and content of the desired output |
| agent           | Agent      | The agent responsible for this task |
| context         | list[Task] | Tasks whose outputs feed into this task |
| output_file     | str        | File path to write the task output |
| async_execution | bool       | Run task asynchronously |
| human_input     | bool       | Pause and request human review/input |
| tools           | list       | Override agent tools for this specific task |
| callback        | callable   | Function called when task completes |

### description
A detailed natural language description of what needs to be done. The more specific and
unambiguous, the better the output. Include: what information to find/generate, constraints
(length, format, tone), and any important context.

Good: "Research the top 5 AI frameworks released in 2024. For each, note: name, creator,
primary use case, and GitHub stars. Focus on frameworks for production deployment."

Poor: "Research AI frameworks."

### expected_output
Describes the format and completeness of the desired output. This acts as a quality check
- the agent tries to produce output matching this description.

Example: "A markdown-formatted table with columns: Framework, Creator, Use Case, Stars.
Followed by a 2-sentence summary of the most promising framework."

### context
A list of other Task objects. When a task has context tasks, CrewAI automatically injects
the string output of those tasks into this task's prompt. This is how you chain tasks:
the output of a research task becomes the input context for a writing task.

### output_file
When set, the task's final output string is written to this file path. Useful for saving
reports, generated code, or analysis results as persistent artifacts.

### human_input
When True, execution pauses after the agent completes the task and waits for a human to
review and optionally modify the output before the crew continues. Enables human-in-the-loop
workflows.

---

## 5. Process Types

### Sequential Process (Default)
Tasks execute one after another in the order they are listed in the Crew's tasks list.
Output from task N is available as context for task N+1 (if configured). This is the
simplest and most predictable process type.

Execution flow:
  Task 1 -> Task 2 -> Task 3 -> ... -> Final Output

Use sequential when:
- Tasks have a clear linear dependency chain
- You want predictable, deterministic execution order
- Debugging is a priority (easy to trace)

### Hierarchical Process
A manager agent (powered by a separate LLM) dynamically assigns tasks to worker agents
based on their roles and capabilities. The manager can re-assign, repeat, or skip tasks.
This mirrors how a real team lead delegates work.

Execution flow:
  Manager LLM -> Assigns Task A to Agent 1
              -> Assigns Task B to Agent 2
              -> Reviews outputs -> Final Result

Use hierarchical when:
- You have many agents and tasks that do not need to run in strict order
- You want the LLM to optimize task assignment
- Tasks may need re-routing based on intermediate results

Configuration requires setting process=Process.hierarchical and optionally providing
a manager_llm (defaults to the crew default LLM).

---

## 6. Crew Anatomy

The Crew ties agents and tasks together into a runnable unit.

### Constructor Parameters

| Parameter     | Type        | Description |
|---------------|-------------|-------------|
| agents        | list[Agent] | All agents in the crew |
| tasks         | list[Task]  | All tasks to execute |
| process       | Process     | Sequential or hierarchical |
| verbose       | bool/int    | Verbosity level (0, 1, 2) |
| memory        | bool        | Enable memory subsystem |
| cache         | bool        | Cache tool results globally |
| max_rpm       | int         | Rate limit for LLM calls per minute |
| manager_llm   | LLM         | LLM for manager in hierarchical mode |
| full_output   | bool        | Return all task outputs, not just last |
| step_callback | callable    | Hook after each agent step |
| task_callback | callable    | Hook after each task completes |
| embedder      | dict        | Embedder config for memory |
| planning      | bool        | Enable crew-level planning before execution |

### kickoff()
The primary method to start crew execution. Returns a CrewOutput object containing
the final result and metadata.

The inputs parameter allows you to pass dynamic values via {placeholder} syntax in
task descriptions and agent fields.

---

## 7. Memory System

CrewAI's memory system allows agents to retain and recall information within and across
crew runs, dramatically improving coherence on long-running or repeated tasks.

### Short-Term Memory
Stored in-memory using embeddings. Available only during the current crew run.
Used for: intra-run context, avoiding repetition, maintaining coherence across tasks.
Backed by: ChromaDB (default) or other compatible vector store.

### Long-Term Memory
Persisted to disk (SQLite by default). Available across multiple crew.kickoff() calls.
Used for: remembering past research, user preferences, previously computed results.
Agents can query long-term memory to avoid re-doing work from previous sessions.

### Entity Memory
Tracks named entities (people, organizations, places, concepts) encountered during execution.
Stored with metadata. Enables agents to build a knowledge graph over time.
Used for: consistent entity handling, relationship tracking, knowledge accumulation.

### Enabling Memory
Set memory=True on the Crew. Configure the embedder if needed.
Supports OpenAI, Azure, Cohere, Google embeddings and more.

---

## 8. Tools

Tools extend agents beyond text generation, enabling real-world interactions.

### Built-In Tools

| Tool                     | Purpose |
|--------------------------|---------|
| SerperDevTool            | Google search via Serper API |
| WebsiteSearchTool        | Semantic search within a specific website |
| ScrapeWebsiteTool        | Scrape full text from a URL |
| FileReadTool             | Read contents of a local file |
| FileWriterTool           | Write content to a local file |
| DirectoryReadTool        | List directory contents |
| CodeInterpreterTool      | Execute Python code in sandbox |
| GithubSearchTool         | Search GitHub repositories |
| YoutubeChannelSearchTool | Search YouTube channel content |
| PDFSearchTool            | Semantic search within PDF files |
| CSVSearchTool            | Query CSV files semantically |
| JSONSearchTool           | Search within JSON files |
| SeleniumScrapingTool     | Scrape JavaScript-rendered pages |

### Custom Tools with @tool Decorator
The @tool decorator registers a Python function as a CrewAI tool. The function's
docstring becomes the tool description that the LLM reads to decide when to use it.
Type hints on parameters are used for input validation.

### Tool Best Practices
- Keep tool functions focused and single-purpose
- Write clear docstrings - the LLM reads these to decide when to use the tool
- Handle errors gracefully and return informative error strings
- Use type hints on parameters for validation
- Cache expensive tools to avoid repeated identical calls

---

## 9. Task Context Chaining

Context chaining is how you build multi-step pipelines where each agent builds on
prior work.

When Task B lists Task A in its context parameter, CrewAI:
1. Waits for Task A to complete
2. Takes Task A's string output
3. Injects it into Task B's prompt as additional context

This enables sophisticated workflows:
- Research -> Summarize -> Write -> Edit
- Fetch Data -> Analyze -> Visualize -> Report
- Review Code -> Identify Bugs -> Fix Bugs -> Verify Fix

---

## 10. Output Handling

### CrewOutput Object
crew.kickoff() returns a CrewOutput with:
- .raw: raw string output of the final task
- .pydantic: Pydantic model if output_pydantic was set
- .json_dict: dict if output_json was set
- .tasks_output: list of TaskOutput objects for each task
- .token_usage: token consumption statistics

### TaskOutput Object
Each task produces a TaskOutput with:
- .raw: string output
- .description: task description
- .agent: name of agent who completed it
- .exported_output: formatted output (JSON, Pydantic, or raw string)

---

## 11. Async Execution

### kickoff_async()
Returns a coroutine. Use with asyncio for non-blocking execution.
Useful when running crews as part of a larger async application (FastAPI, etc.).

### kickoff_for_each_async()
Runs the crew for each item in a list, concurrently. Ideal for batch processing:
processing multiple documents, researching multiple topics, analyzing multiple datasets.

### kickoff_for_each()
Synchronous version - runs crew once per input dict. Uses {placeholder} syntax in
task descriptions to inject each input's values.

---

## 12. Human-in-the-Loop

Setting human_input=True on a Task pauses execution and prompts the terminal user
to review the agent's output and optionally provide corrections or approval.

This is invaluable for:
- High-stakes decisions (publishing content, sending emails)
- Quality gates in content pipelines
- Iterative refinement workflows
- Compliance review steps

The human can press Enter to accept or type new instructions for the agent to retry.

---

## 13. Training

crew.train(n_iterations=3, filename="training.pkl", inputs={...}) runs the crew
multiple times and fine-tunes agent behavior based on human feedback. Training data
is saved as a pickle file for future use with crew.test().

---

## 14. CrewAI Flows

Flows provide a higher-level orchestration layer above Crews. With Flows you can:
- Chain multiple crews in sequence with shared state
- Add conditional branching with @router decorator
- Maintain shared state between crews using a Pydantic state model
- Mix direct Python logic with crew execution
- Handle events with @listen decorators

### Flow Decorators
- @start(): Entry point of the flow
- @listen(method_name): Executes after the named method completes
- @router(method_name): Routes to different branches based on return value

### Flow State
A Pydantic BaseModel subclass acts as the shared state object.
All methods in the flow can read and write to self.state.
State is automatically passed between flow steps.

---

## 15. Best Practices

### Agent Design
1. Write specific backstories: Generic backstories produce generic outputs. Give agents
   real professional context including years of experience and domain expertise.
2. Align role, goal, backstory: These three should tell a coherent story.
3. Limit tool sets: Give each agent only the tools it needs. Too many tools leads to
   incorrect tool selection.
4. Set verbose=True during development to understand agent reasoning.

### Task Design
1. Be specific in descriptions: Include format, length, tone, constraints explicitly.
2. Define expected_output clearly: The agent uses this as a quality target.
3. Use context strategically: Only pass context from tasks whose output is actually needed.
4. Use output_file for important artifacts.

### Crew Design
1. Start sequential: Build and test with sequential process before switching to hierarchical.
2. Enable memory for stateful workflows that run repeatedly on related topics.
3. Set max_rpm to protect against rate limits and runaway costs.
4. Use callbacks for monitoring and auditing crew progress.
5. Test with cheaper models during development, upgrade for production.

### General
- Keep crews focused: one crew per domain/objective
- Version your crew configs like code
- Log CrewOutput.token_usage to monitor costs
- Use environment variables for all API keys
- Test each agent individually before assembling into a crew
- Use Planning=True for complex multi-step crews for better coordination