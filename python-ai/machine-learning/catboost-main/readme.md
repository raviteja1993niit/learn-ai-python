# 🐱 CatBoost — Gradient Boosting for Categorical Data

## What is CatBoost?
CatBoost is Yandex's gradient boosting library with first-class support for categorical features — no manual label encoding or one-hot encoding required. Its ordered boosting algorithm reduces target leakage and often outperforms XGBoost/LightGBM on datasets with many categorical columns.

## Why Learn It?
- Native `cat_features` parameter handles strings/categories without preprocessing
- Ordered boosting reduces prediction shift and overfitting on small datasets
- Built-in overfitting detector stops training automatically, no manual tuning needed
- Fastest inference of the three major boosting libraries for categorical-heavy data

## Key Concepts
```python
import pandas as pd
from catboost import CatBoostClassifier, Pool
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score

# Sample data with real categorical columns
df = pd.read_csv("titanic.csv")
cat_cols = ["Sex", "Embarked", "Pclass"]
feature_cols = ["Age", "Fare", "SibSp", "Parch"] + cat_cols

X = df[feature_cols].fillna("NA")
y = df["Survived"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# No encoding needed — pass cat_features directly
model = CatBoostClassifier(
    iterations=500,
    depth=6,
    learning_rate=0.05,
    cat_features=cat_cols,        # string column names or integer indices
    eval_metric="AUC",
    od_type="Iter",               # overfitting detector
    od_wait=30,
    verbose=False,
    random_seed=42,
)

train_pool = Pool(X_train, y_train, cat_features=cat_cols)
test_pool  = Pool(X_test,  y_test,  cat_features=cat_cols)

model.fit(train_pool, eval_set=test_pool)
print(f"AUC: {roc_auc_score(y_test, model.predict_proba(X_test)[:,1]):.4f}")

# Feature importance
print(model.get_feature_importance(prettified=True))

# | Library    | Categoricals | Speed (train) | Notes                    |
# |------------|--------------|---------------|--------------------------|
# | CatBoost   | Native       | Medium        | Best for cat-heavy data  |
# | XGBoost    | Manual       | Fast (GPU)    | Most flexible            |
# | LightGBM   | Native       | Fastest       | Best for large datasets  |
```

## Learning Path
1. `pip install catboost scikit-learn pandas`
2. Load a dataset with real categorical columns (Titanic, Adult Income, etc.)
3. Pass `cat_features` to `CatBoostClassifier` — compare with and without encoding
4. Enable the overfitting detector (`od_type="Iter"`) and observe early stopping
5. Visualize feature importance and run a three-way comparison with XGBoost and LightGBM

## What to Build
- [ ] A churn prediction model on a telecom dataset with 10+ categorical features
- [ ] A side-by-side benchmark: CatBoost vs XGBoost vs LightGBM on accuracy and training time
- [ ] An Optuna study to tune CatBoost depth, learning_rate, and l2_leaf_reg

## Related Folders
- `machine-learning/xgboost-tutorial-main/` — direct comparison library for tabular boosting
- `machine-learning/optuna-hyperparameter-tuning-main/` — hyperparameter search for CatBoost
