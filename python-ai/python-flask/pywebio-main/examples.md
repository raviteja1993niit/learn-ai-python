# PyWebIO — 15+ App Examples

## Example 1: Hello World
```python
from pywebio import start_server
from pywebio.input import input
from pywebio.output import put_text, put_markdown

def main():
    put_markdown("# 👋 Welcome to PyWebIO!")
    name = input("What is your name?", placeholder="Enter your name")
    put_text(f"Hello, {name}! Nice to meet you.")

start_server(main, port=8080, debug=True)
```

## Example 2: Basic Form
```python
from pywebio.input import input_group, input, select, checkbox, REQUIRED, NUMBER
from pywebio.output import put_success, put_table, put_markdown

def main():
    put_markdown("# 📝 Registration Form")

    data = input_group("Create Account", [
        input("Username", name="username", required=True,
              placeholder="At least 3 characters",
              validate=lambda v: None if len(v) >= 3 else "Username too short"),
        input("Email", name="email", type="email", required=True),
        input("Password", name="password", type="password", required=True),
        select("Role", name="role", options=["Admin", "Editor", "Viewer"],
               value="Viewer"),
        checkbox("Preferences", name="prefs",
                 options=["Newsletter", "Dark Mode", "Notifications"])
    ])

    put_markdown("## ✅ Registration Summary")
    put_table([
        ["Field", "Value"],
        ["Username", data["username"]],
        ["Email", data["email"]],
        ["Role", data["role"]],
        ["Preferences", ", ".join(data["prefs"] or [])],
    ])
```

## Example 3: ML Input Form
```python
from pywebio.input import input_group, input, select, slider, NUMBER
from pywebio.output import put_markdown, put_text, put_success, put_error
import joblib
import numpy as np

model = joblib.load("models/hiring_model.pkl")
EDU_MAP = {'High School': 0, "Bachelor's": 1, "Master's": 2, 'PhD': 3}

def main():
    put_markdown("# 🤖 Hiring Predictor")
    put_text("Fill in candidate details below:")

    data = input_group("Candidate Information", [
        input("Age", name="age", type=NUMBER, required=True,
              validate=lambda v: None if 18 <= v <= 65 else "Age must be 18-65"),
        input("Expected Salary ($)", name="salary", type=NUMBER,
              value=60000, required=True),
        input("Years of Experience", name="experience", type=NUMBER,
              value=5, required=True),
        select("Education Level", name="education",
               options=list(EDU_MAP.keys())),
    ])

    features = np.array([[
        data['age'], data['salary'],
        data['experience'], EDU_MAP[data['education']]
    ]])

    pred = int(model.predict(features)[0])
    prob = float(model.predict_proba(features).max())

    put_markdown("---")
    put_markdown("## 📊 Result")
    if pred == 1:
        put_success(f"✅ Likely Hired — Confidence: {prob:.1%}")
    else:
        put_error(f"❌ Unlikely Hired — Confidence: {prob:.1%}")
```

## Example 4: Interactive Calculator
```python
from pywebio.input import input, NUMBER, actions
from pywebio.output import put_text, put_markdown, clear

def main():
    put_markdown("# 🔢 Calculator")
    history = []

    while True:
        a = input("First number", type=NUMBER)
        op = actions("Operation", ["Add", "Subtract", "Multiply", "Divide", "Exit"])

        if op == "Exit":
            break

        b = input("Second number", type=NUMBER)

        if op == "Add":
            result = a + b
        elif op == "Subtract":
            result = a - b
        elif op == "Multiply":
            result = a * b
        elif op == "Divide":
            if b == 0:
                put_text("❌ Cannot divide by zero!")
                continue
            result = a / b

        history.append(f"{a} {op.lower()[:3]} {b} = {result}")
        put_text(f"Result: {result}")

    put_markdown("## History")
    for entry in history:
        put_text(f"• {entry}")
```

