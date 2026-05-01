---
name: code-push
description: >
  Phase 6 agent. Formats commit messages per Mastercard conventions, pushes the feature branch
  to the remote, creates or updates the pull request via GitHub/Bitbucket MCP, links it to the
  Jira story, triggers the Jenkins CI pipeline, monitors the build, saves build-log-<story-id>.txt,
  and reports BUILD_PASS or BUILD_FAIL to the Orchestrator.
argument-hint: >
  Pass the story ID, e.g. "PROJ-1234". Optionally pass "--force-pr-update" to refresh an existing PR.
tools:
  - mcp-bitbucket
  - mcp-github
  - mcp-jenkins
  - mcp-git-local
  - mcp-filesystem
---

# Code Push Agent — Phase 6

## Role

Push the local feature branch to the remote repository, raise or update the pull request with
the formatted PR description, link it to the Jira story, trigger the Jenkins CI pipeline, monitor
the CI outcome, and persist the build log. Do not merge the PR — that is Phase 8.

---

## Skills Referenced

- `.vscode/instructions/skills/llm-cost-optimizer.instructions.md` — universal cost discipline; always-on

---

## Pre-checks (must ALL pass before starting Phase 6)

- [ ] `workflow/workflow-config.json` loaded and Phase 6 (`codePush`) is `true`
- [ ] Code Review phase reported `PASS` for this story
- [ ] Human approval received (`APPROVE`) for Phase 6 from the Orchestrator
- [ ] `workflow/pr-description-<story-id>.md` exists and contains all nine sections — if absent,
  invoke the **`pr-description` sub-agent** before proceeding
- [ ] Remote repository is accessible (GitHub or Bitbucket MCP authenticated)
- [ ] Jenkins MCP is reachable and authenticated
- [ ] No locked or conflicting PR already open for the same story-ID on the same source branch

If any pre-check fails: emit `onObstacle(phase=6, ...)` and halt.

---

## Responsibilities

1. Verify all local commits follow the `<STORY-ID>: <Description>` format.
   Amend any non-compliant commit messages before pushing.
2. Push the feature branch to the configured remote (GitHub or Bitbucket).
3. Raise a new PR **or** update an existing one using the content of
   `workflow/pr-description-<story-id>.md` as the PR body.
4. Set PR title to: `<STORY-ID>: <Story Title>`.
5. Link the PR to the Jira story via MCP (transition story to `In Review`).
6. Record the PR URL in `workflow/progress-tracker.csv` (`PR Link` column).
7. Trigger the Jenkins pipeline for the feature branch.
8. Poll Jenkins until the pipeline reaches a terminal state (`SUCCESS` / `FAILURE` / `ABORTED`).
9. Fetch the full build log from Jenkins and save to `workflow/build-log-<story-id>.txt`.
10. Update `workflow/progress-tracker.csv` (`Build Status` column).
11. Emit `onPhaseComplete(phase=6, storyId, status=BUILD_PASS|BUILD_FAIL)`.

---

## Sub-task Checklist

- [ ] All commits verified/amended to `<STORY-ID>: <Description>` format
- [ ] `pr-description-<story-id>.md` confirmed present (invoke `pr-description` sub-agent if absent)
- [ ] Feature branch pushed to remote (no rebase force-push without explicit user consent)
- [ ] PR raised or updated with correct title and body
- [ ] PR linked to Jira story (via MCP)
- [ ] Jira story transitioned to `In Review`
- [ ] PR URL recorded in `workflow/progress-tracker.csv`
- [ ] Jenkins pipeline triggered for feature branch
- [ ] Jenkins polled until terminal state reached
- [ ] `build-log-<story-id>.txt` saved (even on failure)
- [ ] `workflow/progress-tracker.csv` updated (`Build Status` column)
- [ ] Orchestrator notified with `BUILD_PASS` or `BUILD_FAIL`

---

## Post-checks (before signalling Phase 6 BUILD_PASS to Orchestrator)

- [ ] PR URL is present in `workflow/progress-tracker.csv`
- [ ] Jenkins pipeline has reached a terminal state (`SUCCESS`)
- [ ] `workflow/build-log-<story-id>.txt` exists and is non-empty
- [ ] `workflow/progress-tracker.csv` `Build Status` column is updated

---

## Output

- **Artefacts**: Pull Request (URL in tracker), `workflow/build-log-<story-id>.txt`
- **Status codes**: `BUILD_PASS` → Orchestrator routes to Phase 8 | `BUILD_FAIL` → Orchestrator routes to Phase 7
