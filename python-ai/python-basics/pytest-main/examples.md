# pytest Examples — 22 Working Test Code Examples

## Example 1: Basic assert — Testing a Pure Function

**Topic:** assert statement with rich diff
**Explanation:** pytest rewrites assert statements to show exactly where values differ — no custom message needed for most failures.

```python
# test_basic_assert.py

def add(a, b):
    return a + b

def test_add_integers():
    assert add(2, 3) == 5

def test_add_floats():
    result = add(1.1, 2.2)
    assert abs(result - 3.3) < 1e-9  # float comparison with tolerance

def test_add_strings():
    assert add("hello", " world") == "hello world"

def test_add_lists():
    result = add([1, 2], [3, 4])
    expected = [1, 2, 3, 4]
    assert result == expected  # pytest shows detailed diff on failure
```

---

## Example 2: pytest.raises() — Testing Exceptions

**Topic:** Exception testing
**Explanation:** Use the `pytest.raises()` context manager to assert that code raises an exception with the correct type and message.

```python
# test_exceptions.py
import pytest

def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    if not isinstance(a, (int, float)):
        raise TypeError(f"Expected number, got {type(a).__name__}")
    return a / b

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_divide_by_zero_message():
    # match= accepts a regex pattern
    with pytest.raises(ZeroDivisionError, match="Cannot divide by zero"):
        divide(10, 0)

def test_type_error():
    with pytest.raises(TypeError) as exc_info:
        divide("ten", 2)
    assert "str" in str(exc_info.value)   # inspect exception message

def test_valid_division():
    assert divide(10, 2) == 5.0
```

---

## Example 3: Fixtures — Setup and Teardown

**Topic:** Fixtures with function scope
**Explanation:** Fixtures provide reusable test data. Code after `yield` runs as teardown.

```python
# test_fixtures.py
import pytest

class UserService:
    def __init__(self):
        self.users = {}

    def add_user(self, user_id, name):
        self.users[user_id] = name

    def get_user(self, user_id):
        return self.users.get(user_id)

    def delete_user(self, user_id):
        return self.users.pop(user_id, None)

@pytest.fixture
def user_service():
    # SETUP
    service = UserService()
    service.add_user(1, "Alice")
    service.add_user(2, "Bob")
    yield service
    # TEARDOWN (runs after each test)
    # in-memory service needs no cleanup here

def test_get_existing_user(user_service):
    assert user_service.get_user(1) == "Alice"

def test_get_nonexistent_user(user_service):
    assert user_service.get_user(99) is None

def test_delete_user(user_service):
    user_service.delete_user(1)
    assert user_service.get_user(1) is None

def test_add_user(user_service):
    user_service.add_user(3, "Charlie")
    assert user_service.get_user(3) == "Charlie"
```

---

## Example 4: Module-Scoped Fixture

**Topic:** Fixture scope=module
**Explanation:** A module-scoped fixture is created once and shared by all tests in the file — avoids redundant expensive setup.

```python
# test_module_scope.py
import pytest

@pytest.fixture(scope="module")
def expensive_resource():
    print("\n[SETUP] Loading expensive resource...")
    resource = {"data": list(range(1000)), "ready": True}
    yield resource
    print("\n[TEARDOWN] Releasing resource...")

def test_resource_is_ready(expensive_resource):
    assert expensive_resource["ready"] is True

def test_resource_data_length(expensive_resource):
    assert len(expensive_resource["data"]) == 1000

def test_resource_first_element(expensive_resource):
    assert expensive_resource["data"][0] == 0
```

---

## Example 5: conftest.py Fixtures

**Topic:** Shared fixtures via conftest.py
**Explanation:** pytest automatically discovers `conftest.py` and makes its fixtures available to all tests in the directory tree.

```python
# conftest.py  (place in tests/ directory)
import pytest

@pytest.fixture(scope="session")
def app_config():
    return {
        "debug": False,
        "db_url": "sqlite:///:memory:",
        "model_path": "models/test_model.pkl",
        "threshold": 0.5
    }

@pytest.fixture
def sample_features():
    return [1.0, 2.5, 0.3, 4.1, 0.0]
```