## Example 5: File Upload and CSV Analysis
```python
from pywebio.input import file_upload
from pywebio.output import put_text, put_table, put_markdown, put_error
import pandas as pd
import io

def main():
    put_markdown("# 📊 CSV Analyzer")
    put_text("Upload a CSV file to analyze it.")

    file = file_upload("Upload CSV", accept=".csv")
    if not file:
        put_error("No file uploaded!")
        return

    df = pd.read_csv(io.BytesIO(file['content']))

    put_markdown(f"## File: `{file['filename']}`")
    put_text(f"Rows: {len(df)} | Columns: {len(df.columns)}")
    put_markdown("### Column Types")
    put_table(
        [["Column", "Type", "Non-Null", "Unique"]] +
        [[col, str(df[col].dtype), df[col].count(), df[col].nunique()]
         for col in df.columns]
    )

    put_markdown("### First 5 Rows")
    put_table([df.columns.tolist()] + df.head().values.tolist())

    numeric_cols = df.select_dtypes(include='number').columns
    if len(numeric_cols) > 0:
        put_markdown("### Numeric Statistics")
        stats = df[numeric_cols].describe().round(2)
        put_table([["Stat"] + list(numeric_cols)] +
                  [[idx] + list(row) for idx, row in stats.iterrows()])
```

## Example 6: Multi-Step Wizard
```python
from pywebio.input import input_group, input, select, textarea, NUMBER
from pywebio.output import put_markdown, put_table, put_success, put_button, clear

def main():
    put_markdown("# 🧙 Multi-Step Wizard")
    data = {}

    # Step 1: Personal info
    put_markdown("## Step 1: Personal Information")
    step1 = input_group("Personal Info", [
        input("Full Name", name="name", required=True),
        input("Email", name="email", type="email", required=True),
        input("Phone", name="phone", placeholder="+1 555-0000")
    ])
    data.update(step1)

    # Step 2: Professional info
    put_markdown("## Step 2: Professional Background")
    step2 = input_group("Professional", [
        input("Job Title", name="job_title"),
        input("Company", name="company"),
        input("Years Experience", name="years_exp", type=NUMBER, value=0),
        select("Department", name="department",
               options=["Engineering", "Marketing", "Sales", "HR", "Other"])
    ])
    data.update(step2)

    # Step 3: Review
    put_markdown("## Step 3: Review Your Information")
    put_table([["Field", "Value"]] + [[k.replace("_"," ").title(), v]
                                       for k, v in data.items()])

    confirmed = input_group("Confirm", [
        input("Type CONFIRM to submit", name="confirm", required=True,
              validate=lambda v: None if v == "CONFIRM" else "Type CONFIRM")
    ])

    if confirmed["confirm"] == "CONFIRM":
        put_success("🎉 Successfully submitted!")
```

## Example 7: Real-Time Progress (Async)
```python
import asyncio
from pywebio import start_server
from pywebio.output import put_text, put_processbar, set_processbar, put_success, clear

async def main():
    put_text("Starting data processing pipeline...")
    steps = ["Loading data", "Cleaning", "Transforming", "Fitting model", "Evaluating"]

    put_processbar("pipeline", init=0)

    for i, step in enumerate(steps):
        put_text(f"→ {step}...")
        await asyncio.sleep(0.8)
        set_processbar("pipeline", (i + 1) / len(steps))

    put_success("✅ Pipeline complete!")

start_server(main, port=8080)
```

