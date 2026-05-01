# LangChain V1 — Code Examples Reference

## Example 1: Simple LLM Call with ChatOpenAI
```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
response = llm.invoke("What is the capital of France?")
print(response.content)  # Paris
print(type(response))    # <class 'langchain_core.messages.ai.AIMessage'>
```

## Example 2: ChatGroq — Fast Inference
```python
from langchain_groq import ChatGroq

llm = ChatGroq(
    model="llama3-70b-8192",
    temperature=0,
    api_key="your-groq-api-key"
)
response = llm.invoke("Explain transformers in 2 sentences.")
print(response.content)
```

## Example 3: ChatOllama — Local Models
```python
from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3", temperature=0.7)
response = llm.invoke("Write a haiku about Python programming.")
print(response.content)
```

## Example 4: ChatPromptTemplate with Variables
```python
from langchain_core.prompts import ChatPromptTemplate

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant specialized in {domain}."),
    ("human", "Answer this question: {question}")
])

formatted = prompt.format_messages(
    domain="machine learning",
    question="What is gradient descent?"
)
for msg in formatted:
    print(f"{msg.type}: {msg.content}")
```

## Example 5: SystemMessage and HumanMessage
```python
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o-mini")
messages = [
    SystemMessage(content="You are a pirate. Always respond like a pirate."),
    HumanMessage(content="What is 2 + 2?")
]
response = llm.invoke(messages)
print(response.content)  # Arrr, that be 4, matey!
```

## Example 6: StrOutputParser Chain
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    ("human", "{input}")
])
llm = ChatOpenAI(model="gpt-4o-mini")
parser = StrOutputParser()

chain = prompt | llm | parser

result = chain.invoke({"input": "Tell me a joke."})
print(result)        # Plain string, not AIMessage
print(type(result))  # <class 'str'>
```

## Example 7: JsonOutputParser
```python
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

parser = JsonOutputParser()
prompt = ChatPromptTemplate.from_messages([
    ("system", "Return your answer as valid JSON."),
    ("human", "Give me info about {topic}. Return JSON with keys: name, description, year_founded.")
])
llm = ChatOpenAI(model="gpt-4o-mini")

chain = prompt | llm | parser
result = chain.invoke({"topic": "Python programming language"})
print(result)        # {'name': 'Python', 'description': '...', 'year_founded': 1991}
print(type(result))  # <class 'dict'>
```

## Example 8: PydanticOutputParser
```python
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field
from typing import List

class MovieReview(BaseModel):
    title: str = Field(description="Movie title")
    rating: float = Field(description="Rating from 0 to 10")
    pros: List[str] = Field(description="List of positive aspects")
    cons: List[str] = Field(description="List of negative aspects")
    summary: str = Field(description="One-sentence summary")

parser = PydanticOutputParser(pydantic_object=MovieReview)

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a movie critic. {format_instructions}"),
    ("human", "Review the movie: {movie}")
])
prompt = prompt.partial(format_instructions=parser.get_format_instructions())

llm = ChatOpenAI(model="gpt-4o-mini")
chain = prompt | llm | parser

review = chain.invoke({"movie": "Inception"})
print(review.title)   # Inception
print(review.rating)  # 9.0
print(review.pros)    # ['Mind-bending plot', 'Stunning visuals', ...]
```

## Example 9: LCEL Chain — Full Pipeline
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

system_msg = "You are an expert {role}."
human_msg = "{task}"

prompt = ChatPromptTemplate.from_messages([
    ("system", system_msg),
    ("human", human_msg)
])
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.3)
parser = StrOutputParser()

chain = prompt | llm | parser

output = chain.invoke({"role": "data scientist", "task": "Explain overfitting."})
print(output)
```

## Example 10: Streaming with stream()
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([("human", "{input}")])
llm = ChatOpenAI(model="gpt-4o-mini", streaming=True)
chain = prompt | llm | StrOutputParser()

print("Streaming output:")
for chunk in chain.stream({"input": "Write a short poem about AI."}):
    print(chunk, end="", flush=True)
print()  # newline at end
```

## Example 11: Batch Calls with batch()
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("human", "Translate '{text}' to {language}.")
])
llm = ChatOpenAI(model="gpt-4o-mini")
chain = prompt | llm | StrOutputParser()

inputs = [
    {"text": "Hello", "language": "Spanish"},
    {"text": "Hello", "language": "French"},
    {"text": "Hello", "language": "Japanese"},
    {"text": "Hello", "language": "Arabic"},
]
results = chain.batch(inputs)
for r in results:
    print(r)
```

## Example 12: ConversationBufferMemory
```python
from langchain.memory import ConversationBufferMemory
from langchain_openai import ChatOpenAI
from langchain.chains import ConversationChain

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
memory = ConversationBufferMemory(return_messages=True)

conversation = ConversationChain(llm=llm, memory=memory, verbose=True)

conversation.predict(input="Hi! My name is Alice.")
conversation.predict(input="What's my name?")  # Remembers Alice
conversation.predict(input="What did I say first?")
print(memory.chat_memory.messages)
```

## Example 13: ConversationSummaryMemory
```python
from langchain.memory import ConversationSummaryMemory
from langchain_openai import ChatOpenAI
from langchain.chains import ConversationChain

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
memory = ConversationSummaryMemory(llm=llm, return_messages=True)

conversation = ConversationChain(llm=llm, memory=memory)

conversation.predict(input="I'm building a recommendation system for e-commerce.")
conversation.predict(input="It needs to handle 1 million products.")
conversation.predict(input="I'm considering collaborative filtering.")
print("Summary:", memory.load_memory_variables({})["history"])
```

