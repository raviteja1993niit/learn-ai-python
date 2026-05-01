# ⚖️ Responsible AI & Bias Detection — Building Fair and Explainable Models

## What is Responsible AI?
Responsible AI is the practice of designing, building, and deploying AI systems that are fair, transparent, accountable, and safe. It covers detecting and mitigating bias in data and models, explaining predictions to affected users, and meeting regulatory requirements like GDPR and the EU AI Act.

## Why Learn It?
- Prevent discriminatory outcomes in hiring, lending, healthcare, and legal systems
- Meet GDPR, EU AI Act, and internal governance requirements
- Build trust with users through explainability (LIME, SHAP)
- Produce model cards and data cards for documentation and audits
- Use Microsoft's Responsible AI Toolbox for integrated fairness + debugging

## Key Concepts
```python
import numpy as np
import pandas as pd
import shap
from lime.lime_tabular import LimeTabularExplainer

# --- IBM AIF360: Disparate Impact ---
from aif360.datasets import BinaryLabelDataset
from aif360.metrics import BinaryLabelDatasetMetric, ClassificationMetric
from aif360.algorithms.preprocessing import Reweighing

df = pd.read_csv("credit.csv")
dataset = BinaryLabelDataset(
    df=df,
    label_names=["loan_approved"],
    protected_attribute_names=["gender"]
)
metric = BinaryLabelDatasetMetric(
    dataset,
    privileged_groups=[{"gender": 1}],
    unprivileged_groups=[{"gender": 0}]
)
print(f"Disparate Impact: {metric.disparate_impact():.3f}")   # ideal = 1.0
print(f"Mean Difference:  {metric.mean_difference():.3f}")    # ideal = 0.0

# Apply Reweighing mitigation
rw         = Reweighing(privileged_groups=[{"gender": 1}],
                        unprivileged_groups=[{"gender": 0}])
ds_fair    = rw.fit_transform(dataset)

# --- Fairlearn: MetricFrame ---
from fairlearn.metrics import MetricFrame, demographic_parity_difference, equalized_odds_difference
from sklearn.metrics import accuracy_score

mf = MetricFrame(
    metrics={"accuracy": accuracy_score},
    y_true=y_test,
    y_pred=y_pred,
    sensitive_features=df_test["gender"]
)
print(mf.by_group)
print(f"Demographic Parity Diff:  {demographic_parity_difference(y_test, y_pred, sensitive_features=df_test['gender']):.4f}")
print(f"Equalized Odds Diff:      {equalized_odds_difference(y_test, y_pred, sensitive_features=df_test['gender']):.4f}")

# Fairlearn mitigation: ExponentiatedGradient
from fairlearn.reductions import ExponentiatedGradient, DemographicParity
from sklearn.linear_model import LogisticRegression
mitigator = ExponentiatedGradient(LogisticRegression(), DemographicParity())
mitigator.fit(X_train, y_train, sensitive_features=df_train["gender"])
y_pred_fair = mitigator.predict(X_test)

# --- SHAP Global Explainability ---
import xgboost as xgb
model    = xgb.XGBClassifier().fit(X_train, y_train)
explainer = shap.TreeExplainer(model)
shap_vals = explainer.shap_values(X_test)
shap.summary_plot(shap_vals, X_test, plot_type="bar")   # feature importance
shap.waterfall_plot(explainer(X_test[0:1])[0])          # single prediction

# --- LIME Local Explainability ---
lime_exp = LimeTabularExplainer(X_train, feature_names=feature_names,
                                class_names=["denied", "approved"], mode="classification")
explanation = lime_exp.explain_instance(X_test[0], model.predict_proba, num_features=6)
explanation.show_in_notebook()
```

## Learning Path
1. Study fairness definitions: demographic parity, equalized odds, individual fairness
2. Learn IBM AIF360 for dataset-level bias metrics and preprocessing mitigation
3. Use Fairlearn's MetricFrame to audit model performance across subgroups
4. Apply Fairlearn's ExponentiatedGradient or GridSearch for in-processing mitigation
5. Explain model predictions globally with SHAP and locally with LIME
6. Write model cards documenting intended use, performance, and limitations
7. Write data cards documenting dataset provenance, collection, and biases
8. Map your AI system to GDPR Article 22 and EU AI Act risk categories
9. Explore the Microsoft Responsible AI Toolbox for unified fairness + error analysis
10. Build an end-to-end responsible AI audit pipeline for a real dataset

## What to Build
- [ ] Bias audit report for a credit or hiring dataset using AIF360 and Fairlearn
- [ ] SHAP-powered explanation dashboard for a tabular classification model
- [ ] Fair model pipeline: detect bias → apply mitigation → compare accuracy/fairness tradeoff
- [ ] Model card generator that auto-populates from sklearn model metadata
- [ ] GDPR compliance checklist runner for a production ML system
- [ ] Responsible AI Toolbox integration for error analysis + fairness in one UI

## Related Folders
- `data-science/ab-testing-experimentation-main/` — ensure experiments are tested fairly across groups
- `data-science/causal-inference-main/` — distinguish bias from genuine causal differences
- `ml-engineering/model-deployment-main/` — monitor fairness metrics in production
