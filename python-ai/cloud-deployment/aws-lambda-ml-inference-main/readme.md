# ⚡ AWS Lambda for ML Inference — Serverless Model Serving at Scale

## What is AWS Lambda for ML Inference?
AWS Lambda is a serverless compute service that runs code in response to events without managing
servers. For ML inference, it lets you serve predictions from scikit-learn, XGBoost, or lightweight
deep learning models via HTTP through API Gateway — paying only per invocation rather than for
idle SageMaker endpoints. It is ideal for low-to-medium traffic models where cost matters more
than single-digit millisecond latency.

## Why Learn It?
- 80–95% cheaper than SageMaker real-time endpoints for spiky or low-volume traffic
- Deploy models in under 10 minutes using AWS SAM with a single `sam deploy`
- Understand cold start trade-offs and mitigation (provisioned concurrency, model caching)
- API Gateway + Lambda = instant REST endpoint for any trained model
- Foundation for event-driven ML pipelines (S3 trigger → Lambda → prediction → DynamoDB)

## Key Concepts
```python
# handler.py — Lambda function anatomy
import json
import boto3
import pickle
import os

# Load model once outside handler (cached across warm invocations)
s3 = boto3.client("s3")
MODEL_PATH = "/tmp/model.pkl"

def _load_model():
    if not os.path.exists(MODEL_PATH):
        s3.download_file(
            Bucket=os.environ["MODEL_BUCKET"],
            Key=os.environ["MODEL_KEY"],
            Filename=MODEL_PATH,
        )
    with open(MODEL_PATH, "rb") as f:
        return pickle.load(f)

model = _load_model()  # runs at container init, not per request

def handler(event, context):
    """
    event  — dict from API Gateway (body, headers, queryStringParameters)
    context — Lambda runtime metadata (function_name, remaining_time_in_millis)
    """
    body = json.loads(event.get("body", "{}"))
    features = body["features"]          # [[5.1, 3.5, 1.4, 0.2]]
    prediction = model.predict(features)
    return {
        "statusCode": 200,
        "body": json.dumps({"prediction": prediction.tolist()}),
    }
```

```yaml
# template.yaml — AWS SAM definition
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Timeout: 30
    MemorySize: 512       # tune with Lambda Power Tuning tool
    Environment:
      Variables:
        MODEL_BUCKET: my-ml-models
        MODEL_KEY: iris/model.pkl

Resources:
  MLInferenceFunction:
    Type: AWS::Serverless::Function
    Properties:
      PackageType: Image   # Docker image — avoids 250 MB zip limit for large deps
      ImageUri: !Sub "${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/ml-lambda:latest"
      Events:
        Predict:
          Type: Api
          Properties:
            Path: /predict
            Method: post
      Policies:
        - S3ReadPolicy:
            BucketName: my-ml-models
```

## Learning Path
1. Build a "hello world" Lambda in the AWS Console; understand handler/event/context
2. Package a scikit-learn model as a `.zip` with dependencies + `sam build && sam deploy`
3. Wire up API Gateway → Lambda; test with `curl -X POST /predict`
4. Hit the 250 MB zip limit → migrate to Docker container image deployment
5. Measure cold starts; add provisioned concurrency and compare latency
6. Use Lambda Layers to share heavy dependencies (numpy, pandas) across functions
7. Benchmark cost: Lambda vs SageMaker endpoint at 1k/10k/100k requests per day
8. Build an S3-triggered pipeline: upload CSV → Lambda batch inference → results to DynamoDB

## What to Build
- [ ] Lambda function serving a pickled scikit-learn iris classifier via API Gateway
- [ ] Docker-based Lambda with a TensorFlow Lite model (bypasses zip size limits)
- [ ] SAM template with dev/prod stages and environment variable separation
- [ ] Cold start benchmark script comparing zip vs Docker vs provisioned concurrency
- [ ] S3-triggered Lambda that runs batch predictions on uploaded CSV files

## Related Folders
- `cloud-deployment/terraform-ml-infra-main/` — provision Lambda + API Gateway with Terraform
- `cloud-deployment/docker-containers-main/` — build the container images Lambda runs on
- `mlops/mlflow-tracking-main/` — load model artifacts from MLflow registry into Lambda
