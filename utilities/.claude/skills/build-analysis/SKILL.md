---
name: build-analysis
description: >
  Auto-triggered skill that parses Jenkins CI build logs and Maven output to classify failure
  types, identify root causes, and suggest targeted fixes. Invoked by the Build Fix Agent (Phase 7).
triggers:
  - onPhaseStart phase=7
---

# Skill: Build Analysis

## Purpose

Parse CI pipeline and Maven build logs to rapidly classify the failure type, pinpoint the affected
file and line, and suggest a concrete targeted fix. Surfaces structured findings to the Build Fix
Agent to minimise fix-cycle iterations.

---

## Trigger Conditions

- Triggered automatically when Phase 7 (Build Fix Agent) starts
- Can be explicitly invoked: analyse build log for story `<STORY-ID>`

---

## Failure Classification

For each failure detected in the log, assign exactly one type:

| Type | Key Log Patterns | Fix Approach |
|------|-----------------|-------------|
| `COMPILATION` | `ERROR … cannot find symbol`, `package does not exist`, `incompatible types` | Fix import, method signature, or missing class |
| `UNIT_TEST_FAILURE` | `Tests run: N, Failures: N, Errors: N`, `AssertionFailedError` | Fix logic error or update assertion/test data |
| `INTEGRATION_TEST_FAILURE` | `@SpringBootTest`, `HTTP 4xx/5xx` in test log, `Connection refused` | Fix stub, WireMock config, or service interaction |
| `DEPENDENCY_CLASSPATH` | `ClassNotFoundException`, `NoSuchMethodError`, `NoClassDefFoundError` | Align `pom.xml` dependency version; resolve classpath conflict |
| `CONFIGURATION_ENVIRONMENT` | `Could not resolve placeholder`, `Bean creation failed`, `No qualifying bean` | Fix `application.yml`, `@ConfigurationProperties`, or missing `@Bean` |
| `FLAKY_TEST` | Passes intermittently; same commit previously passed | Investigate timing/threading; consider `@Disabled` with Jira TODO |

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
- LOW confidence findings include an explicit note to verify manually
- If failure type cannot be determined: reports `UNKNOWN` with the raw log excerpt for human review
