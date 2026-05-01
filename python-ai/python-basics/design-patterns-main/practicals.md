# OOP & Design Patterns — Practical Exercises

Ten exercises building from beginner to advanced. Each includes an objective, requirements,
hints, and expected outcome. Work through them in order — later exercises build on earlier ones.

---

## Exercise 1 — Shape Hierarchy (OOP Fundamentals)

**Objective**: Build a class hierarchy of geometric shapes using inheritance and polymorphism.

**Requirements**:
1. Create an abstract base class `Shape` with abstract methods `area()` and `perimeter()`.
2. Implement `Circle`, `Rectangle`, and `Triangle` subclasses.
3. Add `__str__` and `__repr__` to each class.
4. Add `__eq__` to compare shapes by area.
5. Collect shapes in a list and sort them by area using the built-in `sorted()`.

**Hints**:
- Import `ABC` and `abstractmethod` from `abc`.
- `sorted()` accepts a `key=` lambda — use `.area()`.
- For `__eq__`, compare `round(self.area(), 6) == round(other.area(), 6)` to handle floats.
- Use `math.pi` for circle area.

**Expected Outcome**:
```
Circle(r=3)    area=28.27
Rectangle(4x5) area=20.00
Triangle(3,4,5) area=6.00
Sorted by area: [Triangle, Rectangle, Circle]
```

---

## Exercise 2 — Frozen Dataclass Config (Dataclasses & Properties)

**Objective**: Model a neural network configuration as an immutable, validated dataclass.

**Requirements**:
1. Create a `frozen=True` dataclass `NetworkConfig` with fields:
   `input_dim: int`, `hidden_dims: tuple`, `output_dim: int`, `dropout: float = 0.5`.
2. Add a `__post_init__` method that validates:
   - `input_dim` and `output_dim` must be positive integers.
   - `dropout` must be in [0, 1].
   - `hidden_dims` must be a non-empty tuple of positive ints.
3. Add a property `total_params` (via `@property` on a non-frozen wrapper class) that
   computes approximate parameter count: `input*h1 + h1*h2 + ... + hn*output`.
4. Make the config hashable and usable as a dict key.

**Hints**:
- `__post_init__` works even on frozen dataclasses — it runs after `__init__`.
- Raise `ValueError` with a descriptive message for each invalid field.
- For the property, create a separate `ConfigAnalyser` class that wraps a `NetworkConfig`.

**Expected Outcome**:
```python
cfg = NetworkConfig(784, (256, 128), 10, dropout=0.3)
analyser = ConfigAnalyser(cfg)
print(analyser.total_params)   # 784*256 + 256*128 + 128*10 = 234,368
configs = {cfg: "experiment_1"}
```

---

## Exercise 3 — Singleton Logger (Singleton Pattern)

**Objective**: Build a thread-safe experiment logger that guarantees a single instance.

**Requirements**:
1. Implement `ExperimentLogger` using the Singleton pattern (`__new__`).
2. The logger must support:
   - `log(message, level="INFO")` — prints `[LEVEL] message` with timestamp.
   - `get_history()` — returns list of all logged messages.
   - `clear()` — resets history.
3. Verify that two separately constructed loggers are the same object (`is` check).
4. Add a context manager (`__enter__` / `__exit__`) that logs start and end of a block.

**Hints**:
- Store history as an instance-level list initialised once in `__new__`.
- Use `datetime.now().strftime("%H:%M:%S")` for timestamps.
- `__exit__` receives `exc_type, exc_val, exc_tb` — return `False` to propagate exceptions.

**Expected Outcome**:
```python
logger1 = ExperimentLogger()
logger2 = ExperimentLogger()
assert logger1 is logger2          # True
with logger1:
    logger1.log("Training started")
# [INFO] 12:34:56 — Context entered
# [INFO] 12:34:56 — Training started
# [INFO] 12:34:56 — Context exited
```

---

## Exercise 4 — Model Registry (Factory + Decorator)

**Objective**: Build a self-registering model factory using class decorators.

**Requirements**:
1. Create a `ModelRegistry` class with a `@register(name)` class decorator.
2. Registered models must be instantiable via `ModelRegistry.create(name, **kwargs)`.
3. Implement at least three registered models: `LinearModel`, `RandomForest`, `MLP`.
4. Each model must implement `fit(X, y)` and `predict(X)` (can be stubs).
5. `ModelRegistry.list_models()` returns all registered names sorted alphabetically.
6. Attempting to create an unregistered model raises `KeyError` with a helpful message.

