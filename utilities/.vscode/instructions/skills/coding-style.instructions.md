---
applyTo: '**/*.java'
description: >
  Mastercard PGS coding-style rules for Java files. Auto-checked on every file write,
  Phase 4 start (Code Development), and Phase 5 start (Code Review).
  Reports findings; does not modify files automatically.
---

# Coding Style — Mastercard PGS Skill

## Trigger Conditions
- Every `.java` file write
- Phase 4 (Code Development) start
- Phase 5 (Code Review) start

---

## Rules

### 1. Copyright Header — BLOCKER if missing

```java
/*
 * Copyright (c) <YEAR> Mastercard. All rights reserved.
 */
```
- Before `package` declaration on every new `.java` file
- Use **current year** at file creation; never change it on edits
- `.java` files **only** — not XML, YAML, JSON, Markdown

---

### 2. Java Style — Performance-First, Not Trend-First

**Use Streams when:** transforming/filtering a collection in a single clear pipeline.

**Use traditional loops when:**
- Loop body has side effects or early `break`/`continue`
- ISO 8583 field-by-index processing
- Performance is critical (hot path)

**Use `Optional`:** as return type when result may be absent — never return `null`.

**Switch expressions** (Java 14+): use arrow form for value assignment.

---

### 3. Javadoc Discipline

**Required (MEDIUM if missing):**
- Every `public` class/interface with business logic (one-sentence minimum)
- `public` methods with non-trivial contracts or checked exceptions

**Forbidden (MEDIUM if present):**
- Simple getters/setters (`return field;`)
- `public static final` constants
- `@param` that merely restates the parameter name
- Enum accessors (`getCode()`, `getDescription()`)

---

### 4. SonarQube-Clean Structure

| Check | Threshold | Severity |
|-------|----------|----------|
| Method length | > 30 lines: warn; > 50 lines: error | HIGH |
| Cyclomatic complexity | > 5: warn; > 10: error | HIGH |
| Nesting depth | > 3 levels | MEDIUM |
| Parameter count | > 5 | MEDIUM |

No `System.out.println`, no `printStackTrace()`, no empty `catch` blocks.

---

### 5. Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes/Interfaces | PascalCase | `AcquirerRequestHandler` |
| Methods/variables | camelCase | `buildRequest()` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES` |
| Booleans | is/has/can/should prefix | `isOnline` |
| Test methods | `should<Behaviour>When<Condition>` | `shouldReturnApprovedWhenCardValid` |

---

### 6. SOLID Principles

- **SRP**: one class, one responsibility; split service, mapper, validator
- **OCP**: use strategy/template method for varying behaviour
- **DI**: constructor injection (`@RequiredArgsConstructor`), never field `@Autowired`
- **ISP**: small, focused interfaces; avoid "god" interfaces

---

### 7. Backward-Compatibility Safety

- Never remove or rename `public`/`protected` methods without deprecation cycle
- Use `@Deprecated` + Javadoc pointing to replacement
- Include Jira ticket in `// TODO(JIRA-ID): ...` comments

---

## Output Format

```
[CODING STYLE] <file>:<line>
  Severity : BLOCKER | HIGH | MEDIUM | LOW | INFO
  Rule     : <Rule name>
  Finding  : <Description>
  Fix      : <Recommended change>
```

BLOCKER/HIGH must be resolved before commit. MEDIUM before Phase 5 PASS.
