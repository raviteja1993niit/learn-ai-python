# 🧱 Databricks — Lakehouse Platform

## What is Databricks?
Databricks is a unified analytics platform built on Apache Spark that implements the Lakehouse
architecture — combining the low-cost storage of a data lake with the ACID reliability of a data
warehouse. It provides a collaborative notebook environment with first-class MLflow, AutoML, and
Feature Store integrations for end-to-end ML workflows.

## Why Learn It?
- Delta Lake gives ACID transactions, time travel, and schema enforcement on cloud object storage
- Databricks Runtime (DBR) is an optimized Spark distribution — 5-50x faster than open-source Spark
- MLflow is deeply integrated: automatic experiment tracking, model registry, and serving
- AutoML (`databricks.automl`) produces a baseline model and notebooks in minutes
- Unity Catalog provides fine-grained governance across all data, ML models, and dashboards
- Widely used in enterprise ML pipelines alongside AWS/Azure/GCP data stacks

## Key Concepts
```python
# Delta Lake — ACID tables with time travel and MERGE (upsert)
from delta.tables import DeltaTable
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

# Write a Delta table
df = spark.read.csv("/databricks-datasets/iris/", header=True, inferSchema=True)
df.write.format("delta").mode("overwrite").saveAsTable("ml_catalog.default.iris")

# Time travel — query a previous version
spark.read.format("delta").option("versionAsOf", 0).table("ml_catalog.default.iris").show()

# MERGE (upsert)
delta_table = DeltaTable.forName(spark, "ml_catalog.default.iris")
delta_table.alias("target").merge(
    source=new_df.alias("source"),
    condition="target.id = source.id"
).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
```

```python
# MLflow on Databricks — experiment tracking + model registry
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier

mlflow.set_experiment("/Users/me@company.com/iris_experiment")

with mlflow.start_run():
    clf = RandomForestClassifier(n_estimators=100, max_depth=5)
    clf.fit(X_train, y_train)
    acc = clf.score(X_test, y_test)

    mlflow.log_param("n_estimators", 100)
    mlflow.log_metric("accuracy", acc)
    mlflow.sklearn.log_model(clf, "model", registered_model_name="IrisClassifier")
```

```python
# Databricks AutoML — generate a baseline model automatically
import databricks.automl as automl

summary = automl.classify(
    dataset=spark.table("ml_catalog.default.iris"),
    target_col="species",
    timeout_minutes=30,
)
print(summary.best_trial.mlflow_run_id)
```

```python
# Databricks Feature Store
from databricks.feature_store import FeatureStoreClient

fs = FeatureStoreClient()
fs.create_table(
    name="ml_catalog.default.driver_features",
    primary_keys=["driver_id"],
    df=feature_df,
    description="Driver hourly stats",
)

# Retrieve features for training (point-in-time correct)
training_set = fs.create_training_set(
    df=labels_df,
    feature_lookups=[FeatureLookup(table_name="ml_catalog.default.driver_features",
                                   lookup_key="driver_id")],
    label="trip_completed",
)
```

## Learning Path
1. Sign up for Databricks Community Edition (free) at community.cloud.databricks.com
2. Create a cluster with DBR 14.x ML runtime and import a sample notebook
3. Read/write a Delta table; run `DESCRIBE HISTORY` to see the transaction log
4. Use time travel: `spark.read.option("versionAsOf", 0).format("delta").load(...)`
5. Run an MLflow experiment inside a notebook; view runs in the Experiments UI
6. Try AutoML on the Iris dataset with `databricks.automl.classify`
7. Set up Unity Catalog and create a three-level namespace: catalog.schema.table
8. Build a Databricks Job (multi-task workflow) that chains notebooks end-to-end

## What to Build
- [ ] Delta Lake CRUD notebook: create, read, update (MERGE), delete, time travel
- [ ] MLflow experiment comparing 3 classifiers; promote best model to registry
- [ ] AutoML run on a real dataset; review the generated feature engineering notebook
- [ ] Feature Store table with FeatureLookup in a training pipeline
- [ ] Databricks Job with 3 tasks: ingest → train → register, scheduled daily
- [ ] Databricks SQL dashboard visualizing model accuracy over time from MLflow

## Related Folders
- `big-data\spark-main\` — core PySpark skills needed before tackling Databricks
- `cloud-deployment\mlflow-main\` — standalone MLflow concepts before Databricks-hosted MLflow
- `cloud-deployment\feast-feature-store-main\` — open-source alternative to Databricks Feature Store
- `big-data\great-expectations-data-quality-main\` — validate Delta table quality before training
