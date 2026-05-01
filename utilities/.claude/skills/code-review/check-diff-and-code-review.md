# How to check local changes and perform a code review

This short guide explains how to inspect local code changes and conduct a simple, effective code review.

1. Ensure you're on the right branch

- Confirm your current branch and workspace state.

```powershell
# show current branch and status
git branch --show-current
git status --short
```

2. See unstaged changes (working tree)

- Use git diff to review un-staged edits file-by-file.

```powershell
# show differences between working tree and index
git diff
```

3. Stage and review staged changes

- Stage individual files or hunks, then inspect staged diffs.

```powershell
# stage a file
git add path\to\file.java

# stage interactively (hunks)
git add -p

# view staged diffs
git diff --staged
```

4. Compare against the base branch (e.g., origin/main)

- See what will change relative to the target branch used for the PR.

```powershell
# fetch latest remote refs
git fetch origin

# compare your branch to origin/main
git diff origin/main...HEAD
```

5. Create a focused commit and push to a topic branch

- Keep commits small and atomic; use a proper ticket-id in the message.

```powershell
# create a topic branch
git switch -c feature/G1198-XXXXX_my-change

# commit
git commit -m "G1198-XXXXX: Short imperative message"

# push
git push -u origin feature/G1198-XXXXX_my-change
```

6. Prepare the Pull Request and run local checks

- Run unit tests, linters, and any static analysis locally before opening a PR.

```powershell
# typical maven commands (example project)
mvn -q -DskipTests=false test
mvn -q checkstyle:check
```

7. Do the code review (checklist)

- High level: Does the change implement the ticket and satisfy acceptance criteria?
- Design: SRP, SOLID principles, clear abstractions, no premature optimisation.
- Tests: Are there unit tests and edge-case tests? Are they meaningful and passing?
- Quality: Formatting, naming, Javadoc/comments for public APIs, and no TODOs without ticket refs.
- Security: No secrets or PII leaked; inputs validated; sensitive data masked in logs.
- Performance: Avoid expensive allocations; acceptable for hot paths.
- Dependencies: No unnecessary new libraries.
- Backwards compatibility: No breaking contract changes unless documented.
- CI: Check the PR CI runs and green status.

8. File-by-file review steps

- Open the diff in your IDE or on the PR page.
- Review changed files in logical order (public API, then internal changes, then tests).
- For complex diffs, use "view file" and the split/side-by-side diff to follow context.
- Leave targeted, constructive comments referencing specific lines.

9. Use interactive tools when needed

- Use `git log -p`, `git show <commit>` or IDE diff tools to inspect historical context.

```powershell
# show patch for last commit
git show --stat --patch HEAD

# view commits vs origin/main
git log --oneline --graph --decorate origin/main..HEAD
```

10. Finalise the review

- Request changes or approve the PR with clear rationale.
- If approving, ensure the PR description is complete and the commit history is tidy (squash/fixup if required by team policy).
- After merge, pull or rebase your local main and clean up the topic branch.

```powershell
# update local main
git checkout main
git pull origin main

# delete local topic branch
git branch -d feature/G1198-XXXXX_my-change
```

Notes

- Keep comments constructive and focused on code behaviour, readability, and maintainability.
- Use the project's coding standards and ticket IDs in commit messages.
- Replace example commands and branch names with the project's conventions.

--
Skill file: quick reference for checking local diffs and running a basic code review.
