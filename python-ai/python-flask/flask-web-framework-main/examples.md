# Flask — 20+ Annotated Code Examples

## Example 1: Minimal Flask App
```python
from flask import Flask

app = Flask(__name__)  # __name__ helps Flask find templates/static

@app.route('/')
def index():
    return 'Hello, Flask!'

if __name__ == '__main__':
    app.run(debug=True)  # debug=True enables auto-reload and debugger
```

## Example 2: Multiple Routes and Methods
```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Home Page</h1>'

@app.route('/about')
def about():
    return '<h1>About Page</h1>'

@app.route('/user/<string:name>')         # string variable rule
def user_profile(name):
    return f'<h1>User: {name}</h1>'

@app.route('/post/<int:post_id>')         # integer variable rule
def show_post(post_id):
    return f'<p>Post #{post_id}</p>'

@app.route('/search')
def search():
    q = request.args.get('q', '')         # GET /search?q=python
    return f'<p>Results for: {q}</p>'

@app.route('/submit', methods=['GET', 'POST'])
def submit():
    if request.method == 'POST':
        data = request.form.get('data')
        return f'<p>Received: {data}</p>'
    return '<form method="POST"><input name="data"><button>Submit</button></form>'
```

## Example 3: JSON API Endpoints
```python
from flask import Flask, jsonify, request, abort

app = Flask(__name__)

# In-memory "database"
users = [
    {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': 2, 'name': 'Bob',   'email': 'bob@example.com'},
]

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({'users': users, 'count': len(users)})

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((u for u in users if u['id'] == user_id), None)
    if not user:
        abort(404)  # Raises 404 HTTPException
    return jsonify(user)

@app.route('/api/users', methods=['POST'])
def create_user():
    if not request.is_json:
        return jsonify({'error': 'Content-Type must be application/json'}), 400
    data = request.get_json()
    if not data.get('name') or not data.get('email'):
        return jsonify({'error': 'name and email are required'}), 422
    new_user = {'id': len(users) + 1, 'name': data['name'], 'email': data['email']}
    users.append(new_user)
    return jsonify(new_user), 201

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    global users
    users = [u for u in users if u['id'] != user_id]
    return '', 204  # 204 No Content
```

## Example 4: Jinja2 Templates with Template Inheritance
```python
# app.py
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def home():
    posts = [
        {'title': 'Flask Basics', 'views': 120, 'tags': ['flask', 'python']},
        {'title': 'Jinja2 Templates', 'views': 85, 'tags': ['jinja2']},
    ]
    return render_template('home.html', posts=posts, page_title='Blog')
```

```html
<!-- templates/base.html -->
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}Site{% endblock %}</title>
  <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
  <nav>
    <a href="{{ url_for('home') }}">Home</a>
  </nav>
  <main>
    {% with messages = get_flashed_messages(with_categories=True) %}
      {% for category, msg in messages %}
        <div class="alert {{ category }}">{{ msg }}</div>
      {% endfor %}
    {% endwith %}
    {% block content %}{% endblock %}
  </main>
</body>
</html>

<!-- templates/home.html -->
{% extends "base.html" %}
{% block title %}{{ page_title }}{% endblock %}
{% block content %}
  <h1>Latest Posts</h1>
  {% for post in posts %}
    <article>
      <h2>{{ post.title | title }}</h2>
      <p>Views: {{ post.views }}</p>
      {% for tag in post.tags %}
        <span class="tag">{{ tag }}</span>
      {% endfor %}
    </article>
  {% else %}
    <p>No posts yet.</p>
  {% endfor %}
{% endblock %}
```

## Example 5: Flask Sessions and Flash Messages
```python
from flask import Flask, session, flash, redirect, url_for, render_template, request
from datetime import timedelta

app = Flask(__name__)
app.secret_key = 'my-secret-key'
app.permanent_session_lifetime = timedelta(days=7)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username == 'admin' and password == 'password':
            session.permanent = True
            session['user'] = username
            flash('Login successful!', 'success')
            return redirect(url_for('dashboard'))
        flash('Invalid credentials.', 'danger')
    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        flash('Please log in first.', 'warning')
        return redirect(url_for('login'))
    return render_template('dashboard.html', user=session['user'])

@app.route('/logout')
def logout():
    user = session.pop('user', None)
    flash(f'Goodbye, {user}!', 'info')
    return redirect(url_for('login'))
```

