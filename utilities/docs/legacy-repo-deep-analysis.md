# Legacy Target Repo — Comprehensive Analysis
> Dependency order: 1 → 6 (each repo may only depend on earlier-numbered repos)
> Source: `C:\Users\e135408\IdeaProjects\MPGS\SourceCode\`
> Elavon S2A (legacy target): `C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice`

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     MERCHANT / FRONTEND                     │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP REST / NVP / VPC
┌───────────────────────────▼─────────────────────────────────┐
│  1. directapi  (WAR v65.47)                                 │
│  Entry point for all merchant-facing card payment API calls │
│  100+ API versions, REST/NVP/VPC/Page servlets              │
└───────────────────────────┬─────────────────────────────────┘
                            │ TNSI Remoting RPC
┌───────────────────────────▼─────────────────────────────────┐
│  2. tnsi-payment-bus-api  (JAR v99.46 — API contract only)  │
│  Internal payment bus interface: 411 classes, all DTOs      │
└───────────────────────────┬─────────────────────────────────┘
                            │ implements payment bus
┌───────────────────────────▼─────────────────────────────────┐
│  3. orchestrator  (WAR v5.107)                              │
│  Coordinates routing, split orders, cross-region, Kafka     │
└────────┬───────────────────────────────────┬────────────────┘
         │ TNSI Remoting                     │ TNSI Remoting
┌────────▼─────────────┐       ┌─────────────▼──────────────┐
│  4. cardpaymentengine│       │  5. externalacquirerservice │
│  (WAR v10.73)        │       │  (WAR v1.67)                │
│  Core payment logic  │       │  HTTP/TLS to REST acquirers │
│  60+ card brands     │       │  Channel manager, circuit   │
│  Routing/rules engine│       │  Settlement file/polling    │
└────────┬─────────────┘       └─────────────────────────────┘
         │ TNSI Remoting
┌────────▼──────────────────────────────────────────────────┐
│  6. acqelavons2aservice  (WAR v1.10.131 — MODERNIZATION)  │
│  Elavon ISO 8583 / TCP-SSL acquiring service              │
│  Modular: message + mapping + connectivity + settlement   │
└───────────────────────────────────────────────────────────┘
```

---

## 1. `directapi` — Independent (Entry Point)

### Purpose
The **Direct API** is the **primary merchant-facing REST gateway** — the front door of the Mastercard Payment Gateway Services (MPGS) system. It exposes a versioned REST/NVP/VPC API to merchants and routes all payment operations downstream through the TNSI remoting layer.

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `api` (Group: `com.dialect`) |
| Version | `65.47.0-SNAPSHOT` |
| Packaging | WAR |
| Server | Jetty 9.4.58 (port 8080, context `/api`) |
| Spring | 5.3.39-atlassian-9 (MVC, not Boot) |
| Total Java files | 1500+ (across 100+ versioned packages) |

### Sub-packages

| Package | Role |
|---|---|
| `com.dialect.gateway.merchant.v1–v100+` | 100+ API versions, each with operations + canonicals |
| `com.dialect.gateway.merchant.utility.internal` | Core request pipeline (servlets, executor) |
| `com.dialect.gateway.merchant.utility.api` | API contracts, routing, specs |
| `com.dialect.gateway.merchant.utility.crypto` | JWE, RSA encryption |
| `com.dialect.gateway.merchant.configuration` | Spring config (TLS, DB, billing, metrics) |
| `com.dialect.gateway.merchant.shopify` | Shopify integration |
| `com.dialect.gateway.publickeys` | Public key distribution |
| `com.dialect.utility` | Auth filters, web security |

### Key Classes

| Class | Responsibility |
|---|---|
| `RestGatewayServlet` | REST/JSON HTTP endpoint handler |
| `NvpGatewayServlet` | Name-Value Pair (NVP) endpoint handler |
| `PageGatewayServlet` | Page/hosted-form requests |
| `VpcRefundServlet` | VPC (Virtual Payment Channel) refund |
| `SpringBootServlet` | Spring container initialization |
| `RequestExecutor` | Core pipeline: parse → auth → throttle → dispatch → respond |
| `FlowControlFacade` | Rate limiting and throttling |
| `FacadeServiceCorrelationIdDecorator` | Correlation ID injection |
| `ApiAccessControlServiceClient` | API access control |
| `MultiSiteConfiguration` | Multi-site TLS, failover |
| `MultiSiteDelegationFilter` | Cross-site failover filter |
| `CryptoServiceClient` | HSM/encryption calls |
| `JweHelper` | JSON Web Encryption |
| `VersionSpecification` | Base class for version registration |
| `ShopifyServlet` | Shopify-specific flow |
| `PublicKeysServlet` | JWK public key endpoint |
| `DocumentationServlet` | Serves OpenAPI JSON documentation |

### API Versioning
100+ API versions (`v1` → `v100+`). Each version class registers supported operations. Latest active version ~`v85+`. Each version has:
- `Version<N>.java` — registers operations
- `canon/` — `*RequestBean.java` / `*ResponseBean.java` (input/output models)
- `operation/` — business operation classes

