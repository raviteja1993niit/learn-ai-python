---
name: coding-style
description: >
  Auto-triggered skill that enforces Mastercard PGS coding-style rules on every modified Java file:
  copyright header, performance-first Java style (traditional or functional on demand, Java 8–17),
  Javadoc discipline, SonarQube-clean structure, naming conventions, SOLID principles, design
  patterns, backward-compatibility safety, and general maintainability.
  Reports findings to the calling agent without modifying files.
triggers:
  - onFileWrite
  - onPhaseStart phase=4
  - onPhaseStart phase=5
---

# Skill: Coding Style

## Purpose

Enforce Mastercard PGS project-specific coding-style rules automatically whenever a Java file is
written or modified. Provide early, actionable feedback during development (Phase 4) and
supplement the SonarQube gate in Phase 5 before issues reach formal code review.

---

## Trigger Conditions

- Triggered after every `skill:write-file` that modifies a `.java` file
- Triggered at the start of Phase 4 (Code Development) and Phase 5 (Code Review)
- Can be explicitly invoked: check coding style for `<file>`

---

## Rules

---

### 1. Mastercard Copyright Header

**Every `.java` source file must open with the Mastercard copyright block, placed before the
`package` declaration.**

- **Required format:**
  ```java
  /*
   * Copyright (c) <YEAR> Mastercard. All rights reserved.
   */
  ```
- Use the **current four-digit calendar year** at the time the file is created (e.g., `2026`).
- The year must **never be changed** once set; do not alter an existing copyright on edits.
- Apply to `.java` files **only** — never add to XML, YAML, JSON, properties, or Markdown files.
- Flag as **BLOCKER** if the copyright block is absent or malformed.
- Flag as **INFO** if the year differs from the file-creation year (do not auto-correct).

---

### 2. Java Style — Traditional vs. Functional: Choose for Performance & Simplicity

**Choose the style that is simpler, more readable, and more performant for the specific context —
not the one that looks more modern. Neither functional nor traditional style is universally
preferred; apply the right tool for the job.**

#### When to use Functional / Stream style

- **Use Streams** when transforming, filtering, or collecting a collection in a single logical
  pipeline where the intent is immediately clear:
  - ✅ `list.stream().filter(Objects::nonNull).map(Mapper::convert).toList()`
  - ✅ `map.entrySet().stream().filter(e -> e.getValue() > 0).collect(toMap(...))`
- **Use method references** (`Class::method`) to replace trivial lambdas where it improves
  readability, not as a default habit.
- **Use `Optional`** as a return type from `public` methods where a result may be absent.
  Never return `null`. Prefer `orElseThrow()` or `orElse()` — never call `Optional.get()`
  without `isPresent()`.
- **Use switch expressions** (arrow form, Java 14+) when assigning a value based on a finite
  set of cases — cleaner and exhaustiveness-checked:
  - ✅ `String label = switch (type) { case AUTH -> "A"; case VOID -> "V"; };`

#### When to use Traditional / Imperative style

- **Use a plain `for` loop** when:
  - The loop body has side effects (e.g., mutating state, accumulating with early exit).
  - Early `break` or `continue` makes the logic significantly simpler.
  - Performance is critical and stream overhead (boxing, lambda allocation) is measurable.
  - ✅ `for (Transaction tx : transactions) { if (tx.isFailed()) { retryQueue.add(tx); break; } }`
- **Use `for` with index** when the position matters (e.g., ISO 8583 field-by-index processing).
- **Use `try-with-resources`** (traditional block) for I/O — never wrap resource management
  in a stream pipeline.
- **Keep imperative code when a stream version would require multiple intermediate variables,
  nested collectors, or a helper method just to fit the stream model** — that is a signal that
  the traditional loop is the right choice.

#### Performance Guidance

- Avoid creating unnecessary intermediate `Stream` objects in hot transaction paths
  (high-frequency ISO 8583 processing, per-request loops).
- Prefer `List.of()`, `Set.of()`, `Map.of()` for small, fixed collections — they are more
  memory-efficient than `ArrayList` / `HashMap` for read-only use.
- Use `Map.getOrDefault()` or `Map.computeIfAbsent()` over repeated `containsKey` + `put`.
- Never use parallel streams unless there is a measured throughput bottleneck and thread-safety
  is guaranteed. Default to sequential.

