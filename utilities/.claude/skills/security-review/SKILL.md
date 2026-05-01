---
name: security-review
description: >
  Auto-triggered skill that runs whenever code changes are present. Checks all modified files
  against OWASP Top 10 patterns, PCI/PII data handling, credential exposure, and injection vectors.
  Reports findings to the calling agent without modifying files.
triggers:
  - onFileWrite
  - onPhaseStart phase=5
---

# Skill: Security Review

## Purpose

Automatically scan modified source files for security vulnerabilities whenever code is written or
modified. Surface findings so the calling agent (Code Development or Code Review) can address
them before commit or before the formal Checkmarx scan in Phase 5.

---

## Trigger Conditions

- Triggered after every `skill:write-file` that modifies a `.java` file
- Triggered at the start of Phase 5 (Code Review) as a supplementary scan
- Can be explicitly invoked: run security scan on these files: `<file-list>`

---

## Checks Performed

### OWASP Top 10 Patterns

| Check | Pattern to Detect |
|-------|------------------|
| Injection | String-concatenated SQL; `Runtime.exec()` with user input; XSS via unescaped output |
| Broken Access Control | Missing auth annotations; hardcoded role bypasses |
| Cryptographic Failures | `MD5`, `SHA-1`, `DES`, `ECB` mode usage; hardcoded encryption keys |
| Security Misconfiguration | `@CrossOrigin("*")` in non-test code; debug endpoints not guarded |
| Vulnerable Components | `@Deprecated` Spring Security methods; known-bad method signatures |
| Auth Failures | Hardcoded credentials; `permitAll()` on sensitive endpoints |
| SSRF | User-supplied URLs passed to `RestTemplate`/`WebClient` without validation |
| Logging Failures | `log.*()` with PAN/CVV/PII variables; stack traces in API responses |

### PCI / PII Data

- Detect field names: `pan`, `cardNumber`, `cvv`, `cvc`, `expiryDate`, `ssn`, `password` used in log statements
- Detect serialisation of sensitive fields without `@JsonIgnore` or masking

### Credential Exposure

- Hardcoded strings matching patterns: API keys, connection strings, JWT secrets, passwords
- `.properties` / `.yml` values with `password=`, `secret=`, `token=` (non-placeholder values)

---

## Output Format

```
[SECURITY SCAN] <file>:<line>
  Severity : CRITICAL | HIGH | MEDIUM | LOW
  CWE      : CWE-<ID>
  Finding  : <Description>
  Fix      : <Recommended remediation>
```

---

## Behaviour

- Reports findings inline to the calling agent
- Does NOT automatically modify files
- CRITICAL or HIGH findings must be addressed before Phase 5 PASS can be issued
- MEDIUM and LOW findings are included in `review-<story-id>.md` improvement suggestions