### Core API Operations (Latest Version)

| Operation | HTTP | Purpose |
|---|---|---|
| Pay | PUT | Auth + capture in one step |
| Authorize | PUT | Authorization hold only |
| Capture | PUT | Complete previously authorized hold |
| Refund | PUT | Return funds to cardholder |
| Void | PUT | Cancel auth or capture |
| UpdateAuthorization | PUT | Adjust authorization amount |
| SaveCard | POST | Tokenize card (store for future use) |
| RetrieveTransaction | GET | Fetch transaction detail |
| RetrieveOrder | GET | Fetch order detail |
| InitiateAuthentication | PUT | Start 3DS authentication flow |
| AuthenticatePayer | PUT | Complete 3DS authentication |
| InitiateBrowserPayment | PUT | HPP/APM payment initiation |
| ConfirmBrowserPayment | PUT | HPP payment confirmation |
| UpdateSession | PUT | Session state management |
| CreateOrUpdateMerchant | PUT/POST | Merchant management |

### REST URL Pattern
```
/api/rest/version/{versionId}/merchant/{merchantId}/order/{orderId}/transaction/{transactionId}
```

### Supported Protocols

| Protocol | Servlet | Use Case |
|---|---|---|
| REST/JSON | `RestGatewayServlet` | Modern merchant integrations |
| NVP | `NvpGatewayServlet` | Legacy Name-Value Pair merchants |
| VPC | `VpcRefundServlet` | Virtual Payment Channel refunds |
| Page/HPF | `PageGatewayServlet` | Hosted Payment Form |
| XML | `DpgXmlApiForwarderServlet` | Legacy XML merchants (forwarded) |

### Key Dependencies
- `tnsi-payment-bus-api:99.43.0` — Payment bus DTOs and interfaces
- `tnsi-payments-api:1.57.3` — Payment domain objects
- `tnsi-business-service-api:99.63.3` — Merchant/business entities
- `tnsi-token-service-api:1.44.1` — Card tokenization
- `tnsi-hosted-payment-form-api:1.49.1` — HPF integration
- `tnsi-crypto-managed:99.29.0` — HSM encryption
- `infrastructure-api:99.24` — Mastercard platform infrastructure
- `tnsi-remoting:99.15.1` — Internal RPC transport
- `kryo:5.4.0` — Java object serialization
- `Rhino/Nashorn` — JavaScript engine for UDM spec generation

---

## 2. `tnsi-payment-bus-api` — Independent (API Contract Library)

### Purpose
The **TNSI Payment Bus API** is the **internal service contract library** — a pure Java API JAR (no business logic) that defines all request/response DTOs, service interfaces, and exceptions for the internal payment processing bus. It is the shared interface consumed by `directapi` (caller) and `orchestrator` (implementer).

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `tnsi-payment-bus-api` (Group: `com.dialect`) |
| Version | `99.46.1-SNAPSHOT` |
| Packaging | JAR (no business logic) |
| Purpose | Internal remote API for processing payments across all gateways |
| Total Classes | 411 |

### Package Structure

| Package | Count | Content |
|---|---|---|
| `com.dialect.paymentbus.api` | 27 | Service interfaces + 24 exception classes |
| `com.dialect.paymentbus.message` | 38 | Request/Response message wrappers |
| `com.dialect.paymentbus.dto` | 340+ | All domain data transfer objects |
| `com.tnsi.remoting.spring` | 2 | JSON converters for CardType serialization |

### Core Service Interfaces

| Interface | Purpose |
|---|---|
| `OrderService` | Order and transaction retrieval operations |
| `CardBrandService` | Card type identification and validation |
| `TransactionRetrieval` | Transaction retrieval by various criteria |

### Exception Hierarchy (24 types, all extend `PaymentBusException`)

| Category | Exceptions |
|---|---|
| Field validation | `InvalidFieldException`, `MissingFieldException`, `FieldValueRejectedException`, `ConstraintViolationException`, `UnsupportedFieldException` |
| State/operation | `InvalidStateException`, `OperationInProgressException`, `ResourceAlreadyExistException`, `NotFoundException` |
| Business | `OrderConstraintException`, `SanctionedException`, `MultiSiteConsistencyException`, `InsufficientPrivilegeException`, `RiskConfigurationException` |
| System | `ServerBusyException`, `ServerFailedException`, `SystemErrorException` |

### Message Classes (38 total)

**Requests:** `AuthenticationIdRequest`, `InitiateBrowserPaymentRequest`, `ConfirmBrowserPaymentRequest`, `OrderDetailsRequest`, `TransactionRetrievalRequest`, `NpciSIAdviceRequest`, `DeletePaymentLinkRequest`, + 7 more

**Responses:** `TransactionResponse`, `OrderDetailsResponse`, `TransactionDetailsResponse`, `AuthenticationIdResponse`, `TokenizeBrowserPaymentResponse`, `DeletePaymentLinkResponse`, `UpdateRiskAssessmentResponse`, + 9 more

