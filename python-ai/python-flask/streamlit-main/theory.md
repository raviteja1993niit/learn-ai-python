# Streamlit — Deep Reference Guide

## 1. How Streamlit Works
Streamlit re-runs your entire Python script from top to bottom on every user interaction.

```
User interacts with widget
        ↓
Streamlit re-runs script
        ↓
New UI is rendered
```

This "just rerun" model makes Streamlit incredibly simple — no callbacks, no state machine
boilerplate — but requires understanding caching and session_state for performance.

### Execution Model
- Every widget interaction triggers a full rerun
- Script runs in a single thread per session
- Multiple users = multiple independent sessions
- State between reruns is managed via `st.session_state`

### Starting an app
```bash
streamlit run app.py
streamlit run app.py --server.port 8080
streamlit run app.py --server.address 0.0.0.0
streamlit run app.py -- --custom-arg value  # pass args to script
```

## 2. App Structure
```python
import streamlit as st
import pandas as pd
import numpy as np

# Page config (must be first Streamlit call)
st.set_page_config(
    page_title="My App",
    page_icon="🤖",
    layout="wide",           # "centered" or "wide"
    initial_sidebar_state="expanded",  # "expanded" or "collapsed"
    menu_items={
        'Get Help': 'https://github.com/me/project',
        'Report a bug': 'mailto:me@example.com',
        'About': '# My Awesome App'
    }
)
```

## 3. Display Elements

### Text
```python
st.title("Main Title")          # H1
st.header("Section Header")     # H2
st.subheader("Subsection")      # H3
st.text("Fixed-width text")     # Monospace
st.markdown("**Bold** _italic_ `code` [link](url)")
st.markdown("# H1\n## H2\n### H3")  # Markdown headers
st.latex(r"\hat{y} = \theta_0 + \theta_1 x")  # LaTeX formula
st.code("print('hello')", language='python')
st.divider()                    # Horizontal line
st.caption("Small caption text below charts")
st.write("Catch-all: renders text, DataFrames, charts, dicts, lists...")
```

### Formatted numbers with st.metric
```python
st.metric(label="Accuracy", value="95.3%", delta="1.2%")
st.metric(label="Loss", value=0.042, delta=-0.003, delta_color="inverse")

col1, col2, col3 = st.columns(3)
with col1:
    st.metric("Precision", "0.92", "0.03")
with col2:
    st.metric("Recall", "0.88", "-0.01")
with col3:
    st.metric("F1 Score", "0.90", "0.01")
```

## 4. Data Display

### DataFrames
```python
st.dataframe(df)                   # Interactive, sortable
st.dataframe(df, use_container_width=True, height=400)

# With column config
st.dataframe(df, column_config={
    "price": st.column_config.NumberColumn("Price ($)", format="$%.2f"),
    "date": st.column_config.DateColumn("Date"),
    "url": st.column_config.LinkColumn("URL"),
    "active": st.column_config.CheckboxColumn("Active?"),
})

st.table(df)                       # Static table (no sorting)
st.json({"key": "value", "list": [1, 2, 3]})  # Expandable JSON
```

### Editable DataFrames
```python
edited_df = st.data_editor(df, num_rows="dynamic")
# User can edit cells, add/delete rows
```

## 5. Charts

### Native Charts
```python
import numpy as np
import pandas as pd

chart_data = pd.DataFrame(np.random.randn(20, 3), columns=["A", "B", "C"])

st.line_chart(chart_data)
st.area_chart(chart_data)
st.bar_chart(chart_data)
st.scatter_chart(chart_data, x="A", y="B", size="C", color="A")

# Map (requires lat/lon columns)
map_data = pd.DataFrame({'lat': [37.76], 'lon': [-122.4]})
st.map(map_data, zoom=12)
```

### Plotly Charts
```python
import plotly.express as px
import plotly.graph_objects as go

fig = px.scatter(df, x='sepal_width', y='sepal_length',
                 color='species', size='petal_length',
                 title='Iris Dataset')
st.plotly_chart(fig, use_container_width=True)

# Interactive 3D
fig3d = px.scatter_3d(df, x='x', y='y', z='z', color='label')
st.plotly_chart(fig3d)
```

