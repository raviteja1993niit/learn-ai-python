# ProcessingIT Class Diagram

## Overview
This diagram shows the class structure and relationships for the ProcessingIT integration test components.

```mermaid
classDiagram
    class ProcessingIT {
        <<SpringBootTest>>
        -RestTemplate restTemplate
        +componentTests() Stream~DynamicNode~
    }
    
    class IntegrationTestsConfig {
        <<TestConfiguration>>
        +restTemplate(RestTemplateBuilder) RestTemplate
        +errorComparator() Comparator~Error~
    }
    
    class ElavonSystemTransactions {
        <<Final>>
        +MODEL$ Model
        -ElavonSystemTransactions()
    }
    
    class AuthFPANTest {
        +MODEL_TAGS$ TaggedGroup
        -authFPAN AuthFPAN
        +AuthFPANTest()
        -getAcquirerRequestFields() Consumer~MutableInteraction~
        -getConnectivityRequest() Consumer~MutableInteraction~
        -getConnectivityResponse() Consumer~MutableInteraction~
    }
    
    class TestConstants {
        +X_MC_MSO_ID$ String
        +X_MC_MERCHANT_ID$ String
        +X_MC_TOGGLE_VERSION$ String
        +VISA_CARD_NUMBER_2$ String
        +MASTERCARD_CARD_NUMBER_2$ String
        -TestConstants()
        +getBaseInteraction()$ Consumer~Deriver~
        +updateConnectivityResponse()$ Consumer~MutableInteraction~
    }
    
    class ElavonAcquirerConstants {
        <<Final>>
        +ELAVON_S2A_ACQ_ID$ String
        +COMPATIBILITY_VERSION_25_10$ String
        +AUTH_LITERAL$ String
        +VISA$ String
        +MASTERCARD$ String
        +INTERNET$ String
    }
    
    class Acquirer {
        <<Final>>
        -AUTH_REQ$ Consumer~ElavonMessage~
        -AUTH_RES$ Consumer~ElavonMessage~
        -TRANSACTION_AMOUNT$ String
        +authRequest()$ Message
        +authResponse()$ Message
    }
    
    class ElavonTestMessage {
        -messageBuilder Consumer~ElavonMessage~
        +ElavonTestMessage(Consumer~ElavonMessage~)
        +masking(Unpredictables, Consumer) ElavonTestMessage
    }
    
    class ElavonMessage {
        -messageType MessageType
        -body ElavonBody
        +setMessageType(MessageType) ElavonMessage
        +body() ElavonBody
    }
    
    class ElavonBody {
        -pan String
        -amount String
        -systemTrace String
        -localDateTime String
        -expiry String
        -posDataCode PosDataCode
        +setPan(String) ElavonBody
        +setAmount(String) ElavonBody
        +setSystemTrace(String) ElavonBody
    }
    
    class PosDataCode {
        -inputCapability String
        -authCapability String
        -captureCapability String
        -operatingEnvironment String
        +setInputCapability(String) PosDataCode
        +setAuthCapability(String) PosDataCode
    }
    
    %% Relationships
    ProcessingIT ..> IntegrationTestsConfig : imports
    ProcessingIT ..> ElavonSystemTransactions : uses MODEL
    ProcessingIT --> RestTemplate : injects
    
    ElavonSystemTransactions --> AuthFPANTest : loads
    
    AuthFPANTest --|> EagerModel : extends
    AuthFPANTest ..> TestConstants : uses
    AuthFPANTest ..> ElavonAcquirerConstants : uses
    AuthFPANTest ..> Acquirer : uses
    
    Acquirer --> ElavonTestMessage : creates
    ElavonTestMessage --> ElavonMessage : wraps
    ElavonMessage --> ElavonBody : contains
    ElavonBody --> PosDataCode : contains
    
    TestConstants ..> Acquirer : references
```

## External Dependencies

```mermaid
classDiagram
    class Model {
        <<interface>>
    }
    
    class LazyModel {
        -name String
        -flowSources List~Class~
        +with(Class) LazyModel
    }
    
    class EagerModel {
        <<abstract>>
        #members Collection~Flow~
        +members(Flow...) void
    }
    
    class TaggedGroup {
        -tags Set~String~
        +TaggedGroup(String...)
    }
    
    class Flow {
        <<interface>>
        +interactions() Collection~Interaction~
    }
    
    class Deriver {
        +build(Flow, Consumer, Consumer) Flow
    }
    
    class Integration {
        -model Model
        -restTemplate RestTemplate
        +Integration(Model, RestTemplate)
        +tests() Stream~DynamicNode~
    }
    
    class Interactions {
        <<Utility>>
        +CPC$ Actor
        +CONNECTIVITY$ Actor
        +ACQUIRER$ Actor
        +rq(Object...)$ Consumer~MutableInteraction~
        +rs(Object...)$ Consumer~MutableInteraction~
    }
    
    LazyModel ..|> Model : implements
    EagerModel ..|> Model : implements
    EagerModel --> Flow : contains
    Integration --> Model : uses
    Deriver --> Flow : creates
```

## Package Structure

```
lib-elavon-interface-integration-tests/
├── src/test/java/.../test/
│   ├── ProcessingIT.java
│   └── IntegrationTestsConfig.java

lib-elavon-interface-test-data/
├── src/main/java/.../flow/
│   ├── ElavonSystemTransactions.java
│   ├── model/
│   │   └── AuthFPANTest.java
│   ├── constant/
│   │   ├── TestConstants.java
│   │   ├── ElavonAcquirerConstants.java
│   │   └── Fields.java
│   ├── msg/
│   │   └── Acquirer.java
│   └── utility/
│       └── ElavonUtil.java

lib-elavon-interface-message/
├── src/main/java/.../message/
│   ├── ElavonMessage.java
│   ├── ElavonBody.java
│   ├── MessageType.java
│   └── PosDataCode.java
```
