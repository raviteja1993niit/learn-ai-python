# DeepSeek R1 — Code Examples (15 Examples)

```bash
pip install openai groq python-dotenv numpy
ollama pull deepseek-r1:7b   # for local examples
```

---

## Example 1 — Basic DeepSeek API Call
```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ["DEEPSEEK_API_KEY"],
    base_url="https://api.deepseek.com"
)

response = client.chat.completions.create(
    model="deepseek-reasoner",
    temperature=0.6,
    messages=[{"role":"user","content":"What is 15% of 840?"}]
)
print(response.choices[0].message.content)
```

---

## Example 2 — Access Reasoning Content
```python
response = client.chat.completions.create(
    model="deepseek-reasoner",
    temperature=0.6,
    messages=[{"role":"user","content":"Solve: 2x + 5 = 13"}]
)
msg = response.choices[0].message
print("=== THINKING ===")
print(getattr(msg, "reasoning_content", "N/A"))
print("\n=== ANSWER ===")
print(msg.content)
```

---

## Example 3 — Parse think Tags (Groq / Ollama)
```python
import re

def parse_r1(text):
    think = re.search(r'<think>(.*?)</think>', text, re.DOTALL)
    reasoning = think.group(1).strip() if think else ""
    answer = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL).strip()
    return {"reasoning": reasoning, "answer": answer}

# Test with Ollama
from openai import OpenAI as OAI
local = OAI(api_key="ollama", base_url="http://localhost:11434/v1")
r = local.chat.completions.create(
    model="deepseek-r1:7b",
    temperature=0.6,
    messages=[{"role":"user","content":"Prove that 2+2=4 step by step."}]
)
result = parse_r1(r.choices[0].message.content)
print("Thinking:", result["reasoning"][:200])
print("Answer:", result["answer"])
```

---

## Example 4 — Math Problem Solver
```python
def solve_math(problem):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":"Solve the math problem step by step. Show all working. Give exact answer."},
            {"role":"user","content":problem}
        ]
    )
    return response.choices[0].message.content

problems = [
    "Find all solutions to x^2 - 5x + 6 = 0",
    "What is the integral of x^2 from 0 to 3?",
    "A train travels 120 km at 60 km/h. How long does it take?"
]
for p in problems:
    print(f"Problem: {p}")
    print(f"Solution: {solve_math(p)}\n")
```

---

## Example 5 — Code Generation
```python
def generate_code(description, language="Python"):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":f"Expert {language} developer. Write clean, documented, type-hinted code only. No explanation."},
            {"role":"user","content":description}
        ]
    )
    return response.choices[0].message.content

print(generate_code("Binary search function with docstring"))
print(generate_code("Fibonacci with memoization using functools.lru_cache"))
```

---

## Example 6 — Code Debugging
```python
def debug_code(code, error_message):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":"You are a Python debugger. Analyse the code, identify the bug, explain why it occurs, and provide fixed code."},
            {"role":"user","content":f"Code:\n```python\n{code}\n```\n\nError:\n{error_message}"}
        ]
    )
    return response.choices[0].message.content

buggy = """
def divide(a, b):
    return a / b

result = divide(10, 0)
print(result)
"""
print(debug_code(buggy, "ZeroDivisionError: division by zero"))
```

---

## Example 7 — Logical Reasoning
```python
def reason(premise):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":"Reason step-by-step. Identify logical structure, test assumptions, conclude."},
            {"role":"user","content":premise}
        ]
    )
    msg = response.choices[0].message
    reasoning = getattr(msg, "reasoning_content", "")
    return {"reasoning": reasoning, "conclusion": msg.content}

result = reason("All mammals breathe air. Dolphins are mammals. What can we conclude?")
print("Reasoning:", result["reasoning"][:300])
print("Conclusion:", result["conclusion"])
```

---

## Example 8 — RAG with DeepSeek R1
```python
import numpy as np
from openai import OpenAI as OAI

# Use OpenAI for embeddings, DeepSeek for reasoning
oai = OAI()
ds_client = client   # DeepSeek client

def embed(text):
    r = oai.embeddings.create(model="text-embedding-3-small", input=text)
    return np.array(r.data[0].embedding)

def cosine(a, b):
    return float(np.dot(a,b)/(np.linalg.norm(a)*np.linalg.norm(b)))

def rag_query(question, documents):
    q_emb = embed(question)
    scored = sorted(enumerate(documents), key=lambda x: -cosine(q_emb, embed(x[1])))
    context = "\n\n".join(documents[i] for i,_ in scored[:3])
    
    r = ds_client.chat.completions.create(
        model="deepseek-reasoner", temperature=0.6,
        messages=[
            {"role":"system","content":f"Answer using ONLY this context:\n{context}"},
            {"role":"user","content":question}
        ]
    )
    return r.choices[0].message.content

docs = ["Python was created by Guido van Rossum in 1991.",
        "Python 3.0 was released in 2008.",
        "Python is known for its readable syntax."]
print(rag_query("When was Python first released?", docs))
```

