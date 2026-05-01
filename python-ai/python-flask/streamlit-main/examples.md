# Streamlit — 20+ App Examples

## Example 1: Minimal Streamlit App
```python
import streamlit as st

st.title("Hello Streamlit!")
name = st.text_input("What's your name?")
if name:
    st.write(f"Hello, **{name}**! 👋")
st.balloons()
```

## Example 2: EDA Dashboard with CSV Upload
```python
import streamlit as st
import pandas as pd
import plotly.express as px

st.set_page_config(page_title="EDA Dashboard", layout="wide")
st.title("📊 EDA Dashboard")

uploaded = st.file_uploader("Upload a CSV file", type=['csv'])

if uploaded is not None:
    df = pd.read_csv(uploaded)
    st.success(f"Loaded {len(df):,} rows × {len(df.columns)} columns")

    tab1, tab2, tab3 = st.tabs(["Preview", "Statistics", "Charts"])

    with tab1:
        st.dataframe(df.head(100), use_container_width=True)

    with tab2:
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Rows", f"{len(df):,}")
        with col2:
            st.metric("Columns", len(df.columns))
        with col3:
            st.metric("Missing Values", df.isnull().sum().sum())
        st.dataframe(df.describe(), use_container_width=True)

    with tab3:
        numeric_cols = df.select_dtypes(include='number').columns.tolist()
        if numeric_cols:
            col = st.selectbox("Select column", numeric_cols)
            col1, col2 = st.columns(2)
            with col1:
                fig = px.histogram(df, x=col, title=f"Distribution of {col}")
                st.plotly_chart(fig, use_container_width=True)
            with col2:
                fig2 = px.box(df, y=col, title=f"Box Plot of {col}")
                st.plotly_chart(fig2, use_container_width=True)
else:
    st.info("👆 Upload a CSV file to get started")
```

## Example 3: ML Model Predictor
```python
import streamlit as st
import joblib
import numpy as np
import pandas as pd

st.set_page_config(page_title="ML Predictor", page_icon="🤖")

@st.cache_resource
def load_model():
    return joblib.load("models/hiring_model.pkl")

model = load_model()

st.title("🤖 Hiring Predictor")
st.markdown("Enter candidate information to predict hiring likelihood.")

with st.form("prediction_form"):
    col1, col2 = st.columns(2)
    with col1:
        age = st.number_input("Age", min_value=18, max_value=65, value=30)
        salary = st.number_input("Expected Salary ($)", min_value=0, value=60000, step=5000)
    with col2:
        experience = st.number_input("Years of Experience", min_value=0, max_value=40, value=5)
        education = st.selectbox("Education", ["high_school", "bachelor", "master", "phd"])

    submitted = st.form_submit_button("Predict", type="primary")

if submitted:
    edu_map = {'high_school': 0, 'bachelor': 1, 'master': 2, 'phd': 3}
    features = np.array([[age, salary, experience, edu_map[education]]])

    with st.spinner("Running prediction..."):
        prediction = model.predict(features)[0]
        probability = model.predict_proba(features).max()

    if prediction == 1:
        st.success(f"✅ **Likely to be Hired** — Confidence: {probability:.1%}")
    else:
        st.error(f"❌ **Unlikely to be Hired** — Confidence: {probability:.1%}")

    st.progress(float(probability), text=f"Model confidence: {probability:.1%}")
```

## Example 4: Session State Counter
```python
import streamlit as st

st.title("Session State Demo")

# Initialize state
if "count" not in st.session_state:
    st.session_state.count = 0
if "history" not in st.session_state:
    st.session_state.history = []

col1, col2, col3 = st.columns(3)

with col1:
    if st.button("➕ Increment"):
        st.session_state.count += 1
        st.session_state.history.append(("increment", st.session_state.count))

with col2:
    if st.button("➖ Decrement"):
        st.session_state.count -= 1
        st.session_state.history.append(("decrement", st.session_state.count))

with col3:
    if st.button("🔄 Reset"):
        st.session_state.count = 0
        st.session_state.history = []

st.metric("Count", st.session_state.count)

if st.session_state.history:
    with st.expander("History"):
        for action, value in reversed(st.session_state.history[-10:]):
            st.write(f"• {action} → {value}")
```

## Example 5: Real-Time Chart with Streaming
```python
import streamlit as st
import numpy as np
import pandas as pd
import time

st.title("📈 Live Streaming Data")

placeholder = st.empty()

if st.button("Start Stream"):
    data = pd.DataFrame({'time': [], 'value': []})
    for i in range(50):
        new_row = pd.DataFrame({'time': [i], 'value': [np.sin(i/5) + np.random.randn()*0.1]})
        data = pd.concat([data, new_row], ignore_index=True)
        with placeholder.container():
            st.line_chart(data.set_index('time'))
            st.metric("Current Value", f"{data['value'].iloc[-1]:.3f}")
        time.sleep(0.1)
    st.success("Stream complete!")
```

