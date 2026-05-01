# Core Python Syntax, Data Types, Control Flow and Functions
## Complete Theory Reference

---

## 1. Python Interpreter, REPL, Scripts vs Modules

Python is an **interpreted** language. The CPython interpreter reads and
executes code line by line rather than compiling to a standalone binary.

### The REPL (Read-Eval-Print Loop)
- Launch with: `python` or `python3` in your terminal
- Interactive prompt: `>>>`
- Great for experimenting; `_` holds the last evaluated result
- Exit with `exit()` or Ctrl-D (Ctrl-Z on Windows)

### Scripts
- Files ending in `.py`, executed top-to-bottom
- Run with: `python script.py`
- Accept command-line arguments via `sys.argv`

### Modules
- Any `.py` file can be imported as a module
- Python ships with a rich standard library (~200 modules)
- `__name__` equals `"__main__"` when run directly, else the module name

```python
# script.py
def main():
    print("Running as a script")

if __name__ == "__main__":
    main()
```

---

## 2. Variables and Naming Conventions (PEP 8)

- Variables are **dynamically typed** — no declaration required
- Assignment uses `=`; Python is **case-sensitive**
- Delete a variable with `del var_name`

### PEP 8 Naming Conventions

| Type        | Convention          | Example              |
|-------------|---------------------|----------------------|
| Variable    | snake_case          | user_name            |
| Constant    | UPPER_SNAKE_CASE    | MAX_RETRIES          |
| Function    | snake_case          | calculate_total()    |
| Class       | PascalCase          | BankAccount          |
| Private     | _leading_underscore | _internal_value      |
| Dunder      | __double_under__    | __init__             |

### Multiple Assignment

```python
x = y = z = 0                       # same value to multiple vars
a, b, c = 1, 2, 3                   # tuple unpacking
first, *rest = [1, 2, 3, 4, 5]     # extended unpacking: rest=[2,3,4,5]
a, b = b, a                         # swap without temp variable
```

---

## 3. Core Data Types

### int
- Arbitrary-precision whole numbers (no overflow in Python 3)
- Literal forms: decimal `42`, binary `0b1010`, octal `0o12`, hex `0xFF`
- Useful builtins: `abs()`, `divmod()`, `pow()`, `int.bit_length()`

### float
- IEEE 754 double-precision (64-bit) floating-point
- Beware: `0.1 + 0.2 != 0.3` (binary representation issue)
- Use `decimal.Decimal` or `round()` for precision-critical code
- Special values: `float("inf")`, `float("-inf")`, `float("nan")`

### str
- Immutable sequence of Unicode code points
- Delimiters: single quotes, double quotes, or triple double-quotes
- Raw strings: `r"
"` — backslash treated literally
- Byte strings: `b"hello"`

### bool
- Subclass of `int`: `True == 1`, `False == 0`
- Falsy values: `0`, `0.0`, `""`, `[]`, `{}`, `set()`, `None`
- Everything else is truthy

### None
- Singleton representing absence of a value
- Returned implicitly by functions with no `return` statement
- Always compare with `is None`, not `== None`

### Type Inspection

```python
x = 3.14
print(type(x))                      # <class 'float'>
print(type(x).__name__)             # float
print(isinstance(x, float))         # True
print(isinstance(x, (int, float)))  # True — accepts a tuple of types
print(issubclass(bool, int))        # True
```

---

## 4. String Methods

Strings are **immutable**; all methods return new strings.

```python
s = "  Hello, World!  "

# Case and whitespace
s.upper()            # "  HELLO, WORLD!  "
s.lower()            # "  hello, world!  "
s.strip()            # "Hello, World!"
s.lstrip()           # "Hello, World!  "
s.rstrip()           # "  Hello, World!"
s.capitalize()       # capitalise first char of entire string
s.title()            # capitalise first char of every word

# Search
s.find("World")      # index of first match; -1 if not found
s.index("World")     # like find but raises ValueError if not found
s.count("l")         # number of non-overlapping occurrences
s.startswith("  H")  # True
s.endswith("!  ")    # True

# Transform
s.replace("World", "Python")
s.split(", ")        # ["  Hello", "World!  "]
s.split()            # splits on any whitespace; removes empty strings
"--".join(["a", "b", "c"])  # "a--b--c"

# Test content
"hello".isalpha()    # True
"123".isdigit()      # True
"hello123".isalnum() # True
"  ".isspace()       # True
```