#### Modern Java Features — Use Where They Simplify

- **Records** — use for immutable data carriers in place of manual POJOs with boilerplate
  `equals`, `hashCode`, `toString`.
- **Sealed classes** — use for closed type hierarchies where exhaustiveness matters.
- **Pattern matching `instanceof`** — eliminates cast-after-check boilerplate:
  - ✅ `if (obj instanceof String s) { use(s); }`
  - ❌ `if (obj instanceof String) { String s = (String) obj; use(s); }`
- **`var`** — use for local variables when the type is obvious from the right-hand side.
  Avoid where it hides the type and forces the reader to infer it.

#### Decision Rule

> **If two implementations are equal in clarity, prefer the one with lower overhead.
> If two implementations are equal in performance, prefer the one that is easier to read and
> maintain. Never sacrifice simplicity for style.**

- Flag as **HIGH** when a clearly simpler or more performant idiom exists and was not used.
- Flag as **MEDIUM** when a stream pipeline is used for a single-element operation or where a
  plain `if`/loop is obviously more readable.
- Flag as **LOW** for stylistic stream-vs-loop disagreements with no measurable difference.

---

### 2b. Lombok — Reduce Boilerplate Deliberately

**Use Lombok to eliminate mechanical boilerplate. Apply it consistently; never mix manual and
generated code for the same concern.**

#### When to use Lombok

| Annotation | Use when |
|-----------|---------|
| `@Getter` | Any `private final` (or non-final) field that has a plain `return field;` getter. Apply per-field on enums; apply at class level on POJOs/records where all fields need getters. |
| `@Setter` | Non-final fields that have a plain `this.x = x;` setter. Never on `final` fields. |
| `@RequiredArgsConstructor` | Classes with only `private final` fields that must be constructor-injected (Spring beans, service classes). Removes the explicit constructor entirely. |
| `@AllArgsConstructor` | Value objects / test-data builders where every field must be supplied at construction. |
| `@Builder` | Classes with ≥ 4 fields where named construction improves readability over positional args. Pair with `@AllArgsConstructor(access = AccessLevel.PRIVATE)`. |
| `@Data` | Simple POJO data carriers with mutable fields — **never on JPA `@Entity` classes**. |
| `@Value` | Immutable value objects — generates `private final` fields, `@AllArgsConstructor`, `@Getter`, and `equals`/`hashCode`/`toString`. Prefer over `@Data` for immutable types. |
| `@Slf4j` | Any class that needs a logger — replaces `private static final Logger log = ...`. |
| `@UtilityClass` | Utility classes with only `static` members — makes constructor private and marks class `final`. |

#### Enum-specific rule

- Use `@Getter` **per field** on enum fields that have a plain getter — do not write the
  getter manually.
  - ✅ `@Getter private final String description;` → Lombok generates `getDescription()`
  - ❌ Manual `public String getDescription() { return description; }` when field is trivial.
- Only keep a manual method when the return value is **computed** (not a plain field read):
  - ✅ Keep manual: `public String getLabel() { return code + " – " + name; }` (computed)
  - ❌ Remove manual: `public String getCode() { return code; }` (plain field read → use `@Getter`)

#### When NOT to use Lombok

| Scenario | Reason |
|---------|--------|
| `@Data` on a JPA `@Entity` | Generates `equals`/`hashCode` on mutable state — breaks JPA dirty-checking. |
| `@Setter` on a `final` field | Does not compile; Lombok will not generate it. |
| `@RequiredArgsConstructor` when the class has `@PostConstruct` or circular deps | Spring may not resolve the bean correctly. Use explicit constructor. |
| `@Builder` on a class that already uses `@Value` or `@Data` | Redundant — combine with `@Builder` annotation directly. |
| Any Lombok on a `record` | Records already generate all accessors and canonical constructors. |

#### Flag Conditions

- Flag as **HIGH** for a manual `getX()` / `setX()` that is a plain field read/write when
  `@Getter` / `@Setter` would suffice — creates unnecessary lines and diverges from project style.
- Flag as **MEDIUM** for missing `@Slf4j` when a `private static final Logger` is declared
  manually.
