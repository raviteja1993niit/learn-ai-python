# 🔗 Causal Inference — Moving from Correlation to Causation

## What is Causal Inference?
Causal inference is the science of determining cause-and-effect relationships from data, rather than mere correlations. Using frameworks like potential outcomes and Directed Acyclic Graphs (DAGs), it answers questions like "Did this treatment actually cause the outcome?" — critical for policy evaluation, A/B attribution, and business decisions.

## Why Learn It?
- Answer "why" questions that predictive models cannot address
- Estimate treatment effects for policy, product, and clinical decisions
- Avoid Simpson's paradox and confounding traps in observational data
- Use DoWhy and EconML for production-grade causal pipelines
- Validate A/B test results with causal attribution methods

## Key Concepts
```python
import numpy as np
import pandas as pd
import dowhy
from dowhy import CausalModel
from econml.dml import CausalForestDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

# --- Build a Causal DAG with DoWhy ---
model = CausalModel(
    data=df,
    treatment="received_discount",
    outcome="purchased",
    common_causes=["age", "income", "past_purchases"],
    graph="""
        digraph {
            age -> received_discount;
            income -> received_discount;
            age -> purchased;
            income -> purchased;
            past_purchases -> received_discount;
            past_purchases -> purchased;
            received_discount -> purchased;
        }
    """
)
model.view_model()

# --- Identify the Causal Effect ---
identified_estimand = model.identify_effect(proceed_when_unidentifiable=True)
print(identified_estimand)

# --- Estimate the Average Treatment Effect (ATE) ---
estimate = model.estimate_effect(
    identified_estimand,
    method_name="backdoor.propensity_score_matching"
)
print(f"ATE (propensity score matching): {estimate.value:.4f}")

# Doubly-robust estimation
estimate_dr = model.estimate_effect(
    identified_estimand,
    method_name="backdoor.econml.dr.LinearDRLearner",
    method_params={"init_params": {}, "fit_params": {}}
)

# --- Refutation Tests (validate the estimate) ---
refute_placebo = model.refute_estimate(estimate, method_name="placebo_treatment_refuter")
refute_subset  = model.refute_estimate(estimate, method_name="data_subset_refuter")
print(refute_placebo)
print(refute_subset)

# --- Heterogeneous Treatment Effects with EconML CausalForest ---
Y  = df["purchased"].values
T  = df["received_discount"].values
X  = df[["age", "income", "past_purchases"]].values
W  = None   # no additional controls beyond X

cf = CausalForestDML(
    model_y=GradientBoostingRegressor(),
    model_t=GradientBoostingClassifier(),
    n_estimators=200,
    random_state=42
)
cf.fit(Y, T, X=X, W=W)

# Individual treatment effects
cate       = cf.effect(X)
lb, ub     = cf.effect_interval(X, alpha=0.05)
print(f"Mean CATE: {cate.mean():.4f} (95% CI: [{lb.mean():.4f}, {ub.mean():.4f}])")

# --- Propensity Score Matching (manual) ---
from sklearn.linear_model import LogisticRegression
ps_model = LogisticRegression().fit(X, T)
df["propensity"] = ps_model.predict_proba(X)[:, 1]

# --- Difference-in-Differences ---
did = (
    df.query("post==1 and treated==1")["outcome"].mean()
  - df.query("post==0 and treated==1")["outcome"].mean()
  - df.query("post==1 and treated==0")["outcome"].mean()
  + df.query("post==0 and treated==0")["outcome"].mean()
)
print(f"DiD Estimate: {did:.4f}")
```

## Learning Path
1. Understand correlation vs causation with classic examples (ice cream & drowning)
2. Learn Directed Acyclic Graphs (DAGs): nodes, edges, confounders, colliders
3. Study the potential outcomes framework (Rubin Causal Model): PO(1), PO(0), ATE
4. Use DoWhy to model, identify, estimate, and refute causal effects
5. Apply propensity score matching and inverse probability weighting
6. Learn instrumental variables for unmeasured confounders
7. Study difference-in-differences for panel and policy data
8. Explore heterogeneous treatment effects with EconML's CausalForestDML
9. Apply causal attribution to A/B test results and marketing mix models
10. Build a full causal inference pipeline with sensitivity analysis

## What to Build
- [ ] DoWhy pipeline that estimates treatment effect of a discount on conversion
- [ ] CausalForest CATE model that finds which user segments benefit most from a feature
- [ ] Difference-in-differences analysis of a policy change using historical panel data
- [ ] Propensity score matching implementation with balance diagnostics
- [ ] Refutation test suite to validate causal estimates against placebo/noise
- [ ] Causal attribution dashboard comparing A/B test vs causal estimate

## Related Folders
- `data-science/ab-testing-experimentation-main/` — complement RCTs with causal analysis
- `data-science/responsible-ai-bias-detection-main/` — separate causal from spurious correlations
- `data-science/time-series-prophet-arima-main/` — causal impact analysis on time series
