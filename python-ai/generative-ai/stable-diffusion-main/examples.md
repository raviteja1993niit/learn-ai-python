# Stable Diffusion & Diffusion Models — Code Examples (20 Examples)

```bash
pip install diffusers transformers accelerate safetensors xformers torch torchvision pillow
```
Requires CUDA GPU (4GB+ VRAM for SD 1.5, 8GB+ for SDXL).

---

## Example 1 — Basic Text-to-Image (SD 1.5)
```python
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

image = pipe(
    prompt="a serene lake at sunset, oil painting style, highly detailed",
    negative_prompt="ugly, blurry, deformed, low quality",
    num_inference_steps=25,
    guidance_scale=7.5,
    generator=torch.Generator("cuda").manual_seed(42)
).images[0]

image.save("output.png")
print("Saved output.png")
```

---

## Example 2 — SDXL Text-to-Image
```python
from diffusers import StableDiffusionXLPipeline
import torch

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    use_safetensors=True
).to("cuda")
pipe.enable_xformers_memory_efficient_attention()

image = pipe(
    prompt="a photorealistic portrait of a cyberpunk scientist, neon lighting, 8k",
    negative_prompt="cartoon, painting, blurry, deformed",
    num_inference_steps=30,
    guidance_scale=7.0,
    width=1024, height=1024
).images[0]
image.save("sdxl_output.png")
```

---

## Example 3 — SDXL with Refiner (Two-stage)
```python
from diffusers import StableDiffusionXLPipeline, StableDiffusionXLImg2ImgPipeline
import torch

base = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16, use_safetensors=True
).to("cuda")
refiner = StableDiffusionXLImg2ImgPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-refiner-1.0",
    torch_dtype=torch.float16, use_safetensors=True
).to("cuda")

prompt = "an astronaut on Mars, photorealistic, dramatic lighting"
# Stage 1: base (80% steps)
image = base(prompt=prompt, num_inference_steps=40, denoising_end=0.8,
             output_type="latent").images
# Stage 2: refiner (20% steps)
image = refiner(prompt=prompt, num_inference_steps=40, denoising_start=0.8,
                image=image).images[0]
image.save("sdxl_refined.png")
```

---

## Example 4 — Batch Generation
```python
prompts = [
    "a red sports car on a mountain road, cinematic",
    "a cozy cottage in a snowy forest, warm lighting",
    "a futuristic spaceship interior, blue neon"
]

images = pipe(
    prompt=prompts,
    num_inference_steps=25,
    guidance_scale=7.5,
    generator=torch.Generator("cuda").manual_seed(42)
).images

for i, img in enumerate(images):
    img.save(f"batch_{i}.png")
    print(f"Saved batch_{i}.png")
```

---

## Example 5 — Different Schedulers Comparison
```python
from diffusers import DDIMScheduler, DPMSolverMultistepScheduler, EulerAncestralDiscreteScheduler

schedulers = {
    "ddim": DDIMScheduler.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="scheduler"),
    "dpm++": DPMSolverMultistepScheduler.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="scheduler"),
    "euler_a": EulerAncestralDiscreteScheduler.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="scheduler")
}

prompt = "a beautiful mountain landscape, digital art"
seed = 42
for name, scheduler in schedulers.items():
    pipe.scheduler = scheduler
    gen = torch.Generator("cuda").manual_seed(seed)
    img = pipe(prompt=prompt, num_inference_steps=25, generator=gen).images[0]
    img.save(f"scheduler_{name}.png")
    print(f"Saved {name}")
```

---

## Example 6 — CFG Scale Sweep
```python
prompt = "a dragon flying over a medieval castle, fantasy art"
negative = "ugly, deformed, blurry"

for cfg in [1.0, 4.0, 7.5, 12.0, 20.0]:
    gen = torch.Generator("cuda").manual_seed(42)
    img = pipe(prompt=prompt, negative_prompt=negative,
               guidance_scale=cfg, num_inference_steps=25,
               generator=gen).images[0]
    img.save(f"cfg_{cfg}.png")
    print(f"CFG={cfg} saved")
```

---

## Example 7 — img2img
```python
from diffusers import StableDiffusionImg2ImgPipeline
from PIL import Image

img2img_pipe = StableDiffusionImg2ImgPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16).to("cuda")

init_image = Image.open("sketch.jpg").convert("RGB").resize((512,512))

result = img2img_pipe(
    prompt="a photorealistic photo of a city, detailed architecture",
    image=init_image,
    strength=0.75,       # 0=keep, 1=ignore original
    guidance_scale=7.5,
    num_inference_steps=30,
    generator=torch.Generator("cuda").manual_seed(42)
).images[0]
result.save("img2img_result.png")
```