- Flag as **MEDIUM** for `@Data` applied to a JPA `@Entity`.
- Flag as **LOW** for a constructor that `@RequiredArgsConstructor` would replace with no
  behavioural difference.

---

### 3. Javadoc & Comment Discipline

**Keep documentation professional, minimal, and purposeful — avoid noise.**

#### Where to add Javadoc / comments

- **Required Javadoc targets — business logic only:**
  - Every `public` class or `interface` that contains business logic — one-sentence description.
  - `public` methods that have a non-trivial contract, edge cases, or checked exceptions.
  - Private helpers that implement a meaningful algorithm or decision (e.g., shared
    `Consumer<MutableInteraction>` builders, flow-derivation helpers).
  - `@param` and `@return` only when the type and name alone do not make the intent obvious.
  - `@throws` for every checked exception declared in the signature.
- **Compact format for helpers:** prefer the inline `/** @return ... */` form for simple
  private helpers whose body is self-explanatory:
  - ✅ `/** @return shared void-auth CPC/CONNECTIVITY response consumer. */`

#### Where NOT to add Javadoc / comments — no-comment zones

The following elements must **never** carry Javadoc or inline comments unless the value or
name alone is genuinely non-obvious:

| Element | Rule |
|---------|------|
| Simple getters (`return field;`) | No Javadoc. Name + return type is sufficient. |
| Simple setters (`this.x = x;`) | No Javadoc. |
| `public static final` constants | No Javadoc. Name must be self-documenting. |
| Local variables | No inline comment unless the assignment reason is non-obvious. |
| Enum accessors (`getDescription()`, `getCode()`) | No Javadoc — trivial accessors. |
| `@param` restating the parameter name | Forbidden — adds zero value. |

- ❌ `/** Returns the description. */ public String getDescription()` — noise stub, remove it.
- ❌ `/** The CVV tag constant. */ public static final String CVV_TAG = "cvv";` — remove.
- ❌ `// set the expiry field` before `flow.update(ACQ_FIELD_EXPIRY, ...)` — describes *what*.
- ✅ `// WorldPay mirrors this pattern — common fields centralised in the model helper.` — explains *why*.

#### Inline comment discipline

- Allowed: explain *why* a non-obvious design decision was made, reference ATF migration rules,
  or annotate a known constraint.
- `// TODO(TICKET-ID): ...` and `// FIXME(TICKET-ID): ...` require a Jira ticket reference.
- Migration notes (`// Migrated from: ...`) belong as a single inline comment on the class,
  **not** in the class-level Javadoc block.

#### Flag conditions

- Flag as **MEDIUM** for Javadoc on a simple getter, setter, constant, or local variable.
- Flag as **MEDIUM** for missing Javadoc on a complex public business-logic method.
- Flag as **MEDIUM** for excessive/noisy Javadoc that restates the method name.
- Flag as **LOW** for `TODO`/`FIXME` missing a Jira ticket reference.

---

### 4. SonarQube-Clean & Modular Structure

**Write code that passes SonarQube Quality Gate with zero critical or major issues.**

- **Method length** — aim for ≤ 30 lines. Extract private helper methods when a method grows
  beyond this. Methods > 50 lines are a blocker.
- **Cyclomatic complexity** — target ≤ 5 per method; ≤ 10 is the hard limit. Refactor using
  guard clauses, strategy pattern, or extracted decision methods.
- **Nesting depth** — maximum 3 levels of indentation in logic blocks. Use early returns and
  guard clauses to flatten structure.
- **Code duplication** — no copy-paste blocks of > 5 lines. Extract shared logic into a utility
  or abstract method.
- **Reusable interaction helpers** — in test-data model and scenario classes, identical
  `rq(...)`/`rs(...)` blocks applied to multiple interactions (e.g., CPC and CONNECTIVITY)
  **must** be extracted into a private `static` method returning `Consumer<MutableInteraction>`.
  Apply this rule whenever the same `rq`/`rs` call appears ≥ 2 times:
  - ✅ Extract `buildTimedOutResponse()` → call from both `.update(CPC, ...)` and
    `.update(CONNECTIVITY, ...)`.
  - ❌ Copy-paste the same 10-field `rs(...)` block verbatim for CPC then CONNECTIVITY.
  - The helper name must express intent, not implementation:
    `buildAmexCpcRequest(scenario)` ✅ — `buildRq(...)` ❌.
