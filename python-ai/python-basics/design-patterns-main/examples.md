# OOP & Design Patterns — Annotated Examples

Each example includes a title, explanation, and full working code with ML-relevant context.

---

## Example 1 — Encapsulation: Protecting Model Weights

**Why**: Prevent accidental mutation of trained weights; expose read-only access.

```python
class TrainedModel:
    def __init__(self, weights):
        self.__weights = weights        # private via name mangling

    @property
    def weights(self):                  # read-only public access
        return tuple(self.__weights)   # return copy — cannot mutate original

    def predict(self, x):
        return sum(w * xi for w, xi in zip(self.__weights, x))

model = TrainedModel([0.3, -0.5, 1.2])
print(model.weights)        # (0.3, -0.5, 1.2)
# model.__weights           # AttributeError — protected
```

---

## Example 2 — Inheritance: Reusable Estimator Base

**Why**: Share `score()` and `get_params()` logic across all ML models.

```python
class BaseEstimator:
    def get_params(self):
        return self.__dict__

    def score(self, X, y):
        preds = self.predict(X)
        return sum(p == t for p, t in zip(preds, y)) / len(y)

class KNNClassifier(BaseEstimator):
    def __init__(self, k=3):
        self.k = k

    def fit(self, X, y):
        self.X_train, self.y_train = X, y
        return self

    def predict(self, X):
        # simplified 1-NN for demo
        results = []
        for x in X:
            dists = [sum((a-b)**2 for a,b in zip(x, xt)) for xt in self.X_train]
            results.append(self.y_train[dists.index(min(dists))])
        return results

clf = KNNClassifier(k=1)
clf.fit([[0,0],[1,1]], [0, 1])
print(clf.score([[0,0],[1,1]], [0, 1]))  # 1.0
```

---

## Example 3 — Polymorphism: Pluggable Loss Functions

**Why**: Train loop works with any loss — swap without changing training code.

```python
class MSELoss:
    def __call__(self, y_true, y_pred):
        return sum((t - p)**2 for t, p in zip(y_true, y_pred)) / len(y_true)

class MAELoss:
    def __call__(self, y_true, y_pred):
        return sum(abs(t - p) for t, p in zip(y_true, y_pred)) / len(y_true)

def train_step(model, X, y, loss_fn):
    preds = model.predict(X)
    return loss_fn(y, preds)            # polymorphic — any callable loss

# swap freely:
print(train_step(clf, [[0,0]], [0], MSELoss()))
print(train_step(clf, [[0,0]], [0], MAELoss()))
```

---

## Example 4 — Abstract Base Class: Metric Contract

**Why**: Enforce a common interface for all evaluation metrics.

```python
from abc import ABC, abstractmethod

class Metric(ABC):
    @abstractmethod
    def compute(self, y_true, y_pred) -> float: ...

    @abstractmethod
    def name(self) -> str: ...

    def __str__(self):
        return self.name()

class Accuracy(Metric):
    def compute(self, y_true, y_pred):
        return sum(t == p for t, p in zip(y_true, y_pred)) / len(y_true)
    def name(self): return "accuracy"

class F1Score(Metric):
    def compute(self, y_true, y_pred):
        tp = sum(t == p == 1 for t, p in zip(y_true, y_pred))
        fp = sum(p == 1 and t == 0 for t, p in zip(y_true, y_pred))
        fn = sum(t == 1 and p == 0 for t, p in zip(y_true, y_pred))
        precision = tp / (tp + fp) if tp + fp else 0
        recall    = tp / (tp + fn) if tp + fn else 0
        return 2 * precision * recall / (precision + recall) if precision + recall else 0
    def name(self): return "f1"

for metric in [Accuracy(), F1Score()]:
    print(f"{metric}: {metric.compute([1,0,1,1],[1,0,0,1]):.2f}")
```

---

## Example 5 — Dataclass: Hyperparameter Container

**Why**: Clean, type-annotated, auto-hashed config objects.

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)
class TrainConfig:
    lr: float = 1e-3
    batch_size: int = 32
    epochs: int = 10
    hidden_dims: tuple = (128, 64)    # tuple — hashable for frozen dataclass

    def scaled_lr(self, factor: float) -> float:
        return self.lr * factor

cfg = TrainConfig(lr=0.01, epochs=50)
print(cfg)                            # TrainConfig(lr=0.01, batch_size=32, ...)
print(hash(cfg))                      # hashable — can be used as dict key
# cfg.lr = 0.1                        # FrozenInstanceError
```

---

## Example 6 — Property: Validated Learning Rate

**Why**: Enforce positive value constraint at assignment time.

```python
class Optimiser:
    def __init__(self, lr=0.01):
        self.lr = lr                   # triggers setter on init

    @property
    def lr(self):
        return self._lr

    @lr.setter
    def lr(self, value):
        if value <= 0:
            raise ValueError(f"lr must be > 0, got {value}")
        self._lr = value

