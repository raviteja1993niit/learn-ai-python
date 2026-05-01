# Flask + ML Model Deployment — Theory & Concepts

## 1. ML Model Deployment Lifecycle
The lifecycle of an ML model in production:

```
Data Collection → Feature Engineering → Model Training → Evaluation
      ↓
Model Serialization (pickle/joblib)
      ↓
REST API Development (Flask)
      ↓
Containerization (Docker)
      ↓
Cloud Deployment (AWS/GCP/Azure/Heroku)
      ↓
Monitoring & Logging → Retraining Loop
```

Key concerns at each stage:
- **Serialization**: Format, size, version compatibility
- **Serving**: Latency, throughput, concurrency
- **Monitoring**: Input drift, prediction drift, latency metrics
- **Maintenance**: Model versioning, rollback, A/B testing

## 2. Model Serialization: pickle vs joblib

### pickle
Python's built-in serialization:
```python
import pickle

# Save
with open('model.pkl', 'wb') as f:
    pickle.dump(model, f)

# Load
with open('model.pkl', 'rb') as f:
    model = pickle.load(f)
```

### joblib
Optimized for NumPy arrays — preferred for sklearn:
```python
import joblib

# Save
joblib.dump(model, 'model.joblib')

# Load
model = joblib.load('model.joblib')

# Compression
joblib.dump(model, 'model.joblib.gz', compress=3)
```

### Comparison
| Aspect         | pickle               | joblib               |
|----------------|----------------------|----------------------|
| NumPy arrays   | Slow                 | Fast (mmap support)  |
| File size      | Larger               | Smaller (compression)|
| Sklearn models | Works                | Recommended          |
| Deep learning  | Works                | Use torch.save/tf.saved_model |
| Security       | ⚠️ Unsafe from untrusted sources | Same warning |

### Security Warning
Never unpickle data from untrusted sources — it can execute arbitrary code!
Use ONNX or PMML formats for cross-language, safer serialization in production.

## 3. Flask ML API Pattern
Standard pattern for serving predictions:

```
POST /api/v1/predict
  → Receive JSON input
  → Validate input schema
  → Preprocess features
  → model.predict(features)
  → Return JSON response

GET /health
  → Return {"status": "ok", "model": "loaded"}
```

Response schema:
```json
{
  "prediction": 42000,
  "probability": 0.87,
  "model_version": "1.0.0",
  "inference_time_ms": 3.2
}
```

## 4. Input Validation Strategies

### Manual validation
```python
def validate_input(data):
    required = ['age', 'salary', 'experience']
    for field in required:
        if field not in data:
            raise ValueError(f"Missing field: {field}")
    if not isinstance(data['age'], (int, float)):
        raise TypeError("age must be numeric")
    if data['age'] < 0 or data['age'] > 120:
        raise ValueError("age out of range")
```

### Using marshmallow
```python
from marshmallow import Schema, fields, validate, ValidationError

class PredictSchema(Schema):
    age = fields.Int(required=True, validate=validate.Range(min=18, max=100))
    salary = fields.Float(required=True, validate=validate.Range(min=0))
    experience = fields.Int(required=True)

schema = PredictSchema()
try:
    data = schema.load(request.json)
except ValidationError as err:
    return jsonify({'errors': err.messages}), 422
```

### Using pydantic (alternative)
```python
from pydantic import BaseModel, validator

class PredictInput(BaseModel):
    age: int
    salary: float
    experience: int

    @validator('age')
    def age_must_be_positive(cls, v):
        if v < 0:
            raise ValueError('Age must be positive')
        return v
```

## 5. Error Handling for ML APIs
```python
@app.errorhandler(400)
def bad_request(e):
    return jsonify({'error': 'Bad Request', 'message': str(e)}), 400

@app.errorhandler(422)
def unprocessable(e):
    return jsonify({'error': 'Validation Error', 'message': str(e)}), 422

@app.errorhandler(500)
def server_error(e):
    app.logger.error(f"Server error: {e}")
    return jsonify({'error': 'Internal Server Error'}), 500
```

Always return structured JSON errors from APIs, never HTML pages.

## 6. Loading the Model Once at Startup
Never load the model inside the route handler — this causes re-loading on every request!

### Anti-pattern (slow)
```python
@app.route('/predict', methods=['POST'])
def predict():
    model = joblib.load('model.pkl')  # BAD: loads on every request
    ...
```

### Correct pattern
```python
# Module-level loading
model = joblib.load('model.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    result = model.predict(features)  # model already in memory
    ...
```

### Application factory pattern
```python
def create_app():
    app = Flask(__name__)
    app.config['MODEL'] = joblib.load('model.pkl')
    return app

@app.route('/predict', methods=['POST'])
def predict():
    model = current_app.config['MODEL']
    ...
```

