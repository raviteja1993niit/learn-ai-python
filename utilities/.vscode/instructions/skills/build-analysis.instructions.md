---
applyTo: '**'
description: >
  Auto-triggered skill that parses Jenkins CI build logs and Maven output to classify
  failure types, identify root causes, and suggest targeted fixes.
  Invoked by the Build Fix Agent (Phase 7).
---

# Build Analysis — Skill

## Trigger Conditions
- Phase 7 (Build Fix Agent) start
- Explicitly: "analyse build log for story `<STORY-ID>`"

---

## Failure Classification

For each failure, assign exactly one type:

| Type | Key Log Patterns | Fix Approach |
|------|-----------------|-------------|
| `COMPILATION` | `cannot find symbol`, `package does not exist`, `incompatible types` | Fix import, method signature, or missing class |
| `UNIT_TEST_FAILURE` | `Tests run: N, Failures: N`, `AssertionFailedError` | Fix logic error or update assertion/test data |
| `INTEGRATION_TEST_FAILURE` | `@SpringBootTest`, `HTTP 4xx/5xx`, `Connection refused` | Fix stub, WireMock config, or service interaction |
| `DEPENDENCY_CLASSPATH` | `ClassNotFoundException`, `NoSuchMethodError` | Align `pom.xml` version; resolve classpath conflict |
| `CONFIGURATION_ENVIRONMENT` | `Could not resolve placeholder`, `Bean creation failed` | Fix `application.yml`, `@ConfigurationProperties`, or missing `@Bean` |
| `FLAKY_TEST` | Passes intermittently; same commit previously passed | Investigate timing/threading |

---

## Output Format

```
[BUILD ANALYSIS] Story: <STORY-ID>
  Failure Type  : <TYPE>
  Affected File : <path>:<line>
  Root Cause    : <description>
  Suggested Fix : <concrete fix instruction>
  Confidence    : HIGH | MEDIUM | LOW
```

Multiple failures are each reported separately, ordered by severity.

---

## Behaviour
- Reads `workflow/build-log-<story-id>.txt`
- Reports structured findings to the Build Fix Agent
- Does NOT automatically modify files
- LOW confidence findings include a note to verify manually
