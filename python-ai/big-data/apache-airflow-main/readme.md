# 🌬️ Apache Airflow — Workflow Orchestration for ML Pipelines

## What is Apache Airflow?
Apache Airflow is an open-source platform for programmatically authoring, scheduling, and
monitoring data and ML workflows as Directed Acyclic Graphs (DAGs). Each DAG is plain Python,
making pipelines version-controllable, testable, and composable across teams.

## Why Learn It?
- Schedules complex multi-step ML pipelines (ingest → preprocess → train → evaluate → deploy)
- Built-in retry logic, alerting, and a rich UI make production workflows observable
- Hundreds of provider integrations: AWS, GCP, Spark, dbt, Docker, Kubernetes, and more
- TaskFlow API (@task decorator) eliminates boilerplate and makes data passing explicit

## Key Concepts
```python
from datetime import datetime, timedelta
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.operators.email import EmailOperator

# --- ML Pipeline DAG using TaskFlow API ---
@dag(
    dag_id="ml_training_pipeline",
    schedule="0 3 * * *",          # daily at 03:00 UTC (cron syntax)
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)},
    tags=["ml", "training"],
)
def ml_pipeline():

    @task()
    def ingest_data() -> dict:
        # pull raw data; return path via XCom automatically
        raw_path = download_from_s3("s3://bucket/raw/")
        return {"raw_path": raw_path, "row_count": 50_000}

    @task()
    def preprocess(meta: dict) -> str:
        df = pd.read_parquet(meta["raw_path"])
        clean_path = run_feature_engineering(df)
        return clean_path                          # passed to next task via XCom

    @task()
    def train_model(clean_path: str) -> str:
        model, metrics = fit_model(clean_path)
        model_path = save_model(model)
        return model_path

    @task()
    def evaluate(model_path: str) -> float:
        accuracy = run_evaluation(model_path)
        if accuracy < 0.85:
            raise ValueError(f"Accuracy {accuracy:.3f} below threshold — failing pipeline")
        return accuracy

    # Traditional operator for a shell step
    deploy = BashOperator(
        task_id="deploy_model",
        bash_command="docker build -t my-model:latest . && docker push my-model:latest",
    )

    notify = EmailOperator(
        task_id="notify_team",
        to="ml-team@company.com",
        subject="✅ ML pipeline succeeded",
        html_content="New model deployed. See Airflow UI for metrics.",
    )

    # Task dependency chain (>> operator)
    raw = ingest_data()
    clean = preprocess(raw)
    model = train_model(clean)
    acc = evaluate(model)
    acc >> deploy >> notify

dag_instance = ml_pipeline()
```

## Learning Path
1. `pip install apache-airflow` or use Docker Compose (recommended for local dev)
2. `airflow db init && airflow standalone` — starts webserver + scheduler locally
3. Place a DAG file in `~/airflow/dags/`; confirm it appears in the Airflow UI
4. Practice `BashOperator` → `PythonOperator` → `TaskFlow @task` patterns
5. Use XComs to pass data between tasks; inspect them in the UI (Admin → XComs)
6. Configure Variables (Admin → Variables) and Connections for secrets
7. Build the full ML pipeline DAG from ingest through deploy
8. Set up Docker Compose with Postgres metadata DB + Redis broker for production-like env

## What to Build
- [ ] ETL pipeline: fetch API data → clean → load to database, scheduled daily
- [ ] ML training DAG: ingest → feature engineering → train → evaluate with accuracy gate
- [ ] Model retraining trigger: watch for new data in S3, kick off training automatically
- [ ] Multi-environment DAG: dev / staging / prod using Airflow Variables to swap configs
- [ ] Monitoring DAG: query model serving metrics and alert on drift via EmailOperator

## Related Folders
- `big-data\spark-main\`                        — Airflow SparkSubmitOperator for big datasets
- `cloud-deployment\github-actions-mlops-main\` — CI/CD complement to Airflow orchestration
- `cloud-deployment\weights-and-biases-main\`   — log metrics from inside Airflow tasks
- `big-data\kafka-main\`                        — stream ingestion feeding Airflow batch jobs
