# pytest, Unit Testing & TDD — Theory Guide

## 1. Why Testing Matters

### In General Software Development
- Catches bugs early before they reach production
- Acts as living documentation of expected behavior
- Enables fearless refactoring — change code confidently
- Reduces debugging time by isolating failures quickly
- Supports team collaboration — others understand intent via tests

### In Machine Learning Projects
- ML pipelines are complex: data → features → model → predictions
- Silent failures are common (wrong shapes, NaN values, off-by-one errors)
- Model training is expensive — catch bugs before a 10-hour training run
- Data drift can break preprocessing silently without tests
- Reproducibility: tests verify deterministic behavior where expected
- Regulatory compliance in some domains (healthcare, finance) requires test coverage

---

## 2. Test Types

### Unit Tests
- Test a single function or class in isolation
- Fast to run (milliseconds each)
- No external dependencies (database, network, filesystem)
- Examples: test a tokenizer, a feature scaler, a math utility

### Integration Tests
- Test multiple components working together
- Slower than unit tests
- May involve real databases or file systems
- Examples: test a data pipeline end-to-end, test model + preprocessor together

### End-to-End (E2E) Tests
- Test the entire system from user perspective
- Slowest and most brittle
- Examples: simulate an HTTP request to an ML API and check the final response

### Regression Tests
- Ensure previously fixed bugs do not return
- Written after a bug is discovered and fixed
- Guard against future refactoring breaking old behavior

### Smoke Tests
- Quick sanity checks that the system starts and basic paths work
- Run before full test suite to fail fast

---

## 3. pytest vs unittest vs doctest

### unittest (built-in)
- Part of Python standard library (no install needed)
- Verbose boilerplate: must subclass `unittest.TestCase`
- Uses `self.assertEqual`, `self.assertRaises`, etc.
- Java-style API (JUnit heritage)

```python
import unittest

class TestMath(unittest.TestCase):
    def test_add(self):
        self.assertEqual(1 + 1, 2)
```

### doctest (built-in)
- Embeds tests inside docstrings
- Great for documentation examples
- Not suitable for complex test logic

```python
def add(a, b):
    """
    >>> add(2, 3)
    5
    """
    return a + b
```

### pytest (recommended)
- Third-party (`pip install pytest`)
- No boilerplate — plain functions with `assert`
- Rich diff output on failure
- Powerful fixtures, marks, parameterization
- Huge plugin ecosystem (pytest-cov, pytest-asyncio, etc.)
- Compatible with unittest tests

```python
def test_add():
    assert 1 + 1 == 2
```

**Verdict:** Use pytest for all serious projects.

---

## 4. Test Discovery

pytest automatically finds and runs tests based on naming conventions:

### File Naming
- `test_*.py` — prefix convention (most common)
- `*_test.py` — suffix convention
- Both work; prefix is standard in most projects

### Function Naming
- Functions must start with `test_`
- Example: `test_model_accuracy`, `test_preprocess_input`

### Class Naming
- Classes must start with `Test` (no `__init__` method)
- Methods inside must start with `test_`

### Directory Structure
```
project/
├── src/
│   └── model.py
└── tests/
    ├── conftest.py
    ├── test_model.py
    └── test_preprocessing.py
```

### Running Tests
```bash
pytest                    # discover and run all tests
pytest tests/             # run tests in specific directory
pytest tests/test_model.py  # run specific file
pytest -v                 # verbose output
pytest -k "preprocess"    # run tests matching keyword
pytest -x                 # stop after first failure
```

---

## 5. The assert Statement & Rich Diff

pytest rewrites `assert` statements to provide detailed failure messages.

```python
def test_example():
    result = [1, 2, 3]
    expected = [1, 2, 4]
    assert result == expected
    # Output: AssertionError: assert [1, 2, 3] == [1, 2, 4]
    #         At index 2 diff: 3 != 4
```

For custom messages:
```python
assert value > 0, f"Expected positive value, got {value}"
```

pytest's assert rewriting works for: lists, dicts, sets, strings, numbers.

---

## 6. pytest.raises() — Testing Exceptions

Use `pytest.raises()` as a context manager to assert that code raises an exception.

```python
import pytest

def test_division_by_zero():
    with pytest.raises(ZeroDivisionError):
        result = 1 / 0

def test_value_error_message():
    with pytest.raises(ValueError, match="invalid input"):
        raise ValueError("invalid input provided")
```

- `match` parameter accepts a regex pattern
- Access exception info with `as exc_info`

```python
def test_exception_details():
    with pytest.raises(TypeError) as exc_info:
        int("not_a_number")
    assert "invalid literal" in str(exc_info.value)
```

---

## 7. Fixtures

Fixtures provide reusable setup/teardown logic for tests.

### Basic Fixture
```python
import pytest

@pytest.fixture
def sample_data():
    return {"x": [1, 2, 3], "y": [0, 1, 0]}

def test_data_length(sample_data):
    assert len(sample_data["x"]) == 3
```

### Fixture Scopes
| Scope | Lifecycle |
|-------|-----------|
| `function` | Default. Created/destroyed per test |
| `class` | Shared across methods in a test class |
| `module` | Shared across all tests in a file |
| `session` | Shared across the entire test run |

```python
@pytest.fixture(scope="module")
def db_connection():
    conn = create_connection()
    yield conn       # teardown after yield
    conn.close()
```

