# Stable Diffusion & Diffusion Models — Complete Reference

## Table of Contents
1. How Diffusion Models Work  2. Schedulers  3. Key Components
4. Text-to-Image Pipeline  5. Key Parameters  6. Prompt Engineering
7. Samplers  8. Model Variants  9. ControlNet  10. LoRA
11. img2img  12. Inpainting  13. HuggingFace Diffusers  14. Automatic1111
15. ComfyUI  16. DALL-E 3 via OpenAI  17. Midjourney Tips  18. Safety
19. Deployment  20. Best Practices

---

## 1. How Diffusion Models Work

### Forward Process (Noising)
During training, Gaussian noise is incrementally added to real images over T timesteps.
At timestep T, the image becomes pure Gaussian noise.

```
x_0 (clean image) → x_1 → x_2 → ... → x_T (pure noise)
```

Mathematically: `q(x_t | x_{t-1}) = N(x_t; sqrt(1-β_t)*x_{t-1}, β_t*I)`
where β_t is a variance schedule.

### Reverse Process (Denoising)
The model learns to denoise from x_T back to x_0.
At inference: start from random Gaussian noise, apply T denoising steps.

```
x_T (random noise) → x_{T-1} → ... → x_1 → x_0 (generated image)
```

### Key Insight: Latent Diffusion
Stable Diffusion operates in **latent space** (not pixel space) for efficiency.
- Encoder compresses 512×512 image to 64×64×4 latent
- Denoising happens in this smaller space (8× smaller)
- Decoder expands back to pixel space

Training cost: 4-8× less than pixel-space diffusion (like DALL-E 1).

---

## 2. DDPM, DDIM, DPM++ Schedulers

| Scheduler   | Steps needed | Quality    | Deterministic | Notes                     |
|-------------|-------------|------------|---------------|---------------------------|
| DDPM        | 1000        | High       | No            | Original, very slow       |
| DDIM        | 20-50       | Good       | Yes (with seed)| 20x faster than DDPM    |
| DPM++ 2M    | 20-30       | Excellent  | Yes           | Best quality/speed trade-off|
| DPM++ 2M Karras | 20-25  | Excellent  | Yes           | Karras noise schedule     |
| Euler       | 20-30       | Good       | Yes           | Simple, fast              |
| Euler A     | 20-40       | Good       | No            | Ancestral (stochastic)    |
| LCM         | 4-8         | Good       | Yes           | Latent Consistency, very fast|
| SDXL Turbo  | 1-4         | Decent     | Yes           | Single-step generation    |

### Trade-offs
- More steps → better quality, slower generation
- DDIM enables exact reproduction with same seed
- LCM/Turbo: fast generation, slightly lower quality

---

## 3. Key Components

### VAE — Variational Autoencoder
- **Encoder** (E): compresses 512×512 RGB → 64×64×4 latent
- **Decoder** (D): expands 64×64×4 latent → 512×512 RGB
- The diffusion happens entirely in latent space
- Quality impacts: VAE choice significantly affects fine detail sharpness

### U-Net — The Denoiser
- Core of the diffusion process
- Predicts the noise added at each timestep
- Architecture: ResNet blocks + attention layers
- Conditions on: timestep t, text embedding, optional control signals

### CLIP — Text Encoder
- Converts text prompts into semantic embeddings
- SD 1.5: CLIP ViT-L/14 (77 token limit)
- SDXL: dual encoders (CLIP ViT-L/14 + OpenCLIP ViT-bigG)
- The embeddings guide the U-Net via cross-attention

---

## 4. Text-to-Image Pipeline

Complete generation flow:

```
Text Prompt
    ↓
CLIP Text Encoder → Text Embeddings (77 × 768)
    ↓                         ↓
Random Latent        Cross-attention in U-Net
(64×64×4)                     ↓
    ↓              Noise Prediction at each step T
    ↓
Denoising Loop (T steps, scheduler)
    ↓
Clean Latent (64×64×4)
    ↓
VAE Decoder
    ↓
Generated Image (512×512 or 1024×1024)
```

### CFG — Classifier-Free Guidance
Runs U-Net twice: once conditioned on text, once unconditioned.
`noise_pred = uncond + guidance_scale * (cond - uncond)`

guidance_scale (CFG) effect:
- 1.0: ignores prompt, pure noise → image
- 7.5: balanced (default)
- 15+: closely follows prompt but looks unnatural

---

## 5. Key Parameters

