# 🌲 XGBoost — Gradient Boosting at Scale

## What is XGBoost?
XGBoost (eXtreme Gradient Boosting) is an optimized gradient boosting library that dominates tabular ML competitions. It builds an ensemble of decision trees sequentially, with each tree correcting the errors of the previous one, delivering top accuracy with built-in regularization and GPU support.

## Why Learn It?
- Wins the majority of Kaggle tabular competitions alongside LightGBM and CatBoost
- Handles missing values natively and is robust to feature scaling
- SHAP integration provides world-class model explainability
- Supports GPU training (`device="cuda"`) for large datasets

## Key Concepts
```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score
import shap

X, y = load_breast_cancer(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Classifier with key hyperparameters
model = xgb.XGBClassifier(
    n_estimators=500,
    max_depth=6,
    learning_rate=0.05,
    subsample=0.8,
    colsample_bytree=0.8,
    reg_alpha=0.1,       # L1 regularization
    reg_lambda=1.0,      # L2 regularization
    eval_metric="auc",
    early_stopping_rounds=20,
    device="cpu",        # change to "cuda" for GPU
    random_state=42,
)

model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)
print(f"AUC: {roc_auc_score(y_test, model.predict_proba(X_test)[:,1]):.4f}")

# SHAP explainability
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_test)
shap.summary_plot(shap_values, X_test)

# Low-level DMatrix API (faster for large datasets)
dtrain = xgb.DMatrix(X_train, label=y_train)
dtest  = xgb.DMatrix(X_test,  label=y_test)
params = {"objective": "binary:logistic", "max_depth": 5, "eta": 0.1}
bst = xgb.train(params, dtrain, num_boost_round=100,
                evals=[(dtest, "test")], verbose_eval=False)
```

## Learning Path
1. `pip install xgboost shap scikit-learn`
2. Train `XGBClassifier` on a real dataset; tune `n_estimators` + `max_depth`
3. Add `early_stopping_rounds` to prevent overfitting automatically
4. Use SHAP `summary_plot` and `waterfall_plot` to explain predictions
5. Compare with LightGBM and CatBoost on the same dataset; benchmark training time

## What to Build
- [ ] A credit risk classifier with SHAP waterfall explanations per prediction
- [ ] A hyperparameter search using Optuna over XGBoost's key params on a Kaggle dataset
- [ ] A GPU vs CPU training benchmark on 1M rows using the DMatrix API

## Related Folders
- `machine-learning/optuna-hyperparameter-tuning-main/` — tune XGBoost params with Optuna TPE sampler
- `machine-learning/catboost-main/` — compare XGBoost vs CatBoost on categorical-heavy datasets