### Key DTO Categories (340+ classes)

| Category | Key DTOs |
|---|---|
| Card | `CardPayment`, `CardDetails`, `CardBrand` (AMEX/VISA/MC/etc.), `CardScheme`, `CardToken`, `CardBin`, `AccountFundingMethod`, `CardTypeDetails` |
| Order | `Order`, `Payment`, `Transaction`, `TransactionResponse`, `AgreementDetails`, `PaymentPlan`, `LineItems`, `Discount` |
| Authentication | `Authentication`, `Authentication3dSecure`, `Authentication3dSecureSdk`, `AuthenticationStatus`, `AuthenticationType` |
| POS/Terminal | `MerchantDetails`, `PosTerminalAttended`, `PosTerminalInputCapability`, `PosTerminalPanEntryMode`, `PosTerminalPinEntryCapability` |
| Risk | `GatewayRecommendation`, `Dynamic3DSecureRecommendation` |
| Wallet/APM | `AppPayment`, `BrowserPayment`, `BrowserPaymentDetails`, `KnetDetails`, `GiropayDetails`, `CitiBoletoDetails` |
| Protocols enum | PC, VPC, MA, REST_JSON, NVP, HB_NATIVE, HOSTPAGE |
| Transaction source enum | MOTO, SSL, PC, AUTO, DIRECT, TOKEN, PAYMENT_LINK, SERVICE_PROVIDER_API, RISK_INITIATED, etc. |

### What is the Payment Bus?
An **internal RPC messaging layer** (TNSI Remoting over HTTP/JSON) acting as middleware between merchant-facing APIs and the payment processing engine. It abstracts protocol differences and provides a uniform operation model across VPC, REST, NVP, and batch integrations.

---

## 3. `orchestrator` — Depends on #2

### Purpose
The **Orchestrator** is the **transaction routing and coordination hub**. It implements the `tnsi-payment-bus-api` interfaces and acts as the central controller that:
- Routes transactions to CPE (Card Payment Engine) or external acquirers
- Manages split-order surcharge flows (parent + child orders)
- Handles cross-region request proxying (with encryption)
- Publishes transaction events to Kafka via Axon SDK
- Enforces distributed order locking

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `orchestrator` (Group: `com.tnsi`) |
| Version | `5.107.0-SNAPSHOT` |
| Packaging | WAR |
| Spring | 5.3.39-atlassian-9 |
| Database | PostgreSQL + Liquibase |
| Messaging | Kafka 2.5.0 + Axon SDK 4.0.1 |
| Total Classes | 751+ |

### Sub-packages

| Package | Role |
|---|---|
| `com.dialect.orchestrator.service` | Core orchestration service implementations |
| `com.dialect.orchestrator.routing` | Transaction routing logic |
| `com.dialect.orchestrator.decorator` | Request data enrichment (auth, wallet, CoF) |
| `com.dialect.orchestrator.validator` | Input validation (30+ validators) |
| `com.dialect.orchestrator.persistence` | Transaction data persistence |
| `com.dialect.orchestrator.axon` | Kafka/Axon event production |
| `com.dialect.orchestrator.delegate` | Remote service clients |
| `com.dialect.orchestrator.crossregion` | Cross-region proxy controller |
| `com.dialect.orchestrator.loadbalancer` | Acquirer load balancing |
| `com.dialect.orchestrator.crypto` | Encryption/decryption |
| `com.dialect.orchestrator.billing` | Billing event generation |
| `com.mastercard.gateway.transactionmanager` | Split-order transaction management |
| `com.mastercard.gateway.historicalrefunds` | Historical refund processing |

### Key Classes

| Class | Responsibility |
|---|---|
| `OrchestratorService` | Master interface: all payment operations |
| `RecordOrchestratorServiceImpl` | Concrete impl: records txns, produces Kafka events |
| `BoostOrchestratorServiceImpl` | Abstract: decorates requests (wallet, auth, CoF) |
| `TransactionManagerServiceImpl` | Split-order: parent + child order processing |
| `CrossRegionController` | `@RestController`: `/x-region/status` + `/x-region/delegate` |
| `CrossRegionReceiverService` | Processes inbound encrypted cross-region requests |
| `RoutedServicesDelegate` | Routes to CPE or external acquirer |
| `TransactionDataService` | Persists transaction records to PostgreSQL |
| `TransactionInjectionCompletedEventProducer` | Produces Avro events to Kafka |
| `PaymentLockingAspect` | `@Aspect`: distributed lock via `@PaymentLock` annotation |
| `PayerAuthenticationDecorator` | Adds 3DS auth data to requests |
| `MobileWalletDecorator` | Adds scheme token data (Apple Pay/Google Pay) |
| `AgreementDetailsDecorator` | Adds recurring/CoF agreement details |
| `EmvRequestDecorator` | Adds EMV/chip card data |
| `BusinessResolver` | Resolves merchant/MSO business entity |
| `SplitOrderHelper` | Determines split-order routing logic |
| `RevertParentProcessor` | Voids parent order when child fails |

