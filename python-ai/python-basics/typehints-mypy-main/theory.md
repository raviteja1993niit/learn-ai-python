# Type Hints & mypy — Theory Reference

> A comprehensive guide to Python's type annotation system and static type checking with mypy.

---

## 1. Why Type Hints?

Type hints (PEP 484) were introduced in Python 3.5 to allow developers to annotate variables, function
parameters, and return types. They do **not** affect runtime behaviour — Python remains dynamically
typed — but they enable:

- Static analysis with tools like **mypy**, **pyright**, and **pylance**
- Better IDE autocompletion and refactoring support
- Self-documenting code that is easier to maintain
- Catching bugs before running code

---

## 2. Basic Built-in Types

The most common primitive type annotations map directly to Python built-ins:

```python
x: int = 42
name: str = "Alice"
price: float = 3.14
flag: bool = True
data: bytes = b"hello"
nothing: None = None
```

### Notes
- `bool` is a subclass of `int` in Python, so `bool` is compatible where `int` is expected.
- `None` as an annotation means the function or variable holds `NoneType`.
- Use `None` as a return type annotation when a function returns nothing (implicitly returns `None`).

```python
def greet(name: str) -> None:
    print(f"Hello, {name}")
```

---

## 3. Container Types

### 3.1 Using `typing` Module (Python 3.5–3.8)

Before Python 3.9, you had to import container generics from `typing`:

```python
from typing import List, Dict, Set, Tuple, Sequence, Mapping

names: List[str] = ["Alice", "Bob"]
scores: Dict[str, int] = {"Alice": 95}
unique: Set[int] = {1, 2, 3}
point: Tuple[int, int] = (10, 20)
items: Sequence[str] = ["a", "b"]   # read-only ordered collection
config: Mapping[str, str] = {"key": "val"}  # read-only mapping
```

### 3.2 Built-in Generics (Python 3.9+)

PEP 585 allows using lowercase built-ins directly:

```python
names: list[str] = ["Alice", "Bob"]
scores: dict[str, int] = {"Alice": 95}
unique: set[int] = {1, 2, 3}
point: tuple[int, int] = (10, 20)
```

### 3.3 Choosing Between typing vs Built-ins

| Use Case                         | Recommended            |
|----------------------------------|------------------------|
| Python 3.9+ only projects        | Built-in generics      |
| Supporting Python 3.7/3.8        | `typing` module      |
| `from __future__ import annotations` | Built-in generics (lazy eval) |

### 3.4 Tuple Variants

```python
# Fixed-length tuple
coord: tuple[int, int, int] = (1, 2, 3)

# Variable-length homogeneous tuple
numbers: tuple[int, ...] = (1, 2, 3, 4, 5)

# Empty tuple
empty: tuple[()] = ()
```

---

## 4. Optional and Union Types

### 4.1 Optional[T]

`Optional[T]` is shorthand for `Union[T, None]` — the value can be `T` or `None`:

```python
from typing import Optional

def find_user(user_id: int) -> Optional[str]:
    if user_id == 1:
        return "Alice"
    return None
```

### 4.2 T | None (Python 3.10+)

PEP 604 introduced the `|` syntax for union types:

```python
def find_user(user_id: int) -> str | None:
    ...
```

This is equivalent to `Optional[str]` but more readable.

### 4.3 Union Types

`Union[X, Y]` means the value can be either type X or type Y:

```python
from typing import Union

def process(value: Union[int, str]) -> str:
    return str(value)

# Python 3.10+ syntax
def process_new(value: int | str) -> str:
    return str(value)
```

---

## 5. Any, TypeVar, and Generic Classes

### 5.1 Any

`Any` is an escape hatch — it is compatible with every type (both as source and destination).
Use sparingly; it disables type checking for that value:

```python
from typing import Any

def legacy_function(data: Any) -> Any:
    return data
```

### 5.2 TypeVar

`TypeVar` creates a type variable for generic functions — the concrete type is inferred at call site:

```python
from typing import TypeVar

T = TypeVar("T")

def first(items: list[T]) -> T:
    return items[0]

result: int = first([1, 2, 3])      # T inferred as int
name: str = first(["a", "b"])       # T inferred as str
```

Bounded TypeVar — constrains to a subtype:

```python
from typing import TypeVar

Numeric = TypeVar("Numeric", int, float)

def double(x: Numeric) -> Numeric:
    return x * 2
```

### 5.3 Generic Classes

Inherit from `Generic[T]` to create parameterised container classes:

```python
from typing import Generic, TypeVar

T = TypeVar("T")

class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()

stack: Stack[int] = Stack()
stack.push(42)
value: int = stack.pop()
```

---

## 6. Callable Types

Annotate functions as values using `Callable`:

```python
from typing import Callable

# Callable[[param_types], return_type]
def apply(func: Callable[[int, str], bool], n: int, s: str) -> bool:
    return func(n, s)

# No parameters
handler: Callable[[], None]

# Variable args — use ... for unknown signature
callback: Callable[..., int]
```

---

## 7. TypedDict

`TypedDict` defines a dictionary with a fixed set of string keys and specific value types:

