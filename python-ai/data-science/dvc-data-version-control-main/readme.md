# 📦 DVC — Data Version Control for ML Pipelines

## What is DVC?
DVC (Data Version Control) extends Git to track large datasets, models, and ML pipeline stages that Git cannot handle efficiently. It stores lightweight `.dvc` pointer files in Git while pushing the actual data to remote storage (S3, GCS, Azure, or local). The result is full reproducibility: any commit in your Git history can restore the exact data and model weights used at that point.

## Why Learn It?
- Version datasets and models alongside code in the same Git workflow
- Declare reproducible ML pipelines in `dvc.yaml` and re-run only changed stages
- Share large files with teammates via S3/GCS without bloating the Git repo
- Experiment tracking and parameter management without a heavy MLflow server

## Key Concepts
```python
# ---------- Shell commands (run in terminal) ----------

# 1. Initialise DVC in an existing Git repo
# dvc init
# git add .dvc .dvcignore && git commit -m "init dvc"

# 2. Track a dataset — creates data/train.csv.dvc (committed to Git)
# dvc add data/train.csv
# git add data/train.csv.dvc data/.gitignore
# git commit -m "track training data"

# 3. Configure a remote and push data
# dvc remote add -d myremote s3://my-bucket/dvc-store
# dvc remote add -d localremote /mnt/shared/dvc          # local remote
# dvc push                                                # upload tracked files
# dvc pull                                                # download on another machine

# 4. Declare a pipeline in dvc.yaml
# stages:
#   featurize:
#     cmd: python src/featurize.py
#     deps: [data/train.csv, src/featurize.py]
#     params: [params.yaml: [n_features]]
#     outs: [data/features.pkl]
#   train:
#     cmd: python src/train.py
#     deps: [data/features.pkl, src/train.py]
#     params: [params.yaml: [model.lr, model.n_estimators]]
#     outs: [models/model.pkl]
#     metrics: [metrics/scores.json]

# 5. Run / reproduce the pipeline (only re-runs changed stages)
# dvc repro

# 6. Track params and metrics
import json, yaml

params = yaml.safe_load(open("params.yaml"))
lr = params["model"]["lr"]

metrics = {"accuracy": 0.94, "f1": 0.91}
json.dump(metrics, open("metrics/scores.json", "w"))

# dvc metrics show
# dvc metrics diff main feature-branch

# 7. Experiment tracking
# dvc exp run --set-param model.lr=0.01
# dvc exp show               # table of all experiments
# dvc exp apply <exp-name>   # promote winning experiment to workspace
```

## Learning Path
1. `pip install dvc dvc-s3`  (or `dvc-gs` for GCS, `dvc-azure` for Azure)
2. Run `dvc init` in a Git repo and commit the DVC config
3. Add a CSV dataset with `dvc add`; inspect the generated `.dvc` file
4. Configure a local remote and round-trip with `dvc push` / `dvc pull`
5. Write a two-stage `dvc.yaml` (featurize → train) and run `dvc repro`
6. Edit `params.yaml`, re-run, and compare metrics with `dvc metrics diff`
7. Use `dvc exp run` to sweep hyperparameters and view results with `dvc exp show`

## What to Build
- [ ] Versioned ML project: dataset → features → model → evaluation pipeline
- [ ] Shared team data registry on S3 where multiple projects `dvc import` datasets
- [ ] Hyperparameter sweep comparing 5 learning rates via `dvc exp run`
- [ ] CI/CD workflow (GitHub Actions) that runs `dvc repro` on every PR

## Related Folders
- `data-science/` — EDA, feature engineering, and modelling notebooks
- `deployment/` — exporting DVC-tracked models to a serving endpoint
- `computer-vision/yolov8-main/` — version YOLO training datasets and checkpoints with DVC
