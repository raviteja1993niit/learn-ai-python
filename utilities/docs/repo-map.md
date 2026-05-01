# MODERNIZATION — Repository Map

> Quick reference for all modules in this workspace.  
> Tech stack: **Java 17 · Maven · Spring Boot 3.3**

---

## 🗂️ Module Index

### 🔧 Shared Libraries

| Module | Type | Purpose |
|--------|------|---------|
| `107092-pgsaascapint-cpc-tspi-mapper-sharedlib` | Shared Lib | Maps CPC ↔ TSPI transaction formats (request/response transformation) |
| `107092-pgsaascapint-cpc-tspi-transaction-adapter-sharedlib` | Shared Lib | Adapts CPC requests to TSPI S2A online service format; includes header enrichment |
| `lib-acquirer-card-payment-api-spec` | API Spec Lib | Common card payment configuration API specifications |
| `lib-acquirer-connectivity-domain-api-spec` | API Spec Lib | Domain API specifications for acquirer connectivity services |
| `lib-acquirer-connectivity-tcp` | Shared Lib | TCP connectivity protocol handling for acquirer communication |
| `lib-acquirer-test` | Test Framework | Shared test framework built on the Flow model for connectivity service testing |
| `107652-pgsaaschtech-lib-acquirer-simulation-sharedlib` | Shared Lib | Simulation stubs and common behaviour classes for acquirer services |
| `card-payment-connectivity` | Domain Lib | Core card payment connectivity domain model and utilities |

---

### 🚀 Acquirer Interface Microservices

| Module | Acquirer | Notes |
|--------|---------|-------|
| `107092-pgsaascapint-pgs-acquirer-cap-interface-service` | CAP (generic) | CAP interface service for payment gateway acquiring |
| `107296-pgsaasbrclys-pgs-acquirer-barclays-interface-service` | Barclays | Barclays acquirer integration service |
| `107297-pgsaaswrldpa-pgs-acquirer-worldpay-interface-service` | Worldpay | Worldpay acquirer integration service |
| `107651-pgsaaselavon-pgs-acquirer-elavon-interface-service` | Elavon | Elavon acquirer integration (lift & shift modernization) |
| `107652-pgsaaschtech-pgs-acq-chase-paymentech-interface-service` | Chase Paymentech | Chase Paymentech service with simulation and response generation |
| `107652-pgsaachtech-pgs-acq-chase-paymentech-interface-service` | Chase Paymentech | Variant of Chase Paymentech service (see above) |

---

### 🧪 Test Suites

| Module | Covers |
|--------|--------|
| `107092-pgsaascapint-pgs-acquirer-cap-interface-service-test` | CAP interface service — integration & smoke tests |
| `107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test` | Elavon interface service — integration & smoke tests |

---

### 🗄️ Legacy / Pre-Modernization Services

| Module | Tech | Notes |
|--------|------|-------|
| `acqchasepaymentech` | Java/Maven, WAR | Legacy Chase Paymentech (Salem 2.0) acquiring service |
| `acqelavons2aservice` | Java/Maven, Docker | Elavon S2A EDI acquiring service; containerised with Docker |

---

### 🛠️ Utilities & Platform

| Module | Purpose |
|--------|---------|
| `connectivity-release-report-generator` | Generates automated release reports integrating Git, Sonar, Checkmarx, BlackDuck, Blazemeter, and Jenkins |
| `pgs-settlement-worldpay-transformer` | Spring Boot 3.3 service that transforms settlement data for Worldpay |
| `s2i-banknet` | Multi-module Banknet S2I platform (Java 17); includes sub-modules for integration tests, simulation, translation, and core service |
| `com-mastercard-pgs-connectivity-acquirer_pgs-acquirer-worldpay-interface-service` | Policy/configuration artifacts for Mastercard–Worldpay connectivity |

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                   Acquirer Interface Layer                │
│   CAP │ Barclays │ Worldpay │ Elavon │ Chase Paymentech  │
└────────────────────────┬─────────────────────────────────┘
                         │ uses
┌────────────────────────▼─────────────────────────────────┐
│               Shared Libraries & Domain                   │
│  cpc-tspi-mapper │ cpc-tspi-adapter │ connectivity-tcp   │
│  card-payment-connectivity │ domain-api-spec             │
└────────────────────────┬─────────────────────────────────┘
                         │ tested by
┌────────────────────────▼─────────────────────────────────┐
│                  Test & Simulation                        │
│  lib-acquirer-test │ lib-acquirer-simulation-sharedlib   │
│  *-service-test modules                                   │
└──────────────────────────────────────────────────────────┘

   Legacy:  acqchasepaymentech │ acqelavons2aservice
   Platform: s2i-banknet │ pgs-settlement-worldpay-transformer
```

---

## 🔑 Naming Conventions

| Prefix | Meaning |
|--------|---------|
| `107092`, `107296`, … | Story/ticket ID — feature branch deliverable |
| `pgsaas` | PGS-as-a-Service platform |
| `capint` | CAP Interface |
| `brclys` | Barclays |
| `wrldpa` | Worldpay |
| `aaselavon` | Elavon |
| `chtech` / `aachtech` | Chase Paymentech |
| `lib-acquirer-*` | Cross-cutting acquirer shared library |
| `s2i` | Salem 2 Integration (legacy platform) |

---

*Generated: 2026-04-16*