## Example 8: Data Collection Form with Actions
```python
from pywebio.input import input, textarea, select, NUMBER
from pywebio.output import put_table, put_button, put_markdown, toast, use_scope

records = []

def add_record():
    from pywebio.input import input_group
    data = input_group("New Record", [
        input("Name", name="name", required=True),
        input("Score", name="score", type=NUMBER, required=True),
        select("Grade", name="grade", options=["A", "B", "C", "D", "F"])
    ])
    records.append(data)
    toast(f"Added: {data['name']}", color='success')
    refresh_table()

def refresh_table():
    with use_scope("table_scope", clear=True):
        if records:
            put_table(
                [["#", "Name", "Score", "Grade"]] +
                [[i+1, r["name"], r["score"], r["grade"]]
                 for i, r in enumerate(records)]
            )
        else:
            put_markdown("*No records yet.*")

def main():
    put_markdown("# 📋 Grade Recorder")
    put_button("➕ Add Record", onclick=add_record, color="primary")
    put_markdown("### Records")
    with use_scope("table_scope"):
        put_markdown("*No records yet.*")

from pywebio import start_server
start_server(main, port=8080)
```

## Example 9: Dashboard Layout
```python
from pywebio.output import (put_row, put_column, put_text, put_table,
                              put_markdown, put_html, use_scope)
from pywebio import start_server
import random

def stat_box(label, value, color="#4CAF50"):
    put_html(f"""
    <div style="background:{color};color:white;padding:15px;
                border-radius:8px;text-align:center;margin:5px;">
        <h3 style="margin:0">{value}</h3>
        <small>{label}</small>
    </div>
    """)

def main():
    put_markdown("# 📊 Analytics Dashboard")
    put_row([
        stat_box("Total Users", "1,247", "#2196F3"),
        stat_box("Revenue", "$84,320", "#4CAF50"),
        stat_box("Active Models", "5", "#9C27B0"),
        stat_box("Predictions Today", "3,421", "#FF9800"),
    ])
    put_markdown("---")
    put_markdown("### Recent Activity")
    put_table(
        [["Time", "User", "Action", "Status"]] +
        [[f"10:{i:02d}", f"user_{i}", "prediction", "success"]
         for i in range(5)]
    )

start_server(main, port=8080)
```

## Example 10: Flask Integration
```python
from flask import Flask
from pywebio.platform.flask import webio_view
from pywebio.input import input, NUMBER
from pywebio.output import put_text, put_markdown
import joblib
import numpy as np

flask_app = Flask(__name__)
model = joblib.load("models/model.pkl")

def prediction_tool():
    put_markdown("# 🎯 Prediction Tool")
    age = input("Age", type=NUMBER, required=True)
    salary = input("Salary", type=NUMBER, required=True)
    features = np.array([[age, salary, 5]])
    pred = model.predict(features)[0]
    put_text(f"Prediction: {'Hired' if pred == 1 else 'Not Hired'}")

flask_app.add_url_rule(
    '/predict-tool',
    'prediction',
    webio_view(prediction_tool),
    methods=['GET', 'POST', 'OPTIONS']
)

@flask_app.route('/')
def home():
    return '<h1>App Home</h1><a href="/predict-tool">Open Prediction Tool</a>'

if __name__ == '__main__':
    flask_app.run(port=5000)
```

## Example 11: Popup and Toast Notifications
```python
from pywebio.input import actions, input
from pywebio.output import put_text, put_markdown, popup, toast

def main():
    put_markdown("# 🔔 Notifications Demo")

    choice = actions("Choose an action:", [
        {"label": "Show Popup", "value": "popup", "color": "primary"},
        {"label": "Show Toast", "value": "toast", "color": "success"},
        {"label": "Confirm Delete", "value": "delete", "color": "danger"},
    ])

    if choice == "popup":
        popup("Information", [
            put_text("This is a popup window!"),
            put_text("It can contain any PyWebIO output elements."),
        ])
    elif choice == "toast":
        toast("✅ Operation successful!", color="success", duration=3)
    elif choice == "delete":
        confirm = actions("⚠️ Are you sure you want to delete?",
                          ["Yes, delete it", "Cancel"])
        if confirm == "Yes, delete it":
            toast("🗑️ Deleted!", color="danger")
        else:
            toast("Cancelled", color="info")
```

