# Security Rules

## Secrets Management

- **Never** hard-code credentials, API keys, passwords, tokens, or connection strings in source code
- **Never** include secrets in configuration files committed to source control
- Always externalise secrets to environment variables or a secrets manager (Vault, AWS Secrets Manager)
- If a secret is accidentally committed: rotate it **immediately** and rewrite history with `git filter-repo`

## PCI / PII Data Handling

- **Never** log, serialise to disk, or include in error messages:
  - Primary Account Number (PAN / card number)
  - CVV / CVC / security code
  - Card expiry date
  - Personally identifiable information (name, address, email, phone, national ID)
  - Authentication credentials or session tokens
- Apply `SensitiveDataMasker` or equivalent masking to all serialisers used in logging paths
- Redact or mask sensitive fields before writing to any log output

## Input Validation

- Validate and sanitise **all** incoming request fields before processing
- Reject unexpected or malformed values early (guard clauses at the controller/handler boundary)
- Never pass raw user input into SQL queries, OS commands, or log statements
- Use parameterised queries or an ORM — never string-concatenated SQL

## OWASP Top 10 Checklist

Verify these are NOT introduced by any code change:

| # | Category | Key Controls |
|---|----------|-------------|
| A01 | Broken Access Control | Endpoint auth checks; no IDOR |
| A02 | Cryptographic Failures | TLS enforced; no MD5/SHA-1 for security; no ECB mode |
| A03 | Injection | Parameterised queries; no command injection; output encoding for XSS |
| A04 | Insecure Design | Threat model reviewed; no bypass of business logic controls |
| A05 | Security Misconfiguration | No debug endpoints in prod; secure headers; least-privilege |
| A06 | Vulnerable Components | `mvn dependency:check`; no CRITICAL/HIGH CVEs |
| A07 | Auth Failures | MFA where applicable; brute-force protection; session expiry |
| A08 | Integrity Failures | Signed artefacts; no unsigned deserialization |
| A09 | Logging Failures | Sufficient audit logging; no sensitive data logged |
| A10 | SSRF | Validate/restrict outbound URL targets; no user-controlled URLs to internal services |

## TLS

- Always enforce **TLS 1.2+** for outbound connections
- **Never** disable certificate validation in non-local environments
- Never set `trustAllCerts = true` or equivalent in any production-bound code

## Dependency Hygiene

- Run `mvn dependency:check` before every PR
- Address **CRITICAL** and **HIGH** CVEs before merging
- Review transitive dependencies when adding or upgrading a library
- Every additional dependency is a future CVE, licence, and upgrade obligation

## Log Hygiene

- Redact or mask sensitive fields before writing to any log output
- Never use string concatenation for log messages — use SLF4J parameterised format
- Log at appropriate levels: `DEBUG` for diagnostic paths; `INFO` for business events; `WARN` for recoverable errors; `ERROR` for failures
- Include correlation IDs in log output for traceability — never include PII

## Error Handling

- **Never** expose internal stack traces or raw exception messages in API responses
- Return structured error objects or appropriate HTTP status codes (4xx/5xx)
- Distinguish recoverable operational errors from non-recoverable programmer errors