**Hints**:
- `@register(name)` is a decorator factory — it returns a decorator that returns the class.
- Store registry in a class-level dict on `ModelRegistry`.
- Use `functools.wraps` is not needed here since we return the class unchanged.

**Expected Outcome**:
```python
print(ModelRegistry.list_models())  # ['LinearModel', 'MLP', 'RandomForest']
model = ModelRegistry.create("MLP", hidden=128)
model.fit([[1,2],[3,4]], [0,1])
print(model.predict([[1,2]]))
```

---

## Exercise 5 — Pipeline Builder (Builder Pattern)

**Objective**: Create a fluent pipeline builder for ML preprocessing.

**Requirements**:
1. Implement `PipelineBuilder` with the following chainable methods:
   - `add_scaler(method="standard")` — adds a `Scaler` step.
   - `add_encoder(strategy="onehot")` — adds an `Encoder` step.
   - `add_feature_selector(k=10)` — adds a `FeatureSelector` step.
   - `add_model(model)` — sets the final estimator.
2. `build()` returns a `Pipeline` object that stores the steps.
3. `Pipeline.run(X, y)` calls `transform(X)` on each step (except the last) then
   `fit(X_transformed, y)` on the model.
4. Calling `build()` without a model raises `ValueError`.
5. Calling `add_model()` twice raises `ValueError`.

**Hints**:
- Each step class can be a stub with `transform(X) -> X` and `__repr__`.
- Return `self` from each `add_*` method.
- Store model separately from transform steps.

**Expected Outcome**:
```python
pipeline = (PipelineBuilder()
            .add_scaler("minmax")
            .add_encoder("label")
            .add_model(LinearModel())
            .build())
print(pipeline)
# Pipeline: Scaler(minmax) -> Encoder(label) -> LinearModel
```

---

## Exercise 6 — Observable Training Loop (Observer Pattern)

**Objective**: Build a training loop with a callback system for monitoring and control.

**Requirements**:
1. Define a `CallbackBase` abstract class with hooks:
   `on_train_start`, `on_epoch_end(epoch, logs)`, `on_train_end(logs)`.
2. Implement three callbacks:
   - `MetricsLogger` — prints epoch metrics.
   - `ModelCheckpoint(filepath)` — saves best model when val_loss improves.
   - `EarlyStopping(patience, monitor="val_loss")` — stops training when metric stagnates.
3. `EarlyStopping` must raise a `StopIteration`-like signal or set a flag that stops training.
4. `Trainer` accepts a list of callbacks and calls them at appropriate points.
5. The training loop should run for up to N epochs but stop early if signalled.

**Hints**:
- Use a `should_stop` flag on `Trainer` that `EarlyStopping` sets to `True`.
- `on_epoch_end` receives a dict: `{"loss": float, "val_loss": float}`.
- For `ModelCheckpoint`, simulate saving with `print(f"Saved model to {filepath}")`.

**Expected Outcome**:
```
Epoch 1: loss=0.900, val_loss=0.950
Epoch 2: loss=0.700, val_loss=0.750
Saved model to best_model.pkl
Epoch 3: loss=0.680, val_loss=0.760
Epoch 4: loss=0.679, val_loss=0.770
Early stopping at epoch 4 (patience=2)
Training complete. Best val_loss: 0.750
```

---

## Exercise 7 — Strategy + Template Method: Flexible Trainer

**Objective**: Combine Strategy and Template Method to build a configurable training system.

**Requirements**:
1. Create a `LossFunctionStrategy` ABC with `compute(y_true, y_pred) -> float`.
2. Implement `MSELoss`, `MAELoss`, `HuberLoss(delta=1.0)`.
3. Create a `BaseTrainer` ABC with the template method `train(X, y, epochs)` that calls:
   `_preprocess(X, y)`, `_train_epoch(X, y)` (must call the injected loss), `_evaluate(X, y)`.
4. Implement `RegressionTrainer(loss_fn: LossFunctionStrategy)` that overrides the abstract steps.
5. Add a `@staticmethod` `compare_losses(trainers, X, y)` on `BaseTrainer` that returns a dict
   mapping loss name to final loss value.

**Hints**:
- Inject the loss strategy via `__init__`.
- `_train_epoch` can use toy gradient updates to make loss decrease each epoch.
- Use `@abstractmethod` for all three step methods.

**Expected Outcome**:
```python
results = BaseTrainer.compare_losses(
    [RegressionTrainer(MSELoss()), RegressionTrainer(MAELoss())],
    X_train, y_train
)
print(results)  # {"mse": 0.023, "mae": 0.11}
```

