# Gradio — 20+ Demo Examples

## Example 1: Minimal Text Demo
```python
import gradio as gr

def greet(name: str) -> str:
    return f"Hello, {name}! Welcome to Gradio! 👋"

demo = gr.Interface(
    fn=greet,
    inputs=gr.Textbox(label="Your Name", placeholder="Enter name..."),
    outputs=gr.Textbox(label="Greeting"),
    title="Greeter Demo",
    description="Enter your name to get a personalized greeting."
)

demo.launch()
```

## Example 2: Text Classifier
```python
import gradio as gr
from transformers import pipeline

classifier = pipeline("text-classification", model="distilbert-base-uncased-finetuned-sst-2-english")

def classify_sentiment(text: str) -> dict:
    results = classifier(text)
    return {r['label']: r['score'] for r in results}

demo = gr.Interface(
    fn=classify_sentiment,
    inputs=gr.Textbox(lines=3, label="Review Text",
                      placeholder="Enter a product review..."),
    outputs=gr.Label(num_top_classes=2, label="Sentiment"),
    title="Sentiment Classifier",
    examples=[
        ["This product is amazing! I love it."],
        ["Terrible experience. Would not recommend."],
        ["It's okay, nothing special."]
    ],
    cache_examples=False
)
demo.launch()
```

## Example 3: Image Classifier
```python
import gradio as gr
from PIL import Image
import numpy as np

def classify_image(image: Image.Image) -> dict:
    # Replace with your actual model
    arr = np.array(image)
    brightness = arr.mean() / 255
    return {
        "Bright": float(brightness),
        "Dark": float(1 - brightness),
        "Colorful": float(arr.std() / 128)
    }

demo = gr.Interface(
    fn=classify_image,
    inputs=gr.Image(type="pil", label="Upload Image"),
    outputs=gr.Label(num_top_classes=3, label="Analysis"),
    title="Image Analyzer",
    description="Upload an image to analyze its properties."
)
demo.launch()
```

## Example 4: Sklearn Model with Multiple Inputs
```python
import gradio as gr
import joblib
import numpy as np

pipeline = joblib.load("models/hiring_pipeline.pkl")
EDU_MAP = {'High School': 0, "Bachelor's": 1, "Master's": 2, 'PhD': 3}

def predict_hiring(age, salary, experience, education):
    edu_val = EDU_MAP[education]
    features = np.array([[age, salary, experience, edu_val]])
    pred = int(pipeline.predict(features)[0])
    prob = float(pipeline.predict_proba(features).max())
    label = "✅ Likely Hired" if pred == 1 else "❌ Unlikely Hired"
    return label, f"{prob:.1%}"

demo = gr.Interface(
    fn=predict_hiring,
    inputs=[
        gr.Slider(18, 65, 30, step=1, label="Age"),
        gr.Number(value=60000, label="Expected Salary ($)"),
        gr.Slider(0, 30, 5, step=1, label="Years of Experience"),
        gr.Dropdown(list(EDU_MAP.keys()), value="Bachelor's", label="Education")
    ],
    outputs=[
        gr.Textbox(label="Prediction"),
        gr.Textbox(label="Confidence")
    ],
    title="🎯 Hiring Predictor",
    examples=[
        [30, 70000, 5, "Bachelor's"],
        [45, 120000, 20, "Master's"],
        [22, 35000, 0, "High School"]
    ]
)
demo.launch()
```

## Example 5: gr.Blocks with Custom Layout
```python
import gradio as gr
import joblib
import numpy as np

model = joblib.load("models/model.pkl")

with gr.Blocks(title="ML Dashboard", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🤖 ML Prediction Dashboard")

    with gr.Tabs():
        with gr.TabItem("Predict"):
            with gr.Row():
                with gr.Column():
                    gr.Markdown("### Input Features")
                    age = gr.Slider(18, 65, 30, label="Age")
                    salary = gr.Number(60000, label="Salary")
                    exp = gr.Slider(0, 30, 5, label="Experience")
                    btn = gr.Button("Predict", variant="primary")
                with gr.Column():
                    gr.Markdown("### Results")
                    prediction_out = gr.Textbox(label="Prediction")
                    probability_out = gr.Label(label="Probabilities")

            def predict(age, salary, exp):
                features = np.array([[age, salary, exp]])
                pred = int(model.predict(features)[0])
                probs = model.predict_proba(features)[0]
                return (
                    "Hired" if pred == 1 else "Not Hired",
                    {"Hired": float(probs[1]), "Not Hired": float(probs[0])}
                )

            btn.click(predict, inputs=[age, salary, exp],
                     outputs=[prediction_out, probability_out])

        with gr.TabItem("About"):
            gr.Markdown("""
            ## About This Model
            - **Algorithm**: Random Forest Classifier
            - **Training data**: 5000 candidates
            - **Accuracy**: 91.3%
            """)

demo.launch()
```

