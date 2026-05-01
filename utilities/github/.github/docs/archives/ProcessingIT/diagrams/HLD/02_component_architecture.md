# ProcessingIT Component Architecture Diagram

## Overview
This diagram illustrates the component architecture and module dependencies within the ProcessingIT integration test framework.

```mermaid
graph TB
    subgraph "lib-elavon-interface-integration-tests"
        subgraph "Test Execution"
            ProcessingIT["ProcessingIT"]
            IntegrationTestsConfig["IntegrationTestsConfig"]
            IntegrationTestsApp["IntegrationTestsApplication"]
        end
    end
    
    subgraph "lib-elavon-interface-test-data"
        subgraph "Flow Models"
            ElavonSystemTxn["ElavonSystemTransactions"]
            AuthFPANTest["AuthFPANTest"]
        end
        
        subgraph "Test Constants"
            TestConstants["TestConstants"]
            ElavonAcqConstants["ElavonAcquirerConstants"]
            Fields["Fields"]
        end
        
        subgraph "Message Builders"
            AcquirerMsg["Acquirer"]
            ElavonTestMessage["ElavonTestMessage"]
        end
    end
    
    subgraph "External Dependencies"
        MCTF["MCTF Integration<br/>(Mastercard Test Framework)"]
        LazyModel["LazyModel"]
        EagerModel["EagerModel"]
        RestTemplate["Spring RestTemplate"]
    end
    
    subgraph "lib-elavon-interface-message"
        ElavonMessage["ElavonMessage"]
        MessageType["MessageType"]
        PosDataCode["PosDataCode"]
    end
    
    ProcessingIT --> MCTF
    ProcessingIT --> ElavonSystemTxn
    ProcessingIT --> IntegrationTestsConfig
    IntegrationTestsConfig --> RestTemplate
    
    ElavonSystemTxn --> LazyModel
    ElavonSystemTxn --> AuthFPANTest
    
    AuthFPANTest --> EagerModel
    AuthFPANTest --> TestConstants
    AuthFPANTest --> ElavonAcqConstants
    AuthFPANTest --> AcquirerMsg
    
    AcquirerMsg --> ElavonTestMessage
    ElavonTestMessage --> ElavonMessage
    ElavonMessage --> MessageType
    ElavonMessage --> PosDataCode
    
    TestConstants --> AcquirerMsg
    
    MCTF --> RestTemplate
```

## Component Descriptions

| Component | Module | Purpose |
|-----------|--------|---------|
| ProcessingIT | integration-tests | Main test class with @TestFactory |
| IntegrationTestsConfig | integration-tests | Spring test configuration |
| ElavonSystemTransactions | test-data | Model container defining test flows |
| AuthFPANTest | test-data | Auth FPAN test scenarios for S2A |
| TestConstants | test-data | Common test request/response builders |
| Acquirer | test-data | Acquirer message definitions |
| ElavonMessage | message | ISO 8583 message structure |
| MCTF Integration | external | Mastercard test framework |

## Module Dependencies

```mermaid
graph LR
    A[lib-elavon-interface-integration-tests] --> B[lib-elavon-interface-test-data]
    B --> C[lib-elavon-interface-message]
    B --> D[lib-elavon-interface-mapping]
    A --> E[pgs-acquirer-elavon-interface-service]
```
