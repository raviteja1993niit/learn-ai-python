# 🎨 Streamlit — Build AI/ML Web Apps in Pure Python

## What is Streamlit?
Streamlit turns Python scripts into **interactive web apps in minutes** — no HTML, CSS, or JavaScript needed.
It is the fastest way to demo any ML/AI model to stakeholders.

## Why Learn It?
- Industry standard for ML demos and internal tools
- Used by data scientists at Google, Uber, Airbnb
- Integrates natively with Pandas, Matplotlib, Plotly, PyTorch, TensorFlow, LangChain

## Key Concepts

| Concept | Code |
|---------|------|
| Display text | `st.title()`, `st.header()`, `st.write()`, `st.markdown()` |
| Input widgets | `st.text_input()`, `st.slider()`, `st.selectbox()`, `st.file_uploader()` |
| Display data | `st.dataframe()`, `st.table()`, `st.json()` |
| Charts | `st.line_chart()`, `st.bar_chart()`, `st.plotly_chart()` |
| Images/Video | `st.image()`, `st.video()`, `st.audio()` |
| Layout | `st.sidebar`, `st.columns()`, `st.tabs()`, `st.expander()` |
| State | `st.session_state` — persist data across reruns |
| Caching | `@st.cache_data`, `@st.cache_resource` |
| Forms | `st.form()` + `st.form_submit_button()` |

## Learning Path
1. `pip install streamlit`
2. `streamlit hello` — run demo app
3. Build a simple app: `streamlit run app.py`
4. Add ML model predictions
5. Add file upload + dynamic charts
6. Deploy to Streamlit Cloud (free)

## What to Build
- [ ] Iris flower classifier (input features → predict species)
- [ ] CSV uploader + auto EDA dashboard
- [ ] Chat interface for LangChain/OpenAI app
- [ ] House price prediction form with sliders
- [ ] Image classification app (upload image → predict)

## Resources
- https://docs.streamlit.io/
- https://streamlit.io/gallery — inspiration gallery
- `pip install streamlit langchain openai` — LangChain + Streamlit combo

## Related Folders
- `python-flask/Gradio-main/` — Gradio comparison (simpler, less flexible)
- `python-flask/FastAPI-main/` — FastAPI for REST APIs
- `ml-projects/` — wrap any ML project with Streamlit