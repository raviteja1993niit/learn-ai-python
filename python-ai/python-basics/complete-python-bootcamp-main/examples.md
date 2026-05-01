# Python Core — Annotated Code Examples
## 21 Working Examples from Basic to Advanced

---

### Example 1: Hello World and the REPL Mindset

```python
# The simplest Python program
print("Hello, World!")

# In the REPL, expressions auto-print
>>> 2 + 2
4
>>> _          # _ holds the last result
4

# type() reveals the runtime type of any object
print(type(42))          # <class 'int'>
print(type("hello"))     # <class 'str'>
print(type(None))        # <class 'NoneType'>
```

---

### Example 2: Variables, Multiple Assignment and Type Checking

```python
# Dynamic typing — assign without declaring type
name       = "Alice"
age        = 30
height     = 5.7
is_student = False
nothing    = None

# isinstance() is safer than type() for checks
print(isinstance(age, int))            # True
print(isinstance(age, (int, float)))   # True — tuple of types accepted
print(isinstance(name, str))           # True

# Multiple assignment patterns
x = y = z = 0                          # all point to same object
a, b, c = 10, 20, 30                   # tuple unpacking
first, *middle, last = [1, 2, 3, 4, 5]
print(first, middle, last)             # 1  [2, 3, 4]  5

# Swap without a temp variable
a, b = b, a
print(a, b)                            # 20  10
```

---

### Example 3: String Methods in Practice

```python
sentence = "  the quick brown fox jumps over the lazy dog  "

clean  = sentence.strip()
words  = clean.split()         # split on any whitespace
print(len(words))              # 9

print(clean.find("fox"))       # 16  (index of first occurrence)
print(clean.count("the"))      # 2
modified = clean.replace("lazy", "energetic")

# Membership test
print("fox" in clean)          # True

# Join — inverse of split
rejoined = " | ".join(words)
print(rejoined)

# Chaining methods
result = "  HELLO WORLD  ".strip().lower().replace("world", "python")
print(result)                  # hello python
```

---

### Example 4: f-Strings and Advanced Formatting

```python
name  = "Bob"
score = 98.6789
count = 3

# Basic f-string
print(f"Hello, {name}!")

# Format specifiers
print(f"Score: {score:.2f}")           # 98.68  (2 decimal places)
print(f"Score: {score:10.2f}")         # right-aligned in 10-char field
print(f"Count: {count:05d}")           # zero-padded integer -> 00003
print(f"Percent: {0.753:.1%}")         # 75.3%
print(f"Hex: {255:#x}")                # 0xff

# Expressions inside f-strings
print(f"Double: {score * 2:.1f}")
print(f"Upper: {name.upper()}")
print(f"Grade: {'A' if score >= 90 else 'B'}")

# Multi-line with alignment
header = f"{'Name':<15} {'Score':>8} {'Grade':>6}"
row    = f"{name:<15} {score:>8.2f} {'A':>6}"
print(header)
print(row)
```

---

### Example 5: List Operations and Comprehensions

```python
numbers = [5, 2, 8, 1, 9, 3, 7, 4, 6]

# Slicing (returns a new list)
print(numbers[2:5])      # [8, 1, 9]
print(numbers[::-1])     # reversed copy: [6, 4, 7, 3, 9, 1, 8, 2, 5]

# Sorting
asc  = sorted(numbers)                  # new list, original unchanged
desc = sorted(numbers, reverse=True)
numbers.sort()                          # in-place sort

# Comprehensions
squares  = [x**2 for x in range(1, 11)]
evens    = [x for x in range(20) if x % 2 == 0]

# Flatten a 2D list
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat   = [n for row in matrix for n in row]
print(flat)   # [1, 2, 3, 4, 5, 6, 7, 8, 9]

# Filter and transform together
people  = [("Alice", 30), ("Bob", 17), ("Carol", 25)]
adults  = [name for name, age in people if age >= 18]
print(adults) # ['Alice', 'Carol']
```

---

### Example 6: Tuple Packing, Unpacking and namedtuple

