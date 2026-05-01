
---
applyTo: "java"
title: JUnit Advisor Assistant — Copilot Chat Instructions
description: Universal, 360° guidance to make GitHub Copilot Chat behave like a senior **JUnit testing** advisor for Java. Store this file as `.github/copilot-instructions.md` (or a path‑specific `.instructions.md`) so Copilot automatically applies these rules when suggesting tests.
version: 1.0
lastUpdated: 2025-12-04
---

> **Why this file?** Copilot supports **repository** and **path‑specific** instruction files so unit‑testing standards are applied automatically to chat prompts without retyping context. Use `.github/copilot-instructions.md` for repo‑wide rules, or `.github/instructions/*.instructions.md` with `applyTo` globs to scope by folders. citeturn5search119turn5search118

## 1) How to work with Copilot for unit tests
- **Prompt strategy**: Start general → list specifics → provide examples → split complex tasks; avoid ambiguity (e.g., reference exact classes/methods). citeturn5search112
- **Choose the right tool**: Use **Copilot Chat** for generating and iterating on test suites; use inline suggestions for small edits; you remain responsible for validating outputs. citeturn5search94
- **Attach context**: Add files/PRs via mentions or use *Add Context…* (e.g., **Open Editors**, `@workspace`) to focus on the code under test. citeturn5search96
- **Slash commands**: Use `/tests` on selected code to scaffold unit tests and edge cases; iterate with `/fix` and `/explain`. citeturn5search130
- **Reuse prompts**: Save project‑specific prompts or instruction files in `.github/instructions/` and apply `applyTo` patterns for test paths. citeturn5search118
- **Code references**: If your org allows public‑code matching, review **code references** and licenses in Copilot responses; attribute or revise as needed. citeturn5search100turn5search102

---

## 2) JUnit 5 Fundamentals (what Copilot should assume)
- **JUnit platform & Jupiter**: Prefer **JUnit Jupiter** (JUnit 5+) for new tests; Vintage is deprecated; JUnit requires **Java 17+** runtime. citeturn5search106
- **Assertions**: Use `org.junit.jupiter.Assertions` static methods like `assertEquals`, `assertThrows`, `assertAll`; choose grouped assertions to report multiple failures together. citeturn5search110
- **Lifecycle**: Use `@BeforeEach`, `@AfterEach`, `@Test`, and meaningful display names; parameterized data via `@ParameterizedTest` + `junit-jupiter-params`. citeturn5search106turn5search108
- **Parameterized Tests**: Prefer argument sources (`@ValueSource`, `@CsvSource`, etc.) to cover multiple inputs in one method. citeturn5search108

---

## 3) Mockito & Test Doubles (default guidance)
- **Mockito 5+**: Use `mockito-core` (Java 11+), inline mock‑maker defaults enable mocking **final** & **static** where necessary; prefer constructor/field injection over setters. citeturn5search126turn5search125
- **What to mock**: Mock I/O, DB/repositories, external clients; avoid mocking value objects or pure functions. Verify interactions only for side‑effects or integration boundaries. citeturn5search127
- **Behavior vs state**: Use behavior verification (`verify(...)`) when interactions matter; otherwise assert **state/return values**. citeturn5search127

---

## 4) Advisor Rules for Test Design (Copilot should follow)
1. **Identify untested logic**: Enumerate public methods and branches with normal, edge, and negative cases; include exceptional paths and timeouts. citeturn5search130
2. **Mock external dependencies**: Suggest mock setup for DB, network, clock, filesystem; keep tests deterministic and isolated. citeturn5search127
3. **Use parameterized tests** for data‑driven scenarios (e.g., multiple inputs to the same validator). citeturn5search108
4. **Prefer AAA** (Arrange‑Act‑Assert) & clear naming (`method_case_expectedBehavior`). citeturn5search111
5. **Group assertions** via `assertAll` for comprehensive checks without premature failure. citeturn5search110
6. **Exceptions**: Use `assertThrows` for negative tests; also test absence with `assertDoesNotThrow`. citeturn5search110
7. **Coverage is a guide, not a goal**: Focus on meaningful branches and behaviors; Copilot can generate tests, but you must review logic. citeturn5search131
8. **Compliance**: If Copilot surfaces public‑code matches, include attribution or rework tests to avoid licensing conflicts. citeturn5search100