```python
# test_with_conftest.py (consumes conftest fixtures by name)
def test_config_has_threshold(app_config):
    assert "threshold" in app_config
    assert app_config["threshold"] == 0.5

def test_sample_features_length(sample_features):
    assert len(sample_features) == 5
```

---

## Example 6: @pytest.mark.parametrize — Single Parameter

**Topic:** Parameterized tests
**Explanation:** Run the same test logic with many input values — pytest generates one test case per value.

```python
# test_parametrize_single.py
import pytest

def is_even(n):
    return n % 2 == 0

@pytest.mark.parametrize("number", [0, 2, 4, 100, -8])
def test_even_numbers(number):
    assert is_even(number) is True

@pytest.mark.parametrize("number", [1, 3, 7, -5, 99])
def test_odd_numbers(number):
    assert is_even(number) is False
```

---

## Example 7: @pytest.mark.parametrize — Multiple Parameters

**Topic:** Parameterized tests with multiple arguments
**Explanation:** Pass tuples to test functions with multiple parameters, covering boundary values explicitly.

```python
# test_parametrize_multi.py
import pytest

def classify_bmi(bmi):
    if bmi < 18.5:
        return "underweight"
    elif bmi < 25.0:
        return "normal"
    elif bmi < 30.0:
        return "overweight"
    else:
        return "obese"

@pytest.mark.parametrize("bmi,expected_class", [
    (15.0, "underweight"),
    (22.0, "normal"),
    (27.5, "overweight"),
    (35.0, "obese"),
    (18.5, "normal"),    # boundary: exactly 18.5 -> normal
    (24.99, "normal"),   # boundary: just under 25
])
def test_bmi_classifier(bmi, expected_class):
    assert classify_bmi(bmi) == expected_class
```

---

## Example 8: @pytest.mark.skip and @pytest.mark.skipif

**Topic:** Skipping tests
**Explanation:** Use `skip` to unconditionally skip, `skipif` for condition-based skipping.

```python
# test_skip.py
import pytest
import sys

@pytest.mark.skip(reason="GPU tests not available in CI")
def test_gpu_inference():
    pass   # skipped entirely

@pytest.mark.skipif(sys.platform == "win32", reason="Requires Unix filesystem")
def test_symlink_creation(tmp_path):
    link = tmp_path / "link"
    link.symlink_to(tmp_path / "target")
    assert link.exists()

def test_always_runs():
    assert 1 + 1 == 2
```

---

## Example 9: @pytest.mark.xfail — Expected Failures

**Topic:** xfail mark
**Explanation:** Mark tests that are known to fail — they show as `xfail` instead of `FAILED`, keeping CI green while tracking the issue.

```python
# test_xfail.py
import pytest

def buggy_function(x):
    return abs(x) * 2   # BUG: should return x * 2 (sign is lost)

@pytest.mark.xfail(reason="Bug #42: negative input returns wrong sign")
def test_negative_input():
    assert buggy_function(-3) == -6   # fails as expected

@pytest.mark.xfail(strict=True, reason="Must fail - feature not implemented")
def test_unimplemented_feature():
    raise NotImplementedError("Feature pending")

def test_positive_input():
    assert buggy_function(3) == 6    # passes correctly
```

---

## Example 10: autouse Fixture

**Topic:** autouse=True fixtures
**Explanation:** An `autouse` fixture runs automatically for every test in scope without being explicitly requested.

```python
# test_autouse.py
import pytest
import random

@pytest.fixture(autouse=True)
def set_random_seed():
    # Ensures every test starts with the same random state
    random.seed(42)
    yield
    # optional teardown here

def test_random_call_1():
    val = random.randint(1, 100)
    assert isinstance(val, int)
    assert 1 <= val <= 100

def test_random_call_2():
    # autouse fixture re-applies seed=42 before this test too
    val = random.randint(1, 100)
    assert 1 <= val <= 100
```

