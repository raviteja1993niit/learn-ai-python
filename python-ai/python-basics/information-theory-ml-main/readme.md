# 📐 Information Theory for ML — Entropy, Divergence & Cross-Entropy

## What is this?
Information theory, founded by Claude Shannon, quantifies uncertainty and information content in probability distributions. It underpins core ML concepts: cross-entropy loss, KL divergence in VAEs, information gain in decision trees, and the ELBO in variational inference — all are direct applications of a small set of foundational ideas.

## Why Learn It?
- Cross-entropy loss is not arbitrary — it equals negative log-likelihood under a categorical model, derived from KL divergence
- KL divergence is the regularization term in VAEs, beta-VAEs, and variational inference
- Mutual information drives feature selection, ICA, InfoNCE (contrastive learning), and MINE
- Understanding entropy gives intuition for why softmax + cross-entropy works better than MSE for classification

## Key Concepts
```python
import numpy as np
from scipy.stats import entropy as scipy_entropy

# ── 1. Shannon Entropy H(X) = -Σ p(x) · log p(x) ────────────────────────────
def entropy(p: np.ndarray, base: float = 2.0) -> float:
    """Entropy in bits (base=2) or nats (base=e)."""
    p = p[p > 0]   # 0·log(0) = 0 by convention
    return -np.sum(p * np.log(p) / np.log(base))

uniform = np.array([0.25, 0.25, 0.25, 0.25])
peaked  = np.array([0.97, 0.01, 0.01, 0.01])
print(entropy(uniform))  # 2.0 bits — maximum uncertainty
print(entropy(peaked))   # ~0.22 bits — almost certain

# scipy shortcut (nats by default, bits with base=2):
print(scipy_entropy(uniform, base=2))   # 2.0

# ── 2. Joint & Conditional Entropy ───────────────────────────────────────────
# H(X,Y) = -Σ p(x,y) · log p(x,y)
# H(Y|X) = H(X,Y) - H(X)    ← chain rule
joint = np.array([[0.3, 0.1], [0.2, 0.4]])   # 2×2 joint distribution
Hxy = entropy(joint.ravel())
Hx  = entropy(joint.sum(axis=1))
Hy_given_x = Hxy - Hx
print(f"H(Y|X) = {Hy_given_x:.4f} bits")

# ── 3. Mutual Information I(X;Y) = H(X) - H(X|Y) ────────────────────────────
def mutual_information(joint: np.ndarray) -> float:
    px = joint.sum(axis=1, keepdims=True)
    py = joint.sum(axis=0, keepdims=True)
    independent = px * py
    mask = joint > 0
    return np.sum(joint[mask] * np.log2(joint[mask] / independent[mask]))

print(f"I(X;Y) = {mutual_information(joint):.4f} bits")

# ── 4. KL Divergence DKL(P || Q) = Σ p · log(p/q) ───────────────────────────
def kl_divergence(p: np.ndarray, q: np.ndarray) -> float:
    """Forward KL: 'mean-seeking', used in MLE/cross-entropy."""
    mask = p > 0
    return np.sum(p[mask] * np.log(p[mask] / q[mask]))

p = np.array([0.4, 0.3, 0.2, 0.1])
q = np.array([0.25, 0.25, 0.25, 0.25])   # uniform baseline
print(f"KL(P||Q) = {kl_divergence(p, q):.4f} nats")
print(f"KL(Q||P) = {kl_divergence(q, p):.4f} nats")   # asymmetric!

# scipy convenience:
from scipy.special import kl_div
print(scipy_entropy(p, q))   # scipy_entropy(p, q) = KL(p||q)

# ── 5. Cross-Entropy H(P, Q) = H(P) + KL(P||Q) ──────────────────────────────
def cross_entropy(p: np.ndarray, q: np.ndarray) -> float:
    """= -Σ p · log(q)  =  negative log-likelihood of q under true dist p."""
    mask = p > 0
    return -np.sum(p[mask] * np.log(q[mask]))

# Minimizing CE ≡ minimizing KL(p||q) ≡ maximizing log-likelihood
# That's why cross-entropy IS the standard classification loss.
y_true = np.array([0.0, 1.0, 0.0])         # one-hot
y_pred = np.array([0.05, 0.90, 0.05])       # softmax output
print(f"Cross-entropy loss: {cross_entropy(y_true, y_pred):.4f}")  # ≈ 0.105

# ── 6. Information Gain (used in decision trees) ─────────────────────────────
def information_gain(parent: np.ndarray,
                     children: list[np.ndarray],
                     weights: list[float]) -> float:
    return entropy(parent) - sum(w * entropy(c) for w, c in zip(weights, children))

parent   = np.array([0.5, 0.5])        # 50/50 class split
left     = np.array([0.9, 0.1])        # mostly class 0 after split
right    = np.array([0.1, 0.9])        # mostly class 1
ig = information_gain(parent, [left, right], weights=[0.5, 0.5])
print(f"Information Gain = {ig:.4f} bits")   # close to 1.0 — perfect split

# ── 7. ELBO (VAE objective) — KL as regularization ───────────────────────────
# ELBO = E[log p(x|z)] - KL(q(z|x) || p(z))
# Maximizing ELBO = maximizing reconstruction - penalizing deviation from prior
# For N(μ,σ²) vs N(0,I):  KL = 0.5 · Σ(1 + log σ² - μ² - σ²)

def vae_kl_loss(mu: np.ndarray, log_var: np.ndarray) -> float:
    return -0.5 * np.sum(1 + log_var - mu**2 - np.exp(log_var))

mu      = np.array([0.1, -0.2, 0.5])
log_var = np.array([-0.3, 0.1, -0.1])
print(f"VAE KL loss: {vae_kl_loss(mu, log_var):.4f}")
```

## Learning Path
1. `pip install scipy numpy`
2. Derive cross-entropy from KL divergence on paper (H(p,q) = H(p) + KL(p||q))
3. Implement entropy, KL, and cross-entropy from scratch and validate against `scipy`
4. Reproduce information gain splitting for a toy decision tree
5. Implement the VAE KL loss and verify it collapses to 0 when μ=0, σ=1
6. Read: *Elements of Information Theory* ch.1–2 (Cover & Thomas)

## What to Build
- [ ] Visualize entropy as a function of p for a Bernoulli variable
- [ ] Plot KL(P||Q) vs KL(Q||P) to demonstrate asymmetry
- [ ] Implement a decision tree split selector using information gain
- [ ] Compute mutual information between two features in a dataset and compare to Pearson correlation
- [ ] Add the KL term to a simple autoencoder to create a VAE and watch latent space collapse without it

## Related Folders
- `deep-learning\vae-main\` — ELBO and KL loss in practice
- `machine-learning\decision-trees-main\` — information gain for splits
- `deep-learning\contrastive-learning-main\` — InfoNCE loss uses mutual information
