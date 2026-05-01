
---
applyTo: "**/*.java"
title: Unified Java Development Instructions — Copilot‑Ready (Enhanced)
description: A universal, 360° instruction set that consolidates your initial Java best‑practice docs into one detailed file. Includes Copilot prompting guidance, coding standards, language features (Java 8–17), concurrency, security, testing, performance, observability, a prompt library, and a review checklist.
version: 2.0
lastUpdated: 2025-12-04
---

> **How this works** — Save this as `.github/copilot-instructions.md` (or as a path‑specific `.instructions.md` with an `applyTo` glob) so **GitHub Copilot Chat** automatically applies these instructions across prompts in VS Code. citeturn9search27turn9search28

## 0) Copilot Usage & Prompting (quick start)
- **Prompt strategy**: Start broad → add specifics → provide examples → break complex tasks into small steps; avoid ambiguous wording. citeturn9search33
- **Attach context**: In VS Code, use **Add Context…** (for example, **Open Editors**, repo files) so Copilot sees the exact classes/methods you mean. citeturn9search27
- **Instruction files**: Use a repo‑wide `.github/copilot-instructions.md` plus path‑specific files in `.github/instructions/` with `applyTo` globs (e.g., `api/**`). Keep files concise for best results. citeturn9search28turn9search31
- **Built‑in commands**: Use `/explain`, `/fix`, `/tests` to accelerate common flows (explain code, propose fixes, generate unit tests). citeturn5search130
- **Code referencing**: If your org allows public‑code matches, review Copilot **code references** and licenses; attribute or replace as needed. citeturn9search9turn9search10

---

## 1) Global Java Coding Standards (consolidated)
> Derived from your initial files; expanded for completeness. citeturn9search1turn9search2turn9search3

- **Imports**: Use explicit imports; avoid wildcard imports. citeturn9search3
- **Naming**: Classes **PascalCase**; methods & variables **camelCase**; constants **UPPER_SNAKE_CASE**. citeturn9search1
- **File organization**: One public type (class/interface/enum/annotation/record) per source file; domain‑based, lowercase packages (e.g., `com.example.app`). citeturn9search3
- **Javadoc**: Every public type and important methods must include intent, responsibilities, and key usage notes. citeturn9search3
- **Method & field guidelines**: Prefer constructor injection; avoid magic numbers; keep methods single‑responsibility and concise. citeturn9search3
- **Comments**: Use Javadoc for API; inline comments only for non‑obvious logic; don’t wrap single‑line comments. citeturn9search3
- **Logging**: Use SLF4J (Logback/Log4j2); avoid logging sensitive data. citeturn9search2
- **Security**: Validate inputs; don’t hardcode secrets; use secure crypto/auth APIs. citeturn9search1
- **Clean‑code principles**: Apply SOLID; DRY/KISS/YAGNI; refactor regularly. citeturn9search1

---

## 2) Language Features to Prefer (Java 8 → 17)
- **Java 8**: Lambdas, Streams, `Optional`, java.time API for dates/times (prefer over `Date`). citeturn9search2
- **Java 9**: Modules (`module-info.java`) and JShell for interactive exploration. citeturn9search1
- **Java 10**: `var` for local type inference (use when it improves readability). citeturn9search2
- **Java 11**: HTTP Client and String enhancements (e.g., `isBlank`). citeturn9search2
- **Java 12–13**: Switch expressions for clearer branching. citeturn9search2
- **Java 14**: Records for immutable data carriers. citeturn9search2
- **Java 15**: Text blocks for multi‑line strings. citeturn9search1
- **Java 16**: Pattern matching (e.g., for `instanceof`). citeturn9search1
- **Java 17**: Sealed types to restrict inheritance hierarchies. citeturn9search1

---

## 3) Advanced Guidelines (enterprise‑grade)
- **Concurrency**: Prefer immutability; use `java.util.concurrent` (executors, futures, locks) and high‑level constructs; avoid manual thread management. citeturn9search1
- **Error handling**: Use specific exceptions; never swallow; use `try-with-resources` for automatic cleanup. citeturn9search3
- **Performance**: Minimize unnecessary allocations; choose the right data structures; optimize hot paths (measure first). citeturn9search3
- **Security**: Input validation, output encoding, and least privilege; never log secrets. citeturn9search2

---

## 4) Testing & Quality (JUnit + Mockito)
- **Unit tests**: Use **JUnit 5/6 (Jupiter)**; grouped assertions, parameterized tests, and a clear AAA (Arrange‑Act‑Assert) structure. citeturn9search39
- **Mocking**: Use **Mockito 5+** for test doubles (supports modern Java, inline mock maker, final/static mocking). citeturn9search16
- **Test generation with Copilot**: Use `/tests` on selected code to scaffold unit tests; iterate and align assertions to business rules. citeturn5search130