## Example 6: Sidebar Controls with Data Filtering
```python
import streamlit as st
import pandas as pd
import plotly.express as px

@st.cache_data
def load_data():
    return pd.read_csv("data/sales.csv", parse_dates=['date'])

df = load_data()

with st.sidebar:
    st.title("🔧 Filters")
    date_range = st.date_input("Date Range",
        value=(df['date'].min(), df['date'].max()))
    regions = st.multiselect("Region", df['region'].unique(),
                              default=df['region'].unique())
    min_amount = st.slider("Min Sale Amount",
        float(df['amount'].min()), float(df['amount'].max()), float(df['amount'].min()))

# Filter
mask = (
    (df['date'] >= pd.to_datetime(date_range[0])) &
    (df['date'] <= pd.to_datetime(date_range[1])) &
    (df['region'].isin(regions)) &
    (df['amount'] >= min_amount)
)
filtered = df[mask]

st.title("📊 Sales Dashboard")
col1, col2, col3 = st.columns(3)
col1.metric("Total Sales", f"${filtered['amount'].sum():,.0f}")
col2.metric("Transactions", f"{len(filtered):,}")
col3.metric("Avg Sale", f"${filtered['amount'].mean():.0f}")

fig = px.line(filtered, x='date', y='amount', color='region', title="Sales Over Time")
st.plotly_chart(fig, use_container_width=True)
```

## Example 7: Caching Demo
```python
import streamlit as st
import time

@st.cache_data(ttl=60)  # Cache for 60 seconds
def expensive_query(n: int):
    time.sleep(2)  # Simulate slow DB query
    return list(range(n))

@st.cache_resource
def load_large_model():
    time.sleep(3)  # Simulate model loading
    return {"model": "loaded", "weights": [1, 2, 3]}

st.title("⚡ Caching Demo")

n = st.slider("N", 100, 10000, 1000)

start = time.time()
data = expensive_query(n)
elapsed = time.time() - start

st.write(f"Got {len(data)} items in {elapsed:.3f}s")
if elapsed < 0.1:
    st.success("⚡ Served from cache!")
else:
    st.info("🔄 Computed fresh (first run)")

model = load_large_model()
st.write("Model status:", model["model"])
```

## Example 8: Multi-Tab Data Analysis App
```python
import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px

st.set_page_config(layout="wide")

@st.cache_data
def generate_data(n=500):
    np.random.seed(42)
    return pd.DataFrame({
        'age': np.random.randint(22, 65, n),
        'salary': np.random.normal(70000, 20000, n).clip(20000),
        'experience': np.random.randint(0, 30, n),
        'department': np.random.choice(['Engineering', 'Marketing', 'Sales', 'HR'], n),
        'score': np.random.uniform(0.5, 1.0, n),
    })

df = generate_data()

st.title("👥 Employee Analytics")
tabs = st.tabs(["Overview", "Distributions", "Correlations", "Department Analysis"])

with tabs[0]:
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Employees", len(df))
    col2.metric("Avg Salary", f"${df['salary'].mean():,.0f}")
    col3.metric("Avg Age", f"{df['age'].mean():.1f}")
    col4.metric("Avg Score", f"{df['score'].mean():.2f}")
    st.dataframe(df.head(20), use_container_width=True)

with tabs[1]:
    col = st.selectbox("Column", df.select_dtypes('number').columns)
    fig = px.histogram(df, x=col, color='department', barmode='overlay',
                       title=f"Distribution of {col} by Department")
    st.plotly_chart(fig, use_container_width=True)

with tabs[2]:
    corr = df.select_dtypes('number').corr()
    fig = px.imshow(corr, title="Correlation Matrix", color_continuous_scale='RdBu')
    st.plotly_chart(fig, use_container_width=True)

with tabs[3]:
    dept_stats = df.groupby('department').agg(
        count=('salary', 'count'),
        avg_salary=('salary', 'mean'),
        avg_score=('score', 'mean')
    ).round(2)
    st.dataframe(dept_stats, use_container_width=True)
    fig = px.bar(dept_stats.reset_index(), x='department', y='avg_salary',
                 title="Average Salary by Department")
    st.plotly_chart(fig, use_container_width=True)
```