## Example 14: ChatMessageHistory with RunnableWithMessageHistory
```python
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

store = {}

def get_session_history(session_id: str) -> InMemoryChatMessageHistory:
    if session_id not in store:
        store[session_id] = InMemoryChatMessageHistory()
    return store[session_id]

llm = ChatOpenAI(model="gpt-4o-mini")
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant."),
    MessagesPlaceholder(variable_name="history"),
    ("human", "{input}")
])

chain = prompt | llm
chain_with_history = RunnableWithMessageHistory(
    chain,
    get_session_history,
    input_messages_key="input",
    history_messages_key="history"
)

config = {"configurable": {"session_id": "user_001"}}
chain_with_history.invoke({"input": "My favorite color is blue."}, config=config)
response = chain_with_history.invoke({"input": "What's my favorite color?"}, config=config)
print(response.content)
```

## Example 15: hub.pull() — Use Community Prompts
```python
from langchain import hub
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import StrOutputParser

prompt = hub.pull("hwchase17/openai-tools-agent")
print(prompt)  # Inspect the pulled prompt structure

llm = ChatOpenAI(model="gpt-4o-mini")
# Use prompt in your agent setup (see tool calling examples)
```

## Example 16: with_structured_output()
```python
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field
from typing import List

class PersonInfo(BaseModel):
    name: str = Field(description="Person's full name")
    age: int = Field(description="Person's age")
    occupation: str = Field(description="Person's job or profession")
    skills: List[str] = Field(description="List of key skills")

llm = ChatOpenAI(model="gpt-4o-mini")
structured_llm = llm.with_structured_output(PersonInfo)

result = structured_llm.invoke(
    "Tell me about a fictional data scientist named Sarah who is 32 years old."
)
print(result.name)       # Sarah
print(result.age)        # 32
print(result.occupation) # Data Scientist
print(result.skills)     # ['Python', 'ML', 'SQL', ...]
```

## Example 17: @tool Decorator
```python
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI

@tool
def get_weather(city: str) -> str:
    """Get current weather for a given city. Returns temperature and conditions."""
    weather_data = {
        "London": "15 degrees C, Cloudy",
        "Paris": "20 degrees C, Sunny",
        "New York": "22 degrees C, Partly cloudy"
    }
    return weather_data.get(city, f"Weather data not available for {city}")

@tool
def calculate(expression: str) -> str:
    """Evaluate a mathematical expression safely."""
    try:
        result = eval(expression, {"__builtins__": {}}, {})
        return str(result)
    except Exception as e:
        return f"Error: {str(e)}"

print(get_weather.name)         # get_weather
print(get_weather.description)  # Get current weather...
print(get_weather.invoke({"city": "London"}))  # 15 degrees C, Cloudy
```

## Example 18: bind_tools()
```python
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

@tool
def search_web(query: str) -> str:
    """Search the web for information about a topic."""
    return f"Search results for: {query} - [simulated results]"

@tool
def get_stock_price(ticker: str) -> str:
    """Get the current stock price for a given ticker symbol."""
    prices = {"AAPL": "182.50", "GOOGL": "141.20", "MSFT": "420.00"}
    return prices.get(ticker, "Unknown ticker")

llm = ChatOpenAI(model="gpt-4o-mini")
llm_with_tools = llm.bind_tools([search_web, get_stock_price])

response = llm_with_tools.invoke([
    HumanMessage(content="What is the current price of Apple stock?")
])
print(response.tool_calls)
# [{'name': 'get_stock_price', 'args': {'ticker': 'AAPL'}, ...}]
```

## Example 19: StreamingStdOutCallbackHandler
```python
from langchain_core.callbacks import StreamingStdOutCallbackHandler
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

callback = StreamingStdOutCallbackHandler()

llm = ChatOpenAI(
    model="gpt-4o-mini",
    streaming=True,
    callbacks=[callback]
)

# Tokens print to stdout automatically as they are generated
response = llm.invoke([
    HumanMessage(content="Count from 1 to 10 slowly, with a comment for each number.")
])
```

## Example 20: Async with astream()
```python
import asyncio
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([("human", "{input}")])
llm = ChatOpenAI(model="gpt-4o-mini", streaming=True)
chain = prompt | llm | StrOutputParser()

async def stream_response():
    async for chunk in chain.astream({"input": "List 5 Python best practices."}):
        print(chunk, end="", flush=True)
    print()

asyncio.run(stream_response())
```

## Example 21: Multi-Turn Conversation (Manual History)
```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

messages = [
    SystemMessage(content="You are a Python tutor. Give concise, clear explanations."),
]

def chat(user_input: str) -> str:
    messages.append(HumanMessage(content=user_input))
    response = llm.invoke(messages)
    messages.append(AIMessage(content=response.content))
    return response.content

print(chat("What is a list comprehension?"))
print(chat("Can you give me an example?"))
print(chat("What about dict comprehensions?"))
print(f"Total messages in history: {len(messages)}")
```

## Example 22: RunnableParallel
```python
from langchain_core.runnables import RunnableParallel
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = ChatOpenAI(model="gpt-4o-mini")
parser = StrOutputParser()

summarize_prompt = ChatPromptTemplate.from_messages([
    ("human", "Summarize this in one sentence: {text}")
])
sentiment_prompt = ChatPromptTemplate.from_messages([
    ("human", "What is the sentiment (positive/negative/neutral) of: {text}")
])

summarize_chain = summarize_prompt | llm | parser
sentiment_chain = sentiment_prompt | llm | parser

parallel_chain = RunnableParallel(
    summary=summarize_chain,
    sentiment=sentiment_chain
)

result = parallel_chain.invoke({
    "text": "I absolutely loved the new product launch! The features are amazing."
})
print("Summary:", result["summary"])
print("Sentiment:", result["sentiment"])
```