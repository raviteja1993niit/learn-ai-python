---
agent: build-fix
description: >
  Manually trigger the Build Fix Agent (Phase 7) for a story. Use when Phase 6 reported
  BUILD_FAIL and you want to route directly to the Build Fix Agent without a full pipeline restart.
---

# Fix Build

Manually invoke the Build Fix Agent for a story that has a `BUILD_FAIL` from Phase 6 (Code Push).

## Usage

```
@build-fix Fix build for PROJ-1234
@build-fix Fix build for PROJ-1234 --iteration 2
```

## What happens

1. The Orchestrator validates pre-checks for Phase 7 (Build Fix Agent).
2. A human approval gate is presented before the Build Fix Agent is activated.
3. The Build Fix Agent reads `workflow/build-log-<story-id>.txt`, classifies the failure,
   applies a fix, runs `mvn clean test -q` locally, and reports `FIX_COMPLETE` or `FIX_BLOCKED`.
4. On `FIX_COMPLETE`: Orchestrator routes to Phase 5 (Code Review) → Phase 6 (Code Push).
5. On `FIX_BLOCKED`: Orchestrator routes to Phase 2 (Planning) for redesign.

## Arguments

| Argument | Description |
|----------|-------------|
| `<STORY-ID>` | Jira story ID with a BUILD_FAIL status (required) |
| `--iteration <N>` | Iteration number (1–3); defaults to auto-detected from `workflow-config.json` |

## Prerequisites

- `workflow/build-log-<story-id>.txt` must exist and be non-empty
- `workflow/plan-<story-id>.md` must exist
- Iteration count must be below `iterationLimits.buildFixCycle` (default: 3)
