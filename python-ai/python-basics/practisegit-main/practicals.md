# Git & GitHub — Practical Exercises

> 10 hands-on exercises. Each builds real-world Git skills through simulated scenarios.
> Work through them in order; later exercises build on earlier ones.

---

## Exercise 1 — Bootstrap a Python Project with Git

**Objective:** Initialise a Git repository, make your first commits, and establish good hygiene.

**Scenario:** You are starting a new data-science project called `iris-classifier`.

**Steps:**
1. Create and enter the project folder:
   ```bash
   mkdir iris-classifier && cd iris-classifier
   ```
2. Initialise Git:
   ```bash
   git init
   ```
3. Create a `.gitignore` for Python:
   ```bash
   curl -s https://www.toptal.com/developers/gitignore/api/python > .gitignore
   # Or manually add: __pycache__/, .venv/, *.pyc, .env
   ```
4. Create a minimal `README.md` and `requirements.txt`.
5. Stage and commit both files:
   ```bash
   git add .
   git commit -m "chore: initial project scaffold"
   ```
6. Verify with `git log --oneline` and `git status`.

**Hints:**
- Always create `.gitignore` before your first `add` so no junk is tracked from the start.
- Use `git status -s` for a compact view.

**Expected Outcome:** One commit on `main`, clean working tree, `.gitignore` protecting Python artefacts.

---

## Exercise 2 — Feature Branch Workflow

**Objective:** Practice creating a branch, making commits, and merging back to `main`.

**Scenario:** Add a data-loading module to the iris-classifier project on a separate branch.

**Steps:**
1. Create and switch to a feature branch:
   ```bash
   git switch -c feature/data-loader
   ```
2. Create `data_loader.py` with a function that reads a CSV file using pandas.
3. Commit your work:
   ```bash
   git add data_loader.py
   git commit -m "feat(data): add CSV data loader"
   ```
4. Add a unit test file `test_data_loader.py` and commit it:
   ```bash
   git commit -m "test: add unit tests for data loader"
   ```
5. Switch back to `main` and merge with a merge commit:
   ```bash
   git switch main
   git merge --no-ff feature/data-loader -m "feat: merge data-loader feature"
   ```
6. View the graph: `git log --oneline --graph --all`

**Hints:**
- Use `git log --oneline feature/data-loader` to see branch commits before merging.
- `--no-ff` keeps a visible branch in history even if fast-forward is possible.

**Expected Outcome:** `main` has 3 commits (initial + 2 feature), visible merge node in graph.

---

## Exercise 3 — Staging Selected Hunks

**Objective:** Use `git add -p` to create atomic commits from a file with multiple changes.

**Scenario:** You edited `data_loader.py` in two unrelated ways simultaneously:
- Added error handling for missing files
- Reformatted a docstring

**Steps:**
1. Make both changes in `data_loader.py` in one editing session.
2. Run `git add -p data_loader.py`.
3. When prompted, press `y` to stage the error-handling hunk and `n` to skip the docstring hunk.
4. Commit the first change:
   ```bash
   git commit -m "fix: handle FileNotFoundError in data loader"
   ```
5. Stage and commit the remaining change:
   ```bash
   git add data_loader.py
   git commit -m "docs: reformat data loader docstring"
   ```

**Hints:**
- Press `?` at the hunk prompt to see all options.
- Press `s` to split a hunk into smaller sub-hunks if changes are adjacent.

**Expected Outcome:** Two clean, atomic commits with clearly separated concerns.

---

## Exercise 4 — Conflict Resolution

**Objective:** Experience and resolve a realistic merge conflict.

**Scenario:** Two developers both edited `config.py` on different branches.

**Steps:**
1. On `main`, create `config.py`:
   ```python
   DATABASE = "sqlite:///prod.db"
   DEBUG = False
   ```
   Commit: `git commit -am "chore: add config"`

2. Create branch A and change the DATABASE line:
   ```bash
   git switch -c branch-a
   # Edit: DATABASE = "postgresql://localhost/prod"
   git commit -am "fix(config): switch to postgres"
   ```

3. Switch to `main`, create branch B, change the same line:
   ```bash
   git switch main
   git switch -c branch-b
   # Edit: DATABASE = "sqlite:///dev.db"
   git commit -am "fix(config): use SQLite for dev"
   ```

