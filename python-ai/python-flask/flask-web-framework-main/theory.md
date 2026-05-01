# Flask Fundamentals — Theory & Concepts

## 1. What is Flask?
Flask is a lightweight WSGI web framework written in Python by Armin Ronacher.
It is classified as a **micro-framework** because it keeps the core simple and extensible,
providing only routing, request handling, and templating out of the box.

### Flask vs Django
| Feature              | Flask                        | Django                       |
|----------------------|------------------------------|------------------------------|
| Philosophy           | Micro, minimal, explicit     | Batteries-included, opinionated |
| ORM                  | No built-in (use SQLAlchemy) | Built-in ORM                 |
| Admin panel          | No (use Flask-Admin)         | Auto-generated admin         |
| Forms                | No (use WTForms)             | Built-in forms framework     |
| Auth                 | No (use Flask-Login)         | Built-in auth system         |
| Learning curve       | Low                          | Medium-High                  |
| Best for             | APIs, small-medium apps      | Full-stack content sites     |

## 2. Application Factory Pattern
The factory pattern creates the Flask app inside a function, enabling multiple
configurations (testing, production) and avoiding circular imports.

```python
# app/__init__.py
from flask import Flask

def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Register extensions
    db.init_app(app)
    login_manager.init_app(app)

    # Register blueprints
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app
```

`Flask(__name__)` — `__name__` tells Flask where to find templates and static files
relative to the module.

## 3. Routes and URL Rules
Routes map URLs to Python functions (view functions).

```python
@app.route('/')                          # GET only by default
@app.route('/about')
@app.route('/user/<username>')           # string variable rule
@app.route('/post/<int:post_id>')        # integer converter
@app.route('/file/<path:filepath>')      # path converter (includes slashes)
@app.route('/submit', methods=['GET','POST'])
```

### URL Converters
| Converter | Description              | Example              |
|-----------|--------------------------|----------------------|
| string    | Default, no slashes      | `<string:name>`      |
| int       | Positive integer         | `<int:id>`           |
| float     | Positive float           | `<float:value>`      |
| path      | Like string but w/ slash | `<path:filepath>`    |
| uuid      | UUID string              | `<uuid:token>`       |

### url_for()
Generates URLs from endpoint names. Always prefer over hardcoding paths:
```python
url_for('index')              # -> '/'
url_for('user', username='alice')  # -> '/user/alice'
url_for('static', filename='css/style.css')
```

## 4. The Request Object
Flask wraps incoming HTTP data in the `request` proxy object.

```python
from flask import request

request.method          # 'GET', 'POST', 'PUT', 'DELETE'
request.args            # ImmutableMultiDict — URL query parameters
request.form            # ImmutableMultiDict — POST form data
request.json            # Parsed JSON body (requires Content-Type: application/json)
request.get_json()      # Safe JSON parse with force/silent options
request.files           # FileStorage objects
request.headers         # HTTP headers
request.cookies         # Request cookies
request.remote_addr     # Client IP
request.url             # Full URL
request.path            # URL path only
request.host            # Host header
request.is_secure       # True if HTTPS
```

## 5. Response Object
Flask view functions can return several types:

```python
return 'Hello'                             # plain text, 200
return 'Not found', 404                    # with status code
return 'OK', 200, {'X-Custom': 'value'}    # with headers
return jsonify({'key': 'val'})             # JSON response
return make_response(render_template('page.html'), 200)
return redirect(url_for('index'))          # 302 redirect
return redirect(url_for('index'), 301)     # 301 permanent redirect
abort(404)                                 # raise HTTPException
```

`jsonify()` sets Content-Type to application/json automatically.

## 6. Jinja2 Templating
Flask uses Jinja2 as its template engine. Templates live in `templates/`.

### Variable Interpolation
```jinja2
{{ variable }}
{{ user.name }}
{{ items[0] }}
{{ dict['key'] }}
```

### Control Structures
```jinja2
{% if user.is_authenticated %}
  <p>Welcome, {{ user.name }}</p>
{% elif user.is_guest %}
  <p>Guest user</p>
{% else %}
  <p>Please log in</p>
{% endif %}

{% for item in items %}
  <li>{{ loop.index }}. {{ item.name }}</li>
{% else %}
  <li>No items found</li>
{% endfor %}
```

### Jinja2 Filters
```jinja2
{{ name | upper }}           # UPPERCASE
{{ name | lower }}           # lowercase
{{ name | title }}           # Title Case
{{ text | truncate(100) }}   # Trim to 100 chars
{{ items | length }}         # Count
{{ price | round(2) }}       # Round float
{{ html | safe }}            # Mark as safe HTML (XSS risk!)
{{ dt | strftime('%Y-%m-%d') }}
```

### Template Inheritance
```jinja2
{# base.html #}
<!DOCTYPE html>
<html>
<head><title>{% block title %}Default{% endblock %}</title></head>
<body>
  {% block content %}{% endblock %}
</body>
</html>

{# child.html #}
{% extends "base.html" %}
{% block title %}My Page{% endblock %}
{% block content %}
  <h1>Hello!</h1>
{% endblock %}
```

### Macros (Reusable Template Functions)
```jinja2
{% macro input(name, type='text', value='') %}
  <input type="{{ type }}" name="{{ name }}" value="{{ value }}">
{% endmacro %}
{{ input('username') }}
```

## 7. Static Files
Static files (CSS, JS, images) live in `static/`.

```python
url_for('static', filename='css/style.css')
url_for('static', filename='js/app.js')
url_for('static', filename='images/logo.png')
```

