# LLM App Patterns: Code Assistant, AI Search, Chatbot — Complete Reference

## Table of Contents
**CODE ASSISTANT**
1. System Prompt for Coding  2. Code Generation  3. Code Explanation
4. Code Review  5. Debugging  6. Unit Test Generation  7. Documentation
8. Refactoring  9. Multi-language Support

**AI SEARCH ENGINE**
10. Web Search Tools Overview  11. LLM + Search Pattern  12. Search-Summarise-Cite
13. Multi-source Aggregation  14. Query Reformulation

**SALES/SUPPORT CHATBOT**
15. Rasa Framework  16. Intent & Entity  17. Dialogue Management
18. Custom Actions  19. LLM-based Chatbot  20. Memory Patterns  21. Guardrails

---

## 1. System Prompt Design for Coding Assistants

The system prompt defines the coding assistant's behaviour, style, and constraints.

### Template
```
You are an expert {language} developer with 10+ years experience.

When writing code:
- Write clean, readable, well-documented code
- Include type hints for all functions and parameters
- Add docstrings in Google format
- Follow PEP 8 (Python) / standard style guides
- Handle edge cases and raise appropriate exceptions
- Include usage example in docstring

When explaining code:
- Explain what the code does in plain English first
- Then go through key parts step by step
- Point out any potential issues or improvements

When reviewing code:
- Check for: bugs, security issues, performance, style, testing coverage
- Be specific: line numbers (approximate), severity (high/medium/low)
```

### Language-specific Additions
- Python: PEP 8, type hints, docstrings, pytest patterns
- JavaScript: ESLint rules, JSDoc, async/await patterns
- TypeScript: strict mode, interfaces over types where appropriate
- Java: Javadoc, design patterns, SOLID principles
- Go: gofmt, exported vs unexported, error handling idioms

---

## 2. Code Generation

Best practices for LLM code generation.

### Effective Prompts
```python
# Poor prompt
"Write a function to process data."

# Good prompt
"""Write a Python function that:
1. Accepts a list of dictionaries with keys: name (str), score (int)
2. Filters out entries where score < 60
3. Returns a sorted list (by score, descending) of (name, score) tuples
4. Include type hints, docstring, and a usage example
5. Handle edge cases: empty list, missing keys"""
```

### Code Generation Function
```python
from openai import OpenAI
client = OpenAI()

def generate_code(spec, language="Python", style="professional"):
    system = f"""You are an expert {language} developer.
Write clean, documented, tested {language} code.
Style: {style}. Include type hints and docstrings.
Return ONLY the code block, no explanation."""

    r = client.chat.completions.create(
        model="gpt-4o",
        temperature=0.3,   # lower temp for more reliable code
        messages=[
            {"role":"system","content":system},
            {"role":"user","content":spec}
        ]
    )
    return r.choices[0].message.content

print(generate_code("Binary search with early exit for duplicates"))
```

---

## 3. Code Explanation

Prompting patterns for explaining existing code.

```python
CODE_EXPLAIN_SYSTEM = """Explain this code to a junior developer.
Structure your explanation:
1. HIGH LEVEL: What does this code do? (1-2 sentences)
2. KEY COMPONENTS: Explain each major function/class
3. LOGIC FLOW: Walk through the execution step by step
4. GOTCHAS: Any tricky or non-obvious parts
5. IMPROVEMENTS: What would you change and why?"""

def explain_code(code, audience="junior"):
    prompts = {
        "junior": "Explain simply, avoid jargon, use analogies",
        "senior": "Focus on architecture, patterns, and trade-offs",
        "business": "Explain what the code accomplishes in business terms"
    }
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":CODE_EXPLAIN_SYSTEM + f"\nAudience: {prompts[audience]}"},
            {"role":"user","content":f"```python\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## 4. Code Review

Structured code review with severity ratings.

