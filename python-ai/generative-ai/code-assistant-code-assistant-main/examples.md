# Code Assistant, AI Search, Chatbot — Code Examples (20 Examples)

```bash
pip install openai pydantic tavily-python duckduckgo-search rasa streamlit
```

---

## Example 1 — Code Generator
```python
from openai import OpenAI
client = OpenAI()

def generate_code(spec, language="Python"):
    r = client.chat.completions.create(
        model="gpt-4o", temperature=0.2,
        messages=[
            {"role":"system","content":f"Expert {language} developer. Return only clean, documented code."},
            {"role":"user","content":spec}
        ]
    )
    return r.choices[0].message.content

print(generate_code("Binary search function with type hints and docstring"))
```

---

## Example 2 — Code Explainer
```python
def explain_code(code, audience="junior"):
    prompts = {
        "junior": "Explain simply with analogies.",
        "senior": "Focus on architecture and trade-offs."
    }
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":f"Explain code. {prompts.get(audience,'')} Structure: 1)What it does 2)How it works 3)Key concepts 4)Potential issues"},
            {"role":"user","content":f"```python\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## Example 3 — Structured Code Review
```python
from pydantic import BaseModel
from typing import List

class Issue(BaseModel):
    severity: str      # high/medium/low
    category: str      # bug/security/performance/style
    description: str
    suggestion: str

class Review(BaseModel):
    issues: List[Issue]
    overall_score: int  # 0-100
    summary: str

def review_code(code):
    r = client.beta.chat.completions.parse(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"You are a senior code reviewer. Be thorough and constructive."},
            {"role":"user","content":f"Review this code:\n```\n{code}\n```"}
        ],
        response_format=Review
    )
    return r.choices[0].message.parsed

report = review_code("def divide(a,b): return a/b")
for issue in report.issues:
    print(f"[{issue.severity.upper()}] {issue.category}: {issue.description}")
```

---

## Example 4 — Debugger
```python
def debug_code(code, error_message):
    r = client.chat.completions.create(
        model="gpt-4o", temperature=0.1,
        messages=[
            {"role":"system","content":"Debugging expert. Provide: 1)Root cause 2)Fixed code 3)Explanation 4)Test to prevent recurrence"},
            {"role":"user","content":f"Code:\n```python\n{code}\n```\nError: {error_message}"}
        ]
    )
    return r.choices[0].message.content

buggy = "result = int('abc')\nprint(result)"
print(debug_code(buggy, "ValueError: invalid literal for int() with base 10: 'abc'"))
```

---

## Example 5 — Unit Test Generator
```python
def generate_tests(function_code, framework="pytest"):
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":f"Generate comprehensive {framework} tests covering: happy path, edge cases, error cases. Use parametrize where appropriate."},
            {"role":"user","content":f"Generate tests for:\n```python\n{function_code}\n```"}
        ]
    )
    return r.choices[0].message.content

fn = '''
def divide(a: float, b: float) -> float:
    if b == 0: raise ValueError("Cannot divide by zero")
    return a / b
'''
print(generate_tests(fn))
```

---

## Example 6 — Docstring Generator
```python
def add_docstrings(code, style="Google"):
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":f"Add {style}-style docstrings to all functions/classes. Keep code unchanged. Only add docstrings."},
            {"role":"user","content":f"```python\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## Example 7 — Code Translator (Language Converter)
```python
def translate_code(code, source_lang, target_lang):
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":f"Expert polyglot developer. Translate to idiomatic {target_lang}. Keep same logic and names."},
            {"role":"user","content":f"Translate this {source_lang} to {target_lang}:\n```{source_lang}\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content

python_code = "def fib(n):\n    if n<=1: return n\n    return fib(n-1)+fib(n-2)"
print(translate_code(python_code, "Python", "Go"))
```

---

## Example 8 — Refactoring Advisor
```python
def suggest_refactoring(code):
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"Analyse for refactoring: SOLID violations, DRY, complexity, naming, design patterns. Provide analysis + refactored version."},
            {"role":"user","content":f"```\n{code}\n```"}
        ]
    )
    return r.choices[0].message.content