## Example 9: LLM Chatbot UI
```python
import streamlit as st

st.set_page_config(page_title="ChatBot", page_icon="💬")
st.title("💬 Chatbot")

if "messages" not in st.session_state:
    st.session_state.messages = []

# Display conversation history
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

# Input
if prompt := st.chat_input("Say something..."):
    # Add user message
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Generate response (replace with actual LLM call)
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response = f"Echo: {prompt}"  # Replace with llm.generate(prompt)
        st.markdown(response)
    st.session_state.messages.append({"role": "assistant", "content": response})

# Clear button
if st.button("Clear Chat"):
    st.session_state.messages = []
    st.rerun()
```

## Example 10: Image Processing App
```python
import streamlit as st
from PIL import Image, ImageFilter, ImageEnhance
import numpy as np

st.title("��️ Image Processor")

uploaded = st.file_uploader("Upload an image", type=['jpg', 'jpeg', 'png'])

if uploaded:
    image = Image.open(uploaded)

    with st.sidebar:
        st.header("Adjustments")
        brightness = st.slider("Brightness", 0.1, 3.0, 1.0)
        contrast = st.slider("Contrast", 0.1, 3.0, 1.0)
        blur = st.slider("Blur radius", 0, 10, 0)
        grayscale = st.checkbox("Grayscale")
        filter_type = st.selectbox("Filter", ["None", "SHARPEN", "EMBOSS", "EDGE_ENHANCE"])

    # Apply adjustments
    processed = ImageEnhance.Brightness(image).enhance(brightness)
    processed = ImageEnhance.Contrast(processed).enhance(contrast)
    if blur > 0:
        processed = processed.filter(ImageFilter.GaussianBlur(radius=blur))
    if grayscale:
        processed = processed.convert('L').convert('RGB')
    if filter_type != "None":
        f = getattr(ImageFilter, filter_type)
        processed = processed.filter(f())

    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Original")
        st.image(image)
    with col2:
        st.subheader("Processed")
        st.image(processed)
```

## Example 11: Data Download Button
```python
import streamlit as st
import pandas as pd
import io

df = pd.DataFrame({'A': [1, 2, 3], 'B': ['x', 'y', 'z']})

# CSV download
csv = df.to_csv(index=False).encode('utf-8')
st.download_button("📥 Download CSV", csv, "data.csv", "text/csv")

# Excel download
buffer = io.BytesIO()
with pd.ExcelWriter(buffer, engine='openpyxl') as writer:
    df.to_excel(writer, index=False)
excel_data = buffer.getvalue()
st.download_button("📥 Download Excel", excel_data, "data.xlsx",
                   "application/vnd.ms-excel")
```

## Example 12: Progress Bar with Status
```python
import streamlit as st
import time

if st.button("Run Pipeline"):
    steps = ["Loading data", "Preprocessing", "Training model", "Evaluating", "Saving"]
    progress = st.progress(0)
    status = st.empty()

    for i, step in enumerate(steps):
        status.info(f"Step {i+1}/{len(steps)}: {step}...")
        time.sleep(0.8)
        progress.progress((i + 1) / len(steps))

    status.success("✅ Pipeline complete!")
    st.balloons()
```

## Example 13: st.data_editor for Interactive Tables
```python
import streamlit as st
import pandas as pd

df = pd.DataFrame({
    "Name": ["Alice", "Bob", "Charlie"],
    "Score": [85, 92, 78],
    "Passed": [True, True, False],
    "Grade": ["B", "A", "C"]
})

st.title("Grade Editor")
edited = st.data_editor(
    df,
    column_config={
        "Score": st.column_config.NumberColumn("Score", min_value=0, max_value=100),
        "Passed": st.column_config.CheckboxColumn("Passed?"),
        "Grade": st.column_config.SelectboxColumn("Grade", options=["A","B","C","D","F"])
    },
    num_rows="dynamic",
    use_container_width=True
)

if st.button("Save Changes"):
    st.success("Saved!")
    st.dataframe(edited)
```

## Example 14: Metrics Dashboard with Delta
```python
import streamlit as st
import random

st.title("📊 KPI Dashboard")
st.subheader("Model Performance Metrics")

col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Accuracy", "94.3%", delta="1.2%", help="Compared to last week")
with col2:
    st.metric("Precision", "0.921", delta="0.03")
with col3:
    st.metric("Recall", "0.887", delta="-0.01", delta_color="inverse")
with col4:
    st.metric("F1 Score", "0.904", delta="0.01")

st.divider()
st.metric("Avg Inference Time", "3.2ms", delta="-0.5ms",
          delta_color="inverse", help="Lower is better")
```

## Example 15: Multipage App Structure
```python
# app.py (main page)
import streamlit as st

st.set_page_config(page_title="ML Platform", layout="wide")
st.title("🏠 ML Platform Home")
st.markdown("Use the sidebar to navigate between pages.")

# pages/1_Data.py
import streamlit as st
st.title("📁 Data Management")
# ... data upload/management code

# pages/2_Train.py
import streamlit as st
st.title("🎯 Model Training")
# ... training configuration UI

# pages/3_Predict.py
import streamlit as st
st.title("🔮 Predictions")
# ... prediction interface
```

