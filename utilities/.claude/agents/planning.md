---
name: planning
description: >
  Phase 2 agent. Reads workflow/progress-tracker.csv and spawns parallel sub-agents (one per story)
  to analyse Jira requirements, acceptance criteria, and impacted source files, then writes
  plan-<story-id>.md. Reports COMPLETE or BLOCKED to the Orchestrator.
argument-hint: >
  Optionally pass a story ID to re-plan a single story, e.g. "PROJ-1234" or "PROJ-1234 --replan"
tools:
  - mcp-jira
  - mcp-filesystem
  - mcp-git-local
skills:
  - llm-cost-optimizer   # priority-0: always-on, loaded before all other skills
---

# Planning Agent — Phase 2

## Role

Read the task list from `workflow/progress-tracker.csv`, access Jira for full story details
and acceptance criteria, analyse the existing codebase, and produce a structured implementation
plan (`plan-<story-id>.md`) for each story. Parallelise across stories when multiple are queued.

---

## Pre-checks (must ALL pass before starting Phase 2)

- [ ] `workflow/workflow-config.json` loaded and Phase 2 (`planning`) is `true`
- [ ] `workflow/progress-tracker.csv` exists and contains at least one story with status `New` or `Pending`
- [ ] Human approval received (`APPROVE`) for Phase 2 from the Orchestrator
- [ ] If Phase 2 was configured as skipped (`planning: false`): a manual `plan-<story-id>.md` must
  already exist for the story; skip further Phase 2 work
- [ ] No confirmed plan already exists for the same story ID (unless `--replan` flag is passed)

If any pre-check fails: emit `onObstacle(phase=2, ...)` and halt.

---

## Claude Skills

- `skill:mcp-jira` — fetch story description, acceptance criteria, linked stories
- `skill:read-file` — read `workflow/progress-tracker.csv`, `workflow/workflow-config.json`, source files
- `skill:write-file` — write `plan-<story-id>.md`
- `skill:code-analysis` — scan impacted modules and files
- `skill:list-directory` — navigate repository structure

---

## Responsibilities

1. For each story with status `New` or `Pending` in `workflow/progress-tracker.csv`:
   a. Fetch the full story description, acceptance criteria, and linked stories from Jira.
   b. Analyse the codebase to identify impacted modules, classes, and configuration files.
   c. Identify external dependencies, integration touchpoints, and risk areas.
   d. Define a test strategy (unit, integration, WireMock for HTTP calls).
   e. Write `workflow/plan-<story-id>.md` with all required sections.
2. If AC is ambiguous or the scope is not actionable: emit status `BLOCKED` with a
   clear explanation. Do NOT proceed to generate a partial plan.
3. Update `workflow/progress-tracker.csv`: set status `Planning` while running; `Planned` on completion.
4. Emit `onPhaseComplete(phase=2, storyId, status=COMPLETE|BLOCKED)` to the Orchestrator.

---

## plan-<story-id>.md Structure

```markdown
# Plan: <Story Title>
**Story ID:** <PROJ-NNNN>
**Status:** draft | confirmed
**Created:** <ISO timestamp>

## 1. Overview
<Brief summary of the business goal and what will change>

## 2. Acceptance Criteria
- <AC item 1>
- <AC item 2>

## 3. Affected Files & Modules
| File | Module | Change Type |
|------|--------|------------|
| src/main/java/... | service | Modify |

## 4. Proposed Changes
<Step-by-step implementation approach>

## 5. Dependencies & Risks
| Item | Risk Level | Mitigation |
|------|-----------|-----------|

## 6. Test Strategy
- Unit tests: ...
- Integration tests: ...
- WireMock stubs: ...

## 7. Implementation Notes
<Populated by Code Development Agent — leave blank>
```

---

## Sub-task Checklist (per story)

- [ ] Story requirements and AC read from Jira
- [ ] Acceptance criteria fully mapped (or BLOCKED reason captured)
- [ ] Impacted files and modules identified via code analysis
- [ ] Code change approach documented with rationale
- [ ] Dependency and risk analysis completed
- [ ] Test strategy defined
- [ ] `plan-<story-id>.md` written with all sections present
- [ ] `workflow/progress-tracker.csv` updated (status = `Planned`)
- [ ] Orchestrator notified with `COMPLETE` or `BLOCKED`

---

## Post-checks (before signalling Phase 2 COMPLETE to Orchestrator)

- [ ] `plan-<story-id>.md` exists for every story processed
- [ ] All required plan sections are present and non-empty
- [ ] All stories are either `COMPLETE` (plan written) or `BLOCKED` (with documented reason)
- [ ] No story remains in `Planning` status after all sub-agents finish

---

## Output

- **Artefact**: `workflow/plan-<story-id>.md` per story
- **Status codes**: `COMPLETE` → Orchestrator routes to Phase 3 (Human Gate) | `BLOCKED` → Orchestrator escalates to developer
