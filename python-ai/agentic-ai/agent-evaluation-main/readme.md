# 📊 Agent Evaluation Frameworks

## What is Agent Evaluation?
Agent evaluation measures whether an AI agent not only reaches the right answer, but follows a correct reasoning trajectory — choosing the right tools, in the right order, with the right inputs. Unlike single-turn LLM evals, agent evals must assess multi-step behavior over time.

## Why Learn It?
- Agents can give correct answers via wrong reasoning — evals catch this
- Tool selection mistakes compound across steps; step-level evals find root causes
- LangSmith + LangGraph makes tracing and dataset-based evaluation straightforward
- LLM-as-judge enables scalable automated evaluation without human labels
- Essential for safely deploying agents in production workflows

## Key Concepts
```python
from langsmith import Client
from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langgraph.graph import StateGraph
from langchain_openai import ChatOpenAI
from typing import TypedDict, Annotated
import operator

# --- Define a simple LangGraph agent to evaluate ---
class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    tool_calls: list
    final_answer: str

# --- LangSmith: create evaluation dataset ---
client = Client()

dataset = client.create_dataset(
    dataset_name="agent-eval-v1",
    description="Multi-step agent evaluation cases",
)

client.create_examples(
    inputs=[
        {"question": "What is 15% of 240?"},
        {"question": "Search for the CEO of OpenAI and return their name."},
    ],
    outputs=[
        {"expected_answer": "36", "expected_tools": ["calculator"]},
        {"expected_answer": "Sam Altman", "expected_tools": ["web_search"]},
    ],
    dataset_id=dataset.id,
)

# --- LLM-as-judge evaluator ---
from langsmith.schemas import Example, Run

def tool_call_accuracy(run: Run, example: Example) -> dict:
    expected = example.outputs.get("expected_tools", [])
    actual = [tc["name"] for tc in run.outputs.get("tool_calls", [])]
    correct = sum(1 for t in expected if t in actual)
    score = correct / max(len(expected), 1)
    return {"key": "tool_call_accuracy", "score": score}

def answer_correctness(run: Run, example: Example) -> dict:
    expected = example.outputs.get("expected_answer", "")
    actual = run.outputs.get("final_answer", "")
    match = expected.lower().strip() in actual.lower().strip()
    return {"key": "answer_correctness", "score": 1.0 if match else 0.0}

# --- TrajectoryCritic pattern (step-level) ---
from langchain_openai import ChatOpenAI

critic_llm = ChatOpenAI(model="gpt-4o-mini")

def trajectory_critic(steps: list[dict]) -> dict:
    trajectory_str = "\n".join(
        f"Step {i+1}: tool={s['tool']}, input={s['input']}, output={s['output']}"
        for i, s in enumerate(steps)
    )
    prompt = f"""Evaluate this agent trajectory for correctness and efficiency.
Trajectory:
{trajectory_str}

Rate: trajectory_accuracy (0-1), unnecessary_steps (count), reasoning_quality (0-1)
Respond as JSON."""
    response = critic_llm.invoke(prompt)
    return response  # parse JSON from response.content

# --- Run evaluation ---
results = evaluate(
    lambda inputs: {"final_answer": "36", "tool_calls": [{"name": "calculator"}]},
    data="agent-eval-v1",
    evaluators=[tool_call_accuracy, answer_correctness],
    experiment_prefix="agent-v1-baseline",
)

# Key metrics summary
print(f"tool_call_accuracy: {results.aggregate_metrics.get('tool_call_accuracy'):.2f}")
print(f"answer_correctness: {results.aggregate_metrics.get('answer_correctness'):.2f}")
```

## Evaluation Dimensions
| Dimension         | Level   | Tool                        |
|-------------------|---------|-----------------------------|
| Final answer      | Outcome | LangSmith evaluator         |
| Tool selection    | Step    | tool_call_accuracy metric   |
| Trajectory        | Path    | TrajectoryCritic (LLM judge)|
| Latency           | Perf    | LangSmith trace timing      |
| Cost              | Perf    | token count × price         |
| Success rate      | Outcome | pass/fail across dataset    |

## Learning Path
1. Build a simple LangGraph agent with 2–3 tools
2. Add LangSmith tracing (`LANGCHAIN_TRACING_V2=true`)
3. Create a dataset with `client.create_dataset`
4. Write `tool_call_accuracy` and `answer_correctness` evaluators
5. Implement TrajectoryCritic with an LLM judge
6. Automate evaluation in CI with `evaluate()`

## What to Build
- [ ] Eval harness for a research agent (search + summarize + cite)
- [ ] Step-level trajectory scorer for a multi-tool agent
- [ ] AgentBench-style leaderboard comparing 3 agent configurations
- [ ] Human feedback UI that logs ratings back to LangSmith
- [ ] Regression test that fails CI if `success_rate` drops below 80%

## Related Folders
- `agentic-ai/langgraph-agents-main/` — agents to evaluate
- `agentic-ai/tool-calling-main/` — tool use patterns under evaluation
- `generative-ai/deepeval-llm-testing-main/` — single-turn LLM evaluation
