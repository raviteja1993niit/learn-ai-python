# 🧠 Attention Mechanisms — Theory & Code (Q, K, V to Flash Attention)

## What is Attention?
Attention is a learned mechanism that lets a model focus on the most relevant parts of its input when producing each output token or representation. Scaled dot-product attention computes compatibility scores between queries and keys, then uses those scores to create a weighted sum of values. It replaced RNNs as the backbone of modern NLP and vision models because it parallelises perfectly and captures long-range dependencies in one shot.

## Why Learn It?
- Attention is the core building block of every Transformer (GPT, BERT, ViT, Whisper)
- Understanding Q/K/V lets you interpret and debug model behaviour via attention maps
- Self-attention vs cross-attention distinction is critical for encoder-decoder models
- Flash Attention and RoPE appear in every modern LLM—know why they exist

## Key Concepts
```python
import torch
import torch.nn as nn
import torch.nn.functional as F
import math

# ── Scaled Dot-Product Attention ─────────────────────────────────────────
def scaled_dot_product_attention(Q, K, V, mask=None):
    """
    Q: (B, heads, seq, d_k)
    K: (B, heads, seq, d_k)
    V: (B, heads, seq, d_v)
    """
    d_k    = Q.size(-1)
    scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(d_k)  # (B, h, s, s)
    if mask is not None:
        scores = scores.masked_fill(mask == 0, float('-inf'))
    weights = F.softmax(scores, dim=-1)          # attention distribution
    return torch.matmul(weights, V), weights     # context, attn_weights

# ── Multi-Head Attention from Scratch ───────────────────────────────────
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model=512, n_heads=8):
        super().__init__()
        assert d_model % n_heads == 0
        self.d_k    = d_model // n_heads
        self.h      = n_heads
        self.Wq     = nn.Linear(d_model, d_model)
        self.Wk     = nn.Linear(d_model, d_model)
        self.Wv     = nn.Linear(d_model, d_model)
        self.Wo     = nn.Linear(d_model, d_model)

    def split_heads(self, x, B, S):
        return x.view(B, S, self.h, self.d_k).transpose(1, 2)  # (B, h, S, d_k)

    def forward(self, Q, K, V, mask=None):
        B, S = Q.size(0), Q.size(1)
        Q = self.split_heads(self.Wq(Q), B, S)
        K = self.split_heads(self.Wk(K), B, K.size(1))
        V = self.split_heads(self.Wv(V), B, V.size(1))
        ctx, weights = scaled_dot_product_attention(Q, K, V, mask)
        ctx = ctx.transpose(1, 2).contiguous().view(B, S, -1)  # concat heads
        return self.Wo(ctx), weights

# ── Sinusoidal Positional Encoding ───────────────────────────────────────
class SinusoidalPE(nn.Module):
    def __init__(self, d_model, max_len=512):
        super().__init__()
        pe  = torch.zeros(max_len, d_model)
        pos = torch.arange(max_len).unsqueeze(1).float()
        div = torch.exp(torch.arange(0, d_model, 2).float() * -(math.log(10000) / d_model))
        pe[:, 0::2] = torch.sin(pos * div)
        pe[:, 1::2] = torch.cos(pos * div)
        self.register_buffer('pe', pe.unsqueeze(0))  # (1, max_len, d_model)

    def forward(self, x):
        return x + self.pe[:, :x.size(1)]

# ── Causal (Decoder) Mask ────────────────────────────────────────────────
def causal_mask(seq_len):
    return torch.tril(torch.ones(seq_len, seq_len)).unsqueeze(0).unsqueeze(0)

# ── Quick sanity check ───────────────────────────────────────────────────
mha   = MultiHeadAttention(d_model=512, n_heads=8)
x     = torch.randn(2, 10, 512)    # (batch=2, seq=10, d_model=512)
out, w = mha(x, x, x)             # self-attention (Q=K=V=x)
print(out.shape, w.shape)         # (2,10,512)  (2,8,10,10)
```

## Learning Path
1. `pip install torch matplotlib seaborn`
2. Derive scaled dot-product attention on paper; verify softmax normalisation
3. Implement `MultiHeadAttention` from scratch (code above)
4. Add a causal mask and test on a toy language model
5. Implement sinusoidal PE; plot the encoding vectors as a heatmap
6. Read Flash Attention paper (Dao 2022): understand IO-awareness
7. Explore RoPE in LLaMA source code (`transformers` library)

## What to Build
- [ ] Attention weight visualizer: heatmap of (seq × seq) weights
- [ ] Self-attention vs cross-attention demo (encoder-decoder translation)
- [ ] Toy GPT: stack 2 decoder blocks with masked MHA + FF
- [ ] Compare sinusoidal PE vs learned PE on a small dataset
- [ ] Benchmark vanilla attention vs `torch.nn.functional.scaled_dot_product_attention` (Flash Attention path)

## Related Folders
- `deep-learning\vision-transformers-vit-main\` — attention applied to image patches
- `nlp\transformers-from-scratch-main\` — full Transformer encoder/decoder
- `python-basics\calculus-for-deep-learning-main\` — softmax gradient derivation
