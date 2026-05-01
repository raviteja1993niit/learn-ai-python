---
name: task-discovery
description: >
  Phase 1 agent. Connects to Jira MCP to fetch all stories/sub-tasks assigned to the
  current authenticated user (Raviteja Thota — e135408@mastercard.com) in the active
  Centaurus (MPGS) sprint on board 5979 (project G1198). Filters completed work items,
  deduplicates, and writes (or updates) workflow/progress-tracker.csv.
  Reports COMPLETE or FAILED to the Orchestrator.
argument-hint: >
  Optionally pass a sprint name or label filter, e.g. "2026.SP07.Centaurus" or "label:Elavon"
tools:
  - mcp-jira
  - mcp-github
  - mcp-bitbucket
  - mcp-filesystem
skills:
  - llm-cost-optimizer   # priority-0: always-on, loaded before all other skills
---

# Task Discovery Agent — Phase 1

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

## Role

Connect to the Jira MCP, identify the active sprint for the Centaurus board, retrieve all
issues assigned to the current user, filter out completed work items, cross-reference any
linked PRs from GitHub/Bitbucket, and persist the canonical story list to
`workflow/progress-tracker.csv`.

---

## How to Interact with Jira MCP (Step-by-Step)

### Step 1 — Verify current user identity
Call `mcp_mcp-jira_getCurrentUser` (no parameters).
Extract `accountId` and `emailAddress` — these are used to filter assignee matches.

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

**Column definitions:**

| Column         | Type    | Description                                                                 |
|----------------|---------|-----------------------------------------------------------------------------|
| `Story ID`     | String  | Jira ticket key (e.g. `G1198-18578`)                                       |
| `Title`        | String  | Jira issue summary                                                          |
| `Status`       | Enum    | Jira workflow status mapped to CSV status (see table below)                 |
| `Progress`     | Percent | Completion percentage — how far along the work item is (0%–100%)            |
| `Priority`     | Integer | Jira priority value                                                         |
| `Type`         | Enum    | `Story` or `Sub-task`                                                       |
| `Parent`       | String  | Parent ticket key; empty for top-level stories                              |
| `Plan File`    | String  | Path to the implementation plan markdown file (populated by Phase 2)        |
| `PR Link`      | String  | URL to the open pull request on GitHub / Bitbucket                          |
| `Review Rating`| String  | Code review outcome populated by reviewer (e.g. `APPROVED`, `CHANGES_REQ`) |
| `Build Status` | String  | CI/CD build result (e.g. `PASSING`, `FAILING`, `PENDING`)                  |
| `Last Updated` | Date    | ISO-8601 date of the last agent-triggered update (`YYYY-MM-DD`)             |

**Progress calculation rules:**

| Scenario                                    | Progress value                                                          |
|---------------------------------------------|-------------------------------------------------------------------------|
| Status = `New` / `Unelaborated`             | `0%`                                                                    |
| Status = `Defined`                          | `0%`                                                                    |
| Status = `In-Progress` (Sub-task)           | Agent sets manually based on code/analysis step — default `50%`         |
| Status = `In-Progress` (Story)              | `round( done_subtasks / total_subtasks * 100 )%` — default `50%` if no sub-tasks |
| Status = `In-Review`                        | `75%`                                                                   |
| Status = `Staging`                          | `90%`                                                                   |
| Status = `Done` / `Accepted`                | `100%` — row **excluded** from tracker                                  |

**Status mapping from Jira → CSV:**

| Jira Status    | CSV Status   |
|----------------|--------------|
| Unelaborated   | New          |
| Defined        | Defined      |
| In-Progress    | In-Progress  |
| In Review      | In-Review    |
| Staging        | Staging      |
| Done / Accepted| *(excluded)* |

**Rules:**
- Preserve existing rows that are still active; only update rows whose Jira status or Progress changed.
- Assign `New` / `0%` to stories appearing in the tracker for the first time.
- For Stories: recalculate `Progress` on every run by counting non-excluded sub-tasks that are `In-Progress`, `In-Review`, or `Staging` vs total sub-tasks.
- For Sub-tasks: set `Progress` based on the table above; agents may override to a finer value (e.g. `75%`) when partial work is confirmed.
- Never duplicate a Story ID.

---

## Pre-checks (must ALL pass before starting Phase 1)

