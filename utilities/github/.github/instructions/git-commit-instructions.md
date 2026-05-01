---
applyTo: "**"
---

Copyright Header:
- Every new Java source file must begin with the Mastercard copyright block before the package declaration.
- Use the exact format observed across the MODERNIZATION repositories:
  /*
   * Copyright (c) <YEAR> Mastercard. All rights reserved.
   */
- Replace <YEAR> with the current four-digit year (e.g., 2025).
- The copyright block applies to all .java files. Do not add it to XML, YAML, properties, or JSON files.
- Never modify or remove an existing copyright header.

Commit Message Format:
- Every commit message must follow the Mastercard project format:
  <TICKET-ID>: <Short imperative description>
- TICKET-ID is the Jira or story identifier used in the branch name (e.g., G1198_18131, G1198-16490).
- The description must be a concise, imperative-mood sentence (50 characters or fewer where possible).
- Capitalise the first word of the description. Do not end with a period.
- Examples of valid commit messages:
    G1198_18131: Add log masking for TSPI request fields
    G1198-16490: Update circuit breaker threshold configuration
    G1198-17457: Apply UCP labeling to Chase transaction flow
- Examples of invalid commit messages:
    Code Refactoring                (missing ticket ID)
    fixed the bug.                  (lowercase, ends with period, no ticket)
    G1198_18131: refactoring        (vague — state what was actually changed)

Commit Granularity:
- Each commit must represent one logical, reviewable change.
- Do not mix unrelated changes (e.g., bug fix + formatting cleanup) in a single commit.
- Squash WIP or checkpoint commits before raising a pull request.
- Keep commits small enough that the diff is understandable in isolation.

Branch Naming:
- Use the format: feature/<TICKET-ID>_<SHORT_DESCRIPTION>
- Use underscores to separate words within the description segment.
- Examples:
    feature/G1198_18131_CHASE_TSPI_MASKING_LOGS
    feature/G1198-16490-circuit-breaker-changes
    fix/G1198-17891-null-pointer-in-mapper

Pre-Commit Checklist:
- Before committing, verify the following:
    1. Copyright header is present at the top of every new .java file.
    2. No secrets, credentials, tokens, or API keys are staged.
    3. All new public classes, interfaces, and methods have Javadoc comments.
    4. Unused imports have been removed. No wildcard imports introduced.
    5. Code compiles locally (mvn clean compile -q).
    6. Unit tests pass locally (mvn test -q).
    7. No SonarQube BLOCKER or CRITICAL issues introduced.
    8. Log statements do not print card numbers, CVV, PAN, passwords, or any PII.
    9. The commit message matches the <TICKET-ID>: <Description> format.
    10. Only files related to the current ticket are staged (git status reviewed).

Commit Message Body (optional):
- For non-trivial changes, add a blank line after the subject and include a short body explaining the "why".
- Wrap body lines at 72 characters.
- Example:
    G1198_18131: Mask PAN and CVV in outbound TSPI log entries

    Regulatory requirement mandates that card data must not appear in
    application logs. Applied SensitiveDataMasker to all outbound
    ChasePaymentech request serialisers.

Footer — Issue and PR References:
- Optionally add a footer after a blank line to link to Jira or PRs:
    Refs: G1198-18131
    Closes: #62
- Do not add footers to merge commits — these are managed automatically.

Merge Commit Messages:
- Merge commits are generated automatically by GitHub/Bitbucket. Do not edit them manually.
- Merge commit subject format used by the platform:
    Merge pull request #<PR_NUMBER> from <org>/<branch>

Pull Request Description — Auto-Generation Instructions:
- When raising a PR, generate the description automatically from the staged commit log.
- The PR description must include the following sections:

  ## Summary
  A one-paragraph, plain-English summary of what this PR does and why.
  Derived from the aggregate of all commit messages since the branch diverged from the base.

  ## Changes
  A bullet list of the discrete changes made, one bullet per logical change.
  Each bullet should be concise (one line) and start with a past-tense verb.
  Example:
  - Added log masking for PAN and CVV in ChasePaymentechRequestSerializer
  - Updated circuit breaker threshold from 50% to 30% in application.yml
  - Removed unused ElavonMapper import from CapInterfaceApplication

  ## Testing
  Describe what was tested: unit tests added or updated, integration test coverage, manual test steps performed.

  ## Related Tickets
  Link the Jira story or task: [G1198-18131](https://jira.mastercard.com/browse/G1198-18131)

  ## Checklist
  - [ ] Copyright header present on all new Java files
  - [ ] No secrets or credentials in staged files
  - [ ] Javadoc added to all new public classes and methods
  - [ ] Unit tests added or updated (mvn test passes)
  - [ ] SonarQube quality gate passes
  - [ ] No PAN, CVV, or PII visible in logs or error messages
  - [ ] PR size is 400 lines or fewer (split if larger)

- When Copilot is asked to generate a commit message, it must:
    1. Run git diff --staged to inspect exactly what files and lines changed.
    2. Identify the ticket ID from the current branch name.
    3. Produce a single-line subject: <TICKET-ID>: <concise imperative description>.
    4. If the change spans multiple concerns, produce one commit message per concern and suggest splitting the commit.

- When Copilot is asked to generate a PR description, it must:
    1. Run git log <base-branch>..HEAD --oneline to collect all commit subjects.
    2. Run git diff <base-branch>..HEAD --stat to see which files changed.
    3. Synthesise a Summary, Changes list, Testing notes, and Related Tickets section.
    4. Pre-fill the Checklist with all items unchecked.
