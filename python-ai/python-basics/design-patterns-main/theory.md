# OOP & Design Patterns — Theory Reference

## 1. The Four Pillars of OOP

### Encapsulation
Bundling data (attributes) and behaviour (methods) into a single unit (class), and restricting
direct access to internal state.

```python
class NeuralNetwork:
    def __init__(self, layers):
        self.__layers = layers          # private — name-mangled to _NeuralNetwork__layers
        self._weights = {}              # protected — convention only

    def get_layers(self):               # controlled read access
        return list(self.__layers)
```

Benefits: prevents invalid state, reduces coupling, eases refactoring.

### Inheritance
A class (child) derives attributes and methods from another class (parent), promoting reuse.

```python
class BaseModel:
    def fit(self, X, y): ...
    def predict(self, X): ...

class LinearRegression(BaseModel):     # single inheritance
    def fit(self, X, y):               # override
        ...
```

### Polymorphism
Different classes respond to the same interface in their own way.

```python
class SGDOptimiser:
    def step(self, grads): ...

class AdamOptimiser:
    def step(self, grads): ...         # same signature, different logic

def train_epoch(optimiser, grads):
    optimiser.step(grads)              # works for any optimiser
```

Duck typing in Python: "if it has a .step(), it is an optimiser."

### Abstraction
Hiding implementation details and exposing only essential interfaces.

```python
from abc import ABC, abstractmethod

class Transformer(ABC):
    @abstractmethod
    def fit_transform(self, X): ...    # contract — subclasses must implement
```

---

## 2. Classes In Depth

### `__init__` and `self`
`__init__` is the initialiser (not constructor). `self` is the implicit first parameter
referring to the instance being created.

```python
class Dataset:
    default_seed = 42                  # class variable — shared across all instances

    def __init__(self, path, split=0.8):
        self.path = path               # instance variable — unique per instance
        self.split = split
        self._data = None
```

### Class vs Instance Variables
- **Class variables**: defined at class body level; shared by all instances.
- **Instance variables**: defined inside methods via `self`; unique per object.

Mutation trap:
```python
class Broken:
    cache = []                         # class variable — shared!
    def add(self, item):
        self.cache.append(item)        # mutates the shared list
```

### `__str__` vs `__repr__`
- `__str__`: human-readable output (`str(obj)`, `print(obj)`)
- `__repr__`: unambiguous, ideally reproducible (`repr(obj)`, REPL display)

```python
class Tensor:
    def __str__(self):
        return f"Tensor(shape={self.shape})"
    def __repr__(self):
        return f"Tensor(data={self.data!r}, dtype={self.dtype!r})"
```

### `__eq__`
Defines equality semantics:
```python
def __eq__(self, other):
    if not isinstance(other, type(self)):
        return NotImplemented
    return self.data == other.data
```

---

## 3. Inheritance Deep Dive

### Single Inheritance
One parent:
```python
class Estimator(BaseEstimator): ...
```

### Multiple Inheritance
Multiple parents — use with care:
```python
class TransformerMixin: ...
class RegressorMixin: ...

class Ridge(LinearRegression, RegressorMixin, TransformerMixin): ...
```

### `super()`
Delegates method call to the next class in the MRO:
```python
class ConvNet(NeuralNetwork):
    def __init__(self, layers, kernel_size):
        super().__init__(layers)       # calls NeuralNetwork.__init__
        self.kernel_size = kernel_size
```

### Method Resolution Order (MRO)
Python uses C3 linearisation. Inspect with `ClassName.__mro__` or `help(ClassName)`.

```python
class A: pass
class B(A): pass
class C(A): pass
class D(B, C): pass

print(D.__mro__)  # D -> B -> C -> A -> object
```

Rule: left-to-right depth-first, but each class appears only after all its subclasses.

---

## 4. Abstract Base Classes (ABC)

```python
from abc import ABC, abstractmethod

class Metric(ABC):
    @abstractmethod
    def compute(self, y_true, y_pred) -> float: ...

    @abstractmethod
    def name(self) -> str: ...

class Accuracy(Metric):
    def compute(self, y_true, y_pred):
        return (y_true == y_pred).mean()
    def name(self):
        return "accuracy"
```

`abstractmethod` prevents direct instantiation of the base class.
Also available: `@abstractclassmethod`, `@abstractstaticmethod`, `@abstractproperty`.

---

## 5. Dataclasses

```python
from dataclasses import dataclass, field

@dataclass
class HyperParams:
    lr: float = 0.001
    epochs: int = 100
    layers: list = field(default_factory=list)  # mutable default via factory
    name: str = field(default="model", repr=False)

@dataclass(frozen=True)         # immutable — hashable, safe as dict key
class ModelConfig:
    input_dim: int
    output_dim: int
```

