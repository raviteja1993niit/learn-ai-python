# AutoGen Hands-On Projects

Ten practical projects you can build with AutoGen. Each project includes an
Overview, Setup Steps, Key Agents, Sample Prompt, and Expected Output.

---

## Table of Contents

1. Code Generation and Execution Agent
2. Data Analysis Agent Team
3. Debate Agents (Pro vs Con)
4. Research Summariser Multi-Agent
5. Code Review Multi-Agent
6. Math Problem Solver with Verification
7. Essay Writer with Feedback Loop
8. Software Engineer + QA Tester Pair
9. Customer Support Multi-Agent
10. AutoGen Studio Workflow Builder

---

## 1. Code Generation and Execution Agent

### Overview
Build a self-contained agent pipeline that writes Python code, executes it in an
isolated environment, and self-corrects on failure. The pipeline loops until the
code produces the expected output or a maximum iteration limit is reached.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai,local-executor]`
2. Set the `OPENAI_API_KEY` environment variable.
3. Create a working directory: `mkdir coding_workspace`
4. Instantiate `LocalCommandLineCodeExecutor(work_dir='coding_workspace')`.
5. Wire up three agents: `code_generator`, `code_executor` (UserProxyAgent), `code_reviewer`.
6. Use `TextMentionTermination('LGTM')` to stop when the reviewer approves.

### Key Agents
| Agent | Role |
|-------|------|
| `code_generator` | Writes Python code in fenced blocks |
| `code_executor`  | Runs code via `LocalCommandLineCodeExecutor`, reports stdout/stderr |
| `code_reviewer`  | Checks correctness and style; emits LGTM when satisfied |

### Sample Prompt
```
Write a Python function `flatten(nested_list)` that recursively flattens
an arbitrarily nested list. Include unit tests using pytest.
```

### Expected Output
- A working `flatten()` implementation in a `.py` file inside `coding_workspace/`.
- Execution output showing all pytest tests passing.
- A final review message ending with `LGTM`.

---

## 2. Data Analysis Agent Team

### Overview
Assemble a four-agent data science team that loads a CSV dataset, performs
exploratory data analysis, generates visualisation code, and writes an
executive summary report — all autonomously.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai] pandas matplotlib seaborn`
2. Place a CSV dataset (e.g., `sales.csv`) in the project directory.
3. Define four `AssistantAgent` instances with distinct system prompts.
4. Use `SelectorGroupChat` so an LLM manager routes tasks intelligently.
5. End the workflow with `TextMentionTermination('TERMINATE')`.

### Key Agents
| Agent | Role |
|-------|------|
| `data_loader` | Reads CSV, prints shape, dtypes, and sample rows |
| `analyst`     | Computes descriptive stats, correlations, and flags anomalies |
| `visualiser`  | Generates matplotlib/seaborn code for charts |
| `reporter`    | Synthesises findings into a markdown report; emits TERMINATE |

### Sample Prompt
```
Analyse sales.csv: identify the top 5 products by revenue, detect any
seasonal trends, visualise monthly sales, and write an executive summary.
```

### Expected Output
- Descriptive statistics printed to console.
- Matplotlib chart code (bar chart + line chart) ready to run.
- A concise executive summary with key insights highlighted.

---

## 3. Debate Agents (Pro vs Con)

### Overview
Stage a structured debate between two adversarial agents — one arguing for
a proposition, one against — with a neutral judge scoring each round.
Great for exploring multi-perspective reasoning and argument quality.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Create three `AssistantAgent` instances: `pro`, `con`, `judge`.
3. Set a distinct `system_message` for each role.
4. Use `RoundRobinGroupChat` to alternate pro → con → pro → con → judge.
5. `MaxMessageTermination(max_messages=7)` gives two debate rounds plus a verdict.

### Key Agents
| Agent | Role |
|-------|------|
| `pro`   | Argues in favour with evidence and logic |
| `con`   | Argues against with counter-evidence |
| `judge` | Evaluates both sides and declares a winner |

### Sample Prompt
```
Motion: Remote work is more productive than office work.
Run a two-round debate and have the judge declare a winner.
```

### Expected Output
- Two rounds of structured arguments (pro then con each round).
- A final judge verdict with reasoning, citing the strongest arguments.

---

## 4. Research Summariser Multi-Agent