---

## Example 11: Mocking with unittest.mock.patch

**Topic:** Mocking external dependencies
**Explanation:** Replace real HTTP calls with mocked responses so tests are fast and don't hit the network.

```python
# test_mock_patch.py
from unittest.mock import patch, MagicMock

def fetch_weather(city):
    import requests
    response = requests.get(f"https://api.weather.com/{city}")
    return response.json()["temperature"]

def test_fetch_weather_mocked():
    mock_response = MagicMock()
    mock_response.json.return_value = {"temperature": 22, "city": "London"}

    with patch("requests.get", return_value=mock_response) as mock_get:
        temp = fetch_weather("London")
        mock_get.assert_called_once_with("https://api.weather.com/London")
        assert temp == 22
```

---

## Example 12: MagicMock — Mocking a Class

**Topic:** MagicMock for dependency injection
**Explanation:** Use `MagicMock(spec=SomeClass)` to create a testable substitute and verify method calls.

```python
# test_magicmock.py
from unittest.mock import MagicMock

class EmailService:
    def send(self, to, subject, body):
        pass   # real SMTP call

class UserRegistration:
    def __init__(self, email_service):
        self.email_service = email_service

    def register(self, user_email):
        self.email_service.send(
            to=user_email,
            subject="Welcome!",
            body="Thanks for registering."
        )
        return True

def test_register_sends_welcome_email():
    mock_email = MagicMock(spec=EmailService)
    registration = UserRegistration(mock_email)
    result = registration.register("user@example.com")

    assert result is True
    mock_email.send.assert_called_once_with(
        to="user@example.com",
        subject="Welcome!",
        body="Thanks for registering."
    )
```

---

## Example 13: side_effect — Simulating Retries and Errors

**Topic:** Mock side_effect
**Explanation:** `side_effect` controls mock behavior per call — raise exceptions on early attempts, succeed on later ones.

```python
# test_side_effect.py
from unittest.mock import MagicMock, patch

def call_api_with_retry(url, retries=3):
    import requests
    for attempt in range(retries):
        try:
            response = requests.get(url)
            return response.json()
        except Exception:
            if attempt == retries - 1:
                raise
    return None

def test_api_fails_then_succeeds():
    mock_success = MagicMock()
    mock_success.json.return_value = {"data": "ok"}

    with patch("requests.get") as mock_get:
        # Fail twice, succeed on 3rd attempt
        mock_get.side_effect = [
            ConnectionError("timeout"),
            ConnectionError("timeout"),
            mock_success,
        ]
        result = call_api_with_retry("http://api.test", retries=3)
        assert result == {"data": "ok"}
        assert mock_get.call_count == 3
```

---

## Example 14: Testing ML Preprocessing

**Topic:** ML test — preprocessing validation
**Explanation:** Verify data transformations produce correct shapes and value ranges before feeding into a model.

```python
# test_preprocessing.py
import pytest
import numpy as np

def normalize_minmax(data):
    data = np.array(data, dtype=float)
    min_val, max_val = data.min(), data.max()
    if max_val == min_val:
        return np.zeros_like(data)
    return (data - min_val) / (max_val - min_val)

@pytest.fixture
def raw_features():
    return np.array([10.0, 20.0, 30.0, 40.0, 50.0])

def test_normalized_min_is_zero(raw_features):
    result = normalize_minmax(raw_features)
    assert result.min() == pytest.approx(0.0)

def test_normalized_max_is_one(raw_features):
    result = normalize_minmax(raw_features)
    assert result.max() == pytest.approx(1.0)

def test_normalized_shape_unchanged(raw_features):
    result = normalize_minmax(raw_features)
    assert result.shape == raw_features.shape

def test_all_same_values():
    result = normalize_minmax([5.0, 5.0, 5.0])
    np.testing.assert_array_equal(result, [0.0, 0.0, 0.0])
```

---

## Example 15: Testing ML Model Output Shape

**Topic:** ML model output validation
**Explanation:** Verify that predictions have the correct shape, valid label values, and probability distributions.

