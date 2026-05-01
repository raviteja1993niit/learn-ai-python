# 🔄 ReAct Pattern — Reasoning + Acting

## What is ReAct?
ReAct (Reasoning + Acting) is a prompting framework where an LLM interleaves **Thought → Action → Observation**
steps to solve tasks. Each thought reasons about what to do next, each action calls a tool, and each observation
feeds the result back into the scratchpad for the next reasoning step.

## Why Learn It?
- Foundation of nearly every modern AI agent framework (LangChain, AutoGPT, CrewAI)
- Enables multi-step reasoning with external tools (search, calculator, APIs)
- Dramatically reduces hallucination vs. single-shot prompting for complex tasks
- Required knowledge for building reliable, auditable agent pipelines
- Directly translates to understanding LangChain's `create_react_agent` internals

## Key Concepts
```python
from openai import OpenAI

client = OpenAI()

SYSTEM_PROMPT = """You run in a Thought → Action → Observation loop.
Available actions: search(query), calculator(expr), finish(answer)

Format:
Thought: <reasoning>
Action: <tool>(<input>)
Observation: <result>
... repeat ...
Thought: I have the answer.
Action: finish(<final answer>)
"""

def run_react_agent(question: str, tools: dict, max_steps: int = 6):
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": question},
    ]
    for _ in range(max_steps):
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            stop=["Observation:"],   # let us inject the real observation
        )
        assistant_text = response.choices[0].message.content
        messages.append({"role": "assistant", "content": assistant_text})

        # Parse the Action line
        for line in assistant_text.splitlines():
            if line.startswith("Action:"):
                action_str = line.replace("Action:", "").strip()
                tool_name, _, arg = action_str.partition("(")
                arg = arg.rstrip(")")
                if tool_name == "finish":
                    return arg
                observation = tools[tool_name](arg)
                messages.append({"role": "user", "content": f"Observation: {observation}"})
                break
    return "Max steps reached"

# --- Tool definitions ---
import math, requests

def search(query: str) -> str:
    # Replace with real search API in production
    return f"[mock result for '{query}']"

def calculator(expr: str) -> str:
    try:
        return str(eval(expr, {"__builtins__": {}}, vars(math)))
    except Exception as e:
        return f"Error: {e}"

tools = {"search": search, "calculator": calculator}

# --- LangChain shortcut ---
from langchain import hub
from langchain.agents import create_react_agent, AgentExecutor
from langchain_openai import ChatOpenAI
from langchain.tools import Tool

llm = ChatOpenAI(model="gpt-4o-mini")
prompt = hub.pull("hwchase17/react")

lc_tools = [
    Tool(name="calculator", func=calculator, description="Evaluate math expressions"),
    Tool(name="search", func=search, description="Search the web for facts"),
]

agent = create_react_agent(llm, lc_tools, prompt)
executor = AgentExecutor(agent=agent, tools=lc_tools, verbose=True, max_iterations=6)
result = executor.invoke({"input": "What is sqrt(144) + the population of Iceland?"})
```

## Learning Path
1. Read the original ReAct paper (Yao et al., 2022)
2. Implement the Thought/Action/Observation loop manually with the OpenAI API
3. Add real tools: SerpAPI search, Python REPL, calculator
4. Explore `create_react_agent` in LangChain and read the generated prompt
5. Compare ReAct with Plan-and-Execute (upfront planning vs. interleaved)
6. Study stopping conditions and loop-detection strategies
7. Evaluate on HotpotQA / ALFWorld benchmarks

## What to Build
- [ ] From-scratch ReAct loop with OpenAI (no frameworks)
- [ ] Multi-step math + web-search agent (e.g. "GDP of France divided by population")
- [ ] ReAct agent with a Python REPL tool for data analysis tasks
- [ ] Side-by-side comparison: ReAct vs. plain GPT-4 on 10 multi-hop questions
- [ ] LangChain ReAct agent with custom tools and a retry-on-parse-error wrapper

## Related Folders
- `agentic-ai/a2a-protocol-main/` — agents built with ReAct can expose themselves via A2A
- `agentic-ai/agent-memory-management-main/` — add long-term memory to ReAct loops
- `agentic-ai/mcp-model-context-protocol-main/` — MCP tools plug directly into ReAct tool lists
