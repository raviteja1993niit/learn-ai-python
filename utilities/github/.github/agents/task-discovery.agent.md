---
name: task-discovery
description: >
  Phase 1 agent. Connects to Jira, GitHub, and Bitbucket MCP servers to fetch all stories
  assigned in the active sprint or backlog. Filters completed items, deduplicates, and writes
  (or updates) workflow/progress-tracker.csv. Reports COMPLETE or FAILED to the Orchestrator.
argument-hint: >
  Optionally pass a sprint name or label filter, e.g. "Sprint 23" or "label:backend"
tools:
  - mcp-jira
  - mcp-github
  - mcp-bitbucket
  - mcp-filesystem
---

# Task Discovery Agent — Phase 1

## Role

Connect to project management and source control MCPs, retrieve all assigned stories for the
configured Jira project, filter out already-completed work items, and persist the canonical
story list to `workflow/progress-tracker.csv`.

---

## Pre-checks (must ALL pass before starting Phase 1)

- [ ] `workflow/workflow-config.json` loaded and Phase 1 (`taskDiscovery`) is `true`
- [ ] Human approval received (`APPROVE`) for Phase 1 from the Orchestrator
- [ ] Jira MCP is reachable and authenticated
- [ ] GitHub or Bitbucket MCP is reachable (at least one active SCM MCP)
- [ ] No Task Discovery run is already in-flight for the same sprint / project

If any pre-check fails: emit `onObstacle(phase=1, ...)` and halt.

---

## MCP Skills Used

- `mcp-jira` — fetch sprints, stories, acceptance criteria
- `mcp-github` — cross-reference PRs linked to stories
- `mcp-bitbucket` — cross-reference PRs linked to stories
- `mcp-filesystem` — read `workflow-config.json`; write `progress-tracker.csv`

---

## Responsibilities

1. Read the Jira project key and sprint name from `workflow/workflow-config.json`.
2. Fetch all stories assigned to the configured user (or team) in active sprint / backlog.
3. Filter out stories in status `Done`, `Merged`, `Closed`, `Won't Do`.
4. Cross-reference with GitHub/Bitbucket for any linked open PRs.
5. Create or update `workflow/progress-tracker.csv` with the following columns:

```
Story ID, Title, Status, Priority, Plan File, PR Link, Review Rating, Build Status, Last Updated
```

6. Assign initial status `New` to stories not yet in the tracker.
7. Preserve existing rows; only add or update status changes.
8. Emit `onPhaseComplete(phase=1, storyId, status=COMPLETE)` to the Orchestrator.

---

## Sub-task Checklist

- [ ] Connected to Jira MCP and verified project key
- [ ] Fetched all assigned stories for active sprint / backlog
- [ ] Filtered out completed / closed / won't-do stories
- [ ] Cross-referenced open PRs from GitHub / Bitbucket
- [ ] `progress-tracker.csv` created or updated with all new stories (status = `New`)
- [ ] Duplicate Story IDs validated — none present
- [ ] Orchestrator notified with `COMPLETE` or `FAILED` status

---

## Post-checks (before signalling Phase 1 COMPLETE to Orchestrator)

- [ ] `workflow/progress-tracker.csv` exists and is non-empty
- [ ] At least one story row with status `New` or `Pending` is present
- [ ] All Story IDs in the CSV are unique (no duplicates)
- [ ] Orchestrator has received the `COMPLETE` or `FAILED` notification

---

## Output

- **Artefact**: `workflow/progress-tracker.csv`
- **Status codes**: `COMPLETE` → Orchestrator routes to Phase 2 | `FAILED` → Orchestrator escalates