opt = Optimiser(lr=0.001)
opt.lr = 0.1                          # fine
try:
    opt.lr = -1                       # raises ValueError
except ValueError as e:
    print(e)
```

---

## Example 7 — Class Method: Alternative Constructor

**Why**: Create objects from different data sources (dict, JSON, file path).

```python
import json
from dataclasses import dataclass

@dataclass
class ModelSpec:
    name: str
    input_dim: int
    output_dim: int

    @classmethod
    def from_dict(cls, d: dict):
        return cls(**d)

    @classmethod
    def from_json(cls, path: str):
        with open(path) as f:
            return cls.from_dict(json.load(f))

spec = ModelSpec.from_dict({"name": "MLP", "input_dim": 784, "output_dim": 10})
print(spec)
```

---

## Example 8 — Dunder Methods: Custom Dataset

**Why**: Make datasets work natively with `len()`, indexing, and `for` loops
so they integrate with any training harness.

```python
class TabularDataset:
    def __init__(self, X, y):
        assert len(X) == len(y), "X and y must have equal length"
        self._X = X
        self._y = y

    def __len__(self):
        return len(self._X)

    def __getitem__(self, idx):
        return self._X[idx], self._y[idx]

    def __iter__(self):
        for i in range(len(self)):
            yield self[i]

    def __repr__(self):
        return f"TabularDataset(n={len(self)}, features={len(self._X[0])})"

ds = TabularDataset([[1,2],[3,4],[5,6]], [0,1,0])
print(len(ds))                         # 3
print(ds[1])                           # ([3, 4], 1)
for x, y in ds:
    print(x, y)
```

---

## Example 9 — Singleton: Global Configuration

**Why**: Ensure one consistent config object throughout an experiment run.

```python
class ExperimentConfig:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.seed = 42
            cls._instance.device = "cpu"
        return cls._instance

cfg1 = ExperimentConfig()
cfg2 = ExperimentConfig()
cfg1.seed = 99
print(cfg2.seed)                       # 99 — same object
print(cfg1 is cfg2)                    # True
```

---

## Example 10 — Factory: Model Registry

**Why**: Decouple model selection from instantiation; load model by name from config.

```python
class ModelFactory:
    _registry = {}

    @classmethod
    def register(cls, name):
        def decorator(model_cls):
            cls._registry[name] = model_cls
            return model_cls
        return decorator

    @classmethod
    def create(cls, name, **kwargs):
        if name not in cls._registry:
            raise ValueError(f"Unknown model: {name}. Available: {list(cls._registry)}")
        return cls._registry[name](**kwargs)

@ModelFactory.register("linear")
class LinearModel:
    def __init__(self, input_dim=10): self.input_dim = input_dim
    def __repr__(self): return f"LinearModel(input_dim={self.input_dim})"

@ModelFactory.register("mlp")
class MLPModel:
    def __init__(self, hidden=64): self.hidden = hidden
    def __repr__(self): return f"MLPModel(hidden={self.hidden})"

model = ModelFactory.create("mlp", hidden=128)
print(model)                           # MLPModel(hidden=128)
```

---

## Example 11 — Builder: ML Pipeline

**Why**: Construct multi-step preprocessing + model pipelines fluently.

```python
class Pipeline:
    def __init__(self, steps):
        self.steps = steps
    def __repr__(self):
        return "Pipeline(" + " -> ".join(s.__class__.__name__ for s in self.steps) + ")"

class PipelineBuilder:
    def __init__(self):
        self._steps = []

    def add_step(self, step):
        self._steps.append(step)
        return self                    # fluent interface — enables chaining

    def build(self):
        if not self._steps:
            raise ValueError("Pipeline must have at least one step")
        return Pipeline(self._steps)

class Scaler:  pass
class PCAStep: pass
class SVMModel: pass

pipeline = (PipelineBuilder()
            .add_step(Scaler())
            .add_step(PCAStep())
            .add_step(SVMModel())
            .build())
print(pipeline)                        # Pipeline(Scaler -> PCAStep -> SVMModel)
```

---

## Example 12 — Prototype: Model Cloning for Ensemble

**Why**: Create independent copies of a trained model for ensemble members.

```python
import copy

class GradientBoostTree:
    def __init__(self, depth=3):
        self.depth = depth
        self.nodes = []               # simulated tree structure

    def fit(self, X, y):
        self.nodes = list(range(2**self.depth - 1))  # placeholder
        return self

    def clone(self):
        return copy.deepcopy(self)    # deep copy — fully independent

