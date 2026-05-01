# ProcessingIT Interaction Layers Sequence

## Overview
This diagram shows how the three interaction layers (CPC, CONNECTIVITY, ACQUIRER) work together in the test flow.

```mermaid
sequenceDiagram
    autonumber
    participant Client as Test Client
    participant CPC as CPC Layer<br/>(Card Processing)
    participant CONN as Connectivity Layer
    participant ACQ as Acquirer Layer<br/>(Elavon S2A)
    
    Note over Client,ACQ: Authorization Flow - 3 Interaction Layers
    
    rect rgb(200, 230, 255)
        Note over Client,CPC: Layer 1: CPC (Card Processing Component)
        Client->>CPC: Authorization Request
        Note right of CPC: Headers:<br/>X-Mc-Toggle-Version: 1<br/>X-Mc-Correlation-Id: {uuid}<br/>X-Mc-MSO-Id: SAMPLEBOOSTMSO1<br/>X-Mc-Merchant-Id: TESTCONRAD0C
        Note right of CPC: Body:<br/>partialAmountSupport: true<br/>acquirerConfigurations[0].id: externalAcquirerId<br/>acquirerConfigurations[0].value: 45678<br/>acquirerId: CPCSIMULATOR
    end
    
    rect rgb(200, 255, 200)
        Note over CPC,CONN: Layer 2: Connectivity
        CPC->>CONN: Forward Request
        Note right of CONN: Request Fields:<br/>transactionType: AUTHORIZATION<br/>acquirerId: ELAVON_S2A<br/>merchantOrderReference: 328492-36593-8rh387f<br/>merchantTransactionReference: 328492-36593-8rh387fs<br/>pointOfServiceTerminalId: 123455<br/>transactionId: {uuid}<br/>submissionTimestamp: 2025-05-24T16:05:15Z
    end
    
    rect rgb(255, 230, 200)
        Note over CONN,ACQ: Layer 3: Acquirer (ISO 8583)
        CONN->>ACQ: ISO 8583 Auth Request
        Note right of ACQ: ISO 8583 Fields:<br/>Field 63.50: 3DSecure Capability Indicator<br/>Field 2: PAN (5212345678901234)<br/>Field 4: Amount (000000002112)<br/>Field 11: STAN (012345)<br/>Field 41: Terminal ID (00123455)<br/>Field 42: Merchant ID (M12345)
        
        ACQ-->>CONN: ISO 8583 Auth Response
        Note left of ACQ: Response:<br/>Field 38: Approval Code (123456)<br/>Field 39: Action Code (000)<br/>Field 48.02: Elavon STAN<br/>Field 63.31: Card Scheme Data
    end
    
    rect rgb(200, 255, 200)
        Note over CPC,CONN: Layer 2 Response
        CONN-->>CPC: Connectivity Response
        Note left of CONN: Response Fields:<br/>status: APPROVED<br/>authorizationCode: 654847<br/>cscVerificationCode: O<br/>networkTransactionId: 7847b2f74ef14<br/>responseCode: 00<br/>acquirerProcessDate: 2025-03-03
    end
    
    rect rgb(200, 230, 255)
        Note over Client,CPC: Layer 1 Response
        CPC-->>Client: CPC Response
        Note left of CPC: Response:<br/>derivedSLI: 210
    end
```

## Layer Responsibilities

```mermaid
graph TB
    subgraph "CPC Layer"
        CPC1[Request Routing]
        CPC2[Acquirer Configuration]
        CPC3[SLI Derivation]
        CPC4[MSO/Merchant Context]
    end
    
    subgraph "Connectivity Layer"
        CONN1[Protocol Translation]
        CONN2[Transaction Type Mapping]
        CONN3[Reference Management]
        CONN4[Timestamp Handling]
    end
    
    subgraph "Acquirer Layer"
        ACQ1[ISO 8583 Formatting]
        ACQ2[Field Mapping]
        ACQ3[Elavon-Specific Processing]
        ACQ4[Response Code Translation]
    end
    
    CPC1 --> CONN1
    CPC2 --> CONN2
    CONN1 --> ACQ1
    CONN2 --> ACQ2
```

## Interaction Configuration

### CPC Layer Configuration
```java
.update(CPC,
    getConnectivityRequest(),
    rq("partialAmountSupport", true,
        "acquirerConfigurations[0].id", "externalAcquirerId",
        "acquirerConfigurations[0].value", "45678",
        ACQUIRERID, "CPCSIMULATOR"),
    getConnectivityResponse())
```

### Connectivity Layer Configuration
```java
.update(Interactions.CONNECTIVITY,
    rq(HttpMsg.header(X_MC_TOGGLE_VERSION), "1",
        TRANSACTION_ID, tranId,
        SUBMISSION_TIMESTAMP, "2025-05-24T16:05:15Z"),
    rs("configurationParams", DELETE,
        "derivedRequestServiceProviderParams", DELETE,
        STATUS, APPROVED))
```

### Acquirer Layer Configuration
```java
.update(Interactions.ACQUIRER, 
    rq(SIXTY_THREE_FIFTY, THREE_DSECURE_CAPABILITY_INDICATOR))
```

## Test Data Values Summary

| Layer | Field | Value |
|-------|-------|-------|
| CPC | MSO ID | SAMPLEBOOSTMSO1 |
| CPC | Merchant ID | TESTCONRAD0C |
| CONN | Acquirer ID | ELAVON_S2A |
| CONN | Transaction Type | AUTHORIZATION |
| ACQ | PAN | 5212345678901234 |
| ACQ | Amount | $21.12 |
| ACQ | Currency | USD (840) |
| ACQ | Response Code | 000 (Approved) |
