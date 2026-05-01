# Flask + ML Deployment — 20+ Code Examples

## Example 1: Minimal ML Prediction API
```python
from flask import Flask, request, jsonify
import joblib
import numpy as np

app = Flask(__name__)
model = joblib.load('model.pkl')  # Load once at module startup

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    features = np.array([[data['feature1'], data['feature2'], data['feature3']]])
    prediction = model.predict(features)[0]
    return jsonify({'prediction': float(prediction)})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
```

## Example 2: Health Check Endpoint
```python
from flask import Flask, jsonify
from datetime import datetime
import joblib

app = Flask(__name__)
app.start_time = datetime.now()
model = None

def load_model():
    global model
    try:
        model = joblib.load('models/model.pkl')
        return True
    except Exception as e:
        app.logger.error(f"Model load failed: {e}")
        return False

load_model()

@app.route('/health')
def health():
    uptime = (datetime.now() - app.start_time).seconds
    return jsonify({
        'status': 'ok' if model is not None else 'degraded',
        'model_loaded': model is not None,
        'uptime_seconds': uptime,
        'version': '1.0.0'
    }), 200 if model is not None else 503
```

## Example 3: Input Validation with Type Checking
```python
from flask import Flask, request, jsonify
import numpy as np

app = Flask(__name__)

REQUIRED_FIELDS = {
    'age': (int, float),
    'salary': (int, float),
    'experience': (int, float),
    'education': str
}

VALID_EDUCATION = ['high_school', 'bachelor', 'master', 'phd']

def validate_input(data):
    errors = []
    for field, expected_types in REQUIRED_FIELDS.items():
        if field not in data:
            errors.append(f"Missing required field: '{field}'")
            continue
        if not isinstance(data[field], expected_types):
            errors.append(f"Field '{field}' must be {expected_types}")
    if 'education' in data and data['education'] not in VALID_EDUCATION:
        errors.append(f"education must be one of: {VALID_EDUCATION}")
    if 'age' in data and not (18 <= data['age'] <= 100):
        errors.append("age must be between 18 and 100")
    if 'salary' in data and data['salary'] < 0:
        errors.append("salary cannot be negative")
    return errors

@app.route('/predict', methods=['POST'])
def predict():
    if not request.is_json:
        return jsonify({'error': 'Content-Type must be application/json'}), 400
    data = request.get_json()
    errors = validate_input(data)
    if errors:
        return jsonify({'errors': errors}), 422
    features = np.array([[data['age'], data['salary'], data['experience']]])
    pred = model.predict(features)[0]
    return jsonify({'prediction': int(pred)}), 200
```

## Example 4: Marshmallow Schema Validation
```python
from flask import Flask, request, jsonify
from marshmallow import Schema, fields, validate, ValidationError, post_load
import joblib

app = Flask(__name__)
model = joblib.load('model.pkl')

class HiringSchema(Schema):
    age = fields.Int(required=True, validate=validate.Range(min=18, max=65))
    salary = fields.Float(required=True, validate=validate.Range(min=0))
    experience = fields.Int(required=True, validate=validate.Range(min=0, max=50))
    rank = fields.Int(load_default=1, validate=validate.Range(min=1, max=10))

    @post_load
    def make_feature_array(self, data, **kwargs):
        import numpy as np
        return np.array([[data['age'], data['salary'],
                          data['experience'], data['rank']]])

schema = HiringSchema()

@app.route('/api/v1/predict', methods=['POST'])
def predict():
    try:
        features = schema.load(request.json or {})
    except ValidationError as err:
        return jsonify({'errors': err.messages}), 422
    prediction = model.predict(features)[0]
    probability = model.predict_proba(features).max()
    return jsonify({
        'prediction': int(prediction),
        'probability': round(float(probability), 4),
        'label': 'Hired' if prediction == 1 else 'Not Hired'
    })
```

