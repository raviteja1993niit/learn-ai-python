# 🔄 Prefect — Workflow Orchestration

## What is Prefect?
Prefect is a modern workflow orchestration platform that lets you turn any Python function into an
observable, retryable, and schedulable data pipeline with minimal code changes. It provides a rich
UI, cloud platform, and a local execution engine for building reliable ML and data workflows.

## Why Learn It?
- Decorate existing Python functions with `@flow` and `@task` — no DAG boilerplate like Airflow
- Built-in retries, caching, timeouts, and concurrency controls per task
- Prefect Cloud UI gives real-time visibility into every run and its logs
- Native task mapping for parallel fan-out over lists of items
- First-class support for ML pipelines: train → evaluate → notify in one flow
- Easier local development than Airflow (no Docker required to start)

## Key Concepts
```python
from prefect import flow, task
from prefect.tasks import task_input_hash
from datetime import timedelta

@task(
    retries=3,
    retry_delay_seconds=10,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(hours=1),
)
def load_data(path: str) -> list:
    # Cached: re-running with same path skips re-execution for 1 hour
    return open(path).readlines()

@task
def train_model(data: list) -> dict:
    # ... training logic ...
    return {"accuracy": 0.95, "model_path": "models/run_1.pkl"}

@task
def notify(result: dict):
    print(f"Training complete! Accuracy: {result['accuracy']}")

@flow(name="ml-training-pipeline", log_prints=True)
def ml_pipeline(data_path: str = "data/train.csv"):
    data = load_data(data_path)
    result = train_model(data)
    notify(result)

if __name__ == "__main__":
    ml_pipeline(data_path="data/train.csv")
```

```python
# Task mapping — run a task in parallel over a list
from prefect import flow, task

@task
def process_file(file: str) -> str:
    return f"processed: {file}"

@flow
def batch_pipeline(files: list[str]):
    results = process_file.map(files)   # parallel fan-out
    return [r.result() for r in results]
```

```yaml
# prefect.yaml — deployment definition
name: ml-training-pipeline
entrypoint: pipeline.py:ml_pipeline
work_pool:
  name: my-process-pool
schedules:
  - cron: "0 6 * * *"   # daily at 6am
parameters:
  data_path: "data/train.csv"
```

## Learning Path
1. `pip install prefect` and run `prefect server start` to launch the local UI
2. Write a two-task `@flow` (load → print) and observe it in the dashboard
3. Add `retries=3` and `cache_key_fn=task_input_hash` to a task; confirm cache hits
4. Use `.map()` to fan-out a task over a list and observe parallel execution
5. Create a `prefect.yaml` and run `prefect deploy` to register a deployment
6. Add a cron schedule and a work pool; start a worker with `prefect worker start`
7. Emit `create_markdown_artifact` from a task and view it in Prefect Cloud
8. Build a full ML pipeline: ingest → preprocess → train → evaluate → Slack notify

## What to Build
- [ ] Basic ETL flow: download CSV → clean → save, with retries on download task
- [ ] ML training pipeline with cached data loading and result artifacts
- [ ] Parallel file processing flow using `task.map()` over an S3 bucket listing
- [ ] Scheduled daily retraining pipeline deployed via `prefect deploy`
- [ ] Prefect + MLflow integration: log metrics inside a Prefect task
- [ ] Compare Prefect vs Airflow: rewrite the same DAG in both frameworks

## Related Folders
- `cloud-deployment\mlflow-main\` — log experiment metrics from within Prefect tasks
- `cloud-deployment\feast-feature-store-main\` — materialize features on a Prefect schedule
- `cloud-deployment\kubeflow-main\` — alternative heavy-weight pipeline orchestration
- `big-data\databricks-main\` — trigger Databricks Jobs from a Prefect flow
