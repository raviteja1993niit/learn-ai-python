
---
applyTo: "**/*.java,**/*.kt"
title: Spring Cloud — Copilot Custom Instructions (Enhanced)
description: A universal, 360° instruction set for Spring Cloud microservices—discovery, config server, gateway, circuit breakers, load balancing, messaging, tracing, contracts, and security.
version: 2.0
lastUpdated: 2025-12-04
---

> **Usage with Copilot**: Start broad → add constraints/examples → attach **Open Editors**/**files** for context; use `/explain`, `/fix`, `/tests`; **validate outputs** before committing. citeturn5search112turn5search99turn5search94

## 1) Service Discovery
- Use **Netflix Eureka** or other registries; auto‑register clients via `spring-cloud-starter-netflix-eureka-client`; configure heartbeat and HA server. citeturn7search50turn7search53

## 2) Config Server (Externalized Configuration)
- Centralize properties in a **Git‑backed Spring Cloud Config Server**; clients read `/application/{profile}[/{label}]`; secure repository and endpoints. citeturn7search56

## 3) API Gateway
- Use **Spring Cloud Gateway** (WebFlux) for routing/predicates/filters; avoid WAR/Servlet containers; add rate limiting and circuit‑breaker fallbacks where needed. citeturn7search74

## 4) Circuit Breakers & Resilience
- Standardize on **Resilience4j** via Spring Cloud CircuitBreaker; configure defaults (timeouts, thresholds) and instance overrides; add event handlers and metrics. citeturn7search69

## 5) Client‑Side Load Balancing
- Use **Spring Cloud LoadBalancer** for discovery‑aware calls; configure retries & backoff per service. citeturn7search76

## 6) Messaging & Streaming
- Use **Spring Cloud Stream** with Kafka/RabbitMQ; define bindings, error channels, and schema evolution; test with stub topics and containerized brokers. citeturn7search76

## 7) Declarative HTTP Clients
- Use **OpenFeign** for service calls; integrate with discovery and Resilience4j; document timeouts and error handling. citeturn7search76

## 8) Distributed Tracing & Metrics
- Prefer **Micrometer Tracing** (Brave/OpenTelemetry bridges) over Sleuth (EOL with Boot 3); ensure W3C propagation & 128‑bit trace IDs; export spans to Zipkin/Tempo. citeturn7search92turn7search93

## 9) Security Between Services
- Secure internal APIs with OAuth2 JWT; configure resource servers with `issuer-uri`; enforce scopes/roles per route; protect Gateway and Config endpoints. citeturn7search80

## 10) Contract Testing (CDC)
- Use **Spring Cloud Contract** to generate producer tests and consumer stubs; run integration tests with **Stub Runner** and **WireMock**. citeturn7search104

---

## Prompt Library — Copy into Copilot Chat
> Attach relevant service/gateway/config files **via Add Context…**. citeturn5search99
- **Eureka setup**: "Add Eureka client to `<service>`; configure `serviceUrl.defaultZone`, heartbeat, and instance metadata; provide tests using a mock registry." citeturn7search53
- **Config Server**: "Create Git‑backed Config Server and client bootstrap; include sample endpoints (`/{app}/{profile}`) and secure access." citeturn7search56
- **Gateway routes**: "Define predicates & filters (rewrite path, rate limit, CB fallback) for `<service>` with YAML + unit tests." citeturn7search74
- **Resilience4j policy**: "Configure CB + TimeLimiter + Retry for `<downstream>`; instrument events and add tests for open/half‑open transitions." citeturn7search69
- **Tracing & metrics**: "Migrate Sleuth→Micrometer Tracing; set W3C propagation & 128‑bit Trace IDs; wire Zipkin; demonstrate span correlation in logs." citeturn7search92
- **Contract tests**: "Generate contracts for `<endpoint>`; build producer tests and consumer stubs; integrate Stub Runner in CI." citeturn7search104

---

## Architecture & Ops Checklist
- **Discovery**: instances healthy; heartbeat intervals tuned; zones documented. citeturn7search53
- **Config**: properties externalized; encrypted secrets; profile hierarchy clear. citeturn7search56
- **Gateway**: routing & filters defined; rate limiting & fallbacks tested; reactive only (no WAR). citeturn7search74
- **Resilience**: circuit thresholds/timeout/retry/backoff sane; bulkheads isolate; events monitored. citeturn7search69
- **Security**: resource servers validate JWTs; scopes enforced per endpoint; management endpoints locked down. citeturn7search80
- **Observability**: Micrometer Tracing configured; spans exported; metrics scraped and visualized. citeturn7search93
- **Contracts**: CDC in place; stubs versioned; CI runs producer & consumer tests. citeturn7search104

---

## File Organization
- Repo‑wide rules: `.github/copilot-instructions.md`
- Path‑specific rules: `.github/instructions/<topic>.instructions.md` with `applyTo` globs (e.g., `gateway/**`)
- Shared prompt library: `.github/prompts/*.md` citeturn5search118
