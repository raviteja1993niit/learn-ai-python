---
applyTo: '**'
description: 'Mastercard MODERNIZATION project coding guidelines for Java/Spring Boot acquirer interface services.'
---

You are working on Mastercard PGS Connectivity acquirer interface services — Java 17 / Spring Boot multi-module Maven projects. Always follow the rules below when generating, reviewing, or refactoring code.

Project Context:
- All modules are part of the Mastercard MODERNIZATION programme for PGS acquirer connectivity.
- Base packages are com.mastercard.pgs.connectivity.acquirer.* or com.mastercard.gateway.acquiring.*.
- groupId follows the pattern com.mastercard.pgs.connectivity.acquirer.<domain>.
- Build tool is Maven. Java version is 17. Framework is Spring Boot with Spring MVC / Spring Integration.
- Observability uses SLF4J + Logback via Lombok @Slf4j.
- Testing uses JUnit 5, Mockito, and WireMock.

Copyright:
- Every new .java file must open with the following block before the package declaration:
  /*
   * Copyright (c) 2025 Mastercard. All rights reserved.
   */
- Do not add copyright headers to XML, YAML, properties, JSON, or Markdown files.
- Never alter or remove an existing copyright header.

Naming:
- Classes and interfaces: PascalCase (e.g., ChasePaymentechRequestMapper).
- Methods and variables: camelCase (e.g., buildAuthRequest(), transactionId).
- Constants: UPPER_SNAKE_CASE (e.g., MAX_RETRY_ATTEMPTS, DEFAULT_TIMEOUT_MS).
- Packages: lowercase (e.g., com.mastercard.pgs.connectivity.acquirer.chase.mapping).
- Booleans: prefix with is, has, can, or should (e.g., isOnline, hasValidToken).
- Enums: PascalCase name, UPPER_SNAKE_CASE members (e.g., enum TransactionType { AUTHORISATION, REVERSAL }).
- Test classes: class name under test + Test suffix (e.g., ElavonResponseMapperTest).

Formatting:
- 4 spaces indentation, no tabs.
- Opening brace on the same line as the declaration. Always use braces for if/for/while bodies.
- Lines 80–120 characters. Break long argument lists across lines with consistent alignment.
- Import groups in order: (1) java.*, (2) javax.*/jakarta.*, (3) org.springframework.*, (4) com.mastercard.*, (5) other third-party. Alphabetical within each group. No wildcard imports.

Code Quality:
- One public class or interface per file.
- Methods 30 lines or fewer. Extract private helpers for complex logic.
- Prefer final for local variables that are not reassigned.
- Guard clauses and early returns to reduce nesting (max 3 levels).
- Prefer constructor injection over @Autowired field injection.
- Use Optional<T> instead of returning null from public methods.
- Return empty collections (List.of(), Map.of()) instead of null.
- Use parameterised SLF4J log calls — log.info("Processed {}", id) — never string concatenation.
- Never log PAN, CVV, expiry date, passwords, or any PII.

Error Handling:
- Define domain exception classes extending RuntimeException (e.g., AcquirerCommunicationException).
- Never catch generic Exception or Throwable except at top-level boundary handlers.
- Every catch block must log, rethrow, or convert to a domain exception — never silently ignore.
- Validate required configuration at startup; fail with a clear message before accepting traffic.

Testing:
- JUnit 5 + Mockito. WireMock for HTTP interaction tests.
- Test method names: should<Behaviour>When<Condition> (e.g., shouldRejectRequestWhenPanIsNull).
- Arrange–Act–Assert structure with blank lines separating each section.
- No real network calls in unit tests.
- Integration tests in the libmpgs-*-integration-tests module, guarded by a Maven profile.

Security:
- No hard-coded credentials, tokens, or keys in source code.
- Redact sensitive card data in all log output and error messages.
- Enforce TLS on all outbound connections. Never disable certificate validation outside local development.
- Run mvn dependency:check regularly; resolve CRITICAL and HIGH CVEs before releasing.

Commits and PRs:
- Commit format: <TICKET-ID>: <Short imperative description> (e.g., G1198-16490: Update circuit breaker threshold).
- Branch format: feature/<TICKET-ID>_<SHORT_DESCRIPTION> (e.g., feature/G1198_18131_CHASE_TSPI_MASKING_LOGS).
- Pre-commit: copyright present, mvn clean compile -q passes, mvn test -q passes, no PII in logs.
- PR description must include Summary, Changes, Testing, Related Tickets, and a pre-filled Checklist.
