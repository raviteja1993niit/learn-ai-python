---
applyTo: '**/*.java'
description: >
  Auto-triggered skill that checks modified files against OWASP Top 10 patterns,
  PCI/PII data handling, credential exposure, and injection vectors.
  Reports findings; does not modify files.
---

# Security Review — Skill

## Trigger Conditions
- Every `.java` file write
- Phase 5 (Code Review) start
- Explicitly: "run security scan on `<file-list>`"

---

## Checks

### OWASP Top 10 Patterns

| Check | Pattern to Detect |
|-------|------------------|
| Injection | String-concatenated SQL; `Runtime.exec()` with user input |
| Broken Access Control | Missing auth annotations; hardcoded role bypasses |
| Cryptographic Failures | `MD5`, `SHA-1`, `DES`, `ECB` usage; hardcoded keys |
| Security Misconfiguration | `@CrossOrigin("*")` in non-test code |
| Auth Failures | Hardcoded credentials; `permitAll()` on sensitive endpoints |
| SSRF | User-supplied URLs passed to `RestTemplate`/`WebClient` without validation |
| Logging Failures | `log.*()` with PAN/CVV/PII variables; stack traces in API responses |

### PCI / PII Data
- Detect field names: `pan`, `cardNumber`, `cvv`, `cvc`, `expiryDate`, `ssn`, `password` in log statements
- Detect serialisation of sensitive fields without `@JsonIgnore` or masking

### Credential Exposure
- Hardcoded strings matching: API keys, JWT secrets, passwords
- `.properties`/`.yml` with `password=`, `secret=`, `token=` (non-placeholder values)

---

## Output Format

```
[SECURITY SCAN] <file>:<line>
  Severity : CRITICAL | HIGH | MEDIUM | LOW
  CWE      : CWE-<ID>
  Finding  : <Description>
  Fix      : <Recommended remediation>
```

CRITICAL/HIGH must be resolved before Phase 5 PASS. MEDIUM/LOW go into `review-<story-id>.md`.