- **Modular test-data builders** — scenario enums must delegate all layer-specific field
  assembly to named private helpers. The constructor lambda body should read as a high-level
  orchestration of `update(LAYER, request, response)` calls, not as inline field lists.
  Keep each named helper focused on a single interaction layer and scenario variant.
- **Dead code** — remove unused `import`, unused private methods, unused variables, and
  unreachable branches. SonarQube flags these as issues.
- **Unused constants in shared constant files** — before removing a `public static final`
  constant flagged as unused by the IDE, verify it is not referenced in **any** `.java` file
  across the entire module (not just the file under review). Use a workspace-wide search for
  the constant name. Apply the following decision table:

  | Condition | Action |
  |-----------|--------|
  | Not referenced in any `.java` file in the module | **Remove** — dead code, Rule 4 violation |
  | Referenced only via a wildcard `static import .*` from a **different** class with the same name | Verify which class the reference resolves to; remove if this class's version is shadowed |
  | Referenced in a scenario/model class for an **upcoming** story in the same sprint | **Keep** with a `// TODO(TICKET-ID): used by <StoryID>` inline comment |
  | Referenced in an **integration test** or **simulation** module | **Keep** — cross-module usage counts |

  Flag as **MEDIUM** for a confirmed-unused `public static final` constant with no `TODO`
  ticket reference explaining why it is retained.
- **Exception handling** — never swallow exceptions in an empty `catch` block. Never catch raw
  `Exception` or `Throwable` except at a top-level boundary handler. Every `catch` must log,
  rethrow, or convert to a domain exception.
- **Layer separation** — controller/handler logic, service/business logic, and
  data-access/mapping code must reside in separate classes. No business logic in mappers;
  no HTTP concerns in services.
- **Single Responsibility** — each class has exactly one reason to change. A class doing mapping
  AND validation AND HTTP calls is a SonarQube smell and a design violation.
- **Magic numbers/strings** — extract to named `static final` constants or configuration
  properties. No inline literals for codes, limits, or identifiers.
- Flag as **BLOCKER** for method > 50 lines or cyclomatic complexity > 10.
- Flag as **HIGH** for empty catch blocks, swallowed exceptions, or mixed-layer responsibilities.
- Flag as **MEDIUM** for dead code, magic literals, or minor duplication.

---

### 5. Naming Conventions & Maintainability

**Write code a new team member can understand on first read.**

- **Classes & Interfaces** — PascalCase, named after what they *do* or *represent*:
  `ElavonRequestMapper`, `AcquirerCircuitBreakerConfig`. Avoid generic suffixes like `Helper`,
  `Manager`, `Util` unless genuinely appropriate.
- **Methods** — camelCase, verb-first, named after *intent* not *implementation*:
  `buildAuthRequest()`, `resolveAcquirerRoute()`. Not: `doStuff()`, `process2()`.
- **Variables** — camelCase, descriptive, scoped as tightly as possible. Prefer `final` for
  variables not reassigned.
- **Constants** — `static final` fields in UPPER_SNAKE_CASE: `MAX_RETRY_ATTEMPTS`,
  `DEFAULT_TIMEOUT_MS`.
- **Boolean fields/methods** — prefix with `is`, `has`, `can`, or `should`:
  `isMutualAuthEnabled`, `hasValidCredentials`, `shouldRetry`.
- **Packages** — lowercase, reverse-domain, following module conventions:
  `com.mastercard.pgs.connectivity.acquirer.elavon.<layer>` (e.g., `config`, `mapping`,
  `service`, `handler`, `validation`, `exception`, `util`).
- **Test classes** — mirror the class under test with a `Test` suffix:
  `ElavonRequestMapperTest`, `CVVScenarioValidatorTest`.
- **Test methods** — `should<Behaviour>When<Condition>`:
  `shouldReturnDeclineWhenCVVIsInvalid`.
- **Enums** — PascalCase name, UPPER_SNAKE_CASE members:
  `enum TransactionType { AUTHORISATION, REVERSAL }`.
- **Avoid** abbreviations, single-letter names (except loop counters `i`, `j`), and
  misleading names that don't match the actual behaviour.
