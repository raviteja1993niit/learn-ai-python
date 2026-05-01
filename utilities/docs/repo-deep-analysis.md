# Comprehensive Repo Functionality Analysis
> Dependency order: 1 → 9 (each repo may only depend on earlier-numbered repos)

---

## 1. `card-payment-connectivity` — Independent

### Purpose
The **Card Payment Connectivity (CPC)** service is the **API gateway and routing hub** for all card payment operations. It receives standardised REST requests from upstream systems and routes them to the appropriate acquirer-specific connectivity service downstream.

### Sub-modules

| Sub-module | Role |
|---|---|
| `card-payment-connectivity-service` | Spring Boot 3 REST service — the running application |
| `lib-card-payment-connectivity-test-data` | Shared test utilities: `TestDataConstants`, `copyFieldFromDependency`, Flow builder helpers |

### Key Classes

| Class | Responsibility |
|---|---|
| `AuthorizationApiDelegateImpl` | Handles authorization REST requests, routes downstream |
| `VerificationApiDelegateImpl` | Handles verification REST requests |
| `CaptureApiDelegateImpl` | Handles capture REST requests |
| `ConnectivityRouter` | Selects acquirer service by `acquirerId` |
| `TestDataConstants` | 1,200+ test field-path constants + `copyFieldFromDependency()` utility |

### API Operations Exposed (REST)
- `POST /authorization` — new auth, repeat auth, void auth, update auth
- `POST /verification` — card verification, repeat verification
- `POST /capture` — capture, standalone capture, batch close

### Technology Stack
- Spring Boot 3, Java 17, OpenAPI-generated controllers

### Data Flow
```
Upstream caller
  → CPC REST API
  → ConnectivityRouter (by acquirerId)
  → Acquirer-specific service (Elavon / Barclays / Worldpay)
```

---

## 2. `lib-acquirer-connectivity-domain-api-spec` — Independent

### Purpose
A **pure specification module** — no Java source, no business logic. Contains OpenAPI 3.0 YAML files defining REST API contracts for the entire acquiring stack. The single source of truth for all field paths and schemas.

### Key YAML Files

| File | Defines |
|---|---|
| `card-payment-connectivity-api.yaml` | Full CPC API: Authorization, Void, Capture, Verification, all schemas |
| `acquirer-card-payment-connectivity-api.yaml` | Acquirer-level API consumed by `lib-acquirer-card-payment-api-spec` |

### Notable Schemas

| Schema | Notes |
|---|---|
| `Authorization` | Standard auth request/response |
| `AuthorizationVoid` | Void auth; `serviceProviderTransactionProcessing.authorizationCode` added |
| `Verification` | Card verification; `serviceProviderTransactionProcessing.authorizationCode` added |
| `AuthorizationCode` | Re-usable `$ref` component |
| `AssociatedAuthorization` | References base auth in subsequent void/capture transactions |

### Key Note
All field path strings referenced in test constants (e.g. `"merchant.orderWsApiId"`, `"associatedAuthorization.merchant.transactionWsApiId"`) are derived from the JSON hierarchy of these YAML schemas.

---

## 3. `lib-acquirer-card-payment-api-spec` — Depends on #2

### Purpose
Transforms the OpenAPI YAML from module #2 into **compiled Spring Boot Java code** via `openapi-generator-maven-plugin`. Provides ready-to-use controllers and model POJOs for any acquirer service to implement. Contains no hand-written Java source.

### Key Artifact Details

| Attribute | Value |
|---|---|
| `artifactId` | `lib-acquirer-card-payment-api-spec` |
| `version` | `0.0.105-SNAPSHOT` |
| Generator | `spring` (Spring Boot 3, delegate pattern) |
| Output package | `com.mastercard.mpgs.acquiring.acquirer.*` |

### Generated Content

| Category | Examples |
|---|---|
| Controllers (3) | `AcquirerAuthorizationApiController`, `AcquirerCaptureApiController`, `AcquirerVerificationApiController` |
| Delegate interfaces (3) | `AcquirerAuthorizationApiDelegate`, `AcquirerCaptureApiDelegate`, `AcquirerVerificationApiDelegate` |
| Request models | `AcquirerAuthorizationSubmission`, `AcquirerCaptureSubmission`, `AcquirerVerificationSubmission` |
| Response models | `AcquirerAuthorization`, `AcquirerCapture`, `AcquirerVerification` |
| Supporting models (320+) | `AuthorizationSubmissionMerchant`, `TransactionType`, `CardScheme`, `DigitalWalletType`, etc. |

