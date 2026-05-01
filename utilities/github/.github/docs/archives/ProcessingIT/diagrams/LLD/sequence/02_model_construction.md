# ProcessingIT Model Construction Sequence

## Overview
This diagram details how the test model is constructed from ElavonSystemTransactions through AuthFPANTest.

```mermaid
sequenceDiagram
    autonumber
    participant EST as ElavonSystemTransactions
    participant LM as LazyModel
    participant AFT as AuthFPANTest
    participant EM as EagerModel
    participant AFPAN as AuthFPAN
    participant D as Deriver
    participant TC as TestConstants
    participant ACQ as Acquirer
    
    Note over EST,LM: Static Model Initialization
    EST->>LM: new LazyModel("ELAVON_S2A")
    activate LM
    LM->>LM: Set model name
    
    EST->>LM: with(AuthFPANTest.class)
    LM->>LM: Register class for lazy loading
    LM-->>EST: MODEL reference
    deactivate LM
    
    Note over LM,AFT: Lazy Instantiation (on first access)
    LM->>AFT: new AuthFPANTest()
    activate AFT
    
    AFT->>EM: super(MODEL_TAGS)
    activate EM
    EM->>EM: Initialize with AUTH tag
    EM-->>AFT: EagerModel ready
    deactivate EM
    
    Note over AFT,AFPAN: Get Base Flow
    AFT->>AFPAN: authFPAN.newAuth
    activate AFPAN
    AFPAN-->>AFT: Base authorization flow
    deactivate AFPAN
    
    Note over AFT,D: Build Derived Flow
    AFT->>TC: getBaseInteraction()
    activate TC
    TC-->>AFT: Consumer<Deriver>
    deactivate TC
    
    AFT->>D: Deriver.build(newAuth, baseInteraction, updates)
    activate D
    
    Note over D,TC: Apply Base Interaction
    D->>TC: Apply base interaction
    TC->>TC: addCall(CONNECTIVITY -> ACQUIRER)
    TC->>ACQ: Acquirer.authRequest()
    activate ACQ
    ACQ-->>TC: ElavonTestMessage (request)
    deactivate ACQ
    TC->>ACQ: Acquirer.authResponse()
    activate ACQ
    ACQ-->>TC: ElavonTestMessage (response)
    deactivate ACQ
    TC->>TC: update(CPC, headers/request)
    TC->>TC: update(CONNECTIVITY, fields)
    TC-->>D: Base interaction configured
    
    Note over D,AFT: Apply Flow-Specific Updates
    D->>D: update(CPC, partialAmountSupport, acquirerConfigs)
    D->>D: update(CONNECTIVITY, transactionType, acquirerId)
    D->>D: update(ACQUIRER, field 63.50)
    
    D-->>AFT: authMandatoryFields Flow
    deactivate D
    
    Note over AFT,EM: Register Flows
    AFT->>AFT: flatten(authMandatoryFields)
    AFT->>EM: members(flattened flows)
    EM->>EM: Store flow members
    
    AFT-->>LM: AuthFPANTest instance
    deactivate AFT
```

## Model Structure

```mermaid
classDiagram
    class ElavonSystemTransactions {
        <<Final>>
        +MODEL: Model
    }
    
    class LazyModel {
        -name: String
        -flowSources: List~Class~
        +with(Class): LazyModel
    }
    
    class AuthFPANTest {
        +MODEL_TAGS: TaggedGroup
        -authFPAN: AuthFPAN
        +AuthFPANTest()
    }
    
    class EagerModel {
        #members: Collection~Flow~
        +members(Flow...): void
    }
    
    class AuthFPAN {
        +newAuth: Flow
    }
    
    class Deriver {
        +build(Flow, Consumer, Consumer): Flow
    }
    
    class TestConstants {
        +getBaseInteraction(): Consumer~Deriver~
        +updateConnectivityResponse(): Consumer~MutableInteraction~
    }
    
    ElavonSystemTransactions --> LazyModel : creates
    LazyModel --> AuthFPANTest : loads
    AuthFPANTest --|> EagerModel : extends
    AuthFPANTest --> AuthFPAN : uses
    AuthFPANTest --> Deriver : builds with
    AuthFPANTest --> TestConstants : configures via
```

## Key Data Transformations

| Source | Transformation | Target |
|--------|---------------|--------|
| AuthFPAN.newAuth | Deriver.build() | authMandatoryFields |
| getBaseInteraction() | Apply CPC/CONNECTIVITY/ACQUIRER updates | Complete flow |
| Flow | flatten() | Collection of executable tests |
