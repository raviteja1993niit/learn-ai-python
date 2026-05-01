# 🧪 pytest — Python Unit Testing

## What is pytest?
pytest is Python'"'"'s most popular **testing framework**. It makes writing and running
tests simple, readable, and powerful.

## Why Testing?
- Catch bugs before they reach production
- Required in all professional Python codebases
- CI/CD pipelines run tests automatically on every push
- ML: validate data pipelines, model outputs, API endpoints

## Key Concepts
```python
# test_math.py
def add(a, b): return a + b

def test_add():
    assert add(2, 3) == 5

def test_add_negative():
    assert add(-1, 1) == 0

# Parameterized tests
import pytest
@pytest.mark.parametrize("a,b,expected", [(1,2,3), (0,0,0), (-1,1,0)])
def test_add_param(a, b, expected):
    assert add(a, b) == expected

# Fixtures — reusable setup
@pytest.fixture
def sample_df():
    return pd.DataFrame({"a": [1,2,3], "b": [4,5,6]})

def test_shape(sample_df):
    assert sample_df.shape == (3, 2)
```

## ML Testing Patterns
```python
def test_model_output_shape():
    model = load_model()
    pred = model.predict(X_test)
    assert pred.shape == (len(X_test),)

def test_model_accuracy():
    assert accuracy_score(y_test, model.predict(X_test)) > 0.85

def test_preprocessing_no_nulls():
    processed = preprocess(raw_df)
    assert processed.isnull().sum().sum() == 0
```

## Run Tests
```bash
pytest                    # run all tests
pytest test_model.py      # specific file
pytest -v                 # verbose output
pytest --cov=src          # coverage report
pytest -k "test_add"      # run matching tests
```

## Learning Path
1. `pip install pytest pytest-cov`
2. Write tests for your utility functions
3. Fixtures for shared setup
4. Mock external APIs with `unittest.mock`
5. Integrate with GitHub Actions CI/CD

## What to Build
- [ ] Test suite for your Car Price ML pipeline
- [ ] Data validation tests (no nulls, correct dtypes)
- [ ] Flask API endpoint tests

## Related Folders
- `python-basics/Complete-Python-Bootcamp-main/` — Python foundation
- `cloud-deployment/mlops-main/` — MLOps includes testing