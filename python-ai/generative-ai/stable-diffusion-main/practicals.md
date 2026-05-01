# Stable Diffusion & Diffusion Models — Practical Projects (10 Projects)

```bash
pip install diffusers transformers accelerate safetensors torch torchvision pillow
pip install openai requests streamlit replicate
```
Requires CUDA GPU (4GB+ VRAM minimum).

---

## Project 1 — Product Image Generator
**Goal**: Generate professional product images from text descriptions.
**Features**: multiple style variations, white/gradient backgrounds, watermark overlay, batch export
**Stack**: SDXL + Streamlit
**Key concepts**: SDXL generation, prompt templates, PIL image post-processing
**Prompt template**: "product photography of {product}, white background, studio lighting, highly detailed, 8k, commercial quality"
**Hint**:
```python
import streamlit as st
product = st.text_input("Product description")
style = st.selectbox("Style", ["studio white","lifestyle","minimalist"])
styles = {"studio white":"white background, studio lighting","lifestyle":"natural setting, ambient light","minimalist":"pure white, drop shadow"}
if st.button("Generate") and product:
    prompt = f"product photography of {product}, {styles[style]}, 8k quality"
    img = pipe(prompt=prompt, guidance_scale=7.5, num_inference_steps=30).images[0]
    st.image(img)
```
**Extension**: Add one-click background removal using `rembg` library.

---

## Project 2 — Avatar Creator
**Goal**: Create stylised avatars from face photos or descriptions.
**Features**: multiple style presets (anime, oil painting, cartoon, sketch), custom style input
**Stack**: img2img pipeline with style LoRA, or ControlNet (IP-Adapter for face)
**Key concepts**: img2img strength, style transfer, face-preserving generation
**Hint**: For face preservation, use IP-Adapter:
```bash
pip install ip-adapter
```
```python
from ip_adapter import IPAdapterFaceID
# ip_model.generate(prompt="anime style portrait", face_image=face_image, ...)
```
**Extension**: Batch process a folder of portraits to generate matching avatars.

---

## Project 3 — Style Transfer App
**Goal**: Transform photos into artwork styles (Van Gogh, Monet, Picasso, anime).
**Features**: style library, strength control, before/after comparison, gallery
**Stack**: img2img + style LoRA weights
**Key concepts**: img2img strength parameter, style LoRA loading, comparison UI
**Hint**:
```python
styles = {
    "Van Gogh": ("Van Gogh style, impressionist, swirling brushstrokes", "van_gogh_lora.safetensors"),
    "Anime": ("anime style, vibrant colors, by Makoto Shinkai", "anime_lora.safetensors"),
}
style_name = "Van Gogh"
prompt, lora = styles[style_name]
pipe.load_lora_weights("path/to/", weight_name=lora)
result = img2img_pipe(prompt=prompt, image=input_image, strength=0.65).images[0]
```

---

## Project 4 — Dataset Augmentation Tool
**Goal**: Generate synthetic training data for ML models.
**Use cases**: augment limited datasets, generate rare-class examples, create synthetic annotations
**Features**: configurable prompts, variation seeds, metadata export, quality filter
**Key concepts**: batch generation, seed variation, systematic prompt variation
**Hint**: Generate variations by systematically changing: lighting conditions, angles, backgrounds, weather
```python
base_prompt = "a {color} car on a {surface} road, {weather}"
for color in ["red","blue","white"]:
    for weather in ["sunny","rainy","foggy"]:
        prompt = base_prompt.format(color=color, surface="asphalt", weather=weather)
        img = pipe(prompt=prompt, generator=torch.Generator("cuda").manual_seed(42)).images[0]
```

---

## Project 5 — ControlNet Pose-to-Image
**Goal**: Generate images matching a specific human pose.
**Features**: extract pose from reference image, generate different scenarios with same pose
**Stack**: OpenPose ControlNet + SD 1.5 or SDXL
**Key concepts**: ControlNet conditioning, pose extraction, controlnet_conditioning_scale
**Setup**:
```bash
pip install controlnet-aux
```
**Hint**:
```python
from controlnet_aux import OpenposeDetector
detector = OpenposeDetector.from_pretrained("lllyasviel/ControlNet")
pose_image = detector(input_image)  # extract pose skeleton
result = ctrl_pipe(prompt="a superhero in this pose, digital art", image=pose_image).images[0]
```

---

