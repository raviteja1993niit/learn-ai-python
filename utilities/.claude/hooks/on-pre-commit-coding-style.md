---
name: on-pre-commit-coding-style
event: onPreCommit
filePattern: "**/*.java"
skill: coding-style
blocking: true
description: >
  Fires immediately before any git commit is staged and recorded. Performs a final coding-style
  gate across all .java files in the commit. A BLOCKER or HIGH finding aborts the commit and
  returns control to the agent to fix the issue first.
---

# Hook: on-pre-commit — Coding Style Final Gate

## Event

`onPreCommit` — triggered once per commit attempt, after the agent has staged files
(`git add`) but **before** `git commit` is executed. Acts as the last line of defence
before style violations enter the branch history.

---

## File Pattern

```
**/*.java
```

Only `.java` files staged in the current commit are evaluated. Non-Java files are ignored.

---

## Skill Invoked

**`coding-style`** — `.claude/skills/coding-style/SKILL.md`

Rules evaluated on every staged `.java` file:

| # | Rule | Abort Commit On |
|---|------|----------------|
| 1 | Mastercard copyright header | BLOCKER |
| 2 | Java style — traditional vs. functional (performance & simplicity) | HIGH |
| 3 | Javadoc & comment discipline | — (collect only) |
| 4 | SonarQube-clean & modular structure | BLOCKER / HIGH |
| 5 | Naming conventions & maintainability | HIGH |
| 6 | Backward compatibility — existing functionality must not break | BLOCKER / HIGH |
| 7 | SOLID principles & design patterns | HIGH |

> Rules 3 MEDIUM/LOW findings are collected and reported but do **not** abort the commit.

---

## Execution Flow

```
Agent runs: git add <files>
        │
        ▼
Agent attempts: git commit -m "<message>"
        │
        ▼
[HOOK: on-pre-commit] fires
        │
        ▼
skill:coding-style evaluates all 7 rules on staged *.java files only
        │
        ├── BLOCKER or HIGH found?
        │         │
        │         ▼
        │   Abort commit ──► Report findings to agent
        │                    Agent fixes, re-stages, retries commit
        │
        └── MEDIUM / LOW / CLEAN?
                  │
                  ▼
            Commit proceeds
            Findings appended to workflow/style-findings-<story-id>.md
```

---

## Output

```
[HOOK: on-pre-commit] Commit aborted | Commit allowed
  Skill    : coding-style
  Files    : <N> staged .java files evaluated
  Findings : <N> BLOCKER | <N> HIGH | <N> MEDIUM | <N> LOW
  Status   : ABORTED | CLEAN

[CODING STYLE] <file>:<line>
  Severity : BLOCKER | HIGH | MEDIUM | LOW | INFO
  Rule     : <Rule number and name>
  Finding  : <Concise description>
  Fix      : <Concrete recommended action>
```

---

## Behaviour

- **Blocking**: `true` — any BLOCKER or HIGH finding aborts the commit entirely.
- The agent receives the findings report, applies fixes, re-stages the corrected files,
  and retries the commit. The hook re-fires on every retry.
- MEDIUM and LOW findings are non-blocking but are appended to
  `workflow/style-findings-<story-id>.md` and referenced in the PR description.
- Does NOT modify any source file automatically.
- Applies only to files **staged in the current commit** — not the full working tree.
- If no `.java` files are staged (e.g., a YAML-only commit), the hook exits immediately
  as `CLEAN` without evaluation.
