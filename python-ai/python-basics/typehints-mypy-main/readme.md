# 🏷️ Type Hints & mypy — Python Static Typing

## What are Type Hints?
Type hints let you annotate Python variables and functions with expected types.
Python still runs without them, but tools like mypy can catch type errors before runtime.

## Why Use Type Hints?
- Catch bugs at development time, not runtime
- IDE autocomplete becomes smarter
- Self-documenting code — no need to guess argument types
- Required in all modern production Python code

## Syntax
```python
# Variables
name: str = "Alice"
age: int = 30
scores: list[float] = [9.5, 8.0, 7.5]
mapping: dict[str, int] = {"a": 1, "b": 2}

# Functions
def greet(name: str, age: int = 0) -> str:
    return f"Hello {name}, age {age}"

# Optional types
from typing import Optional, Union
def find_user(id: int) -> Optional[str]:  # returns str or None
    return db.get(id)

# Complex types
from typing import List, Dict, Tuple, Callable
def train(data: List[Dict[str, float]], epochs: int = 10) -> Tuple[float, float]:
    ...

# TypedDict — typed dictionary
from typing import TypedDict
class UserData(TypedDict):
    name: str
    age: int
    email: str

# Dataclass with types
from dataclasses import dataclass
@dataclass
class ModelConfig:
    learning_rate: float = 0.001
    batch_size: int = 32
    epochs: int = 100
```

## mypy Static Checker
```bash
pip install mypy
mypy my_script.py        # check a file
mypy src/                # check whole package
mypy --strict app.py     # strict mode
```

## Learning Path
1. Add return types to all functions in existing code
2. Add parameter types
3. Use Optional, Union, List, Dict
4. Run mypy and fix all errors
5. Add mypy to CI/CD pipeline

## What to Build
- [ ] Refactor ML project functions with full type hints
- [ ] TypedDict for ML config / hyperparameters
- [ ] Add mypy to GitHub Actions workflow

## Related Folders
- `python-basics/Complete-Python-Bootcamp-main/` — Python basics
- `python-basics/Design-Patterns-main/` — OOP patterns use types