```python
from typing import TypedDict

class Movie(TypedDict):
    title: str
    year: int
    rating: float

movie: Movie = {"title": "Inception", "year": 2010, "rating": 8.8}
```

### Optional Keys with `total=False`

```python
class Config(TypedDict, total=False):
    debug: bool
    log_level: str

# All keys are optional
cfg: Config = {}
cfg2: Config = {"debug": True}
```

---

## 8. Protocols (Structural Subtyping)

A `Protocol` defines an interface by duck typing — any class implementing the required
methods satisfies the protocol, without explicit inheritance (PEP 544):

```python
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None: ...

class Circle:
    def draw(self) -> None:
        print("Drawing circle")

def render(shape: Drawable) -> None:
    shape.draw()

render(Circle())  # OK — Circle satisfies Drawable structurally
```

Use `runtime_checkable` to enable `isinstance` checks:

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Sized(Protocol):
    def __len__(self) -> int: ...

print(isinstance([1, 2], Sized))  # True
```

---

## 9. Literal Types

`Literal` restricts a value to specific literal constants (PEP 586):

```python
from typing import Literal

Direction = Literal["north", "south", "east", "west"]

def move(direction: Direction) -> None:
    print(f"Moving {direction}")

move("north")   # OK
move("up")      # mypy error: Argument 1 has incompatible type "Literal['up']"
```

---

## 10. Final Variables

`Final` marks a variable as a constant that should not be reassigned (PEP 591):

```python
from typing import Final

MAX_SIZE: Final = 100
API_URL: Final[str] = "https://api.example.com"

MAX_SIZE = 200  # mypy error: Cannot assign to final name "MAX_SIZE"
```

---

## 11. @overload Decorator

`@overload` defines multiple signatures for a function with different input/output type combinations:

```python
from typing import overload

@overload
def process(value: int) -> int: ...
@overload
def process(value: str) -> str: ...

def process(value: int | str) -> int | str:
    if isinstance(value, int):
        return value * 2
    return value.upper()
```

The actual implementation is not decorated with `@overload`. mypy uses the overload signatures for
type checking while the real body handles the logic.

---

## 12. Type Narrowing with isinstance()

mypy performs **control flow analysis** — after an `isinstance` check, the type is narrowed:

```python
def handle(value: int | str) -> str:
    if isinstance(value, int):
        # value is int here
        return str(value * 2)
    # value is str here
    return value.upper()
```

Other narrowing techniques:
- `if value is None` / `if value is not None`
- `assert isinstance(value, SomeType)`
- `TypeGuard` functions for custom narrowing

```python
from typing import TypeGuard

def is_str_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)
```

---

## 13. mypy Configuration

### 13.1 mypy.ini

```ini
[mypy]
python_version = 3.11
strict = true
ignore_missing_imports = true
disallow_untyped_defs = true
warn_return_any = true
warn_unused_ignores = true

# Per-module overrides
[mypy-third_party_lib.*]
ignore_missing_imports = true
```

### 13.2 pyproject.toml

```toml
[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true
disallow_untyped_defs = true
warn_return_any = true
```

### 13.3 Inline Ignore Comments

```python
x: int = "hello"  # type: ignore[assignment]
```

---

## 14. Common mypy Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `Incompatible types in assignment` | Assigning wrong type | Correct the type or annotation |
| `Argument 1 has incompatible type` | Wrong arg type in function call | Fix caller or broaden annotation |
| `Item "None" of "Optional[X]" has no attribute` | Accessing attr on Optional without None check | Add `if x is not None` guard |
| `Function is missing a return type annotation` | Unannotated function | Add `-> ReturnType` |
| `Cannot determine type of ...` | Forward reference issue | Use string literal or `from __future__ import annotations` |
| `Module has no attribute` | Accessing non-existent attribute | Fix attribute name |
| `Need type annotation for variable` | Ambiguous empty container | Add explicit type: `x: list[int] = []` |

---

## 15. --strict Mode Explained

Running `mypy --strict` enables the most rigorous checks:

| Flag | Description |
|------|-------------|
| `--disallow-untyped-defs` | All functions must have type annotations |
| `--disallow-incomplete-defs` | Partially annotated functions are an error |
| `--check-untyped-defs` | Type-check body of unannotated functions |
| `--disallow-untyped-decorators` | Decorators must be typed |
| `--warn-return-any` | Warn when returning `Any` |
| `--warn-unused-ignores` | Warn about unnecessary `# type: ignore` comments |
| `--no-implicit-optional` | Disallow implicit `Optional` from default `None` |
| `--strict-equality` | Warn on impossible comparisons |

Recommended approach: start without `--strict`, fix errors incrementally, then enable it.

---

## 16. Summary

Type hints make Python code safer and more maintainable. Combined with mypy, they provide a
powerful static analysis workflow that catches bugs at development time rather than runtime.
Key principles:
1. Annotate all public API functions at minimum
2. Use `Optional` / `| None` for nullable values
3. Prefer specific types over `Any`
4. Use `TypeVar` and `Generic` for reusable containers
5. Use `Protocol` for flexible interface contracts
6. Configure mypy progressively toward `--strict`