### autouse Fixtures
Run automatically for every test without being explicitly requested:
```python
@pytest.fixture(autouse=True)
def reset_random_seed():
    import random
    random.seed(42)
```

### conftest.py
Shared fixture file — pytest discovers it automatically. Place in the `tests/` directory or project root.

```python
# conftest.py
import pytest

@pytest.fixture(scope="session")
def trained_model():
    model = load_model("model.pkl")
    return model
```

---

## 8. Parameterized Tests

Run the same test with multiple inputs using `@pytest.mark.parametrize`.

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (-1, 1),
    (0, 0),
])
def test_square(input, expected):
    assert input ** 2 == expected
```

Parameterize multiple arguments:
```python
@pytest.mark.parametrize("a,b,result", [
    (1, 2, 3),
    (0, 0, 0),
    (-1, 1, 0),
])
def test_add(a, b, result):
    assert a + b == result
```

---

## 9. Marks

### @pytest.mark.skip
```python
@pytest.mark.skip(reason="Feature not yet implemented")
def test_future_feature():
    pass
```

### @pytest.mark.skipif
```python
import sys
@pytest.mark.skipif(sys.platform == "win32", reason="Unix only")
def test_unix_path():
    pass
```

### @pytest.mark.xfail
Mark a test expected to fail (known bug, pending feature):
```python
@pytest.mark.xfail(reason="Bug #123 not yet fixed")
def test_known_bug():
    assert broken_function() == 42
```

### Custom Marks
Register in `pytest.ini` or `pyproject.toml`:
```ini
[pytest]
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    gpu: marks tests requiring GPU
```

```python
@pytest.mark.slow
def test_large_model_training():
    pass
```

Run only fast tests: `pytest -m "not slow"`

---

## 10. Mocking

Mocking replaces real objects with controllable fakes during tests.

### unittest.mock.patch
```python
from unittest.mock import patch

def test_api_call():
    with patch("requests.get") as mock_get:
        mock_get.return_value.json.return_value = {"status": "ok"}
        result = my_api_function()
        assert result == "ok"
```

### MagicMock
```python
from unittest.mock import MagicMock

mock_model = MagicMock()
mock_model.predict.return_value = [1, 0, 1]
result = mock_model.predict([[1, 2, 3]])
assert result == [1, 0, 1]
```

### side_effect
Simulate exceptions or dynamic behavior:
```python
mock_fn = MagicMock()
mock_fn.side_effect = [1, 2, ValueError("error")]
```

---

## 11. Coverage: pytest-cov

Install: `pip install pytest-cov`

```bash
pytest --cov=src tests/           # coverage for src/
pytest --cov=src --cov-report=html  # HTML report in htmlcov/
pytest --cov=src --cov-fail-under=80  # fail if coverage < 80%
```

### .coveragerc Configuration
```ini
[coverage:run]
source = src
omit = tests/*

[coverage:report]
show_missing = True
fail_under = 80
```

---

## 12. Testing ML Code

### Test Preprocessing
```python
def test_normalizer_output_range(normalizer, raw_data):
    result = normalizer.transform(raw_data)
    assert result.min() >= 0.0
    assert result.max() <= 1.0
```

### Test Model Output Shape
```python
def test_model_output_shape(model):
    x = np.random.rand(10, 5)
    predictions = model.predict(x)
    assert predictions.shape == (10,)
```

### Test Accuracy Threshold
```python
def test_model_accuracy_threshold(trained_model, test_data):
    X_test, y_test = test_data
    accuracy = trained_model.score(X_test, y_test)
    assert accuracy >= 0.80, f"Accuracy {accuracy:.2f} below threshold 0.80"
```

---

## 13. Testing Flask/FastAPI APIs

### Flask with test_client
```python
def test_predict_endpoint(flask_app):
    client = flask_app.test_client()
    response = client.post("/predict", json={"features": [1.0, 2.0]})
    assert response.status_code == 200
    assert "prediction" in response.get_json()
```

### FastAPI with TestClient
```python
from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
```

---

## 14. Testing Async Code: pytest-asyncio

Install: `pip install pytest-asyncio`

```python
import pytest
import asyncio

@pytest.mark.asyncio
async def test_async_fetch():
    result = await fetch_data("http://example.com")
    assert result is not None
```

Configure in `pytest.ini`:
```ini
[pytest]
asyncio_mode = auto
```

---

## 15. CI/CD Integration: GitHub Actions

```yaml
# .github/workflows/tests.yml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: "3.11"
      - run: pip install -r requirements.txt
      - run: pytest --cov=src --cov-fail-under=80 -v
```

---

## Summary Cheat Sheet

| Feature | Command/Syntax |
|---------|---------------|
| Run all tests | `pytest` |
| Verbose | `pytest -v` |
| Stop on first fail | `pytest -x` |
| Run by keyword | `pytest -k "model"` |
| Run by mark | `pytest -m "not slow"` |
| Coverage | `pytest --cov=src` |
| HTML coverage | `pytest --cov=src --cov-report=html` |
| Fixture scope | `@pytest.fixture(scope="module")` |
| Parameterize | `@pytest.mark.parametrize(...)` |
| Skip | `@pytest.mark.skip(reason="...")` |
| Expect fail | `@pytest.mark.xfail` |