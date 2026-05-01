applyTo: "src/test/java/*.java"
description: "This document defines coding rules, conventions, and templates to be followed across all test classes."

# ✅ Universal Java Testing Instructions & Best Practices
*(For Unit, Integration, and System Testing using JUnit, TestNG, Mockito, PowerMockito, Spring Test, etc.)*

---

## **A. Project Structure & Organization**
### 1. **Package Organization**
- Follow **Maven/Gradle standard layout**:
  - `src/main/java` → production code.
  - `src/test/java` → test code.
- Mirror source code structure for easy navigation.
- Separate test types:
  - **Unit Tests:** `*Test` suffix or `unit` package.
  - **Integration Tests:** `*IT` suffix or `integration` package.
  - **E2E Tests:** `e2e` package or dedicated module.

### 2. **Imports**
- Use **explicit imports**; avoid wildcard imports (`import *`).
- Group logically:
  - Testing framework (JUnit/TestNG).
  - Mocking (Mockito, PowerMockito).
  - Assertions (AssertJ, Hamcrest, Truth).
  - Project classes.

---

## **B. Test Design & Naming**
### 3. **Class Naming**
- Use `ClassNameTest` or `FeatureNameTests`:
  - Example: `OrderServiceTest`.

### 4. **Method Naming**
- Descriptive, behavior-driven:
  - ✅ `shouldReturnOrderWhenIdExists()`
  - ❌ `testOrder()`

### 5. **Organization**
- Use **nested classes** for grouping scenarios:
  ```java
  @Nested
  class WhenOrderExists {
      @Test void shouldReturnOrder() { ... }
  }
  ```
- Use **tags** for filtering:
  - `@Tag("integration")`.

---

## **C. Lifecycle & Setup**
### 6. **Annotations**
- `@BeforeEach` / `@AfterEach` → per-test setup/cleanup.
- `@BeforeAll` / `@AfterAll` → global setup (static).
- Prefer JUnit 5 features:
  - `@DisplayName` for readability.
  - `@ParameterizedTest` for multiple inputs.

---

## **D. Coverage & Quality**
### 7. **Coverage**
- Cover:
  - All **public methods**.
  - Positive, negative, edge cases.
- Validate:
  - Functional correctness.
  - Exception handling.
- Use **JaCoCo** or **SonarQube** for coverage enforcement.

---

## **E. Mocking & Isolation**
### 8. **Mockito Basics**
- **Mocks**:
  ```java
  @Mock private OrderRepository repository;
  @InjectMocks private OrderService service;
  ```
- **Stubs**:
  ```java
  when(repository.findById(1L)).thenReturn(Optional.of(order));
  ```
- **Spies**:
  ```java
  @Spy private OrderValidator validator;
  ```

### 9. **Mockito Advanced**
- **verify()**:
  ```java
  verify(repository, times(1)).save(order);
  verify(repository, never()).delete(any());
  ```
- **ArgumentCaptor**:
  ```java
  ArgumentCaptor<Order> captor = ArgumentCaptor.forClass(Order.class);
  verify(repository).save(captor.capture());
  assertThat(captor.getValue().getId()).isEqualTo(1L);
  ```

### 10. **PowerMockito**
- For static/final/private methods:
  ```java
  PowerMockito.mockStatic(UtilityClass.class);
  when(UtilityClass.staticMethod()).thenReturn("mocked");
  ```

---

## **F. Parameterized & Data-Driven Tests**
### 11. **Parameterized Tests**
- JUnit 5:
  ```java
  @ParameterizedTest
  @ValueSource(strings = {"abc", "xyz"})
  void shouldValidateInput(String input) { ... }
  ```
- Use `@CsvSource` or `@MethodSource` for complex data.

---

## **G. Assertions**
### 12. **Libraries**
- **AssertJ**:
  ```java
  assertThat(order.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
  ```
- **Hamcrest**:
  ```java
  assertThat(order.getStatus(), is(OrderStatus.CONFIRMED));
  ```
- **Google Truth**:
  ```java
  assertThat(order.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
  ```
- **Exception Testing**:
  ```java
  assertThrows(IllegalArgumentException.class, () -> service.createOrder(null));
  ```

---

## **H. Integration Testing**
### 13. **Spring & DB**
- Use `@SpringBootTest` for Spring context.
- Use `@Transactional` for rollback.
- Use **Testcontainers** for real DB in CI/CD.
- Separate integration tests from unit tests.

---

## **I. CI/CD & Reporting**
### 14. **Build Integration**
- **Surefire** → Unit tests.
- **Failsafe** → Integration tests.
- Reports:
  - HTML/XML via Surefire.
  - Coverage via JaCoCo.
- Enforce **minimum coverage thresholds** in CI pipelines.

---

## **J. Advanced Strategies**
### 15. **Test Pyramid**
- Unit: **70%**
- Integration: **20%**
- E2E: **10%**

### 16. **Security Testing**
- Validate:
  - Input sanitization.
  - Authentication & authorization.
- Test for SQL injection, XSS, CSRF.

### 17. **Performance Testing**
- Use **JMH** for micro-benchmarks.
- Validate response times & resource usage.

---

## **K. Best Practices Summary**
- Test **behavior**, not implementation details.
- Keep tests **fast**, **independent**, **idempotent**.
- Avoid flaky tests.
- Regularly review and refactor.
