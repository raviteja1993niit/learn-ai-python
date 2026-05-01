# Flask — 10 Hands-On Projects & Exercises

## Project 1: Todo App (Beginner)
**Goal**: Build a full CRUD Todo app with Flask + SQLite

### Requirements
- Create todos (POST /todos) with title and optional description
- List all todos (GET /todos) with filtering by status (done/pending)
- Mark todo as done (PUT /todos/<id>)
- Delete todo (DELETE /todos/<id>)
- Simple HTML frontend using Jinja2 templates

### Hints
```python
# Model
class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, default="")
    done = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```
- Use `Flask-SQLAlchemy` for the ORM
- Use `flash()` for success/error messages
- Redirect after POST (PRG pattern) to avoid form resubmission

### Extension
- Add due dates and priority levels (high/medium/low)
- Add categories with many-to-many relationship
- Deploy to Render or Railway

---

## Project 2: REST Blog API (Beginner-Intermediate)
**Goal**: Build a JSON REST API for a blog — no HTML, pure JSON

### Endpoints to Implement
```
GET    /api/posts             - List with ?page=1&per_page=10&q=search
POST   /api/posts             - Create (requires auth header)
GET    /api/posts/<id>        - Get single post
PUT    /api/posts/<id>        - Update (owner only)
DELETE /api/posts/<id>        - Delete (owner only)
GET    /api/posts/<id>/comments
POST   /api/posts/<id>/comments
```

### Hints
- Return proper HTTP status codes (201 for create, 204 for delete)
- Implement simple API key auth via `X-API-Key` header
- Use `request.get_json(silent=True)` and validate manually
- Return consistent error format: `{"error": "...", "message": "..."}`

### Bonus
- Add full-text search using SQLite `LIKE`
- Add rate limiting with `flask-limiter`
- Write 10 test cases using `pytest` and `app.test_client()`

---

## Project 3: User Authentication System (Intermediate)
**Goal**: Full user auth with registration, login, logout, password reset

### Features
- User registration with email validation
- Password hashing with `werkzeug.security`
- Login with JWT token (PyJWT)
- Protected routes with `@login_required` decorator
- Password reset via email token (use `itsdangerous.URLSafeTimedSerializer`)
- "Remember me" checkbox extending session lifetime

### Schema
```python
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```

### Hints
- `generate_password_hash(password)` / `check_password_hash(hash, password)`
- For password reset: `s.dumps(email, salt='reset')` / `s.loads(token, max_age=3600)`
- Use `@wraps` for the decorator to preserve function metadata

---

## Project 4: File Upload & Management (Intermediate)
**Goal**: Build a file hosting service API

### Features
- Upload single/multiple files (POST /upload)
- List uploaded files (GET /files) with metadata (size, type, upload date)
- Download file by ID (GET /files/<id>/download)
- Delete file (DELETE /files/<id>)
- File type restrictions (allowed: images, PDF, CSV, DOCX)
- File size limit (configurable via env var)
- Generate unique filenames to avoid collisions

### Hints
```python
import uuid
from werkzeug.utils import secure_filename

def save_file(file):
    ext = file.filename.rsplit('.', 1)[1].lower()
    unique_name = f"{uuid.uuid4().hex}.{ext}"
    file.save(os.path.join(UPLOAD_FOLDER, unique_name))
    return unique_name
```

### Extension
- Store file metadata in SQLite
- Generate image thumbnails with Pillow
- Add virus scanning (mock implementation)

---

## Project 5: ML Model Prediction API (Intermediate)
**Goal**: Wrap a trained sklearn model with a Flask REST API

### Steps
1. Train a classifier on the `iris` or `breast cancer` dataset
2. Save with `joblib.dump(model, 'model.pkl')`
3. Build Flask API with:
   - `POST /predict` — accepts JSON, returns prediction + probability
   - `GET /health` — model status, version, uptime
   - `GET /model/info` — feature names, model type, accuracy

### Input/Output
```json
// Input
{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}

// Output
{"prediction": "setosa", "probability": 0.97, "model_version": "1.0.0"}
```

### Hints
- Validate all 4 features are present and numeric
- Return 422 for validation errors, 503 if model not loaded
- Log each prediction to a JSON lines file
- Add `@functools.lru_cache` or load model in `create_app()`