### Matplotlib
```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(10, 6))
ax.hist(df['salary'], bins=30, edgecolor='black')
ax.set_xlabel('Salary')
ax.set_ylabel('Count')
ax.set_title('Salary Distribution')
st.pyplot(fig)
plt.close(fig)  # Important: prevent memory leaks
```

### Altair
```python
import altair as alt
chart = alt.Chart(df).mark_circle().encode(
    x='sepal_width',
    y='sepal_length',
    color='species',
    tooltip=['species', 'sepal_length', 'sepal_width']
).interactive()
st.altair_chart(chart, use_container_width=True)
```

## 6. Input Widgets

### Text Inputs
```python
name = st.text_input("Your name", placeholder="Enter name...", max_chars=50)
bio = st.text_area("Bio", height=150, help="Tell us about yourself")
password = st.text_input("Password", type="password")
search = st.text_input("Search", value="default text")
```

### Numeric Inputs
```python
age = st.number_input("Age", min_value=0, max_value=120, value=25, step=1)
price = st.number_input("Price", min_value=0.0, value=9.99, step=0.01, format="%.2f")
n_trees = st.slider("Number of Trees", min_value=10, max_value=500, value=100, step=10)
range_val = st.slider("Range", 0, 100, (25, 75))  # Range slider — returns tuple
select_slider = st.select_slider("Quality", options=["Low", "Medium", "High"], value="Medium")
```

### Selection Widgets
```python
option = st.selectbox("Choose option", ["Option A", "Option B", "Option C"])
options = st.multiselect("Select multiple", ["A", "B", "C", "D"], default=["A"])
radio = st.radio("Pick one", ["Red", "Green", "Blue"], horizontal=True)
agree = st.checkbox("I agree to terms")
```

### Date and Time
```python
from datetime import date, time, datetime, timedelta

d = st.date_input("Date", value=date.today(), min_value=date(2020, 1, 1))
t = st.time_input("Time", value=time(12, 0))
color = st.color_picker("Pick color", value="#3498db")
```

## 7. File Handling
```python
# Upload
uploaded = st.file_uploader("Upload CSV", type=['csv', 'xlsx'])
if uploaded:
    df = pd.read_csv(uploaded)
    st.dataframe(df)

# Multiple files
files = st.file_uploader("Upload files", accept_multiple_files=True)
for f in files:
    st.write(f.name, f.size)

# Camera input
img = st.camera_input("Take a photo")
if img:
    from PIL import Image
    image = Image.open(img)

# Download button
csv_data = df.to_csv(index=False).encode('utf-8')
st.download_button(
    label="Download CSV",
    data=csv_data,
    file_name="data.csv",
    mime="text/csv"
)
```

## 8. Layout

### Columns
```python
col1, col2, col3 = st.columns(3)           # Equal width
col1, col2 = st.columns([2, 1])            # 2:1 ratio
col1, col2, col3 = st.columns([1, 2, 1])   # 1:2:1

with col1:
    st.metric("Accuracy", "95%")
col2.write("Hello from column 2")
```

### Tabs
```python
tab1, tab2, tab3 = st.tabs(["Data", "Charts", "Model"])
with tab1:
    st.dataframe(df)
with tab2:
    st.line_chart(df)
with tab3:
    st.write("Model details")
```

### Expander
```python
with st.expander("Advanced Settings", expanded=False):
    alpha = st.slider("Alpha", 0.0, 1.0, 0.1)
    n_iter = st.number_input("Iterations", value=1000)
```

### Sidebar
```python
with st.sidebar:
    st.title("Controls")
    model = st.selectbox("Model", ["LR", "RF", "XGBoost"])
    n_samples = st.slider("Samples", 100, 10000, 1000)
    uploaded = st.file_uploader("Data")
```

### Container and Empty
```python
container = st.container()
container.write("This appears in the container")

placeholder = st.empty()
placeholder.text("Loading...")
# ... do work ...
placeholder.success("Done!")  # Replace content
placeholder.empty()           # Clear
```

## 9. Control Flow