## Example 5: Full sklearn Pipeline API
```python
import os
from flask import Flask, request, jsonify
import joblib
import pandas as pd
import numpy as np
import logging

logging.basicConfig(level=logging.INFO)
app = Flask(__name__)

FEATURE_COLUMNS = ['age', 'salary', 'experience', 'education_encoded']
MODEL_PATH = os.environ.get('MODEL_PATH', 'models/pipeline.pkl')

pipeline = joblib.load(MODEL_PATH)
app.logger.info(f"Pipeline loaded from {MODEL_PATH}")

EDUCATION_MAP = {'high_school': 0, 'bachelor': 1, 'master': 2, 'phd': 3}

def preprocess(raw: dict) -> pd.DataFrame:
    df = pd.DataFrame([raw])
    df['education_encoded'] = df['education'].map(EDUCATION_MAP).fillna(0)
    return df[FEATURE_COLUMNS]

@app.route('/api/v1/predict', methods=['POST'])
def predict():
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({'error': 'Invalid or missing JSON body'}), 400
    try:
        features = preprocess(data)
        prediction = pipeline.predict(features)[0]
        proba = pipeline.predict_proba(features)[0]
        return jsonify({
            'prediction': int(prediction),
            'probabilities': {str(i): round(float(p), 4)
                              for i, p in enumerate(proba)},
            'model_version': '2.1.0'
        })
    except KeyError as e:
        return jsonify({'error': f'Missing feature: {e}'}), 422
    except Exception as e:
        app.logger.error(f"Prediction error: {e}", exc_info=True)
        return jsonify({'error': 'Internal prediction error'}), 500
```

## Example 6: Logging Predictions to JSON Lines File
```python
from flask import Flask, request, jsonify
import logging
import json
import time
from datetime import datetime

app = Flask(__name__)

prediction_logger = logging.getLogger('predictions')
prediction_logger.setLevel(logging.INFO)
handler = logging.FileHandler('logs/predictions.jsonl')
prediction_logger.addHandler(handler)

def log_prediction(request_data, prediction, latency_ms, status='success'):
    record = {
        'ts': datetime.utcnow().isoformat(),
        'input': request_data,
        'prediction': prediction,
        'latency_ms': round(latency_ms, 2),
        'status': status,
        'client_ip': request.remote_addr
    }
    prediction_logger.info(json.dumps(record))

@app.route('/predict', methods=['POST'])
def predict():
    start = time.time()
    data = request.get_json()
    try:
        pred = run_model(data)
        latency = (time.time() - start) * 1000
        log_prediction(data, pred, latency)
        return jsonify({'prediction': pred, 'latency_ms': round(latency, 2)})
    except Exception as e:
        latency = (time.time() - start) * 1000
        log_prediction(data, None, latency, status='error')
        return jsonify({'error': str(e)}), 500
```

## Example 7: API Versioning with Blueprints
```python
from flask import Flask, jsonify, Blueprint

app = Flask(__name__)

# Version 1 API
v1 = Blueprint('v1', __name__, url_prefix='/api/v1')

@v1.route('/predict', methods=['POST'])
def predict_v1():
    # Original model — takes 3 features
    ...
    return jsonify({'prediction': 0, 'version': 'v1'})

# Version 2 API — new features, different schema
v2 = Blueprint('v2', __name__, url_prefix='/api/v2')

@v2.route('/predict', methods=['POST'])
def predict_v2():
    # New model — takes 5 features, returns probability
    ...
    return jsonify({'prediction': 0, 'probability': 0.92, 'version': 'v2'})

app.register_blueprint(v1)
app.register_blueprint(v2)
```

## Example 8: CORS for Frontend Integration
```python
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)

CORS(app, resources={
    r"/api/*": {
        "origins": [
            "http://localhost:3000",   # React dev server
            "https://myapp.vercel.app" # Production frontend
        ],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
    }
})

@app.route('/api/v1/predict', methods=['POST', 'OPTIONS'])
def predict():
    if request.method == 'OPTIONS':
        return '', 200  # Handle preflight
    return jsonify({'prediction': 42})
```

## Example 9: Rate Limiting ML API
```python
from flask import Flask, jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=["1000 per day", "100 per hour"],
    storage_uri="memory://"
)

@app.route('/api/v1/predict', methods=['POST'])
@limiter.limit("30 per minute")  # 30 predictions per minute per IP
def predict():
    return jsonify({'prediction': 1})

@app.route('/health')
@limiter.exempt
def health():
    return jsonify({'status': 'ok'})

@app.errorhandler(429)
def too_many_requests(e):
    return jsonify({
        'error': 'Too many requests',
        'message': 'Rate limit exceeded. Please slow down.',
        'retry_after_seconds': e.retry_after
    }), 429
```