| Parameter           | Default | Range      | Effect                                        |
|---------------------|---------|------------|-----------------------------------------------|
| prompt              | —       | —          | Text description of desired image             |
| negative_prompt     | ""      | —          | What to avoid in the image                    |
| num_inference_steps | 20-50   | 10-100     | More = better quality, slower                 |
| guidance_scale      | 7.5     | 1-20       | How closely to follow prompt                  |
| seed                | random  | any int    | Reproducibility (-1 = random)                 |
| width               | 512     | 256-2048   | Output width (must be multiple of 8)          |
| height              | 512     | 256-2048   | Output height (must be multiple of 8)         |
| strength (img2img)  | 0.8     | 0.0-1.0   | 0=keep original, 1=ignore original            |

### SDXL Recommended Settings
- Size: 1024×1024 (native resolution)
- Steps: 25-40
- CFG: 5-8
- Sampler: DPM++ 2M Karras or Euler

---

## 6. Prompt Engineering for Images

### Positive Prompt Structure
```
[subject], [style], [quality boosters], [lighting], [composition], [technical]

Example:
"portrait of a young woman, oil painting, masterpiece, highly detailed,
soft natural lighting, rule of thirds composition, 8k resolution, trending on ArtStation"
```

### Quality Boosters (Common Tags)
```
masterpiece, best quality, high resolution, highly detailed, sharp focus,
8k uhd, photorealistic, ultra-detailed, cinematic lighting, volumetric fog
```

### Negative Prompt Essentials
```
ugly, deformed, blurry, bad anatomy, bad hands, extra fingers, missing fingers,
lowres, worst quality, jpeg artifacts, watermark, signature, text, duplicate,
out of frame, cropped, extra limbs, mutation, disfigured
```

### Style Modifiers
| Style         | Prompt Keywords                                    |
|---------------|-----------------------------------------------------|
| Photorealistic| photorealistic, DSLR, natural lighting, 8k         |
| Anime         | anime style, by WLOP, vibrant colors               |
| Oil painting  | oil painting, impasto, by Rembrandt                |
| Watercolour   | watercolor, soft wash, loose brushwork             |
| Digital art   | digital painting, concept art, ArtStation          |
| Sketch        | pencil sketch, graphite, line art                  |

---

## 7. Samplers / Schedulers

### Recommendations
| Use case                  | Recommended Sampler       | Steps |
|---------------------------|---------------------------|-------|
| Default / general         | DPM++ 2M Karras           | 25-30 |
| Fast preview              | Euler A                   | 20    |
| Artistic, varied          | Euler A                   | 30-40 |
| Deterministic reproduction| DDIM                      | 50    |
| Real-time generation      | LCM                       | 4-8   |
| Video frames              | DDIM (consistency needed) | 20-30 |

---

## 8. Model Variants

| Model        | Resolution | Notes                                       |
|--------------|-----------|---------------------------------------------|
| SD 1.5       | 512×512   | Lightweight, huge ecosystem (LoRA, ControlNet)|
| SD 2.1       | 768×768   | Improved, but smaller LoRA/model ecosystem  |
| SDXL 1.0     | 1024×1024 | Two-stage (base + refiner), high quality    |
| SDXL Turbo   | 512×512   | 1-4 steps, real-time generation             |
| SD3          | 1024×1024 | Flow matching, improved text rendering      |
| Flux.1       | 1024×1024 | State-of-art (2024), FLUX.1-dev or schnell  |

### Loading Models
```python
from diffusers import StableDiffusionPipeline, StableDiffusionXLPipeline
import torch

# SD 1.5
pipe = StableDiffusionPipeline.from_pretrained("runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16).to("cuda")

# SDXL
pipe = StableDiffusionXLPipeline.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16, use_safetensors=True).to("cuda")

# Flux
from diffusers import FluxPipeline
pipe = FluxPipeline.from_pretrained("black-forest-labs/FLUX.1-schnell",
    torch_dtype=torch.bfloat16).to("cuda")
```

---

## 9. ControlNet

ControlNet adds conditioning signals to guide image generation (pose, depth, edges, etc.).

### Types
| ControlNet    | Input            | Use Case                               |
|---------------|------------------|----------------------------------------|
| OpenPose      | Skeleton         | Match human pose from reference image  |
| Canny         | Edge map         | Follow outlines / sketch               |
| Depth         | Depth map        | Match 3D spatial layout                |
| Scribble      | Rough sketch     | Transform doodle to realistic image    |
| Tile          | Low-res image    | Upscaling with detail enhancement      |
| LineArt       | Line drawing     | Anime/realistic from line art          |

