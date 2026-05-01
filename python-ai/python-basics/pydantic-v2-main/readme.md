# 🧱 Pydantic v2 — Data Validation & Settings Management

## What is Pydantic v2?
Pydantic v2 is a Python data validation library built on Rust for blazing-fast runtime type checking. It lets you define data schemas using Python type hints and automatically validates, parses, and serializes data. It is the backbone of FastAPI and widely used for config management and LLM output parsing.

## Why Learn It?
- FastAPI uses Pydantic models for request/response validation out of the box
- LLM frameworks (LangChain, Instructor) rely on Pydantic to enforce structured outputs
- v2 is 5–50x faster than v1 and introduces powerful new APIs
- `BaseSettings` simplifies loading environment variables and secrets safely

## Key Concepts
```python
from pydantic import BaseModel, Field, field_validator, model_validator
from pydantic_settings import BaseSettings
from typing import Optional

# --- BaseModel: define schema with typed fields ---
class UserProfile(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)   # required, length constrained
    age: int  = Field(..., ge=0, le=130)                  # ge=greater-equal, le=less-equal
    email: str
    score: Optional[float] = None                         # optional field, defaults to None

    @field_validator("email")
    @classmethod
    def email_must_have_at(cls, v: str) -> str:
        # single-field validator: runs before model_validator
        if "@" not in v:
            raise ValueError("Invalid email address")
        return v.lower()                                  # normalise to lowercase

    @model_validator(mode="after")
    def check_score_for_adults(self) -> "UserProfile":
        # cross-field validator: runs after all fields are set
        if self.age >= 18 and self.score is None:
            raise ValueError("Adults must supply a score")
        return self

# Instantiate and validate — raises ValidationError on bad input
user = UserProfile(name="Alice", age=30, email="Alice@Example.com", score=9.5)

print(user.model_dump())            # → {'name': 'Alice', 'age': 30, ...}
print(user.model_dump_json())       # → compact JSON string
print(UserProfile.model_json_schema())  # → JSON Schema dict (for OpenAI tool calling)

# --- BaseSettings: load config from .env / environment variables ---
class AppSettings(BaseSettings):
    openai_api_key: str             # required — raises error if not set
    debug: bool = False             # optional with default
    model_name: str = "gpt-4o"     # overridable via MODEL_NAME env var

    class Config:
        env_file = ".env"           # also reads from .env file automatically

settings = AppSettings()
print(settings.model_name)         # prints env var value or default

# --- Nested models (used heavily in LLM output parsing) ---
class Address(BaseModel):
    city: str
    country: str = "India"         # default value

class Company(BaseModel):
    name: str
    hq: Address                    # nested model — validated recursively

c = Company(name="OpenAI", hq={"city": "San Francisco", "country": "USA"})
print(c.model_dump())
```

## Learning Path
1. `pip install pydantic pydantic-settings`
2. Define `BaseModel` classes with typed fields and `Field` constraints
3. Write `@field_validator` and `@model_validator` for cross-field logic
4. Use `BaseSettings` to manage API keys and app config from `.env`
5. Integrate with FastAPI routes and explore `model_json_schema()` for LLM tool calling

## What to Build
- [ ] A config loader that validates `.env` values and raises clear errors on startup
- [ ] A FastAPI endpoint that accepts a Pydantic request model and returns a typed response
- [ ] A structured output parser that forces an LLM to return valid JSON matching a schema

## Related Folders
- `python-basics/asyncio-concurrency-main/` — async FastAPI routes pair naturally with Pydantic models
- `machine-learning/xgboost-tutorial-main/` — use Pydantic to validate ML pipeline config objects