## Example 10: Docker-Ready Flask ML App
```python
# wsgi.py
import os
from app import create_app

app = create_app(os.environ.get('FLASK_ENV', 'production'))

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

# app/__init__.py
import os
from flask import Flask
import joblib

def create_app(env='production'):
    app = Flask(__name__)
    app.config['MODEL_PATH'] = os.environ.get('MODEL_PATH', 'models/model.pkl')
    app.config['DEBUG'] = env == 'development'

    # Load model
    try:
        app.config['MODEL'] = joblib.load(app.config['MODEL_PATH'])
        app.logger.info("Model loaded successfully")
    except FileNotFoundError:
        app.logger.error("Model file not found!")
        app.config['MODEL'] = None

    from .routes import api
    app.register_blueprint(api)
    return app
```

## Example 11: A/B Testing Two Models
```python
import random
import joblib
from flask import Flask, jsonify, request

app = Flask(__name__)

models = {
    'A': {'model': joblib.load('models/model_v1.pkl'), 'weight': 0.7},
    'B': {'model': joblib.load('models/model_v2.pkl'), 'weight': 0.3},
}
metrics = {'A': {'requests': 0, 'sum_score': 0},
           'B': {'requests': 0, 'sum_score': 0}}

def select_model():
    """Weighted random selection"""
    variants = list(models.keys())
    weights = [models[v]['weight'] for v in variants]
    return random.choices(variants, weights=weights, k=1)[0]

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    variant = select_model()
    model = models[variant]['model']
    features = extract_features(data)
    prediction = model.predict([features])[0]
    probability = model.predict_proba([features]).max()

    # Track metrics
    metrics[variant]['requests'] += 1
    metrics[variant]['sum_score'] += probability

    return jsonify({
        'prediction': int(prediction),
        'probability': float(probability),
        'ab_variant': variant  # For client-side tracking
    })

@app.route('/ab-metrics')
def ab_metrics():
    result = {}
    for v, m in metrics.items():
        avg = m['sum_score'] / m['requests'] if m['requests'] > 0 else 0
        result[v] = {'requests': m['requests'], 'avg_probability': round(avg, 4)}
    return jsonify(result)
```

## Example 12: Model Reloading Without Restart
```python
from flask import Flask, jsonify
import joblib
import threading
import os
import time

app = Flask(__name__)

class ModelManager:
    def __init__(self, path):
        self.path = path
        self.model = None
        self.lock = threading.Lock()
        self.last_modified = 0
        self.load()

    def load(self):
        with self.lock:
            self.model = joblib.load(self.path)
            self.last_modified = os.path.getmtime(self.path)
            print(f"Model loaded at {time.ctime()}")

    def predict(self, features):
        # Check if model file has been updated
        current_mtime = os.path.getmtime(self.path)
        if current_mtime > self.last_modified:
            self.load()
        with self.lock:
            return self.model.predict(features)

manager = ModelManager('models/model.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    features = extract_features(request.get_json())
    return jsonify({'prediction': int(manager.predict([features])[0])})

@app.route('/reload-model', methods=['POST'])
def reload_model():
    """Admin endpoint to manually trigger reload"""
    manager.load()
    return jsonify({'status': 'reloaded'})
```

## Example 13: Training and Saving Model (hiring.csv use case)
```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
import joblib

# Load data
df = pd.read_csv('hiring.csv')
print(df.head())
print(df.dtypes)

# Preprocess
le = LabelEncoder()
df['education_encoded'] = le.fit_transform(df['education'])

FEATURES = ['age', 'salary', 'experience', 'education_encoded']
TARGET = 'hired'

X = df[FEATURES]
y = df[TARGET]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# Build pipeline
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('model', GradientBoostingClassifier(n_estimators=100, random_state=42))
])

pipeline.fit(X_train, y_train)
print(classification_report(y_test, pipeline.predict(X_test)))

# Save pipeline and encoder together
artifacts = {'pipeline': pipeline, 'label_encoder': le, 'features': FEATURES}
joblib.dump(artifacts, 'models/hiring_artifacts.pkl')
print("Artifacts saved!")
```