- Flag as **HIGH** for class or method names that obscure intent.
- Flag as **MEDIUM** for inconsistent casing or non-standard package names.
- Flag as **LOW** for minor naming improvements (abbreviations, ambiguous names).

---

### 6. Backward Compatibility — Do Not Break Existing Functionality

**Every change must leave all existing behaviour intact unless a breaking change is explicitly
required, documented, and approved.**

#### General Safety Rules

- **Never remove or rename a `public` or `protected` method, field, or class** that is used
  by other modules without a deprecation cycle:
  - Step 1 — mark the old element `@Deprecated` with a Javadoc `@deprecated` note pointing to
    the replacement.
  - Step 2 — introduce the new element alongside the old one.
  - Step 3 — remove the deprecated element only in a subsequent, clearly scoped PR.
- **Never change a method signature** (parameter types, order, return type) in a `public` API
  without introducing an overload and deprecating the old form first.
- **Never silently change default values** of configuration properties, timeouts, or feature
  flags — treat them as a public contract; use versioned property keys when defaults must change.
- **Never alter the behaviour of an existing code path** as a side effect of adding a new
  feature. New behaviour must be gated behind a new method, a new configuration flag, or a
  new implementation of an interface.

#### Refactoring Safety

- **Refactor in isolation** — a PR that restructures code (rename, extract method, move class)
  must not simultaneously change business logic. Keep structural and behavioural changes in
  separate commits.
- **Preserve observable outputs** — after any refactor, all existing unit and integration tests
  must pass without modification to assertions. Changing a test's assertion to make a refactor
  pass is a red flag.
- **Do not delete test cases** to make a build pass. If a test fails after a change, fix the
  code, not the test.
- **Verify downstream modules** — in a multi-module Maven project (`lib-elavon-interface-*`),
  confirm that changes to a shared library module do not break the service module or test
  modules by running `mvn clean install` from the root before raising a PR.

#### Flag Conditions

- Flag as **BLOCKER** for removal of a `public` API element without a deprecation cycle.
- Flag as **BLOCKER** for a signature change that silently breaks callers in other modules.
- Flag as **HIGH** for a default value change in configuration without versioning or a flag.
- Flag as **HIGH** for mixed refactor + behaviour change in a single commit.
- Flag as **MEDIUM** for `@Deprecated` elements missing a Javadoc replacement note.

---

### 7. SOLID Principles & Design Patterns

**Apply SOLID principles and established design patterns to produce code that is maintainable,
extensible, and testable without over-engineering.**

#### SOLID Principles

- **Single Responsibility (SRP)**
  - Each class has exactly one reason to change.
  - Separate mapping logic, validation logic, service orchestration, and HTTP/TCP communication
    into distinct classes.
  - ✅ `ElavonRequestMapper` maps; `ElavonRequestValidator` validates; `ElavonTcpClient` sends.
  - ❌ A single class that builds, validates, sends, and logs a request.
  - Flag as **HIGH** when a class mixes two or more unrelated responsibilities.

- **Open/Closed (OCP)**
  - Classes should be open for extension, closed for modification.
  - Introduce new transaction types, acquirer variants, or response strategies by adding a new
    implementation or strategy — not by adding `if/else` branches inside existing classes.
  - ✅ New acquirer behaviour → new class implementing existing interface.
  - ❌ Adding `if (acquirerType == ELAVON_V2)` inside an existing handler.
  - Flag as **HIGH** when an existing class is modified to add a new case that could be a
    new strategy or subtype.

- **Liskov Substitution (LSP)**
  - Subtypes must be fully substitutable for their base type without altering program
    correctness.
  - Overriding methods must honour the contract of the parent — do not throw unexpected
    exceptions, do not return `null` where a value is guaranteed, do not ignore parameters
    that the parent respects.
  - Flag as **HIGH** for overrides that weaken the parent contract (narrowing accepted input,
    broadening thrown exceptions, returning `null` where parent never does).

- **Interface Segregation (ISP)**
  - Define narrow, focused interfaces. Do not force implementors to depend on methods they
    do not use.
  - Prefer multiple small interfaces over one large `AcquirerService` with 15 methods.
  - ✅ `AuthorisationHandler`, `ReversalHandler`, `SettlementHandler` as separate interfaces.
  - ❌ One interface with `authorise()`, `reverse()`, `settle()`, `healthCheck()`,
    `getConfig()` all required together.
  - Flag as **MEDIUM** when an interface has > 5 unrelated method signatures.

