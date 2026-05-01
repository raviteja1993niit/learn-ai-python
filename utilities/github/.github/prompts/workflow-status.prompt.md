---
agent: orchestrator
description: >
  Print the current pipeline state for all active stories, or a specific story. Shows phase
  completion, current phase, iteration counts, and any outstanding obstacles.
---

# Workflow Status

Display the current pipeline state for one or all active stories.

## Usage

```
@orchestrator Show workflow status
@orchestrator Show workflow status for PROJ-1234
```

## Output Format

```
════════════════════════════════════════════════════════════
 SDLC Pipeline Status — <timestamp>
════════════════════════════════════════════════════════════
Story       : PROJ-1234 — <Story Title>
Current     : Phase 5 — Code Review (iteration 1/3)
Phase Path  : ✅ P0 ✅ P1 ✅ P2 ✅ P3 ✅ P4 🔄 P5 ⬜ P6 ⬜ P8
Obstacles   : None
────────────────────────────────────────────────────────────
```

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Phase complete |
| 🔄 | Phase in progress |
| 🕐 | Awaiting human approval |
| ~~⬜~~ | Skipped |
| ⬜ | Not yet started |
| ❌ | Failed / Blocked |

## Data Source

Reads `workflow/progress-tracker.csv` and `workflow/todos/workflow-todo-<story-id>.md`.
