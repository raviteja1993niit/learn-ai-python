# 🏗️ Dataclasses & Protocol Classes — Structured Python for ML

## What is this?
`@dataclass` auto-generates `__init__`, `__repr__`, and `__eq__` from annotated fields, eliminating boilerplate for config and data objects. `Protocol` enables structural subtyping (duck typing with type-checker support), letting you define interfaces without inheritance — ideal for plugin systems and ML pipelines.

## Why Learn It?
- Replace messy `__init__` boilerplate in model configs, metric containers, and dataset descriptors
- Use `Protocol` to define trainer/model interfaces that any class can satisfy without inheriting
- `frozen=True` dataclasses work as dict keys and are safe as hyperparameter configs
- Understand when to choose `dataclass` vs `NamedTuple` vs `TypedDict` vs `Pydantic`

## Key Concepts
```python
from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable, TypeVar, Generic

# --- Basic dataclass with defaults and post-init validation ---
@dataclass
class TrainConfig:
    model_name: str
    lr: float = 3e-4
    epochs: int = 10
    tags: list[str] = field(default_factory=list)   # mutable default

    def __post_init__(self):
        if self.lr <= 0:
            raise ValueError(f"lr must be positive, got {self.lr}")

cfg = TrainConfig(model_name="resnet50", tags=["cv", "baseline"])
print(cfg)  # TrainConfig(model_name='resnet50', lr=0.0003, epochs=10, tags=['cv', 'baseline'])

# --- Frozen (immutable, hashable) dataclass for safe configs ---
@dataclass(frozen=True)
class HyperParams:
    hidden_dim: int = 256
    dropout: float = 0.1
    num_layers: int = 4

hp = HyperParams()
config_cache = {hp: "experiment_42"}   # hashable — works as dict key

# --- slots=True for memory-efficient objects (Python 3.10+) ---
@dataclass(slots=True)
class Sample:
    image: list
    label: int
    weight: float = 1.0

# --- Dataclass inheritance ---
@dataclass
class BaseMetric:
    name: str
    value: float

@dataclass
class EpochMetric(BaseMetric):
    epoch: int
    split: str = "val"

m = EpochMetric(name="accuracy", value=0.93, epoch=5)

# --- Protocol for structural subtyping (duck typing + type-safety) ---
@runtime_checkable
class Trainer(Protocol):
    def fit(self, X, y) -> None: ...
    def predict(self, X) -> list: ...

class SklearnAdapter:
    """Satisfies Trainer without inheriting from it."""
    def fit(self, X, y): self._data = (X, y)
    def predict(self, X): return [0] * len(X)

adapter = SklearnAdapter()
print(isinstance(adapter, Trainer))  # True — runtime_checkable makes this work

# --- Generic + TypeVar for typed containers ---
T = TypeVar("T")

@dataclass
class Batch(Generic[T]):
    inputs: list[T]
    labels: list[int]

    def __len__(self) -> int:
        return len(self.inputs)

text_batch: Batch[str] = Batch(inputs=["hello", "world"], labels=[0, 1])

# --- dataclass vs alternatives ---
# dataclass   → mutable, flexible, supports methods, __post_init__
# NamedTuple  → immutable, tuple-compatible, no methods easily
# TypedDict   → dict at runtime, type hints only, no methods
# Pydantic    → validation + serialization, heavier dependency
```

## Learning Path
1. `pip install pydantic`  — compare with dataclasses for validation
2. Read PEP 557 (dataclasses) and PEP 544 (Protocols)
3. Practice: convert an ML config dict → frozen dataclass
4. Define a `Model` Protocol and make two different classes satisfy it
5. Add `@dataclass(slots=True)` to a high-frequency object and benchmark with `tracemalloc`

## What to Build
- [ ] `TrainConfig` dataclass with `__post_init__` validation for a CNN trainer
- [ ] `MetricLogger` Protocol satisfied by both a CSV logger and a W&B logger
- [ ] Benchmark memory: 1M plain objects vs `slots=True` dataclass vs `NamedTuple`
- [ ] Plugin registry that accepts any class satisfying a `Predictor` Protocol
- [ ] Replace a Pydantic model with a frozen dataclass and measure startup speedup

## Related Folders
- `python-basics\type-hints-main\` — TypeVar, Generic, and Protocol foundations
- `deep-learning\pytorch-basics-main\` — model configs benefit from frozen dataclasses
- `mlops\experiment-tracking-main\` — structured config objects for run metadata