Blueprint static files:
```python
bp = Blueprint('main', __name__, static_folder='static',
               static_url_path='/main/static')
```

## 8. Flask Configuration
```python
app.config['DEBUG'] = True
app.config['SECRET_KEY'] = 'your-secret-key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///app.db'

# From object
class Config:
    DEBUG = False
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev')

class DevelopmentConfig(Config):
    DEBUG = True

app.config.from_object('config.DevelopmentConfig')

# From environment
app.config.from_envvar('APP_SETTINGS')

# From file
app.config.from_pyfile('config.py')
```

Important config keys:
- `SECRET_KEY` — required for sessions and CSRF
- `DEBUG` — enables debugger and reloader
- `TESTING` — enables testing mode
- `WTF_CSRF_ENABLED` — Flask-WTF CSRF protection

## 9. Sessions
Flask uses secure cookie-based sessions (signed with SECRET_KEY).

```python
from flask import session

session['user_id'] = user.id     # set
val = session.get('key', None)   # read
session.pop('user_id', None)     # delete
session.clear()                  # clear all

# Session is permanent
session.permanent = True
app.permanent_session_lifetime = timedelta(days=7)
```

For server-side sessions: use `Flask-Session` extension.

## 10. Flash Messages
One-time messages stored in the session:

```python
# In view
flash('Login successful!', 'success')
flash('Invalid password.', 'danger')

# In template
{% with messages = get_flashed_messages(with_categories=True) %}
  {% for category, message in messages %}
    <div class="alert alert-{{ category }}">{{ message }}</div>
  {% endfor %}
{% endwith %}
```

## 11. Blueprints
Blueprints organize a Flask app into reusable modules.

```python
# auth/routes.py
from flask import Blueprint
auth = Blueprint('auth', __name__, url_prefix='/auth')

@auth.route('/login', methods=['GET', 'POST'])
def login(): ...

@auth.route('/logout')
def logout(): ...

# app/__init__.py
from .auth.routes import auth
app.register_blueprint(auth)
```

Blueprint-specific templates: `templates/auth/login.html`
Blueprint-specific static: pass `static_folder='static'` to Blueprint()

## 12. Error Handlers
```python
@app.errorhandler(404)
def not_found(e):
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def server_error(e):
    return render_template('errors/500.html'), 500

@app.errorhandler(403)
def forbidden(e):
    return jsonify({'error': 'Forbidden'}), 403
```

## 13. Request Hooks
```python
@app.before_request
def load_user():
    g.user = get_current_user()

@app.after_request
def add_security_headers(response):
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    return response

@app.teardown_request
def shutdown_session(exception=None):
    db_session.remove()

@app.before_first_request  # Flask < 2.3
def initialize():
    db.create_all()
```

The `g` object is a request-scoped namespace for storing data.

## 14. Flask Extensions
| Extension        | Purpose                          |
|------------------|----------------------------------|
| Flask-SQLAlchemy | ORM integration                  |
| Flask-Migrate    | Database migrations (Alembic)    |
| Flask-Login      | User session management          |
| Flask-WTF        | WTForms + CSRF protection        |
| Flask-Mail       | Email sending                    |
| Flask-RESTful    | REST API building                |
| Flask-Marshmallow| Serialization/deserialization    |
| Flask-Caching    | Caching layer                    |
| Flask-Limiter    | Rate limiting                    |
| Flask-CORS       | Cross-Origin Resource Sharing    |

## 15. Testing Flask Apps
```python
import pytest
from app import create_app

@pytest.fixture
def client():
    app = create_app({'TESTING': True, 'SQLALCHEMY_DATABASE_URI': 'sqlite://'})
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client

def test_homepage(client):
    rv = client.get('/')
    assert rv.status_code == 200
    assert b'Welcome' in rv.data

def test_post(client):
    rv = client.post('/login', data={'username': 'test', 'password': 'pass'})
    assert rv.status_code == 302  # redirect after login

# Test request context
with app.test_request_context('/'):
    print(url_for('index'))
```

## 16. Deployment
```
# requirements.txt
Flask==3.0.0
gunicorn==21.2.0

# Procfile (Heroku)
web: gunicorn app:app

# wsgi.py
from app import create_app
app = create_app('production')

if __name__ == '__main__':
    app.run()
```

Production checklist:
- Set `DEBUG=False`
- Use strong `SECRET_KEY` from environment
- Use production database (PostgreSQL)
- Serve static files via nginx or CDN
- Use HTTPS
- Configure logging
- Set up error monitoring (Sentry)

## 17. Flask Application Context vs Request Context
- **Application Context** (`app.app_context()`): Holds `current_app` and `g`
- **Request Context** (`app.test_request_context()`): Holds `request` and `session`

Both are pushed/popped automatically in normal request handling.

## 18. WSGI and Flask Internals
Flask implements the WSGI callable interface:
```python
def application(environ, start_response):
    ...
```
Every request creates a new Request object. Flask uses Werkzeug underneath for
routing, request/response handling, and the development server.

## 19. Flask-SQLAlchemy Quickstart
```python
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)

# In factory
db.init_app(app)
with app.app_context():
    db.create_all()
```

## 20. Security Best Practices
- Always validate and sanitize user input
- Use `escape()` or Jinja2 auto-escaping for XSS prevention
- Enable CSRF protection via Flask-WTF
- Store passwords using `werkzeug.security.generate_password_hash`
- Use HTTPS in production
- Set security headers (Content-Security-Policy, X-Frame-Options)
- Never expose DEBUG=True in production