## Example 16: Plotly Subplots
```python
import streamlit as st
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np

x = np.linspace(0, 10, 100)

fig = make_subplots(
    rows=2, cols=2,
    subplot_titles=["Sine", "Cosine", "Scatter", "Bar"],
    shared_xaxes=False
)
fig.add_trace(go.Scatter(x=x, y=np.sin(x), name="sin"), row=1, col=1)
fig.add_trace(go.Scatter(x=x, y=np.cos(x), name="cos"), row=1, col=2)
fig.add_trace(go.Scatter(x=np.random.randn(50), y=np.random.randn(50),
                          mode="markers", name="scatter"), row=2, col=1)
fig.add_trace(go.Bar(x=["A","B","C","D"], y=[4,7,2,9], name="bar"), row=2, col=2)
fig.update_layout(height=600, title_text="Dashboard Charts")

st.plotly_chart(fig, use_container_width=True)
```

## Example 17: Secrets and Config
```python
import streamlit as st
import psycopg2

# .streamlit/secrets.toml
# [database]
# host = "localhost"
# dbname = "mydb"
# user = "admin"
# password = "secret"

@st.cache_resource
def get_connection():
    return psycopg2.connect(
        host=st.secrets["database"]["host"],
        dbname=st.secrets["database"]["dbname"],
        user=st.secrets["database"]["user"],
        password=st.secrets["database"]["password"]
    )

conn = get_connection()
st.write("Connected to DB!")
```

## Example 18: State Machine for Multi-Step Form
```python
import streamlit as st

STEPS = ["Personal Info", "Preferences", "Review", "Done"]

if "step" not in st.session_state:
    st.session_state.step = 0
if "data" not in st.session_state:
    st.session_state.data = {}

st.progress(st.session_state.step / (len(STEPS) - 1))
st.subheader(STEPS[st.session_state.step])

if st.session_state.step == 0:
    with st.form("step1"):
        name = st.text_input("Name")
        email = st.text_input("Email")
        if st.form_submit_button("Next →"):
            st.session_state.data.update({"name": name, "email": email})
            st.session_state.step = 1
            st.rerun()

elif st.session_state.step == 1:
    with st.form("step2"):
        theme = st.selectbox("Theme", ["Light", "Dark"])
        if st.form_submit_button("Next →"):
            st.session_state.data["theme"] = theme
            st.session_state.step = 2
            st.rerun()

elif st.session_state.step == 2:
    st.json(st.session_state.data)
    if st.button("Submit"):
        st.session_state.step = 3
        st.rerun()

elif st.session_state.step == 3:
    st.success("🎉 Submitted successfully!")
    if st.button("Start Over"):
        st.session_state.step = 0
        st.session_state.data = {}
        st.rerun()
```

## Example 19: Folium Map Integration
```python
import streamlit as st
import folium
from streamlit_folium import st_folium
import pandas as pd

st.title("🗺️ Interactive Map")

df = pd.DataFrame({
    'city': ['New York', 'Los Angeles', 'Chicago'],
    'lat': [40.71, 34.05, 41.85],
    'lon': [-74.0, -118.24, -87.65],
    'population': [8_336_817, 3_979_576, 2_693_976]
})

m = folium.Map(location=[39.5, -98.35], zoom_start=4)
for _, row in df.iterrows():
    folium.CircleMarker(
        [row['lat'], row['lon']],
        radius=row['population'] / 500_000,
        popup=f"{row['city']}: {row['population']:,}",
        fill=True
    ).add_to(m)

result = st_folium(m, width=800, height=500)
if result['last_object_clicked']:
    st.write("Clicked:", result['last_object_clicked'])
```

## Example 20: Custom Styled Metric Cards
```python
import streamlit as st

def card(title, value, icon="📊", color="#1f77b4"):
    st.markdown(f"""
    <div style="
        background: {color}22;
        border-left: 4px solid {color};
        padding: 10px 15px;
        border-radius: 5px;
        margin: 5px 0;
    ">
        <h4 style="margin:0;color:{color}">{icon} {title}</h4>
        <h2 style="margin:0">{value}</h2>
    </div>
    """, unsafe_allow_html=True)

col1, col2, col3 = st.columns(3)
with col1:
    card("Revenue", "$1.2M", "💰", "#2ecc71")
with col2:
    card("Users", "42,000", "👥", "#3498db")
with col3:
    card("Errors", "3", "⚠️", "#e74c3c")
```