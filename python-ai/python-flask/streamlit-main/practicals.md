# Streamlit — 10 Hands-On Projects

## Project 1: CSV Explorer App
**Goal**: Build a fully interactive CSV data explorer

### Features
- Drag-and-drop CSV upload
- Auto-detect column types
- Show: shape, dtypes, missing values heatmap, duplicates count
- Per-column analysis: distribution charts, value counts, outlier detection (IQR method)
- Correlation matrix with interactive Plotly heatmap
- Filter rows by column values
- Download filtered data as CSV

### Hints
```python
@st.cache_data
def load_and_profile(file):
    df = pd.read_csv(file)
    return df, df.describe(), df.isnull().sum()
```

---

## Project 2: ML Model Demo App
**Goal**: Interactive demo for a trained classification model

### Features
- Sidebar: all feature inputs (sliders, dropdowns, number inputs)
- Center: prediction result with confidence bar
- Show feature importance chart (if Random Forest/Gradient Boosting)
- Show SHAP values for the current prediction (use `shap` library)
- History: log last 10 predictions in session_state
- Download prediction history as CSV

### Hints
```python
@st.cache_resource
def load_model():
    return joblib.load("models/model.pkl")

if "history" not in st.session_state:
    st.session_state.history = []
```

---

## Project 3: LLM Chatbot UI
**Goal**: Build a ChatGPT-like interface

### Features
- Chat history displayed with st.chat_message
- User input at bottom with st.chat_input
- System prompt in sidebar (customizable)
- Model selector in sidebar (gpt-4o, gpt-3.5-turbo, etc.)
- Temperature slider
- Clear conversation button
- Export conversation as markdown
- Token count estimate in sidebar

### Hints
```python
import openai

client = openai.OpenAI(api_key=st.secrets["openai"]["api_key"])

def get_response(messages, model, temperature):
    with st.chat_message("assistant"):
        stream = client.chat.completions.create(
            model=model, messages=messages,
            temperature=temperature, stream=True
        )
        response = st.write_stream(stream)
    return response
```

---

## Project 4: Real-Time Stock Dashboard
**Goal**: Live stock price tracker with charts

### Features
- Sidebar: enter stock tickers (comma-separated)
- Auto-refresh every 30 seconds using `st.rerun()`
- For each ticker: current price, % change, volume
- Interactive candlestick chart (Plotly)
- Moving averages (SMA 20, SMA 50)
- Portfolio summary: total value, daily P&L

### Hints
```python
import yfinance as yf

@st.cache_data(ttl=30)  # Refresh every 30 seconds
def get_stock_data(ticker: str, period: str = "1mo"):
    return yf.Ticker(ticker).history(period=period)
```

---

## Project 5: Image Segmentation / Object Detection Demo
**Goal**: Run YOLO or a custom CV model in a Streamlit app

### Features
- Upload image or use webcam (st.camera_input)
- Run object detection model
- Display annotated image with bounding boxes
- Show detection results table (class, confidence, bbox)
- Toggle between models (YOLOv8 small/medium/large)
- Side-by-side: original vs annotated

### Hints
```python
@st.cache_resource
def load_yolo():
    from ultralytics import YOLO
    return YOLO("yolov8n.pt")

model = load_yolo()
results = model(image_array)
annotated = results[0].plot()
st.image(annotated, caption="Detected Objects")
```

---

## Project 6: Time-Series Forecasting App
**Goal**: Upload time-series data and run forecasting

### Features
- Upload CSV with `date` and `value` columns
- Visualize raw time series
- Select forecasting model: Prophet, ARIMA, or simple linear trend
- Configure forecast horizon (1-365 days)
- Show forecast with confidence intervals
- Display model metrics (RMSE, MAE on holdout set)
- Download forecast as CSV

### Hints
```python
from prophet import Prophet

@st.cache_data
def run_prophet(df, periods):
    m = Prophet(yearly_seasonality=True)
    m.fit(df.rename(columns={"date": "ds", "value": "y"}))
    future = m.make_future_dataframe(periods=periods)
    return m.predict(future)
```

---

## Project 7: Multi-Page Data Science Platform
**Goal**: Multi-page Streamlit app for an end-to-end ML workflow

### Pages Structure
```
app.py         — Landing page with overview
pages/
├── 1_Upload.py      — Upload & validate data
├── 2_EDA.py         — Exploratory data analysis
├── 3_Preprocess.py  — Feature engineering, encoding
├── 4_Train.py       — Train multiple models, compare metrics
├── 5_Evaluate.py    — Confusion matrix, ROC curve, feature importance
└── 6_Predict.py     — Use trained model for predictions
```

### Key Feature: Shared State
Use `st.session_state` to share data between pages:
```python
# In Upload.py
if uploaded:
    st.session_state.df = pd.read_csv(uploaded)

# In EDA.py
if "df" not in st.session_state:
    st.warning("Please upload data first")
    st.stop()
df = st.session_state.df
```

---

## Project 8: A/B Test Analyzer
**Goal**: Statistical A/B test calculator and visualizer

### Features
- Input: control vs treatment metrics (conversion rates, sample sizes)
- Calculate: Z-test or T-test for significance
- Visualize: distribution curves for both groups
- Show: p-value, confidence interval, effect size, power
- Bayesian A/B test option (beta distribution update)
- Minimum detectable effect calculator

### Hints
```python
from scipy import stats

def run_z_test(n_a, conv_a, n_b, conv_b):
    p_a = conv_a / n_a
    p_b = conv_b / n_b
    p_pool = (conv_a + conv_b) / (n_a + n_b)
    z = (p_b - p_a) / (p_pool * (1 - p_pool) * (1/n_a + 1/n_b)) ** 0.5
    p_value = 2 * (1 - stats.norm.cdf(abs(z)))
    return z, p_value
```

---

## Project 9: NLP Text Analysis Tool
**Goal**: Text analysis dashboard with multiple NLP features

### Features
- Text input (paste or upload .txt file)
- Sentiment analysis (positive/negative/neutral score)
- Named entity recognition (highlight persons, orgs, locations)
- Keyword extraction (TF-IDF top-N keywords)
- Summary generation (extractive or using transformers)
- Word cloud visualization
- Readability scores (Flesch-Kincaid)

### Hints
```python
import spacy
nlp = spacy.load("en_core_web_sm")

@st.cache_resource
def get_nlp():
    return spacy.load("en_core_web_sm")
```

---

## Project 10: Deployment and Sharing
**Goal**: Deploy a Streamlit app to Streamlit Community Cloud

### Steps
1. Complete one of the above projects
2. Add `requirements.txt` with pinned versions
3. Add `.streamlit/config.toml` for theme/settings
4. Add `.streamlit/secrets.toml` (local only, add to .gitignore)
5. Push to GitHub (public or private repo)
6. Sign into share.streamlit.io
7. Deploy: connect repo, set main file path
8. Add secrets in the Streamlit Cloud dashboard

### requirements.txt Template
```
streamlit>=1.28.0
pandas>=2.0.0
plotly>=5.17.0
scikit-learn>=1.3.0
joblib>=1.3.0
numpy>=1.24.0
```

### Checklist
- [ ] No hardcoded secrets
- [ ] All dependencies in requirements.txt
- [ ] App starts in < 30 seconds
- [ ] Health check: app responds at the root URL
- [ ] Works on mobile (use `layout="wide"` carefully)