### REST Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/x-region/status` | Health check: returns `{"health":"active"}` |
| POST | `/x-region/delegate` | Cross-region proxy: decrypt → route → encrypt response |

### Integration Points (Downstream)

| Service | Protocol | Purpose |
|---|---|---|
| Card Payment Engine (CPE) | TNSI Remoting | Core transaction processing |
| External Acquirer Service | TNSI Remoting | HTTP-based acquirers |
| Risk Service | TNSI Remoting | Fraud/risk assessment |
| Token Service | TNSI Remoting | Card tokenization |
| MPI Service | TNSI Remoting | 3DS authentication |
| Surcharge Service | TNSI Remoting | Surcharge calculation |
| Batch / Chargeback Service | TNSI Remoting | Settlement and chargebacks |
| Card Service V2 | TNSI Remoting | Card storage/retrieval |
| Authentication Service | HTTP/REST | 3DS authentication API |
| Business Service | Cached RPC | Merchant entity resolution |
| Billing Client | TNSI Remoting | Billing record creation |
| Kafka | Axon SDK (Avro) | Transaction completion events |
| PostgreSQL | Hibernate/JDBC | Transaction persistence |

### Split-Order Surcharge Flow

```
AuthorisationRequest (with surcharge)
  ├─ [1] Calculate surcharge → SurchargeService
  ├─ [2] Generate child OrderId (charge amount)
  ├─ [3] Lock both orders (@PaymentLock)
  ├─ [4] Process PARENT order → CPE
  ├─ [5] If parent SUCCESS → Process CHILD order → CPE
  ├─ [6] If child FAILS → RevertParentProcessor (void parent)
  └─ [7] Return combined TransactionResponse
```

### Kafka / Axon Event Streaming

- **Event:** `TransactionInjectionCompletedEvent` (Avro serialized)
- **Avro schemas:** `transactionInjectionCompletedEvent.avsc`, `eventMetaData.avsc`, `orderId.avsc`
- **Purpose:** Downstream systems subscribe to transaction completion notifications
- **Producer types:** `TransactionInjectionCompletedEventAxonProducer` (Kafka) + logging variant

### Validation Framework
30+ validators covering: Amount, Currency, Authorization/Pay request, Capture, Refund, Card enrollment, EMV, Industry data, VPCM, Account funding, Payment links, Tokens, Risk assessment.

### Key Dependencies
- `tnsi-payment-bus-api:99.43.0` — Payment bus contract (implements it)
- `tnsi-liquid-transactions:1.57.3` — Liquid transaction framework
- `tnsi-risk-service-api:1.77.0` — Risk service API
- `tnsi-billing-client:1.94.0` — Billing integration
- `tnsi-order-lock:99.42.1` — Distributed order locking
- `axon-sdk:4.0.1` — Kafka event-driven framework
- `kafka-clients:2.5.0` — Kafka messaging
- `pgs-avro-spec-transaction-injection:2.0.11` — Avro schema
- `infrastructure-tls-client-api:99.24.0` — Secure TLS communication

---

## 4. `cardpaymentengine` — Depends on #2 + #3

### Purpose
The **Card Payment Engine (CPE)** is the **core payment processing engine** — an enterprise-grade payment processor that handles actual financial transaction logic. It supports 60+ card brands, 12+ transaction types, intelligent acquirer routing, 3DS authentication, risk integration, and multi-acquirer communication.

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `cardPaymentEngine` (Group: `com.tnsi`) |
| Version | `10.73.1-SNAPSHOT` |
| Packaging | WAR |
| Spring | 5.3.39-atlassian-9 (traditional MVC, not Boot) |
| Database | Relational DB (Hibernate) + Cassandra (high volume) |
| Total Classes | 577+ |

### Package Structure

| Package | Role |
|---|---|
| `QSI.Payment.*` | 60+ card brand payment classes |
| `QSI.Transaction.*` | Financial transaction objects |
| `QSI.PaymentServer.*` | Server entry points, adaptors, controllers |
| `com.qsipayments.paymentserver.paymentengine.*` | Main engine implementation + executors |
| `com.dialect.paymentserver.paymentbus.*` | Service layer (implements payment bus) |
| `com.mastercard.gateway.*` | Mastercard-specific utilities |

### Core Engine Classes

| Class | Responsibility |
|---|---|
| `PaymentEngineImpl` | Primary engine: auth, purchase, capture, refund, void |
| `RoutingPaymentEngine` | Routes transactions local or remote; load balancing |
| `RemotePaymentEngine2` | Remote engine delegate |
| `TransactionExecutorFactory` | Dispatcher: selects executor by transaction type |
| `PurchaseExecutor` | Purchase transaction execution |
| `AuthorisationExecutor` | Authorization hold |
| `CaptureExecutor` | Capture authorized amount |
| `RefundExecutor` | Refund processing |
| `VoidExecutor` | Void auth/capture |
| `VerificationExecutor` | AVS/card verification (no charge) |
| `UpdateAuthorisationExecutor` | Adjust auth amount (tips etc.) |
| `DisbursementExecutor` | Disbursement transactions |
| `AutoCaptureExecutor` | Auto-capture after auth |
| `RoutingDecisionHelper` | Routing engine: selects acquirer by rules |
| `AcquirerLinkSelector` | Evaluates merchant-acquirer relationships |
| `MerchantLoadBalancer` | Distributes load across merchants |
| `SchemeTransactionThrottleHelper` | Active/passive transaction throttling |
| `ThreeDSRouterService` | Routes to correct 3DS directory server |

