---
name: on-file-write
event: onFileWrite
filePattern: "**/*.java"
skill: coding-style
blocking: true
description: >
  Fires immediately after any .java file is written or modified. Invokes the coding-style skill
  to run all 7 rules against the saved file. BLOCKER and HIGH findings halt the commit step;
  MEDIUM and LOW findings are collected for the PR description.
---

# Hook: on-file-write — Coding Style Check

## Event

`onFileWrite` — triggered every time a `.java` source file is created or modified by any agent
or manual edit within the workflow.

---

## File Pattern

```
**/*.java
```

Matches all Java source files across every module:
- `pgs-acquirer-elavon-interface-service/src/**/*.java`
- `lib-elavon-interface-mapping/src/**/*.java`
- `lib-elavon-interface-message/src/**/*.java`
- `lib-elavon-interface-simulation/src/**/*.java`
- `lib-elavon-interface-test-data/src/**/*.java`
- `lib-elavon-interface-integration-tests/src/**/*.java`

---

## Skill Invoked

**`coding-style`** — `.claude/skills/coding-style/SKILL.md`

Rules evaluated on every trigger:

| # | Rule | Blocking Severity |
|---|------|------------------|
| 1 | Mastercard copyright header | BLOCKER |
| 2 | Java style — traditional vs. functional (performance & simplicity) | HIGH |
| 3 | Javadoc & comment discipline | MEDIUM |
| 4 | SonarQube-clean & modular structure | BLOCKER / HIGH |
| 5 | Naming conventions & maintainability | HIGH |
| 6 | Backward compatibility — existing functionality must not break | BLOCKER / HIGH |
| 7 | SOLID principles & design patterns | HIGH |

---

## Execution Flow

```
Agent writes / modifies *.java file
        │
        ▼
[HOOK: on-file-write] fires
        │
        ▼
skill:coding-style evaluates all 7 rules on the saved file
        │
        ├── BLOCKER found?  ──► Halt commit step; report to agent; agent must fix before retry
        │
        ├── HIGH found?     ──► Flag to agent; agent must fix before Phase 4 COMPLETE
        │
        ├── MEDIUM found?   ──► Collect in findings buffer; include in PR description
        │
        └── LOW / INFO      ──► Collect in findings buffer; advisory only
```

---

## Output

```
[HOOK: on-file-write] <relative/path/to/File.java>
  Skill    : coding-style
  Findings : <N> BLOCKER | <N> HIGH | <N> MEDIUM | <N> LOW
  Status   : BLOCKED | WARNINGS | CLEAN

[CODING STYLE] <file>:<line>
  Severity : BLOCKER | HIGH | MEDIUM | LOW | INFO
  Rule     : <Rule number and name>
  Finding  : <Concise description>
  Fix      : <Concrete recommended action>
```

---

## Behaviour

- **Blocking**: `true` — a BLOCKER finding prevents the file from being committed until resolved.
- Does NOT modify the file automatically.
- All findings are accumulated in the session findings buffer and flushed to
  `workflow/style-findings-<story-id>.md` at the end of Phase 4.
- If the same file is written multiple times in a session, only the **latest** version is
  evaluated (deduplication by file path).
