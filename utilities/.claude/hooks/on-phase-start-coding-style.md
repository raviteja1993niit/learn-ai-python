---
name: on-phase-start-coding-style
event: onPhaseStart
phases:
  - 4
  - 5
skill: coding-style
blocking: false
description: >
  Fires at the start of Phase 4 (Code Development) and Phase 5 (Code Review). Performs a
  full coding-style sweep across all .java files touched by the current story before any
  development or review work begins. Surfaces pre-existing style debt so the agent is
  aware of the baseline before making changes.
---

# Hook: on-phase-start — Coding Style Pre-Flight Sweep

## Event

`onPhaseStart` — triggered once when Phase 4 or Phase 5 begins for a story, before the
respective agent executes its first action.

---

## Phases

| Phase | Agent | Purpose of Hook |
|-------|-------|----------------|
| **4** | Code Development | Baseline sweep of files listed in `plan-<story-id>.md` (section 3 — Affected Files). Surfaces pre-existing style issues so the developer agent knows the starting state before writing new code. |
| **5** | Code Review | Full sweep of all `.java` files changed on the feature branch. Provides a coding-style dimension to supplement the SonarQube and Checkmarx scans. |

---

## Skill Invoked

**`coding-style`** — `.claude/skills/coding-style/SKILL.md`

All 7 rules are evaluated on every file in scope:

| # | Rule |
|---|------|
| 1 | Mastercard copyright header |
| 2 | Java style — traditional vs. functional (performance & simplicity) |
| 3 | Javadoc & comment discipline |
| 4 | SonarQube-clean & modular structure |
| 5 | Naming conventions & maintainability |
| 6 | Backward compatibility — existing functionality must not break |
| 7 | SOLID principles & design patterns |

---

## Execution Flow

### Phase 4 — Pre-Development Baseline

```
Phase 4 starts (Code Development Agent initialises)
        │
        ▼
[HOOK: on-phase-start phase=4] fires
        │
        ▼
Read plan-<story-id>.md → extract affected file list (section 3)
        │
        ▼
skill:coding-style evaluates all 7 rules on each affected file
        │
        ▼
Emit baseline style report → agent is informed of pre-existing issues
        │
        ▼
Code Development Agent proceeds (baseline findings do NOT block Phase 4 start)
```

### Phase 5 — Pre-Review Style Sweep

```
Phase 5 starts (Code Review Agent initialises)
        │
        ▼
[HOOK: on-phase-start phase=5] fires
        │
        ▼
Read git diff of feature branch → collect all changed *.java files
        │
        ▼
skill:coding-style evaluates all 7 rules on each changed file
        │
        ▼
Append coding-style findings to review-<story-id>.md (Coding Style section)
        │
        ▼
Any new BLOCKER / HIGH introduced on the branch → treated as Code Review FAIL
```

---

## Output

```
[HOOK: on-phase-start phase=<4|5>] Story: <STORY-ID>
  Skill      : coding-style
  Files      : <N> files evaluated
  Findings   : <N> BLOCKER | <N> HIGH | <N> MEDIUM | <N> LOW

[CODING STYLE] <file>:<line>
  Severity   : BLOCKER | HIGH | MEDIUM | LOW | INFO
  Rule       : <Rule number and name>
  Finding    : <Concise description>
  Fix        : <Concrete recommended action>

Summary: BLOCKED | HAS_WARNINGS | CLEAN
```

---

## Behaviour

- **Non-blocking at Phase 4 start** — baseline findings are informational; they do not
  prevent Phase 4 from commencing, but the agent must not *introduce new* BLOCKER/HIGH
  issues in files it modifies.
- **Blocking at Phase 5 start** — any BLOCKER or HIGH finding introduced on the branch
  (not present in `main`/`develop`) is treated as a Phase 5 pre-check failure and added
  to the review report as a Critical finding.
- Findings are written to `workflow/style-findings-<story-id>.md` and referenced in the
  Phase 5 review report under a dedicated **Coding Style** section.
- Does NOT modify any source file automatically.