```python
from pydantic import BaseModel
from typing import List

class Issue(BaseModel):
    severity: str     # high/medium/low
    category: str     # bug/security/performance/style/testing
    line_ref: str     # approximate line or function name
    description: str
    suggestion: str

class ReviewReport(BaseModel):
    language: str
    issues: List[Issue]
    overall_score: int  # 0-100
    summary: str
    positive_aspects: List[str]

def review_code(code):
    r = client.beta.chat.completions.parse(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"You are a senior code reviewer. Be thorough but constructive."},
            {"role":"user","content":f"Review this code:\n```\n{code}\n```"}
        ],
        response_format=ReviewReport
    )
    return r.choices[0].message.parsed
```

---

## 5. Debugging

Error message + code → root cause + fix.

```python
DEBUG_SYSTEM = """You are a debugging expert.
Given code and an error message:
1. ROOT CAUSE: Exactly why the error occurs
2. FIX: Corrected code
3. EXPLANATION: Why your fix works
4. PREVENTION: How to avoid this in future
5. TEST: A test case that would catch this bug"""

def debug(code, error_msg, language="Python"):
    r = client.chat.completions.create(
        model="gpt-4o",
        temperature=0.2,
        messages=[
            {"role":"system","content":DEBUG_SYSTEM},
            {"role":"user","content":f"Language: {language}\n\nCode:\n```\n{code}\n```\n\nError:\n{error_msg}"}
        ]
    )
    return r.choices[0].message.content
```

---

## 6. Unit Test Generation

Auto-generate tests for any function.