```python
from collections import namedtuple

# Basic tuple operations
point = (3, 4)
x, y  = point             # unpack
print(f"x={x}, y={y}")

# Extended unpacking
a, *b, c = (1, 2, 3, 4, 5)
print(a, b, c)             # 1  [2, 3, 4]  5

# Functions commonly return tuples (multiple values)
def min_max(lst):
    return min(lst), max(lst)

lo, hi = min_max([3, 1, 4, 1, 5, 9])
print(lo, hi)              # 1  9

# Named tuple — lightweight, readable record
Point3D = namedtuple("Point3D", ["x", "y", "z"])
p = Point3D(1, 2, 3)
print(p.y)                 # 2
print(p[2])                # 3  (index access still works)
print(p._asdict())         # OrderedDict representation

# Modify via _replace (returns a new tuple)
p2 = p._replace(z=10)
print(p2)                  # Point3D(x=1, y=2, z=10)
```

---

### Example 7: Dictionary CRUD and Comprehensions

```python
# Build and modify a contact record
contact = {
    "name": "Alice",
    "phone": "555-1234",
    "email": "alice@example.com",
}

# Safe read with default
print(contact.get("address", "No address on file"))

# Update multiple keys at once
contact.update({"city": "NYC", "zip": "10001"})

# Remove a key safely
removed = contact.pop("zip", None)

# Iterate over key-value pairs
for key, value in contact.items():
    print(f"  {key:10s} -> {value}")

# Dict comprehension: invert key-value
original = {"a": 1, "b": 2, "c": 3}
inverted = {v: k for k, v in original.items()}
print(inverted)     # {1: 'a', 2: 'b', 3: 'c'}

# Nested dict — student records
students = {
    "Alice": {"grade": "A", "score": 95},
    "Bob":   {"grade": "B", "score": 82},
}
top = {name: info for name, info in students.items() if info["score"] >= 90}
print(top)
```

---

### Example 8: Sets and Set Operations

```python
# Deduplicate a list using a set
raw    = [1, 2, 2, 3, 3, 3, 4]
unique = sorted(set(raw))     # sorted to get deterministic order
print(unique)   # [1, 2, 3, 4]

# Typical use case: find overlap between two groups
python_devs = {"Alice", "Bob", "Carol", "Dave"}
js_devs     = {"Bob", "Eve", "Carol", "Frank"}

fullstack  = python_devs & js_devs          # intersection
either     = python_devs | js_devs          # union
only_py    = python_devs - js_devs          # difference
exclusive  = python_devs ^ js_devs          # symmetric difference

print(f"Fullstack devs : {sorted(fullstack)}")
print(f"Only Python    : {sorted(only_py)}")
print(f"Total unique   : {len(either)}")

# Set comprehension
even_squares = {x**2 for x in range(-5, 6) if x % 2 == 0}
print(even_squares)   # {0, 4, 16}
```

---

### Example 9: Control Flow — if/elif/else and Ternary

```python
def classify_bmi(bmi):
    '''Return a BMI category string.'''
    if bmi < 18.5:
        return "Underweight"
    elif bmi < 25.0:
        return "Normal weight"
    elif bmi < 30.0:
        return "Overweight"
    else:
        return "Obese"

for bmi in [16.0, 22.5, 27.3, 35.1]:
    print(f"BMI {bmi:.1f}: {classify_bmi(bmi)}")

# Ternary in a list comprehension
labels = ["even" if x % 2 == 0 else "odd" for x in range(6)]
print(labels)   # ['even', 'odd', 'even', 'odd', 'even', 'odd']
```

---

### Example 10: Loops — for, while, break, continue

```python
# Generate Fibonacci numbers with while
a, b = 0, 1
fibs = []
while b < 100:
    fibs.append(b)
    a, b = b, a + b
print(fibs)   # [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

# for + enumerate + for-else
fruits = ["apple", "banana", "cherry", "date", "elderberry"]
for i, fruit in enumerate(fruits):
    if fruit.startswith("d"):
        print(f"Found at index {i}: {fruit}")
        break
else:
    print("Not found")    # only runs if loop completed without break

# zip — parallel iteration over two sequences
names  = ["Alice", "Bob", "Carol"]
scores = [95, 82, 91]
for name, score in zip(names, scores):
    print(f"{name}: {score}")
```

---

### Example 11: Functions — Default Args, *args, **kwargs

```python
def power(base, exponent=2):
    '''Raise base to exponent (default: square).'''
    return base ** exponent

print(power(3))        # 9
print(power(2, 10))    # 1024

def summarize(*args, sep=", ", **kwargs):
    '''Print positional args joined by sep, then keyword args.'''
    print("Values :", sep.join(str(a) for a in args))
    print("Options:")
    for k, v in kwargs.items():
        print(f"  {k} = {v}")

summarize(1, 2, 3, sep=" | ", name="Alice", role="Admin")
# Values : 1 | 2 | 3
# Options:
#   name = Alice
#   role = Admin
```