## Project 6 — Inpainting Object Remover
**Goal**: Remove unwanted objects from photos using inpainting.
**Features**: interactive mask drawing UI, multiple fill options, batch processing
**Stack**: SD Inpainting pipeline + Gradio UI
**Key concepts**: inpainting strength, mask creation, prompt for fill
**Hint**:
```python
import gradio as gr
def remove_object(image_dict):
    image = image_dict["image"]
    mask = image_dict["mask"]
    result = inpaint_pipe(
        prompt="clean background, natural, seamless",
        image=image, mask_image=mask,
        num_inference_steps=50, guidance_scale=7.5
    ).images[0]
    return result
demo = gr.Interface(fn=remove_object, inputs=gr.ImageMask(), outputs="image")
demo.launch()
```

---

## Project 7 — Automatic1111 Batch Processor
**Goal**: Automate batch image generation via A1111 REST API.
**Features**: CSV prompt list, parameter variations (CFG, steps, seed), result naming, gallery
**Key concepts**: A1111 API, JSON payload, base64 decoding, file organisation
**Hint**:
```python
import csv, requests, base64, os
def process_csv(csv_file, output_dir="outputs"):
    os.makedirs(output_dir, exist_ok=True)
    with open(csv_file) as f:
        for i, row in enumerate(csv.DictReader(f)):
            payload = {"prompt":row["prompt"],"negative_prompt":row.get("neg",""),
                       "steps":int(row.get("steps",25)),"cfg_scale":float(row.get("cfg",7.5))}
            r = requests.post("http://localhost:7860/sdapi/v1/txt2img", json=payload)
            img = base64.b64decode(r.json()["images"][0])
            with open(f"{output_dir}/image_{i:04d}.png","wb") as out: out.write(img)
```

---

## Project 8 — Image-to-Video Slideshow
**Goal**: Create smooth video transitions between generated images.
**Features**: prompt list → images → interpolated frames → MP4 export
**Stack**: SDXL for frames + PIL for interpolation + imageio for video
**Key concepts**: frame interpolation, consistent seed, img2img for transitions
**Hint**:
```python
import imageio, numpy as np
from PIL import Image

def blend_frames(img1, img2, steps=10):
    """Linear interpolation between two images."""
    arr1, arr2 = np.array(img1).astype(float), np.array(img2).astype(float)
    return [Image.fromarray((arr1*(1-t) + arr2*t).astype(np.uint8))
            for t in np.linspace(0,1,steps)]
```

---

## Project 9 — LoRA Training Pipeline
**Goal**: Fine-tune SD 1.5 on custom images using LoRA (Dreambooth style).
**Steps**: collect images, caption them, train LoRA, test generation
**Requirements**: 5-20 training images, 8GB+ VRAM, ~30 minutes training
**Setup**:
```bash
pip install peft bitsandbytes
git clone https://github.com/huggingface/diffusers
cd diffusers && pip install -e .
```
**Training command**:
```bash
accelerate launch examples/dreambooth/train_dreambooth_lora.py \
  --pretrained_model_name_or_path="runwayml/stable-diffusion-v1-5" \
  --instance_data_dir="./my_images" \
  --instance_prompt="a photo of sks [subject]" \
  --output_dir="./my_lora" \
  --resolution=512 --train_batch_size=1 --max_train_steps=500 \
  --learning_rate=1e-4
```
**Test**:
```python
pipe.load_lora_weights("./my_lora")
img = pipe("a portrait of sks [subject] in a space suit, detailed").images[0]
```

---

## Project 10 — Multi-model Image Generation Comparison App
**Goal**: Run the same prompt through SD 1.5, SDXL, Flux, and DALL-E 3; display comparison.
**Features**: side-by-side grid, generation time tracking, cost estimation, export
**Stack**: Streamlit + diffusers + OpenAI
**Key concepts**: multiple pipeline management, performance benchmarking
**Hint**:
```python
import time, streamlit as st

models = {"SD 1.5": sd15_pipe, "SDXL": sdxl_pipe}
prompt = st.text_input("Prompt")
if st.button("Generate All") and prompt:
    cols = st.columns(len(models) + 1)
    for i, (name, p) in enumerate(models.items()):
        start = time.time()
        img = p(prompt=prompt, num_inference_steps=25).images[0]
        elapsed = time.time()-start
        with cols[i]:
            st.image(img, caption=f"{name} ({elapsed:.1f}s)")
    # DALL-E 3
    r = dalle_client.images.generate(model="dall-e-3",prompt=prompt,n=1,size="1024x1024")
    # display DALL-E result in last column
```
**Extension**: Add quality rating buttons and save ratings to a CSV for human eval.