4. Merge branch-a into main first (fast-forward or merge commit).
5. Now merge branch-b — this will conflict.
6. Open `config.py`, resolve the markers, keep `postgresql://localhost/prod`.
7. `git add config.py && git commit`.

**Hints:**
- `git diff` after step 5 shows both sides of the conflict.
- Use `git merge --abort` if you want to cancel and start over.

**Expected Outcome:** One resolved merge commit on `main` containing the correct database URL.

---

## Exercise 5 — Undo Mistakes (reset, revert, restore)

**Objective:** Practice the three main undo mechanisms in appropriate scenarios.

**Scenario:** Three mistakes to fix, each requiring a different tool.

**Steps:**

**Mistake A — Unstage a file:**
```bash
git add secrets.env          # oops!
git restore --staged secrets.env
```
Confirm with `git status` — file is back to untracked.

**Mistake B — Undo last local commit (not pushed):**
```bash
git commit -am "bad commit"
git reset --soft HEAD~1      # moves HEAD back, keeps staged changes
# OR: git reset --mixed HEAD~1  (unstages too)
```

**Mistake C — Revert a pushed commit:**
```bash
# Find the bad commit SHA
git log --oneline
git revert <sha>             # creates a new "undo" commit
git push
```

**Hints:**
- Use `--soft` when you want to recommit with corrections.
- Use `--hard` only when you are certain you want to discard changes permanently.
- Never `reset --hard` on commits already pushed to shared branches.

**Expected Outcome:** Understanding of when each undo command is appropriate.

---

## Exercise 6 — Stash and Context Switch

**Objective:** Use `git stash` to juggle multiple work streams.

**Scenario:** You're halfway through adding a new model when an urgent bug report arrives.

**Steps:**
1. Make partial changes to `model.py` (simulate mid-feature work).
2. Stash them with a descriptive message:
   ```bash
   git stash push -m "WIP: transformer model layer"
   ```
3. Verify your working tree is clean: `git status`
4. Switch to a hotfix branch and fix a typo in `README.md`:
   ```bash
   git switch -c hotfix/readme-typo
   # fix typo
   git commit -am "fix: correct README typo"
   git switch main
   git merge hotfix/readme-typo
   git branch -d hotfix/readme-typo
   ```
5. Return to your feature branch and restore stashed work:
   ```bash
   git switch feature/transformer   # or main if working from main
   git stash pop
   ```
6. List stashes: `git stash list` (should be empty after pop).

**Hints:**
- `git stash apply stash@{0}` applies without removing; `pop` applies and removes.
- Stashes are per-repository, not per-branch — you can pop onto any branch.

**Expected Outcome:** WIP changes restored, hotfix merged, stash list empty.

---

## Exercise 7 — Working with Remotes and GitHub

**Objective:** Push a local repository to GitHub, create a PR, and simulate a code review cycle.

**Scenario:** You want to share the iris-classifier project and collaborate via PRs.

**Steps:**
1. Create a new **empty** repository on GitHub (no README, no .gitignore).
2. Link your local repo:
   ```bash
   git remote add origin git@github.com:<username>/iris-classifier.git
   git push -u origin main
   ```
3. Create a feature branch locally:
   ```bash
   git switch -c feature/model-training
   # add model.py with a simple sklearn classifier
   git commit -am "feat: add logistic regression model"
   git push -u origin feature/model-training
   ```
4. On GitHub, open a Pull Request from `feature/model-training` → `main`.
   - Write a descriptive PR title and body.
   - Reference a hypothetical issue: "Closes #1"
5. In the PR, leave a review comment on a specific line.
6. Address the comment locally, push again:
   ```bash
   # make the requested change
   git add . && git commit -m "refactor: apply PR review feedback"
   git push
   ```
7. Merge the PR on GitHub (use "Squash and merge" or "Create merge commit").
8. Pull the merged changes locally:
   ```bash
   git switch main && git pull
   git branch -d feature/model-training
   git push origin --delete feature/model-training
   ```

**Expected Outcome:** A complete GitHub PR cycle: push → review → address → merge → clean up.

---

## Exercise 8 — Interactive Rebase to Clean Up History

**Objective:** Use `git rebase -i` to squash, reorder, and reword commits before a PR.

**Scenario:** You made 5 messy commits on a feature branch and want a clean, single commit.

**Steps:**
1. Simulate 5 commits on `feature/cleanup`:
   ```bash
   git switch -c feature/cleanup
   for i in 1 2 3 4 5; do echo "change $i" >> notes.txt; git add notes.txt; git commit -m "WIP $i"; done
   ```