### String Formatting

```python
name, score = "Alice", 98.765

# f-strings (Python 3.6+) — recommended
print(f"Name: {name}, Score: {score:.2f}")
print(f"{score:10.2f}")     # width 10, 2 decimals, right-aligned
print(f"{name!r}")           # repr() of name -> 'Alice'
print(f"{42:08b}")           # binary, zero-padded to 8 chars -> 00101010

# .format() method
print("Name: {0}, Score: {1:.2f}".format(name, score))
print("Name: {n}, Score: {s}".format(n=name, s=score))
```

---

## 5. Lists

Ordered, **mutable**, heterogeneous sequences. Created with `[]` or `list()`.

```python
lst = [10, 20, 30, 40, 50]

# Indexing and Slicing
lst[0]        # 10   (first element)
lst[-1]       # 50   (last element)
lst[1:3]      # [20, 30]
lst[::2]      # [10, 30, 50]  — every second element
lst[::-1]     # [50, 40, 30, 20, 10]  — reversed copy

# Mutating methods
lst.append(60)           # add to end
lst.extend([70, 80])     # add all elements from iterable
lst.insert(0, 5)         # insert value at index
lst.remove(5)            # remove first occurrence; ValueError if absent
popped = lst.pop()       # remove and return last element
lst.pop(0)               # remove and return element at index 0
lst.clear()              # remove all elements

# Sorting
lst.sort()               # in-place, ascending
lst.sort(reverse=True)   # in-place, descending
lst.sort(key=len)        # in-place, by custom key function
new_lst = sorted(lst)    # returns new sorted list; original unchanged

# Other utilities
lst.reverse()            # in-place reverse
lst.index(30)            # find index of first occurrence of value
lst.count(20)            # count occurrences of value
copy = lst.copy()        # shallow copy (also: lst[:] or list(lst))
```

### List Comprehension

```python
squares  = [x**2 for x in range(10)]
evens    = [x for x in range(20) if x % 2 == 0]
flat     = [n for row in [[1, 2], [3, 4]] for n in row]   # flatten 2D
pairs    = [(x, y) for x in range(3) for y in range(3) if x != y]
strings  = [str(x) for x in range(5)]
```

---

## 6. Tuples

Ordered, **immutable** sequences. Created with `()` or `tuple()`.

```python
t = (1, 2, 3)
single_item = (42,)     # trailing comma required for single-element tuple
empty = ()

# Immutability: t[0] = 99  would raise TypeError

# Packing and Unpacking
coords = 10, 20               # packing (parentheses optional)
x, y   = coords               # unpacking
a, *b, c = (1, 2, 3, 4, 5)   # extended unpacking: a=1, b=[2,3,4], c=5

# Tuples are hashable — can be used as dict keys or set members
location_visits = {(40.7128, -74.0060): "New York"}
point_set = {(0, 0), (1, 2), (3, 4)}
```

### Named Tuples

```python
from collections import namedtuple

Employee = namedtuple("Employee", ["name", "department", "salary"])
emp = Employee("Alice", "Engineering", 95000)

print(emp.name)             # Alice
print(emp[1])               # Engineering  (index access still works)
print(emp._asdict())        # OrderedDict-like view
new_emp = emp._replace(salary=100000)   # returns modified copy
```

---

## 7. Dictionaries

Ordered (Python 3.7+), **mutable** key-value mappings. Keys must be hashable.

```python
d = {"name": "Alice", "age": 30, "city": "NYC"}

# CRUD
d["email"] = "a@b.com"          # Create or Update
value = d["name"]                # Read (KeyError if key missing)
value = d.get("phone", "N/A")   # Safe read with default
del d["city"]                    # Delete (KeyError if key missing)
removed = d.pop("age", None)     # Remove and return; default avoids error

# Views (dynamic — reflect current dict state)
d.keys()     # dict_keys(['name', 'email'])
d.values()   # dict_values(['Alice', 'a@b.com'])
d.items()    # dict_items([('name', 'Alice'), ('email', 'a@b.com')])

# Iteration
for key in d:
    print(key, d[key])

for key, val in d.items():
    print(f"{key}: {val}")

# Merge
d.update({"zip": "10001"})      # adds/overwrites keys from another dict
merged = {**d1, **d2}           # unpack merge (Python 3.5+)
merged = d1 | d2                # merge operator (Python 3.9+)
```

