---
name: workflow-status
description: >
  Print the current pipeline state for all active stories, or a specific story. Shows phase
  completion, current phase, iteration counts, and any outstanding obstacles.
argument-hint: >
  Optionally pass a story ID, e.g. "PROJ-1234". Omit for all active stories.
---

# /project:workflow-status

Display the current pipeline state for one or all active stories.

## Usage

```
/project:workflow-status
/project:workflow-status PROJ-1234
```

## Output Format

```
════════════════════════════════════════════════════════════
 SDLC Pipeline Status — <timestamp>
════════════════════════════════════════════════════════════
Story       : PROJ-1234 — <Story Title>
Current Phase: Phase 5 — Code Review (iteration 1/3)
Phase Path  : ✅ P0 ✅ P1 ✅ P2 ✅ P3 ✅ P4 🔄 P5 ⬜ P6 ⬜ P8
Last Action : Code Review Agent started at <timestamp>
Obstacles   : None
────────────────────────────────────────────────────────────
Story       : PROJ-1235 — <Story Title>
Current Phase: Phase 2 — Planning (awaiting APPROVE)
Phase Path  : ✅ P0 ✅ P1 🕐 P2 ⬜ P3 ⬜ P4 ⬜ P5 ⬜ P6 ⬜ P8
Last Action : Human approval gate presented at <timestamp>
Obstacles   : None
════════════════════════════════════════════════════════════
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

Reads from:
- `workflow/progress-tracker.csv`
- `workflow/todos/workflow-todo-<story-id>.md` for each active story
