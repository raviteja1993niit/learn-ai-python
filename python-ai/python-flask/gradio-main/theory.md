# Gradio — ML Demo Interfaces — Theory & Concepts

## 1. Gradio Philosophy
Gradio lets you build ML demo interfaces with minimal code — typically 3-5 lines for a basic app.

**Core idea**: Wrap any Python function with a UI and share it instantly.

```
Python function → Gradio Interface → Web UI + REST API + shareable link
```

Use cases:
- Demo your trained model to stakeholders
- Internal testing tool for data scientists
- Public-facing ML showcase on HuggingFace Spaces
- Prototype before building a full frontend

Every Gradio app automatically exposes a REST API that anyone can call.

## 2. Interface vs Blocks

### gr.Interface — Simple
For functions with clear inputs → outputs:
```python
import gradio as gr

def greet(name: str, formal: bool) -> str:
    greeting = "Good day" if formal else "Hey"
    return f"{greeting}, {name}!"

demo = gr.Interface(
    fn=greet,
    inputs=["text", "checkbox"],
    outputs="text",
    title="Greeter",
    description="Enter your name to get a greeting"
)
demo.launch()
```

### gr.Blocks — Advanced
Full layout control with event-driven logic:
```python
with gr.Blocks() as demo:
    gr.Markdown("# My App")
    with gr.Row():
        inp = gr.Textbox(label="Input")
        out = gr.Textbox(label="Output")
    btn = gr.Button("Submit")
    btn.click(fn=process, inputs=inp, outputs=out)
demo.launch()
```

| Feature              | Interface          | Blocks              |
|----------------------|--------------------|---------------------|
| Simplicity           | ✅ Very simple     | ❌ More verbose     |
| Layout control       | ❌ Limited         | ✅ Full control     |
| Multiple functions   | ❌ One function    | ✅ Multiple         |
| State management     | ❌ Basic           | ✅ gr.State()       |
| Custom events        | ❌ Limited         | ✅ Full event API   |

## 3. Input Components

### Text Inputs
```python
gr.Textbox(label="Name", placeholder="Enter name...", lines=1)
gr.Textbox(label="Prompt", lines=5, max_lines=20)
gr.Number(label="Age", minimum=0, maximum=120, step=1, value=25)
```

### Numeric Inputs
```python
gr.Slider(minimum=0, maximum=100, step=1, value=50, label="Threshold")
gr.Number(minimum=0.0, maximum=1.0, step=0.01, value=0.5)
```

### Selection Inputs
```python
gr.Dropdown(choices=["Option A", "B", "C"], value="A", label="Model")
gr.Dropdown(choices=["A", "B"], multiselect=True, label="Tags")
gr.Checkbox(label="Use GPU", value=False)
gr.CheckboxGroup(choices=["A", "B", "C"], label="Features", value=["A"])
gr.Radio(choices=["Small", "Medium", "Large"], label="Size", value="Medium")
```

### Media Inputs
```python
gr.Image(type="pil")           # PIL Image
gr.Image(type="numpy")         # NumPy array
gr.Image(type="filepath")      # File path string
gr.Image(sources=["upload", "webcam", "clipboard"])
gr.Audio(type="filepath", sources=["upload", "microphone"])
gr.Video(sources=["upload", "webcam"])
gr.File(file_types=[".csv", ".xlsx"], file_count="single")
gr.File(file_count="multiple")
```

### Data Inputs
```python
gr.Dataframe(headers=["Name", "Age"], row_count=5, col_count=2)
gr.JSON(label="Input JSON")
gr.Code(language="python", label="Code")
```

## 4. Output Components

### Text Outputs
```python
gr.Textbox(label="Result")
gr.Markdown()            # Renders markdown
gr.HTML()                # Renders HTML
gr.JSON()                # Expandable JSON tree
gr.Code(language="python")
```

### Classification Output
```python
# For classifiers — shows label with confidence bars
gr.Label(num_top_classes=5)
# Input: {"cat": 0.9, "dog": 0.08, "bird": 0.02}
```

### Media Outputs
```python
gr.Image()               # Display image
gr.Audio()               # Play audio
gr.Video()               # Play video
gr.Plot()                # Matplotlib figure
gr.Gallery()             # Grid of images
```

