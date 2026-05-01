# 🛡️ Guardrails AI — Validation, Safety & Quality Control for LLM Outputs

## What is Guardrails AI?
Guardrails AI is a Python framework that wraps LLM calls with validators to enforce output quality, safety, and format constraints. You define a `Guard` with validators (e.g., no toxic language, no PII, valid length), run your LLM call through it, and Guardrails automatically detects violations and applies on-fail actions like fixing, re-asking the LLM, or raising an exception.

## Why Learn It?
- Production LLMs produce unpredictable outputs — validators catch failures before they reach users
- Built-in validators for PII detection, toxicity, regex matching, JSON structure, and more
- `reask` action automatically feeds validation errors back to the LLM for self-correction
- Guardrails Hub offers 50+ community validators ready to plug in

## Key Concepts
```python
from guardrails import Guard
from guardrails.hub import ToxicLanguage, DetectPII, ValidLength, RegexMatch
import openai

# --- Basic Guard with multiple validators ---
guard = Guard().use_many(
    ToxicLanguage(threshold=0.5, on_fail="exception"),
    ValidLength(min=10, max=500, on_fail="fix"),
    DetectPII(pii_entities=["EMAIL_ADDRESS", "PHONE_NUMBER"], on_fail="filter"),
)

# --- Guard.__call__ wrapping an LLM function ---
raw_llm_output = "Here is the answer: john@example.com is the contact."
result = guard.parse(raw_llm_output)
print(result.validated_output)  # PII filtered out

# --- Guard with OpenAI integration ---
guard_with_llm = Guard().use_many(
    ToxicLanguage(on_fail="reask"),
    ValidLength(min=20, max=300, on_fail="reask"),
)
response = guard_with_llm(
    openai.chat.completions.create,
    prompt="Write a product review for headphones.",
    model="gpt-4o",
    max_tokens=256,
)
print(response.validated_output)

# --- RegexMatch validator ---
phone_guard = Guard().use(
    RegexMatch(regex=r"^\+?[1-9]\d{7,14}$", on_fail="exception"),
)

# --- on_fail actions ---
# "fix"       → auto-correct the output (e.g. truncate length)
# "reask"     → re-send to LLM with validation error feedback
# "exception" → raise ValidationError immediately
# "filter"    → remove violating content from the output
# "noop"      → log but do not alter output

# --- Custom Validator ---
from guardrails import Validator, register_validator
from guardrails.validators import PassResult, FailResult

@register_validator(name="no-placeholder-text", data_type="string")
class NoPlaceholderText(Validator):
    def validate(self, value, metadata):
        if "TODO" in value or "PLACEHOLDER" in value:
            return FailResult(error_message="Output contains placeholder text")
        return PassResult()

custom_guard = Guard().use(NoPlaceholderText(on_fail="reask"))

# --- Hallucination detection pattern ---
from guardrails.hub import SimilarToDocument
factual_guard = Guard().use(
    SimilarToDocument(
        document="The Eiffel Tower is located in Paris, France.",
        threshold=0.7,
        on_fail="exception",
    )
)
```

## Learning Path
1. Install `guardrails-ai` and run `guardrails hub install hub://guardrails/toxic_language`
2. Create a basic `Guard` with `ValidLength` and test with sample text
3. Add `ToxicLanguage` and `DetectPII` validators with different `on_fail` actions
4. Wrap an OpenAI call with a Guard and observe `reask` behavior
5. Explore Guardrails Hub for domain-specific validators
6. Write a custom `Validator` subclass for your business rules
7. Integrate with LangChain using `GuardrailsOutputParser`
8. Build a hallucination detection pipeline with `SimilarToDocument`

## What to Build
- [ ] Safe customer support bot: filter PII and toxicity from all LLM responses
- [ ] Structured data extractor with schema validation and auto-reask on malformed JSON
- [ ] Content moderation pipeline for user-generated content review
- [ ] Custom validator for domain-specific compliance rules (finance, healthcare)
- [ ] Hallucination detector: validate model claims against a reference document

## Related Folders
- `generative-ai\instructor-structured-outputs-main\` — Pydantic-based structured output alternative
- `generative-ai\openai-function-calling-main\` — schema enforcement via function calling
- `generative-ai\litellm-main\` — multi-provider LLM calls to wrap with guards
