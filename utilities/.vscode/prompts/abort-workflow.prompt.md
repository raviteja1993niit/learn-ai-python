---
agent: workflow-orchestrator
description: >
  Send an ABORT decision to pause the pipeline for a story. All in-progress work is halted,
  the Orchestrator logs the abort reason, and a Slack/Teams alert is sent to the developer.
---

# Abort Workflow

Immediately pause the SDLC pipeline for a story. The current phase is halted and the state is
preserved so the pipeline can be resumed later.

## Usage

```
@workflow-orchestrator Abort the workflow for PROJ-1234
@workflow-orchestrator Abort the workflow for PROJ-1234 --reason "Requirements changed — awaiting updated AC"
```

## What happens

1. The Orchestrator receives an `ABORT` signal.
2. The current agent stops after completing any atomic operation in progress.
3. The abort reason and timestamp are written to `workflow/todos/workflow-todo-<story-id>.md` Obstacle Log.
4. `progress-tracker.csv` status for this story is set to `Aborted`.
5. A Slack / Teams notification is sent to the configured developer channel.
6. The pipeline halts; no further phases are executed until explicitly resumed.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID to abort (required) |
| `--reason <text>` | Human-readable reason for the abort (recommended) |

## Resumption

To resume from the aborted phase:

```
@workflow-orchestrator Start the workflow for PROJ-1234 --phase <N>
```

where `<N>` is the phase number shown in the abort log.
