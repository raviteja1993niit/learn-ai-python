# ⚡ LightGBM — Fast Gradient Boosting

## What is LightGBM?
LightGBM (Light Gradient Boosting Machine) by Microsoft is one of the **fastest and most accurate
gradient boosting frameworks**. It wins most Kaggle structured data competitions.

## Why Learn It?
- Faster than XGBoost (leaf-wise tree growth vs level-wise)
- Handles large datasets with low memory
- Native support for categorical features
- Built-in GPU training

## LightGBM vs XGBoost vs CatBoost

| Feature | LightGBM | XGBoost | CatBoost |
|---------|----------|---------|----------|
| Speed | ⚡ Fastest | Fast | Moderate |
| Categorical | Native | Manual encoding | Native (best) |
| GPU | ✅ | ✅ | ✅ |
| Small data | ⚠️ Overfits | Good | Best |
| Large data | Best | Good | Good |

## Key Parameters
```python
params = {
    "n_estimators": 1000,
    "learning_rate": 0.05,
    "num_leaves": 31,          # main complexity control
    "max_depth": -1,           # -1 = no limit
    "min_child_samples": 20,
    "feature_fraction": 0.9,   # like colsample_bytree
    "bagging_fraction": 0.8,
    "bagging_freq": 5,
    "reg_alpha": 0.1,          # L1
    "reg_lambda": 0.1,         # L2
}
```

## Learning Path
1. `pip install lightgbm`
2. Train on Titanic / House Price dataset
3. Tune with Optuna
4. Feature importance & SHAP values
5. Compare with XGBoost on same dataset

## What to Build
- [ ] Credit scoring model (LightGBM vs XGBoost comparison)
- [ ] Sales forecasting pipeline
- [ ] Customer churn prediction
- [ ] Kaggle competition entry

## Related Folders
- `machine-learning/SVM-Kernels-main/` — classic algorithms
- `machine-learning/Cutom-Ensemble-ML-main/` — ensemble methods
- `machine-learning/Shapash--main/` — model explainability