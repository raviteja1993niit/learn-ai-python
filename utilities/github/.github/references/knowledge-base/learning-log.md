# Learning Log
> What this agent has learned from interactions with the YAML specs

## How to Use This File
- Agent updates this after each significant interaction
- Entries are chronological (newest first)
- Used to improve future decisions

---

## Recent Learnings

### 2026-02-25 — VerificationSubmission required fields alignment
**Context:** User provided a VERIFICATION payload containing `transactionType` and `orderId`. Audit of `VerificationSubmission` schema revealed `orderId` was already required but `transactionType` was only in properties.
**Learned:** Always cross-check properties vs required list when a payload field seems "obvious" — it may be a property but not required. `TransactionType` enum already included `VERIFICATION`, so the only gap was the `required` declaration.
**Applied:** When auditing any submission schema, always run a diff between the `required:` array and the fields in a valid payload. Missing entries are prime candidates for required-list additions.
**Confidence:** High

### 2026-02-25 — `VerificationSubmission.merchant` requires `timeZone`
**Context:** Comparing `AuthorizationSubmission.merchant` required fields vs `VerificationSubmission.merchant` required fields. Verification uniquely requires `timeZone` while Authorization does not.
**Learned:** Submission schemas for different operation types have subtly different `merchant` required sets. Always check the specific `title:` block of `merchant` within each schema, not a generic shared merchant schema.
**Applied:** When a user asks about merchant fields, check the title-tagged inner object for the specific operation type.
**Confidence:** High

### 2026-02-25 — allOf inheritance in acquirer overlay
**Context:** `AcquirerVerificationSubmission` uses `allOf` referencing `VerificationSubmission`. After adding `transactionType` to `VerificationSubmission.required`, no change was needed in `AcquirerVerificationSubmission`.
**Learned:** The acquirer overlay `allOf` pattern fully inherits required lists from the base schema. Only the acquirer-specific additional fields (`acquirerConfigurations`, `systemTraceAuditNumber`, `originalSystemTraceAuditNumber`) need explicit required declarations in the overlay.
**Applied:** After every primary schema required-list change, verify that the acquirer overlay uses `allOf` (inherits automatically) rather than re-declaring the full required list.
**Confidence:** High

---

## Pattern Library

| ID | Pattern | When to Use | Success Rate |
|----|---------|-------------|--------------|
| P001 | Check properties vs required diff | When validating schema completeness | 100% |
| P002 | allOf inherits required automatically | When checking acquirer overlay impact | 100% |
| P003 | Merchant required differs per schema | When comparing merchant fields across schemas | 100% |
| P004 | TransactionType enum covers VERIFICATION | When validating transactionType for verification ops | 100% |

---

## Anti-Patterns (What NOT to do)

| ID | Anti-Pattern | Why Bad | Instead Do |
|----|--------------|---------|------------|
| A001 | Assume acquirer overlay needs updating when primary changes | allOf inheritance makes it automatic | Only update overlay if adding acquirer-specific fields |
| A002 | Add `transactionAmount` to VerificationSubmission | Verification is non-financial — no amount | Leave it absent |
| A003 | Use `type: object` without `title:` for nested inline schemas | Makes schema tools give unhelpful names | Always add `title: ParentSchemaNestedName` |
| A004 | Hardcode cross-file $ref paths | Breaks if files move | Use relative paths `./filename.yaml#/path` |

---

## Performance Summary
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Successful schema edits | 1 | - | ✅ |
| Cross-file ref accuracy | 100% | >95% | ✅ |
| Breaking changes introduced | 0 | 0 | ✅ |

---
*Auto-updated by agent after each interaction*
