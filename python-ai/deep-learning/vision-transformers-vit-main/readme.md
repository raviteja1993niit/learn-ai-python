# 🔭 Vision Transformers (ViT) — Attention Over Image Patches

## What is a Vision Transformer?
A Vision Transformer (ViT) applies the Transformer architecture—originally designed for text—directly to images by splitting them into fixed-size patches and treating each patch as a "token". With enough training data, ViT matches or exceeds CNNs on image classification while offering a cleaner, unified architecture. It demonstrated that attention-based models are not limited to sequential data.

## Why Learn It?
- Understand how self-attention scales to vision tasks beyond NLP
- Fine-tune state-of-the-art image classifiers with HuggingFace in minutes
- Grasp the foundation behind Stable Diffusion's image encoder
- Prepare for multimodal models (CLIP, Flamingo) that mix vision + language

## Key Concepts
```python
import torch
import torch.nn as nn
from transformers import ViTForImageClassification, ViTImageProcessor
from PIL import Image
import timm

# ── Patch Embedding (the heart of ViT) ──────────────────────────────────
class PatchEmbedding(nn.Module):
    def __init__(self, img_size=224, patch_size=16, in_channels=3, embed_dim=768):
        super().__init__()
        self.n_patches = (img_size // patch_size) ** 2   # 196 for 224x224/16
        # Conv2d with stride=patch_size slices image into patches in one op
        self.proj = nn.Conv2d(in_channels, embed_dim, patch_size, patch_size)

    def forward(self, x):                     # x: (B, C, H, W)
        x = self.proj(x)                      # (B, embed_dim, H/P, W/P)
        x = x.flatten(2).transpose(1, 2)      # (B, n_patches, embed_dim)
        return x

# ── CLS token + positional encoding ─────────────────────────────────────
B, embed_dim, n_patches = 4, 768, 196
patch_tokens = torch.randn(B, n_patches, embed_dim)
cls_token    = nn.Parameter(torch.zeros(1, 1, embed_dim))
cls_tokens   = cls_token.expand(B, -1, -1)                # (B, 1, 768)
tokens       = torch.cat([cls_tokens, patch_tokens], dim=1)  # (B, 197, 768)
pos_embed    = nn.Parameter(torch.randn(1, 197, embed_dim))
tokens       = tokens + pos_embed                          # add position info

# ── Fine-tune ViT with HuggingFace ──────────────────────────────────────
processor = ViTImageProcessor.from_pretrained("google/vit-base-patch16-224")
model     = ViTForImageClassification.from_pretrained(
    "google/vit-base-patch16-224",
    num_labels=10,
    ignore_mismatched_sizes=True
)
# Freeze all layers except the classifier head
for name, param in model.named_parameters():
    if "classifier" not in name:
        param.requires_grad = False

# ── timm: fastest way to load any ViT variant ───────────────────────────
vit   = timm.create_model("vit_base_patch16_224", pretrained=True, num_classes=10)
swin  = timm.create_model("swin_base_patch4_window7_224", pretrained=True)
deit  = timm.create_model("deit_base_patch16_224", pretrained=True)
dummy = torch.randn(1, 3, 224, 224)
print(vit(dummy).shape)   # (1, 10)
```

## ViT vs CNN Comparison

| Feature              | ViT                          | CNN                        |
|----------------------|------------------------------|----------------------------|
| Inductive bias       | None (learns from data)      | Translation equivariance   |
| Small data (<10k)    | ❌ Underperforms              | ✅ Generalises well         |
| Large data (>1M)     | ✅ Outperforms                | ✅ Competitive              |
| Long-range deps      | ✅ Global attention           | ❌ Needs deep stacking      |
| Compute (inference)  | Higher (quadratic attention) | Lower                      |

## Learning Path
1. `pip install torch transformers timm Pillow`
2. Read the original ViT paper: *"An Image is Worth 16×16 Words"* (Dosovitskiy 2020)
3. Implement `PatchEmbedding` + `CLS token` + `positional encoding` from scratch
4. Fine-tune `google/vit-base-patch16-224` on CIFAR-10 with HuggingFace Trainer
5. Compare accuracy vs `ResNet-50` on the same dataset
6. Explore Swin Transformer (hierarchical shifted-window attention)

## What to Build
- [ ] Patch embedding visualizer: show the 196 patches extracted from an image
- [ ] Fine-tune ViT on a custom 10-class image dataset
- [ ] Attention rollout: visualize which patches the CLS token attends to
- [ ] Benchmark ViT-Base vs ResNet-50 on CIFAR-10 (accuracy + training time)
- [ ] Build a Gradio demo: upload image → top-5 predictions with attention map

## Related Folders
- `deep-learning\attention-mechanisms-main\` — self-attention that ViT uses
- `deep-learning\cnn-architectures-main\` — CNNs that ViT competes with
- `nlp\transformers-from-scratch-main\` — Transformer architecture foundations