### Build Process
```
lib-acquirer-connectivity-domain-api-spec JAR (classpath)
  → contains acquirer-card-payment-connectivity-api.yaml
  → openapi-generator-maven-plugin (generate-sources phase)
  → 320+ Java classes in target/
  → compiled into distributable JAR
```

---

## 4. `107092-pgsaascapint-cpc-tspi-mapper-sharedlib` — Independent

### Purpose
Translation library responsible for mapping **CPC models ↔ TSPI** (MegaJSON) format. Acts as the semantic bridge between the REST-style CPC API and Mastercard's internal TSPI binary protocol.

### Key Artifact Details

| Attribute | Value |
|---|---|
| `artifactId` | `cpc-tspi-mapper` |
| `version` | `0.0.1-SNAPSHOT` |

### Key Classes

| Class | Responsibility |
|---|---|
| `CpcTspiTranslator` | Main translator: CPC model ↔ TSPI `TransactionRequest`/`TransactionResponse` |
| `MpgIdMapper` | Maps Mastercard PGS IDs across protocol boundaries |
| `CustomFields` | Defines custom field mappings beyond standard schemas |
| `TspiCustomFieldsMapper` | Maps custom/extension fields in TSPI requests |
| `Operation` | Domain model representing a single payment operation |
| `OperationType` | Enum of all supported operation types |

### Translation Direction
```
CPC REST Request (JSON)
  → CpcTspiTranslator.toTspiRequest()
  → TSPI TransactionRequest (MegaJSON)

TSPI TransactionResponse (MegaJSON)
  → CpcTspiTranslator.toCpcResponse()
  → CPC REST Response (JSON)
```

---

## 5. `107092-pgsaascapint-cpc-tspi-transaction-adapter-sharedlib` — Depends on #3 + #4