---

### Example 12: Lambda and Higher-Order Functions

```python
from functools import reduce

# Lambda — anonymous single-expression function
square   = lambda x: x ** 2
multiply = lambda x, y: x * y

# sorted with key
people  = [("Alice", 30), ("Bob", 25), ("Carol", 35)]
by_age  = sorted(people, key=lambda p: p[1])
by_name = sorted(people, key=lambda p: p[0])
print(by_age)   # [('Bob', 25), ('Alice', 30), ('Carol', 35)]

# map and filter (list comprehensions often clearer)
doubled  = list(map(lambda x: x * 2, range(5)))
positive = list(filter(lambda x: x > 0, [-2, -1, 0, 1, 2]))

# reduce — fold a sequence into a single value
product = reduce(lambda acc, x: acc * x, [1, 2, 3, 4, 5])
print(product)   # 120
```

---

### Example 13: Closures and the LEGB Rule

```python
# LEGB demonstration
x = "global"

def outer():
    x = "enclosing"
    def inner():
        # x = "local"  # uncomment to see local scope take precedence
        print(f"inner sees: {x}")    # enclosing
    inner()

outer()
print(f"module sees: {x}")   # global

# Practical closure: function factory
def make_multiplier(factor):
    def multiply(n):
        return n * factor       # factor captured from enclosing scope
    return multiply

double = make_multiplier(2)
triple = make_multiplier(3)
print(double(5), triple(5))    # 10  15

# nonlocal — modify enclosing variable
def make_counter():
    count = 0
    def increment(step=1):
        nonlocal count
        count += step
        return count
    return increment

c = make_counter()
print(c(), c(), c(5))   # 1  2  7
```

---

### Example 14: Exception Handling — Full Pattern

```python
class NegativeValueError(ValueError):
    '''Raised when a value should be non-negative but is not.'''
    pass

def safe_sqrt(n):
    '''Return square root of n; raises on invalid input.'''
    if not isinstance(n, (int, float)):
        raise TypeError(f"Expected number, got {type(n).__name__}")
    if n < 0:
        raise NegativeValueError(f"sqrt undefined for negative: {n}")
    return n ** 0.5

test_values = [4, 9, -1, "hello", 0]
for val in test_values:
    try:
        result = safe_sqrt(val)
    except NegativeValueError as e:
        print(f"Domain error  : {e}")
    except TypeError as e:
        print(f"Type error    : {e}")
    else:
        print(f"sqrt({val}) = {result:.4f}")
    finally:
        print(f"  processed: {val!r}")
```

---

### Example 15: File I/O — Read, Write, Append

```python
import os

filename = "demo_notes.txt"

# Write (create or overwrite)
with open(filename, "w", encoding="utf-8") as f:
    f.write("Line 1: Python is fun\n")
    f.write("Line 2: File I/O is straightforward\n")

# Append
with open(filename, "a", encoding="utf-8") as f:
    f.write("Line 3: Added later\n")

# Read entire file
with open(filename, "r", encoding="utf-8") as f:
    print(f.read())

# Read line by line (memory-efficient for large files)
with open(filename) as f:
    for line_no, line in enumerate(f, start=1):
        print(f"{line_no:>3}: {line.rstrip()}")

os.remove(filename)   # cleanup demo file
```

---

### Example 16: CSV Module — Read and Write

```python
import csv, io

# Use in-memory buffer for demo (same API as a real file)
buf = io.StringIO()

# Write CSV with a DictWriter
fieldnames = ["name", "age", "city"]
writer = csv.DictWriter(buf, fieldnames=fieldnames)
writer.writeheader()
writer.writerows([
    {"name": "Alice", "age": 30, "city": "NYC"},
    {"name": "Bob",   "age": 25, "city": "LA"},
    {"name": "Carol", "age": 35, "city": "Chicago"},
])

# Read it back with a DictReader
buf.seek(0)
reader = csv.DictReader(buf)
for row in reader:
    print(f"{row['name']:<10} ({row['age']}) lives in {row['city']}")
```

---

### Example 17: JSON Module — Serialise and Deserialise

```python
import json, datetime

# Python dict -> JSON string
data = {
    "user":   "Alice",
    "scores": [95, 87, 92],
    "active": True,
    "notes":  None,
}

json_str = json.dumps(data, indent=2)
print(json_str)

# JSON string -> Python dict
parsed = json.loads(json_str)
print(parsed["user"])          # Alice
print(type(parsed["active"]))  # <class 'bool'>

# Serialise types json doesn't know (e.g., date)
event = {"name": "Meeting", "date": datetime.date.today()}
serialized = json.dumps(event, default=str)   # convert unknown types to str
print(serialized)
```

