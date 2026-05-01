# 🔧 OpenAI Function Calling & Structured Outputs — Tool Use & Schema-Driven Responses

## What is OpenAI Function Calling?
Function calling lets you define tools (Python functions) that the model can invoke by returning a structured JSON payload instead of plain text. The model decides when to call a tool, what arguments to pass, and you execute the function and return results. Structured outputs extend this with Pydantic-validated, schema-enforced JSON responses.

## Why Learn It?
- Build agents that can query APIs, databases, and external services
- Replace brittle regex/prompt parsing with guaranteed JSON schemas
- Enable parallel tool execution for complex, multi-step workflows
- Foundation for every production-grade agentic system

## Key Concepts
```python
from openai import OpenAI
from pydantic import BaseModel
import json

client = OpenAI()

# --- Tool/Function Schema ---
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get current weather for a city",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "City name"},
                    "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]},
                },
                "required": ["city"],
            },
        },
    }
]

# --- Basic Function Calling ---
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}],
    tools=tools,
    tool_choice="auto",
)

msg = response.choices[0].message
if msg.tool_calls:
    for tool_call in msg.tool_calls:
        args = json.loads(tool_call.function.arguments)
        result = get_weather(**args)  # your function
        # Append tool result back into conversation
        messages.append({"role": "tool", "tool_call_id": tool_call.id, "content": str(result)})

# --- Structured Outputs with Pydantic ---
class WeatherReport(BaseModel):
    city: str
    temperature: float
    condition: str
    humidity: int

completion = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[{"role": "user", "content": "Give me a weather report for Paris"}],
    response_format=WeatherReport,
)
report: WeatherReport = completion.choices[0].message.parsed
print(report.city, report.temperature)

# --- JSON Mode (simpler, no schema enforcement) ---
resp = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Return JSON with name and age"}],
    response_format={"type": "json_object"},
)
```

## Learning Path
1. Understand OpenAI chat completions API basics
2. Define your first function schema (name/description/parameters/required)
3. Parse `tool_calls` from the response and execute functions
4. Return tool results and continue the conversation loop
5. Try parallel function calling (multiple tools in one response)
6. Upgrade to structured outputs with `client.beta.chat.completions.parse`
7. Add error handling, retries, and validation with Pydantic
8. Build a complete weather agent or database query agent

## What to Build
- [ ] Weather agent using OpenWeatherMap API + function calling
- [ ] SQL query agent: model writes SQL, function executes it, returns results
- [ ] Multi-tool research agent (search + summarise + save)
- [ ] Structured data extractor: parse unstructured text into typed Pydantic models
- [ ] Retry wrapper that re-calls on validation errors

## Related Folders
- `generative-ai\instructor-structured-outputs-main\` — higher-level structured output library built on top of function calling
- `agentic-ai\semantic-kernel-main\` — enterprise agentic framework using plugins/functions
- `generative-ai\anthropic-claude-api-main\` — Claude's equivalent tool use API