### Overview
A multi-agent research pipeline that takes a topic, performs simulated web
research via tool calls, synthesises sources, and produces a structured
literature summary with citations.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Define a `web_search` tool (wrapping SerpAPI or a mock) using `@tool`.
3. Create agents: `query_planner`, `researcher` (with tool), `synthesiser`.
4. Chain them with `RoundRobinGroupChat` or `SelectorGroupChat`.
5. Use `TextMentionTermination('DONE')` to end when synthesis is complete.

### Key Agents
| Agent | Role |
|-------|------|
| `query_planner` | Decomposes the topic into 3-5 targeted search queries |
| `researcher`    | Executes searches via tool call, collects results |
| `synthesiser`   | Merges findings into a structured summary with citations |

### Sample Prompt
```
Research the current state of large language model alignment techniques.
Provide a structured summary with at least five cited sources.
```

### Expected Output
- A list of targeted search queries used.
- Raw research snippets from each query.
- A formatted summary with section headers and inline citations.

---

## 5. Code Review Multi-Agent

### Overview
An automated code review pipeline. Submit a pull-request diff; specialised
agents check for bugs, security issues, style violations, and performance
problems; a final agent compiles all findings into a structured review report.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Load a code diff as a string (or read from a `.patch` file).
3. Create four `AssistantAgent` reviewers with focused system prompts.
4. Use `RoundRobinGroupChat`; collect all review comments.
5. Add a `review_compiler` agent that formats findings into a GitHub-style review.

### Key Agents
| Agent | Role |
|-------|------|
| `bug_finder`       | Identifies logic errors and off-by-one issues |
| `security_auditor` | Flags injection risks, exposed secrets, unsafe deps |
| `style_checker`    | Enforces PEP 8 / language style guides |
| `perf_analyst`     | Spots O(n^2) loops, unnecessary allocations |
| `review_compiler`  | Merges all findings into a concise review report |

### Sample Prompt
```
Review this Python diff for a REST API endpoint that handles user login.
[paste diff here]
```

### Expected Output
- Categorised review comments (bug / security / style / performance).
- Suggested fixes in code-fence blocks.
- A summary score: Approve / Request Changes / Comment.

---

## 6. Math Problem Solver with Verification

### Overview
A solver-verifier agent pair that tackles maths problems. The solver works
step by step; the verifier checks every step for arithmetic or logical errors
and requests corrections until a verified solution is reached.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Define a `python_calculator` tool that evaluates expressions safely.
3. Create `solver` agent (equipped with calculator tool) and `verifier` agent.
4. Use `RoundRobinGroupChat`; the verifier emits VERIFIED when satisfied.
5. `TextMentionTermination('VERIFIED')` ends the loop.

### Key Agents
| Agent | Role |
|-------|------|
| `solver`   | Breaks problem into steps, uses calculator tool for arithmetic |
| `verifier` | Checks each step, requests corrections; emits VERIFIED on success |

### Sample Prompt
```
Solve the following system of equations:
  3x + 2y = 12
  x - y = 1
Show all working and verify the solution by substitution.
```

### Expected Output
- Step-by-step solution with each intermediate value.
- Verifier confirmation that the solution satisfies both equations.
- Final message ending with `VERIFIED`.

---

## 7. Essay Writer with Feedback Loop

### Overview
An iterative essay-writing workflow. A writer agent drafts an essay;
a critic agent provides specific, actionable feedback; the writer revises.
The loop continues for a configurable number of revision cycles.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Create `writer` and `critic` agents with appropriate system prompts.
3. Use `RoundRobinGroupChat` with `MaxMessageTermination(max_messages=9)`
   (allows up to four revision cycles).
4. Optionally add a `final_editor` agent that polishes the last draft.

### Key Agents
| Agent | Role |
|-------|------|
| `writer`       | Produces an essay draft based on the prompt |
| `critic`       | Gives structured feedback: clarity, argument, evidence, flow |
| `final_editor` | Polishes grammar, transitions, and conclusion |

### Sample Prompt
```
Write a 500-word persuasive essay arguing that open-source AI models
are safer than closed-source models. Then revise based on feedback.
```

### Expected Output
- Initial essay draft (approximately 500 words).
- Structured critique with numbered improvement points.
- Revised essay incorporating the feedback.
- Polished final version from the editor.

---

## 8. Software Engineer + QA Tester Pair