## Example 14: Car Price Prediction API
```python
import pandas as pd
import numpy as np
from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)
artifacts = joblib.load('models/car_price_artifacts.pkl')
pipeline = artifacts['pipeline']
FEATURES = artifacts['features']

VALID_BRANDS = ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes']
VALID_FUEL = ['Petrol', 'Diesel', 'Electric', 'Hybrid']

def validate_car(data):
    errors = []
    if data.get('brand') not in VALID_BRANDS:
        errors.append(f"brand must be one of {VALID_BRANDS}")
    if data.get('fuel_type') not in VALID_FUEL:
        errors.append(f"fuel_type must be one of {VALID_FUEL}")
    if not (0 < data.get('mileage', -1) < 500000):
        errors.append("mileage must be between 1 and 500000 km")
    if not (1990 <= data.get('year', 0) <= 2025):
        errors.append("year must be between 1990 and 2025")
    return errors

@app.route('/api/car-price', methods=['POST'])
def predict_price():
    data = request.get_json()
    errors = validate_car(data)
    if errors:
        return jsonify({'errors': errors}), 422

    df = pd.DataFrame([data])
    price = pipeline.predict(df[FEATURES])[0]
    price_range = (price * 0.9, price * 1.1)

    return jsonify({
        'estimated_price': round(float(price), 2),
        'price_range': {
            'min': round(float(price_range[0]), 2),
            'max': round(float(price_range[1]), 2)
        },
        'currency': 'USD'
    })
```

## Example 15: Batch Prediction Endpoint
```python
from flask import Flask, request, jsonify
import numpy as np
import joblib

app = Flask(__name__)
model = joblib.load('model.pkl')
MAX_BATCH_SIZE = 100

@app.route('/api/v1/batch-predict', methods=['POST'])
def batch_predict():
    data = request.get_json()
    records = data.get('records', [])

    if not records:
        return jsonify({'error': 'records list is empty'}), 400
    if len(records) > MAX_BATCH_SIZE:
        return jsonify({
            'error': f'Batch too large. Max: {MAX_BATCH_SIZE}'
        }), 400

    features = np.array([[r['age'], r['salary'], r['experience']]
                          for r in records])
    predictions = model.predict(features).tolist()
    probabilities = model.predict_proba(features).max(axis=1).tolist()

    results = [
        {
            'index': i,
            'prediction': int(p),
            'probability': round(float(pr), 4)
        }
        for i, (p, pr) in enumerate(zip(predictions, probabilities))
    ]
    return jsonify({'results': results, 'count': len(results)})
```

## Example 16: Environment-Based Configuration
```python
import os
from flask import Flask
import joblib
from dotenv import load_dotenv

load_dotenv()  # Load .env file

class Config:
    MODEL_PATH = os.environ['MODEL_PATH']
    SCALER_PATH = os.environ.get('SCALER_PATH', '')
    PREDICTION_THRESHOLD = float(os.environ.get('THRESHOLD', '0.5'))
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    MAX_BATCH_SIZE = int(os.environ.get('MAX_BATCH_SIZE', '50'))
    SECRET_KEY = os.environ['SECRET_KEY']

app = Flask(__name__)
app.config.from_object(Config)

# Load model using config
model = joblib.load(app.config['MODEL_PATH'])
```

## Example 17: Async Model Loading with Threading
```python
from flask import Flask, jsonify
import joblib
import threading
import time

app = Flask(__name__)
model_ready = threading.Event()
model = None

def load_model_async():
    global model
    app.logger.info("Loading model in background thread...")
    time.sleep(2)  # Simulate slow loading
    model = joblib.load('models/large_model.pkl')
    model_ready.set()
    app.logger.info("Model loaded!")

# Start loading in background thread
thread = threading.Thread(target=load_model_async, daemon=True)
thread.start()

@app.route('/predict', methods=['POST'])
def predict():
    if not model_ready.is_set():
        return jsonify({'error': 'Model still loading, please retry'}), 503
    data = request.get_json()
    return jsonify({'prediction': float(model.predict([[data['x']]])[0])})
```

