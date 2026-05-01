# 🏛️ Design Patterns in Python

## What are Design Patterns?
Design patterns are **reusable solutions** to common software design problems.
Knowing them helps write maintainable, scalable production code.

## Three Categories

### 🏗️ Creational Patterns
| Pattern | Purpose | Python Example |
|---------|---------|----------------|
| **Singleton** | One instance only | ML model loader, DB connection |
| **Factory** | Create objects without specifying class | Model factory (sklearn/torch/tf) |
| **Builder** | Step-by-step object construction | ML Pipeline builder |

```python
# Singleton — load model once
class ModelLoader:
    _instance = None
    _model = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._model = load_model("model.pkl")
        return cls._instance

# Factory — create right model type
class ModelFactory:
    @staticmethod
    def create(model_type: str):
        if model_type == "rf": return RandomForestClassifier()
        if model_type == "xgb": return XGBClassifier()
        raise ValueError(f"Unknown model: {model_type}")
```

### 🔧 Structural Patterns
| Pattern | Purpose |
|---------|---------|
| **Decorator** | Add behavior without changing code (Python `@decorator`) |
| **Adapter** | Convert interface to another (wrap sklearn in torch API) |
| **Facade** | Simplify complex subsystem (MLflow facade) |

```python
# Decorator pattern — timing any function
import time, functools

def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time()-start:.2f}s")
        return result
    return wrapper

@timer
def train_model(X, y): ...
```

### 🔄 Behavioral Patterns
| Pattern | Purpose |
|---------|---------|
| **Observer** | Notify subscribers of state changes (model training callbacks) |
| **Strategy** | Swap algorithms at runtime (swap ML models) |
| **Command** | Encapsulate requests as objects (undo/redo) |
| **Template Method** | Define skeleton, subclass fills details (base ML pipeline) |

```python
# Strategy — swap models at runtime
class Predictor:
    def __init__(self, strategy):
        self.strategy = strategy

    def predict(self, X):
        return self.strategy.predict(X)

predictor = Predictor(RandomForestClassifier())
predictor.strategy = XGBClassifier()  # swap at runtime
```

## Learning Path
1. Singleton (model loading)
2. Factory (model creation)
3. Decorator (logging, timing)
4. Observer (training callbacks)
5. Strategy (algorithm selection)
6. Template Method (base ML pipeline class)

## What to Build
- [ ] ML model registry using Factory + Singleton
- [ ] Training pipeline using Template Method
- [ ] Pluggable preprocessing using Strategy pattern

## Related Folders
- `python-basics/Complete-Python-Bootcamp-main/` — OOP foundation
- `python-basics/TypeHints-mypy-main/` — typed patterns
- `machine-learning/Pipeline-MAchine-Learning-main/` — apply patterns