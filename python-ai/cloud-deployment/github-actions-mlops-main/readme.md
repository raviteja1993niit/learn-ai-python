# ⚙️ GitHub Actions CI/CD for ML — Automated MLOps Pipelines

## What is GitHub Actions CI/CD for ML?
GitHub Actions lets you define automated workflows as YAML files that trigger on code events
(push, PR, schedule) and run jobs on GitHub-hosted or self-hosted runners. For ML, this means
automatically testing model code, pulling versioned data, training, evaluating, and deploying
— all gated on metric thresholds before anything reaches production.

## Why Learn It?
- Catches regressions early: every PR runs unit tests on data preprocessing and model code
- Enforces quality gates — a model only gets deployed if evaluation metrics exceed a threshold
- Self-hosted GPU runners let you run real training jobs inside the same CI/CD flow
- Matrix builds verify your ML code works across Python versions and dependency combinations

## Key Concepts
```yaml
# .github/workflows/ml-pipeline.yml
name: ML Pipeline

# Triggers: on push/PR to main, and weekly retraining schedule
on:
  push:           { branches: [main] }
  pull_request:   { branches: [main] }
  schedule:       [ cron: "0 2 * * 1" ]   # every Monday at 02:00 UTC

env:
  PYTHON_VERSION:     "3.11"
  ACCURACY_THRESHOLD: "0.88"              # deploy only if model beats this score

jobs:

  # ── Job 1: Run tests across multiple Python versions ─────────────────────
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]   # matrix: 3 parallel builds
    steps:
      - uses: actions/checkout@v4                   # clone the repo
      - uses: actions/setup-python@v5
        with: { python-version: "${{ matrix.python-version }}", cache: pip }
      - run: pip install -r requirements.txt
      - run: pytest tests/ -v --tb=short            # fail fast on any test error

  # ── Job 2: Train model on a GPU runner (runs only after tests pass) ───────
  train:
    needs: test                                     # depends on test job
    runs-on: [self-hosted, gpu]                     # self-hosted GPU machine
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "${{ env.PYTHON_VERSION }}" }
      - run: pip install -r requirements.txt dvc[s3]
      - name: Pull versioned data via DVC
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}     # stored in repo secrets
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: dvc pull data/processed.dvc             # fetch data from S3 remote
      - run: python src/train.py --output models/model.pkl
      - uses: actions/upload-artifact@v4             # share model between jobs
        with: { name: trained-model, path: models/model.pkl }

  # ── Job 3: Evaluate — quality gate blocks deploy if accuracy too low ──────
  evaluate:
    needs: train
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4           # retrieve model from train job
        with: { name: trained-model, path: models/ }
      - run: pip install -r requirements.txt
      - name: Accuracy gate
        run: |
          ACC=$(python src/evaluate.py --model models/model.pkl)
          echo "Accuracy: $ACC"
          # assert: if accuracy < threshold, this step fails and deploy is blocked
          python -c "assert float('$ACC') >= ${{ env.ACCURACY_THRESHOLD }}, \
            'Accuracy $ACC below threshold ${{ env.ACCURACY_THRESHOLD }}'"

  # ── Job 4: Deploy — only on main branch, only after gate passes ───────────
  deploy:
    needs: evaluate
    if: github.ref == 'refs/heads/main'             # skip on PRs — main branch only
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: trained-model, path: models/ }
      - name: Build & push Docker image to GHCR
        env: { REGISTRY_TOKEN: "${{ secrets.REGISTRY_TOKEN }}" }
        run: |
          # authenticate to GitHub Container Registry
          echo "$REGISTRY_TOKEN" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          # tag image with commit SHA for full traceability
          docker build -t ghcr.io/${{ github.repository }}/ml-model:${{ github.sha }} .
          docker push ghcr.io/${{ github.repository }}/ml-model:${{ github.sha }}
```

## Learning Path
1. Create `.github/workflows/` directory in your repo
2. Start with a minimal workflow: `actions/checkout` + `setup-python` + `pytest`
3. Add DVC (`pip install dvc`) and version a small dataset; practice `dvc pull` in CI
4. Add a training step; upload the model as a workflow artifact
5. Write `src/evaluate.py` that prints a float metric; add the evaluation gate job
6. Configure a self-hosted runner on a GPU machine (Settings → Actions → Runners)
7. Add `secrets` for AWS/GCP credentials and registry tokens in repo Settings
8. Experiment with matrix strategy to test multiple Python/dependency combinations

## What to Build
- [ ] PR check: run `pytest` on preprocessing + model unit tests on every pull request
- [ ] Nightly retraining cron job that auto-deploys if accuracy stays above threshold
- [ ] DVC + S3 data versioning pipeline integrated end-to-end in GitHub Actions
- [ ] Multi-environment deploy: staging on every push to `main`, production on tagged releases
- [ ] Slack/email notification step that posts model metrics when a deploy succeeds

## Related Folders
- `cloud-deployment\weights-and-biases-main\` — log training metrics from CI runs to W&B
- `big-data\apache-airflow-main\`             — Airflow for complex scheduled orchestration
- `cloud-deployment\mlflow-main\`             — MLflow model registry as deploy target
- `cloud-deployment\docker-main\`             — build and push Docker images in the deploy job