## Example 6: LLM Chatbot with Streaming
```python
import gradio as gr

def stream_response(message: str, history: list):
    """Stream tokens from LLM"""
    # Replace with actual LLM streaming
    response = f"You said: '{message}'. This is a streaming response example!"
    partial = ""
    for char in response:
        partial += char
        yield partial

with gr.Blocks() as demo:
    gr.Markdown("# 💬 Streaming Chatbot")
    chatbot = gr.Chatbot(height=400)
    msg = gr.Textbox(placeholder="Type your message...", show_label=False)
    with gr.Row():
        submit = gr.Button("Send", variant="primary")
        clear = gr.Button("Clear")

    def user_message(message, history):
        return "", history + [[message, None]]

    def bot_response(history):
        last_user_msg = history[-1][0]
        bot_msg = ""
        for chunk in stream_response(last_user_msg, history[:-1]):
            history[-1][1] = chunk
            yield history

    msg.submit(user_message, [msg, chatbot], [msg, chatbot]).then(
        bot_response, chatbot, chatbot
    )
    submit.click(user_message, [msg, chatbot], [msg, chatbot]).then(
        bot_response, chatbot, chatbot
    )
    clear.click(lambda: [], None, chatbot)

demo.launch()
```

## Example 7: Audio Transcription
```python
import gradio as gr

def transcribe_audio(audio_path: str) -> str:
    """Transcribe audio using Whisper"""
    import whisper
    model = whisper.load_model("base")
    result = model.transcribe(audio_path)
    return result["text"]

demo = gr.Interface(
    fn=transcribe_audio,
    inputs=gr.Audio(type="filepath", sources=["upload", "microphone"],
                    label="Audio Input"),
    outputs=gr.Textbox(lines=5, label="Transcription"),
    title="🎙️ Audio Transcriber",
    description="Upload audio or record from microphone to transcribe."
)
demo.launch()
```

## Example 8: Image-to-Image Transformation
```python
import gradio as gr
from PIL import Image, ImageFilter, ImageOps
import numpy as np

def transform_image(image, operation, intensity):
    if operation == "Blur":
        result = image.filter(ImageFilter.GaussianBlur(radius=intensity))
    elif operation == "Sharpen":
        for _ in range(int(intensity)):
            result = image.filter(ImageFilter.SHARPEN)
    elif operation == "Edge Detect":
        result = image.filter(ImageFilter.FIND_EDGES)
    elif operation == "Grayscale":
        result = ImageOps.grayscale(image).convert('RGB')
    else:
        result = image
    return result

demo = gr.Interface(
    fn=transform_image,
    inputs=[
        gr.Image(type="pil", label="Input Image"),
        gr.Dropdown(["Blur", "Sharpen", "Edge Detect", "Grayscale"], label="Operation"),
        gr.Slider(1, 10, 3, step=1, label="Intensity")
    ],
    outputs=gr.Image(type="pil", label="Output Image"),
    title="🎨 Image Transformer",
    live=False
)
demo.launch()
```

## Example 9: Batch Processing
```python
import gradio as gr
import numpy as np

def batch_classify(texts):
    """Process a batch of texts"""
    return [f"Category: {'A' if len(t) > 10 else 'B'}" for t in texts]

demo = gr.Interface(
    fn=batch_classify,
    inputs=gr.Textbox(lines=10, label="Enter texts (one per line)"),
    outputs=gr.Textbox(lines=10, label="Classifications"),
    title="Batch Text Classifier"
)
demo.launch()
```

## Example 10: gr.State for Multi-Turn Conversation
```python
import gradio as gr

def add_to_history(message: str, history: list) -> tuple:
    history = history or []
    response = f"Received: {message}"
    history.append((message, response))
    return history, history, ""

with gr.Blocks() as demo:
    history_state = gr.State([])
    chatbot = gr.Chatbot()
    msg_input = gr.Textbox(placeholder="Message...")
    submit_btn = gr.Button("Send")

    submit_btn.click(
        fn=add_to_history,
        inputs=[msg_input, history_state],
        outputs=[chatbot, history_state, msg_input]
    )

demo.launch()
```