### Data Outputs
```python
gr.Dataframe()           # Table
gr.JSON()                # JSON viewer
gr.HTML()                # Rich HTML
gr.HighlightedText()     # Text with highlighted spans
gr.AnnotatedImage()      # Image with bounding boxes
```

## 5. gr.Interface Full Reference
```python
demo = gr.Interface(
    fn=predict,                          # Function to wrap
    inputs=[
        gr.Image(type="pil"),
        gr.Slider(0, 1, 0.5, label="Threshold")
    ],
    outputs=[
        gr.Label(num_top_classes=3),
        gr.Textbox(label="Confidence")
    ],
    title="Image Classifier",
    description="Upload an image to classify it",
    article="## About\nThis uses ResNet-50 trained on ImageNet.",
    examples=[                           # Pre-loaded examples
        ["examples/cat.jpg", 0.7],
        ["examples/dog.jpg", 0.5]
    ],
    cache_examples=True,                 # Cache example outputs
    flagging_mode="never",               # Disable flagging
    allow_flagging="never",              # Older versions
    live=False,                          # Auto-submit on input change
    theme=gr.themes.Soft(),
)
```

## 6. gr.Blocks — Flexible Layout

### Rows and Columns
```python
with gr.Blocks() as demo:
    gr.Markdown("# Classifier")
    with gr.Row():
        with gr.Column(scale=2):
            image_in = gr.Image(label="Input Image")
            threshold = gr.Slider(0, 1, 0.5, label="Threshold")
        with gr.Column(scale=1):
            label_out = gr.Label(num_top_classes=5)
    btn = gr.Button("Classify", variant="primary")
    btn.click(fn=classify, inputs=[image_in, threshold], outputs=label_out)
```

### Groups and Tabs
```python
with gr.Blocks() as demo:
    with gr.Tab("Image"):
        img_in = gr.Image()
        img_out = gr.Image()
        gr.Button("Process").click(process_image, img_in, img_out)

    with gr.Tab("Text"):
        text_in = gr.Textbox(lines=5)
        text_out = gr.Textbox()
        gr.Button("Analyze").click(analyze_text, text_in, text_out)

    with gr.Accordion("Advanced Settings", open=False):
        model_choice = gr.Dropdown(["v1", "v2"], label="Model version")
```

## 7. Event Listeners
```python
with gr.Blocks() as demo:
    inp = gr.Textbox()
    out = gr.Textbox()
    btn = gr.Button()

    # Click
    btn.click(fn=process, inputs=inp, outputs=out)

    # Change (fires on every keystroke)
    inp.change(fn=validate, inputs=inp, outputs=out)

    # Submit (fires on Enter key)
    inp.submit(fn=process, inputs=inp, outputs=out)

    # Upload (fires when file uploaded)
    file = gr.File()
    file.upload(fn=handle_upload, inputs=file, outputs=out)

    # Select (fires when selection changes)
    dropdown = gr.Dropdown(["A", "B", "C"])
    dropdown.select(fn=on_select, inputs=dropdown, outputs=out)
```

### Multiple inputs/outputs
```python
btn.click(
    fn=analyze,
    inputs=[text, slider, checkbox],   # Multiple inputs
    outputs=[result, confidence, plot] # Multiple outputs
)
```

## 8. State Management
```python
with gr.Blocks() as demo:
    # gr.State persists between interactions for a single user session
    history_state = gr.State(value=[])

    chatbox = gr.Chatbot()
    user_input = gr.Textbox(placeholder="Say something...")
    clear_btn = gr.Button("Clear")

    def chat(message, history):
        response = llm_generate(message, history)
        history = history + [[message, response]]
        return "", history

    user_input.submit(chat, [user_input, history_state], [user_input, chatbox])
    clear_btn.click(lambda: [], None, chatbox)
```

## 9. Streaming Outputs (Real-time LLM)
```python
def stream_text(prompt: str):
    """Generator function for streaming"""
    for token in llm.stream(prompt):
        yield token  # Each yield updates the output

with gr.Blocks() as demo:
    prompt = gr.Textbox(label="Prompt")
    output = gr.Textbox(label="Response", lines=10)
    btn = gr.Button("Generate")

    btn.click(
        fn=stream_text,
        inputs=prompt,
        outputs=output,
        stream_every=0.1  # Update every 100ms
    )
```