---

## Project 6: URL Shortener (Intermediate)
**Goal**: Build a bit.ly clone

### Features
- `POST /shorten` — accepts `{"url": "https://very-long.url/path"}`, returns short code
- `GET /<code>` — redirect to original URL (301 permanent)
- `GET /stats/<code>` — click count, created date, original URL
- Input validation: check URL is valid using `validators` library

### Hints
```python
import string, random

def generate_code(length=6):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choices(chars, k=length))
```
- Check for collision before inserting
- Track clicks in a separate `clicks` table with timestamp and IP

---

## Project 7: Quiz App (Intermediate)
**Goal**: REST API for a multiple-choice quiz system

### Endpoints
```
GET  /api/quizzes           - List available quizzes
POST /api/quizzes           - Create quiz (with questions)
GET  /api/quizzes/<id>      - Get quiz with questions (hide answers)
POST /api/quizzes/<id>/submit - Submit answers, get score
GET  /api/leaderboard       - Top scores
```

### Data Model
```python
# Quiz → Questions → Options (one correct per question)
# Score = (correct_answers / total_questions) * 100
```

### Hints
- Use nested JSON for quiz creation (quiz with embedded questions/options)
- Validate answers server-side, never trust client
- Store quiz attempts with user_id, score, timestamp

---

## Project 8: Weather Dashboard API (Intermediate)
**Goal**: Proxy and cache weather data from OpenWeatherMap API

### Features
- `GET /weather/<city>` — current weather (cached 10 minutes)
- `GET /forecast/<city>` — 5-day forecast
- Rate limiting (10 requests/minute per IP)
- Cache using `Flask-Caching` with SimpleCache backend

### Hints
```python
import requests

WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather"
API_KEY = os.environ["OPENWEATHER_API_KEY"]

@cache.cached(timeout=600, key_prefix=lambda: f"weather_{request.view_args['city']}")
def get_weather(city):
    resp = requests.get(WEATHER_URL, params={"q": city, "appid": API_KEY, "units": "metric"})
    resp.raise_for_status()
    return resp.json()
```

---

## Project 9: E-commerce Cart API (Advanced)
**Goal**: Shopping cart backend with products, cart, and orders

### Models
```
Product: id, name, price, stock, category
Cart: id, user_id, created_at
CartItem: cart_id, product_id, quantity
Order: id, user_id, total, status, created_at
OrderItem: order_id, product_id, quantity, price_at_time
```

### Endpoints
```
GET    /products              - Browse products with filters
POST   /cart/items            - Add to cart
GET    /cart                  - View cart with subtotals
DELETE /cart/items/<id>       - Remove from cart
POST   /orders                - Checkout (cart → order, deduct stock)
GET    /orders/<id>           - Order status
```

### Hints
- Use database transactions for checkout (atomic: deduct stock + create order)
- Validate stock availability before checkout
- Calculate `price_at_time` to preserve price history

---

## Project 10: Background Job Queue (Advanced)
**Goal**: Async task system with Flask + threading/Celery

### Features
- `POST /jobs` — submit a job (data processing task)
- `GET /jobs/<id>` — check job status (pending/running/done/failed)
- `GET /jobs` — list all jobs with status
- Jobs run in background (use threading.Thread or Celery)
- Jobs update their own status in the database

### Hints
```python
import threading

def run_job(job_id, params):
    with app.app_context():
        job = Job.query.get(job_id)
        job.status = 'running'
        db.session.commit()
        try:
            result = process_data(params)
            job.result = json.dumps(result)
            job.status = 'done'
        except Exception as e:
            job.error = str(e)
            job.status = 'failed'
        finally:
            db.session.commit()

@app.route('/jobs', methods=['POST'])
def submit_job():
    job = Job(status='pending', params=json.dumps(request.json))
    db.session.add(job)
    db.session.commit()
    t = threading.Thread(target=run_job, args=(job.id, request.json))
    t.start()
    return jsonify({'job_id': job.id}), 202
```

### Extension
- Use Celery + Redis as the task broker
- Add job retries with exponential backoff
- Add webhook notifications when jobs complete