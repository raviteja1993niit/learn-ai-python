# ⚡ Dask & Ray — Distributed Python Computing

## What are Dask and Ray?
- **Dask** — Parallel Pandas/NumPy for datasets larger than RAM
- **Ray** — General-purpose distributed Python (ML training, serving, pipelines)

## When to Use Each
| Scenario | Tool |
|----------|------|
| Dataset > RAM, Pandas API | Dask |
| Parallel ML training | Ray Train |
| Hyperparameter tuning | Ray Tune |
| Model serving at scale | Ray Serve |
| General parallel Python | Ray |

## Dask Key Code
```python
import dask.dataframe as dd

# Read 100GB CSV — lazy, out-of-core
df = dd.read_csv("huge_dataset_*.csv")
result = df.groupby("category")["sales"].mean().compute()  # .compute() triggers execution

# Parallel numpy
import dask.array as da
x = da.from_array(np_array, chunks=1000)
result = x.mean().compute()
```

## Ray Key Code
```python
import ray
ray.init()

@ray.remote
def train_model(params):
    # runs in separate process / machine
    return model.fit(X_train, params)

# Run 10 models in parallel
futures = [train_model.remote(p) for p in param_grid]
results = ray.get(futures)

# Ray Tune — hyperparameter search
from ray import tune
tune.run(train_model, config={"lr": tune.loguniform(1e-4, 1e-1)})
```

## Learning Path
1. `pip install dask ray`
2. Dask: process a CSV that doesn'"'"'t fit in memory
3. Dask: parallel groupby/aggregation
4. Ray: parallelize a for loop
5. Ray Tune: distributed hyperparameter search

## What to Build
- [ ] Process the playstore dataset with Dask (simulate large scale)
- [ ] Parallel cross-validation with Ray
- [ ] Distributed hyperparameter tuning on ML models

## Related Folders
- `big-data/Pyspark-With-Python-main/` — PySpark alternative
- `big-data/Polars-GPU-Engine-Demo-main/` — fast single-machine processing
- `machine-learning/Pipeline-MAchine-Learning-main/` — sklearn pipelines to parallelize