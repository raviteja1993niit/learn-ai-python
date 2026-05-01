# Git & GitHub — Command Examples

> 20+ annotated, real-world examples covering everyday Git workflows.

---

## Example 1 — Initialise a New Project

**Context:** You are starting a brand-new Python project from scratch.

```bash
mkdir my-ml-project
cd my-ml-project
git init
```

**Expected output:**
```
Initialized empty Git repository in /home/alice/my-ml-project/.git/
```

**What happened:** Git created the hidden `.git/` directory that stores all version control
data — objects, refs, config, and hooks. No commits exist yet.

---

## Example 2 — First Commit

**Context:** You have created `README.md` and want to record it permanently.

```bash
echo "# My ML Project" > README.md
git add README.md
git commit -m "docs: add initial README"
```

**Expected output:**
```
[main (root-commit) 3a1b2c4] docs: add initial README
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
```

**Tip:** The hash `3a1b2c4` is the first 7 characters of the commit SHA.

---

## Example 3 — Check Repository Status

**Context:** You edited two files and want to know what Git sees before staging.

```bash
git status
```

**Expected output:**
```
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
        modified:   train.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        data/features.csv
```

**Tip:** `git status -s` gives a compact two-column summary:
```
 M train.py        # modified (not staged)
?? data/features.csv
```

---

## Example 4 — View Commit History

**Context:** You want a visual graph of all branches and their commits.

```bash
git log --oneline --graph --all --decorate
```

**Expected output:**
```
* 9f1e2a3 (HEAD -> main) feat: add data pipeline
* 7c3d4b5 fix: handle missing values in CSV loader
* 3a1b2c4 docs: add initial README
```

**Tip:** Add `--author="Alice"` to filter by contributor.

---

## Example 5 — Stage Only Part of a File

**Context:** `model.py` has two independent changes; you want to commit them separately.

```bash
git add -p model.py
```

Git presents each hunk interactively:
```
@@ -10,6 +10,7 @@ class Model:
+    def predict(self, X):
...
Stage this hunk [y,n,q,a,d,/,e,?]?
```

Type `y` to stage a hunk, `n` to skip it. Enables atomic, focused commits.

---

## Example 6 — Compare Changes

**Context:** You want to see what changed before committing.

```bash
# Working directory vs staging area
git diff model.py

# Staging area vs last commit
git diff --staged

# Two branches
git diff main..feature/dropout
```

**Expected output (excerpt):**
```
-    learning_rate = 0.01
+    learning_rate = 0.001
```

---

## Example 7 — Create and Switch to a Feature Branch

**Context:** Starting work on a new login feature without affecting `main`.

```bash
git switch -c feature/user-auth
```

**Expected output:**
```
Switched to a new branch 'feature/user-auth'
```

Verify:
```bash
git branch
# * feature/user-auth
#   main
```

---

## Example 8 — Merge a Feature Branch (No-FF)

**Context:** Feature is complete; merge into `main` while preserving branch history.

```bash
git switch main
git merge --no-ff feature/user-auth -m "feat: merge user-auth feature"
```

**Expected output:**
```
Merge made by the 'ort' strategy.
 auth.py | 45 ++++++++++++
 1 file changed, 45 insertions(+)
```

`--no-ff` forces a merge commit even if a fast-forward is possible.

---

## Example 9 — Rebase a Feature Branch

**Context:** `main` has progressed; you want a clean, linear history before merging.

```bash
git switch feature/user-auth
git rebase main
```

**Expected output:**
```
Successfully rebased and updated refs/heads/feature/user-auth.
```

Each feature commit is replayed on top of the latest `main` commit.

---

## Example 10 — Resolve a Merge Conflict

**Context:** Both `main` and `feature/user-auth` modified `config.py`.

```bash
git switch main
git merge feature/user-auth
# CONFLICT (content): Merge conflict in config.py
```

Open `config.py`:
```python
<<<<<<< HEAD
DATABASE_URL = "postgresql://localhost/prod"
=======
DATABASE_URL = "sqlite:///dev.db"
>>>>>>> feature/user-auth
```

Edit to keep the correct version, then:
```bash
git add config.py
git commit
# Merge branch 'feature/user-auth' into main
```

---

## Example 11 — Clone and Push to Remote

**Context:** You created a repo on GitHub and want to link your local project.

```bash
git remote add origin git@github.com:alice/my-ml-project.git
git push -u origin main
```