- **Dependency Inversion (DIP)**
  - Depend on abstractions (interfaces), not concrete implementations.
  - Inject dependencies via constructor — never instantiate collaborators with `new` inside
    a service or handler class.
  - ✅ `private final ElavonClient client;` injected via constructor.
  - ❌ `private final ElavonClient client = new ElavonTcpClient(...);` inside a service.
  - Flag as **HIGH** for `new ConcreteService()` inside a Spring-managed bean.
  - Flag as **HIGH** for field-level `@Autowired` (use constructor injection instead).

#### Design Patterns — Apply When They Solve a Real Problem

Use patterns to eliminate concrete duplication or complexity — never for ceremony:

| Pattern | When to Apply |
|---------|--------------|
| **Strategy** | Multiple algorithms/behaviours that vary independently (e.g., different acquirer routing rules, different response code mappings). Replaces `if/else` or `switch` chains that grow with new cases. |
| **Builder** | Constructing complex objects with many optional fields (e.g., ISO 8583 request assembly). Use Lombok `@Builder` where appropriate. |
| **Factory / Factory Method** | Creating objects whose concrete type is determined at runtime (e.g., selecting the correct request builder based on transaction type). |
| **Adapter** | Bridging incompatible interfaces between internal models and external acquirer protocols (e.g., wrapping Elavon TCP response into internal `AcquirerResponse`). |
| **Template Method** | Defining a fixed processing skeleton with variable steps (e.g., a base `AbstractTransactionHandler` that defines the flow, with subclasses filling in type-specific steps). |
| **Decorator** | Adding cross-cutting behaviour (logging, metrics, retry) to an existing object without modifying it. Prefer Spring AOP or Resilience4j annotations over manual decoration. |
| **Null Object** | Returning a safe default implementation instead of `null` to avoid null checks at every call site. |

#### Pattern Anti-Patterns to Avoid

- **Do not introduce a pattern** because it looks professional — only when it removes a real
  pain point (duplication, rigid branching, tight coupling).
- **Do not create abstract base classes** unless at least two concrete subtypes exist and share
  genuine behaviour.
- **Do not use Singleton manually** — use Spring's default singleton bean scope instead.
- **Do not chain more than 3 decorators** without documenting the order and interaction.

#### Flag Conditions

- Flag as **HIGH** for `new ConcreteClass()` inside a Spring bean violating DIP.
- Flag as **HIGH** for an `if/else` chain of > 3 cases that should be a Strategy or Factory.
- Flag as **HIGH** for a class violating SRP by mixing concerns from different layers.
- Flag as **MEDIUM** for a bloated interface violating ISP.
- Flag as **MEDIUM** for a pattern introduced without a clear justification
  (over-engineering signal).
- Flag as **LOW** for missed opportunities to apply a pattern that would modestly simplify
  existing code.

---

## Output Format

```
[CODING STYLE] <file>:<line>
  Severity : BLOCKER | HIGH | MEDIUM | LOW | INFO
  Rule     : <Rule number and name>  (e.g., Rule 1 – Copyright Header)
  Finding  : <Concise description of the violation>
  Fix      : <Concrete recommended action>
```

Multiple findings are reported individually, ordered by severity (BLOCKER first).

---

## Behaviour

- Reports findings inline to the calling agent.
- Does **NOT** automatically modify files.
- **BLOCKER** findings (missing copyright, method > 50 lines, complexity > 10, broken public
  API without deprecation cycle) must be resolved before Phase 5 PASS can be issued.
- **HIGH** findings (SOLID violations, DIP breaches, backward-compatibility breaks, mixed
  refactor + behaviour change) must be addressed before merge.
- **MEDIUM** and **LOW** findings are included in improvement suggestions and should be resolved
  in the same PR where practical (Boy Scout Rule).
- **INFO** findings are advisory only and do not block merge.
- Rules are applied in order: **1 → 2 → 3 → 4 → 5 → 6 → 7**. A BLOCKER from Rule 1 or 6
  does not suppress remaining rule checks — all rules are always evaluated.