## Example 11: Dataframe Input/Output
```python
import gradio as gr
import pandas as pd

def analyze_dataframe(df: pd.DataFrame) -> tuple:
    stats = df.describe()
    missing = df.isnull().sum().to_frame("missing").T
    return stats, missing

demo = gr.Interface(
    fn=analyze_dataframe,
    inputs=gr.Dataframe(
        headers=["age", "salary", "experience"],
        datatype=["number", "number", "number"],
        row_count=5,
        label="Input Data"
    ),
    outputs=[
        gr.Dataframe(label="Statistics"),
        gr.Dataframe(label="Missing Values")
    ],
    title="DataFrame Analyzer"
)
demo.launch()
```

## Example 12: Progress Tracking
```python
import gradio as gr
import time

def long_process(n_steps: int, progress=gr.Progress()):
    progress(0, desc="Starting...")
    results = []
    for i in range(n_steps):
        time.sleep(0.2)
        results.append(f"Step {i+1}: processed")
        progress((i + 1) / n_steps, desc=f"Step {i+1}/{n_steps}")
    return "\n".join(results)

demo = gr.Interface(
    fn=long_process,
    inputs=gr.Slider(1, 20, 5, step=1, label="Steps"),
    outputs=gr.Textbox(lines=10, label="Results"),
    title="Progress Demo"
)
demo.launch()
```

## Example 13: Authentication
```python
import gradio as gr

def secret_function(text: str) -> str:
    return f"SECRET OUTPUT: {text.upper()}"

demo = gr.Interface(
    fn=secret_function,
    inputs="text",
    outputs="text",
    title="Protected Demo"
)

demo.launch(
    auth=[("alice", "pass123"), ("bob", "secure456")],
    auth_message="🔒 Enter your credentials to access this demo"
)
```

## Example 14: Custom CSS Styling
```python
import gradio as gr

custom_css = """
.gradio-container {
    max-width: 800px !important;
    margin: 0 auto;
}
.prediction-box {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 20px;
    border-radius: 10px;
    text-align: center;
    font-size: 1.5em;
}
"""

with gr.Blocks(css=custom_css, title="Styled Demo") as demo:
    gr.Markdown("# 🎨 Custom Styled App")
    with gr.Row():
        inp = gr.Textbox(label="Input", elem_id="main-input")
        out = gr.HTML(elem_classes=["prediction-box"])
    btn = gr.Button("Process", variant="primary")

    def process(text):
        return f'<div class="prediction-box">Result: {text.upper()}</div>'

    btn.click(process, inputs=inp, outputs=out)

demo.launch()
```

## Example 15: HuggingFace Model Integration
```python
import gradio as gr
from transformers import pipeline

# Zero-shot classification
classifier = pipeline("zero-shot-classification",
                      model="facebook/bart-large-mnli")

def classify(text: str, labels_str: str) -> dict:
    labels = [l.strip() for l in labels_str.split(",")]
    result = classifier(text, candidate_labels=labels)
    return dict(zip(result['labels'], result['scores']))

demo = gr.Interface(
    fn=classify,
    inputs=[
        gr.Textbox(lines=3, label="Text to classify"),
        gr.Textbox(value="sports, politics, technology, science",
                   label="Labels (comma-separated)")
    ],
    outputs=gr.Label(num_top_classes=5, label="Classification"),
    title="🎯 Zero-Shot Text Classifier",
    examples=[
        ["The new iPhone has a better camera.", "technology, fashion, sports"],
        ["The team won the championship.", "sports, politics, science"],
    ]
)
demo.launch()
```

## Example 16: Video Processing
```python
import gradio as gr
import cv2
import numpy as np

def process_video(video_path: str) -> str:
    cap = cv2.VideoCapture(video_path)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    duration = frame_count / fps
    cap.release()
    return f"Frames: {frame_count}, FPS: {fps:.1f}, Duration: {duration:.1f}s"

demo = gr.Interface(
    fn=process_video,
    inputs=gr.Video(label="Upload Video"),
    outputs=gr.Textbox(label="Video Info"),
    title="🎥 Video Analyzer"
)
demo.launch()
```

