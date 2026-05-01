---
name: approve-phase
description: >
  Send an APPROVE decision for the current phase awaiting human approval. The Orchestrator will
  proceed to route control to the appropriate agent for that phase.
argument-hint: >
  Pass the story ID and optionally the phase number, e.g. "PROJ-1234" or "PROJ-1234 --phase 5"
---

# /project:approve-phase

Approve the currently pending phase for a story and allow the Orchestrator to proceed.

## Usage

```
/project:approve-phase PROJ-1234
/project:approve-phase PROJ-1234 --phase 5
```

## What happens

1. The Orchestrator receives an `APPROVE` signal for the pending phase.
2. The approval timestamp is recorded in `workflow/todos/workflow-todo-<story-id>.md`.
3. The Orchestrator routes to the appropriate phase agent.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID with a pending approval (required) |
| `--phase <N>` | Phase number to approve (optional; defaults to the currently-awaiting phase) |

## Notes

- Only one phase can be pending approval at a time per story.
- If no phase is currently awaiting approval, the Orchestrator will report the current state.
