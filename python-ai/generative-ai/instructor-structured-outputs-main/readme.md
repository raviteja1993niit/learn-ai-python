# 📐 Instructor — Structured LLM Outputs via Pydantic

## What is Instructor?
Instructor is a Python library that patches LLM clients (OpenAI, Anthropic, Gemini, Ollama) to return validated Pydantic model instances instead of raw text. You define the exact shape of the data you want, pass `response_model=YourModel` to the chat call, and Instructor handles schema generation, JSON parsing, validation errors, and automatic retries — all transparently.

## Why Learn It?
- Eliminates all manual JSON parsing and regex extraction from LLM responses
- Automatic retry with validation error feedback when the model returns bad data
- Works across 10+ providers with the same API surface
- Nested models, lists, and optional fields just work — powered by Pydantic v2

## Key Concepts
```python
import instructor
from openai import OpenAI
from anthropic import Anthropic
from pydantic import BaseModel, Field
from typing import List, Optional

# --- Patch OpenAI client ---
client = instructor.from_openai(OpenAI())

# --- Simple structured extraction ---
class Person(BaseModel):
    name: str
    age: int
    email: Optional[str] = None

person = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=Person,
    messages=[{"role": "user", "content": "John Doe is 30 years old, reach him at john@doe.com"}],
)
print(person.name, person.age, person.email)

# --- Nested models ---
class Address(BaseModel):
    street: str
    city: str
    country: str

class Company(BaseModel):
    name: str
    founded: int
    headquarters: Address
    employees: int = Field(description="Approximate headcount")

company = client.chat.completions.create(
    model="gpt-4o",
    response_model=Company,
    messages=[{"role": "user", "content": "Tell me about OpenAI the company."}],
)
print(company.headquarters.city)

# --- List extraction ---
class Product(BaseModel):
    name: str
    price: float
    category: str

products = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=List[Product],
    messages=[{"role": "user", "content": "List 3 popular electronics with prices."}],
)
for p in products:
    print(p.name, p.price)

# --- max_retries for resilience ---
result = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=Person,
    max_retries=3,  # retries with validation error context
    messages=[{"role": "user", "content": "Extract: Alice, twenty-five, no email."}],
)

# --- Streaming partial objects ---
from instructor import Iterable as InstructorIterable
for partial_person in client.chat.completions.create(
    model="gpt-4o",
    response_model=InstructorIterable[Person],
    stream=True,
    messages=[{"role": "user", "content": "List 5 famous scientists with ages."}],
):
    print(partial_person)

# --- Anthropic support ---
anthropic_client = instructor.from_anthropic(Anthropic())
result = anthropic_client.messages.create(
    model="claude-3-5-haiku-20241022",
    max_tokens=512,
    response_model=Person,
    messages=[{"role": "user", "content": "Grace Hopper, 85, hopper@navy.mil"}],
)

# --- Async support ---
import instructor
from openai import AsyncOpenAI
import asyncio

async_client = instructor.from_openai(AsyncOpenAI())
async def extract():
    return await async_client.chat.completions.create(
        model="gpt-4o-mini", response_model=Person,
        messages=[{"role": "user", "content": "Bob, 40"}],
    )
```

## Learning Path
1. `pip install instructor` and patch your OpenAI client with `instructor.from_openai()`
2. Define a simple Pydantic model and extract it from an LLM response
3. Add nested models and optional fields
4. Extract a `List[MyModel]` from free-form text
5. Test `max_retries` by giving intentionally ambiguous input
6. Try streaming with `Iterable[MyModel]` for large extractions
7. Switch providers: patch Anthropic or Ollama client with `instructor.from_anthropic()`
8. Build an async extraction pipeline for batch processing

## What to Build
- [ ] Entity extractor: pull people, places, and dates from news articles
- [ ] Job posting normaliser: unstructured job description → typed `JobPosting` model
- [ ] Classification pipeline: route support tickets to departments using enum fields
- [ ] Async batch processor: extract structured data from 100+ documents in parallel
- [ ] Multi-provider benchmark: same extraction task across GPT, Claude, and Llama

## Related Folders
- `generative-ai\openai-function-calling-main\` — lower-level function calling that Instructor builds on
- `generative-ai\guardrails-ai-main\` — validation-focused alternative with on-fail actions
- `generative-ai\anthropic-claude-api-main\` — Anthropic client that Instructor can patch