### Dict Comprehension

```python
squares  = {x: x**2 for x in range(6)}
inverted = {v: k for k, v in original.items()}
filtered = {k: v for k, v in d.items() if v is not None}
```

### defaultdict

```python
from collections import defaultdict

# No KeyError on first access — creates a default value automatically
word_count = defaultdict(int)
word_count["hello"] += 1        # works without pre-initializing

groups = defaultdict(list)
for item in data:
    groups[item["category"]].append(item)
```

---

## 8. Sets

Unordered collections of **unique**, hashable elements. Use `set()` or `{a, b, c}`.

```python
s1 = {1, 2, 3, 4, 5}
s2 = {3, 4, 5, 6, 7}
empty_set = set()           # IMPORTANT: {} creates an empty dict, not a set!

# Set operations (operator and method forms)
s1 | s2     # union: {1,2,3,4,5,6,7}  — s1.union(s2)
s1 & s2     # intersection: {3,4,5}   — s1.intersection(s2)
s1 - s2     # difference: {1,2}       — s1.difference(s2)
s1 ^ s2     # symmetric diff: {1,2,6,7} — s1.symmetric_difference(s2)

# Mutating
s1.add(6)
s1.discard(10)   # safe remove — no error if element is not present
s1.remove(1)     # raises KeyError if element is not present
s1.update([7, 8, 9])

# Subset / superset checks
{1, 2}.issubset({1, 2, 3})       # True
{1, 2, 3}.issuperset({1, 2})     # True

# Set comprehension
unique_lengths = {len(word) for word in sentence.split()}
```

---

## 9. Control Flow

### if / elif / else

```python
score = 85
if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
else:
    grade = "F"

# Ternary (conditional expression)
label = "pass" if score >= 60 else "fail"
```

### while Loop

```python
n = 1
while n <= 5:
    print(n)
    n += 1
else:
    print("Done!")   # runs if loop ended normally (no break)
```

### for Loop

```python
for i in range(5):
    print(i)                   # 0 1 2 3 4

for i, val in enumerate(["a", "b", "c"]):
    print(i, val)              # 0 a  /  1 b  /  2 c

for a, b in zip([1, 2, 3], ["x", "y", "z"]):
    print(a, b)                # 1 x  /  2 y  /  3 z
```

### break, continue, pass

```python
for n in range(10):
    if n % 2 == 0: continue   # skip even numbers
    if n == 7:     break      # exit loop at 7
    print(n)                   # prints 1  3  5

class Placeholder:
    pass    # no-op; required when a code block must not be empty
```

---

## 10. Functions

```python
def greet(name, greeting="Hello"):
    '''Greet someone. Returns a formatted greeting string.

    Args:
        name:     The persons name.
        greeting: Greeting word (default Hello).
    Returns:
        str: The formatted greeting.
    '''
    return f"{greeting}, {name}!"

print(greet("Alice"))          # Hello, Alice!
print(greet("Bob", "Hi"))     # Hi, Bob!
```

### *args and **kwargs

```python
def total(*args):
    '''Sum any number of positional arguments.'''
    return sum(args)

def display(**kwargs):
    '''Print all keyword arguments.'''
    for k, v in kwargs.items():
        print(f"  {k} = {v}")

total(1, 2, 3, 4)                     # 10
display(name="Alice", age=30)          # name=Alice  /  age=30

# Unpacking at call site
numbers = [1, 2, 3]
config  = {"sep": " | ", "end": "\n"}
print(*numbers)                        # 1 2 3
```

### Lambda Functions

```python
square   = lambda x: x**2
multiply = lambda x, y: x * y

# Common use: as a sort key
people = [("Alice", 30), ("Bob", 25), ("Carol", 35)]
people.sort(key=lambda p: p[1])         # sort by age
print(people)
```

### Nested Functions and Closures

```python
def make_power(exp):
    '''Factory: returns a function that raises its argument to exp.'''
    def power(base):
        return base ** exp    # exp comes from the enclosing scope
    return power

square = make_power(2)
cube   = make_power(3)
print(square(4), cube(3))    # 16  27
```

---

## 11. Scope: The LEGB Rule

Python resolves names in this order:

1. **L** — Local: inside the current function
2. **E** — Enclosing: enclosing function scopes (closures)
3. **G** — Global: module-level names
4. **B** — Built-in: `len`, `print`, `range`, `type`, etc.

```python
x = "global"

def outer():
    x = "enclosing"
    def inner():
        x = "local"
        print(x)     # local
    inner()
    print(x)          # enclosing

outer()
print(x)              # global
```

### global and nonlocal Keywords

```python
count = 0

def increment():
    global count       # allows modification of module-level variable
    count += 1

def make_counter():
    n = 0
    def inc(step=1):
        nonlocal n     # allows modification of enclosing variable
        n += step
        return n
    return inc

c = make_counter()
print(c(), c(), c(5))  # 1  2  7
```

---

## 12. Exception Handling

```python
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print(f"Division error: {e}")
except (TypeError, ValueError) as e:
    print(f"Type or value problem: {e}")
else:
    print("Success — no exception was raised")
finally:
    print("Always executes — use for cleanup")
```

### Raising Exceptions

```python
def validate_age(age):
    if not isinstance(age, int):
        raise TypeError(f"Age must be int, got {type(age).__name__}")
    if not (0 <= age <= 150):
        raise ValueError(f"Unrealistic age: {age}")
    return age
```

### Custom Exceptions

```python
class InsufficientFundsError(Exception):
    '''Raised when a withdrawal exceeds the current balance.'''
    def __init__(self, amount, balance):
        super().__init__(
            f"Cannot withdraw {amount:.2f}; balance is {balance:.2f}"
        )
        self.amount  = amount
        self.balance = balance
```

---

## 13. File I/O

```python
# Writing (creates or overwrites)
with open("notes.txt", "w", encoding="utf-8") as f:
    f.write("First line\n")
    f.writelines(["Second\n", "Third\n"])

# Reading
with open("notes.txt", "r", encoding="utf-8") as f:
    content = f.read()          # entire file as one string
    f.seek(0)
    lines   = f.readlines()     # list of strings including newlines
    f.seek(0)
    for line in f:              # line-by-line (memory-efficient)
        print(line.rstrip())

# Appending
with open("notes.txt", "a") as f:
    f.write("Appended line\n")
```

### CSV Module

```python
import csv

# Writing
with open("people.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "age"])
    writer.writeheader()
    writer.writerows([
        {"name": "Alice", "age": 30},
        {"name": "Bob",   "age": 25},
    ])

# Reading
with open("people.csv", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        print(row["name"], row["age"])
```

### JSON Module

```python
import json

data = {"users": ["Alice", "Bob"], "count": 2, "active": True}

# Serialise
json_str = json.dumps(data, indent=2)    # dict -> JSON string
with open("data.json", "w") as f:
    json.dump(data, f, indent=2)          # dict -> file

# Deserialise
parsed = json.loads(json_str)             # JSON string -> dict
with open("data.json") as f:
    loaded = json.load(f)                 # file -> dict
```

---

## 14. Modules and Packages

```python
import math                           # full module
import os, sys                        # multiple modules
from datetime import datetime         # specific name
from pathlib import Path
import collections as col             # alias

# Guard — standard entry-point pattern
def main():
    print("Running main logic")

if __name__ == "__main__":
    main()
```

### Standard Library Highlights

| Module       | Purpose                               |
|--------------|---------------------------------------|
| os           | OS interactions, env vars, paths      |
| sys          | Interpreter info, argv, exit          |
| pathlib      | Object-oriented filesystem paths      |
| re           | Regular expressions                   |
| math         | Mathematical functions and constants  |
| datetime     | Dates, times, timedeltas              |
| collections  | Counter, defaultdict, namedtuple, deque |
| itertools    | Infinite and combinatoric iterators   |
| functools    | lru_cache, reduce, partial            |
| json         | JSON serialisation/deserialisation    |
| csv          | CSV file reading and writing          |
| random       | Pseudo-random number generation       |

### Packages (`__init__.py`)

```
my_package/
    __init__.py      # marks directory as a package; can re-export names
    utils.py
    models.py
```

```python
# Importing from a package
from my_package.utils import helper_function
from my_package import models

# __init__.py can expose a clean public API
# my_package/__init__.py
from .utils import helper_function
from .models import User
```

---

*End of THEORY.md — Core Python: Syntax, Data Types, Control Flow and Functions*
