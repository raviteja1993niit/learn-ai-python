# PyWebIO — Web Apps in Pure Python — Theory & Concepts

## 1. PyWebIO Philosophy
PyWebIO lets you build interactive web applications using only Python I/O functions —
no HTML, no CSS, no JavaScript required.

**Core idea**: Convert Python terminal-style I/O (`input()`, `print()`) into
a web interface automatically.

```
Python I/O functions → PyWebIO server → Web browser UI
```

### PyWebIO vs Streamlit vs Flask vs Gradio

| Aspect           | PyWebIO           | Streamlit         | Flask              | Gradio            |
|------------------|-------------------|-------------------|--------------------|-------------------|
| Code style       | Sequential I/O    | Script reruns     | Route handlers     | Function wrappers |
| HTML knowledge   | Not needed        | Not needed        | Optional           | Not needed        |
| Layout control   | Limited           | Good              | Full               | Good              |
| State mgmt       | Sequential flow   | session_state     | session/cookie     | gr.State          |
| Best for         | Forms, wizards    | Dashboards, EDA   | Full web apps      | ML demos          |
| Async support    | Yes               | No                | Flask 2.x          | No                |
| Deployment       | Simple            | Streamlit Cloud   | Many options       | HuggingFace Spaces|

## 2. Input Functions

### Basic Inputs
```python
from pywebio.input import *

# Text
name = input("What is your name?", placeholder="Enter your name")
email = input("Email", type=TEXT, validate=lambda v: None if '@' in v else 'Invalid email')

# Password
password = input("Password", type=PASSWORD)

# Number
age = input("Age", type=NUMBER)

# Text area (multiline)
bio = textarea("Bio", rows=5, placeholder="Tell us about yourself...")

# File upload
file = file_upload("Upload CSV", accept=".csv")
content = file['content']  # bytes
name = file['filename']
files = file_upload("Upload multiple", multiple=True, accept=['.jpg', '.png'])
```

### Selection Inputs
```python
# Single select (dropdown)
country = select("Country", options=["USA", "UK", "Canada", "Australia"])
# With labels and values
level = select("Level", options=[
    {"label": "Beginner", "value": 1},
    {"label": "Intermediate", "value": 2},
    {"label": "Expert", "value": 3}
])

# Multiple select (checkboxes)
skills = checkbox("Skills", options=["Python", "Java", "JavaScript", "Go"])

# Radio buttons
gender = radio("Gender", options=["Male", "Female", "Prefer not to say"])

# Slider
age = slider("Age", min_value=0, max_value=100, value=25, step=1)
```

### Combined Form (input_group)
```python
from pywebio.input import input_group, input, select, checkbox, REQUIRED

data = input_group("User Registration", [
    input("Username", name="username", required=True),
    input("Email", name="email", type="email", required=True),
    input("Password", name="password", type=PASSWORD),
    select("Role", name="role", options=["Admin", "User", "Guest"]),
    checkbox("Accept Terms", name="accept", options=["I agree"], required=True)
])
# Returns dict: {"username": "...", "email": "...", ...}
```

### Input Validation
```python
def check_age(val):
    if val < 0 or val > 120:
        return "Age must be between 0 and 120"
    return None  # None means valid

age = input("Age", type=NUMBER, validate=check_age)

# Inline validation
name = input("Name",
    validate=lambda v: None if len(v) >= 2 else "Name too short")
```

## 3. Output Functions

### Text Output
```python
from pywebio.output import *

put_text("Hello, World!")
put_text("Line 1", "Line 2", sep="\n")  # Multiple items
put_markdown("# Title\n**Bold** _italic_ `code`")
put_html("<h1>Title</h1><p>Paragraph</p>")
put_code("print('Hello')", language='python')
```

### Data Display
```python
# Table
put_table([
    ['Name', 'Age', 'City'],
    ['Alice', 30, 'NYC'],
    ['Bob', 25, 'LA']
])

# Table with HTML in cells
put_table([
    ['Product', 'Status'],
    ['Widget A', put_button('View', onclick=lambda: ...)],
])

# Links and buttons
put_link("Visit GitHub", "https://github.com")
put_button("Click me", onclick=lambda: put_text("Clicked!"))
put_buttons(
    buttons=["Option A", "Option B", "Option C"],
    onclick=lambda val: put_text(f"Selected: {val}")
)
```

### Images and Files
```python
# Display image
put_image("path/to/image.png")
put_image(img_bytes, format='png')  # bytes
put_image(pil_image)  # PIL Image

# Download link
put_file("data.csv", csv_bytes, "Download CSV")
```

## 4. Layout

### Rows and Columns
```python
from pywebio.output import put_row, put_column, put_grid

# Row layout
put_row([
    put_text("Left"),
    None,  # Spacer
    put_text("Right")
])

# Column layout (vertical stacking)
put_column([
    put_text("Top"),
    put_text("Middle"),
    put_text("Bottom")
])

# Grid layout
put_grid([
    [put_text("(0,0)"), put_text("(0,1)"), put_text("(0,2)")],
    [put_text("(1,0)"), put_text("(1,1)"), put_text("(1,2)")],
])
```

