# 🔬 Optuna — Hyperparameter Tuning with Bayesian Optimization

## What is Optuna?
Optuna is a state-of-the-art hyperparameter optimization framework that uses Tree-structured Parzen Estimator (TPE) search — a Bayesian method that learns from past trials to suggest better hyperparameters. It is framework-agnostic and integrates natively with sklearn, XGBoost, LightGBM, and PyTorch.

## Why Learn It?
- TPE finds better hyperparameters in fewer trials than random or grid search
- Pruning stops unpromising trials early, saving significant compute time
- Built-in visualizations reveal which hyperparameters actually matter
- Multi-objective optimization handles accuracy vs. latency trade-offs

## Key Concepts
```python
import optuna
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import cross_val_score

X, y = load_breast_cancer(return_X_y=True)

def objective(trial: optuna.Trial) -> float:
    params = {
        "n_estimators": trial.suggest_int("n_estimators", 100, 1000, step=50),
        "max_depth": trial.suggest_int("max_depth", 3, 10),
        "learning_rate": trial.suggest_float("learning_rate", 1e-3, 0.3, log=True),
        "subsample": trial.suggest_float("subsample", 0.5, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.5, 1.0),
        "reg_alpha": trial.suggest_float("reg_alpha", 1e-8, 10.0, log=True),
        "eval_metric": "auc",
        "random_state": 42,
    }
    model = xgb.XGBClassifier(**params)
    scores = cross_val_score(model, X, y, cv=3, scoring="roc_auc")
    return scores.mean()

# Create study with TPE sampler and median pruner
study = optuna.create_study(
    direction="maximize",
    sampler=optuna.samplers.TPESampler(seed=42),
    pruner=optuna.pruners.MedianPruner(n_startup_trials=5, n_warmup_steps=10),
)
study.optimize(objective, n_trials=50, timeout=120, show_progress_bar=True)

print(f"Best AUC: {study.best_value:.4f}")
print(f"Best params: {study.best_params}")

# Visualizations
import optuna.visualization as vis
vis.plot_optimization_history(study).show()
vis.plot_param_importances(study).show()
vis.plot_contour(study, params=["max_depth", "learning_rate"]).show()

# Multi-objective (accuracy vs model size)
study_mo = optuna.create_study(directions=["maximize", "minimize"])
```

## Learning Path
1. `pip install optuna optuna-dashboard xgboost lightgbm scikit-learn plotly`
2. Write an `objective(trial)` function that returns the metric to optimize
3. Use `trial.suggest_int`, `suggest_float`, `suggest_categorical` to define the search space
4. Add `MedianPruner` to kill bad trials early; run 50–100 trials
5. Visualize with `plot_param_importances` to understand which params matter most

## What to Build
- [ ] Tune XGBoost on a Kaggle competition dataset and beat the default params by 2%+
- [ ] A multi-objective study balancing model AUC vs inference time on a large dataset
- [ ] An Optuna dashboard (`optuna-dashboard`) deployed locally to monitor live trials

## Related Folders
- `machine-learning/xgboost-tutorial-main/` — primary model to tune with Optuna
- `machine-learning/catboost-main/` — tune CatBoost's depth, learning_rate, and l2_leaf_reg