## Example 12: Input Validation Demo
```python
from pywebio.input import input_group, input, NUMBER
from pywebio.output import put_markdown, put_success, put_table

import re

def validate_email(email):
    pattern = r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$'
    return None if re.match(pattern, email) else "Invalid email format"

def validate_phone(phone):
    clean = re.sub(r'[\s\-\(\)]', '', phone)
    return None if re.match(r'^\+?[\d]{10,15}$', clean) else "Invalid phone number"

def main():
    put_markdown("# ✅ Form Validation Demo")

    data = input_group("Validated Form", [
        input("Full Name", name="name",
              validate=lambda v: None if len(v.split()) >= 2 else "Enter full name"),
        input("Email", name="email", type="email", validate=validate_email),
        input("Phone", name="phone", validate=validate_phone),
        input("Age", name="age", type=NUMBER,
              validate=lambda v: None if 18 <= v <= 120 else "Age 18-120"),
        input("Website", name="website",
              validate=lambda v: None if v.startswith('http') else "Must start with http"),
    ])

    put_success("✅ All fields validated!")
    put_table([["Field", "Value"]] + [[k, v] for k, v in data.items()])
```

## Example 13: Async Real-Time Data Feed
```python
import asyncio
from pywebio import start_server
from pywebio.output import put_text, put_table, use_scope, clear
import random
import time

async def live_data():
    put_text("📡 Live Data Feed (updates every second)")
    put_text("Press Ctrl+C to stop\n")

    data_history = []

    while True:
        row = {
            "time": time.strftime("%H:%M:%S"),
            "temperature": round(random.uniform(20, 25), 1),
            "humidity": round(random.uniform(40, 60), 1),
            "pressure": round(random.uniform(1013, 1020), 1)
        }
        data_history.insert(0, row)
        data_history = data_history[:10]

        with use_scope("data", clear=True):
            put_table(
                [["Time", "Temp (°C)", "Humidity (%)", "Pressure (hPa)"]] +
                [[r["time"], r["temperature"], r["humidity"], r["pressure"]]
                 for r in data_history]
            )

        await asyncio.sleep(1)

start_server(live_data, port=8080)
```

## Example 14: Image Display
```python
from pywebio.input import file_upload
from pywebio.output import put_image, put_text, put_row, put_markdown
from PIL import Image, ImageFilter
import io

def main():
    put_markdown("# 🖼️ Image Viewer")
    file = file_upload("Upload an image", accept=".jpg,.jpeg,.png")

    if file:
        img = Image.open(io.BytesIO(file['content']))
        blurred = img.filter(ImageFilter.GaussianBlur(radius=3))

        buffer = io.BytesIO()
        blurred.save(buffer, format='PNG')
        blurred_bytes = buffer.getvalue()

        put_text(f"Original: {img.width}×{img.height} pixels")
        put_row([
            put_image(file['content']),
            put_image(blurred_bytes)
        ])
        put_text("Left: Original | Right: Blurred")
```

## Example 15: Scope Management
```python
from pywebio.output import put_text, put_markdown, use_scope, clear
from pywebio.input import actions
import time

def main():
    put_markdown("# 🎭 Scope Management Demo")
    put_text("This text is in the global scope and won't change.")

    with use_scope("status"):
        put_text("Status: Idle")

    with use_scope("results"):
        put_text("Results will appear here")

    while True:
        choice = actions("Action:", ["Run Task", "Clear Results", "Update Status", "Exit"])

        if choice == "Exit":
            break
        elif choice == "Run Task":
            with use_scope("status", clear=True):
                put_text("Status: Running...")
            time.sleep(1)  # Simulate work
            with use_scope("results"):
                put_text(f"→ Task completed at {time.strftime('%H:%M:%S')}")
            with use_scope("status", clear=True):
                put_text("Status: Complete ✅")
        elif choice == "Clear Results":
            with use_scope("results", clear=True):
                put_text("Results cleared.")
        elif choice == "Update Status":
            msg = f"Last updated: {time.strftime('%H:%M:%S')}"
            with use_scope("status", clear=True):
                put_text(f"Status: {msg}")
```