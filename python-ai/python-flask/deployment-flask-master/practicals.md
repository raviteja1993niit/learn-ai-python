# Flask ML Deployment — 10 Hands-On Projects

## Project 1: Deploy the hiring.csv Model
**Goal**: Train a model on hiring.csv and serve it via Flask API

### Steps
1. Load hiring.csv into a DataFrame
2. Explore: `df.info()`, `df.describe()`, `df.isnull().sum()`
3. Encode categorical features (education, department)
4. Train/test split (80/20, stratified)
5. Train 3 models: Logistic Regression, Random Forest, Gradient Boosting
6. Compare with cross-validation
7. Save the best pipeline: `joblib.dump(pipeline, 'models/hiring_pipeline.pkl')`
8. Build Flask API with `/predict`, `/health`, `/model/info`

### API Contract
```json
// POST /predict
// Input
{"age": 30, "experience": 5, "salary": 70000, "education": "bachelor"}
// Output
{"prediction": 1, "label": "Hired", "probability": 0.87, "model": "GradientBoosting"}
```

### Validation Rules
- age: 18–65, required
- experience: 0–50, required
- salary: > 0, required
- education: one of [high_school, bachelor, master, phd]

### Testing
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"age": 28, "experience": 3, "salary": 55000, "education": "bachelor"}'
```

---

## Project 2: Car Price Prediction API
**Goal**: Build and deploy a car price prediction API

### Dataset
Use the Car Price dataset (car_data.csv) with features:
- Year, Selling_Price, Present_Price, Kms_Driven, Fuel_Type, Seller_Type, Transmission, Owner

### Steps
1. Feature engineering: create `car_age = 2024 - year`
2. Encode: Fuel_Type, Seller_Type, Transmission (LabelEncoder or OneHotEncoder)
3. Train RandomForestRegressor or GradientBoostingRegressor
4. Evaluate with RMSE, R²
5. Build regression API: returns predicted price + price range (±10%)

### API Endpoint
```python
@app.route('/api/predict-price', methods=['POST'])
def predict_price():
    # Returns: {"price_inr": 425000, "range": {"min": 382500, "max": 467500}}
```

---

## Project 3: Complete ML API with Versioning
**Goal**: Production-ready API with v1 and v2 endpoints

### Requirements
- Two model versions (e.g., Logistic Regression v1, Random Forest v2)
- Blueprint-based versioning: `/api/v1/predict`, `/api/v2/predict`
- v1: simple 3-feature input
- v2: 5-feature input, returns probability per class
- `/api/latest` redirects to v2
- `/api/versions` lists available versions with descriptions

### Structure
```
app/
├── __init__.py          # create_app() factory
├── models/
│   ├── v1_model.pkl
│   └── v2_model.pkl
├── api/
│   ├── v1/routes.py     # Blueprint for v1
│   └── v2/routes.py     # Blueprint for v2
└── config.py
```

---

## Project 4: Model Monitoring Dashboard
**Goal**: Log and visualize prediction patterns

### Steps
1. Log every prediction to a SQLite database:
   - timestamp, input_features (JSON), prediction, probability, latency_ms
2. Build monitoring endpoints:
   - `GET /monitoring/summary` — prediction distribution, avg latency
   - `GET /monitoring/drift` — compare recent inputs to training distribution
   - `GET /monitoring/errors` — failed prediction requests

### Hints
```python
class PredictionLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    inputs = db.Column(db.JSON)
    prediction = db.Column(db.Integer)
    probability = db.Column(db.Float)
    latency_ms = db.Column(db.Float)
    status = db.Column(db.String(20), default='success')
```

---

## Project 5: Dockerized ML API
**Goal**: Containerize your Flask ML app for deployment

### Steps
1. Write a working Flask ML API (use the hiring model)
2. Write a `Dockerfile`:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "wsgi:app"]
```
3. Write `docker-compose.yml` with the API service
4. Test: `docker-compose up`, then curl the API
5. Add a `.dockerignore` file

### Validation
```bash
docker build -t ml-api .
docker run -p 5000:5000 -e MODEL_PATH=/app/models/model.pkl ml-api
curl http://localhost:5000/health
```

---

## Project 6: A/B Testing Framework
**Goal**: Serve two models and track performance metrics