## Example 18: Request/Response Logging Middleware
```python
from flask import Flask, request, g
import logging
import time
import uuid

app = Flask(__name__)
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                    level=logging.INFO)

@app.before_request
def before():
    g.start = time.time()
    g.request_id = str(uuid.uuid4())[:8]

@app.after_request
def after(response):
    duration_ms = (time.time() - g.start) * 1000
    app.logger.info(
        f"[{g.request_id}] {request.method} {request.path} "
        f"-> {response.status_code} in {duration_ms:.1f}ms "
        f"| IP={request.remote_addr}"
    )
    response.headers['X-Request-ID'] = g.request_id
    return response
```

## Example 19: Feature Importance Endpoint
```python
from flask import Flask, jsonify
import joblib
import numpy as np

app = Flask(__name__)
model = joblib.load('models/rf_model.pkl')
FEATURES = ['age', 'salary', 'experience', 'education', 'rank']

@app.route('/model/features', methods=['GET'])
def feature_importance():
    """Return model feature importance scores"""
    importances = model.feature_importances_
    feature_scores = sorted(
        zip(FEATURES, importances),
        key=lambda x: x[1],
        reverse=True
    )
    return jsonify({
        'feature_importance': [
            {'feature': f, 'importance': round(float(i), 4)}
            for f, i in feature_scores
        ],
        'model_type': type(model).__name__,
    })

@app.route('/model/info', methods=['GET'])
def model_info():
    return jsonify({
        'type': type(model).__name__,
        'n_estimators': getattr(model, 'n_estimators', None),
        'features': FEATURES,
        'n_features': len(FEATURES),
    })
```

## Example 20: Full Production Flask ML API
```python
import os, time, logging, joblib
from flask import Flask, request, jsonify, g
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import numpy as np

logging.basicConfig(level=logging.INFO)

def create_app():
    app = Flask(__name__)
    CORS(app, origins=os.environ.get('CORS_ORIGINS', '*').split(','))

    limiter = Limiter(key_func=get_remote_address, app=app,
                      default_limits=["500/day", "50/hour"])

    model_path = os.environ.get('MODEL_PATH', 'models/model.pkl')
    try:
        app.config['MODEL'] = joblib.load(model_path)
        app.logger.info(f"Model loaded: {model_path}")
    except Exception as e:
        app.logger.error(f"Model load failed: {e}")
        app.config['MODEL'] = None

    @app.before_request
    def start_timer():
        g.t0 = time.time()

    @app.after_request
    def add_timing(response):
        ms = (time.time() - g.t0) * 1000
        response.headers['X-Process-Time'] = f"{ms:.1f}ms"
        return response

    @app.route('/health')
    @limiter.exempt
    def health():
        return jsonify({'status': 'ok', 'model': app.config['MODEL'] is not None})

    @app.route('/api/v1/predict', methods=['POST'])
    @limiter.limit("30/minute")
    def predict():
        if app.config['MODEL'] is None:
            return jsonify({'error': 'Model unavailable'}), 503
        data = request.get_json(silent=True)
        if not data:
            return jsonify({'error': 'Invalid JSON'}), 400
        try:
            features = np.array([[data['age'], data['salary'], data['experience']]])
            pred = app.config['MODEL'].predict(features)[0]
            prob = app.config['MODEL'].predict_proba(features).max()
            return jsonify({
                'prediction': int(pred),
                'probability': round(float(prob), 4),
                'latency_ms': round((time.time()-g.t0)*1000, 2)
            })
        except KeyError as e:
            return jsonify({'error': f'Missing field: {e}'}), 422
        except Exception as e:
            app.logger.error(f"Predict error: {e}", exc_info=True)
            return jsonify({'error': 'Prediction failed'}), 500

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'error': 'Endpoint not found'}), 404

    @app.errorhandler(429)
    def too_many(e):
        return jsonify({'error': 'Rate limit exceeded'}), 429

    return app

app = create_app()
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
```