**Expected output:**
```
Enumerating objects: 5, done.
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

`-u` sets the upstream so future `git push` / `git pull` need no arguments.

---

## Example 12 — Fetch vs Pull

**Context:** A teammate pushed changes; you want to inspect before merging.

```bash
git fetch origin           # download, don't merge
git log origin/main --oneline  # inspect what arrived
git merge origin/main      # merge when ready
```

vs.

```bash
git pull origin main       # fetch + merge in one step
```

**Best practice:** Use `fetch` + inspect + `merge` when working on shared branches.

---

## Example 13 — Undo a Staged File

**Context:** You accidentally staged `secrets.env`.

```bash
git restore --staged secrets.env
```

The file returns to the working directory (modified, not staged). Add it to `.gitignore`
immediately to prevent future accidents.

---

## Example 14 — Amend the Last Commit

**Context:** You forgot to include `utils.py` in the last commit (not yet pushed).

```bash
git add utils.py
git commit --amend --no-edit
```

`--no-edit` keeps the existing commit message. The commit SHA changes — never amend
pushed commits on shared branches.

---

## Example 15 — Interactive Rebase (Squash Commits)

**Context:** You made 5 messy "WIP" commits on a feature branch; squash them before PR.

```bash
git rebase -i HEAD~5
```

In the editor, change `pick` to `squash` (or `s`) for commits 2-5:
```
pick  abc1234 feat: start auth module
squash def5678 WIP: add token logic
squash 789abcd WIP: fix typo
squash ...
```

Save → Git combines them into one commit with a combined message you edit.

---

## Example 16 — Stash Work in Progress

**Context:** An urgent bug appears; you need to switch branches but have uncommitted work.

```bash
git stash push -m "WIP: preprocessing pipeline"
git switch hotfix/critical-bug
# ... fix the bug, commit, push ...
git switch feature/preprocessing
git stash pop
```

**Expected output after pop:**
```
On branch feature/preprocessing
Changes not staged for commit:
        modified:   preprocess.py
Dropped refs/stash@{0}
```

---

## Example 17 — Revert a Bad Commit (Safe for Shared Branches)

**Context:** Commit `bcd9876` introduced a regression in production.

```bash
git revert bcd9876
```

Git creates a **new commit** that undoes the changes of `bcd9876`. History is preserved —
safe to push to shared branches without force-pushing.

---

## Example 18 — Create an Annotated Tag for a Release

**Context:** You are releasing version 2.0.0.

```bash
git tag -a v2.0.0 -m "Release v2.0.0: add transformer model support"
git push origin v2.0.0
```

**Verify:**
```bash
git show v2.0.0
# tag v2.0.0
# Tagger: Alice <alice@example.com>
# Date:   Mon Jan 15 10:30:00 2024
# Release v2.0.0: add transformer model support
```

---

## Example 19 — Use .gitignore to Exclude Files

**Context:** You want to prevent committing large model files and virtual environments.

```bash
cat >> .gitignore << 'EOF'
.venv/
__pycache__/
*.pkl
*.h5
data/raw/
.env
EOF

git add .gitignore
git commit -m "chore: update gitignore for ML artefacts"
```

Check what's now ignored:
```bash
git status --ignored
```

---

## Example 20 — View a Specific Commit's Changes

**Context:** You want to inspect exactly what changed in commit `abc1234`.

```bash
git show abc1234
```

**Expected output:**
```
commit abc1234...
Author: Alice <alice@example.com>
Date:   Tue Jan 16 09:00:00 2024

    fix: correct learning rate decay formula

diff --git a/train.py b/train.py
-    lr = base_lr / step
+    lr = base_lr / math.sqrt(step)
```

---

## Example 21 — Search Commit Messages

**Context:** You need to find when a specific feature was introduced.

```bash
git log --all --grep="dropout"
```

Or search for code changes that added/removed a string:
```bash
git log -S "dropout_rate" --oneline
```

---

## Example 22 — Delete a Remote Branch After PR Merge

**Context:** The feature branch was merged via PR on GitHub; clean up locally and remotely.

```bash
# Delete remote branch
git push origin --delete feature/user-auth

# Delete local branch
git branch -d feature/user-auth

# Prune stale remote-tracking references
git fetch --prune
```

---

## Example 23 — Cherry-Pick a Single Commit

**Context:** A bug fix on `develop` needs to be applied to `main` immediately.

```bash
git switch main
git cherry-pick abc1234
```

This copies commit `abc1234` (with a new SHA) onto `main`. Useful for hotfixes.

---

## Example 24 — Set Up a GitHub Actions Workflow

**Context:** Auto-run tests on every push and PR.

```bash
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: Python CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install -r requirements.txt
      - run: pytest --tb=short
EOF

git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions Python test workflow"
git push
```

After pushing, check the **Actions** tab on GitHub to see the workflow running.

---

## Quick Reference

| Goal                          | Command                              |
|-------------------------------|--------------------------------------|
| Stage all changes             | `git add .`                          |
| Discard working dir changes   | `git restore <file>`                 |
| View unstaged changes         | `git diff`                           |
| View staged changes           | `git diff --staged`                  |
| Undo last commit (keep files) | `git reset --soft HEAD~1`            |
| List all branches             | `git branch -a`                      |
| Delete local branch           | `git branch -d <branch>`             |
| Show remote URLs              | `git remote -v`                      |
| Tag current commit            | `git tag -a v1.0 -m "msg"`           |
| Push all tags                 | `git push origin --tags`             |