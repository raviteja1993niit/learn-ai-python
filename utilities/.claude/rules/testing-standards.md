# Testing Standards

## Coverage Targets

| Code Category | Line Coverage | Branch Coverage |
|--------------|--------------|----------------|
| Business logic (service, mapping) | ≥ 80% | ≥ 80% |
| Utility / validation / converter | 100% | 100% |
| Controller / handler | ≥ 70% | ≥ 70% |

## Test Naming

Pattern: `should<Behaviour>When<Condition>`

Examples:
- `shouldReturnDeclineWhenCardIsExpired`
- `shouldThrowMappingExceptionWhenRequestFieldIsNull`
- `shouldReturnEmptyOptionalWhenStoryNotFound`

## Arrange–Act–Assert (AAA)

Every test uses clear AAA sections separated by blank lines:

```java
@Test
void shouldReturnDeclineWhenCardIsExpired() {
    // Arrange
    final AuthorisationRequest request = AuthorisationRequestBuilder.expiredCard().build();

    // Act
    final AuthorisationResponse response = underTest.authorise(request);

    // Assert
    assertThat(response.getResponseCode()).isEqualTo("51");
}
```

## Frameworks

- **JUnit 5** (`@Test`, `@ParameterizedTest`, `@ExtendWith`) — no JUnit 4
- **Mockito** for mocking dependencies (`@Mock`, `@InjectMocks` via `@ExtendWith(MockitoExtension.class)`)
- **AssertJ** for fluent assertions (`assertThat(...)`) — preferred over JUnit's `assertEquals`
- **WireMock** for HTTP interaction tests (no real network calls in unit or integration tests)

## Mocking Rules

- Do NOT make real network calls in unit tests
- Use `@Mock` + `@InjectMocks` — do NOT use `@SpringBootTest` for pure unit tests
- WireMock stubs go in dedicated `*IT.java` integration test classes
- Integration tests: separate module or class suffix `IT`; guarded by Maven profile or env flag

## Test Data

- Use builder or factory methods for test fixtures: `AuthorisationRequestBuilder.validVisa().build()`
- Avoid large inline JSON strings in test methods — externalise to `/src/test/resources/`
- Never use production-like PAN, CVV, or real credentials in test data

## Edge Cases (always test)

- `null` inputs to all public methods
- Empty collections / empty strings
- Maximum field lengths (boundary values)
- Boundary numeric values (min, max, overflow)
- Error response paths (exception thrown, MCP unavailable)
- All enum members exercised

## Integration Tests

- Keep in a separate module (e.g., `libmpgs-*-integration-tests`) or class suffix `IT`
- Guard with a Maven profile or environment flag: do NOT run in CI unit-test phases
- Use WireMock to stub all HTTP interactions

## Disabled Tests

- Never leave a failing test permanently disabled
- If a flaky test must be disabled: use `@Disabled` with a Jira TODO comment:
  ```java
  @Disabled("TODO(PROJ-9999): Re-enable after WireMock stub stabilisation")
  ```
