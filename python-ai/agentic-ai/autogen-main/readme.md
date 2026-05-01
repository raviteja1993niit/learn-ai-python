# 🤖 AutoGen — Microsoft Multi-Agent Framework

## What is AutoGen?
AutoGen (by Microsoft Research) is a framework for building **multi-agent AI applications**
where multiple AI agents collaborate, debate, and solve complex tasks autonomously.

## AutoGen vs CrewAI vs LangGraph
| Feature | AutoGen | CrewAI | LangGraph |
|---------|---------|--------|-----------|
| Style | Conversation-based | Role-based crew | Graph/stateful |
| Code execution | ✅ Built-in | ❌ | ❌ |
| Human-in-loop | ✅ | Partial | ✅ |
| Best for | Code tasks | Structured workflows | Complex reasoning |

## Key Agents
```python
from autogen import AssistantAgent, UserProxyAgent, GroupChat

# AI assistant
assistant = AssistantAgent(
    name="Assistant",
    llm_config={"model": "gpt-4"}
)

# Human proxy (can execute code)
user_proxy = UserProxyAgent(
    name="User",
    code_execution_config={"work_dir": "coding"}
)

# Start conversation
user_proxy.initiate_chat(assistant, message="Write a Python web scraper")
```

## Learning Path
1. `pip install pyautogen`
2. Two-agent conversation (UserProxy + Assistant)
3. Code execution agent
4. GroupChat with multiple specialized agents
5. Tool use + function calling in agents

## What to Build
- [ ] Code review agent (write → review → fix loop)
- [ ] Research agent (web search → summarize → report)
- [ ] Data analysis agent (upload CSV → agent writes and runs analysis)
- [ ] Multi-agent debate system

## Related Folders
- `agentic-ai/Crew-AI-Crash-course-main/` — CrewAI alternative
- `agentic-ai/Agentic-AI-Application-main/` — custom agents
- `agentic-ai/Agentic-LanggraphCrash-course-main/` — LangGraph alternative