## Example 6: Blueprint — Auth Module
```python
# auth/__init__.py  (empty)

# auth/routes.py
from flask import Blueprint, render_template, redirect, url_for, flash, request, session
from functools import wraps

auth = Blueprint('auth', __name__, url_prefix='/auth',
                 template_folder='templates')

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return decorated

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # validate credentials
        session['user_id'] = 1
        return redirect(url_for('main.index'))
    return render_template('auth/login.html')

@auth.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect(url_for('auth.login'))

# app/__init__.py
def create_app():
    app = Flask(__name__)
    app.secret_key = 'dev'
    from .auth.routes import auth
    app.register_blueprint(auth)
    return app
```

## Example 7: File Upload
```python
import os
from flask import Flask, request, redirect, url_for, jsonify
from werkzeug.utils import secure_filename

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf', 'csv'}

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    if not allowed_file(file.filename):
        return jsonify({'error': f'File type not allowed'}), 400
    filename = secure_filename(file.filename)  # Sanitize filename
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)
    return jsonify({'filename': filename, 'size': os.path.getsize(filepath)}), 201
```

## Example 8: Flask with SQLAlchemy
```python
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///todos.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    done = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {'id': self.id, 'title': self.title, 'done': self.done}

with app.app_context():
    db.create_all()

@app.route('/todos', methods=['GET'])
def get_todos():
    todos = Todo.query.all()
    return jsonify([t.to_dict() for t in todos])

@app.route('/todos', methods=['POST'])
def create_todo():
    data = request.get_json()
    todo = Todo(title=data['title'])
    db.session.add(todo)
    db.session.commit()
    return jsonify(todo.to_dict()), 201

@app.route('/todos/<int:id>', methods=['PUT'])
def update_todo(id):
    todo = Todo.query.get_or_404(id)
    data = request.get_json()
    todo.title = data.get('title', todo.title)
    todo.done = data.get('done', todo.done)
    db.session.commit()
    return jsonify(todo.to_dict())

@app.route('/todos/<int:id>', methods=['DELETE'])
def delete_todo(id):
    todo = Todo.query.get_or_404(id)
    db.session.delete(todo)
    db.session.commit()
    return '', 204
```

## Example 9: Error Handlers
```python
from flask import Flask, jsonify, render_template

app = Flask(__name__)

@app.errorhandler(400)
def bad_request(e):
    if request.accept_mimetypes.best == 'application/json':
        return jsonify({'error': 'Bad Request', 'message': str(e)}), 400
    return render_template('errors/400.html'), 400

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Not Found', 'message': str(e)}), 404

@app.errorhandler(500)
def internal_error(e):
    db.session.rollback()  # Reset DB session
    return jsonify({'error': 'Internal Server Error'}), 500

# Custom exception
class APIException(Exception):
    def __init__(self, message, status_code=400):
        self.message = message
        self.status_code = status_code

@app.errorhandler(APIException)
def handle_api_exception(e):
    return jsonify({'error': e.message}), e.status_code
```

## Example 10: Before/After Request Hooks
```python
from flask import Flask, g, request, jsonify
import time
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.before_request
def start_timer():
    g.start_time = time.time()
    g.request_id = request.headers.get('X-Request-ID', 'N/A')

@app.after_request
def log_request(response):
    duration = (time.time() - g.start_time) * 1000
    logging.info(
        f"{request.method} {request.path} "
        f"{response.status_code} {duration:.1f}ms"
    )
    response.headers['X-Request-ID'] = g.request_id
    response.headers['X-Response-Time'] = f"{duration:.1f}ms"
    return response

@app.teardown_appcontext
def shutdown_db(exception=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()
```

## Example 11: Application Factory with Config Classes
```python
# config.py
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///dev.db'

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///prod.db')

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

# app/__init__.py
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    db.init_app(app)
    with app.app_context():
        db.create_all()
    from .api import api as api_blueprint
    app.register_blueprint(api_blueprint, url_prefix='/api/v1')
    return app
```