## 7. Singleton Pattern for Model Loading
```python
class ModelSingleton:
    _instance = None
    _model = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
            cls._model = joblib.load('model.pkl')
        return cls._instance

    def predict(self, features):
        return self._model.predict(features)

# Usage
model = ModelSingleton.get_instance()
```

## 8. Environment Variables for Configuration
```python
import os

class Config:
    MODEL_PATH = os.environ.get('MODEL_PATH', 'models/model.pkl')
    SCALER_PATH = os.environ.get('SCALER_PATH', 'models/scaler.pkl')
    PREDICTION_THRESHOLD = float(os.environ.get('THRESHOLD', '0.5'))
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max upload
```

Use `.env` file + `python-dotenv`:
```
MODEL_PATH=models/random_forest_v2.pkl
SECRET_KEY=abc123xyz
PORT=5000
```

## 9. Logging Predictions for Monitoring
```python
import logging
import json
from datetime import datetime

logging.basicConfig(
    filename='predictions.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)

def log_prediction(input_data, prediction, latency_ms):
    record = {
        'timestamp': datetime.utcnow().isoformat(),
        'input': input_data,
        'prediction': prediction,
        'latency_ms': round(latency_ms, 2)
    }
    logging.info(json.dumps(record))
```

In production, send logs to ELK Stack, Datadog, or CloudWatch.

## 10. CORS Handling
When a React/Vue frontend calls your Flask API:

```python
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow all origins (dev only)

# Production: restrict origins
CORS(app, resources={
    r"/api/*": {
        "origins": ["https://myapp.com", "https://www.myapp.com"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

## 11. API Versioning
```python
# Blueprint-based versioning
v1 = Blueprint('v1', __name__, url_prefix='/api/v1')
v2 = Blueprint('v2', __name__, url_prefix='/api/v2')

@v1.route('/predict', methods=['POST'])
def predict_v1(): ...

@v2.route('/predict', methods=['POST'])
def predict_v2(): ...  # new input schema or model

app.register_blueprint(v1)
app.register_blueprint(v2)
```

Always version your APIs from day one. Breaking changes require a new version.

## 12. Testing with Postman / curl
```bash
# Health check
curl http://localhost:5000/health

# Prediction request
curl -X POST http://localhost:5000/api/v1/predict \
  -H "Content-Type: application/json" \
  -d '{"age": 30, "experience": 5, "salary": 60000}'

# With authentication
curl -X POST http://localhost:5000/api/v1/predict \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"age": 30}'
```

## 13. Docker Containerization
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_ENV=production
ENV MODEL_PATH=models/model.pkl

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "wsgi:app"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "5000:5000"
    environment:
      - MODEL_PATH=/app/models/model.pkl
    volumes:
      - ./models:/app/models
```

```bash
docker build -t ml-api .
docker run -p 5000:5000 ml-api
docker-compose up -d
```

## 14. Health Check Endpoint
Essential for load balancers and orchestration (Kubernetes, ECS):

```python
@app.route('/health')
def health():
    status = {
        'status': 'ok',
        'model_loaded': model is not None,
        'version': '1.0.0',
        'uptime_seconds': (datetime.now() - app.start_time).seconds
    }
    code = 200 if status['model_loaded'] else 503
    return jsonify(status), code
```

Kubernetes liveness probe:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10
```

## 15. Rate Limiting
Protect your API from abuse:

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/v1/predict', methods=['POST'])
@limiter.limit("10 per minute")
def predict():
    ...
```

## 16. A/B Model Testing
Serve different models to different users to compare performance:

```python
import random

models = {
    'v1': joblib.load('model_v1.pkl'),
    'v2': joblib.load('model_v2.pkl')
}

@app.route('/predict', methods=['POST'])
def predict():
    # 80% traffic to v1, 20% to v2
    version = 'v1' if random.random() < 0.8 else 'v2'
    model = models[version]
    prediction = model.predict(features)[0]

    return jsonify({
        'prediction': prediction,
        'model_version': version
    })
```

Track version metrics in your logging system to compare model performance.

## 17. Preprocessing Pipeline
Always save and load the preprocessing pipeline alongside the model:

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier

# Training time
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('classifier', RandomForestClassifier())
])
pipeline.fit(X_train, y_train)
joblib.dump(pipeline, 'pipeline.pkl')

# Serving time
pipeline = joblib.load('pipeline.pkl')
prediction = pipeline.predict(input_array)
# No need for separate scaler — it's part of the pipeline!
```

## 18. Feature Engineering at Inference
```python
import pandas as pd

def preprocess(raw_input: dict) -> pd.DataFrame:
    df = pd.DataFrame([raw_input])
    # Same transformations as training
    df['age_squared'] = df['age'] ** 2
    df['salary_log'] = np.log1p(df['salary'])
    df = df[FEATURE_COLUMNS]  # Ensure same column order
    return df
```

**Critical**: The preprocessing at inference MUST match training exactly.
Difference = training-serving skew = silent bugs.