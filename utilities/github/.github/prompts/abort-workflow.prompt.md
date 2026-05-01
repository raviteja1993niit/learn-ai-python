---
agent: orchestrator
description: >
  Send an ABORT decision to immediately pause the pipeline for a story. The Orchestrator halts
  all in-progress work, logs the abort reason in the workflow todo, updates progress-tracker.csv,
  and sends a Slack/Teams notification to the developer.
---

# Abort Workflow

Immediately pause the SDLC pipeline for a story.

## Usage

```
@orchestrator Abort workflow for PROJ-1234
@orchestrator Abort workflow for PROJ-1234 --reason "Requirements changed — awaiting updated AC"
```

## What happens

1. The Orchestrator receives an `ABORT` signal.
2. The current agent stops after completing any atomic in-progress operation.
3. Abort reason and timestamp are written to `workflow/todos/workflow-todo-<story-id>.md` Obstacle Log.
4. `progress-tracker.csv` status for this story is set to `Aborted`.
5. Slack / Teams notification sent to the configured developer channel.
6. Pipeline halts; no further phases until explicitly resumed.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Story ID to abort (required) |
| `--reason <text>` | Human-readable reason (recommended) |

## Resumption

```
@orchestrator Start the workflow for PROJ-1234 --phase <N>
```

where `<N>` is the phase number shown in the abort log.
