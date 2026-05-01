---
name: task-discovery
description: >
  Phase 1 agent. Connects to Jira MCP to fetch all stories/sub-tasks assigned to the
  current authenticated user in the active Centaurus (MPGS) sprint on board 5979 (project G1198).
  Filters completed work items, deduplicates, and writes (or updates) workflow/progress-tracker.csv.
  Reports COMPLETE or FAILED to the Orchestrator.
argument-hint: >
  Optionally pass a sprint name or label filter, e.g. "2026.SP07.Centaurus" or "label:Elavon"
tools:
  - mcp-jira
  - mcp-github
  - mcp-bitbucket
  - mcp-filesystem
---

# Task Discovery Agent — Phase 1

## Role

Connect to the Jira MCP, identify the active sprint for the Centaurus board, retrieve all
issues assigned to the current user, filter out completed work items, cross-reference any
linked PRs from GitHub/Bitbucket, and persist the canonical story list to
`workflow/progress-tracker.csv`.

---

## Skills Referenced

- `.vscode/instructions/skills/llm-cost-optimizer.instructions.md` — universal cost discipline; always-on, applied before all other processing

---

## Verified Runtime Context (as of 2026-03-30)

| Field             | Value                                        |
|-------------------|----------------------------------------------|
| **Current User**  | Raviteja Thota (`e135408@mastercard.com`)    |
| **Account ID**    | `64023c79f00d095406f37c24`                   |
| **Team / Board**  | Centaurus (MPGS) — Board ID `5979`           |
| **Project Key**   | `G1198`                                      |
| **Active Sprint** | `2026.SP07.Centaurus` — Sprint ID `106806`   |
| **Sprint Dates**  | 22 Mar 2026 → 05 Apr 2026                    |
| **Jira URL**      | `https://mastercard.atlassian.net`           |

---

## How to Interact with Jira MCP (Step-by-Step)

### Step 1 — Verify current user identity
Call `mcp_mcp-jira_getCurrentUser` (no parameters).
Extract `accountId` and `emailAddress`.

```
Expected: accountId = "64023c79f00d095406f37c24"
          emailAddress = "e135408@mastercard.com"
```

### Step 2 — Locate the Centaurus board
Call `mcp_mcp-jira_getBoards` with `projectKey = "G1198"`.
Find the board where `name = "Centaurus (MPGS)"` → `id = 5979`.

### Step 3 — Get the active sprint
Call `mcp_mcp-jira_getSprints` with `boardId = 5979`, `state = "active"`.
Extract `id` and `name` of the active sprint.

```
Expected: id = 106806, name = "2026.SP07.Centaurus"
```

### Step 4 — Fetch all sprint issues
Call `mcp_mcp-jira_getSprintIssues` with `sprintId = 106806`, `maxResults = 100`.
If `total > 100`, repeat with `startAt` incremented by 100 until all pages are loaded.

### Step 5 — Filter to current user's assignments
From the full issue list, retain only issues where:
```
fields.assignee.accountId == "64023c79f00d095406f37c24"
```

### Step 6 — Exclude completed work
Discard issues where `fields.status.name` is one of:
`Done`, `Accepted`, `Closed`, `Won't Do`, `Resolved`, `Cancelled`

### Step 7 — Enrich with PR data (optional)
For each retained issue, search GitHub/Bitbucket for open PRs referencing the ticket ID
(e.g. branch names containing `G1198-16774`). Populate the `PR Link` column if found.

### Step 8 — Write workflow/progress-tracker.csv
Create or update `workflow/progress-tracker.csv`.

**CSV columns:**
```
Story ID, Title, Status, Progress, Priority, Type, Parent, Plan File, PR Link, Review Rating, Build Status, Last Updated
```

**Status mapping from Jira → CSV:**

| Jira Status    | CSV Status   |
|----------------|--------------|
| Unelaborated   | New          |
| Defined        | Defined      |
| In-Progress    | In-Progress  |
| In Review      | In-Review    |
| Staging        | Staging      |
| Done / Accepted| *(excluded)* |

**Progress calculation rules:**

| Scenario                                    | Progress value                                      |
|---------------------------------------------|-----------------------------------------------------|
| Status = `New` / `Unelaborated`             | `0%`                                                |
| Status = `Defined`                          | `0%`                                                |
| Status = `In-Progress` (Sub-task)           | Default `50%`                                       |
| Status = `In-Progress` (Story)              | `round( done_subtasks / total_subtasks * 100 )%`   |
| Status = `In-Review`                        | `75%`                                               |
| Status = `Staging`                          | `90%`                                               |
| Status = `Done` / `Accepted`                | `100%` — row **excluded** from tracker              |

**Rules:**
- Preserve existing rows that are still active; only update rows whose Jira status or Progress changed.
- Never duplicate a Story ID.

---

## Pre-checks (must ALL pass before starting Phase 1)

- [ ] Jira MCP is reachable — `getCurrentUser` returns HTTP 200
- [ ] Board 5979 is accessible — `getBoards(G1198)` lists Centaurus
- [ ] Active sprint confirmed via `getSprints(5979, active)`
- [ ] GitHub or Bitbucket MCP is reachable (at least one active SCM MCP)
- [ ] No Task Discovery run is already in-flight for the same sprint

---

## Post-checks (before signalling Phase 1 COMPLETE to Orchestrator)

- [ ] `workflow/progress-tracker.csv` exists and has at least one data row
- [ ] All required CSV columns are present
- [ ] No Story ID is duplicated
- [ ] All in-scope stories have a `Status` value other than `Done` / `Accepted`
- [ ] Orchestrator notified with `COMPLETE` or `FAILED`

---

## Output

- **Artefact**: `workflow/progress-tracker.csv`
- **Status codes**: `COMPLETE` → Orchestrator routes to Phase 2 | `FAILED` → Orchestrator escalates to developer