### Scopes (Named Regions)
```python
# Create named region to update later
with use_scope("results"):
    put_text("Initial result")

# Later, clear and update the scope
with use_scope("results", clear=True):
    put_text("Updated result!")

# Or explicitly
clear("results")
with use_scope("results"):
    put_text("New content")

# output_mutex prevents scope conflicts in async
```

## 5. Control and Interaction

### Actions (Confirmation + Choice)
```python
# Confirmation
if actions("Are you sure?", ["Yes", "No"]) == "Yes":
    delete_record()

# Choice selection with icons
choice = actions("Choose action", [
    {"label": "Edit", "value": "edit", "color": "primary"},
    {"label": "Delete", "value": "delete", "color": "danger"},
])
```

### Popups
```python
# Simple popup
popup("Alert", "File saved successfully!", closable=True)

# Rich popup with widgets
with popup("Settings") as s:
    put_text("Current settings:")
    put_table(settings_data)
    put_button("Close", onclick=lambda: s.close(), color="secondary")
```

### Toast Notifications
```python
toast("Success!", color="success", duration=3)  # 3 seconds
toast("Warning: low memory", color="warning")
toast("Error occurred", color="danger", duration=0)  # Stays until closed
```

### hold()
Keep the app alive after the function returns:
```python
def main():
    put_text("App is running")
    put_button("Click me", onclick=lambda: put_text("Clicked!"))
    hold()  # Wait for interactions
```

## 6. Server Modes

### Standalone Server
```python
from pywebio import start_server

def main():
    name = input("Name?")
    put_text(f"Hello, {name}!")

start_server(main, port=8080, debug=True)
start_server(main, port=8080, host="0.0.0.0")
```

### Multiple Routes
```python
from pywebio import start_server

def page1():
    put_text("Page 1")

def page2():
    name = input("Name")
    put_text(f"Hello {name}")

start_server({
    '/': page1,
    '/form': page2
}, port=8080)
```

### Flask Integration
```python
from flask import Flask
from pywebio.platform.flask import webio_view
from pywebio import COROUTINE_BASED

flask_app = Flask(__name__)
flask_app.add_url_rule(
    '/tool',
    'webio_view',
    webio_view(my_pywebio_func),
    methods=['GET', 'POST', 'OPTIONS']
)

if __name__ == '__main__':
    flask_app.run(port=8080)
```

### Django Integration
```python
# urls.py
from django.urls import path
from pywebio.platform.django import webio_view
urlpatterns = [
    path('tool/', webio_view(my_pywebio_func))
]
```

### aiohttp Integration
```python
from aiohttp import web
from pywebio.platform.aiohttp import webio_handler

app = web.Application()
app.router.add_routes([web.get('/tool', webio_handler(my_func))])
web.run_app(app, port=8080)
```

## 7. Session Management
```python
from pywebio.session import local, run_js, eval_js, set_env

# Per-session local storage
local.username = "alice"
local.history = []

# JavaScript execution
run_js("document.title = 'My App'")
viewport_width = eval_js("window.innerWidth")

# Environment settings
set_env(title="Custom Tab Title", output_animation=False)
```

## 8. Real-time Updates with Async
```python
import asyncio
from pywebio.output import put_text, put_processbar, set_processbar, clear
from pywebio import start_server

async def realtime_progress():
    put_processbar('progress')
    for i in range(1, 101):
        set_processbar('progress', i / 100)
        await asyncio.sleep(0.1)
    put_text("Done!")

start_server(realtime_progress, port=8080)
```

### Async data streaming
```python
import asyncio
from pywebio.output import put_text, use_scope

async def stream_data():
    with use_scope("output", clear=True):
        async for item in fetch_stream():
            put_text(item)
            await asyncio.sleep(0)  # Yield to event loop
```

## 9. Comparison Summary

### When to use PyWebIO
- Quickly wrap a Python script with a web interface
- Build data collection forms for internal use
- Create simple dashboards without frontend knowledge
- Add a web UI to a command-line tool
- Educational demos and prototypes

### When NOT to use PyWebIO
- Production customer-facing applications (use Flask/Django)
- Complex real-time dashboards (use Streamlit)
- ML model demos for sharing (use Gradio)
- Apps requiring custom CSS/JS design (use Flask/FastAPI + frontend)

## 10. Theming and Styling
```python
from pywebio import config

@config(theme='dark')
def main():
    put_text("Dark theme app")

# Themes: 'default', 'dark', 'sketchy', 'minty', 'yeti', 'united', 'cyborg'

# CDN for themes
config(js_file='https://cdn.example.com/custom.js',
       css_file='path/to/style.css')
```

## 11. Error Handling
```python
from pywebio.output import put_error, put_warning

try:
    result = process_data(data)
    put_text("Success:", result)
except ValueError as e:
    put_error(f"Validation error: {e}")
except Exception as e:
    put_error(f"Unexpected error: {e}")
    import traceback
    put_code(traceback.format_exc(), language='text')
```

## 12. Running in Jupyter
```python
# Works in Jupyter notebooks too
from pywebio.output import put_text
from pywebio.platform.jupyter import start_server

# Or use as standalone cells
from pywebio import output
output.put_text("Hello from Jupyter!")
```