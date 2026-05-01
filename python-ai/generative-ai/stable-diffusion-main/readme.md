# 🖼️ Stable Diffusion — AI Image Generation

## What is Stable Diffusion?
Stable Diffusion is an open-source **text-to-image diffusion model**.
It can generate, edit, and transform images from text prompts.

## How Diffusion Models Work
1. **Forward process** — gradually add Gaussian noise to an image
2. **Reverse process** — neural network learns to remove noise step by step
3. Text prompt is encoded by CLIP and guides the denoising process

## Key Libraries
```python
# HuggingFace Diffusers — main library
pip install diffusers transformers accelerate

from diffusers import StableDiffusionPipeline
pipe = StableDiffusionPipeline.from_pretrained("runwayml/stable-diffusion-v1-5")
image = pipe("a photo of an astronaut on the moon").images[0]
image.save("output.png")
```

## Capabilities
| Task | Description |
|------|-------------|
| Text-to-Image | Generate image from text prompt |
| Image-to-Image | Transform existing image with prompt |
| Inpainting | Fill in masked regions of an image |
| ControlNet | Control pose/structure of generated image |
| LoRA fine-tuning | Fine-tune on custom image style |

## Models Available
- `stable-diffusion-v1-5` — classic
- `stable-diffusion-xl-base-1.0` — SDXL, higher quality
- `DALL-E 3` — via OpenAI API
- `Midjourney` — via API

## Learning Path
1. Run SD locally with diffusers
2. Prompt engineering for images (negative prompts, CFG scale)
3. Image-to-image transformation
4. ControlNet for pose-guided generation
5. Fine-tune with LoRA on custom images

## What to Build
- [ ] Text-to-image web app with Gradio/Streamlit
- [ ] Product image generator for e-commerce
- [ ] LoRA fine-tuned avatar generator
- [ ] AI art pipeline with SDXL

## Related Folders
- `deep-learning/GANs-main/` — GAN comparison
- `deep-learning/Finetuning-LLM-main/` — LoRA technique
- `generative-ai/OPENAI-API-Tutorials-main/` — DALL-E via OpenAI API