---

## Example 8 — Inpainting
```python
from diffusers import StableDiffusionInpaintPipeline
from PIL import Image
import numpy as np

inpaint = StableDiffusionInpaintPipeline.from_pretrained(
    "runwayml/stable-diffusion-inpainting", torch_dtype=torch.float16).to("cuda")

image = Image.open("photo.jpg").resize((512,512))
mask = np.zeros((512,512), dtype=np.uint8)
mask[150:350, 100:400] = 255   # white = area to fill
mask_image = Image.fromarray(mask)

result = inpaint(
    prompt="a beautiful garden with flowers",
    image=image,
    mask_image=mask_image,
    num_inference_steps=50,
    guidance_scale=7.5
).images[0]
result.save("inpainted.png")
```

---

## Example 9 — ControlNet (Canny Edges)
```python
from diffusers import ControlNetModel, StableDiffusionControlNetPipeline
from diffusers.utils import load_image
import cv2, numpy as np
from PIL import Image
import torch

controlnet = ControlNetModel.from_pretrained(
    "lllyasviel/sd-controlnet-canny", torch_dtype=torch.float16)
ctrl_pipe = StableDiffusionControlNetPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", controlnet=controlnet,
    torch_dtype=torch.float16).to("cuda")

# Extract Canny edges
img_bgr = cv2.imread("input.jpg")
img_bgr = cv2.resize(img_bgr, (512,512))
edges = cv2.Canny(img_bgr, 100, 200)
control_image = Image.fromarray(edges)

result = ctrl_pipe(
    prompt="a beautiful watercolor painting of a city",
    image=control_image,
    num_inference_steps=30,
    guidance_scale=7.5,
    controlnet_conditioning_scale=0.8
).images[0]
result.save("controlnet_result.png")
```

---

## Example 10 — LoRA Loading
```python
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16).to("cuda")

# Load LoRA from HuggingFace Hub
pipe.load_lora_weights("CiroN2022/toy-face")

image = pipe(
    prompt="a toy face portrait of a smiling cat, high quality",
    cross_attention_kwargs={"scale": 0.8},   # LoRA strength
    num_inference_steps=25, guidance_scale=7.5
).images[0]
image.save("lora_result.png")

# Unload when done
pipe.unload_lora_weights()
```

---

## Example 11 — DALL-E 3 Generation
```python
from openai import OpenAI
import urllib.request

client = OpenAI()

r = client.images.generate(
    model="dall-e-3",
    prompt="A photorealistic image of a friendly robot reading books in a library, warm lighting",
    n=1, size="1024x1024", quality="hd", style="natural"
)
url = r.data[0].url
print("URL:", url)
print("Revised prompt:", r.data[0].revised_prompt)
urllib.request.urlretrieve(url, "dalle3_output.png")
```

---

## Example 12 — DALL-E 2 Variations
```python
r = client.images.create_variation(
    image=open("original.png","rb"),
    n=4,
    size="512x512",
    response_format="b64_json"
)
import base64
for i, img in enumerate(r.data):
    with open(f"variation_{i}.png","wb") as f:
        f.write(base64.b64decode(img.b64_json))
    print(f"Saved variation_{i}.png")
```

---

## Example 13 — Automatic1111 API Call
```python
import requests, base64

def a1111_txt2img(prompt, neg_prompt="", steps=25, cfg=7.5, seed=-1, w=512, h=512):
    payload = {
        "prompt": prompt, "negative_prompt": neg_prompt,
        "steps": steps, "cfg_scale": cfg, "seed": seed,
        "width": w, "height": h,
        "sampler_name": "DPM++ 2M Karras"
    }
    r = requests.post("http://localhost:7860/sdapi/v1/txt2img", json=payload)
    result = r.json()
    img_bytes = base64.b64decode(result["images"][0])
    with open("a1111_output.png","wb") as f: f.write(img_bytes)
    return result.get("info","")

info = a1111_txt2img("a cyberpunk street at night, neon lights, rain reflections")
```

---

