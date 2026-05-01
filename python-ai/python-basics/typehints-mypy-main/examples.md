# Type Hints — Annotated Examples

> 20+ examples progressing from basic annotations to Generic classes.

---

## Example 1: Basic Variable Annotations

```python
# Annotating primitive variables at module level
age: int = 30
username: str = "alice"
temperature: float = 36.6
is_active: bool = True
raw_data: bytes = b"\x00\x01"
nothing: None = None
```

---

## Example 2: Annotated Function — Primitives

```python
# All parameters and return type annotated
def add(a: int, b: int) -> int:
    return a + b

def greet(name: str, loud: bool = False) -> str:
    msg = f"Hello, {name}"
    return msg.upper() if loud else msg
```

---

## Example 3: Optional Parameters

```python
from typing import Optional

# The function may return a string or None
def find_name(user_id: int) -> Optional[str]:
    users = {1: "Alice", 2: "Bob"}
    return users.get(user_id)

# Equivalent using Python 3.10+ union syntax
def find_name_new(user_id: int) -> str | None:
    users = {1: "Alice", 2: "Bob"}
    return users.get(user_id)
```

---

## Example 4: List and Dict Annotations

```python
# typing module (Python 3.5–3.8 compatible)
from typing import List, Dict

def total_scores(scores: Dict[str, int]) -> int:
    return sum(scores.values())

def top_names(names: List[str], n: int) -> List[str]:
    return sorted(names)[:n]

# Python 3.9+ built-in generics
def total_scores_new(scores: dict[str, int]) -> int:
    return sum(scores.values())
```

---

## Example 5: Tuple and Set Annotations

```python
# Fixed-length tuple: x, y coordinates
def distance(point: tuple[float, float]) -> float:
    x, y = point
    return (x ** 2 + y ** 2) ** 0.5

# Variable-length homogeneous tuple
def sum_all(values: tuple[int, ...]) -> int:
    return sum(values)

# Set of unique tags
def add_tag(tags: set[str], new_tag: str) -> set[str]:
    return tags | {new_tag}
```

---

## Example 6: Union Types

```python
from typing import Union

# Function accepts int or string, returns string representation
def stringify(value: Union[int, float, str]) -> str:
    return str(value)

# Python 3.10+ syntax
def stringify_new(value: int | float | str) -> str:
    return str(value)

# Union in variable annotation
id_or_name: int | str = 42
id_or_name = "alice"  # also valid
```

---

## Example 7: Type Narrowing with isinstance

```python
# mypy narrows the type inside each branch
def process(value: int | str | list[int]) -> str:
    if isinstance(value, int):
        # value: int here
        return f"integer: {value * 2}"
    elif isinstance(value, str):
        # value: str here
        return f"string: {value.upper()}"
    else:
        # value: list[int] here
        return f"list: {sum(value)}"
```

---

## Example 8: Callable Annotations

```python
from typing import Callable

# A function that accepts a transform function and applies it
def apply_twice(func: Callable[[int], int], x: int) -> int:
    return func(func(x))

# Higher-order function: accepts predicate
def filter_items(
    items: list[str],
    predicate: Callable[[str], bool]
) -> list[str]:
    return [item for item in items if predicate(item)]

# Usage
result = apply_twice(lambda n: n + 1, 5)   # 7
long_words = filter_items(["hi", "hello", "hey"], lambda s: len(s) > 3)
```

---

## Example 9: Sequence and Mapping (Read-Only Views)

```python
from typing import Sequence, Mapping

# Sequence: read-only ordered collection (list, tuple, str all qualify)
def first_element(items: Sequence[int]) -> int:
    return items[0]

first_element([1, 2, 3])    # list works
first_element((1, 2, 3))    # tuple works

# Mapping: read-only dict-like interface
def lookup(table: Mapping[str, int], key: str) -> int:
    return table.get(key, 0)
```

---

## Example 10: TypeVar — Generic Functions

```python
from typing import TypeVar

T = TypeVar("T")

# Works with any type — T is inferred at call site
def identity(x: T) -> T:
    return x

def last_item(items: list[T]) -> T:
    return items[-1]

# Constrained TypeVar
Numeric = TypeVar("Numeric", int, float)

def square(x: Numeric) -> Numeric:
    return x * x

n: int = square(4)        # int
f: float = square(2.5)    # float
```

---

## Example 11: Generic Class — Stack

```python
from typing import Generic, TypeVar

T = TypeVar("T")

class Stack(Generic[T]):
    """Type-safe LIFO stack."""

    def __init__(self) -> None:
        self._data: list[T] = []

    def push(self, item: T) -> None:
        self._data.append(item)

    def pop(self) -> T:
        if not self._data:
            raise IndexError("Stack is empty")
        return self._data.pop()

    def peek(self) -> T:
        return self._data[-1]

    def __len__(self) -> int:
        return len(self._data)

int_stack: Stack[int] = Stack()
int_stack.push(1)
int_stack.push(2)
value: int = int_stack.pop()  # type is int, not Any
```

---

## Example 12: Generic Class — Pair (two TypeVars)