base = GradientBoostTree(depth=4).fit([[1],[2],[3]], [0,1,0])
ensemble = [base.clone() for _ in range(10)]
print(len(ensemble))                   # 10 independent trees
print(ensemble[0] is base)             # False
```

---

## Example 13 — Decorator Pattern: Timing & Logging Wrapper

**Why**: Add cross-cutting concerns (timing, logging) without modifying model code.

```python
import time
import functools

def log_and_time(fn):
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        print(f"[START] {fn.__name__}")
        t0 = time.perf_counter()
        result = fn(*args, **kwargs)
        elapsed = time.perf_counter() - t0
        print(f"[END]   {fn.__name__} — {elapsed:.4f}s")
        return result
    return wrapper

class Trainer:
    @log_and_time
    def fit(self, epochs=5):
        for e in range(epochs):
            pass                       # simulate training
        return self

Trainer().fit(epochs=3)
```

---

## Example 14 — Adapter: Sklearn-Compatible Wrapper for Custom Models

**Why**: Plug a custom model into sklearn's cross_val_score / GridSearchCV.

```python
from abc import ABC, abstractmethod

class CustomNeuralNet:
    """Imagine this has a non-sklearn API."""
    def train(self, X, y, iters=100): self.coef_ = [0.1]*len(X[0]); return self
    def infer(self, X): return [round(sum(w*xi for w,xi in zip(self.coef_, x))) for x in X]

class SklearnAdapter:
    """Adapts CustomNeuralNet to sklearn estimator interface."""
    def __init__(self, iters=100):
        self.iters = iters
        self._model = CustomNeuralNet()

    def fit(self, X, y):
        self._model.train(X, y, iters=self.iters)
        return self

    def predict(self, X):
        return self._model.infer(X)

    def get_params(self, deep=True):
        return {"iters": self.iters}

adapted = SklearnAdapter(iters=50).fit([[1,2],[3,4]], [0,1])
print(adapted.predict([[1,2]]))
```

---

## Example 15 — Facade: High-Level Trainer

**Why**: Hide the complexity of data loading, training loop, evaluation behind one class.

```python
class DataLoader:
    def load(self, path): return ([[1,2],[3,4]], [0,1])  # stub

class ModelTrainer:
    def train(self, model, X, y, epochs): return model   # stub

class Evaluator:
    def evaluate(self, model, X, y): return {"accuracy": 1.0}

class TrainerFacade:
    """One-stop interface: load, train, evaluate."""
    def __init__(self):
        self._loader  = DataLoader()
        self._trainer = ModelTrainer()
        self._eval    = Evaluator()

    def run(self, model, data_path, epochs=10):
        X, y = self._loader.load(data_path)
        model = self._trainer.train(model, X, y, epochs)
        return self._eval.evaluate(model, X, y)

facade = TrainerFacade()
results = facade.run(object(), "data/train.csv")
print(results)                         # {"accuracy": 1.0}
```

---

## Example 16 — Proxy: Lazy Dataset Loading

**Why**: Avoid loading a huge dataset into memory until first access.

```python
class HeavyDataset:
    def __init__(self, path):
        print(f"Loading {path} into memory...")
        self._data = list(range(1_000_000))  # simulate large data

    def __getitem__(self, idx): return self._data[idx]
    def __len__(self): return len(self._data)

class LazyDatasetProxy:
    def __init__(self, path):
        self._path    = path
        self._dataset = None            # not loaded yet

    def _ensure_loaded(self):
        if self._dataset is None:
            self._dataset = HeavyDataset(self._path)

    def __getitem__(self, idx):
        self._ensure_loaded()
        return self._dataset[idx]

    def __len__(self):
        self._ensure_loaded()
        return len(self._dataset)

proxy = LazyDatasetProxy("data/huge.csv")  # no loading yet
print("Proxy created — data not loaded")
print(proxy[0])                            # loads on first access
```

---

## Example 17 — Observer: Training Callbacks

**Why**: Decouple metric logging, early stopping, LR scheduling from the training loop.

```python
class TrainingEvent:
    def __init__(self, epoch, loss, val_loss):
        self.epoch, self.loss, self.val_loss = epoch, loss, val_loss

class Callback:
    def on_epoch_end(self, event: TrainingEvent): pass

class LossLogger(Callback):
    def on_epoch_end(self, event):
        print(f"Epoch {event.epoch}: loss={event.loss:.4f}, val={event.val_loss:.4f}")

class EarlyStopping(Callback):
    def __init__(self, patience=3):
        self.patience, self.best, self.wait = patience, float("inf"), 0
    def on_epoch_end(self, event):
        if event.val_loss < self.best:
            self.best, self.wait = event.val_loss, 0
        else:
            self.wait += 1
            if self.wait >= self.patience:
                print("Early stopping triggered")