```python
from diffusers import ControlNetModel, StableDiffusionControlNetPipeline
import torch, cv2
import numpy as np

controlnet = ControlNetModel.from_pretrained("lllyasviel/sd-controlnet-canny",
    torch_dtype=torch.float16)
pipe = StableDiffusionControlNetPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", controlnet=controlnet,
    torch_dtype=torch.float16).to("cuda")

# Extract edges with Canny
img = cv2.imread("reference.jpg")
edges = cv2.Canny(img, 100, 200)
edges_pil = Image.fromarray(edges)

image = pipe(
    prompt="a beautiful landscape, oil painting style",
    image=edges_pil,
    controlnet_conditioning_scale=0.8
).images[0]
```

---

## 10. LoRA — Low-Rank Adaptation

LoRA fine-tunes a model's style with just a few example images.
Weights are small (<50MB) and merge into the base model.

```python
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16).to("cuda")

# Load LoRA weights
pipe.load_lora_weights("path/to/lora", weight_name="my_style.safetensors")
# Or from HuggingFace Hub
pipe.load_lora_weights("CiroN2022/toy-face")

image = pipe(
    prompt="a portrait of sks person, photorealistic",
    cross_attention_kwargs={"scale": 0.7}  # LoRA strength 0-1
).images[0]
```

### LoRA Training (with diffusers or kohya)
```bash
# With diffusers accelerate
accelerate launch train_dreambooth_lora.py \
  --pretrained_model_name_or_path="runwayml/stable-diffusion-v1-5" \
  --instance_data_dir="./my_images" \
  --output_dir="./my_lora" \
  --instance_prompt="a photo of sks cat" \
  --resolution=512 --train_batch_size=1 --max_train_steps=500
```

---

## 11. img2img

Start from an existing image and transform it.

```python
from diffusers import StableDiffusionImg2ImgPipeline
from PIL import Image

pipe = StableDiffusionImg2ImgPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16).to("cuda")

init_image = Image.open("sketch.jpg").convert("RGB").resize((512,512))

image = pipe(
    prompt="a beautiful oil painting landscape",
    image=init_image,
    strength=0.75,       # 0=keep original, 1=ignore original
    guidance_scale=7.5,
    num_inference_steps=30
).images[0]
image.save("output.jpg")
```

---

## 12. Inpainting

Fill a masked region of an image with generated content.

```python
from diffusers import StableDiffusionInpaintPipeline
from PIL import Image
import numpy as np

pipe = StableDiffusionInpaintPipeline.from_pretrained(
    "runwayml/stable-diffusion-inpainting", torch_dtype=torch.float16).to("cuda")

image = Image.open("photo.jpg").resize((512,512))
# Create mask: white = area to inpaint, black = keep
mask_array = np.zeros((512,512), dtype=np.uint8)
mask_array[200:400, 150:350] = 255  # inpaint this region
mask = Image.fromarray(mask_array)

result = pipe(
    prompt="a beautiful sunset sky",
    image=image,
    mask_image=mask,
    num_inference_steps=50
).images[0]
result.save("inpainted.jpg")
```

---

## 13. HuggingFace Diffusers Library

```bash
pip install diffusers transformers accelerate safetensors xformers
```

### Pipeline Classes
| Class                              | Use                              |
|------------------------------------|----------------------------------|
| StableDiffusionPipeline            | SD 1.x/2.x text-to-image        |
| StableDiffusionXLPipeline          | SDXL text-to-image               |
| StableDiffusionImg2ImgPipeline     | Image-to-image                   |
| StableDiffusionInpaintPipeline     | Inpainting                       |
| StableDiffusionControlNetPipeline  | ControlNet guided generation     |
| FluxPipeline                       | Flux text-to-image               |
| AnimateDiffPipeline                | Short video generation           |

### Memory Optimisation
```python
# Enable memory-efficient attention
pipe.enable_xformers_memory_efficient_attention()

# Offload to CPU when not in use
pipe.enable_model_cpu_offload()

# Reduce memory with float16
pipe = StableDiffusionPipeline.from_pretrained(..., torch_dtype=torch.float16)
```

---

## 14. Automatic1111 WebUI

Popular local UI for Stable Diffusion.

### Installation
```bash
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui
# Place models in models/Stable-diffusion/
./webui.sh           # Linux/Mac
webui-user.bat       # Windows
```

### Key Features
- txt2img, img2img, inpainting, extras (upscaling)
- Extensions: ControlNet, ADetailer, Regional Prompter
- Styles: save/load prompt presets
- X/Y/Z Plot: systematic parameter comparison
- API: localhost:7860/docs

### API Usage
```python
import requests, base64

payload = {
    "prompt": "a beautiful landscape",
    "negative_prompt": "ugly, blurry",
    "width": 512, "height": 512,
    "steps": 25, "cfg_scale": 7.5, "sampler_name": "DPM++ 2M Karras"
}
r = requests.post("http://localhost:7860/sdapi/v1/txt2img", json=payload)
image_b64 = r.json()["images"][0]
with open("output.png","wb") as f:
    f.write(base64.b64decode(image_b64))
```