## Example 14 — Flux.1 Schnell (Fast)
```python
from diffusers import FluxPipeline
import torch

pipe = FluxPipeline.from_pretrained(
    "black-forest-labs/FLUX.1-schnell",
    torch_dtype=torch.bfloat16
).to("cuda")
pipe.enable_model_cpu_offload()

image = pipe(
    prompt="a futuristic cityscape at dawn, photorealistic",
    num_inference_steps=4,     # Schnell: 4 steps is enough!
    guidance_scale=0.0,        # Schnell doesn't use CFG
    max_sequence_length=256,
    generator=torch.Generator("cpu").manual_seed(42)
).images[0]
image.save("flux_output.png")
```

---

## Example 15 — Upscaling with RealESRGAN
```python
from diffusers import StableDiffusionUpscalePipeline
import torch
from PIL import Image

upscaler = StableDiffusionUpscalePipeline.from_pretrained(
    "stabilityai/stable-diffusion-x4-upscaler",
    torch_dtype=torch.float16).to("cuda")

low_res = Image.open("low_res.png").convert("RGB")
low_res = low_res.resize((128,128))   # simulate low-res input

result = upscaler(
    prompt="a high quality detailed photo",
    image=low_res,
    num_inference_steps=20
).images[0]
result.save("upscaled.png")
print(f"Upscaled to {result.size}")
```

---

## Example 16 — Stable Video Diffusion (Image-to-Video)
```python
from diffusers import StableVideoDiffusionPipeline
from diffusers.utils import load_image, export_to_video
import torch

pipe = StableVideoDiffusionPipeline.from_pretrained(
    "stabilityai/stable-video-diffusion-img2vid-xt",
    torch_dtype=torch.float16, variant="fp16"
).to("cuda")
pipe.enable_model_cpu_offload()

image = load_image("starting_frame.jpg").resize((1024,576))
frames = pipe(image, num_inference_steps=25, decode_chunk_size=8).frames[0]
export_to_video(frames, "output_video.mp4", fps=7)
```

---

## Example 17 — Replicate API (Cloud)
```python
import replicate, urllib.request

output = replicate.run(
    "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
    input={
        "prompt": "a stunning sunset over the ocean, photorealistic",
        "negative_prompt": "ugly, deformed, blurry",
        "width": 1024, "height": 1024,
        "num_inference_steps": 30, "guidance_scale": 7.5
    }
)
urllib.request.urlretrieve(output[0], "replicate_output.png")
print("Downloaded:", output[0])
```

---

## Example 18 — Prompt Comparison Grid
```python
from PIL import Image
import math

def generate_grid(prompts, pipe, cols=3, steps=20):
    images = []
    for p in prompts:
        img = pipe(prompt=p, num_inference_steps=steps,
                   guidance_scale=7.5).images[0]
        img = img.resize((256,256))
        images.append(img)
    rows = math.ceil(len(images)/cols)
    grid = Image.new("RGB", (cols*256, rows*256))
    for i, img in enumerate(images):
        grid.paste(img, ((i%cols)*256, (i//cols)*256))
    grid.save("comparison_grid.png")
    return grid

prompts = ["sunset oil painting","sunset watercolor","sunset digital art"]
# grid = generate_grid(prompts, pipe)
```

---

## Example 19 — Seed Exploration
```python
prompt = "a majestic dragon in a fantasy landscape"
negative = "ugly, blurry, deformed"

for seed in [42, 100, 200, 500, 1337]:
    gen = torch.Generator("cuda").manual_seed(seed)
    img = pipe(prompt=prompt, negative_prompt=negative,
               generator=gen, num_inference_steps=25,
               guidance_scale=7.5).images[0]
    img.save(f"seed_{seed}.png")
    print(f"Seed {seed} saved")
```

---

## Example 20 — Image Metadata Embedding
```python
from PIL import Image, PngImagePlugin
import json

def save_with_metadata(image, output_path, params):
    """Save PNG with generation parameters embedded."""
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("parameters", json.dumps(params, indent=2))
    image.save(output_path, "PNG", pnginfo=metadata)
    print(f"Saved with metadata: {output_path}")

def read_metadata(image_path):
    """Read generation parameters from PNG."""
    img = Image.open(image_path)
    params_str = img.info.get("parameters","")
    return json.loads(params_str) if params_str else {}

params = {
    "prompt": "a beautiful forest path in autumn",
    "negative_prompt": "ugly, blurry",
    "steps": 25, "cfg": 7.5, "seed": 42, "model": "sd-v1-5"
}
# save_with_metadata(generated_image, "output.png", params)
# loaded = read_metadata("output.png")
```