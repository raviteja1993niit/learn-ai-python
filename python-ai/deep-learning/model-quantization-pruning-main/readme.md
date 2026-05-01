# ⚡ Model Quantization & Pruning — Compress Without Losing Accuracy

## What is Quantization & Pruning?
Quantization reduces a model's weight precision (e.g., FP32 → INT8) so it runs faster and consumes less memory, often with negligible accuracy loss. Pruning removes weights or entire neurons that contribute little to the output, creating sparse or structurally smaller networks. Together, these techniques are essential for deploying large models on edge devices or serving them cost-effectively at scale.

## Why Learn It?
- Run 7B-parameter LLMs on a single consumer GPU with 4-bit quantization
- Reduce inference latency 2–4× by switching FP32 → FP16/INT8
- Shrink model file size for mobile/embedded deployment
- Understand GPTQ, AWQ, and bitsandbytes—the tools behind every LLM serving stack

## Key Concepts
```python
import torch
import torch.nn as nn
import torch.nn.utils.prune as prune
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

# ── FP16 inference (simple, ~2× memory reduction) ────────────────────────
model = nn.Linear(1024, 1024)
model = model.half()                          # FP32 → FP16
x = torch.randn(32, 1024).half()
print(model(x).dtype)                         # torch.float16

# ── Post-Training Quantization with torch.quantization (PTQ) ─────────────
class TinyMLP(nn.Module):
    def __init__(self):
        super().__init__()
        self.quant   = torch.quantization.QuantStub()
        self.fc1     = nn.Linear(128, 64)
        self.relu    = nn.ReLU()
        self.fc2     = nn.Linear(64, 10)
        self.dequant = torch.quantization.DeQuantStub()
    def forward(self, x):
        return self.dequant(self.fc2(self.relu(self.fc1(self.quant(x)))))

m = TinyMLP().eval()
m.qconfig = torch.quantization.get_default_qconfig('fbgemm')
torch.quantization.prepare(m, inplace=True)
# calibrate: run representative data through m(...)
torch.quantization.convert(m, inplace=True)   # INT8 weights
print(m.fc1.weight().dtype)                   # torch.qint8

# ── 4-bit LLM loading with bitsandbytes ─────────────────────────────────
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",           # NormalFloat4 — best for LLMs
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True       # nested quantization
)
model_id = "mistralai/Mistral-7B-v0.1"
# model = AutoModelForCausalLM.from_pretrained(model_id, quantization_config=bnb_config)
# → ~4 GB VRAM instead of ~14 GB

# ── Magnitude Pruning with torch.nn.utils.prune ─────────────────────────
layer = nn.Linear(128, 64)
# Unstructured: remove 30% of smallest-magnitude weights globally
prune.l1_unstructured(layer, name='weight', amount=0.30)
print("Sparsity:", (layer.weight == 0).float().mean().item())  # ~0.30

# Structured: remove entire output neurons (rows)
prune.ln_structured(layer, name='weight', amount=0.2, n=2, dim=0)

# Make pruning permanent (remove mask buffers)
prune.remove(layer, 'weight')

# ── Benchmarking size & speed ─────────────────────────────────────────────
import os, time

def model_size_mb(m):
    torch.save(m.state_dict(), "tmp_weights.pt")
    size = os.path.getsize("tmp_weights.pt") / 1e6
    os.remove("tmp_weights.pt")
    return size

def latency_ms(m, x, runs=100):
    m.eval()
    with torch.no_grad():
        start = time.perf_counter()
        for _ in range(runs): m(x)
        return (time.perf_counter() - start) / runs * 1000
```

## Learning Path
1. `pip install torch bitsandbytes transformers optimum`
2. Quantize a small FP32 MLP to INT8 with `torch.quantization` (PTQ)
3. Load a 7B LLM in 4-bit with `BitsAndBytesConfig`; compare VRAM usage
4. Apply magnitude pruning at 50% sparsity; measure accuracy drop
5. Read GPTQ paper; try `AutoGPTQ` library on a small model
6. Export a quantized model to ONNX and benchmark with ONNX Runtime
7. Explore AWQ (`autoawq`) for activation-aware weight quantization

## What to Build
- [ ] PTQ pipeline: FP32 → INT8 ResNet on ImageNet subset, plot accuracy vs size
- [ ] Load Mistral-7B in 4-bit and benchmark tokens/sec vs FP16
- [ ] Iterative pruning script: prune 10% every epoch, plot accuracy degradation curve
- [ ] ONNX export + ONNX Runtime inference benchmark (latency comparison table)
- [ ] Quantization-aware training (QAT) demo on MNIST

## Related Folders
- `deep-learning\vision-transformers-vit-main\` — ViT models to quantize
- `mlops\model-serving-main\` — serve quantized models via FastAPI
- `deep-learning\diffusion-models-theory-main\` — large models that benefit most from quantization
