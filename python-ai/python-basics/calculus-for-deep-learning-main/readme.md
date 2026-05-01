# 📐 Calculus for Deep Learning — Derivatives, Gradients & Backprop

## What is Calculus for Deep Learning?
Calculus is the mathematical engine behind how neural networks learn. Derivatives measure how a small change in a weight affects the loss, and the chain rule ties those changes together across every layer. Gradient descent then uses these derivatives to iteratively nudge weights toward lower loss.

## Why Learn It?
- Understand *why* backpropagation works, not just that it does
- Debug exploding/vanishing gradients by knowing what drives them
- Implement optimizers (SGD, Adam) from first principles
- Read ML papers confidently when they discuss Jacobians or Hessians

## Key Concepts
```python
import numpy as np
import sympy as sp
import torch

# --- Symbolic differentiation with SymPy ---
x = sp.Symbol('x')
f = x**3 + 2*x**2 - 5*x + 1
print("f'(x) =", sp.diff(f, x))          # 3x² + 4x - 5
print("f''(x) =", sp.diff(f, x, 2))      # 6x + 4

# --- Numerical gradient (finite differences) ---
def numerical_grad(f, x, h=1e-5):
    return (f(x + h) - f(x - h)) / (2 * h)

loss = lambda w: (w - 3.0) ** 2
print("Numerical grad at w=1:", numerical_grad(loss, 1.0))  # -4.0

# --- Gradient descent from scratch ---
w = np.float64(0.0)
lr = 0.1
for _ in range(30):
    grad = 2 * (w - 3.0)   # d/dw (w-3)^2
    w -= lr * grad
print(f"Converged w: {w:.4f}")  # ~3.0

# --- Chain rule: backprop through 2-layer network ---
# Forward: x -> h = relu(W1 @ x) -> y_hat = W2 @ h -> loss = MSE
x  = np.array([1.0, 2.0])
W1 = np.random.randn(3, 2) * 0.1
W2 = np.random.randn(1, 3) * 0.1
y  = np.array([1.0])

h_pre = W1 @ x
h     = np.maximum(0, h_pre)          # ReLU
y_hat = W2 @ h
loss  = 0.5 * np.sum((y_hat - y)**2)

# Backward
dL_dyhat = y_hat - y                  # (1,)
dL_dW2   = dL_dyhat[:, None] * h      # outer product
dL_dh    = W2.T @ dL_dyhat            # (3,)
dL_dhpre = dL_dh * (h_pre > 0)       # ReLU gate
dL_dW1   = dL_dhpre[:, None] * x     # (3,2)

# --- PyTorch autograd ---
w_t = torch.tensor(0.0, requires_grad=True)
loss_t = (w_t - 3.0) ** 2
loss_t.backward()
print("torch grad:", w_t.grad)   # tensor(-6.)

# --- Partial derivatives (gradient vector) ---
# f(w1, w2) = w1^2 + w2^2  →  ∇f = [2w1, 2w2]
w = np.array([1.0, 2.0])
grad_f = 2 * w   # [2, 4]
print("Gradient:", grad_f)
```

## Learning Path
1. `pip install numpy sympy torch matplotlib`
2. Study limits → derivatives → chain rule (Khan Academy Calculus)
3. Implement numerical gradient checker and compare to analytical
4. Derive backprop by hand for a 2-layer MLP on paper
5. Verify your hand derivation against `torch.autograd`
6. Explore Jacobians for vector-to-vector functions
7. Experiment with learning rate schedules and watch loss curves

## What to Build
- [ ] Gradient descent visualizer (contour plot + arrow steps)
- [ ] Backprop from scratch: 2-layer MLP, no PyTorch
- [ ] Numerical gradient checker that validates any autograd engine
- [ ] Saddle point explorer: plot f(x,y) = x²−y² and trace gradient steps
- [ ] Compare SGD vs Adam vs RMSprop convergence on the same loss surface

## Related Folders
- `python-basics\linear-algebra-main\` — matrix ops used in Jacobians
- `deep-learning\attention-mechanisms-main\` — softmax gradients in practice
- `deep-learning\diffusion-models-theory-main\` — score-matching loss derivatives