## 10. Custom CSS and JS
```python
custom_css = """
.gradio-container { background: #f0f0f0; }
.output-textbox { font-family: monospace; }
"""

with gr.Blocks(css=custom_css) as demo:
    gr.Markdown("# Styled App")
    with gr.Row(elem_classes=["custom-row"]):
        inp = gr.Textbox(elem_id="my-input")

# Custom JS
demo = gr.Interface(
    fn=fn,
    inputs="text",
    outputs="text",
    js="() => { console.log('Page loaded'); }"  # Runs on load
)
```

## 11. Authentication
```python
# Simple authentication
demo.launch(
    auth=("admin", "password123"),
    auth_message="Enter credentials to access the demo"
)

# Multiple users
demo.launch(
    auth=[("alice", "pass1"), ("bob", "pass2")]
)

# Function-based auth
def check_auth(username, password):
    return username == "admin" and password == "secret"

demo.launch(auth=check_auth)
```

## 12. Queueing for Production
```python
# Without queue: one request processed at a time
demo.launch()

# With queue: handles concurrent users
demo.queue(
    max_size=20,          # Max queued requests
    default_concurrency_limit=2  # Parallel processing
).launch()

# Per-function concurrency
@demo.fn(concurrency_limit=5)
def fast_function(x):
    ...
```

## 13. Batch Processing
```python
def batch_classify(batch_inputs):
    return model.predict(batch_inputs)

demo = gr.Interface(
    fn=batch_classify,
    inputs=gr.Image(),
    outputs=gr.Label(),
    batch=True,
    max_batch_size=16
)
```

## 14. API Access
Every Gradio app exposes a REST API:

```python
# Python client
from gradio_client import Client

client = Client("http://localhost:7860")
result = client.predict("Hello world", api_name="/predict")

# Or from HuggingFace Spaces
client = Client("username/space-name")
result = client.predict("input", api_name="/predict")
```

```bash
# curl
curl -X POST http://localhost:7860/api/predict \
  -H "Content-Type: application/json" \
  -d '{"data": ["Hello world"]}'
```

## 15. Share Link and HuggingFace Spaces
```python
# Instant public URL (72 hours)
demo.launch(share=True)

# Deploy to HuggingFace Spaces
# 1. Create a Space at huggingface.co/spaces
# 2. Push your code with a requirements.txt and app.py
# 3. Spaces auto-deploys on git push
```

```
# requirements.txt for Spaces
gradio>=4.0.0
transformers
torch
```

## 16. Themes
```python
# Built-in themes
demo = gr.Interface(fn=fn, inputs="text", outputs="text",
                    theme=gr.themes.Base())      # Default
demo = gr.Interface(..., theme=gr.themes.Soft())
demo = gr.Interface(..., theme=gr.themes.Monochrome())
demo = gr.Interface(..., theme=gr.themes.Glass())

# Custom theme
theme = gr.themes.Default(
    primary_hue=gr.themes.colors.purple,
    secondary_hue=gr.themes.colors.pink,
    font=gr.themes.GoogleFont("Roboto")
)
demo = gr.Interface(..., theme=theme)
```

## 17. Progress and Loading
```python
def long_running(input, progress=gr.Progress()):
    progress(0, desc="Starting...")
    for i in range(100):
        process_step(i)
        progress((i+1)/100, desc=f"Step {i+1}/100")
    return "Done!"

demo = gr.Interface(fn=long_running, inputs="text", outputs="text")
```

## 18. Integrating Models
```python
# Sklearn
from sklearn.pipeline import Pipeline
import joblib

pipeline = joblib.load('pipeline.pkl')

def predict(age, salary, experience):
    import pandas as pd
    df = pd.DataFrame([[age, salary, experience]],
                      columns=['age', 'salary', 'experience'])
    pred = pipeline.predict(df)[0]
    prob = pipeline.predict_proba(df).max()
    return f"Prediction: {pred}", f"Confidence: {prob:.1%}"

# HuggingFace Transformers
from transformers import pipeline as hf_pipeline
classifier = hf_pipeline("sentiment-analysis")

def sentiment(text):
    result = classifier(text)[0]
    return {result['label']: result['score']}
```