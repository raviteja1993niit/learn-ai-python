# CLAUDE.md — pgs-acquirer-elavon-interface-service

## Project Overview

**pgs-acquirer-elavon-interface-service** is a PCF-based (Cloud Foundry) Acquirer Interface Service for the **Elavon S2A Acquirer**, developed and maintained by Mastercard as part of the PGS (Payment Gateway Services) Connectivity platform.

This is a **lift-and-shift modernization** project (`107651-pgsaaselavon`) targeting migration from legacy PCF deployment toward modern infrastructure.

---

## Repository Structure

```
pgs-acquirer-elavon-interface/          ← Root (parent Maven project)
├── pgs-acquirer-elavon-interface-service/   ← Main Spring Boot application
├── lib-elavon-interface-message/            ← ISO 8583 message model library
├── lib-elavon-interface-mapping/            ← Request/response mapping library
├── lib-elavon-interface-simulation/         ← Simulation/stub library
├── lib-elavon-interface-test-data/          ← Shared test data library
├── lib-elavon-interface-integration-tests/  ← Integration test module
├── environment/                             ← Per-environment CF manifests & values
└── .claude/                                 ← Claude AI project context (not committed)
```

---

## Technology Stack

| Layer              | Technology                                      |
|--------------------|-------------------------------------------------|
| Language           | Java 17                                         |
| Framework          | Spring Boot 3.3.10                              |
| Build Tool         | Apache Maven (multi-module)                     |
| Deployment         | Cloud Foundry (PCF) via `manifest.yml`          |
| Database           | Oracle DB (via Oracle UCP connection pool)      |
| Resilience         | Resilience4j (Circuit Breaker, Retry, Bulkhead) |
| Messaging Protocol | ISO 8583 (TCP/IP via Elavon S2A)                |
| Security           | Mutual TLS, nimbus-jose-jwt                     |
| Observability      | Spring Actuator, Micrometer                     |
| Testing            | JUnit 5, Spring Boot Test, MCTF                 |
| Code Quality       | Checkstyle, JaCoCo                              |
| CI/CD              | Jenkins (Mastercard Common Pipeline)            |

---

## Key Maven Modules

| Artifact ID                              | Purpose                                         |
|------------------------------------------|-------------------------------------------------|
| `pgs-acquirer-elavon-interface-service`  | Main deployable Spring Boot service             |
| `lib-elavon-interface-message`           | ISO 8583 / Elavon message models                |
| `lib-elavon-interface-mapping`           | Mapping between internal and Elavon formats     |
| `lib-elavon-interface-simulation`        | Elavon acquirer simulation for testing          |
| `lib-elavon-interface-test-data`         | Shared test data and scenarios                  |
| `lib-elavon-interface-integration-tests` | End-to-end integration test suite               |

---

## Main Application Entry Point

```
pgs-acquirer-elavon-interface-service/src/main/java/
  com/mastercard/pgs/connectivity/acquirer/
    acqelavons2aservice/AcqElavonS2AServiceApplication.java
```

Component scan covers:
- `com.mastercard.mpgs.acquiring`
- `com.mastercard.pgs.connectivity.acquirer`

---

## Configuration

- **Primary config:** `src/main/resources/application.yml`
- **Environment-specific:** `application-{env}.yml` (dev1, dev2, itf1, itf2, stage1, stage2) with `-green` variants for blue/green deployments
- **CF manifests:** `environment/{dev2,development,itf,itf2,stage,stage2}/manifest.yml`

### Key Configuration Properties

| Property Prefix       | Description                               |
|-----------------------|-------------------------------------------|
| `elavon.connectivity` | Elavon TCP host/port, TLS settings        |
| `acqElavonS2AService` | Acquirer-specific configuration           |
| `acqService.common`   | Common ACQ service feature flags          |
| `spring.datasource`   | Oracle DB connection via UCP pool         |

---

## Build & Run Commands

```bash
# Build all modules (skip tests)
mvn clean install -DskipTests

# Build with tests
mvn clean install

# Run the service locally
cd pgs-acquirer-elavon-interface-service
mvn spring-boot:run -Dspring.profiles.active=local

# Run tests for a specific module
mvn test -pl lib-elavon-interface-mapping

# Run integration tests
mvn verify -pl lib-elavon-interface-integration-tests
```

---

## Environments

| Environment   | Purpose                        |
|---------------|--------------------------------|
| `development` | Primary development environment|
| `dev2`        | Secondary dev environment      |
| `itf`         | Integration test environment   |
| `itf2`        | Secondary ITF environment      |
| `stage`       | Staging / pre-production       |
| `stage2`      | Secondary staging              |

---

## CI/CD Pipeline

- **Jenkinsfile:** Uses the Mastercard `common-pipeline-library` shared library via `commonPipeline(this)`
- **Pipeline config:** `pipeline.yml`
- **Artifact repository:** Mastercard Artifactory (releases + snapshots)
  - Releases: `https://artifacts.mastercard.int/artifactory/releases/`
  - Snapshots: `https://artifacts.mastercard.int/artifactory/snapshots/`

---

## Important Notes for AI Assistance

- **Naming conventions:** Follow existing package structure under `com.mastercard.pgs.connectivity.acquirer.elavon.*`
- **Lombok:** Used extensively — prefer `@Data`, `@Builder`, `@Slf4j` annotations
- **ISO 8583:** Message encoding/decoding uses `libmpgs-iso8583` (Mastercard internal library)
- **TCP connectivity:** Elavon communication is over TCP/IP, not HTTP — see `elavon/tcp/` package
- **Database:** Oracle UCP pool is used; avoid introducing H2 or other in-memory DBs without profile guards
- **Resilience:** All outbound calls to Elavon should be wrapped in Resilience4j circuit breakers/retries
- **Security:** Do not log raw card data (PAN, CVV); ensure PCI-DSS compliance in any new code
- **Checkstyle:** All code must pass Checkstyle rules defined in parent POM before committing
- **Test coverage:** JaCoCo is configured — maintain or improve coverage with every change

---

## .gitignore Reminder

The `.claude/` directory is excluded from Git tracking via `.gitignore`. Do **not** commit this directory or its contents.