### Service Layer

| Service | Responsibility |
|---|---|
| `PurchaseServiceImpl` | Purchase orchestration |
| `AuthorisationServiceImpl` | Authorization orchestration |
| `CaptureServiceImpl` | Capture orchestration |
| `RefundServiceImpl` | Refund orchestration |
| `VoidServiceImpl` | Void orchestration |
| `MpiServiceImpl` | 3DS MPI integration |
| `CardBrandServiceImpl` | Card brand determination + BIN lookup |
| `BinBaseLookupService` | BIN database lookup |
| `RiskAssessmentServiceClient` | Remote risk service calls |
| `CardMaskingService` | PCI: card number masking in logs |
| `TransactionProtectionServiceImpl` | Fraud protection integration |

### Transaction Types

| Type | Code | Purpose |
|---|---|---|
| Purchase | 00 | Auth + capture in one step |
| Pre-authorization | 01 | Authorization hold only |
| Capture | 03 | Complete pre-auth |
| Refund | 04 | Return funds |
| Void Auth | 05 | Cancel authorization |
| Void Purchase | 06 | Cancel purchase |
| Void Capture | 07 | Cancel capture |
| Void Refund | 08 | Cancel refund |
| Update Authorization | 09 | Adjust amount (tips) |
| Credit Payment | 10 | Standalone credit |
| AVS Verification | — | Address check only (no charge) |
| Balance Inquiry | — | Prepaid/gift card balance |
| Batch Close | — | Settlement batch |
| ATC Update | — | EMV application counter sync |
| Acquirer Tokenization | — | Token generation |

### 60+ Supported Card Brands