### Buttons and Forms
```python
if st.button("Predict", type="primary"):
    result = model.predict(inputs)
    st.write(f"Result: {result}")

# Form (collects inputs, prevents reruns until submit)
with st.form("prediction_form"):
    name = st.text_input("Name")
    age = st.number_input("Age", min_value=0, max_value=120)
    submitted = st.form_submit_button("Submit")
    if submitted:
        st.write(f"Hello {name}, age {age}")
```

## 10. Session State
Persists data between reruns within a session:

```python
# Initialize
if 'counter' not in st.session_state:
    st.session_state.counter = 0

if 'history' not in st.session_state:
    st.session_state.history = []

# Modify
if st.button("Increment"):
    st.session_state.counter += 1

st.write(f"Count: {st.session_state.counter}")

# Widget key binds widget value to session_state
name = st.text_input("Name", key="user_name")
# st.session_state.user_name == name

# Callback pattern
def increment():
    st.session_state.counter += 1

st.button("Click", on_click=increment)
```

## 11. Caching

### @st.cache_data — For data/functions
```python
@st.cache_data
def load_csv(url: str) -> pd.DataFrame:
    return pd.read_csv(url)

@st.cache_data(ttl=3600)  # 1 hour TTL
def fetch_api_data(endpoint: str) -> dict:
    return requests.get(endpoint).json()

@st.cache_data(max_entries=10)
def expensive_computation(n: int) -> list:
    return [i**2 for i in range(n)]
```

### @st.cache_resource — For connections/models
```python
@st.cache_resource
def load_ml_model():
    return joblib.load('model.pkl')

@st.cache_resource
def get_db_connection():
    return create_engine('postgresql://...')

model = load_ml_model()  # Loaded once, shared across all users
```

Key difference:
- `cache_data`: Returns copies (safe for DataFrames, dicts, lists)
- `cache_resource`: Returns same object (safe for models, connections)

## 12. Progress and Status
```python
# Progress bar
progress = st.progress(0, text="Starting...")
for i in range(100):
    progress.progress(i + 1, text=f"Processing {i+1}/100")
    time.sleep(0.05)

# Spinner
with st.spinner("Loading model..."):
    model = load_model()
st.success("Model loaded!")

# Alerts
st.success("Operation completed!")
st.error("An error occurred: division by zero")
st.warning("Data contains missing values")
st.info("Using cached results from yesterday")
st.toast("Saved!", icon="✅")  # Non-blocking toast notification

# Status box
with st.status("Running pipeline...", expanded=True):
    st.write("Step 1: Loading data")
    load_data()
    st.write("Step 2: Preprocessing")
    preprocess()
    st.write("Step 3: Training")
    train()
```

## 13. Secrets Management
```toml
# .streamlit/secrets.toml (never commit to git!)
[database]
host = "localhost"
password = "secret123"

[api]
key = "sk-abc123"
```

```python
# Access in app
db_host = st.secrets["database"]["host"]
api_key = st.secrets.api.key

# In database connections
conn = psycopg2.connect(
    host=st.secrets["database"]["host"],
    password=st.secrets["database"]["password"]
)
```

## 14. Multipage Apps
```
myapp/
├── app.py           # Main page
└── pages/
    ├── 1_Data.py    # Page 1 (number prefix for ordering)
    ├── 2_Charts.py  # Page 2
    └── 3_Model.py   # Page 3
```

Navigation appears automatically in sidebar. Use `st.page_link()` for custom navigation.

## 15. Custom Components
```python
# Install custom components
# pip install streamlit-aggrid streamlit-folium streamlit-lottie

from st_aggrid import AgGrid
AgGrid(df, editable=True, height=400)

import folium
from streamlit_folium import st_folium
m = folium.Map(location=[45.5236, -122.6750], zoom_start=13)
st_folium(m, width=700, height=500)
```

## 16. Deployment

### Streamlit Community Cloud
1. Push app to GitHub
2. Go to share.streamlit.io
3. Connect repo, specify main file
4. Add secrets in dashboard

### Docker
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8501
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]
```

### Configuration file
```toml
# .streamlit/config.toml
[server]
port = 8501
maxUploadSize = 200

[theme]
primaryColor = "#FF4B4B"
backgroundColor = "#FFFFFF"
secondaryBackgroundColor = "#F0F2F6"
textColor = "#262730"
font = "sans serif"
```