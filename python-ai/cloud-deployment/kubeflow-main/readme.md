# ☸️ Kubeflow — ML Pipelines on Kubernetes

## What is Kubeflow?
Kubeflow is an open-source ML platform built on Kubernetes that provides a complete toolkit for
deploying, orchestrating, and monitoring ML workflows at scale. It bundles Kubeflow Pipelines for
DAG-based workflows, KServe for model serving, and Katib for hyperparameter optimization.

## Why Learn It?
- Reproduce any ML experiment as a versioned, containerized pipeline DAG
- KServe (formerly KFServing) gives Kubernetes-native model serving with autoscaling
- Katib automates hyperparameter search (grid, random, Bayesian, NAS)
- Scales from a local `kind` cluster to production GKE/EKS/AKS deployments
- Full UI dashboard: pipeline runs, experiments, model endpoints, artifact lineage
- Industry standard for MLOps on Kubernetes — widely used at Google, Spotify, Airbnb

## Key Concepts
```python
# pipeline.py — define a multi-step ML pipeline with the kfp SDK v2
import kfp
from kfp import dsl
from kfp.dsl import component, pipeline, Output, Dataset, Model, Metrics

@component(base_image="python:3.11", packages_to_install=["pandas", "scikit-learn"])
def preprocess(raw_data_path: str, output_dataset: Output[Dataset]):
    import pandas as pd
    df = pd.read_csv(raw_data_path).dropna()
    df.to_csv(output_dataset.path, index=False)

@component(base_image="python:3.11", packages_to_install=["scikit-learn", "joblib"])
def train(dataset: Input[Dataset], model_output: Output[Model], metrics: Output[Metrics]):
    import pandas as pd, joblib
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import train_test_split

    df = pd.read_csv(dataset.path)
    X, y = df.drop("label", axis=1), df["label"]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

    clf = RandomForestClassifier(n_estimators=100)
    clf.fit(X_train, y_train)
    acc = clf.score(X_test, y_test)

    joblib.dump(clf, model_output.path)
    metrics.log_metric("accuracy", acc)

@pipeline(name="iris-training-pipeline", description="Preprocess → Train → Evaluate")
def iris_pipeline(data_path: str = "gs://my-bucket/iris.csv"):
    preprocess_task = preprocess(raw_data_path=data_path)
    train_task = train(dataset=preprocess_task.outputs["output_dataset"])

# Compile to pipeline YAML and submit
compiler.Compiler().compile(iris_pipeline, "iris_pipeline.yaml")
client = kfp.Client(host="http://localhost:8080")
client.create_run_from_pipeline_func(iris_pipeline, arguments={"data_path": "gs://..."})
```

```yaml
# KServe InferenceService — deploy a model endpoint on Kubernetes
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: iris-classifier
  namespace: kubeflow
spec:
  predictor:
    sklearn:
      storageUri: "gs://my-bucket/models/iris"
      resources:
        requests:
          cpu: "100m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

```yaml
# Katib Experiment — Bayesian hyperparameter optimization
apiVersion: kubeflow.org/v1beta1
kind: Experiment
metadata:
  name: random-forest-hpo
spec:
  objective:
    type: maximize
    goal: 0.99
    objectiveMetricName: accuracy
  algorithm:
    algorithmName: bayesianoptimization
  parameters:
    - name: n_estimators
      parameterType: int
      feasibleSpace: { min: "50", max: "300" }
    - name: max_depth
      parameterType: int
      feasibleSpace: { min: "3", max: "20" }
  maxTrialCount: 20
  parallelTrialCount: 3
```

## Learning Path
1. Set up a local Kubeflow environment using `kind` + the Kubeflow manifests (`kubectl apply -k`)
2. Open the Kubeflow dashboard at `localhost:8080` and explore the UI
3. Write a two-component `@pipeline` with the kfp SDK v2 and compile to YAML
4. Submit the pipeline via the UI or `kfp.Client` and inspect the run graph
5. Add `Output[Metrics]` to a component and view metrics in the Experiments tab
6. Deploy a trained model with a KServe `InferenceService` YAML and test with curl
7. Run a Katib `Experiment` for hyperparameter search and view the results chart
8. Build a full pipeline: preprocess → train → evaluate → conditional deploy to KServe

## What to Build
- [ ] Hello-world two-step pipeline compiled to YAML and run on a local kind cluster
- [ ] Iris classification pipeline: preprocess + train + evaluate components
- [ ] KServe endpoint serving a sklearn model from GCS with live curl test
- [ ] Katib HPO experiment tuning RandomForest `n_estimators` and `max_depth`
- [ ] Full MLOps pipeline: data ingest → feature eng → train → HPO → KServe deploy
- [ ] Pipeline with a conditional step: only deploy if accuracy > 0.95

## Related Folders
- `cloud-deployment\bentoml-model-serving-main\` — lightweight alternative to KServe for serving
- `cloud-deployment\mlflow-main\` — integrate MLflow tracking inside Kubeflow components
- `cloud-deployment\feast-feature-store-main\` — consume Feast features inside pipeline components
- `cloud-deployment\prefect-workflow-orchestration-main\` — simpler orchestration without K8s
