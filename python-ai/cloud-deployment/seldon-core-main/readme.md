# ⚙️ Seldon Core — ML Deployment on Kubernetes

## What is Seldon Core?
Seldon Core is an open-source ML deployment platform built on Kubernetes that turns any trained model into a production microservice via a single YAML manifest (`SeldonDeployment` CRD). It provides pre-packaged servers for common frameworks (SKLearn, XGBoost, MLflow), a Python SDK for custom microservices, and advanced traffic routing for canary releases, A/B tests, and shadow deployments. Alibi Detect and Alibi Explain sidecars add drift detection and explainability without touching model code.

## Why Learn It?
- Deploy any ML model to Kubernetes with a single `kubectl apply` and zero boilerplate
- Built-in canary and A/B traffic splitting with no Istio/Envoy configuration needed
- Drift detector and explainer run as sidecars alongside the model — no code changes
- Seldon Deploy UI provides a visual interface for managing and monitoring deployments
- Deeper Kubernetes integration than BentoML; more ML-native than plain KServe YAML

## Key Concepts
```yaml
# ── Pre-packaged SKLearn server ──────────────────────────────────────────────
apiVersion: machinelearning.seldon.io/v1
kind: SeldonDeployment
metadata:
  name: sklearn-iris
  namespace: seldon
spec:
  predictors:
    - name: default
      replicas: 2
      graph:
        name: classifier
        implementation: SKLEARN_SERVER
        modelUri: gs://my-bucket/sklearn-iris/  # or s3://, pvc://
      componentSpecs:
        - spec:
            containers:
              - name: classifier
                resources:
                  requests: { cpu: "500m", memory: "512Mi" }
                  limits:   { cpu: "1",    memory: "1Gi"   }

---
# ── Canary deployment (90% stable / 10% canary) ──────────────────────────────
apiVersion: machinelearning.seldon.io/v1
kind: SeldonDeployment
metadata:
  name: model-canary
  namespace: seldon
spec:
  predictors:
    - name: stable
      replicas: 3
      traffic: 90
      graph:
        name: stable-model
        implementation: MLFLOW_SERVER
        modelUri: s3://models/v1/
    - name: canary
      replicas: 1
      traffic: 10
      graph:
        name: canary-model
        implementation: MLFLOW_SERVER
        modelUri: s3://models/v2/

---
# ── Shadow deployment (mirror traffic, don't affect response) ────────────────
apiVersion: machinelearning.seldon.io/v1
kind: SeldonDeployment
metadata:
  name: model-shadow
spec:
  predictors:
    - name: main
      replicas: 2
      traffic: 100
      graph:
        name: prod-model
        implementation: XGBOOST_SERVER
        modelUri: s3://models/xgb-prod/
    - name: shadow
      replicas: 1
      shadow: true                          # receives mirrored traffic only
      graph:
        name: shadow-model
        implementation: XGBOOST_SERVER
        modelUri: s3://models/xgb-v2/
```

```python
# ── Custom Python microservice (SeldonComponent) ─────────────────────────────
import numpy as np
from typing import Dict, List

class MyModel:                              # filename must be MyModel.py
    def __init__(self):
        import joblib
        self.model = joblib.load("/app/model.pkl")

    def predict(self, X: np.ndarray, features_names: List[str] = None) -> np.ndarray:
        return self.model.predict_proba(X)

    def health_status(self) -> Dict:        # optional liveness probe
        return {"status": "ok"}

# ── Alibi Detect drift detector sidecar config ───────────────────────────────
"""
In SeldonDeployment spec add under the predictor graph:

  graph:
    name: classifier
    implementation: SKLEARN_SERVER
    modelUri: s3://models/clf/
    children:
      - name: drift-detector
        type: COMBINER                      # routes to both and combines
        implementation: TRITON_SERVER

OR use dedicated Alibi Detect server:

  - name: drift
    type: OUTPUT_TRANSFORMER
    implementation: ALIBI_DETECT_SERVER
    modelUri: gs://detectors/drift-ksdrift/
    envSecretRefName: seldon-rclone-secret
"""

# ── Send predictions via REST ─────────────────────────────────────────────────
import requests, json

url = "http://<ingress>/seldon/seldon/sklearn-iris/api/v1.0/predictions"
payload = {"data": {"ndarray": [[5.1, 3.5, 1.4, 0.2]]}}
resp = requests.post(url, json=payload)
print(resp.json())  # {"data": {"ndarray": [[0.97, 0.02, 0.01]]}, ...}

# ── kubectl workflow ──────────────────────────────────────────────────────────
"""
# Install Seldon Core with Helm
helm install seldon-core seldon-core-operator \
  --repo https://storage.googleapis.com/seldon-charts \
  --namespace seldon-system --create-namespace \
  --set usageMetrics.enabled=true \
  --set istio.enabled=true

kubectl apply -f sklearn-iris.yaml
kubectl get seldondeployments -n seldon
kubectl rollout status deployment/sklearn-iris-default-0-classifier -n seldon
"""
```

## Learning Path
1. Install Seldon Core on a local cluster (kind/minikube) using Helm
2. Deploy a pre-packaged `SKLEARN_SERVER` with a saved `.pkl` model from S3
3. Write a custom `SeldonComponent` Python class and containerize it
4. Configure a canary deployment (90/10 traffic split) and verify with load test
5. Set up a shadow deployment and compare predictions between model versions
6. Add an Alibi Detect drift detector sidecar to monitor production data
7. Attach an Alibi Explain explainer and request SHAP explanations via REST

## What to Build
- [ ] Iris classifier as a pre-packaged SKLearn server deployed via `kubectl apply`
- [ ] Custom fraud detection microservice using `SeldonComponent` with feature preprocessing
- [ ] Canary release pipeline for an XGBoost model with gradual traffic shift (10→50→100%)
- [ ] Drift monitoring dashboard using Alibi Detect + Prometheus + Grafana
- [ ] A/B test comparing two NLP models with Seldon's traffic routing and Kibana metrics

## Related Folders
- `cloud-deployment\triton-inference-server-main\` — use Triton as a Seldon backend for GPU serving
- `cloud-deployment\model-deployment-main\` — compare Seldon vs KServe vs BentoML vs TorchServe
- `mlops\model-monitoring-main\` — plug Alibi Detect outputs into a broader monitoring stack
