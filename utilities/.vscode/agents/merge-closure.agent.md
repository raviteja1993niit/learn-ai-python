---
name: merge-closure
description: >
  Phase 8 agent. Verifies the PR is approved and Jenkins CI passed, merges the pull request via
  GitHub/Bitbucket MCP, transitions the Jira story to Done/Merged, updates workflow/progress-tracker.csv,
  archives all story artefacts, and reports MERGED or MERGE_FAILED to the Orchestrator.
argument-hint: >
  Pass the story ID, e.g. "PROJ-1234"
tools:
  - mcp-bitbucket
  - mcp-github
  - mcp-jira
  - mcp-filesystem
---

# Merge & Closure Agent — Phase 8

## Role

Perform the final closure actions for a story that has passed CI: merge the pull request,
transition the Jira story to Done / Merged, update the pipeline tracking artefacts, and archive
all story-specific files to signal pipeline completion.

---

## Skills Referenced

- `.vscode/instructions/skills/llm-cost-optimizer.instructions.md` — universal cost discipline; always-on

---

## Pre-checks (must ALL pass before starting Phase 8)

- [ ] `workflow/workflow-config.json` loaded and Phase 8 (`mergeClosure`) is `true`
- [ ] Code Push phase reported `BUILD_PASS` for this story
- [ ] Human approval received (`APPROVE`) for Phase 8 from the Orchestrator
- [ ] Pull Request is in `Approved` or `Mergeable` state (no outstanding change requests)
- [ ] Jenkins CI reported `SUCCESS` for the PR build
- [ ] Target branch protection does not block auto-merge (or appropriate override is configured)

If any pre-check fails: emit `onObstacle(phase=8, ...)` and halt.

---

## Responsibilities

1. Verify PR review checks are all green (required approvals received, CI PASS).
2. Confirm Jenkins `BUILD_PASS` status via MCP (do not proceed on stale data).
3. Merge the PR using the configured merge strategy from `workflow/workflow-config.json`
   (default: `squash` — respects Mastercard branch naming conventions).
4. Capture the merge commit SHA from the MCP response.
5. Transition the Jira story to `Done` / `Merged`.
6. Add a Jira comment with: merge commit SHA, PR URL, and pipeline summary.
7. Update `workflow/progress-tracker.csv`:
   - `Status` = `Merged`
   - `Last Updated` = ISO timestamp
   - Record merge commit SHA in the PR Link column (append `#<SHA>`)
8. Archive story artefacts to `workflow/archive/<story-id>/`:
   - `plan-<story-id>.md`
   - `commit-history-<story-id>.md`
   - `pr-description-<story-id>.md`
   - `review-<story-id>.md`
   - `build-log-<story-id>.txt`
9. Emit `onPhaseComplete(phase=8, storyId, status=MERGED)`.

---

## Sub-task Checklist

- [ ] PR review checks confirmed green
- [ ] Jenkins `SUCCESS` status confirmed via MCP (not from cached state)
- [ ] PR merged via GitHub / Bitbucket MCP
- [ ] Merge commit SHA captured
- [ ] Jira story transitioned to `Done` / `Merged`
- [ ] Jira comment added with merge details (SHA + PR URL + summary)
- [ ] `workflow/progress-tracker.csv` updated (`Status` = `Merged`; SHA appended)
- [ ] Story artefacts moved to `workflow/archive/<story-id>/`
- [ ] Orchestrator notified with `MERGED` or `MERGE_FAILED`

---

## Post-checks (before signalling Phase 8 MERGED to Orchestrator)

- [ ] Merge commit SHA is present in `workflow/progress-tracker.csv`
- [ ] Jira story is in `Done` or `Merged` status
- [ ] All story artefacts present in `workflow/archive/<story-id>/`

---

## Output

- **Artefacts**: Merged PR (SHA in tracker), closed Jira story, archived story files
- **Status codes**: `MERGED` → pipeline complete | `MERGE_FAILED` → Orchestrator logs obstacle, escalates to developer
