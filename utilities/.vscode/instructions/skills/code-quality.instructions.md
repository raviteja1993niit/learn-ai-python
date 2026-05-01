---
applyTo: '**/*.java'
description: >
  Auto-triggered skill for code quality checks on modified Java files: method length,
  cyclomatic complexity, naming, imports, Javadoc completeness, Lombok, and collections.
  Reports findings; does not modify files.
---

# Code Quality — Skill

## Trigger Conditions
- Every `.java` file write
- Phase 5 (Code Review) start
- Explicitly: "check code quality for `<file>`"

---

## Checks

### Method Quality

| Check | Threshold | Severity |
|-------|----------|----------|
| Method length | > 30 lines: warn; > 50 lines: error | HIGH |
| Cyclomatic complexity | > 5: warn; > 10: error | HIGH |
| Nesting depth | > 3 levels | MEDIUM |
| Parameter count | > 5 | MEDIUM |

### Naming Conventions
- Classes/Interfaces: PascalCase
- Methods/variables: camelCase
- Constants (`static final`): UPPER_SNAKE_CASE
- Boolean fields: `is`, `has`, `can`, `should` prefix
- Test methods: `should<Behaviour>When<Condition>`

### Import Ordering
Order: `java.*` → `javax.*`/`jakarta.*` → `org.springframework.*` → `com.mastercard.*` → other.
Flag unsorted groups or wildcard imports.

### Copyright Header
Every `.java` file must start with Mastercard copyright block before `package` declaration.

### Javadoc
Required on `public` classes with business logic and non-trivial `public` methods.
Forbidden on simple getters/setters, constants, and trivial enum accessors.

### Lombok Usage
- Warn: `@Data` on a JPA `@Entity` class
- Warn: field-level `@Autowired`

### Collections & Optionals
- Warn: method returning `null` where `Optional<T>` or empty collection is expected
- Warn: `Optional.get()` without `isPresent()` guard

---

## Output Format

```
[CODE QUALITY] <file>:<line>
  Severity : HIGH | MEDIUM | LOW
  Rule     : <Rule name>
  Finding  : <Description>
  Fix      : <Recommended change>
```

HIGH must be fixed before commit. MEDIUM before Phase 5 PASS.