```python
# test_model_output.py
import pytest
import numpy as np
from unittest.mock import MagicMock

@pytest.fixture
def mock_classifier():
    model = MagicMock()
    model.predict.return_value = np.array([0, 1, 1, 0, 1])
    model.predict_proba.return_value = np.array([
        [0.8, 0.2], [0.3, 0.7], [0.1, 0.9], [0.6, 0.4], [0.2, 0.8],
    ])
    return model

def test_prediction_shape(mock_classifier):
    preds = mock_classifier.predict(np.random.rand(5, 10))
    assert preds.shape == (5,)    # one prediction per sample

def test_predictions_are_binary(mock_classifier):
    preds = mock_classifier.predict(np.random.rand(5, 10))
    assert set(preds).issubset({0, 1})

def test_probabilities_sum_to_one(mock_classifier):
    proba = mock_classifier.predict_proba(np.random.rand(5, 10))
    np.testing.assert_array_almost_equal(proba.sum(axis=1), np.ones(5))
```

---

## Example 16: Testing Model Accuracy Threshold

**Topic:** Accuracy regression test
**Explanation:** Ensure the model never silently drops below a minimum required accuracy — catch performance regressions.

```python
# test_accuracy_threshold.py
import pytest
import numpy as np
from unittest.mock import MagicMock

@pytest.fixture
def accuracy_model():
    model = MagicMock()
    model.score.return_value = 0.85   # simulates 85% accuracy
    return model

@pytest.fixture
def test_dataset():
    X_test = np.random.rand(100, 5)
    y_test = np.random.randint(0, 2, 100)
    return X_test, y_test

def test_model_accuracy_above_threshold(accuracy_model, test_dataset):
    X_test, y_test = test_dataset
    accuracy = accuracy_model.score(X_test, y_test)
    assert accuracy >= 0.80, f"Accuracy {accuracy:.2f} below threshold 0.80"

def test_accuracy_is_valid_float(accuracy_model, test_dataset):
    X_test, y_test = test_dataset
    accuracy = accuracy_model.score(X_test, y_test)
    assert isinstance(accuracy, float)
    assert 0.0 <= accuracy <= 1.0
```

---

## Example 17: Testing Flask API

**Topic:** Flask API testing with test_client
**Explanation:** Use Flask's built-in test client to send requests and inspect responses without starting a real server.

```python
# test_flask_api.py
import pytest
try:
    from flask import Flask, jsonify, request
    FLASK_AVAILABLE = True
except ImportError:
    FLASK_AVAILABLE = False

@pytest.mark.skipif(not FLASK_AVAILABLE, reason="Flask not installed")
class TestFlaskAPI:

    @pytest.fixture
    def client(self):
        app = Flask(__name__)
        app.config["TESTING"] = True

        @app.route("/health")
        def health():
            return jsonify({"status": "ok"})

        @app.route("/predict", methods=["POST"])
        def predict():
            data = request.get_json()
            features = data.get("features", [])
            return jsonify({"prediction": int(sum(features) > 0)})

        with app.test_client() as c:
            yield c

    def test_health_check(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "ok"

    def test_predict_positive(self, client):
        response = client.post("/predict", json={"features": [1.0, 2.0, 3.0]})
        assert response.status_code == 200
        assert response.get_json()["prediction"] == 1

    def test_predict_negative(self, client):
        response = client.post("/predict", json={"features": [-1.0, -2.0]})
        assert response.get_json()["prediction"] == 0
```

---

## Example 18: Testing Async Code with pytest-asyncio

**Topic:** Async testing
**Explanation:** `@pytest.mark.asyncio` allows testing `async/await` functions directly.