### Overview
A paired-programming simulation. A software engineer agent implements a
feature; a QA tester agent writes and runs tests against it, reports
failures, and the engineer fixes them until all tests pass.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai,local-executor] pytest`
2. Configure `LocalCommandLineCodeExecutor` as the code runner.
3. Create `engineer` (writes implementation) and `qa_tester` (writes+runs tests).
4. Use `RoundRobinGroupChat`; terminate when QA emits `ALL TESTS PASS`.

### Key Agents
| Agent | Role |
|-------|------|
| `engineer`  | Implements the feature specification in Python |
| `qa_tester` | Writes pytest tests, executes them, reports failures |

### Sample Prompt
```
Implement a Python class `BankAccount` with deposit, withdraw, and
balance methods. Enforce a minimum balance of $0. Write and run full
test coverage using pytest.
```

### Expected Output
- `bank_account.py` with complete implementation.
- `test_bank_account.py` with edge-case tests.
- Execution output: all tests pass.
- Final QA message: `ALL TESTS PASS`.

---

## 9. Customer Support Multi-Agent

### Overview
A tiered customer support system. A triage agent classifies incoming queries
and routes them to the appropriate specialist agent (billing, technical,
returns). A supervisor agent reviews all responses for quality and escalates
unresolved issues.

### Setup Steps
1. `pip install autogen-agentchat autogen-ext[openai]`
2. Create a `triage` agent with routing instructions.
3. Create specialist agents: `billing_agent`, `tech_support_agent`, `returns_agent`.
4. Create a `supervisor` agent that reviews final responses.
5. Use `SelectorGroupChat` with a custom `selector_func` that reads the
   triage classification to route to the correct specialist.

### Key Agents
| Agent | Role |
|-------|------|
| `triage`        | Classifies query: billing / technical / returns |
| `billing_agent` | Handles payment, invoices, subscription questions |
| `tech_support`  | Diagnoses product/software issues |
| `returns_agent` | Manages refund and return requests |
| `supervisor`    | QA-checks responses; escalates if unresolved |

### Sample Prompt
```
Customer message: 'I was charged twice for my subscription last month
and now I can't log in to my account. Please help.'
```

### Expected Output
- Triage classification: billing + technical (dual-route).
- Billing agent response addressing the duplicate charge.
- Tech support response with login troubleshooting steps.
- Supervisor sign-off confirming both issues were addressed.

---

## 10. AutoGen Studio Workflow Builder

### Overview
Use AutoGen Studio's no-code UI to visually construct, test, and export
multi-agent workflows. This project walks through creating a research-to-report
pipeline entirely through the Studio interface.

### Setup Steps
1. `pip install autogenstudio`
2. Launch: `autogenstudio ui --port 8081`
3. Open `http://localhost:8081` in your browser.
4. Create a new **Team** in the Studio UI.
5. Add agents: drag and drop `AssistantAgent` and `UserProxyAgent` blocks.
6. Configure each agent's system prompt and model settings in the sidebar.
7. Connect agents with directed edges to define message flow.
8. Click **Run** and enter your task prompt in the test panel.
9. Export the workflow as a JSON config for use in code with `TeamConfig`.

### Key Agents (configured in Studio UI)
| Agent | Studio Block | Configuration |
|-------|-------------|---------------|
| `researcher`  | AssistantAgent | System prompt: 'Research the topic thoroughly.' |
| `writer`      | AssistantAgent | System prompt: 'Write a structured report.' |
| `user_proxy`  | UserProxyAgent | human_input_mode: NEVER |

### Sample Prompt
```
Research the environmental impact of lithium-ion battery production
and write a two-page briefing document for policy makers.
```

### Expected Output
- A structured briefing document visible in the Studio chat panel.
- Downloadable JSON workflow config for reuse in Python scripts.
- Studio session log showing inter-agent message flow.

---

## Quick-Start Cheat Sheet

```bash
# Install core AutoGen packages
pip install autogen-agentchat autogen-ext[openai]

# Install optional extras
pip install autogen-ext[docker]         # Docker code executor
pip install autogen-ext[cache]          # DiskCacheClient
pip install diskcache                   # Required by DiskCacheClient
pip install autogenstudio               # AutoGen Studio UI

# Set your API key
export OPENAI_API_KEY="sk-..."          # Linux/macOS
$env:OPENAI_API_KEY="sk-..."           # Windows PowerShell

# Launch AutoGen Studio
autogenstudio ui --port 8081
```

---

*End of PRACTICALS.md — 10 hands-on AutoGen projects.*