---

## 15. ComfyUI — Node-based Workflow

ComfyUI provides a visual node graph for building generation pipelines.

### Installation
```bash
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI && pip install -r requirements.txt
python main.py
```

### Key Node Types
- KSampler: main denoising node
- CLIPTextEncode: text → embeddings
- VAEDecode/VAEEncode: latent ↔ pixel
- LoadCheckpoint: load model
- ControlNetApply: add ControlNet
- LoraLoader: load LoRA weights

### API Usage (Python)
```python
import json, requests

# Load workflow JSON, modify inputs, send to /prompt endpoint
workflow = json.load(open("workflow.json"))
workflow["6"]["inputs"]["text"] = "my prompt"  # node 6 = CLIPTextEncode
r = requests.post("http://localhost:8188/prompt", json={"prompt": workflow})
```

---

## 16. DALL-E 3 via OpenAI API

```python
from openai import OpenAI
client = OpenAI()

r = client.images.generate(
    model="dall-e-3",
    prompt="A photorealistic image of a red robot playing chess against a human in a cozy library",
    n=1, size="1024x1024",
    quality="hd",         # standard or hd
    style="natural"       # natural or vivid
)
print("URL:", r.data[0].url)
print("Revised:", r.data[0].revised_prompt)

# DALL-E 3 auto-enhances your prompt
# Check revised_prompt to see what it sent to the model
```

---

## 17. Midjourney Prompt Tips

Midjourney is a commercial image generation service accessed via Discord.

### Prompt Structure
```
/imagine [subject], [style], [lighting], [camera], [quality] --ar 16:9 --v 6 --q 2
```

### Useful Parameters
| Flag      | Example         | Effect                           |
|-----------|-----------------|----------------------------------|
| --ar      | --ar 16:9       | Aspect ratio                     |
| --v       | --v 6           | Model version (6 = latest)       |
| --q       | --q 2           | Quality (0.25, 0.5, 1, 2)        |
| --style   | --style raw     | Less opinionated, more literal   |
| --no      | --no text       | Negative prompt                  |
| --seed    | --seed 1234     | Reproducibility                  |
| --chaos   | --chaos 50      | Variation amount (0-100)         |
| --tile    | --tile          | Generate seamless tile pattern   |

---

## 18. Safety Checker

Diffusers includes a built-in NSFW safety checker.

```python
# Default: safety checker enabled
pipe = StableDiffusionPipeline.from_pretrained("runwayml/stable-diffusion-v1-5")
# If flagged: returns black image + has_nsfw_concepts=True

# Disable (use responsibly, only for appropriate use cases)
pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", safety_checker=None)
```

---

## 19. Deployment Options

| Platform          | Type       | Notes                                      |
|-------------------|------------|---------------------------------------------|
| Replicate         | Cloud API  | Simple REST API, pay per second             |
| Modal             | Serverless | Auto-scales to zero, GPU inference          |
| HuggingFace Spaces| Demo       | Free CPU, paid GPU Spaces                   |
| AWS SageMaker     | Managed    | Enterprise, custom VPC                      |
| RunPod            | Cloud GPU  | Rent A100/H100, affordable                  |
| Vast.ai           | P2P GPU    | Cheap community GPUs                        |
| Local GPU         | On-prem    | RTX 3090/4090+ for SDXL, RTX 3060 for SD1.5|

### Replicate Example
```python
import replicate
output = replicate.run(
    "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
    input={"prompt": "A futuristic city, cinematic lighting", "width":1024,"height":1024}
)
print(output[0])  # URL to generated image
```

---

## 20. Best Practices

### Quality
- Use SDXL or Flux for best quality (2024+)
- Always add a negative prompt — it significantly improves output
- CFG 6-8 is optimal for most cases; very high CFG causes oversaturation
- More steps rarely helps past 30 (with DPM++ 2M Karras)

### Speed
- Enable xformers for ~2× speedup: `pipe.enable_xformers_memory_efficient_attention()`
- Use fp16: `torch_dtype=torch.float16`
- LCM for real-time: 4 steps at 512×512 takes ~0.5s on RTX 4090

### Reproducibility
- Always save the seed for images you want to reproduce
- DDIM scheduler is deterministic with fixed seed

### Prompt Tips
- Be specific, not abstract: "red rose with dew drops on petals" not "beautiful flower"
- Add artist names for style: "by Greg Rutkowski, by Alphonse Mucha"
- Use commas to separate concepts; parentheses for emphasis: (detailed eyes:1.3)
- A1111 uses weight syntax: (term:1.5) = 50% more weight