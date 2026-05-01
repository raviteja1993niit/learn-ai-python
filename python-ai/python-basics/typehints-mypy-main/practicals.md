# Type Hints & mypy — Practical Exercises

> 10 hands-on exercises: add annotations to existing code and fix mypy errors.
> Run `mypy <file>.py` after each exercise to verify your solution.

---

## Exercise 1: Annotate a Simple Calculator

**Objective:** Add type annotations to a basic calculator module.

**Untyped code to annotate:**
```python
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        return None
    return a / b
```

**Requirements:**
- `add`, `subtract`, `multiply` accept and return `float`
- `divide` returns `float | None` (None when b == 0)
- All parameters must be annotated

**Hints:**
- Use `float` not `int` for widest numeric compatibility
- For divide, the return type must account for the `None` case

**Expected outcome:** `mypy exercise1.py` reports 0 errors.

---

## Exercise 2: Annotate a Student Grade System

**Objective:** Add type annotations to a grade management module.

**Untyped code to annotate:**
```python
def average(scores):
    if not scores:
        return None
    return sum(scores) / len(scores)

def letter_grade(score):
    if score >= 90:
        return "A"
    elif score >= 80:
        return "B"
    elif score >= 70:
        return "C"
    else:
        return "F"

def class_report(students):
    return {name: letter_grade(avg) for name, avg in students.items()}
```

**Requirements:**
- `average` takes a `list[float]` and returns `float | None`
- `letter_grade` takes a `float` and returns a `str`
- `class_report` takes `dict[str, float]` and returns `dict[str, str]`

**Hints:**
- Empty list check means return type must be Optional
- `dict[str, float]` is valid in Python 3.9+; use `Dict[str, float]` for 3.8

**Expected outcome:** No mypy errors; all functions fully annotated.

---

## Exercise 3: Fix Optional Attribute Access Errors

**Objective:** Identify and fix mypy errors caused by unguarded `None` access.

**Broken code:**
```python
from typing import Optional

def get_username(user_id: int) -> Optional[str]:
    db = {1: "alice", 2: "bob"}
    return db.get(user_id)

def print_upper(user_id: int) -> None:
    name = get_username(user_id)
    print(name.upper())   # mypy error here
```

**mypy error:**
```
error: Item "None" of "Optional[str]" has no attribute "upper"
```

**Requirements:**
- Fix `print_upper` so mypy is satisfied
- Do not change the return type of `get_username`
- Print a fallback message if name is None

**Hints:**
- Use an `if name is not None:` guard
- Or use a ternary: `name.upper() if name else "Unknown"`

**Expected outcome:** `mypy --strict exercise3.py` produces 0 errors.

---

## Exercise 4: Annotate a Generic Cache Class

**Objective:** Add TypeVar and Generic annotations to a simple cache.

**Untyped code:**
```python
class Cache:
    def __init__(self):
        self._store = {}

    def set(self, key, value):
        self._store[key] = value

    def get(self, key):
        return self._store.get(key)

    def clear(self):
        self._store.clear()
```

**Requirements:**
- Use `TypeVar` for key (`K`) and value (`V`) types
- Make `Cache` inherit from `Generic[K, V]`
- Annotate `set`, `get`, and `clear` with proper types
- `get` should return `V | None`

**Hints:**
- `from typing import TypeVar, Generic`
- `K = TypeVar("K")`; `V = TypeVar("V")`
- `class Cache(Generic[K, V]):`

**Expected outcome:** Can instantiate `Cache[str, int]()` with full type safety.

---

## Exercise 5: Replace Any with Proper Types

**Objective:** Eliminate `Any` usage and replace with precise annotations.

**Code using Any:**
```python
from typing import Any

def process_record(record: Any) -> Any:
    name: Any = record["name"]
    score: Any = record["score"]
    return {"display": name.upper(), "doubled": score * 2}

def batch_process(records: Any) -> Any:
    return [process_record(r) for r in records]
```

**Requirements:**
- Define a `TypedDict` called `Record` with `name: str` and `score: int`
- Define a `TypedDict` called `Result` with `display: str` and `doubled: int`
- Replace all `Any` annotations with proper types

**Hints:**
- `from typing import TypedDict`
- Input is `list[Record]`, output is `list[Result]`

**Expected outcome:** No `Any` remains; mypy strict mode passes.

---

## Exercise 6: Annotate a Protocol-based Renderer

**Objective:** Define a Protocol and annotate functions that use it.

**Untyped code:**
```python
class HtmlRenderer:
    def render(self, content):
        return f"<p>{content}</p>"

class MarkdownRenderer:
    def render(self, content):
        return f"> {content}"

def output(renderer, text):
    return renderer.render(text)
```