- [ ] Jira MCP is reachable — `getCurrentUser` returns HTTP 200
- [ ] Board 5979 is accessible — `getBoards(G1198)` lists Centaurus
- [ ] Active sprint ID `106806` confirmed via `getSprints(5979, active)`
- [ ] GitHub or Bitbucket MCP is reachable (at least one active SCM MCP)
- [ ] No Task Discovery run is already in-flight for the same sprint

If any pre-check fails: emit `onObstacle(phase=1, reason=<detail>)` and halt.

---

## My Assigned Stories — Sprint 2026.SP07.Centaurus

> These were fetched live on 2026-03-30 and reflect the current state.
> The agent must re-fetch on every run to pick up any status changes.

| Ticket           | Type     | Title                                                                          | Jira Status | Progress | Parent       |
|------------------|----------|--------------------------------------------------------------------------------|-------------|----------|--------------|
| G1198-16774      | Story    | Elavon \| Modernization \| SPT Changes \| Mapping sensitive data               | Defined     | 0%       | G1198-322    |
| G1198-18576      | Story    | Elavon \| FLOW \| Write Flow test scenario VoID Auth operation                 | Defined     | 0%       | G1198-5772   |
| G1198-18577      | Story    | Elavon \| FLOW \| Write Flow test scenario TimeOutExpiry                       | Defined     | 0%       | G1198-5772   |
| G1198-18578      | Story    | Elavon \| FLOW \| Write Flow test scenario CVV                                 | In-Progress | 50%      | G1198-5772   |
| G1198-18593      | Sub-task | Analysis \[TimeOutExpiry\]                                                     | Defined     | 0%       | G1198-18577  |
| G1198-18594      | Sub-task | Code changes \[TimeOutExpiry\]                                                 | Defined     | 0%       | G1198-18577  |
| G1198-18595      | Sub-task | Automation Testing \[TimeOutExpiry\]                                           | Defined     | 0%       | G1198-18577  |
| G1198-18596      | Sub-task | PR Review \[TimeOutExpiry\]                                                    | Defined     | 0%       | G1198-18577  |
| G1198-18597      | Sub-task | Analysis \[CVV\]                                                               | In-Progress | 100%     | G1198-18578  |
| G1198-18598      | Sub-task | Code changes \[CVV\]                                                           | In-Progress | 50%      | G1198-18578  |
| G1198-18599      | Sub-task | Automation Testing \[CVV\]                                                     | Defined     | 0%       | G1198-18578  |
| G1198-18600      | Sub-task | PR Review \[CVV\]                                                              | Defined     | 0%       | G1198-18578  |
| G1198-18603      | Sub-task | Automation Testing \[VoidAuth\]                                                | Defined     | 0%       | G1198-18576  |
| G1198-18604      | Sub-task | PR Review \[VoidAuth\]                                                         | Defined     | 0%       | G1198-18576  |

---

## Sub-task Checklist

- [ ] `getCurrentUser` called — accountId confirmed as `64023c79f00d095406f37c24`
- [ ] Centaurus board ID `5979` confirmed via `getBoards(G1198)`
- [ ] Active sprint `106806` confirmed via `getSprints(5979, active)`
- [ ] All sprint issues fetched (paginated if total > 100)
- [ ] Filtered to assignee `e135408@mastercard.com` only
- [ ] Excluded all Done / Accepted / Closed statuses
- [ ] Cross-referenced open PRs from GitHub / Bitbucket
- [ ] `workflow/progress-tracker.csv` created or updated
- [ ] Duplicate Story IDs validated — none present
- [ ] Orchestrator notified with `COMPLETE` or `FAILED` status

---

## Post-checks (before signalling Phase 1 COMPLETE)

- [ ] `workflow/progress-tracker.csv` exists and is non-empty
- [ ] At least one story row with status `New`, `Defined`, or `In-Progress` is present
- [ ] All Story IDs in the CSV are unique (no duplicates)
- [ ] `Last Updated` column reflects today's date (`2026-03-30`)
- [ ] Orchestrator has received the `COMPLETE` or `FAILED` notification

---

## Output

- **Artefact**: `workflow/progress-tracker.csv`
- **Columns**: `Story ID, Title, Status, Progress, Priority, Type, Parent, Plan File, PR Link, Review Rating, Build Status, Last Updated`
- **Progress range**: `0%` (not started) → `100%` (complete / excluded)
- **Status codes**: `COMPLETE` → Orchestrator routes to Phase 2 | `FAILED` → Orchestrator escalates