---

## Exercise 8 — Proxy + Prototype: Dataset Manager

**Objective**: Build a lazy-loading dataset manager that supports efficient cloning.

**Requirements**:
1. `RealDataset` simulates slow loading (use `time.sleep(0.1)`) and stores `n` samples.
2. `DatasetProxy` wraps `RealDataset` with lazy loading — only loads on first data access.
3. `DatasetProxy` implements `__len__`, `__getitem__`, `__iter__`, and `clone()`.
4. `clone()` uses `copy.deepcopy` on the underlying dataset (loads it first if needed).
5. Add a `@property loaded` to `DatasetProxy` that returns whether the dataset is loaded.
6. Demonstrate: create proxy, confirm not loaded, access item, confirm loaded, clone, time it.

**Hints**:
- Guard `_real_dataset` as `None` until first access.
- `clone()` returns a new `DatasetProxy` whose internal dataset is a deep copy.
- Use `time.perf_counter()` to measure load time.

**Expected Outcome**:
```
Proxy created. Loaded: False
Accessing item 0...
[Loading dataset — 100ms]
Item: sample_0. Loaded: True
Cloned. Clone loaded: True (shares deep copy)
```

---

## Exercise 9 — Command Pattern: AutoML Experiment Queue

**Objective**: Build an experiment queue with undo, retry, and result tracking.

**Requirements**:
1. Define a `Command` ABC with `execute() -> dict` and `undo()`.
2. Implement `TrainCommand(model, X, y, params)` that:
   - `execute()`: trains model, returns `{"status": "ok", "score": float}`.
   - `undo()`: resets model to pre-training state.
3. `ExperimentQueue` supports:
   - `enqueue(command)`, `run_next()`, `run_all()`.
   - `undo_last()` — undoes the most recently executed command.
   - `get_results()` — returns all results with command names.
4. `run_all()` catches exceptions per command, marks failed runs as `{"status": "error"}`.
5. After `run_all()`, print a summary table: command name, status, score (or N/A).

**Hints**:
- Store executed commands in a stack for `undo_last()`.
- For `undo()`, save model state before training (deepcopy of params/weights).
- Wrap `execute()` in try/except inside `run_all()`.

**Expected Outcome**:
```
+------------------+--------+-------+
| Command          | Status | Score |
+------------------+--------+-------+
| TrainCommand_lr1 | ok     | 0.912 |
| TrainCommand_lr2 | ok     | 0.887 |
+------------------+--------+-------+
```

---

## Exercise 10 — Full ML System (All Patterns Combined)

**Objective**: Build a mini ML framework integrating all patterns from Exercises 1–9.

**Requirements**:
1. **Config** (Singleton + frozen Dataclass): `ExperimentConfig` holds global settings.
2. **Model Registry** (Factory): register at least 2 models.
3. **Pipeline** (Builder): preprocessing + registered model.
4. **Dataset** (Proxy + Dunder methods): lazy-loading `TabularDataset`.
5. **Training** (Template Method + Strategy): configurable loss, fixed loop skeleton.
6. **Callbacks** (Observer): at least `MetricsLogger` and `EarlyStopping`.
7. **Experiments** (Command + Queue): queue 3 experiments with different hyperparams.
8. **Facade**: expose everything through a single `AutoMLFacade.run(config_dict)` method.
9. The facade must: load data, build pipeline, run experiment queue, return best result.
10. Add at least 5 assertions / sanity checks throughout (not just at the end).

**Hints**:
- Start with data structures and work outward to the facade.
- The dataset and config can be stubs — focus on the pattern interactions.
- Use `@dataclass(frozen=True)` for config; `__new__` singleton for `ExperimentConfig`.
- The `AutoMLFacade` is the top-level entry point — all complexity hidden inside.

**Expected Outcome**:
```python
result = AutoMLFacade.run({
    "data_path": "synthetic",
    "models": ["linear", "mlp"],
    "lr_values": [0.01, 0.001, 0.0001],
    "epochs": 20,
    "patience": 3
})
print(result)
# {
#   "best_model": "mlp",
#   "best_lr": 0.001,
#   "best_val_loss": 0.043,
#   "experiments_run": 6,
#   "stopped_early": True
# }
```

**Stretch goals** (optional):
- Add `__repr__` to every class in your system.
- Make `ExperimentQueue` thread-safe with `threading.Lock`.
- Persist best config to JSON using `json.dump`.
- Write unit tests for `ExperimentConfig` validation using `unittest`.