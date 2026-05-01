# Git, GitHub & Version Control — Theory

## 1. What is Git?

Git is a **distributed version control system (DVCS)** created by Linus Torvalds in 2005.
Unlike centralised VCS (e.g., SVN), every developer holds a **full copy** of the repository
— including its entire history — on their local machine. This means:

- You can work **offline** and commit changes locally.
- There is **no single point of failure**; every clone is a backup.
- Operations like `log`, `diff`, and `branch` are nearly instantaneous (local I/O, not network).
- Merging and branching are first-class citizens — cheap and fast.

### Centralised vs Distributed VCS

| Feature              | Centralised (SVN)        | Distributed (Git)         |
|----------------------|--------------------------|---------------------------|
| Repository location  | One server               | Every developer           |
| Offline work         | Very limited             | Full capability           |
| Branching cost       | Expensive (file copies)  | Cheap (pointer/hash)      |
| History              | Linear on server         | Full DAG locally          |

---

## 2. Git's Internal Object Model

Git stores everything as **objects** in `.git/objects/`. Each object is identified by its
SHA-1 (or SHA-256 in newer Git) hash — a 40-character hex string derived from the content.

### 2.1 Blob
A **blob** (binary large object) stores the raw contents of a file. It contains no filename
or metadata — just bytes. Two files with identical content share one blob.

```
git cat-file -p <blob-sha>   # inspect a blob
```

### 2.2 Tree
A **tree** object represents a directory. It contains a list of entries, each mapping:
- a mode (file permissions: 100644, 100755, 040000)
- an object type (blob or tree)
- a SHA-1 hash
- a filename

Trees are recursive: a tree can reference other trees (subdirectories).

### 2.3 Commit
A **commit** object wraps a tree snapshot with metadata:
- Pointer to the root **tree** object
- One or more **parent** commit SHA(s) (zero for the initial commit)
- Author name, email, timestamp
- Committer name, email, timestamp
- Commit message

This forms a **Directed Acyclic Graph (DAG)** — the Git history.

### 2.4 Tag
An **annotated tag** is a Git object pointing to another object (usually a commit) with:
- Tagger identity and date
- A message
- An optional GPG signature

A **lightweight tag** is simply a named ref (a file in `.git/refs/tags/`) pointing to a commit SHA.

---

## 3. Three-Stage Workflow

```
Working Directory  →  Staging Area (Index)  →  Repository (.git)
     (edit)              (git add)                (git commit)
```

1. **Working Directory** — files you see and edit in your project folder.
2. **Staging Area (Index)** — a preparation zone. `git add` snapshots file content into the index.
3. **Repository** — permanent history. `git commit` writes the staged snapshot as a new commit object.

This three-stage model lets you craft precise commits: you can stage part of a file (`git add -p`),
leaving other changes for a later commit.

---

## 4. Core Commands

### 4.1 `git init`
Creates a new repository in the current directory by generating the `.git/` folder.
```bash
git init my-project
cd my-project
```

### 4.2 `git clone`
Copies a remote repository to your local machine, sets up `origin` remote automatically.
```bash
git clone https://github.com/user/repo.git
git clone git@github.com:user/repo.git   # SSH
```

### 4.3 `git add`
Moves changes from the working directory into the staging area.
```bash
git add file.py          # stage one file
git add .                # stage all changes
git add -p               # interactively stage hunks
```

### 4.4 `git commit`
Records staged changes as a new commit in the repository.
```bash
git commit -m "feat: add login endpoint"
git commit --amend       # rewrite the last commit (before pushing)
```

### 4.5 `git status`
Shows the state of the working directory and staging area.
```bash
git status
git status -s            # short/compact output
```

### 4.6 `git log`
Displays commit history.
```bash
git log --oneline --graph --all
git log --author="Alice" --since="2 weeks ago"
```

### 4.7 `git diff`
Shows differences between states.
```bash
git diff                 # working dir vs staging
git diff --staged        # staging vs last commit
git diff main..feature   # between branches
```

---

## 5. Branching & Merging

### 5.1 Creating & Switching Branches
```bash
git branch feature/login          # create
git switch feature/login          # switch (modern syntax)
git switch -c feature/login       # create + switch in one step
git checkout -b feature/login     # older equivalent
```

A branch is simply a **movable pointer** to a commit. `HEAD` is a special pointer to the
currently checked-out branch (or commit in detached HEAD state).

### 5.2 Merge Strategies

**Fast-Forward Merge** — when the target branch has no new commits since the feature branch diverged:
```
main:    A---B
feature:      C---D
# After: main: A---B---C---D  (no merge commit)
git merge feature/login
```

**3-Way Merge** — when both branches have diverged. Git finds the common ancestor and creates a merge commit:
```
main:    A---B---E
feature:  \--C---D
# After: A---B---E---M  (M is merge commit with two parents)
git merge --no-ff feature/login
```

**Rebase** — replays commits from one branch onto another, creating a linear history:
```bash
git switch feature/login
git rebase main
# Moves feature commits on top of current main tip
```
> ⚠️ Never rebase commits that have been pushed to a shared remote branch.

### 5.3 Conflict Resolution (Step by Step)

1. Attempt the merge: `git merge feature/login`
2. Git marks conflicting files with conflict markers.
3. Open the file — you'll see:
```
<<<<<<< HEAD
code from current branch
=======
code from incoming branch
>>>>>>> feature/login
```
4. Edit the file to the desired final state, removing all markers.
5. Stage the resolved file: `git add conflicted_file.py`
6. Complete the merge: `git commit` (Git pre-fills the merge commit message)

---

