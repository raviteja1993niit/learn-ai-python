---
agent: orchestrator
description: >
  Launch the SDLC agentic pipeline for a given Jira story ID. Activates the Workflow Orchestrator
  (Phase 0) which presents configuration questions, then proceeds Phase 1 onward with human
  approval gates at each phase boundary.
---

# Start Workflow

Activate the Workflow Orchestrator to begin or resume the Phase-gated SDLC pipeline.

## Usage

Invoke this prompt with a Jira story ID:

```
@orchestrator Start the workflow for PROJ-1234
@orchestrator Start the workflow for PROJ-1234 --reconfigure
@orchestrator Resume workflow for PROJ-1234 from phase 4
```

## What the Orchestrator will do

1. Run **Phase 0**: check or create `workflow/workflow-config.json` interactively.
2. Present a **human approval gate** before every phase transition.
3. Drive the pipeline through active phases: 1 (Task Discovery) → 2 (Planning) → 3 (Human Gate) → 4 (Code Dev) → 5 (Code Review) → 6 (Code Push) → 7 (Build Fix if needed) → 8 (Merge & Closure).

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID to process (required) |
| `--reconfigure` | Re-run Phase 0 even if `workflow-config.json` exists |
| `--phase <N>` | Resume from a specific phase number |

## Prerequisites

- `workflow/workflow-config.json` will be created interactively if absent
- Jira, GitHub/Bitbucket, and Jenkins MCP servers configured and reachable