```

---

## Example 9 — GitHub PR Reviewer (File Diff)
```python
def review_diff(diff_text):
    r = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"Review this code diff as a senior engineer. Check: correctness, security, performance, test coverage, breaking changes."},
            {"role":"user","content":f"Review this diff:\n```diff\n{diff_text}\n```"}
        ], max_tokens=1000
    )
    return r.choices[0].message.content
```

---

## Example 10 — AI Search with Tavily
```python
from tavily import TavilyClient
import os

tavily = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def ai_search(question):
    results = tavily.search(query=question, max_results=3, search_depth="advanced")
    context = "\n\n".join(
        f"[{i+1}] {r['url']}\n{r['content'][:400]}"
        for i,r in enumerate(results["results"])
    )
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Answer using ONLY the search results. Cite with [1],[2],[3]. If unsure, say so."},
            {"role":"user","content":f"Q: {question}\n\nResults:\n{context}"}
        ]
    )
    return {"answer": r.choices[0].message.content,
            "sources": [r["url"] for r in results["results"]]}

result = ai_search("What are the latest developments in quantum computing?")
print(result["answer"])
print("\nSources:", result["sources"])
```

---

## Example 11 — DuckDuckGo + LLM Search (Free)
```python
from duckduckgo_search import DDGS

def ddg_search_and_answer(query):
    with DDGS() as ddgs:
        results = list(ddgs.text(query, max_results=5))
    context = "\n\n".join(f"[{i+1}] {r['href']}\n{r['body']}" for i,r in enumerate(results))
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":"Answer concisely using only these search results. Cite sources."},
            {"role":"user","content":f"Question: {query}\n\n{context}"}
        ], max_tokens=400
    )
    return r.choices[0].message.content
```

---

## Example 12 — Query Reformulation
```python
import json
def reformulate_queries(query, n=3):
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        response_format={"type":"json_object"},
        messages=[
            {"role":"system","content":f"Generate {n} diverse search query variants for better coverage. Return {{\"queries\":[...]}}"},
            {"role":"user","content":f"Query: {query}"}
        ]
    )
    return json.loads(r.choices[0].message.content)["queries"]

queries = reformulate_queries("how to speed up Python code")
print(queries)
# ["Python performance optimization techniques", "profiling Python programs",
#  "Python code bottleneck identification and fixes"]
```

---

## Example 13 — LLM Chatbot with Persona
```python
SUPPORT_BOT = """You are Sam, a friendly customer support specialist for CloudStore.
Help with: orders, returns, products, shipping, account issues.
Be concise (2-3 sentences max per response). Ask one clarifying question at a time.
If you cannot help, offer to escalate to a human agent."""

def support_chat(conversation, user_msg):
    if not conversation:
        conversation = [{"role":"system","content":SUPPORT_BOT}]
    conversation.append({"role":"user","content":user_msg})
    r = client.chat.completions.create(
        model="gpt-4o-mini", messages=conversation, max_tokens=200
    )
    reply = r.choices[0].message.content
    conversation.append({"role":"assistant","content":reply})
    return reply, conversation

reply, conv = support_chat([], "Hi, my order hasn't arrived yet")
print(reply)
```

---

## Example 14 — Topic Guardrail
```python
def is_on_topic(message, allowed_topics=("products","orders","support","returns")):
    topics_str = ", ".join(allowed_topics)
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role":"system","content":f"Is this message about: {topics_str}? Reply YES or NO only."},
            {"role":"user","content":message}
        ],
        max_tokens=3, temperature=0
    )
    return "yes" in r.choices[0].message.content.lower()

def safe_chat(conversation, user_msg):
    if not is_on_topic(user_msg):
        return "I can only help with products, orders, and support. What can I help you with?", conversation
    return support_chat(conversation, user_msg)
