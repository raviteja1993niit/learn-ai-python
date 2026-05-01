# ProcessingIT Test Execution Sequence Diagram

## Overview
This sequence diagram shows the complete test execution flow for ProcessingIT integration test.

```mermaid
sequenceDiagram
    autonumber
    actor Developer
    participant JUnit as JUnit 5 Engine
    participant PIT as ProcessingIT
    participant Config as IntegrationTestsConfig
    participant EST as ElavonSystemTransactions
    participant AFT as AuthFPANTest
    participant MCTF as MCTF Integration
    participant RT as RestTemplate
    participant SUT as System Under Test
    
    Developer->>JUnit: Run Integration Tests
    activate JUnit
    
    Note over JUnit,PIT: Test Discovery Phase
    JUnit->>PIT: @TestFactory componentTests()
    activate PIT
    
    Note over PIT,Config: Spring Context Initialization
    PIT->>Config: @Import IntegrationTestsConfig
    activate Config
    Config->>RT: @Bean restTemplate()
    RT-->>Config: RestTemplate instance
    Config-->>PIT: Configuration ready
    deactivate Config
    
    Note over PIT,EST: Model Loading Phase
    PIT->>EST: Load MODEL (LazyModel)
    activate EST
    EST->>AFT: with(AuthFPANTest.class)
    activate AFT
    
    Note over AFT: Flow Construction
    AFT->>AFT: Deriver.build(authFPAN.newAuth)
    AFT->>AFT: update(CPC, getConnectivityRequest)
    AFT->>AFT: update(CONNECTIVITY, ...)
    AFT->>AFT: update(ACQUIRER, getAcquirerRequestFields)
    AFT->>AFT: members(flatten(authMandatoryFields))
    
    AFT-->>EST: Model with flows
    deactivate AFT
    EST-->>PIT: Complete MODEL
    deactivate EST
    
    Note over PIT,MCTF: Test Generation Phase
    PIT->>MCTF: new Integration(MODEL, restTemplate)
    activate MCTF
    MCTF->>MCTF: Parse flow definitions
    MCTF->>MCTF: Generate DynamicTests
    MCTF-->>PIT: Stream<DynamicNode>
    
    Note over JUnit,SUT: Test Execution Phase
    loop For Each DynamicTest
        JUnit->>MCTF: Execute test case
        MCTF->>RT: Execute HTTP request
        activate RT
        RT->>SUT: POST /transaction
        activate SUT
        SUT->>SUT: Process authorization
        SUT-->>RT: Response (ISO 8583)
        deactivate SUT
        RT-->>MCTF: HTTP Response
        deactivate RT
        
        MCTF->>MCTF: Validate response against model
        MCTF-->>JUnit: Test result (Pass/Fail)
    end
    
    deactivate MCTF
    PIT-->>JUnit: All tests completed
    deactivate PIT
    
    JUnit-->>Developer: Test Report
    deactivate JUnit
```

## Sequence Steps Explained

| Step | Phase | Description |
|------|-------|-------------|
| 1-2 | Discovery | JUnit discovers @TestFactory method |
| 3-6 | Configuration | Spring context loads, RestTemplate bean created |
| 7-14 | Model Loading | Lazy model loads AuthFPANTest flows |
| 15-17 | Test Generation | MCTF creates dynamic tests from flows |
| 18-24 | Execution | Each test case executed via HTTP |
| 25-26 | Completion | Results aggregated and reported |

## Key Method Calls

### ProcessingIT.componentTests()
```java
@TestFactory
Stream<DynamicNode> componentTests() {
    return new Integration(ElavonSystemTransactions.MODEL, restTemplate).tests();
}
```

### AuthFPANTest Constructor
```java
Flow authMandatoryFields = Deriver.build(authFPAN.newAuth, getBaseInteraction(),
    flow -> flow
        .meta(data -> data.description("New Base Auth request"))
        .update(CPC, getConnectivityRequest(), rq(...), getConnectivityResponse())
        .update(Interactions.CONNECTIVITY, getConnectivityRequest(), getConnectivityResponse())
        .update(Interactions.ACQUIRER, getAcquirerRequestFields()));
```