## 6. Working with Remotes

```bash
git remote add origin https://github.com/user/repo.git
git remote -v                    # list remotes with URLs
git fetch origin                 # download but don't merge
git pull origin main             # fetch + merge
git push origin feature/login    # push branch to remote
git push -u origin main          # push + set upstream tracking
```

### Tracking Branches
When you clone, Git creates **remote-tracking branches** (e.g., `origin/main`). These are
local read-only snapshots of what's on the remote. `git fetch` updates them; `git pull`
fetches and merges in one step.

---

## 7. Undoing Changes

```bash
# Discard working directory changes (not staged)
git restore file.py

# Unstage a file (keep working dir change)
git restore --staged file.py

# Move HEAD and branch pointer (reset)
git reset --soft HEAD~1    # undo commit; keep staged
git reset --mixed HEAD~1   # undo commit; unstage (default)
git reset --hard HEAD~1    # undo commit; discard all changes ⚠️

# Create a new commit that reverses a previous commit (safe for shared history)
git revert abc1234

# Stash uncommitted work temporarily
git stash push -m "WIP: login form"
git stash list
git stash pop              # re-apply and remove from stash
git stash apply stash@{1}  # apply without removing
```

---

## 8. Tags

```bash
# Lightweight tag (just a pointer)
git tag v1.0.0

# Annotated tag (full object with message)
git tag -a v1.0.0 -m "Release version 1.0.0"

# List tags
git tag --list

# Push tags to remote (not pushed automatically)
git push origin v1.0.0
git push origin --tags    # push all tags

# Delete a tag
git tag -d v1.0.0
git push origin --delete v1.0.0
```

---

## 9. GitHub Concepts

### Forks
A **fork** is a server-side clone of a repository under your account. Used in open-source
to contribute without write access to the original repo.

### Pull Requests (PRs)
A PR is a GitHub-hosted request to merge one branch into another. It provides:
- A diff view of all changes
- Inline code review comments
- CI/CD status checks
- Merge controls (squash, rebase, merge commit)

### Code Review
Reviewers can leave comments, request changes, or approve. Best practices:
- Keep PRs small and focused (< 400 lines)
- Link to the relevant issue
- Respond to all comments before merging

### Issues
GitHub Issues are used to track bugs, feature requests, and tasks. They support:
- Labels, milestones, assignees
- Closing keywords in commits (`Fixes #42`)
- Linking to PRs

### GitHub Actions
GitHub Actions is a CI/CD platform. Workflows are YAML files in `.github/workflows/`.
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - run: pip install -r requirements.txt && pytest
```

---

## 10. .gitignore — Python Project Template

```gitignore
# Byte-compiled / optimised
__pycache__/
*.py[cod]
*$py.class
*.pyc

# Virtual environments
.venv/
venv/
env/
ENV/

# Distribution / packaging
dist/
build/
*.egg-info/
*.egg

# Testing & coverage
.pytest_cache/
.coverage
htmlcov/
.tox/

# IDEs
.idea/
.vscode/
*.swp

# Jupyter Notebooks checkpoints
.ipynb_checkpoints/

# Environment variables
.env
.env.*
!.env.example

# OS artefacts
.DS_Store
Thumbs.db

# ML artefacts (large files)
*.h5
*.pkl
*.pt
*.pth
models/
data/raw/
```

---

## 11. Git Workflow Strategies

### GitFlow
Defines long-running branches: `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`.
- **main**: production-ready code, tagged with releases
- **develop**: integration branch for features
- Suited for scheduled release cycles

### Trunk-Based Development
All developers commit to `main` (trunk) frequently (at least daily). Feature flags hide
incomplete features in production. Suits CI/CD and high-velocity teams.

---

## 12. Git for ML: Data Version Control (DVC)

**DVC** (dvc.org) extends Git for machine learning projects by versioning large data files
and ML models that shouldn't live in Git objects:

```bash
pip install dvc
dvc init
dvc add data/train.csv        # creates data/train.csv.dvc (tracked by Git)
dvc remote add -d s3remote s3://mybucket/dvcstore
dvc push                      # push data to remote storage
dvc pull                      # fetch data from remote storage
```

DVC pipelines (`dvc.yaml`) version the full ML pipeline: data ingestion → preprocessing
→ training → evaluation. Each stage is reproducible and cached.

---

## 13. Commit Message Best Practices — Conventional Commits

Format: `<type>(<scope>): <short description>`

| Type     | When to use                                      |
|----------|--------------------------------------------------|
| feat     | A new feature                                    |
| fix      | A bug fix                                        |
| docs     | Documentation only                               |
| style    | Formatting, no logic change                      |
| refactor | Code restructure, no feature/bug change          |
| test     | Adding or updating tests                         |
| chore    | Build process, dependencies, tooling             |
| perf     | Performance improvement                          |
| ci       | CI/CD configuration changes                      |

**Full example:**
```
feat(auth): add JWT refresh token endpoint

Implements POST /auth/refresh that validates the refresh token stored
in an HTTP-only cookie and returns a new access token (15 min TTL).

Closes #87
```

Rules:
- Subject line ≤ 72 characters, imperative mood ("add" not "added")
- Blank line between subject and body
- Body explains **why**, not **what** (the diff shows what)
- Reference issues/PRs in the footer

---

## 14. Summary Cheat-Sheet

```
git init / clone          → start a repo
git add / commit          → record changes
git status / log / diff   → inspect state
git branch / switch       → manage branches
git merge / rebase        → integrate branches
git remote / fetch / pull / push → sync with remotes
git restore / reset / revert / stash → undo changes
git tag                   → mark releases
```