---
name: start-workflow
description: >
  Launch the SDLC agentic pipeline for a given Jira story ID. Invokes the Workflow Orchestrator
  which starts with Phase 0 configuration, then proceeds Phase 1 onward with human approval gates.
argument-hint: >
  Pass the Jira story ID and optional flags, e.g. "PROJ-1234" or "PROJ-1234 --reconfigure"
---

# /project:start-workflow

Trigger the Workflow Orchestrator to start or resume the SDLC pipeline.

## Usage

```
/project:start-workflow PROJ-1234
/project:start-workflow PROJ-1234 --reconfigure
```

## What happens

1. The **Workflow Orchestrator** (`.claude/agents/workflow-orchestrator.md`) is activated.
2. Phase 0 runs: `workflow-config.json` is checked or created interactively.
3. The Orchestrator presents a human approval gate before advancing to Phase 1.
4. The pipeline then runs Phase 1 → Phase 8 with a human approval prompt at each phase boundary.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID to process (required) |
| `--reconfigure` | Re-run Phase 0 even if `workflow-config.json` already exists |
| `--phase <N>` | Resume pipeline from a specific phase (skips phases 1 to N-1) |

## Prerequisites

- `workflow/workflow-config.json` exists or will be created interactively
- Jira, GitHub/Bitbucket, and Jenkins MCP servers are configured and reachable