2. Squash all 5 into one:
   ```bash
   git rebase -i HEAD~5
   ```
3. In the interactive editor, keep the first as `pick` and change the rest to `squash`:
   ```
   pick  abc1 WIP 1
   squash def2 WIP 2
   squash ghi3 WIP 3
   squash jkl4 WIP 4
   squash mno5 WIP 5
   ```
4. Save; Git opens a second editor for the combined commit message. Write:
   ```
   feat(notes): add project notes file

   Consolidated 5 WIP commits into a single clean commit.
   ```
5. Verify: `git log --oneline` should show only one new commit.

**Hints:**
- `git rebase -i HEAD~5` opens the last 5 commits in your `$EDITOR`.
- If something goes wrong: `git rebase --abort` returns to the pre-rebase state.

**Expected Outcome:** Five WIP commits replaced by one well-formatted commit.

---

## Exercise 9 — Tags and Releases

**Objective:** Tag a release, push it to GitHub, and create a GitHub Release.

**Scenario:** iris-classifier v1.0.0 is production-ready.

**Steps:**
1. Ensure `main` is up to date with all features merged.
2. Create an annotated tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0: initial iris classifier with logistic regression"
   ```
3. List tags: `git tag --list`
4. Inspect the tag object:
   ```bash
   git show v1.0.0
   ```
5. Push the tag to GitHub:
   ```bash
   git push origin v1.0.0
   ```
6. On GitHub, go to **Tags** → click `v1.0.0` → **Create release**.
   - Add release notes describing new features, fixes, and known issues.
7. Tag a pre-release for the next version:
   ```bash
   git tag -a v1.1.0-beta.1 -m "Beta: add SVM model"
   git push origin v1.1.0-beta.1
   ```

**Hints:**
- Annotated tags (`-a`) appear on GitHub Releases; lightweight tags do not show metadata.
- Use semantic versioning: `MAJOR.MINOR.PATCH` (https://semver.org).

**Expected Outcome:** A tagged release visible on GitHub with a changelog-style description.

---

## Exercise 10 — Set Up a GitHub Actions CI Pipeline

**Objective:** Automate testing on every push and PR using GitHub Actions.

**Scenario:** Add a CI workflow to automatically run pytest for iris-classifier.

**Steps:**
1. Create the workflow directory and file:
   ```bash
   mkdir -p .github/workflows
   ```
2. Create `.github/workflows/ci.yml`:
   ```yaml
   name: Python CI
   on:
     push:
       branches: [main, "feature/**"]
     pull_request:
       branches: [main]
   jobs:
     test:
       runs-on: ubuntu-latest
       strategy:
         matrix:
           python-version: ["3.10", "3.11", "3.12"]
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-python@v5
           with:
             python-version: ${{ matrix.python-version }}
         - name: Install dependencies
           run: |
             pip install --upgrade pip
             pip install -r requirements.txt
         - name: Run tests
           run: pytest --tb=short -q
   ```
3. Commit and push:
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "ci: add GitHub Actions Python test workflow"
   git push
   ```
4. On GitHub, click the **Actions** tab. Watch the workflow run on 3 Python versions.
5. Introduce a deliberate test failure (break an assertion), push to a new branch, open a PR.
   Observe the red ❌ on the PR — the CI blocks the merge.
6. Fix the test, push again → green ✅.

**Hints:**
- `matrix.python-version` runs the job in parallel for each Python version.
- Failed steps show the full log under the **Actions** tab for debugging.
- Add `--cov=.` to the pytest command to generate coverage reports.

**Expected Outcome:** Automated CI running on all pushes; PRs blocked by failing tests; green on fix.

---

## Summary of Skills Practised

| Exercise | Primary Skill                              |
|----------|--------------------------------------------|
| 1        | Init, add, commit, .gitignore              |
| 2        | Feature branches, merge --no-ff            |
| 3        | Atomic commits with git add -p             |
| 4        | Conflict detection and resolution          |
| 5        | restore, reset, revert                     |
| 6        | git stash (push, pop, apply)               |
| 7        | Remotes, push, PR, code review, clean up   |
| 8        | Interactive rebase, squash                 |
| 9        | Annotated tags, GitHub Releases            |
| 10       | GitHub Actions CI, matrix builds           |