`@dataclass` auto-generates `__init__`, `__repr__`, `__eq__`.
`frozen=True` also generates `__hash__`.

---

## 6. Properties

```python
class LearningRate:
    def __init__(self, value):
        self._value = value

    @property
    def value(self):               # getter
        return self._value

    @value.setter
    def value(self, v):            # setter with validation
        if v <= 0:
            raise ValueError("Learning rate must be positive")
        self._value = v

    @value.deleter
    def value(self):               # deleter
        del self._value
```

---

## 7. Static vs Class Methods

```python
class DataLoader:
    _registry = {}

    @staticmethod
    def normalise(arr):            # no access to class or instance
        return (arr - arr.mean()) / arr.std()

    @classmethod
    def register(cls, name, loader_cls):   # receives class as first arg
        cls._registry[name] = loader_cls

    @classmethod
    def from_config(cls, config: dict):    # alternative constructor
        return cls(**config)
```

---

## 8. Magic / Dunder Methods

| Method | Triggered by | ML use case |
|---|---|---|
| `__len__` | `len(obj)` | dataset size |
| `__getitem__` | `obj[i]` | batch indexing |
| `__iter__` | `for x in obj` | epoch iteration |
| `__contains__` | `x in obj` | vocabulary lookup |
| `__add__` | `a + b` | tensor addition |
| `__mul__` | `a * b` | scalar multiply |
| `__call__` | `obj()` | callable layers |
| `__enter__`/`__exit__` | `with obj` | resource management |

```python
class VocabDataset:
    def __len__(self):   return len(self._samples)
    def __getitem__(self, idx): return self._samples[idx]
    def __iter__(self):  return iter(self._samples)
    def __contains__(self, token): return token in self._vocab
```

---

## 9. Creational Patterns

### Singleton
Ensures a single instance exists — useful for config, loggers, GPU manager.

```python
class Config:
    _instance = None
    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
```

### Factory Method
Delegates object creation to subclasses — decouples client from concrete types.

```python
class ModelFactory:
    @staticmethod
    def create(model_type: str):
        registry = {"rf": RandomForest, "xgb": XGBoost, "nn": NeuralNet}
        return registry[model_type]()
```

### Builder
Constructs complex objects step by step — pipeline construction.

```python
class PipelineBuilder:
    def __init__(self): self._steps = []
    def add_scaler(self): self._steps.append(StandardScaler()); return self
    def add_pca(self, n): self._steps.append(PCA(n)); return self
    def build(self): return Pipeline(self._steps)
```

### Prototype
Clones existing objects — useful for model checkpointing, hyperparameter search.

```python
import copy
class ModelPrototype:
    def clone(self): return copy.deepcopy(self)
```

---

## 10. Structural Patterns

### Decorator (Python @decorator)
Wraps a function to extend behaviour without modifying it.

```python
def timer(fn):
    def wrapper(*args, **kwargs):
        import time; t = time.time()
        result = fn(*args, **kwargs)
        print(f"{fn.__name__} took {time.time()-t:.2f}s")
        return result
    return wrapper
```

### Adapter
Converts one interface to another — wrapping sklearn estimators for PyTorch pipelines.

### Facade
Provides a simplified interface to a complex subsystem — ML training loop.

### Proxy
Controls access to another object — lazy loading of large datasets.

---

## 11. Behavioral Patterns

### Observer
Defines one-to-many dependency; when subject changes, observers are notified.
ML use: training callbacks (TensorBoard, early stopping, LR scheduler).

### Strategy
Encapsulates interchangeable algorithms — pluggable loss functions, optimisers.

### Template Method
Defines the skeleton of an algorithm in a base class; subclasses fill in steps.
ML use: BaseEstimator.fit() — subclasses override _fit_core().

### Command
Encapsulates a request as an object — hyperparameter tuning trial queues.

### Iterator
Provides sequential access without exposing internal structure.
ML use: DataLoader, generator-based epoch iteration.

---

## 12. Real ML Use Cases Summary

| Pattern | ML Application |
|---|---|
| Singleton | Global config, GPU allocator |
| Factory | Model registry, loss function factory |
| Builder | sklearn Pipeline, data preprocessing chain |
| Prototype | Model cloning for ensemble, checkpoint restore |
| Decorator | Timing, logging, gradient clipping wrappers |
| Adapter | Wrapping legacy models to new API |
| Facade | High-level Trainer class |
| Proxy | Lazy dataset loading, remote model serving |
| Observer | Training callbacks, metric logging |
| Strategy | Pluggable optimisers and schedulers |
| Template Method | Base training loop with overridable steps |
| Command | Experiment queue, undo/redo in AutoML |
| Iterator | DataLoader, streaming dataset |