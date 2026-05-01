# 🍽️ Feast — Feature Store

## What is Feast?
Feast (Feature Store) is an open-source operational data system for managing and serving machine
learning features. It solves the training-serving skew problem by providing a single, consistent
source of features for both offline model training and online real-time inference.

## Why Learn It?
- Eliminates training-serving skew: exact same feature logic for training and production
- Point-in-time correct joins prevent data leakage in historical training datasets
- Decouples feature engineering from model training and serving code
- Supports multiple offline stores (Parquet, BigQuery, Redshift) and online stores (Redis, DynamoDB)
- `feast materialize` syncs features from offline to online store for low-latency serving
- Integrates with MLflow, Airflow, and Kubeflow Pipelines

## Key Concepts
```python
# feature_repo/features.py — define entities, feature views, and services
from feast import Entity, FeatureView, FeatureService, Field, FileSource
from feast.types import Float32, Int64
from datetime import timedelta

# Entity: the primary key that features are joined on
driver = Entity(name="driver_id", description="Driver entity")

# Offline source (Parquet file or BigQuery table)
driver_stats_source = FileSource(
    path="data/driver_stats.parquet",
    timestamp_field="event_timestamp",
)

# FeatureView: group of related features with a TTL
driver_stats_fv = FeatureView(
    name="driver_hourly_stats",
    entities=[driver],
    ttl=timedelta(days=7),
    schema=[
        Field(name="conv_rate", dtype=Float32),
        Field(name="acc_rate",  dtype=Float32),
        Field(name="avg_daily_trips", dtype=Int64),
    ],
    online=True,
    source=driver_stats_source,
)

# FeatureService: logical grouping used in training & serving
driver_activity_svc = FeatureService(
    name="driver_activity",
    features=[driver_stats_fv],
)
```

```python
# Training — get historical features with point-in-time correct joins
from feast import FeatureStore
import pandas as pd

store = FeatureStore(repo_path="feature_repo/")

entity_df = pd.DataFrame({
    "driver_id": [1001, 1002, 1003],
    "event_timestamp": pd.to_datetime(["2024-01-01", "2024-01-02", "2024-01-03"]),
})

training_df = store.get_historical_features(
    entity_df=entity_df,
    features=["driver_hourly_stats:conv_rate", "driver_hourly_stats:acc_rate"],
).to_df()

# Inference — get online features (low-latency, from Redis)
online_features = store.get_online_features(
    features=["driver_hourly_stats:conv_rate", "driver_hourly_stats:avg_daily_trips"],
    entity_rows=[{"driver_id": 1001}],
).to_dict()
```

```yaml
# feature_store.yaml
project: driver_ranking
registry: data/registry.db
provider: local
online_store:
  type: redis
  connection_string: "localhost:6379"
offline_store:
  type: file
entity_key_serialization_version: 2
```

```bash
feast apply           # register feature definitions
feast materialize-incremental $(date -u +"%Y-%m-%dT%H:%M:%S")  # sync offline→online
feast ui              # launch the Feast feature catalog UI
```

## Learning Path
1. `pip install feast` and run `feast init my_project` to scaffold a feature repo
2. Define an `Entity`, `FileSource`, and `FeatureView`; run `feast apply`
3. Create a training dataset with `get_historical_features` and verify point-in-time joins
4. Run `feast materialize` to populate the online store; call `get_online_features`
5. Swap the offline store to BigQuery and the online store to Redis in `feature_store.yaml`
6. Build a `FeatureService` and use it in both training and a FastAPI inference endpoint
7. Schedule `feast materialize-incremental` via a Prefect or Airflow task
8. Integrate with MLflow: log feature version metadata alongside experiment runs

## What to Build
- [ ] Driver ranking feature store: entity, 3 feature views, offline Parquet source
- [ ] Point-in-time correct training dataset to prove no data leakage
- [ ] Online serving demo: materialize to Redis → FastAPI endpoint reads online features
- [ ] BigQuery offline store + Redis online store setup on GCP
- [ ] Prefect flow that materializes features daily before model retraining
- [ ] MLflow + Feast integration: tag runs with the feature service version used

## Related Folders
- `cloud-deployment\mlflow-main\` — pair MLflow experiment tracking with Feast feature versions
- `cloud-deployment\prefect-workflow-orchestration-main\` — schedule feature materialization
- `cloud-deployment\kubeflow-main\` — use Feast inside a Kubeflow pipeline component
- `big-data\databricks-main\` — Databricks Feature Store as an alternative to Feast
