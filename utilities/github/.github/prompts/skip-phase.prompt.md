---
agent: orchestrator
description: >
  Send a SKIP decision for the current phase awaiting approval. The Orchestrator marks the phase
  as skipped, records the reason, and advances to the next active phase with a new approval gate.
---

# Skip Phase

Skip the currently pending phase for a story.

## Usage

```
@orchestrator Skip phase for PROJ-1234
@orchestrator Skip phase 2 for PROJ-1234 --reason "Manual plan already exists"
```

## What happens

1. The Orchestrator receives a `SKIP` signal.
2. The phase is recorded as `~~skipped~~` in `workflow/todos/workflow-todo-<story-id>.md`.
3. The Orchestrator advances to the next active phase and presents a new approval gate.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Story ID with a pending phase (required) |
| `phase <N>` | Phase number to skip (optional) |
| `--reason <text>` | Reason recorded in the workflow todo (recommended) |

## Warnings

- Skipping Phase 3 (Human Review Gate) removes developer plan confirmation.
- Skipping Phase 5 (Code Review) bypasses the SonarQube/Checkmarx quality gate.
- Skipping Phase 6 (Code Push) automatically skips Phase 8 (Merge & Closure).
- All skips are logged with timestamp for audit.
