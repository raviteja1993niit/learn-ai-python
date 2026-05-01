---
agent: orchestrator
description: >
  Send an APPROVE decision for the current phase awaiting human approval. The Orchestrator
  will record the approval and route control to the appropriate pipeline agent.
---

# Approve Phase

Approve the pending phase for a story so the Orchestrator can proceed.

## Usage

```
@orchestrator Approve phase for PROJ-1234
@orchestrator Approve phase 5 for PROJ-1234
```

## What happens

1. The Orchestrator receives an `APPROVE` signal.
2. Approval timestamp is recorded in `workflow/todos/workflow-todo-<story-id>.md`.
3. The Orchestrator emits `onPhaseStart` and routes to the appropriate agent.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Story ID with a pending approval (required) |
| `phase <N>` | Phase number to approve (optional — defaults to currently-awaiting phase) |

## Notes

- Only one phase can be awaiting approval at a time per story.
- Use `/workflow-status` to check which phase is currently pending.
