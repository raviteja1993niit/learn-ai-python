# 🍱 BentoML — Model Serving

## What is BentoML?
BentoML is an open-source framework for building, packaging, and deploying machine learning models
as production-ready APIs. It abstracts away infrastructure concerns so you can go from a trained
model to a containerized, scalable HTTP service with minimal boilerplate.

## Why Learn It?
- Deploy any ML framework (sklearn, PyTorch, TensorFlow, XGBoost) with a unified API
- Built-in adaptive batching for high-throughput inference
- First-class support for LLM serving via OpenLLM
- One command to build a Docker image (`bentoml containerize`)
- Bridges the gap between MLflow model registry and production serving
- Deploy to BentoCloud, Kubernetes, or any container platform

## Key Concepts
```python
import bentoml
import numpy as np
from bentoml.io import NumpyNdarray

# Save a trained model to the BentoML model store
bentoml.sklearn.save_model("iris_clf", model, signatures={"predict": {"batchable": True}})

# Define a service with the @bentoml.service decorator
svc = bentoml.Service("iris_classifier")

iris_runner = bentoml.sklearn.get("iris_clf:latest").to_runner()
svc.add_runner(iris_runner)

@svc.api(input=NumpyNdarray(), output=NumpyNdarray())
async def classify(input_data: np.ndarray) -> np.ndarray:
    return await iris_runner.predict.async_run(input_data)
```

```yaml
# bentofile.yaml — defines what goes into the Bento archive
service: "service:svc"
labels:
  owner: ml-team
  stage: production
include:
  - "*.py"
python:
  packages:
    - scikit-learn
    - numpy
docker:
  python_version: "3.11"
```

```bash
# Serve locally, build a Bento, then containerize
bentoml serve service:svc --reload
bentoml build
bentoml containerize iris_classifier:latest -t iris-api:latest
docker run -p 3000:3000 iris-api:latest
```

## Learning Path
1. Install BentoML and save your first sklearn model with `bentoml.sklearn.save_model`
2. Define a `Service`, attach a Runner, and expose an `@svc.api` endpoint
3. Test locally with `bentoml serve` and call the `/predict` endpoint via curl
4. Write a `bentofile.yaml` and run `bentoml build` to create a versioned Bento archive
5. Containerize with `bentoml containerize` and run the Docker image
6. Explore adaptive batching: set `batchable=True` and tune `max_batch_size`
7. Serve an LLM locally using `openllm start llama2` (OpenLLM integration)
8. Deploy to BentoCloud with `bentoml deploy` or write a Kubernetes `Deployment` YAML

## What to Build
- [ ] Iris classifier REST API served with BentoML and tested with Swagger UI
- [ ] Multi-model service: preprocessing Runner + inference Runner chained together
- [ ] Adaptive batching benchmark — compare throughput with/without batching enabled
- [ ] LLM chat endpoint using OpenLLM + BentoML serving LLaMA or Mistral
- [ ] Full pipeline: train in MLflow → register model → serve with BentoML → containerize
- [ ] Kubernetes deployment manifest for a BentoML service with HPA autoscaling

## Related Folders
- `cloud-deployment\mlflow-main\` — MLflow model registry as the source for BentoML models
- `cloud-deployment\docker-kubernetes-main\` — container orchestration for BentoML services
- `cloud-deployment\fastapi-main\` — alternative serving approach to compare against BentoML
- `cloud-deployment\kubeflow-main\` — end-to-end pipelines that produce models for BentoML
