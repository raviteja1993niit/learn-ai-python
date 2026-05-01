# 📦 Python Packaging — Poetry, uv & Publishing to PyPI

## What is Python Packaging?
Python packaging is the discipline of bundling your code so others (or future you) can install it with a single command. Modern tools like Poetry and uv replace the old `setup.py` era with a clean `pyproject.toml`-centric workflow. Mastering packaging lets you ship reusable ML utilities, CLI tools, and libraries to the world.

## Why Learn It?
- Share ML utility libraries across projects without copy-pasting code
- Publish models, preprocessors, or evaluation tools to PyPI
- Manage reproducible virtual environments for every project
- Build CLI entry points so teammates can run your tools like native commands

## Key Concepts
```python
# ── pyproject.toml anatomy ──────────────────────────────────────────────
# [tool.poetry]
# name = "ml-utils"
# version = "0.1.0"
# description = "Reusable ML preprocessing helpers"
# authors = ["You <you@example.com>"]
# readme = "README.md"
#
# [tool.poetry.dependencies]
# python = "^3.11"
# numpy = "^1.26"
# scikit-learn = "^1.4"
#
# [tool.poetry.dev-dependencies]
# pytest = "^8.0"
# ruff = "^0.4"
#
# [tool.poetry.scripts]
# ml-utils = "ml_utils.cli:main"   # entry_point → CLI command
#
# [build-system]
# requires = ["poetry-core"]
# build-backend = "poetry.core.masonry.api"

# ── src layout ──────────────────────────────────────────────────────────
# ml-utils/
# ├── pyproject.toml
# ├── src/
# │   └── ml_utils/
# │       ├── __init__.py        ← expose public API
# │       ├── preprocessing.py
# │       └── cli.py
# └── tests/

# ── __init__.py: clean public API ───────────────────────────────────────
# from .preprocessing import normalize, encode_labels
# __version__ = "0.1.0"
# __all__ = ["normalize", "encode_labels", "__version__"]

# ── CLI entry point ──────────────────────────────────────────────────────
import argparse

def main():
    parser = argparse.ArgumentParser(description="ML Utils CLI")
    parser.add_argument("--normalize", type=str, help="Path to CSV to normalize")
    args = parser.parse_args()
    if args.normalize:
        print(f"Normalizing {args.normalize} ...")

# ── Semver cheat sheet ───────────────────────────────────────────────────
# MAJOR.MINOR.PATCH  e.g. 1.4.2
# MAJOR → breaking API change
# MINOR → new backward-compatible feature
# PATCH → bug fix
```

## Learning Path
1. `pip install poetry` then `curl -Lsf https://astral.sh/uv/install.sh | sh` (or `pip install uv`)
2. `poetry new ml-utils` — scaffold a fresh project
3. `poetry add numpy scikit-learn` — add runtime deps
4. `poetry add --group dev pytest ruff` — add dev deps
5. Build the package: `poetry build` → inspect `dist/` wheel + tarball
6. Publish to TestPyPI: `poetry publish -r testpypi`
7. Try uv: `uv venv .venv && uv pip install -r requirements.txt`
8. Test install from TestPyPI: `pip install --index-url https://test.pypi.org/simple/ ml-utils`

## What to Build
- [ ] Package a `normalize` + `encode_labels` ML preprocessing library
- [ ] Add a `ml-utils` CLI command using `[tool.poetry.scripts]`
- [ ] Publish v0.1.0 to TestPyPI and install it in a fresh venv
- [ ] Create a GitHub Actions workflow that auto-publishes on tag push
- [ ] Benchmark `uv pip install torch` vs `pip install torch` (speed diff)

## Related Folders
- `python-basics\python-environments-main\` — venv + conda foundations
- `python-basics\calculus-for-deep-learning-main\` — example lib to package
- `mlops\model-serving-main\` — packaging models as installable services