### Requirements
- Load model_v1 and model_v2 at startup
- 70/30 traffic split (configurable via env var)
- Track per-variant: request count, avg probability, avg latency
- `/api/ab-stats` endpoint showing comparison
- `/api/ab-config` POST to change traffic split without restart

### Hints
```python
import os, random, threading

class ABManager:
    def __init__(self):
        self.models = {'A': load_model('v1'), 'B': load_model('v2')}
        self.split = float(os.environ.get('AB_SPLIT', '0.7'))
        self.stats = {'A': Counter(), 'B': Counter()}
        self.lock = threading.Lock()

    def predict(self, features):
        variant = 'A' if random.random() < self.split else 'B'
        model = self.models[variant]
        return variant, model.predict([features])[0]
```

---

## Project 7: Batch Prediction API
**Goal**: Accept CSV files and return predictions for all rows

### Endpoint: POST /batch-predict (multipart/form-data)
- Accept a CSV file upload
- Validate columns match model's expected features
- Run predictions for all rows (up to 10,000)
- Return results as downloadable CSV
- Track job status for large files (async processing)

### Hints
```python
from io import StringIO

@app.route('/batch-predict', methods=['POST'])
def batch_predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file'}), 400
    df = pd.read_csv(StringIO(request.files['file'].read().decode('utf-8')))
    # Validate columns, run pipeline.predict(df[FEATURES])
    # Return CSV response
```

---

## Project 8: Rate-Limited API with API Keys
**Goal**: Secure your ML API with API key authentication and per-key rate limits

### Requirements
- Store API keys in SQLite with tier (free/pro/enterprise)
- Per-tier limits: free=100/day, pro=1000/day, enterprise=unlimited
- Check API key on every request via `X-API-Key` header
- Track usage per key in the database
- `GET /api/usage` — current user's usage stats

### Hints
```python
class APIKey(db.Model):
    key = db.Column(db.String(64), primary_key=True)
    owner = db.Column(db.String(100))
    tier = db.Column(db.String(20), default='free')
    daily_limit = db.Column(db.Integer, default=100)
    requests_today = db.Column(db.Integer, default=0)
    last_reset = db.Column(db.Date, default=date.today)
```

---

## Project 9: Model Health and Alerting System
**Goal**: Build automated model health checks

### Checks to Implement
1. **Data drift detection**: Compare incoming feature distributions to training baseline
   - Use statistical test (KS test) for numeric features
   - Alert if p-value < 0.05
2. **Prediction drift**: Alert if prediction distribution shifts by > 10%
3. **Latency alerting**: Alert if 95th percentile latency > 500ms
4. **Error rate**: Alert if error rate > 1%

### Alert System
```python
def check_drift(recent_age_values, baseline_mean, baseline_std):
    from scipy import stats
    z_score = abs(np.mean(recent_age_values) - baseline_mean) / baseline_std
    return z_score > 2.0  # Alert if more than 2 std devs away
```

---

## Project 10: Full Production Deploy to Render/Railway
**Goal**: Deploy your Flask ML API to a cloud platform

### Steps
1. Prepare app:
   - Use environment variables for all secrets
   - Add `requirements.txt` with pinned versions
   - Add `Procfile`: `web: gunicorn wsgi:app --workers 2`
   - Add `runtime.txt`: `python-3.11.0`

2. Database:
   - Use PostgreSQL (not SQLite) for production
   - Add `psycopg2-binary` to requirements
   - Use `DATABASE_URL` environment variable

3. Deploy to Render:
   - Create Web Service from GitHub repo
   - Add environment variables in dashboard
   - Add Health Check URL: `/health`

4. Post-deploy verification:
```bash
# Test production API
curl https://my-ml-api.onrender.com/health
curl -X POST https://my-ml-api.onrender.com/predict \
  -H "Content-Type: application/json" \
  -d '{"age": 30, "salary": 70000, "experience": 5, "education": "bachelor"}'
```

### Checklist
- [ ] DEBUG=False in production
- [ ] SECRET_KEY from environment variable
- [ ] Logging to stdout (Railway/Render collect logs)
- [ ] Health check endpoint responds in < 1s
- [ ] Model file included in deployment or loaded from cloud storage