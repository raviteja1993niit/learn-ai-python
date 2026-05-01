# 🔒 Differential Privacy — Privacy-Preserving ML

## What is Differential Privacy?
Differential Privacy (DP) is a mathematical framework that guarantees adding or removing any single individual's data from a dataset cannot significantly change the output of an algorithm. It works by injecting calibrated noise into computations, controlled by a privacy budget (ε, δ). It's the gold standard for GDPR/HIPAA-compliant ML.

## Why Learn It?
- Legal compliance: GDPR Article 25 (privacy by design), HIPAA Safe Harbor
- Prevents membership inference attacks on trained ML models
- Federated learning deployments require DP guarantees
- Google, Apple, and Meta use DP in production at scale
- Growing employer demand for privacy-aware ML engineers

## Key Concepts
```python
import numpy as np

# --- Laplace Mechanism (pure ε-DP) ---
def laplace_mechanism(true_value: float, sensitivity: float, epsilon: float) -> float:
    """Add Laplace noise calibrated to sensitivity/epsilon."""
    scale = sensitivity / epsilon
    noise = np.random.laplace(0, scale)
    return true_value + noise

age_mean = 35.4          # true statistic
sensitivity = 1.0        # max one person can change the mean
epsilon = 1.0            # privacy budget
private_mean = laplace_mechanism(age_mean, sensitivity, epsilon)
print(f"Private mean: {private_mean:.2f}")

# --- Gaussian Mechanism ((ε,δ)-DP) ---
def gaussian_mechanism(true_value: float, sensitivity: float, epsilon: float, delta: float) -> float:
    sigma = sensitivity * np.sqrt(2 * np.log(1.25 / delta)) / epsilon
    return true_value + np.random.normal(0, sigma)

private_sum = gaussian_mechanism(1000.0, sensitivity=1.0, epsilon=0.5, delta=1e-5)

# --- Google DP Library (dp-accounting) ---
# pip install google-dp
from dp_accounting.pld import privacy_loss_distribution as pld
# BoundedMean and BoundedSum via Pipeline DP
import pipeline_dp

# --- Opacus: DP training for PyTorch ---
# pip install opacus
import torch
from torch import nn
from opacus import PrivacyEngine

model = nn.Sequential(nn.Linear(10, 5), nn.ReLU(), nn.Linear(5, 1))
optimizer = torch.optim.SGD(model.parameters(), lr=0.01)

privacy_engine = PrivacyEngine()
model, optimizer, data_loader = privacy_engine.make_private(
    module=model,
    optimizer=optimizer,
    data_loader=torch.utils.data.DataLoader(
        torch.utils.data.TensorDataset(torch.randn(100, 10), torch.randn(100, 1)),
        batch_size=16,
    ),
    noise_multiplier=1.1,   # higher = more noise = more privacy
    max_grad_norm=1.0,       # gradient clipping (DP-SGD requirement)
)

for epoch in range(5):
    for X, y in data_loader:
        optimizer.zero_grad()
        loss = nn.MSELoss()(model(X), y)
        loss.backward()
        optimizer.step()

epsilon_spent = privacy_engine.get_epsilon(delta=1e-5)
print(f"(ε={epsilon_spent:.2f}, δ=1e-5) privacy guarantee after training")

# --- TensorFlow Privacy ---
# pip install tensorflow-privacy
# from tensorflow_privacy.optimizers.dp_optimizer_keras import DPKerasAdamOptimizer
# optimizer = DPKerasAdamOptimizer(
#     l2_norm_clip=1.0, noise_multiplier=1.1, num_microbatches=16, learning_rate=0.001
# )

# --- Local DP (randomized response) ---
def randomized_response(true_answer: bool, epsilon: float) -> bool:
    """Local DP: each user randomizes their own answer before sharing."""
    p_truth = np.exp(epsilon) / (np.exp(epsilon) + 1)
    return true_answer if np.random.rand() < p_truth else not true_answer

responses = [randomized_response(True, epsilon=2.0) for _ in range(1000)]
# Estimate true proportion using known flip probability
```

## Privacy Budget Guide
| ε value  | Privacy level     | Utility impact | Typical use         |
|----------|-------------------|----------------|---------------------|
| ε < 1    | Very strong       | High noise     | Census, healthcare  |
| 1 ≤ ε ≤ 5| Moderate          | Moderate noise | Model training      |
| ε > 10   | Weak              | Low noise      | Aggregate analytics |

## Learning Path
1. Implement Laplace and Gaussian mechanisms from scratch
2. Run Opacus `make_private` on a simple PyTorch classifier
3. Track privacy budget with `get_epsilon()` across epochs
4. Compare model accuracy at ε=1, ε=5, ε=10 (privacy-utility tradeoff)
5. Explore PipelineDP for aggregate analytics on DataFrames
6. Survey GDPR/HIPAA requirements and map DP guarantees to compliance

## What to Build
- [ ] DP mean/count statistics on a synthetic healthcare dataset
- [ ] Opacus-trained binary classifier with ε ≤ 3 guarantee
- [ ] Privacy-utility tradeoff chart (accuracy vs epsilon curve)
- [ ] Local DP survey simulation with randomized response
- [ ] Federated learning sketch with DP noise injection per client

## Related Folders
- `data-science\federated-learning-main\` — DP is core to federated ML
- `data-science\machine-learning-main\` — base ML models to make private
- `data-science\mlops-main\` — compliance logging and audit trails