---

## Example 9 — Streaming with DeepSeek
```python
stream = client.chat.completions.create(
    model="deepseek-chat",   # V3 supports streaming
    temperature=0.6,
    messages=[{"role":"user","content":"Explain recursion with a Python example."}],
    stream=True
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

---

## Example 10 — Multi-turn Conversation
```python
history = [{"role":"system","content":"You are an expert mathematics tutor. Think through each problem carefully."}]

def math_chat(question):
    history.append({"role":"user","content":question})
    r = client.chat.completions.create(
        model="deepseek-reasoner", temperature=0.6, messages=history
    )
    reply = r.choices[0].message.content
    history.append({"role":"assistant","content":reply})
    return reply

print(math_chat("What is the Pythagorean theorem?"))
print(math_chat("Give me a hard problem using it."))
print(math_chat("Now solve it step by step."))
```

---

## Example 11 — Local Ollama DeepSeek R1
```python
from openai import OpenAI

# Connect to locally running Ollama
ollama_client = OpenAI(
    api_key="ollama",
    base_url="http://localhost:11434/v1"
)

def local_reason(question):
    r = ollama_client.chat.completions.create(
        model="deepseek-r1:7b",
        temperature=0.6,
        messages=[{"role":"user","content":question}]
    )
    raw = r.choices[0].message.content
    return parse_r1(raw)  # from Example 3

result = local_reason("What is the prime factorisation of 360?")
print("Thinking:", result["reasoning"][:200])
print("Answer:", result["answer"])
```

---

## Example 12 — Groq DeepSeek R1 (Fast Inference)
```python
from groq import Groq
import os

groq_client = Groq(api_key=os.environ["GROQ_API_KEY"])

response = groq_client.chat.completions.create(
    model="deepseek-r1-distill-llama-70b",
    messages=[{"role":"user","content":"Solve: Integrate x*sin(x) dx"}],
    temperature=0.6,
    max_tokens=2048
)
raw = response.choices[0].message.content
result = parse_r1(raw)
print("Reasoning:", result["reasoning"][:300])
print("Answer:", result["answer"])
```

---

## Example 13 — Code Review with Reasoning
```python
def review_code(code_snippet):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":"Review this Python code for: bugs, security issues, performance problems, style violations. Provide specific line-by-line feedback."},
            {"role":"user","content":f"```python\n{code_snippet}\n```"}
        ]
    )
    return response.choices[0].message.content

sample = """
def get_user(user_id):
    query = f"SELECT * FROM users WHERE id = {user_id}"
    result = db.execute(query)
    return result[0]
"""
print(review_code(sample))
```

---

## Example 14 — Compare R1 vs V3 for Reasoning
```python
problem = "A clock shows 3:15. What is the angle between the hour and minute hands?"

for model_name in ["deepseek-reasoner", "deepseek-chat"]:
    r = client.chat.completions.create(
        model=model_name, temperature=0.6,
        messages=[{"role":"user","content":problem}]
    )
    answer = r.choices[0].message.content
    tokens = r.usage.total_tokens
    print(f"\nModel: {model_name}")
    print(f"Tokens: {tokens}")
    print(f"Answer: {answer[:200]}")
```

---

## Example 15 — Research Summariser
```python
def summarise_research(paper_text):
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        temperature=0.6,
        messages=[
            {"role":"system","content":"You are a research analyst. Provide: 1) Key hypothesis, 2) Methodology, 3) Results, 4) Limitations, 5) Practical implications."},
            {"role":"user","content":f"Analyse this paper:\n\n{paper_text[:3000]}"}
        ]
    )
    return response.choices[0].message.content

# Test with abstract
abstract = """
This paper presents a novel approach to image classification using
transfer learning with Vision Transformers (ViT). We demonstrate
that fine-tuning a pre-trained ViT-B/16 model achieves 95.3% accuracy
on the CIFAR-100 benchmark, outperforming previous CNN-based approaches.
"""
print(summarise_research(abstract))
```