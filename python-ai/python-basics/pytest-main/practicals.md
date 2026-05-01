# pytest Practicals — 10 Exercises

Write complete test suites for each code snippet below.
Each exercise includes: objective, code to test, requirements, hints, and expected outcome.

---

## Exercise 1: String Utilities

**Objective:** Write a full test suite for a string utility module using parametrize and edge cases.

**Code to Test:**
```python
# string_utils.py

def reverse_string(s):
    return s[::-1]

def count_vowels(s):
    return sum(1 for c in s.lower() if c in "aeiou")

def is_palindrome(s):
    clean = s.lower().replace(" ", "")
    return clean == clean[::-1]

def title_case(s):
    return s.title()
```

**Requirements:**
- Test `reverse_string` with a normal string, empty string, and single character
- Test `count_vowels` with zero vowels, multiple vowels, and uppercase input
- Test `is_palindrome` with true cases, false cases, with spaces, and mixed case
- Test `title_case` with all-lowercase and mixed input
- Use `@pytest.mark.parametrize` for `is_palindrome` (at least 5 input/expected pairs)

**Hints:**
- `reverse_string("")` should return `""`
- "racecar" is a palindrome; "hello" is not
- "A man a plan a canal Panama" is a palindrome (after stripping spaces and lowering)

**Expected Outcome:** At least 12 passing test cases.

---

## Exercise 2: Temperature Converter

**Objective:** Test unit conversion functions with boundary values and exception checking.

**Code to Test:**
```python
# temperature.py

def celsius_to_fahrenheit(c):
    return (c * 9/5) + 32

def fahrenheit_to_celsius(f):
    return (f - 32) * 5/9

def celsius_to_kelvin(c):
    if c < -273.15:
        raise ValueError(f"Temperature {c} is below absolute zero")
    return c + 273.15
```

**Requirements:**
- Test each conversion function with at least 3 known input/output pairs
- Verify round-trip: convert C -> F then F -> C and check you get the original value
- Test `celsius_to_kelvin` raises `ValueError` for temperatures below -273.15
- Test that 0°C maps to 273.15 K
- Use `pytest.approx()` for all float comparisons

**Hints:**
- Known values: 0°C = 32°F = 273.15 K; 100°C = 212°F; -40°C = -40°F
- Use `pytest.raises(ValueError, match=...)` to verify the error message
- Use `@pytest.mark.parametrize` for the 3-value conversion tests

**Expected Outcome:** 10+ passing tests covering conversions, round-trips, and errors.

---

## Exercise 3: Stack Data Structure

**Objective:** Test a custom Stack class with state-based fixtures and exception handling.

**Code to Test:**
```python
# stack.py

class Stack:
    def __init__(self):
        self._items = []

    def push(self, item):
        self._items.append(item)

    def pop(self):
        if self.is_empty():
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def peek(self):
        if self.is_empty():
            raise IndexError("peek at empty stack")
        return self._items[-1]

    def is_empty(self):
        return len(self._items) == 0

    def size(self):
        return len(self._items)
```

**Requirements:**
- Create a `@pytest.fixture` returning a Stack pre-loaded with items `[1, 2, 3]`
- Create a separate `@pytest.fixture` for an empty Stack
- Test `push`, `pop`, `peek`, `is_empty`, and `size`
- Test LIFO order: last pushed item should be first popped
- Test that `pop()` and `peek()` on empty stack raise `IndexError`

**Hints:**
- Use the populated fixture for pop/peek/size tests
- Use the empty fixture for `is_empty` and exception tests
- After pushing and popping the same item, size should be unchanged

**Expected Outcome:** 8+ tests covering all methods and error conditions.

---

## Exercise 4: Email and Password Validator

**Objective:** Use parametrize extensively for a validation module with many test cases.

**Code to Test:**
```python
# validator.py
import re

def is_valid_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def is_strong_password(password):
    if len(password) < 8:
        return False
    has_upper = any(c.isupper() for c in password)
    has_digit = any(c.isdigit() for c in password)
    return has_upper and has_digit
```

**Requirements:**
- Parametrize `test_valid_emails` with at least 5 valid email addresses
- Parametrize `test_invalid_emails` with at least 5 invalid email addresses
- Parametrize `test_strong_passwords` with at least 4 strong passwords
- Parametrize `test_weak_passwords` with at least 4 weak passwords
- Cover edge cases: empty string, no `@`, no domain extension, spaces