**Requirements:**
- Create a `Renderer` Protocol with `def render(self, content: str) -> str`
- Annotate `output` to accept any `Renderer` and return `str`
- Both `HtmlRenderer` and `MarkdownRenderer` must satisfy the Protocol without explicit inheritance

**Hints:**
- `from typing import Protocol`
- Do NOT modify the renderer classes to inherit from `Renderer`
- This demonstrates structural subtyping

**Expected outcome:** `output(HtmlRenderer(), "hello")` type-checks correctly.

---

## Exercise 7: Add Literal Types to a State Machine

**Objective:** Restrict a state machine's transitions using `Literal`.

**Untyped code:**
```python
VALID_TRANSITIONS = {
    "idle": ["running", "error"],
    "running": ["idle", "paused", "error"],
    "paused": ["running", "idle"],
    "error": ["idle"],
}

def transition(current_state, new_state):
    allowed = VALID_TRANSITIONS.get(current_state, [])
    if new_state not in allowed:
        raise ValueError(f"Cannot transition from {current_state} to {new_state}")
    return new_state
```

**Requirements:**
- Define `State = Literal["idle", "running", "paused", "error"]`
- Annotate `current_state` and `new_state` as `State`
- Annotate the return type
- Annotate `VALID_TRANSITIONS` as `dict[State, list[State]]`

**Hints:**
- `from typing import Literal`
- Literal types make invalid states a compile-time error

**Expected outcome:** Calling `transition("flying", "idle")` is a mypy error.

---

## Exercise 8: Fix Incomplete Return Type Annotations

**Objective:** Fix functions that have missing or incorrect return type annotations.

**Broken code with mypy errors:**
```python
def get_config(env: str):           # missing return type
    if env == "prod":
        return {"debug": False, "db": "prod-db"}
    elif env == "dev":
        return {"debug": True, "db": "dev-db"}

def first_or_default(items: list[int], default: int) -> int:
    if items:
        return items[0]
    # mypy error: Missing return statement

def parse_int(s: str) -> int:
    try:
        return int(s)
    except ValueError:
        return None  # mypy error: Incompatible return value type
```

**Requirements:**
- Add return type to `get_config`: returns `dict[str, bool | str]`
- Fix `first_or_default` to always return an `int`
- Fix `parse_int` to return `int | None`

**Hints:**
- Add explicit `return` at the end of `first_or_default`
- Change `parse_int` return type to `int | None`

**Expected outcome:** All three functions pass mypy with no errors.

---

## Exercise 9: Annotate a Dataclass Hierarchy

**Objective:** Fully annotate a dataclass-based class hierarchy.

**Untyped code:**
```python
from dataclasses import dataclass, field

@dataclass
class Shape:
    colour = "red"

    def area(self):
        raise NotImplementedError

@dataclass
class Circle(Shape):
    radius = 1.0

    def area(self):
        import math
        return math.pi * self.radius ** 2

@dataclass
class Rectangle(Shape):
    width = 1.0
    height = 1.0

    def area(self):
        return self.width * self.height
```

**Requirements:**
- All fields must be declared as typed dataclass fields (`colour: str = "red"`)
- `area` must return `float`
- Add a free function `total_area(shapes: list[Shape]) -> float`

**Hints:**
- Dataclass fields need type annotations to be recognised as fields
- Use `from __future__ import annotations` if you have forward references

**Expected outcome:** Full mypy compliance; `total_area` works polymorphically.

---

## Exercise 10: Configure mypy and Reach Zero Errors on a Module

**Objective:** Set up `mypy.ini` and bring a partially-typed module to full compliance.

**Step 1 — Create `mypy.ini`:**
```ini
[mypy]
python_version = 3.11
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
warn_return_any = true
warn_unused_ignores = true
strict_optional = true
```

**Step 2 — Partially typed module to fix (`app.py`):**
```python
from typing import Any

users: Any = []

def register(name, email):
    users.append({"name": name, "email": email})

def find(email):
    for user in users:
        if user["email"] == email:
            return user
    return None

def count():
    return len(users)
```

**Requirements:**
- Replace `Any` with a `TypedDict` for user records
- Add annotations to `register`, `find`, and `count`
- Ensure `find` returns `UserRecord | None`

**Hints:**
- `from typing import TypedDict`
- `class UserRecord(TypedDict): name: str; email: str`
- Run `mypy app.py` after each change to track progress

**Expected outcome:** `mypy app.py` with the `mypy.ini` above shows 0 errors.

---

## Quick mypy Command Reference

```bash
# Basic check
mypy your_file.py

# Strict mode (most rigorous)
mypy --strict your_file.py

# Check entire package
mypy src/

# Show error codes (useful for targeted ignores)
mypy --show-error-codes your_file.py

# Generate a baseline (ignore existing errors, catch new ones)
mypy --ignore-missing-imports your_file.py

# Install type stubs for third-party libraries
pip install types-requests types-boto3
```