---

## 5) Performance & Observability (JDK tools)
- **Java Flight Recorder (JFR)**: Low‑overhead event collection built into the JDK; configure via `-XX:StartFlightRecording` or API, then visualize with **Java Mission Control**. citeturn9search45turn9search47
- **JFR options**: Tune delay, duration, disk, dump‑on‑exit, name, and max‑age to fit incident analysis and profiling flows. citeturn9search46
- **VisualVM**: All‑in‑one troubleshooting (profiling, heap/thread analysis); download and run separately for modern JDKs. citeturn9search21turn9search22
- **JFR overview/tutorials**: Use official guides for setup and analysis workflows. citeturn9search48turn9search50

---

## 6) Prompt Library — Copy into Copilot Chat
> Attach the files/classes under discussion via **Add Context… → Open Editors** for precise scope. citeturn9search27

### Documentation
- "Generate inline Javadoc for `<MethodName>` (params, return, exceptions, side effects) and a class‑level summary for `<ClassName>`." citeturn9search33
- "Create module documentation for `<Module>` covering responsibilities, dependencies, and configuration." citeturn9search33

### Refactoring
- "You are a senior Java engineer. Refactor `<ClassName>` to improve readability, maintainability, and testability while preserving behavior. Provide a **diff**, a short rationale per change, and **unit tests** for edge cases." citeturn9search33
- "Optimize `<MethodName>` hot path for time/allocations; keep behavior identical; include micro‑benchmarks or JFR steps to verify." citeturn9search47

### Test Data & Unit Tests
- "Provide sample input/output (normal/edge/negative) for `<ClassName>` and generate JUnit 5 tests (including parameterized cases)." citeturn9search39
- "Mock external dependencies with Mockito and verify interactions; prefer constructor injection over field injection." citeturn9search16

### Code Explanation
- "Explain `<ClassName>` (logic flow, invariants, dependencies) and list potential risks; propose simplifications." citeturn9search33

### New Code Generation
- "Create a new utility class `<Name>` with pure functions and comprehensive unit tests; document time/space trade‑offs." citeturn9search33

### SQL & Data Access
- "Propose SQL schemas/queries for `<useCase>` with indexing and pagination considerations; include test data and edge cases." citeturn9search33

### Bug Fixing & Debugging
- "Identify and fix the bug causing `<symptom>` in `<MethodName>`; return a patch and failing‑then‑passing tests; suggest JFR/VisualVM steps for root‑cause analysis." citeturn9search47turn9search21

### Commit Messages & Migration
- "Generate a conventional commit message summarizing changes in `<Module>`; include scope and rationale." citeturn9search33
- "Migrate Java 8 code to modern features (records, text blocks, pattern matching) where appropriate; provide before/after diff." citeturn9search2

---

## 7) Code Review Checklist (apply before merging)
- **Style & structure**: Imports explicit; naming consistent; one public type per file; meaningful Javadoc. citeturn9search3
- **Correctness**: Edge cases covered; no magic numbers; exceptions specific; resources closed via `try-with-resources`. citeturn9search3
- **Concurrency**: Shared state minimized; thread‑safe patterns; no blocking in async paths without clear reason. citeturn9search1
- **Security**: Inputs validated; secrets not logged or hardcoded; crypto/auth via approved libraries. citeturn9search1
- **Performance**: Hot paths measured; allocations minimized; appropriate data structures used. citeturn9search3
- **Testing**: JUnit 5 tests for normal/edge/negative; Mockito mocks for external dependencies; clear AAA structure. citeturn9search39turn9search16
- **Observability**: JFR/VisualVM steps documented for troubleshooting or performance verification. citeturn9search47turn9search21
- **Copilot hygiene**: Instruction files present; prompts include context; public‑code matches reviewed for licensing. citeturn9search28turn9search9

---

## 8) Governance, Licensing & Instruction Hygiene
- **Code referencing**: Copilot may show references when suggestions match public code; review licenses and decide to attribute, avoid, or replace. citeturn9search9
- **Instruction hygiene**: Keep files focused and reasonably short to maximize Copilot’s adherence; iterate based on observed behavior. citeturn9search31
- **Organizing instructions**: Use repo‑wide plus path‑specific files; attach additional prompt libraries when needed. citeturn9search28

---

**Changelog**
- 2.0 — Unified and enhanced edition consolidating your initial best‑practice docs (coding standards, features, advanced guidelines) with Copilot prompting, testing, performance/observability, a prompt library, and a review checklist. citeturn9search1turn9search2turn9search3
