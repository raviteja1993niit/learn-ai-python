# 📊 Weights & Biases (W&B) — Experiment Tracking & MLOps

## What is Weights & Biases?
Weights & Biases (W&B) is a machine learning experiment tracking platform that logs metrics,
visualizes training runs, and manages models and datasets as versioned Artifacts. It integrates
with PyTorch, scikit-learn, HuggingFace, and more, giving teams a shared dashboard for every run.

## Why Learn It?
- Replaces manual metric logging with automatic, searchable experiment history
- Sweeps automate hyperparameter search (Bayesian, random, grid) without extra code
- Artifacts version datasets and models so experiments are fully reproducible
- Model Registry provides a governed promotion path: staging → production
- W&B Tables make it easy to visually audit predictions and spot labelling errors

## Key Concepts
```python
import wandb
from wandb import Artifact

# 1. Initialize a run
run = wandb.init(
    project="image-classifier",
    config={"lr": 1e-3, "epochs": 20, "batch_size": 64, "architecture": "resnet18"},
)
config = wandb.config  # access config values

# 2. Log metrics & media each step
for epoch in range(config.epochs):
    train_loss, val_acc = train_one_epoch(model, loader)
    wandb.log({"epoch": epoch, "train/loss": train_loss, "val/accuracy": val_acc})
    wandb.log({"predictions": wandb.Image(sample_img, caption="epoch {epoch}")})

# 3. Save a model as a versioned Artifact
artifact = Artifact("resnet18-classifier", type="model")
artifact.add_file("model.pth")
run.log_artifact(artifact)

# 4. Hyperparameter Sweep (bayesian)
sweep_config = {
    "method": "bayes",
    "metric": {"goal": "maximize", "name": "val/accuracy"},
    "parameters": {
        "lr":         {"distribution": "log_uniform_values", "min": 1e-5, "max": 1e-2},
        "batch_size": {"values": [32, 64, 128]},
    },
}
sweep_id = wandb.sweep(sweep_config, project="image-classifier")
wandb.agent(sweep_id, function=train, count=20)

# 5. W&B Tables — explore predictions
table = wandb.Table(columns=["image", "pred", "truth"])
for img, pred, label in zip(images, preds, labels):
    table.add_data(wandb.Image(img), pred, label)
wandb.log({"eval_table": table})

run.finish()
```

## Learning Path
1. `pip install wandb`
2. `wandb login` — authenticate with your W&B account (free tier available)
3. Add `wandb.init()` + `wandb.log()` to an existing PyTorch/sklearn training loop
4. Browse the W&B UI: compare runs, view loss curves, inspect system metrics
5. Log your first Artifact (dataset or model checkpoint)
6. Configure and launch a Sweep; analyse parallel-coordinate plots in the UI
7. Register a model in the Model Registry and set an alias (`production`)
8. Explore W&B Tables with a classification or object-detection dataset

## What to Build
- [ ] Image classifier with full run tracking (loss, accuracy, sample predictions)
- [ ] Bayesian sweep over learning-rate & optimizer for a regression problem
- [ ] Dataset versioning pipeline: raw CSV → cleaned CSV as linked Artifacts
- [ ] HuggingFace fine-tune logged to W&B with `report_to="wandb"` in `TrainingArguments`
- [ ] Team dashboard comparing 10+ runs with custom chart panels

## Related Folders
- `cloud-deployment\mlflow-main\`          — alternative experiment tracker (local/self-hosted)
- `cloud-deployment\github-actions-mlops-main\` — trigger W&B runs from CI/CD pipelines
- `deep-learning\pytorch-main\`            — primary training framework to integrate with W&B
- `nlp\huggingface-transformers-main\`     — HuggingFace trainer has built-in W&B support