```

---

## Example 15 — Memory-Summarised Conversation
```python
class SummaryMemory:
    def __init__(self, max_turns=6):
        self.turns = []
        self.summary = ""
        self.max = max_turns * 2

    def add(self, role, content):
        self.turns.append({"role":role,"content":content})
        if len(self.turns) > self.max:
            self._compress()

    def _compress(self):
        r = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role":"system","content":"Summarise this chat in 3 sentences."}] + self.turns,
            max_tokens=150
        )
        self.summary = r.choices[0].message.content
        self.turns = self.turns[-4:]  # keep last 2 turns

    def to_messages(self, system_prompt):
        msgs = [{"role":"system","content":system_prompt}]
        if self.summary:
            msgs.append({"role":"system","content":f"Prior context: {self.summary}"})
        return msgs + self.turns
```

---

## Example 16 — Rasa NLU Config (nlu.yml snippet)
```yaml
# nlu.yml
version: "3.1"
nlu:
- intent: greet
  examples: |
    - hi
    - hello
    - hey
- intent: order_status
  examples: |
    - where is my order [#1234](order_id)?
    - track order [ORD-567](order_id)
- intent: request_refund
  examples: |
    - I want a refund
    - refund my order [#890](order_id)
```

---

## Example 17 — Rasa Custom Action (Python)
```python
# actions/actions.py
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

class ActionOrderStatus(Action):
    def name(self): return "action_order_status"
    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: dict):
        order_id = tracker.get_slot("order_id")
        if order_id:
            dispatcher.utter_message(text=f"Order {order_id}: Shipped, arrives in 2 days.")
        else:
            dispatcher.utter_message(text="What is your order ID?")
        return []
```

---

## Example 18 — Streamlit Code Assistant UI
```python
import streamlit as st
from openai import OpenAI
client = OpenAI()

st.title("AI Code Assistant")
task = st.selectbox("Task", ["Generate","Explain","Review","Debug","Test","Document"])
code_input = st.text_area("Code or description", height=200)
language = st.selectbox("Language", ["Python","JavaScript","TypeScript","Go","Java","Rust"])

if st.button("Run") and code_input:
    prompts = {
        "Generate": f"Write clean {language} code for: {code_input}",
        "Explain": f"Explain this {language} code:\n```{language}\n{code_input}\n```",
        "Review": f"Review this {language} code for bugs/security/style:\n```\n{code_input}\n```",
        "Debug": f"Debug this {language} code:\n```\n{code_input}\n```",
        "Test": f"Write pytest tests for:\n```python\n{code_input}\n```",
        "Document": f"Add docstrings to:\n```python\n{code_input}\n```"
    }
    with st.spinner("Processing..."):
        r = client.chat.completions.create(model="gpt-4o",
            messages=[{"role":"user","content":prompts[task]}], max_tokens=2000)
        st.code(r.choices[0].message.content, language=language.lower())
```

---

## Example 19 — Streaming Code Assistant
```python
def stream_code_help(prompt):
    print("AI: ", end="", flush=True)
    stream = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role":"system","content":"You are an expert coding assistant."},
            {"role":"user","content":prompt}
        ],
        stream=True
    )
    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print()

stream_code_help("Explain Python decorators with a practical example")
```

---

## Example 20 — Multi-search Aggregator
```python
def comprehensive_search(query):
    sources = []
    # Try Tavily
    try:
        t = tavily.search(query=query, max_results=3)
        sources.extend(t["results"])
    except Exception as e:
        print(f"Tavily error: {e}")
    # Try DuckDuckGo as fallback
    if len(sources) < 3:
        try:
            with DDGS() as ddgs:
                for r in ddgs.text(query, max_results=3):
                    sources.append({"url":r["href"],"content":r["body"]})
        except: pass

    if not sources:
        return "No search results available."

    context = "\n\n".join(f"[{i+1}] {s.get('url','')}\n{s.get('content','')[:400]}" for i,s in enumerate(sources))
    r = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role":"system","content":"Answer using these sources. Cite with [1],[2]."},
                  {"role":"user","content":f"Q: {query}\n\n{context}"}]
    )
    return r.choices[0].message.content
```