Visa, VisaDebit, VisaPurchaseCard, VisaITMX, Mastercard, MastercardPurchaseCard, MastercardITMX, Amex, AmexPurchaseCard, Diners, JCB, Discover, Maestro, Laser, Switch, China Union Pay, RuPay, ELO, VERVE, Girocard variants, Banamex, Soriana, QCard, PayPak, Jaywan, CarteBancaire, Carnet, Private Label (Costco, Dillard's, Vitamin Shoppe, Bed Bath & Beyond), and more.

### Acquirer Message Formats

| Format | Handler | Used For |
|---|---|---|
| MegaMessage | `MegaMessageMap`, `MegaMessageRequestBuilder` | Main acquirer format |
| S2I (Mastercard) | `S2IAcquirerV1`, `S2IAcquirerConstants` | Mastercard S2I network |
| CBSG | `CbsgIMerchantTransactionProcessor` | CBSG iMerchant |
| PayPipe | `PayPipeMessageMap` | PayPipe acquirer |
| TSPI | `TspiRequestMessageBuilder` | Modern TSPI acquirers (Elavon etc.) |
| ISO 8583 | ISO8583 transport | Legacy bank networks |

### Routing Decision Factors
1. **Source of Funds** — Credit/debit/prepaid, digital wallet
2. **Transaction type** — Purchase, auth, capture, refund
3. **Merchant context** — MCC, region, acquirer relationships
4. **Risk assessment** — Risk score, throttling rules, fraud prevention
5. **3DS requirements** — PSD2, regional authentication mandates
6. **Scheme rules** — Mastercard/Visa scheme-specific routing

### Infrastructure Features
- **Cassandra** — High-volume NoSQL transaction storage (`CassandraThreeDSService`, `CassandraRuPayBinRecordsService`)
- **Spring ORM/Hibernate** — Relational DB persistence
- **Spring JMS** — Settlement and batch notifications
- **JMX beans** — Live metrics (transaction counts, latency, batch performance)
- **50+ Spring XML contexts** — Acquirer-specific, 3DS, DCC, risk, security
- **AOP** — Transaction management, security, metrics as cross-cutting concerns

---

## 5. `externalacquirerservice` — Depends on #2 + #3

### Purpose
The **External Acquirer Service (EAS)** is a **bridge service** that routes payment transactions from MPGS to **REST-based external acquirers** (non-ISO-8583) using HTTP/HTTPS with optional mTLS. It handles online authorization, settlement file submission, settlement polling, and settlement validation.

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `externalAcquirerService` (Group: `com.mastercard.gateway`) |
| Version | `1.67.0-SNAPSHOT` |
| Packaging | WAR |
| Server | Jetty 9.4.29 (port 9091 SSL) |
| Spring | 5.3.39 (MVC) |
| Total Classes | 47 main classes |

### Package Structure

| Package | Role |
|---|---|
| `channel/` | 6 channel types + circuit breaker per acquirer |
| `service/` | Online, SettlementFile, SettlementPolling, SettlementValidation |
| `http/` | TLS and Partner HTTP client implementations |
| `cache/` | IntegrationPartnerSupportCache (acquirer config) |
| `remoting/` | OnlineRemoteService, SettlementRemoteService |
| `monitoring/` | JMX metrics |
| `configuration/` | Spring beans (TLS, remoting, OpenAPI) |
| `siteproperty/` | Default configuration properties |

### Key Classes

| Class | Responsibility |
|---|---|
| `OnlineRemoteService` | `@RemoteService("OnlineInterface_EXTERNAL_ACQUIRER")` — RPC entry point |
| `OnlineService` | Core: decorates, JSON-schema-validates, routes to acquirer HTTP |
| `SettlementFileService` | Generates and transmits settlement batch files |
| `SettlementPollingService` | Polls acquirer for settlement response status |
| `SettlementValidationService` | Validates settlement transactions before submission |
| `ChannelManager` | Creates/caches channel instances by type + acquirer ID |
| `CircuitBreakerManager` | Per-acquirer circuit breakers |
| `IntegrationPartnerSupportCache` | 1000-entry, 10-min refresh cache of acquirer configs from IPS |
| `ExternalAcquirerServiceTlsHttpClient` | HTTPS/mTLS client (Mastercard TLS v99.23.4) |
| `ExternalAcquirerServicePartnerHttpClient` | HTTP via PartnerHttpClient (secure/insecure) |
| `ExternalAcquirerServiceHttpClientFactory` | Factory: selects TLS or Partner client per acquirer |
| `WhitelistDataSanitiser` | Filters/sanitizes acquirer request data by whitelist |
| `ServiceProviderStatusPollingJob` | Scheduled: polls service provider status |
| `AcquirerServiceClient` | Fetches acquirer configs (Stripe check, IPS data) |
| `FirstDataRemoteService` | First Data-specific: retrieves DataWire ID via remoting |

### Channel Types

| Channel | HTTP Variant | Remoting Variant | Use Case |
|---|---|---|---|
| `ONLINE` | `OnlineHttpChannel` | `OnlineRemotingChannel` | Real-time authorization |
| `ONLINE_SERVICE_ROUTING` | `OnlineServiceRoutingHttpChannel` | `OnlineServiceRoutingRemotingChannel` | Multi-acquirer routing |
| `SETTLEMENT_FILE` | `SettlementFileHttpChannel` | `SettlementFileRemotingChannel` | Batch file upload |
| `SETTLEMENT_POLLING` | `SettlementPollingHttpChannel` | `SettlementPollingRemotingChannel` | Poll for batch results |
| `SETTLEMENT_VALIDATION` | `SettlementValidationHttpChannel` | `SettlementValidationRemotingChannel` | Validate before submit |
| `RECORD_ACQUIRER_RESPONSE` | — | `RecordAcquirerResponseRemotingChannel` | Log acquirer responses |

### Protocol

**JSON/REST over HTTP** (NOT ISO 8583):
- **LiquidBean** (MegaJSON) internal message format
- **HTTP POST/GET** to acquirer REST endpoints
- **mTLS** optional (`mpgs.externalAcquirer.connection.mtls.enabled`)
- **TNSI Remoting** for internal RPC
- **ActiveMQ** (JMS v5.19.0) for async messaging

### Supported Acquirers
- **First Data** — dedicated `FirstDataRemoteService` for DataWire ID retrieval
- **Stripe** — feature-toggle support (`isStripeEnabled()`)
- **Generic REST acquirers** — dynamically configured via IPS cache
- **Any HTTP-based acquirer** — configurable through `IntegrationPartnerSupportCache`

### Transaction Categories

| Category | Channel | Service |
|---|---|---|
| Online Authorization | `ONLINE` | `OnlineService` |
| Settlement File | `SETTLEMENT_FILE` | `SettlementFileService` |
| Settlement Polling | `SETTLEMENT_POLLING` | `SettlementPollingService` |
| Settlement Validation | `SETTLEMENT_VALIDATION` | `SettlementValidationService` |

---

## 6. `acqelavons2aservice` — Depends on #3 + #4 (Indirect)

### Purpose
The **Elavon S2A Acquirer Service** is the **ISO 8583 / TCP-SSL acquiring service for Elavon** — one of the world's largest payment acquirers. It translates TSPI (MegaJSON) transaction requests into ISO 8583 binary messages and sends them to Elavon's S2A (Secure-to-Acquirer) banking network over TCP with mutual TLS.

### Key Details

| Attribute | Value |
|---|---|
| Artifact ID | `acqElavonS2A` (Group: `com.mastercard.gateway.acquiring`) |
| Version | `1.10.131-SNAPSHOT` |
| Packaging | Multi-module WAR reactor |
| Spring | 5.3.39 (MVC + MPGS infra framework) |
| Protocol | ISO 8583 over TCP + mutual TLS |

### Sub-modules

| Module | Artifact | Role |
|---|---|---|
| `acqElavonS2AService` | WAR | Deployable Spring MVC web application |
| `libmpgs-message-elavon` | JAR | ISO 8583 message definitions (60+ fields) |
| `libmpgs-mapping-elavon` | JAR | TSPI ↔ ISO 8583 bi-directional field mappers |
| `libmpgs-connectivity-elavon` | JAR | Netty TCP/SSL channel builder + ISO encoder/decoder |
| `libmpgs-settlement-elavon` | JAR | Settlement file parsing, rendering, SFTP transmission |
| `libmpgs-elavon-test-data` | JAR | Test data corpus for compliance/certification |
| `elavon-integration-tests` | JAR | Cucumber/JUnit BDD integration tests |

### Key Classes (Main Service)

| Class | Responsibility |
|---|---|
| `ElavonOnlineRemoteService` | `@RemoteService` — Main online authorization handler |
| `ElavonPollingRemoteService` | Background polling for async responses |
| `ElavonSettlementRemoteService` | Settlement file processing |
| `ElavonHealthCheckRemoteService` | Network health monitoring |
| `ElavonSpyModeRemoteService` | Test/debug message intercept mode |
| `MegaJsonToElavonMessageMapper` | TSPI → ISO 8583 field mapping (40+ fields) |
| `ElavonResponseToMegaJsonMapper` | ISO 8583 → TSPI response mapping |
| `ISORequestMessageConverter` | MegaJSON → ISO 8583 binary bytes |
| `ISOResponseMessageConverter` | ISO 8583 bytes → MegaJSON |
| `ElavonMessageConverterConfig` | Spring beans for 15+ message converters |
| `ElavonMessageCommsConfig` | TCP/SSL connection configuration |
| `ElavonGftConfig` | GFT (Global File Transfer / SFTP) config |
| `ElavonSptPublisherService` | SPT event publisher for transaction lifecycle |
| `ElavonSettlementRenderRequestHandler` | Settlement render pipeline |
| `ElavonIncrementalSettlementRenderRequestHandler` | Incremental batch settlement |
| `ElavonGftSettlementCommsImpl` | SFTP-based settlement file transmission |
| `ElavonTestModeValidation` | Test vs live mode detection |
| `VoidOrReversalValidationRule` | Validates void has matching base auth |
| `CAVV_UCAFValidationRule` | 3DS cryptogram validation |
| `ElavonMessageSanitizer` | PCI: masks sensitive data in logs |

### ISO 8583 Key Field Mapping

| ISO Field | TSPI Source | Format |
|---|---|---|
| F2 — PAN | `card.primaryAccountNumber` | BCD, max 19 |
| F4 — Amount | `amount` | BCD, 12-digit |
| F11 — STAN | `systemTraceAuditNumber` | BCD, 6 |
| F14 — Expiry | `card.expiryDate` | BCD YYMM |
| F22 — POS Data | `merchant.posDataCode` | Variable |
| F37 — Reference | `merchant.orderWsApiId` | Fixed 12 |
| F38 — Approval Code | Response only | Fixed 6 |
| F39 — Action Code | Response: 001=Approved | BCD 3 |
| F41 — Terminal ID | `merchant.terminalId` | BCD 8 |
| F42 — Merchant ID | `merchant.merchantId` | Fixed 15 |
| F49 — Currency | `currency` (ISO 4217) | BCD 3 |
| F53 — CVC/CAVV | `card.cvv` / `threeDSecure.cavv` | Variable |
| F55 — ICC/EMV | `card.emvData` | Variable, max 255 |

### ISO 8583 Message Types (MTI)

| MTI | Description |
|---|---|
| 1100 | Pre-authorization Request |
| 1110 | Pre-authorization Response |
| 1200 | Authorization Request |
| 1210 | Authorization Response |
| 1220 | Refund Authorization Request |
| 1230 | Refund Response |
| 1420 | Void Authorization Request |
| 1430 | Void Authorization Response |
| 1804 | Network Management (Health Check) |
| 1814 | Network Management Response |

### Validation Rules

| Rule | Purpose |
|---|---|
| `CAVV_UCAFValidationRule` | 3DS cryptogram presence check |
| `AcquirerTxnIdValidationRule` | STAN format validation |
| `AcquirerActionValidationRule` | Valid action codes |
| `MerchantTrxReferenceValidationRule` | Reference number format |
| `MerchantPaymentGatewayIDRule` | Payment gateway ID format |
| `Recurring3DSValidationRule` | CoF + 3DS combination rules |
| `VoidOrReversalValidationRule` | Must reference original transaction |

### Settlement Sub-system

| Class | Role |
|---|---|
| `ElavonSettlementOperations` | Main: validate + render + transmit |
| `ElavonAllInOneSettlementRender` | Monolithic settlement file format |
| `ElavonIncrementalSettlementRender` | Incremental/batch settlement updates |
| `ElavonSettlementValidator` | Settlement rule validation |
| `ElavonGftSettlementCommsImpl` | SFTP upload to Elavon |

**Settlement File Structure:**
```
FILE_HEADER (processor info, date, file ID)
  BATCH_HEADER
    TRANSACTION_DETAIL (+ AUXILIARY + ADDENDUM records)
    ...
  BATCH_TRAILER (batch totals: count, amount, fees)
FILE_TRAILER (file totals: all batches summed)
```

### Legacy vs Modernized Elavon Comparison

| Aspect | Legacy `acqelavons2aservice` | Modernized `107651-pgsaaselavon` |
|---|---|---|
| Framework | Spring MVC + MPGS infra | Spring Boot 3 |
| Entry point | Called via TNSI Remoting from CPE | Called via REST from `card-payment-connectivity` |
| Remote services | `@RemoteService` (Online, Polling, Settlement, SpyMode, HealthCheck) | REST endpoint via lib-acquirer-connectivity |
| Mapping | `libmpgs-mapping-elavon` (dedicated module) | `lib-elavon-interface-mapping` (equivalent module) |
| Connectivity | `libmpgs-connectivity-elavon` (Netty + SSL) | `lib-acquirer-connectivity-tcp` + Elavon Netty pipeline |
| Settlement | `libmpgs-settlement-elavon` with SFTP | Embedded in service |
| SPT / Spy mode | `ElavonSpyModeRemoteService` + `SptPublisherService` | `ScientistPatternHandler` |
| Test framework | Cucumber BDD + integration tests | Flow framework + IO tests |
| Configuration | Site properties + `@Property` | Spring Boot properties |
| Health monitoring | Multi-level: `ElavonLiveOnlineHealthMonitor` + `ElavonTestOnlineHealthMonitor` | Circuit breaker only |
| PCI compliance | `ElavonMessageSanitizer` + masked reflection | `ElavonMessageSanitizer` equivalent |

---

## Cross-Cutting Dependency Summary

```
MERCHANT
  │ HTTP REST / NVP / VPC
  ▼
directapi (v65.47)
  │ TNSI Remoting  [uses tnsi-payment-bus-api DTOs as contract]
  ▼
tnsi-payment-bus-api (v99.46) [pure API contract JAR]
  │ implemented by
  ▼
orchestrator (v5.107)
  ├── Risk Service    ──── TNSI Remoting
  ├── Token Service   ──── TNSI Remoting
  ├── Billing Client  ──── TNSI Remoting
  ├── PostgreSQL      ──── Hibernate/JDBC
  ├── Kafka           ──── Axon SDK (Avro events)
  │
  ├── TNSI Remoting ──▶ cardpaymentengine (v10.73)
  │                        ├── 60+ card brands
  │                        ├── Routing/rules engine
  │                        ├── 3DS / Risk / AVS
  │                        ├── Cassandra (high-volume)
  │                        └── TNSI Remoting ──▶ acqelavons2aservice (v1.10.131)
  │                                                  ISO 8583 over TCP+SSL
  │                                                  → Elavon S2A network
  │
  └── TNSI Remoting ──▶ externalacquirerservice (v1.67)
                           ├── Circuit breaker per acquirer
                           ├── HTTP/mTLS channel manager
                           ├── Settlement file/polling
                           └── → REST acquirers (First Data, Stripe, etc.)
```

---

## Technology Summary

| Technology | Repos | Purpose |
|---|---|---|
| Spring MVC 5.3.39 | All (1–6) | Web framework (traditional, not Spring Boot) |
| Jetty 9.x | #1, #3, #4, #5 | Embedded servlet container |
| TNSI Remoting | All (1–6) | Internal RPC transport between services |
| ISO 8583 | #6 | Binary banking protocol to Elavon S2A |
| Netty 4.x | #6 | Async TCP/SSL networking for ISO 8583 |
| Jackson 2.x | All | JSON serialization |
| Hibernate 5.x | #3, #4 | ORM / relational persistence |
| Cassandra 3.x | #4 | High-volume NoSQL transaction storage |
| PostgreSQL 9.2 | #3 | Orchestrator transaction records |
| Kafka 2.5 + Axon SDK 4 | #3 | Transaction event streaming |
| Avro 1.12 | #3 | Event schema serialization |
| Liquibase 2.0.2 | #3 | Database schema migrations |
| EHCache 2.x | #1, #3 | Merchant/business data caching |
| ActiveMQ 5.x | #5 | JMS / async messaging |
| Cucumber BDD 7.2 | #6 | Integration test framework |
| TNSI Crypto/HSM | #1, #3, #4, #6 | Encryption and key management |
| JMX | #4, #5 | Operations and performance monitoring |
| Log4j2 | #4 | Structured logging |
| Circuit Breaker (tnsi) | #5, #6 | Fault tolerance / resilience |
| Kryo 5.4 | #1 | Fast Java object serialization |
| MapStruct 1.5 | #3 | Object-to-object mapping |
| Lombok 1.18 | #3, #5 | Boilerplate reduction |
