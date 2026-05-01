# 🔵 Semantic Kernel — Microsoft's Enterprise AI Orchestration Framework

## What is Semantic Kernel?
Semantic Kernel (SK) is Microsoft's open-source SDK for building enterprise AI applications with Python and .NET. It provides a `Kernel` that orchestrates LLM services, plugins (collections of functions), memory with embeddings, and an automatic Planner that decomposes natural language goals into multi-step execution plans — all designed to integrate with Azure OpenAI and enterprise security patterns.

## Why Learn It?
- Microsoft's official framework for enterprise Copilot and agent development
- First-class Azure OpenAI integration with managed identity and compliance
- Planner enables goal-driven automation without manually scripting every step
- Built-in memory, filters/middleware, and chat history management

## Key Concepts
```python
import asyncio
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, AzureChatCompletion
from semantic_kernel.functions import kernel_function, KernelPlugin
from semantic_kernel.contents import ChatHistory
from semantic_kernel.connectors.ai.open_ai import OpenAITextEmbedding
from semantic_kernel.memory import SemanticTextMemory, VolatileMemoryStore

# --- Kernel setup ---
kernel = Kernel()

# Add OpenAI service
kernel.add_service(
    OpenAIChatCompletion(
        service_id="openai",
        ai_model_id="gpt-4o",
        # api_key loaded from OPENAI_API_KEY env var
    )
)

# --- Azure OpenAI (enterprise pattern) ---
# kernel.add_service(AzureChatCompletion(
#     service_id="azure-openai",
#     deployment_name="gpt-4o",
#     endpoint="https://your-resource.openai.azure.com/",
#     api_key="...",  # or use DefaultAzureCredential()
# ))

# --- @kernel_function decorator: define a plugin ---
class MathPlugin:
    @kernel_function(name="add", description="Add two numbers together")
    def add(self, a: float, b: float) -> float:
        """Add two numbers together."""
        return a + b

    @kernel_function(name="multiply", description="Multiply two numbers")
    def multiply(self, a: float, b: float) -> float:
        return a * b

kernel.add_plugin(MathPlugin(), plugin_name="Math")

# --- Semantic (prompt template) functions ---
summarise_fn = kernel.add_function(
    plugin_name="WritingPlugin",
    function_name="Summarise",
    prompt="Summarise the following text in one sentence:\n{{$input}}",
    description="Summarises text to one sentence",
)

# --- Invoke a semantic function ---
async def run_semantic():
    result = await kernel.invoke(
        summarise_fn,
        input="Semantic Kernel is a framework that helps developers build AI applications...",
    )
    print(result)

# --- Invoke a native function ---
async def run_native():
    result = await kernel.invoke(
        kernel.plugins["Math"]["add"],
        a=10.0, b=25.0,
    )
    print(result)  # 35.0

# --- Chat History for multi-turn ---
chat_history = ChatHistory()
chat_history.add_system_message("You are a helpful assistant.")
chat_history.add_user_message("What is the capital of France?")

chat_service = kernel.get_service("openai")
async def chat():
    response = await chat_service.get_chat_message_content(
        chat_history=chat_history,
        settings=chat_service.get_prompt_execution_settings_class()(service_id="openai"),
    )
    chat_history.add_assistant_message(str(response))
    return response

# --- Memory with embeddings ---
async def setup_memory():
    embedding_service = OpenAITextEmbedding(ai_model_id="text-embedding-3-small")
    memory = SemanticTextMemory(storage=VolatileMemoryStore(), embeddings_generator=embedding_service)
    await memory.save_information("facts", id="sk_fact", text="Semantic Kernel was created by Microsoft.")
    results = await memory.search("facts", "Who made Semantic Kernel?")
    print(results[0].text)

# --- Filters / Middleware (hook before/after function calls) ---
from semantic_kernel.filters import FunctionInvocationContext
async def logging_filter(context: FunctionInvocationContext, next):
    print(f"[BEFORE] Calling {context.function.name}")
    await next(context)
    print(f"[AFTER] Result: {context.result}")

kernel.add_function_invocation_filter(logging_filter)

asyncio.run(run_semantic())
```

## Learning Path
1. `pip install semantic-kernel` and create a `Kernel` with `OpenAIChatCompletion`
2. Add a semantic (prompt template) function and invoke it with `kernel.invoke()`
3. Write a `@kernel_function` plugin class and call its methods via the kernel
4. Build a multi-turn chat loop with `ChatHistory`
5. Add memory: embed text, save to `VolatileMemoryStore`, search by semantic similarity
6. Explore the Planner: give it a goal and watch it auto-compose plugin calls
7. Add a filter/middleware for logging, auth, or rate-limiting
8. Switch to `AzureChatCompletion` and test with a real Azure OpenAI deployment

## What to Build
- [ ] Personal assistant with memory: remembers facts across conversations
- [ ] Code review plugin: @kernel_function reads a file, calls LLM, returns review
- [ ] Auto-planner: give a natural language goal, SK plans and executes plugin steps
- [ ] Enterprise chatbot with Azure OpenAI + managed identity (no API key in code)
- [ ] RAG pipeline: embed documents into memory, retrieve on query, generate answer

## Related Folders
- `agentic-ai\` — sibling agent frameworks (LangGraph, CrewAI, AutoGen)
- `generative-ai\openai-function-calling-main\` — the underlying tool use mechanism SK uses
- `generative-ai\litellm-main\` — multi-provider alternative to SK's service connectors