### Purpose
The **transaction processing adapter** that wires together the CPC API (from #3) with the TSPI translation layer (from #4). Provides delegate implementations for all API operations and the validation framework that runs before translation.

### Key Artifact Details

| Attribute | Value |
|---|---|
| `artifactId` | `cpc-tspi-transaction-adapter` |
| `version` | `1.0.0-RELEASE` |
| Uses mapper version | `1.64.0-develop` (module #4) |
| Uses card-payment-api-spec version | `0.0.105-SNAPSHOT` (module #3) |

### Key Classes

| Class | Responsibility |
|---|---|
| `ApiDelegateImpl` | Base delegate — receives CPC request, runs validation, calls translator, invokes acquirer |
| `AcquirerAuthorizationApiDelegateImpl` | Authorization-specific delegate |
| `AcquirerVerificationApiDelegateImpl` | Verification-specific delegate |
| `AcquirerCaptureApiDelegateImpl` | Capture-specific delegate |
| `TSPITransactionHandler` | Orchestrates full TSPI transaction lifecycle |
| `ParamsBuilder` | Builds TSPI `TransactionContext` from HTTP headers |
| `HeaderUtils` | Extracts/injects correlation IDs and tracing headers |
| `AcquirerServiceValidation` | Validation entry point, runs all validation rules |
| `TransactionRequestValidationBuilder` | Rule chain builder |
| `TSPIRequest` / `TSPIResponse` | TSPI wire models |
| `ExceptionHandler` | Translates exceptions to HTTP error responses |
| `ConnectivityMetricsAwareImpl` | Adds Micrometer metrics to delegate calls |

### Validation Rules

| Rule | Purpose |
|---|---|
| `SupportedActionValidationRule` | Rejects unsupported operation types |
| `AmountValidationRule` | Validates transaction amount format and range |
| `CurrencyValidationRule` | Validates ISO 4217 currency code |
| `OrderIdValidationRule` | Validates merchant order ID presence/format |
| `OrderDateValidationRule` | Validates order date |
| `VoidReversalValidationRule` | Validates void/reversal has matching base auth |
| `VerificationReversalValidationRule` | Validates verification reversal |
| `IndustryPracticeValidationRule` | Validates industry practice codes |
| `VerificationAmountValidationRule` | Validates verification-specific amounts |

### Full Request Flow (how #3 and #4 are used)
```
CPC REST request (JSON)
  → AcquirerAuthorizationApiController (#3 generated)
  → AcquirerAuthorizationApiDelegateImpl (#5)
  → AcquirerServiceValidation.validate()
  → TSPITransactionHandler.handle()
  → CpcTspiTranslator.toTspiRequest() (#4)
  → TSPI TransactionRequest (MegaJSON)
  → [sent to acquirer service downstream via HTTP]
  → TSPI TransactionResponse (MegaJSON)
  → CpcTspiTranslator.toCpcResponse() (#4)
  → AcquirerAuthorization (#3 model)
  → HTTP 200 response
```

---

## 6. `lib-acquirer-connectivity-tcp` — Independent

### Purpose
A **reusable Netty-based TCP networking library** providing channel builders and clients for binary protocol communication with banking networks. Used by all acquirer services that communicate over TCP (ISO 8583, APACS, JSON, X.25-in-IP).

### Key Classes

| Class | Responsibility |
|---|---|
| `TCPClient` | Single-use Netty TCP client — connect, send, receive, close |
| `PersistentTCPClient` | Long-lived TCP client with keep-alive and reconnect logic |
| `TCPClientConfigurer` | Configures Netty bootstrap (timeouts, SSL, thread groups) |
| `PooledTCPClientConfigurer` | Connection pool variant |
| `TCPChannelBuilder` | Base interface for building Netty pipeline channels |
| `Iso8583TCPChannelBuilder` | Pipeline for binary ISO 8583 (length-prefixed frames) |
| `SSLIso8583TCPChannelBuilder` | SSL-wrapped ISO 8583 channel |
| `StringLengthIso8583TCPChannelBuilder` | ISO 8583 with ASCII-encoded length prefix |
| `ApacsTCPChannelBuilder` | APACS protocol channel builder |
| `JsonTCPChannelBuilder` | JSON-over-TCP channel builder |
| `X25InIPChannelBuilder` | X.25-in-IP (legacy protocol) channel builder |
| `Iso8583FrameDecoder` | Netty decoder: splits byte stream into ISO 8583 frames |
| `StringLengthFieldBasedFrameDecoder` | String-encoded length-delimited frame decoder |
| `JsonDecoder` | JSON frame decoder |
| `ResponseWrapper` | Wraps raw byte response with metadata |
| `TCPReceiver` | Netty inbound handler for receiving responses |
| `SslContextUtils` | SSL/TLS context builder from keystore/truststore |
| `ConnectivityException` | Base exception for TCP connectivity failures |
| `ChannelResponseTimeoutException` | Thrown when response times out |
| `BaseLoadBalancer` | Round-robin or failover load balancing across endpoints |
| `LogContextChannelInitialiser` | Injects MDC logging context into Netty pipelines |

### Supported Protocol Channels

| Protocol | Channel Builder | Use Case |
|---|---|---|
| ISO 8583 (binary) | `Iso8583TCPChannelBuilder` | Standard bank network |
| ISO 8583 + SSL/TLS | `SSLIso8583TCPChannelBuilder` | Secure bank network |
| ISO 8583 + String length | `StringLengthIso8583TCPChannelBuilder` | Some acquirers use ASCII length |
| APACS | `ApacsTCPChannelBuilder` | UK APACS protocol acquirers |
| JSON-over-TCP | `JsonTCPChannelBuilder` | Modern acquirer interfaces |
| X.25-in-IP | `X25InIPChannelBuilder` | Legacy X.25 emulation over IP |

---

## 7. `107651-pgsaaselavon-pgs-acquirer-elavon-interface-service` — Depends on #5 + #6

### Purpose
The **Elavon acquirer interface service** — a Spring Boot microservice that receives TSPI `TransactionRequest` objects from CPC (via module #5) and communicates with the Elavon S2A banking network using ISO 8583 over TCP (via module #6).

### Sub-modules

| Sub-module | Role |
|---|---|
| `lib-elavon-interface-message` | ISO 8583 message definitions, enums, data structures |
| `lib-elavon-interface-mapping` | Message mappers: TSPI ↔ ISO 8583 field translation |
| `lib-elavon-interface-simulation` | Elavon bank simulation for local/test environments |
| `pgs-acquirer-elavon-interface-service` | Main Spring Boot application |
| `lib-elavon-interface-integration-tests` | Integration test suite |
| `lib-elavon-interface-test-data` | Test scenario data and compliance fixtures |

### Key Classes (Main Service)

| Class | Responsibility |
|---|---|
| `ElavonTransactionHandler` | Entry point: receives TSPI request, orchestrates processing |
| `ElavonExceptionHandler` | Catches all exceptions, maps to error responses |
| `ElavonMessageTranslator` | Implements `MessageTranslator<T,U>` — drives translation pipeline |
| `ElavonRequestResponseBuilder` | Builds ISO 8583 request bytes, parses ISO 8583 response bytes |
| `MessageConverterFactory` | Factory: selects correct converter by `OperationType` |
| `ISORequestMessageConverter` | TSPI `TransactionRequest` → ISO 8583 bytes |
| `ISOResponseMessageConverter` | ISO 8583 bytes → MegaJSON `TransactionResponse` |
| `ElavonNettyTcpServer` | Starts/stops internal Netty TCP server (port 17231) |
| `ElavonTcpCommsPipelineBuilder` | Implements `CommsPipelineBuilder` from #6 |
| `ElavonIsoEncoder` / `ElavonIsoDecoder` | ISO 8583 encode/decode |
| `TspiToElavonMessageMapper` | Enum-based: 80+ field mappers TSPI → ISO 8583 |
| `ElavonResponseToMegaJsonMapper` | Enum-based: ISO 8583 response → MegaJSON |
| `ElavonResponseToTspiMapper` | ISO 8583 response → TSPI response |
| `ElavonSimulationService` | Mock Elavon S2A for test/local mode |
| `ScientistPatternHandler` | Validates modernised vs legacy system output (SPT) |
| `ElavonServiceValidation` | Service-level validation |
| `VoidOrReversalValidationRule` | Validates void/reversal has associated authorization |
| `AcquirerActionValidationRule` | Validates operation type is permitted |

### Supported Operations

**Standard:** AUTHORIZATION, BALANCE_ENQUIRY, BATCH_CLOSE, CAPTURE, STANDALONE_CAPTURE, REFUND, STANDALONE_REFUND, PAYMENT, VERIFICATION, UPDATE_AUTHORIZATION, VOID_AUTHORIZATION, VOID_CAPTURE, VOID_PAYMENT, VOID_REFUND, DISBURSEMENT, AGREEMENT_CANCELLATION, REFUND_AUTHORIZATION

**Repeat:** REPEAT_AUTHORIZATION, REPEAT_CAPTURE, REPEAT_REFUND, REPEAT_PAYMENT, REPEAT_VERIFICATION, REPEAT_VOID_AUTH

**Reversals:** REVERSE_AUTHORIZATION, REVERSE_CAPTURE, REVERSE_REFUND, REVERSE_PAYMENT, REVERSE_REFUND_AUTHORIZATION, REVERSE_VOID_REFUND_AUTHORIZATION

**Settlement:** VALIDATE_CAPTURE, VALIDATE_STANDALONE_CAPTURE, VALIDATE_REFUND, VALIDATE_STANDALONE_REFUND, RENDER_SETTLEMENT, START/WRITE/END_INCREMENTAL_SETTLEMENT_RENDER

**Special:** RESPONSE_POLL, SMOKE_TEST, SCHEDULED_PAYMENT_NOTIFICATION

### ISO 8583 Message Type Codes

| MTI | Description |
|---|---|
| 0x1100 | Pre-authorization Request |
| 0x1110 | Pre-authorization Response |
| 0x1200 | Authorization Request |
| 0x1210 | Authorization Response |
| 0x1220 | Refund Authorization Request |
| 0x1230 | Refund Response |
| 0x1420 | Void Authorization Request |
| 0x1430 | Void Authorization Response |
| 0x1804 | Network Management |
| 0x1814 | Network Management Response |

### How #5 (adapter) and #6 (TCP) Are Used

**Module #5 usage:**
- `cpc-tspi-transaction-adapter` (v1.53.0-develop) provides TSPI `TransactionRequest`/`TransactionResponse` models
- `ElavonMessageTranslator` consumes `TransactionRequest` directly
- `MegaJSONUtil` used for MegaJSON utilities

**Module #6 usage:**
- `lib-acquirer-connectivity-tcp` (v0.0.59-RELEASE) provides `TCPClient`, `TCPClientConfigurer`, `CommsPipelineBuilder`
- `ElavonTcpCommsPipelineBuilder` implements `CommsPipelineBuilder` from #6
- `ElavonTCPChannelBuilder` uses `Iso8583TCPChannelBuilder`/`SSLIso8583TCPChannelBuilder` from #6

### Full Transaction Flow
```
TSPI TransactionRequest (from CPC/module #5)
  → ElavonTransactionHandler
  → ElavonServiceValidation.validate()
  → ElavonMessageTranslator.translate()
  → MessageConverterFactory.getConverter(operationType)
  → ISORequestMessageConverter
  → TspiToElavonMessageMapper (80+ field mappers)
  → ISO 8583 binary bytes
  → ElavonTcpCommsPipelineBuilder → TCPClient (#6)
  → [TCP socket → Elavon S2A banking network]
  → ISO 8583 response bytes
  → ElavonIsoDecoder
  → ISOResponseMessageConverter
  → ElavonResponseToMegaJsonMapper
  → MegaJSON TransactionResponse
  → [returned to CPC]
```

### Spring Boot Features
- **Resilience4j circuit breaker** — protects TCP connections
- **Netty TCP server** (port 17231) — receives simulation/test traffic
- **Scientist Pattern Testing (SPT)** — `ScientistPatternHandler` compares modernised output with legacy system reference output
- **Dual-mode connectivity** — test S2A endpoint vs live S2A endpoint (lazy-loaded)
- **Mutual TLS** — SSL certificate authentication for Elavon S2A

---

## 8. `lib-acquirer-test` — Independent

### Purpose
A **specialisation of the [Mastercard Flow test framework](https://github.com/Mastercard/flow)** for the acquiring subsystem. Provides the infrastructure to define a single unified model of system behaviour and assert it across multiple test levels (unit, integration, e2e) without duplication.

### Key Classes

| Class | Responsibility |
|---|---|
| `Integration` | Main assertion class — drives `@TestFactory` for JUnit 5 |
| `IntegrationOptions` | Configuration: entry point, env, acquirerId, URL |
| `TestConfig` | Spring test context configuration |
| `Actors` | Enum: `CARD_PAYMENT_CONNECTIVITY`, `CONNECTIVITY`, `ACQUIRER`, `BANK` |
| `Interactions` | Defines standard CPC ↔ Connectivity ↔ Bank interaction names |
| `Unpredictables` | Field masks for non-deterministic values (timestamps, UUIDs) |
| `ISO8583Message` | Flow `Message` implementation wrapping ISO 8583 bytes |
| `HttpClient` | REST client for integration assertions |
| `AbstractClient` | Base class for entry-point clients |
| `Local` / `Pcf` | Environment implementations (local vs PCF cloud) |
| `CardNumbers` | Standard test card PAN constants |
| `DefaultResidue` | Default ignored field residue for flow assertions |
| `DefaultChecker` | Default field equality checker |
| `ProgressLogger` | Logs test execution progress |
| `Resources` | Loads classpath test resources |
| `DBConfig` / `HttpClientConfig` | Spring configuration for test context |

### Configuration Properties

| Property | Default | Description |
|---|---|---|
| `acquirerId` | (required) | The acquirer ID for test transactions |
| `entryPoint` | `CARD_PAYMENT_CONNECTIVITY` | Entry point: CPC or CONNECTIVITY |
| `env` | `pcf` | Environment: `local` or `pcf` |
| `connectivityUrl` | CPC service URL | Target service URL |
| `mctf.filter.include` | — | Only run flows with all these tags |
| `mctf.filter.exclude` | — | Skip flows with any of these tags |

### Testing Pattern
```
1. Define: Build a Flow model describing expected system behaviour
         e.g. "When CPC receives NewAuth → it sends ISO 8583 Auth to Elavon"
2. Assert: Run Integration.tests() against:
         - Unit level: mock downstream, assert CPC logic
         - Integration level: real CPC → real Elavon (PCF/local)
3. Result: Single test codebase covers unit + integration + e2e
```

### IO Tests (build-time)
```java
@TestFactory
Stream<DynamicNode> tests() {
    return new Integration(MY_MODEL, restTemplate)
        .config(a -> a.setEntryPoint(Actors.CONNECTIVITY.name())
                      .setEnv("local"))
        .tests();
}
```

---

## 9. `107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test` — Depends on #7 + #8

### Purpose
The **complete test suite for the Elavon interface service**. Uses the Flow framework (module #8) to define system behaviour models and assert them against the real Elavon service (module #7) at multiple test levels.

### Sub-modules

| Sub-module | Role |
|---|---|
| `lib-elavon-interface-test-data` | Flow model definitions, test data, scenarios, constants |
| `lib-elavon-interface-integration-tests` | PCF/local integration test runner |

### Key Classes — Test Data Module

| Class | Responsibility |
|---|---|
| `ElavonSystemTransactions` | Root `Model` — registers all transaction flow groups |
| `ElavonAuthTransactions` | Auth flow definitions (FPAN, DPAN, etc.) |
| `ElavonVoidTransactions` | Void flow: base auth + void auth in two-step sequence |
| `ElavonVerifyTransactions` | Verification flow definitions |
| `ElavonCVVTransactions` | CVV-related flow definitions |
| `ElavonCredentialOnFileTransactions` | CoF/recurring transaction flows |
| `ElavonThreeDSecureTransactions` | 3DS flow definitions |
| `ElavonWalletTransactions` | Digital wallet flow definitions |
| `ElavonTimeOutExpiryTransactions` | Timeout and expiry edge case flows |
| `ElavonCompliance` | Compliance test flows |
| `AuthFPANTest` | Full PAN authorization flows |
| `BaseElavon` | Base interaction config: builds CPC + CONNECTIVITY + ISO 8583 interaction templates |
| `TestConstants` | 300+ local field-path string constants (avoiding cross-library dependency) |
| `ElavonAcquirerConstants` | Elavon-specific acquirer constants |
| `Fields` | ISO 8583 field number constants |
| `ElavonTestIsoMapper` | Test-side ISO 8583 message assertion utility |
| `ElavonUtil` | Utility: card data builders, amount formatters |
| `CardData` | Holds test card PAN, expiry, CVV data |
| `ElavonTestMessage` | Elavon-specific `Message` implementation for Flow |
| `Acquirer` | Actor definition for Elavon bank simulator |

### Scenario Enums

| Enum | Scenarios Covered |
|---|---|
| `VoidScenarios` | `VOID_APPROVED`, `VOID_DECLINED`, `VOID_REFERRAL`, etc. |
| `VerifyScenarios` | `VERIFY_APPROVED`, `VERIFY_DECLINED`, etc. |
| `Verify3DSScenarios` | 3DS verification flows |
| `CofScenarios` | Credential-on-file initial transactions |
| `CofCitSubsequentScenarios` | CoF subsequent (MIT/CIT) transactions |
| `CVVScenarios` | CVV pass/fail flows |
| `ThreeDSecureScenarios` | 3DS authentication flows |
| `ExpiryScenarios` | Card expiry edge cases |
| `TimeOutExpiryScenarios` | Network timeout flows |
| `WalletTransactionScenarios` | Apple Pay / Google Pay flows |
| `ElavonComplianceScenarios` | Compliance validation flows |

### Void Flow Design (Recently Updated)

The void flow uses a **two-step dependency pattern**:

```java
// Step 1: base auth flow — sets order and transaction WS API IDs
Flow authFlow = createAuthFlowForScenario(scenario);
// BaseElavon.getElavonAuthBaseInteraction() sets:
//   MERCHANT_TRANSACTION_WS_API_ID = UUID.randomUUID()
//   ORDER_ID = UUID.randomUUID() (via getOrderId())

// Step 2: void flow — copies IDs from step 1
Flow voidFlow = createVoidFlowForScenario(scenario);
// ElavonVoidTransactions.createVoidFlowForScenario() copies:
//   ORDER_ID → ASSOC_AUTH_MERCHANT_ORDER_WS_API_ID
//   MERCHANT_TRANSACTION_WS_API_ID → ASSOC_AUTH_MERCHANT_TRANSACTION_WS_API_ID
// using copyFieldFromDependency(authFlow, REQUEST, REQUEST, fromField, toField)
```

### TestConstants (local) — Key Field Paths

| Constant | Value | Used In |
|---|---|---|
| `ORDER_ID` | `"merchant.orderWsApiId"` | Base auth CPC request |
| `MERCHANT_TRANSACTION_WS_API_ID` | `"merchant.transactionWsApiId"` | Base auth CPC request |
| `ASSOC_AUTH_MERCHANT_ORDER_WS_API_ID` | `"associatedAuthorization.merchant.orderWsApiId"` | Void auth CPC request |
| `ASSOC_AUTH_MERCHANT_TRANSACTION_WS_API_ID` | `"associatedAuthorization.merchant.transactionWsApiId"` | Void auth CPC request |

### Integration Tests Module

| Class | Responsibility |
|---|---|
| `IntegrationTestsApplication` | Spring Boot app for running integration tests |
| `IntegrationTestsConfig` | Test context: configures `RestTemplate`, acquirerId, environment |
| `ProcessingIT` | `@TestFactory` that runs `ElavonSystemTransactions` model via `Integration` from #8 |

### How #7 (Elavon service) and #8 (lib-acquirer-test) Are Used

**Module #7 usage:**
- Imports `lib-elavon-interface-message` for ISO 8583 message type definitions (`MessageType`, `ElavonMessage`)
- Imports `lib-elavon-interface-simulation` for `BankInteraction` (mock bank responses in Flow models)
- Integration tests target the running `pgs-acquirer-elavon-interface-service` (module #7) via HTTP

**Module #8 usage:**
- `Integration` class drives all `@TestFactory` test discovery
- `Actors` enum provides `CARD_PAYMENT_CONNECTIVITY`, `CONNECTIVITY`, `ACQUIRER`, `BANK`
- `Interactions` provides standard interaction name constants
- `ISO8583Message` wraps raw ISO 8583 bytes as Flow `Message`
- `Unpredictables` masks dynamic fields (timestamps, correlation IDs, UUIDs) during assertion

---

## Cross-Cutting Dependency Graph

```
                    ┌─────────────────────────────────────────────┐
                    │  lib-acquirer-connectivity-domain-api-spec   │  (#2)
                    │  (YAML specs only)                           │
                    └────────────────┬────────────────────────────┘
                                     │ generates
                    ┌────────────────▼────────────────────────────┐
                    │  lib-acquirer-card-payment-api-spec          │  (#3)
                    │  (320+ generated Spring Boot models)         │
                    └────────────────┬────────────────────────────┘
                                     │
          ┌──────────────────────────▼──────────────────────────┐
          │  cpc-tspi-mapper-sharedlib                          │  (#4 independent)
          │  (CPC ↔ TSPI translation)                          │
          └────────────────────────┬────────────────────────────┘
                                   │
          ┌────────────────────────▼────────────────────────────┐
          │  cpc-tspi-transaction-adapter-sharedlib (#3 + #4)   │  (#5)
          │  (delegates, validation, TSPI lifecycle)            │
          └──────────────────┬──────────────────────────────────┘
                             │
┌────────────────────────────┼──────────────────────────────────────────┐
│  lib-acquirer-connectivity-tcp (independent)                          │  (#6)
│  (Netty TCP: ISO 8583, APACS, JSON, X.25)                            │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
          ┌──────────────────▼──────────────────────────────────┐
          │  pgs-acquirer-elavon-interface-service (#5 + #6)    │  (#7)
          │  (ISO 8583 ↔ Elavon S2A, 40+ operation types)      │
          └──────────────────┬──────────────────────────────────┘
                             │
┌────────────────────────────┼──────────────────────────────────────────┐
│  lib-acquirer-test (independent)                                      │  (#8)
│  (Flow test framework: model, assert, multi-level)                   │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
          ┌──────────────────▼──────────────────────────────────┐
          │  elavon-interface-service-test (#7 + #8)            │  (#9)
          │  (Flow models + integration test runner)            │
          └─────────────────────────────────────────────────────┘

card-payment-connectivity (#1) runs orthogonally as the upstream API gateway
routing all requests into this pipeline.
```

---

## Key Technology Summary

| Technology | Modules Using It | Purpose |
|---|---|---|
| Spring Boot 3 | #1, #7 | REST API + microservice runtime |
| OpenAPI 3.0 Generator | #2 → #3 | YAML spec → Java code generation |
| Mastercard Flow framework | #8, #9 | Unified test model across unit/integration/e2e |
| Netty (NIO) | #6, #7 | Async TCP for ISO 8583 bank connectivity |
| ISO 8583 | #6, #7, #9 | Banking network message protocol |
| TSPI / MegaJSON | #4, #5, #7 | Mastercard internal transaction protocol |
| Resilience4j | #7 | Circuit breaker for TCP resilience |
| Lombok | #3, #5, #7 | Boilerplate code reduction |
| Java 17 | All | Language baseline |