## Example 12: JWT Authentication (without Flask-Login)
```python
from flask import Flask, jsonify, request
import jwt
import datetime
from functools import wraps

app = Flask(__name__)
SECRET = 'supersecret'

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return jsonify({'error': 'Token missing'}), 401
        try:
            data = jwt.decode(token, SECRET, algorithms=['HS256'])
            current_user = data['sub']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if data.get('username') == 'admin' and data.get('password') == 'admin':
        token = jwt.encode({
            'sub': data['username'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, SECRET, algorithm='HS256')
        return jsonify({'token': token})
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/protected')
@token_required
def protected(current_user):
    return jsonify({'message': f'Hello, {current_user}!'})
```

## Example 13: Flask REST API with Pagination
```python
from flask import Flask, jsonify, request
from math import ceil

app = Flask(__name__)
# Simulate database
ITEMS = [{'id': i, 'name': f'Item {i}', 'value': i * 10} for i in range(1, 101)]

@app.route('/api/items')
def get_items():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    per_page = min(per_page, 100)  # Cap at 100

    total = len(ITEMS)
    start = (page - 1) * per_page
    end = start + per_page
    items_page = ITEMS[start:end]

    return jsonify({
        'items': items_page,
        'meta': {
            'page': page,
            'per_page': per_page,
            'total': total,
            'pages': ceil(total / per_page),
            'has_next': end < total,
            'has_prev': start > 0,
        }
    })
```

## Example 14: Flask with WTForms (CSRF-protected)
```python
from flask import Flask, render_template, redirect, url_for
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, TextAreaField, SelectField
from wtforms.validators import DataRequired, Email, Length, EqualTo

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret'
app.config['WTF_CSRF_ENABLED'] = True

class RegisterForm(FlaskForm):
    username = StringField('Username', validators=[
        DataRequired(), Length(min=3, max=30)
    ])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[
        DataRequired(), Length(min=8)
    ])
    confirm = PasswordField('Confirm Password', validators=[
        DataRequired(), EqualTo('password', message='Passwords must match')
    ])
    bio = TextAreaField('Bio', validators=[Length(max=500)])
    role = SelectField('Role', choices=[
        ('user', 'Regular User'),
        ('admin', 'Administrator')
    ])

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm()
    if form.validate_on_submit():
        # form.username.data, form.email.data etc.
        return redirect(url_for('login'))
    return render_template('register.html', form=form)
```

## Example 15: Flask Caching with flask-caching
```python
from flask import Flask, jsonify
from flask_caching import Cache
import time

app = Flask(__name__)
cache = Cache(app, config={
    'CACHE_TYPE': 'SimpleCache',
    'CACHE_DEFAULT_TIMEOUT': 300  # 5 minutes
})

@app.route('/expensive-data')
@cache.cached(timeout=60, key_prefix='expensive_data')
def expensive_data():
    time.sleep(2)  # Simulate slow computation
    return jsonify({'data': [1, 2, 3, 4, 5], 'timestamp': time.time()})

@app.route('/user/<int:id>')
@cache.cached(timeout=120, key_prefix=lambda: f'user_{request.view_args["id"]}')
def get_user(id):
    return jsonify({'id': id, 'name': 'Alice'})

@app.route('/clear-cache')
def clear_cache():
    cache.clear()
    return jsonify({'message': 'Cache cleared'})
```

## Example 16: CORS with Flask-CORS
```python
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)

# Allow all origins (development only)
CORS(app)

# Production: specific origins
CORS(app, resources={
    r"/api/*": {
        "origins": ["https://myapp.com", "https://staging.myapp.com"],
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "allow_headers": ["Content-Type", "Authorization"],
        "expose_headers": ["X-Total-Count"],
        "max_age": 600  # preflight cache seconds
    }
})

@app.route('/api/data')
def data():
    return jsonify({'result': 'data accessible from CORS-listed origins'})
```