class Trainer:
    def __init__(self):
        self._callbacks = []

    def add_callback(self, cb: Callback):
        self._callbacks.append(cb)

    def _notify(self, event):
        for cb in self._callbacks:
            cb.on_epoch_end(event)

    def fit(self, epochs=5):
        losses = [0.9, 0.7, 0.65, 0.66, 0.67]
        for e in range(epochs):
            self._notify(TrainingEvent(e, losses[e], losses[e] + 0.05))

trainer = Trainer()
trainer.add_callback(LossLogger())
trainer.add_callback(EarlyStopping(patience=2))
trainer.fit()
```

---

## Example 18 — Strategy: Pluggable Optimiser

**Why**: Switch optimisation algorithm without changing training code.

```python
class SGD:
    def __init__(self, lr=0.01): self.lr = lr
    def update(self, params, grads):
        return [p - self.lr * g for p, g in zip(params, grads)]

class AdaGrad:
    def __init__(self, lr=0.01):
        self.lr, self.cache = lr, None
    def update(self, params, grads):
        if self.cache is None: self.cache = [0.0] * len(params)
        self.cache = [c + g**2 for c, g in zip(self.cache, grads)]
        return [p - self.lr * g / (c**0.5 + 1e-8)
                for p, g, c in zip(params, grads, self.cache)]

class SimpleNet:
    def __init__(self, optimiser):
        self.params = [1.0, -0.5]
        self.opt    = optimiser        # strategy injected

    def step(self, grads):
        self.params = self.opt.update(self.params, grads)

net = SimpleNet(SGD(lr=0.1))
net.step([0.2, -0.1])
print(net.params)

net2 = SimpleNet(AdaGrad(lr=0.1))
net2.step([0.2, -0.1])
print(net2.params)
```

---

## Example 19 — Template Method: Base Training Loop

**Why**: Fix the algorithm skeleton; let subclasses override specific steps.

```python
from abc import ABC, abstractmethod

class BaseTrainer(ABC):
    def train(self, epochs):           # template method — fixed skeleton
        self.setup()
        for e in range(epochs):
            loss = self.train_epoch(e)
            val  = self.validate(e)
            self.log(e, loss, val)
        self.teardown()

    def setup(self): print("Setting up...")
    def teardown(self): print("Done.")
    def log(self, e, loss, val): print(f"[{e}] loss={loss:.3f} val={val:.3f}")

    @abstractmethod
    def train_epoch(self, epoch) -> float: ...

    @abstractmethod
    def validate(self, epoch) -> float: ...

class ClassifierTrainer(BaseTrainer):
    def train_epoch(self, epoch): return 1.0 / (epoch + 1)
    def validate(self, epoch):    return 1.2 / (epoch + 1)

ClassifierTrainer().train(epochs=3)
```

---

## Example 20 — Command: Experiment Queue

**Why**: Encapsulate hyperparameter trials as objects; queue, execute, and undo them.

```python
from dataclasses import dataclass
from typing import Callable

@dataclass
class Experiment:
    name: str
    fn: Callable
    params: dict

    def run(self):
        print(f"Running {self.name} with {self.params}")
        return self.fn(**self.params)

class ExperimentQueue:
    def __init__(self):
        self._queue   = []
        self._history = []

    def add(self, experiment: Experiment):
        self._queue.append(experiment)

    def run_all(self):
        while self._queue:
            exp = self._queue.pop(0)
            result = exp.run()
            self._history.append((exp, result))
        return self._history

def dummy_train(lr, epochs): return {"lr": lr, "epochs": epochs, "val_acc": 0.85}

queue = ExperimentQueue()
queue.add(Experiment("exp_1", dummy_train, {"lr": 0.01, "epochs": 10}))
queue.add(Experiment("exp_2", dummy_train, {"lr": 0.001, "epochs": 20}))
results = queue.run_all()
for exp, res in results:
    print(f"  {exp.name}: {res}")
```

---

## Example 21 — Iterator: Batch Generator

**Why**: Stream mini-batches without loading all data at once.

```python
class BatchIterator:
    def __init__(self, dataset, batch_size=2, shuffle=False):
        import random
        self._dataset    = dataset
        self._batch_size = batch_size
        self._indices    = list(range(len(dataset)))
        if shuffle:
            random.shuffle(self._indices)

    def __iter__(self):
        for start in range(0, len(self._indices), self._batch_size):
            batch_idx = self._indices[start:start + self._batch_size]
            yield [self._dataset[i] for i in batch_idx]

    def __len__(self):
        import math
        return math.ceil(len(self._dataset) / self._batch_size)

data = list(range(7))                  # dataset of 7 samples
loader = BatchIterator(data, batch_size=3)
for batch in loader:
    print(batch)
# [0, 1, 2]
# [3, 4, 5]
# [6]
```