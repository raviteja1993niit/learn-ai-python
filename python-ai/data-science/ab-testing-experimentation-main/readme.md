# 🧪 A/B Testing & Experimentation — Rigorous Hypothesis Testing for ML & Products

## What is A/B Testing?
A/B testing is a controlled experiment that compares two variants (A and B) to determine which performs better on a target metric. It combines statistics and product intuition to make data-driven decisions. In ML, it extends to model evaluation, feature rollouts, and canary deployments.

## Why Learn It?
- Make statistically sound decisions instead of guessing
- Validate ML model improvements before full rollout
- Understand p-values, power, and sample size to avoid false conclusions
- Apply Bayesian methods for faster, more intuitive results
- Prevent costly mistakes from underpowered or biased experiments

## Key Concepts
```python
import numpy as np
from scipy import stats
from statsmodels.stats.power import TTestIndPower
import pymc as pm

# --- Frequentist A/B Test ---
control   = np.random.binomial(1, 0.10, 1000)   # 10% conversion
treatment = np.random.binomial(1, 0.13, 1000)   # 13% conversion

t_stat, p_value = stats.ttest_ind(control, treatment)
print(f"p-value: {p_value:.4f} — {'Significant' if p_value < 0.05 else 'Not significant'}")

# Cohen's d effect size
pooled_std = np.sqrt((control.std()**2 + treatment.std()**2) / 2)
cohens_d   = (treatment.mean() - control.mean()) / pooled_std
print(f"Cohen's d: {cohens_d:.3f}")

# --- Sample Size Calculation ---
analysis    = TTestIndPower()
sample_size = analysis.solve_power(effect_size=0.2, alpha=0.05, power=0.80)
print(f"Required sample size per group: {int(np.ceil(sample_size))}")

# --- Multiple Testing Correction (Bonferroni) ---
from statsmodels.stats.multitest import multipletests
p_values = [0.03, 0.01, 0.07, 0.002, 0.04]
reject, p_corrected, _, _ = multipletests(p_values, alpha=0.05, method='fdr_bh')
print("Corrected p-values (BH):", p_corrected.round(4))
print("Reject H0?:", reject)

# --- Bayesian A/B Test with PyMC ---
with pm.Model() as model:
    p_control   = pm.Beta("p_control",   alpha=1, beta=1)
    p_treatment = pm.Beta("p_treatment", alpha=1, beta=1)
    obs_control   = pm.Binomial("obs_control",   n=1000, p=p_control,   observed=100)
    obs_treatment = pm.Binomial("obs_treatment", n=1000, p=p_treatment, observed=130)
    lift          = pm.Deterministic("lift", p_treatment - p_control)
    trace = pm.sample(2000, tune=1000, progressbar=False)

prob_better = (trace.posterior["lift"] > 0).mean().item()
print(f"P(treatment > control): {prob_better:.2%}")

# --- ML Shadow Mode Experiment ---
# Route 100% traffic to model_A; log model_B predictions without serving them
def shadow_predict(request, model_a, model_b, log_fn):
    pred_a = model_a.predict(request)   # served to user
    pred_b = model_b.predict(request)   # shadowed — logged only
    log_fn({"shadow_pred": pred_b, "live_pred": pred_a})
    return pred_a
```

## Learning Path
1. Understand null hypothesis (H0) vs alternative hypothesis (H1)
2. Learn t-tests, chi-square tests, and Mann-Whitney U for different data types
3. Study Type I (false positive) and Type II (false negative) errors
4. Calculate statistical power and required sample sizes with `statsmodels`
5. Explore effect sizes (Cohen's d, relative lift) for practical significance
6. Apply multiple testing corrections (Bonferroni, Benjamini-Hochberg)
7. Learn Bayesian A/B testing with PyMC or Beta-Binomial conjugate model
8. Implement sequential testing (SPRT) for early stopping
9. Build ML-specific experiments: shadow mode, canary deployments, interleaving

## What to Build
- [ ] Frequentist A/B test pipeline with power analysis and significance report
- [ ] Bayesian A/B dashboard showing posterior distributions and lift probability
- [ ] Multiple metric experiment with BH correction to control false discovery rate
- [ ] Shadow-mode ML experiment framework that logs both model predictions
- [ ] Canary deployment simulator that gradually shifts traffic with auto-rollback
- [ ] Sequential test that monitors a live experiment and stops at significance

## Related Folders
- `data-science/causal-inference-main/` — move beyond correlation to true causal effects
- `data-science/responsible-ai-bias-detection-main/` — ensure experiments are fair across groups
- `ml-engineering/model-deployment-main/` — deploy models with canary & blue-green strategies
