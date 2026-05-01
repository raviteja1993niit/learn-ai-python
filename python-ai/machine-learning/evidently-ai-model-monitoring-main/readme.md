# 📊 Evidently AI — Data Drift & Model Monitoring

## What is Evidently AI?
Evidently AI is an open-source library for evaluating and monitoring ML models in production. It detects data drift, target drift, and model performance degradation by comparing a reference dataset (training) to current production data, generating rich HTML reports and JSON metrics.

## Why Learn It?
- Production models silently degrade when input distributions shift — Evidently catches this
- One-line presets generate comprehensive reports without custom metric coding
- JSON output integrates with MLflow, Airflow, and Grafana for automated alerting
- Essential skill for any MLOps pipeline or model maintenance workflow

## Key Concepts
```python
import pandas as pd
import numpy as np
from evidently import ColumnMapping
from evidently.report import Report
from evidently.metric_preset import (
    DataDriftPreset,
    TargetDriftPreset,
    DataQualityPreset,
    ClassificationPreset,
)
from evidently.metrics import DatasetDriftMetric, DatasetMissingValuesSummaryMetric

# Simulate reference (train) vs current (production) data
np.random.seed(42)
reference = pd.DataFrame({
    "age": np.random.normal(35, 10, 500),
    "income": np.random.normal(60000, 15000, 500),
    "churn": np.random.randint(0, 2, 500),
    "prediction": np.random.randint(0, 2, 500),
})
# Introduce drift in production data
current = pd.DataFrame({
    "age": np.random.normal(45, 12, 200),      # distribution shifted
    "income": np.random.normal(55000, 20000, 200),
    "churn": np.random.randint(0, 2, 200),
    "prediction": np.random.randint(0, 2, 200),
})

column_mapping = ColumnMapping(
    target="churn",
    prediction="prediction",
    numerical_features=["age", "income"],
)

# Generate HTML report with multiple presets
report = Report(metrics=[
    DataDriftPreset(),
    TargetDriftPreset(),
    DataQualityPreset(),
    ClassificationPreset(),
])
report.run(reference_data=reference, current_data=current,
           column_mapping=column_mapping)

report.save_html("monitoring_report.html")   # open in browser

# Extract JSON metrics for programmatic alerting
result = report.as_dict()
drift_score = result["metrics"][0]["result"]["dataset_drift"]
if drift_score:
    print("⚠️  Data drift detected — retraining recommended!")

# Individual metric check
single = Report(metrics=[DatasetDriftMetric()])
single.run(reference_data=reference, current_data=current)
print(single.as_dict()["metrics"][0]["result"])
```

## Learning Path
1. `pip install evidently scikit-learn pandas`
2. Split your dataset into reference (train/validation) and current (recent production) sets
3. Run `DataDriftPreset` and open the HTML report — inspect per-feature drift scores
4. Add `TargetDriftPreset` and `ClassificationPreset` for full model health monitoring
5. Export JSON metrics and wire into an MLflow run or an Airflow alert task

## What to Build
- [ ] A weekly drift report pipeline that compares last week's predictions to the training distribution
- [ ] An Airflow DAG that runs Evidently checks nightly and sends a Slack alert on drift detection
- [ ] A Grafana dashboard fed by Evidently JSON metrics stored in a PostgreSQL metrics table

## Related Folders
- `machine-learning/xgboost-tutorial-main/` — monitor XGBoost models deployed to production
- `machine-learning/optuna-hyperparameter-tuning-main/` — trigger retraining + re-tuning on drift
