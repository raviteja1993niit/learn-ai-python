# 🧩 Outlines — Structured Generation

## What is Outlines?
Outlines is a Python library that guarantees structured output from LLMs using constrained decoding — not post-processing. It works by manipulating the model's logits at each token step so the output is always valid JSON, a regex match, or a fixed choice. No retries, no parsing errors.

## Why Learn It?
- Zero-failure structured extraction — the model *cannot* produce invalid output
- Works with local models (Transformers, vLLM) and OpenAI
- Faster than prompt-engineering alone; no retry loops needed
- Pydantic schema support means type-safe LLM outputs
- Critical skill for production AI pipelines that consume structured data

## Key Concepts
```python
import outlines
from pydantic import BaseModel
from enum import Enum
from typing import Optional

# --- Load a model (local Transformers) ---
model = outlines.models.transformers("mistralai/Mistral-7B-Instruct-v0.1")

# --- JSON generation from Pydantic schema ---
class UserProfile(BaseModel):
    name: str
    age: int
    email: str
    is_premium: bool

generator = outlines.generate.json(model, UserProfile)
profile = generator("Extract user info: John Doe, 34, john@example.com, premium member")
print(profile)  # UserProfile(name='John Doe', age=34, ...)

# --- Choice / enum constraint ---
class Sentiment(str, Enum):
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"

sentiment_gen = outlines.generate.choice(model, ["positive", "negative", "neutral"])
result = sentiment_gen("Classify: 'I love this product!'")
print(result)  # "positive"

# --- Regex constraint ---
phone_gen = outlines.generate.regex(model, r"\(\d{3}\) \d{3}-\d{4}")
phone = phone_gen("What is a sample US phone number?")

date_gen = outlines.generate.regex(model, r"\d{4}-\d{2}-\d{2}")
date = date_gen("When did WWII end?")

email_gen = outlines.generate.regex(model, r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
email = email_gen("Give me a sample email address.")

# --- Free text (no constraint) ---
text_gen = outlines.generate.text(model)
answer = text_gen("Explain black holes in one sentence.")

# --- OpenAI backend ---
openai_model = outlines.models.openai("gpt-4o-mini")
structured_gen = outlines.generate.json(openai_model, UserProfile)
result = structured_gen("Extract: Alice Smith, 28, alice@corp.com, free tier user")

# --- vLLM integration ---
# vllm_model = outlines.models.vllm("mistralai/Mistral-7B-Instruct-v0.1")
# generator = outlines.generate.json(vllm_model, UserProfile)
```

## Constrained Decoding vs Post-Processing
| Approach         | Reliability | Speed     | Complexity |
|------------------|-------------|-----------|------------|
| Post-processing  | ❌ Can fail | Fast      | Low        |
| Prompt-only JSON | ⚠️ 95%      | Fast      | Medium     |
| Outlines         | ✅ 100%     | Near same | Low        |
| Instructor       | ✅ ~99%     | + retries | Medium     |
| Guardrails       | ✅ ~99%     | + retries | High       |

## Learning Path
1. Install: `pip install outlines transformers`
2. Run a simple `generate.choice` on a small local model
3. Define a Pydantic schema and use `generate.json`
4. Add regex constraints for dates, phones, emails
5. Swap in OpenAI or vLLM backend
6. Integrate into a data extraction pipeline

## What to Build
- [ ] Invoice data extractor (vendor, amount, date) using Pydantic + JSON
- [ ] Multi-label classifier using `generate.choice` with enum
- [ ] Form auto-fill pipeline that validates phone/email with regex
- [ ] Compare output quality: Outlines vs raw GPT JSON mode
- [ ] Production REST API wrapping an Outlines structured extractor

## Related Folders
- `generative-ai/rag-pipeline-main/` — structure retrieved context into typed outputs
- `generative-ai/deepeval-llm-testing-main/` — evaluate structured output accuracy
- `agentic-ai/tool-calling-main/` — structured tool call arguments from LLMs