## Example 17: Flask + Celery for Async Tasks
```python
from flask import Flask, jsonify
from celery import Celery
import time

app = Flask(__name__)
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'

celery = Celery(app.name, broker=app.config['CELERY_BROKER_URL'])
celery.conf.update(app.config)

@celery.task(bind=True)
def send_email_task(self, email: str, subject: str):
    try:
        time.sleep(3)  # Simulate sending email
        return {'status': 'sent', 'email': email}
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60, max_retries=3)

@app.route('/send-email', methods=['POST'])
def trigger_email():
    data = request.get_json()
    task = send_email_task.delay(data['email'], data['subject'])
    return jsonify({'task_id': task.id, 'status': 'queued'}), 202

@app.route('/task/<task_id>')
def task_status(task_id):
    task = send_email_task.AsyncResult(task_id)
    return jsonify({
        'task_id': task_id,
        'status': task.status,
        'result': task.result if task.ready() else None
    })
```

## Example 18: Rate Limiting
```python
from flask import Flask, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://"
)

@app.route('/api/predict', methods=['POST'])
@limiter.limit("10 per minute")
def predict():
    return jsonify({'prediction': 42})

@app.route('/api/public')
@limiter.exempt  # No rate limit
def public():
    return jsonify({'message': 'Public endpoint'})

@app.errorhandler(429)
def too_many_requests(e):
    return jsonify({'error': 'Rate limit exceeded', 'retry_after': str(e.retry_after)}), 429
```

## Example 19: Streaming Responses
```python
from flask import Flask, Response, stream_with_context
import time

app = Flask(__name__)

def generate_data():
    """Generator function for streaming"""
    for i in range(10):
        yield f"data: Event {i}\n\n"  # SSE format
        time.sleep(0.5)

@app.route('/stream')
def stream():
    return Response(
        stream_with_context(generate_data()),
        content_type='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no'  # Disable nginx buffering
        }
    )

# Streaming large CSV
@app.route('/export-csv')
def export_csv():
    def generate_csv():
        yield 'id,name,value\n'
        for i in range(100000):
            yield f'{i},Item {i},{i * 1.5}\n'

    return Response(
        generate_csv(),
        mimetype='text/csv',
        headers={'Content-Disposition': 'attachment; filename=data.csv'}
    )
```

## Example 20: Testing Flask Apps with pytest
```python
import pytest
from app import create_app
from app.models import db, User

@pytest.fixture
def app():
    app = create_app({'TESTING': True, 'SQLALCHEMY_DATABASE_URI': 'sqlite://'})
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def auth_client(client):
    """Logged-in client"""
    client.post('/auth/login', json={'username': 'admin', 'password': 'admin'})
    return client

def test_homepage(client):
    rv = client.get('/')
    assert rv.status_code == 200

def test_create_user(client):
    rv = client.post('/api/users', json={'name': 'Alice', 'email': 'alice@test.com'})
    assert rv.status_code == 201
    data = rv.get_json()
    assert data['name'] == 'Alice'

def test_unauthorized_access(client):
    rv = client.get('/api/protected')
    assert rv.status_code == 401

def test_get_user_404(client):
    rv = client.get('/api/users/9999')
    assert rv.status_code == 404

def test_form_submission(client):
    rv = client.post('/submit', data={'title': 'Hello', 'content': 'World'})
    assert rv.status_code in [200, 302]
```

## Example 21: Flask with make_response and custom headers
```python
from flask import Flask, make_response, jsonify

app = Flask(__name__)

@app.route('/api/data')
def get_data():
    data = {'key': 'value', 'items': [1, 2, 3]}
    response = make_response(jsonify(data))
    response.headers['Cache-Control'] = 'public, max-age=300'
    response.headers['X-Total-Count'] = '3'
    response.headers['X-API-Version'] = '1.0'
    response.status_code = 200
    return response

@app.route('/download')
def download():
    content = "col1,col2\nval1,val2\n"
    response = make_response(content)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=export.csv'
    return response
```

## Example 22: Context Processors (Template Globals)
```python
from flask import Flask, g
from datetime import datetime

app = Flask(__name__)

@app.context_processor
def inject_globals():
    """These variables are available in ALL templates"""
    return {
        'current_year': datetime.now().year,
        'app_name': 'My Flask App',
        'current_user': g.get('user', None),
    }

@app.template_filter('datetimeformat')
def datetimeformat(value, format='%Y-%m-%d %H:%M'):
    """Custom Jinja2 filter: {{ post.created_at | datetimeformat }}"""
    return value.strftime(format)
```