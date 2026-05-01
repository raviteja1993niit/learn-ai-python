---
name: code-quality
description: >
  Auto-triggered skill that checks code quality patterns in modified Java files: method length,
  cyclomatic complexity, naming conventions, import ordering, and Javadoc completeness. Reports
  findings to the calling agent without modifying files.
triggers:
  - onFileWrite
  - onPhaseStart phase=5
---

# Skill: Code Quality

## Purpose

Automatically verify that modified Java files conform to project coding standards every time
a file is written. Supplement the SonarQube scan in Phase 5 with immediate inline feedback
during development (Phase 4), allowing issues to be caught before the formal review cycle.

---

## Trigger Conditions

- Triggered after every `skill:write-file` that modifies a `.java` file
- Triggered at the start of Phase 5 (Code Review) as a supplementary scan
- Can be explicitly invoked: check code quality for `<file>`

---

## Checks Performed

### Method Quality

| Check | Threshold | Severity |
|-------|----------|----------|
| Method length | > 30 lines → warn; > 50 lines → error | HIGH |
| Cyclomatic complexity | > 5 → warn; > 10 → error | HIGH |
| Nesting depth | > 3 levels → warn | MEDIUM |
| Parameter count | > 5 parameters → warn | MEDIUM |

### Naming Conventions

- Classes/Interfaces: PascalCase
- Methods/variables: camelCase
- Constants (`static final`): UPPER_SNAKE_CASE
- Boolean fields: prefixed with `is`, `has`, `can`, `should`
- Test methods: `should<Behaviour>When<Condition>` pattern

### Import Ordering

Verify order: `java.*` → `javax.*`/`jakarta.*` → `org.springframework.*` → `com.mastercard.*` → other.
Flag unsorted groups or wildcard imports.

### Copyright Header

Verify every `.java` file starts with the Mastercard copyright block before the package declaration.

### Javadoc

**Add Javadoc only on business-logic classes and methods. Never add it on trivial elements.**

#### Required (flag MEDIUM if missing)

- Every `public` class or interface containing business logic: at least one-sentence description.
- `public` methods with a non-trivial contract, parameters whose purpose is not obvious from
  the name, or declared checked exceptions (`@throws`).
- Private helpers that implement a meaningful algorithm or shared interaction builder.

#### Forbidden — no-comment zones (flag MEDIUM if present)

| Element | Why no comment |
|---------|---------------|
| Simple getters (`return field;`) | Name + return type is self-documenting. |
| Simple setters (`this.x = x;`) | Assignment intent is obvious. |
| `public static final` constants | Constant name must be self-documenting; no Javadoc. |
| Local variables | No inline comment unless the assignment reason is non-obvious. |
| Enum accessors (`getCode()`, `getDescription()`) | Trivial — name says it all. |
| `@param` that merely restates the parameter name | Zero-value noise — remove it. |

### Lombok Usage

- Warn on `@Data` applied to a JPA `@Entity` class
- Warn on field-level `@Autowired`

### Collections & Optionals

- Warn on method returning `null` where `Optional<T>` or empty collection is expected
- Warn on `Optional.get()` without prior `isPresent()` guard or `orElse`/`orElseThrow`

---

## Output Format

```
[CODE QUALITY] <file>:<line>
  Severity : HIGH | MEDIUM | LOW
  Rule     : <Rule name>
  Finding  : <Description>
  Fix      : <Recommended change>
```

---

## Behaviour

- Reports findings inline to the calling agent
- Does NOT automatically modify files
- HIGH findings are expected to be fixed before the code is committed
- MEDIUM findings must be addressed before Phase 5 PASS can be issued
- LOW findings are included in `review-<story-id>.md` improvement suggestions