---

### Example 18: Standard Library — Counter, defaultdict, lru_cache

```python
from collections import Counter, defaultdict
from functools import lru_cache

# Counter — frequency map in one line
text  = "the quick brown fox jumps over the lazy fox"
words = text.split()
freq  = Counter(words)
print(freq.most_common(3))   # [('the', 2), ('fox', 2), ('quick', 1)]

# Counter arithmetic
c1 = Counter("abracadabra")
c2 = Counter("alakazam")
print(c1 + c2)    # combined counts
print(c1 & c2)    # minimum (intersection)
print(c1 - c2)    # subtract (only positives kept)

# defaultdict — group items without KeyError
animals = ["cat", "dog", "cat", "fish", "dog", "dog"]
groups  = defaultdict(list)
for animal in animals:
    groups[animal].append(1)
print({k: sum(v) for k, v in groups.items()})

# lru_cache — automatic memoization
@lru_cache(maxsize=None)
def fib(n):
    if n < 2: return n
    return fib(n - 1) + fib(n - 2)

print([fib(i) for i in range(10)])   # [0,1,1,2,3,5,8,13,21,34]
```

---

### Example 19: Modules — Import Patterns and __name__ Guard

```python
# math_utils.py  (save as a module)

import math
from pathlib import Path
from typing import List

def circle_area(radius: float) -> float:
    '''Return the area of a circle.'''
    if radius < 0:
        raise ValueError("Radius cannot be negative")
    return math.pi * radius ** 2

def statistics(numbers: List[float]) -> dict:
    '''Return basic statistics for a list of numbers.'''
    if not numbers:
        return {}
    n = len(numbers)
    mean = sum(numbers) / n
    variance = sum((x - mean)**2 for x in numbers) / n
    return {
        "count":  n,
        "mean":   round(mean, 4),
        "std":    round(variance**0.5, 4),
        "min":    min(numbers),
        "max":    max(numbers),
    }

if __name__ == "__main__":
    print(circle_area(5))
    print(statistics([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
```

---

### Example 20: Full Pipeline — Text Analyser

```python
import re
from collections import Counter
from pathlib import Path

def analyze_text(text: str) -> dict:
    '''
    Analyse text: frequency, unique words, avg length, top-5.
    Returns a dict with analysis results.
    '''
    words = re.findall(r"\b[a-z]+\b", text.lower())

    if not words:
        return {"error": "No words found in input"}

    freq   = Counter(words)
    unique = set(words)

    return {
        "total_words":  len(words),
        "unique_words": len(unique),
        "avg_length":   round(sum(len(w) for w in words) / len(words), 2),
        "top_5":        freq.most_common(5),
        "longest_word": max(unique, key=len),
        "shortest_word": min(unique, key=len),
    }

sample = """
    Python is an interpreted high-level general-purpose programming language.
    Python's design philosophy emphasizes code readability with the use of
    significant indentation. Python is dynamically typed and garbage-collected.
    It supports multiple programming paradigms including structured functional
    and object-oriented programming.
"""

result = analyze_text(sample)
print(f"{'Metric':<20} Value")
print("-" * 40)
for k, v in result.items():
    print(f"{k:<20} {v}")
```

---

### Example 21 (Bonus): Decorator — Timing and Logging

```python
import time
from functools import wraps

def timer(func):
    '''Decorator: print execution time of the wrapped function.'''
    @wraps(func)           # preserves __name__, __doc__, etc.
    def wrapper(*args, **kwargs):
        start  = time.perf_counter()
        result = func(*args, **kwargs)
        end    = time.perf_counter()
        print(f"[timer] {func.__name__} took {end - start:.6f}s")
        return result
    return wrapper

def retry(times=3):
    '''Decorator factory: retry function up to `times` on exception.'''
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(1, times + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == times:
                        raise
                    print(f"Attempt {attempt} failed: {e}. Retrying...")
        return wrapper
    return decorator

@timer
def slow_sum(n):
    return sum(range(n))

@retry(times=3)
def unreliable():
    import random
    if random.random() < 0.7:
        raise RuntimeError("Random failure")
    return "Success"

print(slow_sum(1_000_000))
```

---

*End of EXAMPLES.md — 21 annotated working examples covering all theory topics*
