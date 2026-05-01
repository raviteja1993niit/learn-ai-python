---
name: skip-phase
description: >
  Send a SKIP decision for the current phase awaiting human approval. The Orchestrator will mark
  the phase as skipped and advance to the next active phase, presenting a new approval gate.
argument-hint: >
  Pass the story ID and optionally the phase number, e.g. "PROJ-1234" or "PROJ-1234 --phase 2"
---

# /project:skip-phase

Skip the currently pending phase for a story. The Orchestrator will mark it as skipped and
advance to the next active phase.

## Usage

```
/project:skip-phase PROJ-1234
/project:skip-phase PROJ-1234 --phase 2
```

## What happens

1. The Orchestrator receives a `SKIP` signal for the pending phase.
2. The phase is recorded as `~~skipped~~` in `workflow/todos/workflow-todo-<story-id>.md`.
3. The Orchestrator advances to the next active phase and presents a new approval gate.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID with a pending phase (required) |
| `--phase <N>` | Phase number to skip (optional; defaults to the currently-awaiting phase) |
| `--reason <text>` | Optional reason string recorded in the workflow todo |

## Warnings

- Skipping Phase 3 (Human Review Gate) removes the developer plan confirmation step.
- Skipping Phase 5 (Code Review) bypasses the SonarQube/Checkmarx quality gate.
- Skipping Phase 6 (Code Push) automatically skips Phase 8 (Merge & Closure).
- All skips are logged with timestamp for audit purposes.