```python
from typing import Generic, TypeVar

A = TypeVar("A")
B = TypeVar("B")

class Pair(Generic[A, B]):
    """Immutable typed pair."""

    def __init__(self, first: A, second: B) -> None:
        self.first = first
        self.second = second

    def swap(self) -> "Pair[B, A]":
        return Pair(self.second, self.first)

    def __repr__(self) -> str:
        return f"Pair({self.first!r}, {self.second!r})"

p: Pair[str, int] = Pair("age", 30)
swapped: Pair[int, str] = p.swap()
```

---

## Example 13: TypedDict

```python
from typing import TypedDict

class Address(TypedDict):
    street: str
    city: str
    zip_code: str

class Employee(TypedDict):
    name: str
    age: int
    address: Address

emp: Employee = {
    "name": "Alice",
    "age": 30,
    "address": {"street": "1 Main St", "city": "Springfield", "zip_code": "12345"}
}

# Partial TypedDict with total=False
class PartialConfig(TypedDict, total=False):
    debug: bool
    timeout: int
    log_file: str

cfg: PartialConfig = {"debug": True}  # only some keys required
```

---

## Example 14: Protocol — Structural Subtyping

```python
from typing import Protocol

class Serialisable(Protocol):
    def to_json(self) -> str: ...

class User:
    def __init__(self, name: str) -> None:
        self.name = name

    def to_json(self) -> str:
        import json
        return json.dumps({"name": self.name})

class Product:
    def __init__(self, sku: str, price: float) -> None:
        self.sku = sku
        self.price = price

    def to_json(self) -> str:
        import json
        return json.dumps({"sku": self.sku, "price": self.price})

def save(obj: Serialisable) -> None:
    print(obj.to_json())

save(User("Alice"))       # OK — has to_json
save(Product("X1", 9.99)) # OK — has to_json
```

---

## Example 15: Literal Types

```python
from typing import Literal

LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
HttpMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]

def log(message: str, level: LogLevel = "INFO") -> None:
    print(f"[{level}] {message}")

def make_request(url: str, method: HttpMethod) -> None:
    print(f"{method} {url}")

log("Server started")          # OK
log("Bad request", "ERROR")    # OK
# log("test", "VERBOSE")       # mypy error: invalid literal
```

---

## Example 16: Final Variables

```python
from typing import Final

MAX_CONNECTIONS: Final[int] = 100
DEFAULT_HOST: Final = "localhost"
PI: Final[float] = 3.14159265358979

class Config:
    VERSION: Final = "1.0.0"
    DEBUG: Final[bool] = False

# MAX_CONNECTIONS = 200  # mypy error: Cannot assign to final name
```

---

## Example 17: @overload Decorator

```python
from typing import overload

@overload
def repeat(value: str, times: int) -> str: ...
@overload
def repeat(value: list[int], times: int) -> list[int]: ...

def repeat(value: str | list[int], times: int) -> str | list[int]:
    if isinstance(value, str):
        return value * times
    return value * times

result_str: str = repeat("ab", 3)        # "ababab"
result_list: list[int] = repeat([1, 2], 3)  # [1, 2, 1, 2, 1, 2]
```

---

## Example 18: TypeGuard — Custom Type Narrowing

```python
from typing import TypeGuard

def is_string_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def process_strings(items: list[object]) -> None:
    if is_string_list(items):
        # items is list[str] here
        for s in items:
            print(s.upper())  # no mypy error
```

---

## Example 19: ClassVar and dataclass

```python
from typing import ClassVar
from dataclasses import dataclass, field

@dataclass
class Counter:
    # ClassVar: shared across all instances, not an instance field
    count: ClassVar[int] = 0

    name: str
    value: int = 0
    tags: list[str] = field(default_factory=list)

    def increment(self) -> None:
        self.value += 1
        Counter.count += 1

c1 = Counter("first")
c2 = Counter("second")
c1.increment()
print(Counter.count)  # 1
```

---

## Example 20: Putting It All Together — Typed Repository Pattern

```python
from typing import Generic, TypeVar, Optional, Protocol

class HasId(Protocol):
    @property
    def id(self) -> int: ...

T = TypeVar("T", bound=HasId)

class Repository(Generic[T]):
    def __init__(self) -> None:
        self._store: dict[int, T] = {}

    def save(self, entity: T) -> None:
        self._store[entity.id] = entity

    def find_by_id(self, entity_id: int) -> Optional[T]:
        return self._store.get(entity_id)

    def all(self) -> list[T]:
        return list(self._store.values())

    def delete(self, entity_id: int) -> bool:
        if entity_id in self._store:
            del self._store[entity_id]
            return True
        return False

from dataclasses import dataclass

@dataclass
class Product:
    id: int
    name: str
    price: float

repo: Repository[Product] = Repository()
repo.save(Product(1, "Widget", 9.99))
repo.save(Product(2, "Gadget", 19.99))

item: Optional[Product] = repo.find_by_id(1)
all_products: list[Product] = repo.all()
```

---

## Example 21: Annotated — Metadata-enriched Types

```python
from typing import Annotated

# Annotated[type, metadata...] — metadata is for tools/validators, ignored by mypy
PositiveInt = Annotated[int, "must be > 0"]
EmailStr = Annotated[str, "must be valid email"]

def create_user(name: str, age: PositiveInt, email: EmailStr) -> dict[str, object]:
    return {"name": name, "age": age, "email": email}
```