```python
# test_async.py
# Install: pip install pytest-asyncio
import pytest
import asyncio

async def fetch_data(url: str) -> dict:
    await asyncio.sleep(0.01)   # simulate network I/O
    if "error" in url:
        raise ConnectionError("Server error")
    return {"url": url, "data": "sample result"}

@pytest.mark.asyncio
async def test_fetch_data_success():
    result = await fetch_data("https://api.example.com/data")
    assert result["data"] == "sample result"

@pytest.mark.asyncio
async def test_fetch_data_error():
    with pytest.raises(ConnectionError, match="Server error"):
        await fetch_data("https://api.example.com/error")

@pytest.mark.asyncio
async def test_concurrent_fetches():
    urls = ["http://api.com/1", "http://api.com/2", "http://api.com/3"]
    results = await asyncio.gather(*[fetch_data(u) for u in urls])
    assert len(results) == 3
    assert all("data" in r for r in results)
```

---

## Example 19: Custom Marks — Slow Tests

**Topic:** Custom marks and filtering
**Explanation:** Tag slow/expensive tests so they can be excluded from rapid development feedback loops.

```python
# test_custom_marks.py
# Register mark in pytest.ini:
#   [pytest]
#   markers = slow: marks tests as slow running
import pytest

@pytest.mark.slow
def test_heavy_computation():
    result = sum(range(10_000_000))
    assert result == 49999995000000

def test_fast_computation():
    assert 2 + 2 == 4

# Run all tests except slow:  pytest -m "not slow"
# Run only slow tests:        pytest -m slow
```

---

## Example 20: pytest-cov Coverage Example

**Topic:** Code coverage tracking
**Explanation:** `pytest-cov` measures which lines are executed by tests. Use `--cov-fail-under` to enforce a minimum.

```python
# src/calculator.py
class Calculator:
    def add(self, a, b):      return a + b
    def subtract(self, a, b): return a - b
    def multiply(self, a, b): return a * b
    def divide(self, a, b):
        if b == 0:
            raise ZeroDivisionError("division by zero")
        return a / b

# tests/test_calculator.py
import pytest
from src.calculator import Calculator

@pytest.fixture
def calc():
    return Calculator()

def test_add(calc):        assert calc.add(3, 4) == 7
def test_subtract(calc):   assert calc.subtract(10, 3) == 7
def test_multiply(calc):   assert calc.multiply(3, 4) == 12
def test_divide(calc):     assert calc.divide(10, 2) == 5.0

def test_divide_by_zero(calc):
    with pytest.raises(ZeroDivisionError):
        calc.divide(5, 0)

# Run: pytest --cov=src --cov-report=html --cov-fail-under=90
```

---

## Example 21: tmp_path Built-in Fixture

**Topic:** Temporary file handling
**Explanation:** `tmp_path` provides an isolated temporary directory that pytest cleans up automatically after each test.

```python
# test_file_processing.py
import json

def save_results(filepath, data):
    with open(filepath, "w") as f:
        json.dump(data, f)

def load_results(filepath):
    with open(filepath) as f:
        return json.load(f)

def test_save_and_load_results(tmp_path):
    output_file = tmp_path / "results.json"
    data = {"accuracy": 0.92, "loss": 0.08, "epochs": 10}

    save_results(output_file, data)
    loaded = load_results(output_file)

    assert loaded["accuracy"] == 0.92
    assert loaded["epochs"] == 10
    assert output_file.exists()
```

---

## Example 22: Parametrize + Fixture Combined

**Topic:** Combining parametrize with fixtures
**Explanation:** Parametrize and fixtures compose seamlessly — pytest injects the fixture into each parameterized test case.

```python
# test_combined.py
import pytest

def preprocess_text(text, lowercase=True, strip=True):
    if strip:
        text = text.strip()
    if lowercase:
        text = text.lower()
    return text

@pytest.fixture
def processor():
    return preprocess_text

@pytest.mark.parametrize("raw,expected", [
    ("  Hello World  ", "hello world"),
    ("PYTHON",          "python"),
    ("  Mixed CASE  ",  "mixed case"),
    ("already clean",   "already clean"),
])
def test_text_preprocessing(processor, raw, expected):
    result = processor(raw)
    assert result == expected, f"Input {repr(raw)} -> Got {repr(result)}"
```