**Hints:**
- Valid: `user@example.com`, `first.last@sub.domain.org`
- Invalid: `no-at-sign`, `@no-local.com`, `missing@dot`
- Weak passwords: too short, no uppercase, no digit

**Expected Outcome:** 20+ parameterized test cases, all passing.

---

## Exercise 5: Bank Account

**Objective:** Test a stateful class with fixture isolation and comprehensive error checking.

**Code to Test:**
```python
# bank.py

class BankAccount:
    def __init__(self, owner, balance=0.0):
        self.owner = owner
        self.balance = balance
        self._transactions = []

    def deposit(self, amount):
        if amount <= 0:
            raise ValueError("Deposit amount must be positive")
        self.balance += amount
        self._transactions.append(("deposit", amount))

    def withdraw(self, amount):
        if amount <= 0:
            raise ValueError("Withdrawal amount must be positive")
        if amount > self.balance:
            raise ValueError("Insufficient funds")
        self.balance -= amount
        self._transactions.append(("withdraw", amount))

    def get_transaction_count(self):
        return len(self._transactions)
```

**Requirements:**
- Create a fixture that returns a `BankAccount("Alice", balance=1000.0)`
- Test `deposit` increases balance correctly
- Test `withdraw` decreases balance correctly
- Test withdrawing exactly the full balance succeeds (boundary)
- Test `deposit(0)` and `deposit(-50)` raise `ValueError`
- Test `withdraw` with insufficient funds raises `ValueError`
- Test `get_transaction_count` increments with each operation

**Hints:**
- Use `pytest.raises(ValueError, match="Insufficient funds")` for specific message
- Boundary test: `account.withdraw(1000.0)` should leave balance at 0.0
- Each test should receive a fresh account from the fixture

**Expected Outcome:** 10+ tests covering all methods and error conditions.

---

## Exercise 6: Data Pipeline with Mocking

**Objective:** Test a data pipeline by mocking file I/O and database connections.

**Code to Test:**
```python
# pipeline.py
import json

def load_config(filepath):
    with open(filepath) as f:
        return json.load(f)

def process_records(records):
    return [
        {**r, "processed": True, "score": r.get("value", 0) * 2}
        for r in records
    ]

def save_to_db(db_conn, table, records):
    db_conn.execute(f"INSERT INTO {table} VALUES (?)", records)
    db_conn.commit()
    return len(records)
```

**Requirements:**
- Mock `builtins.open` to test `load_config` without a real file
- Test `process_records` directly with sample data (no mocking needed)
- Mock `db_conn` as a `MagicMock` to test `save_to_db`
- Verify `db_conn.execute` is called with the correct arguments
- Verify `db_conn.commit` is called once
- Test that `save_to_db` returns the correct record count

**Hints:**
- Use `unittest.mock.mock_open(read_data='{"key": "value"}')` for `load_config`
- Use `patch("builtins.open", mock_open(...))` as a context manager
- `MagicMock()` auto-creates any attribute you access on it

**Expected Outcome:** 6+ tests using mocks and direct testing, all passing.

---

## Exercise 7: ML Feature Engineering

**Objective:** Test numpy-based feature transformation functions for ML pipelines.

**Code to Test:**
```python
# features.py
import numpy as np

def add_polynomial_features(X, degree=2):
    return np.column_stack([X ** i for i in range(1, degree + 1)])

def clip_outliers(X, lower=-3.0, upper=3.0):
    return np.clip(X, lower, upper)

def encode_labels(labels):
    unique = sorted(set(labels))
    mapping = {label: idx for idx, label in enumerate(unique)}
    return [mapping[l] for l in labels], mapping
```

**Requirements:**
- Test `add_polynomial_features` output shape for degree 2 (n_samples x 2) and degree 3
- Test `clip_outliers` ensures no value is outside [lower, upper]
- Test `clip_outliers` with default and custom bounds
- Test `encode_labels` encoding is consistent and starts from 0
- Test `encode_labels` mapping contains all unique labels

**Hints:**
- Use `@pytest.fixture` to provide a reusable array `[1.0, 2.0, 3.0]`
- Use `numpy.testing.assert_array_almost_equal` for float array checks
- `add_polynomial_features([2, 3], degree=2)` should give `[[2, 4], [3, 9]]`

**Expected Outcome:** 8+ tests validating shapes, values, and label encoding.

---