```python
TEST_SYSTEM = """Generate comprehensive unit tests using pytest.
Tests must cover:
- Happy path (normal input)
- Edge cases (empty, None, boundary values)
- Error cases (should raise exceptions)
- Type validation if relevant

Use pytest fixtures and parametrize where appropriate.
Include descriptive test function names: test_<function>_<scenario>."""

def generate_tests(function_code, framework="pytest"):
    r = client.chat.completions.create(
        model="gpt-4o",
        temperature=0.3,
        messages=[
            {"role":"system","content":TEST_SYSTEM.replace("pytest",framework)},
            {"role":"user","content":f"Generate tests for:\n```python\n{function_code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## 7. Documentation Generation

Auto-generate docstrings, README, and API documentation.

```python
def add_docstrings(code, style="Google"):
    styles = {
        "Google": "Use Google docstring format with Args, Returns, Raises, Example sections.",
        "NumPy": "Use NumPy docstring format with Parameters, Returns, Examples sections.",
        "Sphinx": "Use reStructuredText Sphinx format."
    }
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":f"Add docstrings to all functions and classes. {styles[style]} Keep existing code exactly the same. Only add docstrings."},
            {"role":"user","content":f"```python\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## 8. Refactoring Suggestions

Analyse code and suggest structural improvements.

```python
REFACTOR_SYSTEM = """Analyse this code for refactoring opportunities.
Focus on:
1. SOLID principles violations
2. DRY (Don't Repeat Yourself) violations
3. Functions doing too much (Single Responsibility)
4. Magic numbers and hardcoded values
5. Naming clarity
6. Design pattern opportunities (Strategy, Factory, Observer, etc.)

Provide both the analysis AND refactored code."""

def suggest_refactoring(code):
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"system","content":REFACTOR_SYSTEM},
                  {"role":"user","content":f"```\n{code}\n```"}]
    )
    return r.choices[0].message.content
```

---

## 9. Multi-language Code Assistant

```python
LANGUAGES = {
    "python": "Python 3.10+, PEP 8, type hints, pytest",
    "javascript": "ES2022+, async/await, Jest for tests",
    "typescript": "TypeScript 5+, strict mode, interfaces",
    "java": "Java 17+, Maven, JUnit 5",
    "go": "Go 1.21+, idiomatic error handling",
    "rust": "Rust 2021 edition, ownership patterns",
    "sql": "PostgreSQL dialect, CTEs, window functions"
}

def polyglot_assistant(code_or_spec, task, source_lang=None, target_lang=None):
    if task == "translate" and source_lang and target_lang:
        prompt = f"Translate this {source_lang} code to idiomatic {target_lang}:\n```{source_lang}\n{code_or_spec}\n```"
    elif task == "review":
        lang = source_lang or "unknown"
        prompt = f"Review this {lang} code:\n```\n{code_or_spec}\n```"
    else:
        prompt = code_or_spec

    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role":"system","content":"Expert polyglot developer. Know all major languages."},
                  {"role":"user","content":prompt}]
    )
    return r.choices[0].message.content
```

---

## 10. Web Search Tools Overview

| Tool        | Type      | Notes                                      |
|-------------|-----------|---------------------------------------------|
| Tavily      | API       | Built for LLMs, returns cleaned content     |
| SerpAPI     | API       | Google Search results, paid                 |
| DuckDuckGo  | Free      | pip install duckduckgo-search, rate limited  |
| Bing Search | API       | Microsoft, generous free tier               |
| Google      | API       | Custom Search JSON API, 100 req/day free     |

### Tavily Setup
```bash
pip install tavily-python
```
```python
from tavily import TavilyClient
tavily = TavilyClient(api_key="tvly-...")
result = tavily.search(query="latest AI news 2025", max_results=5)
for r in result["results"]:
    print(r["title"], r["url"])
    print(r["content"][:200])
```

---

## 11. LLM + Search: Grounded Response Pattern

```python
from openai import OpenAI
client = OpenAI()

def grounded_answer(question):
    # Step 1: Search
    results = tavily.search(query=question, max_results=3, search_depth="basic")
    
    # Step 2: Build context
    context = "\n\n".join(
        f"Source: {r['url']}\n{r['content'][:500]}"
        for r in results["results"]
    )
    
    # Step 3: Answer with sources
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Answer the question using ONLY the provided search results. Cite sources."},
            {"role":"user","content":f"Question: {question}\n\nSearch Results:\n{context}"}
        ]
    )
    return {
        "answer": r.choices[0].message.content,
        "sources": [r["url"] for r in results["results"]]
    }
```

---

## 12. Search-Summarise-Cite Pattern

```python
def research_and_summarise(topic, num_sources=5):
    results = tavily.search(query=topic, max_results=num_sources)
    sources = results["results"]
    
    # Build numbered source list for citation
    source_text = "\n\n".join(
        f"[{i+1}] {s['url']}\n{s['content'][:600]}"
        for i, s in enumerate(sources)
    )
    
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Write a comprehensive summary with inline citations [1], [2], etc."},
            {"role":"user","content":f"Topic: {topic}\n\nSources:\n{source_text}"}
        ], max_tokens=800
    )
    return r.choices[0].message.content
```

---

## 13. Multi-source Search Aggregation

```python
def multi_source_search(query):
    results = {}
    # DuckDuckGo (free)
    try:
        from duckduckgo_search import DDGS
        with DDGS() as ddgs:
            results["ddg"] = list(ddgs.text(query, max_results=3))
    except: pass
    
    # Tavily
    try:
        t = tavily.search(query=query, max_results=3)
        results["tavily"] = t["results"]
    except: pass
    
    # Combine and deduplicate by URL
    all_results = []
    seen_urls = set()
    for source, items in results.items():
        for item in items:
            url = item.get("url","")
            if url not in seen_urls:
                all_results.append({**item, "source_engine": source})
                seen_urls.add(url)
    return all_results
```

---

## 14. Query Reformulation

Improve search relevance by rewriting user queries.

```python
def reformulate_query(original_query, num_variants=3):
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        response_format={"type":"json_object"},
        messages=[
            {"role":"system","content":f"Generate {num_variants} alternative search queries for better results. Return JSON: {{queries:[...]}}"},
            {"role":"user","content":f"Original query: {original_query}"}
        ]
    )
    import json
    return json.loads(r.choices[0].message.content)["queries"]

# Multi-query search
def comprehensive_search(query):
    variants = reformulate_query(query)
    all_results = []
    for q in [query] + variants:
        r = tavily.search(query=q, max_results=2)
        all_results.extend(r["results"])
    # Deduplicate
    seen = set()
    return [r for r in all_results if not (r["url"] in seen or seen.add(r["url"]))]
```

---

## 15. Rasa Framework Overview

Rasa is a Python ML framework for conversational AI.

```bash
pip install rasa
rasa init                # create project
rasa train               # train NLU + policies
rasa shell               # interactive CLI chat
rasa run                 # start API server
```

### Project Structure
```
rasa_project/
  data/
    nlu.yml              # intent examples
    stories.yml          # conversation flows
    rules.yml            # strict rules
  domain.yml             # intents, entities, slots, responses, actions
  config.yml             # pipeline (NLU) + policies
  actions/actions.py     # custom Python actions
```

---

## 16. Rasa Intent & Entity Configuration

### nlu.yml
```yaml
version: "3.1"
nlu:
- intent: greet
  examples: |
    - hi
    - hello
    - hey there
    - good morning
- intent: check_order_status
  examples: |
    - where is my order [#12345](order_id)?
    - track order [ORD-789](order_id)
    - what is the status of [A100](order_id)?
- intent: request_refund
  examples: |
    - I want a refund for order [#555](order_id)
    - refund my purchase
```

---

## 17. Rasa Dialogue Management

### stories.yml
```yaml
version: "3.1"
stories:
- story: order status flow
  steps:
  - intent: check_order_status
  - action: action_check_order
  - intent: request_refund
  - action: action_process_refund
```

### rules.yml
```yaml
version: "3.1"
rules:
- rule: always greet
  steps:
  - intent: greet
  - action: utter_greet
- rule: out of scope
  steps:
  - intent: out_of_scope
  - action: utter_out_of_scope
```

---

## 18. Rasa Custom Actions

```python
# actions/actions.py
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

class ActionCheckOrder(Action):
    def name(self): return "action_check_order"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker, domain: dict):
        order_id = tracker.get_slot("order_id")
        if order_id:
            # Query backend
            status = f"Order {order_id} is shipped and arrives tomorrow."
            dispatcher.utter_message(text=status)
        else:
            dispatcher.utter_message(text="Please provide your order ID.")
        return []
```

---

## 19. LLM-based Chatbot with Persona

```python
SALES_PERSONA = """You are Alex, a friendly sales assistant for TechStore.
You help customers:
- Find the right product based on their needs
- Explain product features and compare options
- Process purchases (call purchase_product tool when ready)
- Handle basic questions about shipping and returns

Stay focused on TechStore products. If asked about competitors, politely redirect.
Always be helpful, concise, and professional."""

def sales_chat(history, user_message):
    if not history:
        history = [{"role":"system","content":SALES_PERSONA}]
    history.append({"role":"user","content":user_message})
    r = client.chat.completions.create(model="gpt-4o-mini", messages=history, max_tokens=300)
    reply = r.choices[0].message.content
    history.append({"role":"assistant","content":reply})
    return reply, history
```

---

## 20. Memory Patterns for Multi-turn Conversations

```python
from collections import deque

class ConversationMemory:
    def __init__(self, max_turns=10, summary_threshold=8):
        self.messages = deque(maxlen=max_turns * 2)
        self.summary = ""
        self.summary_threshold = summary_threshold

    def add(self, role, content):
        self.messages.append({"role":role,"content":content})
        if len(self.messages) >= self.summary_threshold * 2:
            self._summarise()

    def _summarise(self):
        r = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role":"system","content":"Summarise this conversation concisely for context."},
                      *list(self.messages)],
            max_tokens=200
        )
        self.summary = r.choices[0].message.content
        self.messages.clear()

    def get_messages(self, system_prompt):
        msgs = [{"role":"system","content":system_prompt}]
        if self.summary:
            msgs.append({"role":"system","content":f"Previous conversation summary: {self.summary}"})
        msgs.extend(list(self.messages))
        return msgs
```

---

## 21. Guardrails: Stay On Topic

```python
TOPIC_CLASSIFIER = "Classify if this message is relevant to: {topic}. Reply YES or NO only."

def is_on_topic(message, allowed_topics):
    for topic in allowed_topics:
        r = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role":"system","content":TOPIC_CLASSIFIER.format(topic=topic)},
                      {"role":"user","content":message}],
            max_tokens=5, temperature=0
        )
        if "yes" in r.choices[0].message.content.lower():
            return True
    return False

def guarded_chat(user_msg, allowed_topics=("product questions","pricing","support")):
    if not is_on_topic(user_msg, allowed_topics):
        return "I can only help with product questions, pricing, and support. How can I assist you?"
    # Proceed with normal chat
    return sales_chat([], user_msg)[0]
```