## Example 17: Multi-Model Comparison
```python
import gradio as gr
import joblib
import numpy as np

models = {
    "Logistic Regression": joblib.load("models/lr_model.pkl"),
    "Random Forest": joblib.load("models/rf_model.pkl"),
    "SVM": joblib.load("models/svm_model.pkl"),
}

def compare_models(age, salary, experience):
    features = np.array([[age, salary, experience]])
    results = {}
    for name, model in models.items():
        pred = int(model.predict(features)[0])
        prob = float(model.predict_proba(features).max())
        results[name] = f"{'Hired' if pred==1 else 'Not Hired'} ({prob:.1%})"

    return "\n".join(f"**{k}**: {v}" for k, v in results.items())

demo = gr.Interface(
    fn=compare_models,
    inputs=[
        gr.Slider(18, 65, 30, label="Age"),
        gr.Number(60000, label="Salary"),
        gr.Slider(0, 30, 5, label="Experience")
    ],
    outputs=gr.Markdown(label="Model Comparison"),
    title="🏆 Multi-Model Comparison"
)
demo.launch()
```

## Example 18: Gradio API Client Usage
```python
# Server (app.py)
import gradio as gr

def predict(text: str) -> str:
    return text.upper()

demo = gr.Interface(fn=predict, inputs="text", outputs="text")
demo.launch(server_port=7860)

# Client (client.py) — call the Gradio app programmatically
from gradio_client import Client

client = Client("http://localhost:7860")

# Single prediction
result = client.predict("hello world", api_name="/predict")
print(result)  # "HELLO WORLD"

# From HuggingFace Space
client = Client("username/my-space")
result = client.predict("input text", api_name="/predict")
```

## Example 19: Accordion and Group Layout
```python
import gradio as gr

with gr.Blocks() as demo:
    gr.Markdown("# Advanced Layout Demo")

    with gr.Row():
        with gr.Column(scale=2):
            main_input = gr.Textbox(label="Main Input", lines=3)
            with gr.Accordion("Advanced Options", open=False):
                temperature = gr.Slider(0.1, 2.0, 0.7, label="Temperature")
                max_tokens = gr.Slider(50, 2000, 200, step=50, label="Max Tokens")
                stop_seq = gr.Textbox(label="Stop Sequence")
            submit = gr.Button("Generate", variant="primary")
        with gr.Column(scale=1):
            output = gr.Textbox(label="Output", lines=10)
            with gr.Group():
                gr.Markdown("**Stats**")
                word_count = gr.Number(label="Word Count", interactive=False)
                char_count = gr.Number(label="Char Count", interactive=False)

    def process(text, temp, max_t, stop):
        result = f"Generated from: {text} (temp={temp})"
        return result, len(result.split()), len(result)

    submit.click(process, [main_input, temperature, max_tokens, stop_seq],
                 [output, word_count, char_count])

demo.launch()
```

## Example 20: Full ML App with Tabs and Analysis
```python
import gradio as gr
import joblib
import numpy as np
import pandas as pd

pipeline = joblib.load("models/pipeline.pkl")
FEATURES = ['age', 'salary', 'experience']

def predict_single(age, salary, exp):
    feat = np.array([[age, salary, exp]])
    pred = int(pipeline.predict(feat)[0])
    prob = float(pipeline.predict_proba(feat).max())
    return ("✅ Hired" if pred == 1 else "❌ Not Hired",
            f"Confidence: {prob:.1%}")

def predict_batch(file):
    df = pd.read_csv(file.name)[FEATURES]
    preds = pipeline.predict(df)
    probs = pipeline.predict_proba(df).max(axis=1)
    df['prediction'] = preds
    df['confidence'] = probs.round(3)
    df['label'] = df['prediction'].map({1: 'Hired', 0: 'Not Hired'})
    return df

with gr.Blocks(title="Hiring Prediction Tool") as demo:
    gr.Markdown("# 🏢 Hiring Prediction Tool")
    with gr.Tabs():
        with gr.TabItem("Single Prediction"):
            with gr.Row():
                age_in = gr.Slider(18, 65, 30, label="Age")
                sal_in = gr.Number(60000, label="Salary ($)")
                exp_in = gr.Slider(0, 30, 5, label="Experience")
            btn = gr.Button("Predict")
            pred_out = gr.Textbox(label="Result")
            conf_out = gr.Textbox(label="Confidence")
            btn.click(predict_single, [age_in, sal_in, exp_in], [pred_out, conf_out])

        with gr.TabItem("Batch Prediction"):
            file_in = gr.File(label="Upload CSV", file_types=[".csv"])
            batch_btn = gr.Button("Process Batch")
            results_out = gr.Dataframe(label="Results")
            batch_btn.click(predict_batch, file_in, results_out)

demo.launch(share=False)
```