# PyWebIO — 8 Hands-On Projects

## Project 1: Student Data Collection Form
**Goal**: Multi-field form to collect and display student records

### Requirements
- Fields: name, student_id, email, age, courses (multi-select), GPA, enrollment_date
- Validation: student_id must be alphanumeric, GPA between 0-4, valid email
- After submission: show summary table
- Option to add another record or export all as CSV
- In-memory storage with `records = []`

### Hints
```python
from pywebio.input import input_group, input, select, checkbox, NUMBER, file_upload
from pywebio.output import put_table, put_button, put_file, put_success
import csv, io
```

---

## Project 2: ML Input Form with Validation
**Goal**: PyWebIO form for ML model predictions with rich validation

### Requirements
- Feature inputs with PyWebIO's built-in validation
- Real-time feedback as user fills the form
- After prediction: show result prominently, with confidence bar (HTML)
- Save prediction history in a list
- Button to view history as table
- Export history as CSV with `put_file()`

### Hints
```python
from pywebio.output import put_html

def confidence_bar(value: float, label: str):
    pct = int(value * 100)
    color = "#2ecc71" if value > 0.7 else "#e67e22" if value > 0.4 else "#e74c3c"
    put_html(f"""
    <div style="background:#eee;border-radius:4px;overflow:hidden;">
        <div style="width:{pct}%;background:{color};padding:8px;color:white;text-align:center;">
            {label}: {pct}%
        </div>
    </div>
    """)
```

---

## Project 3: Interactive Quiz Application
**Goal**: Multiple-choice quiz with scoring

### Requirements
- Define 10+ questions with options and correct answers
- Present questions one at a time using `actions()`
- Show feedback after each answer (correct/wrong)
- Track score and progress (Question X of N)
- Final results screen with percentage and pass/fail
- Leaderboard: save name + score, show top 5

### Structure
```python
QUESTIONS = [
    {
        "question": "What does WSGI stand for?",
        "options": ["Web Server Gateway Interface", "Web Scripting Guide Interface", ...],
        "answer": "Web Server Gateway Interface"
    },
    ...
]
```

---

## Project 4: CSV Data Dashboard
**Goal**: Upload CSV and display analytics in PyWebIO

### Requirements
- File upload for CSV
- Summary stats using put_table
- Top N rows display
- Column selector → show value counts or statistics
- Numeric column → show min/max/mean/median
- Export cleaned data as downloadable CSV

---

## Project 5: Multi-Step Survey
**Goal**: Branching survey with conditional questions

### Requirements
- Question 1: user role (student/professional/other) → different follow-up questions
- Progress indicator (Step X of Y)
- Review screen before final submit
- Save responses to a list
- Admin view: `actions("Admin or User?", ["User", "Admin"])` → admin sees all responses

### Hints
```python
from pywebio.input import actions, input_group, input, select
role = actions("What is your role?", ["Student", "Professional", "Other"])
if role == "Student":
    data = input_group("Student Info", [...])
elif role == "Professional":
    data = input_group("Professional Info", [...])
```

---

## Project 6: Real-Time Data Monitor (Async)
**Goal**: Display live data that updates automatically

### Requirements
- Simulate sensor readings (temperature, humidity, pressure)
- Update every second using asyncio
- Show current readings with colored indicators
- Alert if values exceed thresholds (using toast)
- Store last 100 readings, show in scrollable table
- Start/Stop button to control streaming

### Hints
```python
import asyncio
from pywebio import start_server
from pywebio.output import put_text, use_scope, toast
from pywebio.input import actions
import random

async def monitor():
    running = True
    while running:
        temp = 20 + random.uniform(-2, 5)
        with use_scope("readings", clear=True):
            put_text(f"Temperature: {temp:.1f}°C")
        if temp > 24:
            toast(f"⚠️ High temperature: {temp:.1f}°C", color="warning")
        await asyncio.sleep(1)
```

---

## Project 7: Flask-Integrated Tool
**Goal**: Embed a PyWebIO tool inside a Flask application

### Requirements
- Flask app with normal HTML routes
- One route (`/tool`) serves a PyWebIO application
- PyWebIO tool: a data entry form that saves to Flask-SQLAlchemy DB
- The Flask app displays saved records via a regular HTML template
- Demonstrate bidirectional data flow

### Structure
```python
from flask import Flask
from pywebio.platform.flask import webio_view
from .models import db, Record

flask_app = Flask(__name__)

def pywebio_form():
    from pywebio.input import input_group, input
    from pywebio.output import put_success
    data = input_group("Add Record", [...])
    record = Record(**data)
    db.session.add(record)
    db.session.commit()
    put_success("Saved!")

flask_app.add_url_rule('/tool', 'tool', webio_view(pywebio_form),
                       methods=['GET', 'POST', 'OPTIONS'])
```

---

## Project 8: Personal Budget Tracker
**Goal**: Track income and expenses with PyWebIO

### Requirements
- Add income/expense entries: amount, category, date, description
- Categories for expense: Food, Transport, Housing, Entertainment, Other
- View summary: total income, total expense, balance
- Monthly breakdown: table grouped by month
- Category breakdown: pie chart using put_html with Chart.js
- Export all entries as CSV

### Hints
```python
entries = []  # {"type": "income"/"expense", "amount": ..., "category": ..., "date": ..., "desc": ...}

# Category totals
from collections import defaultdict
totals = defaultdict(float)
for e in entries:
    if e["type"] == "expense":
        totals[e["category"]] += e["amount"]

# Render Chart.js
import json
chart_data = json.dumps(dict(totals))
put_html(f"""
<canvas id="chart" width="400" height="400"></canvas>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
new Chart(document.getElementById('chart'), {{
    type: 'pie',
    data: {{
        labels: {list(totals.keys())},
        datasets: [{{data: {list(totals.values())}}}]
    }}
}});
</script>
""")
```