## Exercise 8: REST API Client with HTTP Mocking

**Objective:** Test an HTTP API client without making real network requests.

**Code to Test:**
```python
# api_client.py
import requests

class WeatherClient:
    BASE_URL = "https://api.weather.com/v1"

    def __init__(self, api_key):
        self.api_key = api_key
        self.session = requests.Session()

    def get_temperature(self, city):
        url = f"{self.BASE_URL}/current"
        response = self.session.get(url, params={"city": city, "key": self.api_key})
        response.raise_for_status()
        return response.json()["temperature"]

    def get_forecast(self, city, days=5):
        url = f"{self.BASE_URL}/forecast"
        response = self.session.get(
            url, params={"city": city, "days": days, "key": self.api_key}
        )
        response.raise_for_status()
        return response.json()["forecast"]
```

**Requirements:**
- Create a `@pytest.fixture` that returns a `WeatherClient` with a test API key
- Mock `self.session.get` using `unittest.mock.patch.object`
- Test `get_temperature` returns correct temperature from mocked JSON
- Test `get_forecast` returns a list of forecasts
- Test that HTTP errors from `raise_for_status()` propagate to the caller

**Hints:**
- `patch.object(client.session, "get", return_value=mock_response)`
- Set `mock_response.json.return_value = {"temperature": 22}`
- For error test: `mock_response.raise_for_status.side_effect = requests.HTTPError()`

**Expected Outcome:** 6+ tests all passing with properly mocked HTTP calls.

---

## Exercise 9: Async Task Queue

**Objective:** Test asynchronous code using pytest-asyncio.

**Code to Test:**
```python
# task_queue.py
import asyncio

class AsyncTaskQueue:
    def __init__(self):
        self._queue = asyncio.Queue()
        self.processed = []

    async def enqueue(self, task):
        await self._queue.put(task)

    async def process_one(self):
        task = await self._queue.get()
        result = task.upper()   # simulate processing
        self.processed.append(result)
        return result

    async def process_all(self):
        results = []
        while not self._queue.empty():
            result = await self.process_one()
            results.append(result)
        return results
```

**Requirements:**
- Mark all tests with `@pytest.mark.asyncio`
- Create an async fixture that returns an `AsyncTaskQueue`
- Test `enqueue` adds an item (check queue size after enqueue)
- Test `process_one` returns the uppercased result
- Test `process_all` processes all items and clears the queue
- Test `processed` list tracks all processed tasks

**Hints:**
- Install: `pip install pytest-asyncio`
- Add `asyncio_mode = auto` to `pytest.ini` or use `@pytest.mark.asyncio` explicitly
- `queue._queue.qsize()` gives the current queue depth

**Expected Outcome:** 5+ async tests all passing.

---

## Exercise 10: Flask ML API — Full Integration Test Suite

**Objective:** Write a comprehensive test suite for a Flask endpoint serving ML predictions.

**Code to Test:**
```python
# app.py
from flask import Flask, request, jsonify
import numpy as np

app = Flask(__name__)

class SimpleModel:
    def predict(self, X):
        return (np.sum(X, axis=1) > 0).astype(int).tolist()

model = SimpleModel()

@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": "1.0"})

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()
    if not data or "features" not in data:
        return jsonify({"error": "Missing features"}), 400
    try:
        X = np.array(data["features"])
        if X.ndim == 1:
            X = X.reshape(1, -1)
        predictions = model.predict(X)
        return jsonify({"predictions": predictions, "count": len(predictions)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
```

**Requirements:**
- Create a `@pytest.fixture` that returns a Flask test client with `TESTING=True`
- Test `/health` returns status 200 with `{"status": "ok", "version": "1.0"}`
- Test `/predict` with a single feature vector `[1.0, 2.0, 3.0]` -> prediction 1
- Test `/predict` with a negative feature vector -> prediction 0
- Test `/predict` with a batch of multiple samples (2D array)
- Test `/predict` with missing body returns 400 and an error message
- Test the `count` field matches the number of input samples
- Test that `predictions` is a list

**Hints:**
- Import `app` from `app.py` (or define it inline in the test file)
- Use `client.post("/predict", json={"features": [...]})` to send data
- `response.get_json()` returns the deserialized JSON body
- A single feature vector `[1, 2, 3]` has sum > 0, so prediction should be 1

**Expected Outcome:** 8+ tests covering health, predictions, batch input, and error handling.
