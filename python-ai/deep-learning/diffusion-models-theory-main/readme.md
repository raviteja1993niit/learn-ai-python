# 🌫️ Diffusion Models — Theory & DDPM from Scratch

## What is a Diffusion Model?
A diffusion model learns to generate data by reversing a gradual noising process. During training, Gaussian noise is progressively added to real images (the forward process) over T timesteps until the image is pure noise. A neural network (usually a U-Net) then learns to predict and remove that noise step by step (the reverse process), enabling generation of new images from random noise.

## Why Learn It?
- Diffusion models power Stable Diffusion, DALL·E 3, Imagen, and Sora
- Understanding DDPM gives you the theoretical foundation for all latent diffusion variants
- Classifier-free guidance is the key trick behind high-quality controllable generation
- The HuggingFace `diffusers` library exposes every component—great for fine-tuning

## Key Concepts
```python
import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np

# ── Variance Schedule (linear) ────────────────────────────────────────────
T = 1000
beta  = torch.linspace(1e-4, 0.02, T)         # β_1 … β_T
alpha = 1.0 - beta                             # α_t
alpha_bar = torch.cumprod(alpha, dim=0)        # ᾱ_t = ∏ α_i

# ── Forward Process: q(x_t | x_0) — add noise analytically ──────────────
def q_sample(x0, t, noise=None):
    """
    Closed form: x_t = √ᾱ_t * x_0 + √(1-ᾱ_t) * ε   where ε ~ N(0,I)
    """
    if noise is None:
        noise = torch.randn_like(x0)
    ab_t = alpha_bar[t].view(-1, 1, 1, 1)     # broadcast to image dims
    return ab_t.sqrt() * x0 + (1 - ab_t).sqrt() * noise, noise

# ── DDPM Training Loss ────────────────────────────────────────────────────
def ddpm_loss(model, x0):
    B = x0.size(0)
    t = torch.randint(0, T, (B,))             # random timestep per sample
    x_t, noise = q_sample(x0, t)
    noise_pred = model(x_t, t)                # U-Net predicts ε
    return F.mse_loss(noise_pred, noise)       # L_simple from DDPM paper

# ── Reverse Process: sample x_{t-1} from x_t ────────────────────────────
@torch.no_grad()
def p_sample(model, x_t, t_idx):
    t_tensor = torch.full((x_t.size(0),), t_idx, dtype=torch.long)
    beta_t   = beta[t_idx]
    a_t      = alpha[t_idx]
    ab_t     = alpha_bar[t_idx]
    eps_pred = model(x_t, t_tensor)

    # Posterior mean (equation 11, Ho et al. 2020)
    coef1  = 1.0 / a_t.sqrt()
    coef2  = beta_t / (1 - ab_t).sqrt()
    mean   = coef1 * (x_t - coef2 * eps_pred)

    if t_idx == 0:
        return mean
    noise  = torch.randn_like(x_t)
    return mean + beta_t.sqrt() * noise        # reparameterisation

@torch.no_grad()
def p_sample_loop(model, shape):
    x = torch.randn(shape)
    for t in reversed(range(T)):
        x = p_sample(model, x, t)
    return x

# ── Minimal U-Net block (used as noise predictor) ────────────────────────
class ResBlock(nn.Module):
    def __init__(self, ch):
        super().__init__()
        self.net = nn.Sequential(
            nn.GroupNorm(8, ch), nn.SiLU(),
            nn.Conv2d(ch, ch, 3, padding=1),
            nn.GroupNorm(8, ch), nn.SiLU(),
            nn.Conv2d(ch, ch, 3, padding=1),
        )
    def forward(self, x): return x + self.net(x)

# ── HuggingFace diffusers: Stable Diffusion in 5 lines ───────────────────
# from diffusers import StableDiffusionPipeline
# pipe = StableDiffusionPipeline.from_pretrained(
#     "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16
# ).to("cuda")
# image = pipe("a photograph of an astronaut riding a horse").images[0]
# image.save("output.png")

# ── DDIM (faster sampling, 50 steps instead of 1000) ─────────────────────
# from diffusers import DDIMScheduler
# scheduler = DDIMScheduler.from_pretrained("runwayml/stable-diffusion-v1-5",
#                                           subfolder="scheduler")
# scheduler.set_timesteps(50)
```

## Learning Path
1. `pip install torch diffusers transformers accelerate Pillow matplotlib`
2. Read DDPM paper (Ho et al., 2020) — focus on equations 1–14
3. Implement forward process: visualise a CIFAR image at t=0,100,500,999
4. Train a tiny DDPM U-Net on MNIST (28×28 grayscale, T=200)
5. Implement DDIM sampling; compare 50-step vs 1000-step sample quality
6. Run Stable Diffusion with `diffusers` and experiment with CFG scale
7. Fine-tune with DreamBooth or LoRA on a custom concept

## What to Build
- [ ] MNIST DDPM trainer: ~10 epochs, sample a 8×8 grid of generated digits
- [ ] Noising visualiser: plot x_0 → x_T at 10 evenly spaced timesteps
- [ ] CFG explorer: generate same prompt at guidance_scale 1, 5, 10, 15 and compare
- [ ] DDPM vs DDIM sampling speed benchmark (wall-clock time for 64 images)
- [ ] Fine-tune Stable Diffusion 1.5 on a custom style with LoRA (diffusers)

## Related Folders
- `deep-learning\attention-mechanisms-main\` — U-Net uses cross-attention for conditioning
- `deep-learning\vision-transformers-vit-main\` — DiT replaces U-Net with Transformers
- `deep-learning\model-quantization-pruning-main\` — quantize SD for faster inference
