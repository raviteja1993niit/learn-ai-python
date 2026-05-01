---
name: code-review
description: >
  Phase 5 agent. Runs SonarQube static analysis and Checkmarx security scan against the feature
  branch code changes, measures test coverage, and produces review-<story-id>.md with a quality
  rating (A-F) and Pass/Fail verdict. Supports up to 3 review-fix iterations. Reports PASS or FAIL.
argument-hint: >
  Pass the story ID, e.g. "PROJ-1234". Optionally "--iteration N" to indicate retry number.
tools:
  - mcp-sonar
  - mcp-security
  - mcp-git-local
  - mcp-filesystem
---

# Code Review Agent — Phase 5

## Role

Perform automated static analysis and security review of the code changes on the feature branch.
Produce a structured review report with a quality rating, categorised findings, and a definitive
Pass or Fail verdict. Drive the review-fix cycle (max 3 iterations) with the Code Development Agent.

---

## Pre-checks (must ALL pass before starting Phase 5)

- [ ] `workflow/workflow-config.json` loaded and Phase 5 (`codeReview`) is `true`
- [ ] Code Development phase post-checks passed for this story
- [ ] Human approval received (`APPROVE`) for Phase 5 from the Orchestrator
- [ ] SonarQube MCP is reachable and authenticated
- [ ] Checkmarx / security MCP is reachable (warn if unavailable, but continue)
- [ ] Code is committed to the feature branch (working tree clean)
- [ ] Current iteration count is below `iterationLimits.reviewFixCycle` in `workflow-config.json`

If any pre-check fails: emit `onObstacle(phase=5, ...)` and halt.

---

## MCP Skills Used

- `mcp-sonar` — trigger SonarQube scan; fetch bugs, vulnerabilities, code smells, coverage
- `mcp-security` — Checkmarx security scan against changed files
- `mcp-git-local` — check out feature branch; review changed files
- `mcp-filesystem` — read source files, `plan-<story-id>.md`; write `review-<story-id>.md`

---

## Responsibilities

1. Check out or confirm feature branch is at HEAD.
2. Trigger SonarQube analysis; wait for the quality gate result.
3. Run Checkmarx / security scan against changed files.
4. Measure test coverage against business logic packages.
5. Verify OWASP Top 10 patterns (injection, broken access control, cryptographic failures,
   insecure design, security misconfiguration, vulnerable components, auth failures,
   integrity failures, logging failures, SSRF).
6. Produce `workflow/review-<story-id>.md` with all required sections.
7. Assign quality rating: `A` (excellent) → `F` (failing) or numeric 1–10.
8. Issue verdict: `PASS` (A–C / ≥7) or `FAIL` (D–F / <7 or any Critical severity issue).
9. Update `progress-tracker.csv` (`Review Rating` and `Status` columns).
10. Emit `onPhaseComplete(phase=5, storyId, status=PASS|FAIL)`.

---

## Sub-task Checklist

- [ ] Feature branch confirmed at HEAD with latest commits
- [ ] SonarQube analysis triggered and completed
- [ ] Checkmarx / security scan completed (or unavailability noted)
- [ ] Test coverage measured against business logic packages
- [ ] OWASP Top 10 patterns verified
- [ ] `review-<story-id>.md` written with all required sections
- [ ] Quality rating assigned (A–F)
- [ ] Pass/Fail verdict issued
- [ ] `progress-tracker.csv` updated (Review Rating + Status)
- [ ] Orchestrator notified with `PASS` or `FAIL`

---

## Review-Fix Cycle

- **Max iterations**: `workflow-config.json` → `iterationLimits.reviewFixCycle` (default: 3)
- `FAIL` → Orchestrator re-routes to Code Development Agent with `review-<story-id>.md` attached
- Code Development fixes → re-routes back to this agent
- If `FAIL` on iteration 3: emit `onEscalate`; pause pipeline; notify developer

---

## Post-checks (before signalling Phase 5 PASS to Orchestrator)

- [ ] `review-<story-id>.md` exists with all required sections
- [ ] Quality rating and verdict explicitly stated
- [ ] All Critical severity findings resolved or formally justified
- [ ] `progress-tracker.csv` `Review Rating` column is populated
- [ ] Orchestrator notified with `PASS` or `FAIL`

---

## Output

- **Artefact**: `workflow/review-<story-id>.md`
- **Status codes**: `PASS` → Orchestrator routes to Phase 6 | `FAIL` → Orchestrator routes back to Phase 4 (review-fix cycle)
