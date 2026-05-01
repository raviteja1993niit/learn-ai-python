---
applyTo: "**"
---

Copyright and Licensing:
- Every new Java source file must open with the Mastercard copyright block, placed before the package declaration:
  /*
   * Copyright (c) <YEAR> Mastercard. All rights reserved.
   */
- Replace <YEAR> with the current four-digit year (e.g., 2025).
- Apply the copyright block to .java files only. Do not add it to XML, YAML, properties, JSON, or Markdown files.
- Never alter or remove an existing copyright header in any file.
- The groupId for all Mastercard PGS Connectivity projects follows the pattern com.mastercard.pgs.connectivity.acquirer.<domain>.
- The base package for all generated code must start with com.mastercard.pgs or com.mastercard.gateway.acquiring, matching the module being extended.

Naming Conventions:
- Classes and Interfaces: Use PascalCase (e.g., CapInterfaceService, AcquirerRequestHandler).
- Methods and Variables: Use camelCase (e.g., buildRequest(), transactionContext).
- Constants (static final fields): Use UPPER_SNAKE_CASE (e.g., MAX_RETRIES, DEFAULT_TIMEOUT_MS).
- Packages: Use lowercase reverse-domain (e.g., com.mastercard.pgs.connectivity.acquirer.chase).
- Booleans: Prefix with is, has, can, or should (e.g., isOnline, hasValidCredentials, shouldRetry).
- Enums: PascalCase name with UPPER_SNAKE_CASE members (e.g., enum TransactionType { AUTHORISATION, REVERSAL, SETTLEMENT }).
- Test Classes: Mirror the class under test with a Test suffix (e.g., ChasePaymentechMapperTest).
- Source Files: One public class or interface per file; file name must match the class name exactly.