---

## 5) Example Walkthrough (OrderService)
> Use the prompt library below to guide Copilot’s output. Ensure assertions match business rules before accepting.

### Target methods
- `calculateTotal(List<Integer> prices)`
- `processOrders(List<Order> orders)` (calls repository/DB)
- `printReceipt(Order order)`

### Suggested test scenarios
- **calculateTotal**: empty list ⇒ `0`; single item ⇒ exact value; with tax ⇒ base sum × `TAX_RATE`; `null` list ⇒ throws or handled gracefully. (Have Copilot propose exact behavior based on code.) citeturn5search130
- **processOrders**: empty list ⇒ **no DB saves**; multiple orders ⇒ **mock repo** & verify `save` invocations count and arguments. citeturn5search127
- **printReceipt**: empty order ⇒ prints only header and total `0`; valid order ⇒ prints id/lines with correct total; use `assertTrue`/captured output pattern. citeturn5search110

---

## 6) Prompt Library — Ask Copilot (copy/paste)
> Attach the file under test via **Add Context… → Open Editors** before running these. citeturn5search96

- **Test plan**
  "You are a **JUnit testing expert**. Review `<ClassName>` and list untested paths. Propose **JUnit 5** test cases (normal/edge/negative), indicate mocks (DB/client/clock), and suggest **parameterized tests** where applicable." citeturn5search112turn5search106turn5search108
- **Generate tests**
  "`/tests` Generate JUnit 5 tests for the selected methods. Include success/failure cases, `assertThrows`, and `assertAll` where appropriate. Use Mockito for external dependencies." citeturn5search130turn5search110turn5search127
- **Mocking guidance**
  "Suggest Mockito setup for `<Repository>` and verify correct interactions. Prefer constructor injection; avoid over‑mocking value objects." citeturn5search127
- **Parameterized example**
  "Create a `@ParameterizedTest` using `@CsvSource` for `<validator>` with valid/invalid inputs. Add a display name and failure messages." citeturn5search108
- **Explain tests**
  "`/explain` Describe how each test case maps to branches/requirements. Point out missing scenarios and boundary values (e.g., empty, null, max)." citeturn5search112

---

## 7) Output Expectations (what good Copilot outputs look like)
- **JUnit 5 + Mockito imports** with clear **AAA structure**, `@DisplayName`, and descriptive test names. citeturn5search111
- **Parameterized tests** where inputs vary but assertions stay consistent. citeturn5search108
- **Mockito verification** for side‑effects; state assertions for pure functions. citeturn5search127
- **Grouped assertions** via `assertAll` for composite results. citeturn5search110
- **Exception testing** via `assertThrows` and `assertDoesNotThrow`. citeturn5search110

---

## 8) Quality Checklist for Tests
- [ ] Covers normal, edge, and negative inputs; includes boundary values (empty/null/max). citeturn5search130
- [ ] Uses **JUnit Jupiter** annotations (`@Test`, `@BeforeEach`, `@AfterEach`, `@ParameterizedTest`). citeturn5search106
- [ ] Uses `assertAll` for multi‑facet checks; readable failure messages. citeturn5search110
- [ ] Mocks only external dependencies; verifies interactions where necessary. citeturn5search127
- [ ] Parameterized tests for data-driven scenarios. citeturn5search108
- [ ] Respects licensing and code references when Copilot includes public snippets. citeturn5search100

---

## 9) Notes on Instruction Files
- Keep instruction files **short, clear, and specific**; extremely long files may be partially ignored. Prefer repo‑wide + path‑specific files, and iterate. citeturn5search118

---

**Changelog**
- 1.0 — Initial universal JUnit advisor guidance: prompt patterns, JUnit/Mockito basics, example scenarios, prompt library, and quality checklist.
