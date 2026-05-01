# Coding Standards — Java 17 / Spring Boot 3.x

## Language & Version

- Target: **Java 17** — use language features: records, sealed classes, pattern matching for `instanceof`, text blocks
- Framework: **Spring Boot 3.x** — use Jakarta EE namespace (`jakarta.*`)
- Build: **Maven multi-module**; no Gradle

## Base Package

All generated code must start with `com.mastercard.pgs` or `com.mastercard.gateway.acquiring`,
matching the module being extended.

## Copyright Header

Every new `.java` file must begin with (before the package declaration):

```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
```

Apply to `.java` files **only**. Never add to XML, YAML, properties, JSON, or Markdown.

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Classes / Interfaces | PascalCase | `CapInterfaceService` |
| Methods / Variables | camelCase | `buildRequest()`, `transactionContext` |
| Constants (`static final`) | UPPER_SNAKE_CASE | `MAX_RETRIES` |
| Packages | lowercase reverse-domain | `com.mastercard.pgs.connectivity.acquirer.chase` |
| Booleans | `is` / `has` / `can` / `should` prefix | `isOnline`, `hasValidCredentials` |
| Enums | PascalCase name, UPPER_SNAKE_CASE members | `enum TransactionType { AUTHORISATION, REVERSAL }` |
| Test Classes | Mirror + `Test` suffix | `ChasePaymentechMapperTest` |
| Source Files | One public class per file; file name = class name | |

## Formatting

- Indent: **4 spaces** (no tabs)
- Brace style: opening `{` on the **same line**; always use braces even for single-line `if`/`for` bodies
- Line length: **80–120 characters** — break long chains/arguments with consistent alignment
- Spaces around operators, after commas, between keywords and parentheses
- No trailing whitespace; one blank line at end of every file
- One blank line between methods; two blank lines between top-level declarations

## Import Ordering

1. `java.*` standard library
2. `javax.*` / `jakarta.*`
3. `org.springframework.*`
4. `com.mastercard.*`
5. Other third-party libraries

Separate each group with a blank line. Sort alphabetically within groups. **No wildcard imports.**

## Spring Boot Practices

- **Constructor injection** only — no `@Autowired` on fields
- `@Configuration` + `@Bean` for explicit wiring
- `@Value` for simple scalar properties; `@ConfigurationProperties` for grouped config
- Prefer `@Slf4j` (Lombok) — parameterised log messages only: `log.info("Processing {}", id)`
- Never string-concatenate log messages; never log PAN, CVV, PII, passwords, tokens

## Immutability & Collections

- Prefer `final` fields; constructor injection; avoid mutable shared state
- Return `Optional<T>` instead of `null` from public methods; never `Optional.get()` without guard
- Return **empty collections**, not `null` — use `List.of()`, `Map.of()`, `Set.of()` for immutable
- Use Streams and functional operations for data transformation; avoid side effects in stream pipelines

## Lombok

Use `@Data`, `@Builder`, `@RequiredArgsConstructor`, `@Slf4j` judiciously.
**Do NOT use `@Data` on JPA entities.**

## Annotations

Place each annotation on its own line immediately above the annotated element.

## Method Design

- Method length: **≤ 30 lines**; extract private helpers when growing beyond that
- Cyclomatic complexity: **≤ 5** per method
- Guard clauses / early returns: validate inputs and return/throw early to reduce nesting
- Max nesting depth: **3 levels** — refactor using extracted methods or guard clauses

## Exceptions

- Define domain-specific exceptions extending `RuntimeException` with meaningful message + cause
- Never `catch (Exception e)` or `catch (Throwable t)` unless at a top-level boundary handler
- Every `catch` block must log, rethrow, or convert — no silent catches
- Never expose internal stack traces or raw exception messages in API responses

## Logging

- Use **SLF4J + Logback** via `@Slf4j`
- Always use parameterised messages: `log.info("Event {} for story {}", event, storyId)`
- **Never log**: PAN, CVV, expiry date, passwords, API keys, PII, session tokens

## Layer Separation

- Controller / handler logic → `controller` / `handler` package
- Service / business logic → `service` package
- Data-access / API-client code → `client` / `repository` package
- Package structure: `config`, `converter`, `mapping`, `validation`, `service`, `exception`, `util`