Formatting and Layout:
- Indentation: Use 4 spaces for indentation, not tabs.
- Brace Style: Opening brace on the same line as the declaration (e.g., public class MyClass {). Always use braces even for single-line if/for bodies.
- Line Length: Keep lines within 80-120 characters. Break long method chains or argument lists across lines with consistent alignment.
- Whitespace: Use spaces around operators, after commas, and between keywords and parentheses. No trailing whitespace. One blank line at the end of every file.
- Blank Lines: Use one blank line between methods and two blank lines between top-level declarations or major logical sections.
- Imports: Group and order imports — (1) java.* standard library, (2) javax.* / jakarta.*, (3) org.springframework.*, (4) com.mastercard.*, (5) other third-party libraries. Separate each group with a blank line. Sort alphabetically within each group. Never use wildcard imports.
- Annotations: Place each annotation on its own line immediately above the element it annotates.

Documentation and Comments:
- Javadoc Comments: Add Javadoc to every public class, interface, and method. Include @param, @return, @throws, and @since where applicable.
- Inline Comments: Explain complex logic or non-obvious decisions, focusing on the "why" rather than restating the "what".
- TODO / FIXME: Always include a Jira ticket reference (e.g., // TODO(G1198-18131): replace with structured error handler).
- Deprecation: Use @deprecated with a Javadoc note explaining the replacement.

Code Organisation and Structure:
- File Organisation: Each source file contains exactly one public class or interface.
- Method Length: Keep methods focused on a single responsibility. Aim for 30 lines or fewer; extract private helpers when a method grows beyond that.
- Variable Scope: Declare local variables as close as possible to their first use. Prefer final for variables that are not reassigned.
- Import Statements: No wildcard imports. Organise as described in Formatting and Layout.
- Early Returns / Guard Clauses: Validate inputs and return or throw early to reduce nesting depth.
- Avoid Deep Nesting: Keep a maximum of 3 levels of indentation in logic blocks. Refactor using extracted methods or guard clauses.
- Layer Separation: Keep controller/handler logic, service/business logic, and data-access/API-client code in separate classes.
- Package Structure: Follow the module conventions observed in the MODERNIZATION repositories — config, converter, mapping, validation, service, exception, util.

Java and Spring Boot Practices:
- Java Version: Target Java 17. Use records for immutable data carriers, sealed classes for closed type hierarchies, and pattern matching for instanceof checks where appropriate.
- Immutability: Prefer final fields and constructor injection. Avoid mutable shared state.
- Lombok: Use @Data, @Builder, @RequiredArgsConstructor, and @Slf4j judiciously. Do not use @Data on JPA entities.
- Spring Annotations: Prefer constructor injection over field injection (@Autowired on fields). Use @Configuration and @Bean for explicit wiring. Use @Value for simple scalar properties and @ConfigurationProperties for grouped configuration.
- Optional: Never return null from a public method where a value may be absent — return Optional<T> instead. Never call Optional.get() without isPresent() or use orElseThrow() with a meaningful exception.
- Collections: Return empty collections instead of null. Use List.of(), Map.of(), Set.of() for immutable collections.
- Streams: Prefer Streams and functional operations over imperative loops for data transformation. Avoid side effects inside stream pipelines.
- Logging: Use SLF4J with Logback (via @Slf4j). Always use parameterised log messages (log.info("Processing {}", id)) — never string concatenation. Do not log card numbers, CVV, PAN, passwords, or any PII.

Error Handling and Exceptions:
- Typed Exceptions: Define domain-specific exception classes extending RuntimeException (e.g., AcquirerCommunicationException, TransactionMappingException) with a meaningful message and optional cause.
- Handle exceptions gracefully. Never catch a generic Exception or Throwable unless at a top-level boundary handler.
- Do not ignore caught exceptions. Every catch block must log, rethrow, or convert to a domain exception.
- Fail Fast: Validate required configuration at application startup. Throw an IllegalStateException or use @PostConstruct validation to surface missing config before the application accepts traffic.
- Distinguish Error Categories: Treat recoverable operational errors (timeout, upstream 5xx) differently from non-recoverable programmer errors (null contract violations, assertion failures).
- Never expose internal stack traces or raw exception messages in API responses. Return structured error objects or appropriate HTTP status codes.

SOLID Design Principles:
- Single Responsibility (SRP): Each class has exactly one reason to change. Separate mapping logic, validation logic, and communication logic into distinct classes.
- Open/Closed (OCP): Extend behaviour by adding new implementations or strategies, not by modifying existing classes.
- Liskov Substitution (LSP): Subtypes must be fully substitutable for their base types without altering the correctness of the program.
- Interface Segregation (ISP): Define narrow, focused interfaces. Acquirer service handlers should implement only the methods relevant to their transaction type.
- Dependency Inversion (DIP): Depend on abstractions (interfaces), not concrete implementations. Inject dependencies via constructor rather than creating them inside the class.

Security:
- Secrets: Never hard-code credentials, API keys, passwords, or tokens in source code or configuration files. Always externalise to environment variables or a secrets manager.
- PCI / PII Data: Never log, serialise to disk, or include in error messages any card number (PAN), CVV, expiry date, or personally identifiable information.
- Input Validation: Validate and sanitise all incoming request fields before processing. Reject unexpected values early.
- TLS: Always enforce TLS for outbound connections. Do not disable certificate validation in non-local environments.
- Dependency Hygiene: Run mvn dependency:check and review transitive dependencies regularly. Address CRITICAL and HIGH CVEs before releasing.
- Log Hygiene: Redact or mask sensitive fields before writing to any log output. Apply SensitiveDataMasker or equivalent to all serialisers used in logging paths.

Testing:
- Coverage Targets: Aim for 80% or more line and branch coverage on business logic. Target 100% on utility, validation, and mapping classes.
- Test Naming: Use the pattern should<Behaviour>When<Condition> (e.g., shouldReturnDeclineWhenCardIsExpired).
- Arrange–Act–Assert (AAA): Structure every test with clear Arrange, Act, and Assert sections separated by blank lines.
- No Implementation Details: Test observable behaviour and return values, not internal method calls or field state.
- Mocking: Use Mockito for mocking dependencies. Do not make real network calls in unit tests. Use WireMock for HTTP interaction tests.
- Integration Tests: Keep in a separate module (e.g., libmpgs-*-integration-tests). Guard with a Maven profile or environment flag so they do not run in CI unit-test phases.
- Test Data: Use builder or factory methods for generating test fixtures. Avoid copying large inline JSON strings.
- Edge Cases: Always test null inputs, empty collections, maximum field lengths, boundary values, and error response paths.

Performance:
- Lazy Initialisation: Defer expensive setup (connection pool creation, remote client warm-up) until first use.
- Caching: Cache read-heavy, rarely changing data (acquirer configuration, field metadata) with a defined TTL. Always provide a cache-invalidation mechanism.
- Pagination: Never fetch unbounded result sets from downstream APIs. Always pass page size or limit parameters.
- Object Allocation: Avoid creating large intermediate collections in hot transaction paths. Prefer streaming or iterator-based processing.
- Connection Pooling: Configure and tune HTTP connection pools and thread pools explicitly. Do not rely on defaults in production.

Git and Version Control:
- Commit Format: Every commit message must follow the Mastercard format — <TICKET-ID>: <Short imperative description> (e.g., G1198-16490: Update circuit breaker threshold configuration).
- Atomic Commits: Each commit represents one logical change. Do not mix unrelated changes in a single commit.
- Branch Naming: Use feature/<TICKET-ID>_<SHORT_DESCRIPTION> (e.g., feature/G1198_18131_CHASE_TSPI_MASKING_LOGS, fix/G1198-17891-null-pointer-in-mapper).
- PR Size: Keep pull requests to 400 lines changed or fewer. Split larger changes into stacked PRs.
- No Secrets in History: If a secret is accidentally committed, rotate it immediately and rewrite history with git filter-repo.
- Pre-Commit: Ensure copyright header is present, code compiles (mvn clean compile -q), and unit tests pass (mvn test -q) before pushing.

Best Practices:
- Clarity over Cleverness: Write code that a new team member can understand on first read. Prefer explicit, readable logic over terse one-liners or language tricks that obscure intent.
- Right Abstraction at the Right Level: Introduce an abstraction only when it genuinely simplifies the calling code or enables a clear extension point. Premature abstraction adds indirection without value.
- Fail Loudly, Recover Gracefully: Surface unexpected states as loud errors close to their origin (assertions, typed exceptions, startup validation). Reserve silent fallbacks only for genuinely expected partial-degradation scenarios.
- Immutability by Default: Model all data carriers as immutable (Java records, final fields, List.copyOf). Introduce mutability only at explicit, documented service boundaries.
- Eliminate Duplication Purposefully: Remove duplication when a shared concept genuinely exists; tolerate duplication when two pieces of code that look alike are actually evolving in different directions.
- Keep Cyclomatic Complexity Low: Aim for a cyclomatic complexity of 5 or fewer per method. When logic branches multiply, extract decision tables, strategy implementations, or dedicated validator classes.
- Design for Testability from the Start: Structure every class so its dependencies can be injected and its behaviour verified without a running container. Testable code is a proxy for good design.
- Name Things After What They Do, Not How They Do It: Class and method names should describe intent and contract (ProcessPaymentRequest, resolveAcquirerRoute) rather than implementation detail (NodeIteratorHelper, StringParserV2).
- Centralise Cross-Cutting Concerns: Logging, metrics, retry, and correlation-ID propagation belong in a single place (interceptors, filters, AOP advisors) — not scattered across business classes.
- Dependency Minimalism: Before adding a library, verify it is not already available transitively and cannot be replaced by a standard library class. Every additional dependency is a future CVE, licence, and upgrade obligation.
- Prefer Configuration over Code for Variability: Externalise thresholds, timeouts, feature flags, and routing rules to properties or a config service. Code changes should not be required to adjust operational behaviour.
- Continuous Improvement over Big-Bang Refactors: Apply the Boy Scout Rule on every PR — leave one measurable improvement (rename, extract method, remove dead code) rather than deferring cleanup to a dedicated refactor sprint that never arrives.
