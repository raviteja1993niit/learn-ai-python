
---
applyTo: "**/*.java,**/*.kt,**/*.groovy"
title: Java + Spring Development — Copilot Custom Instructions (Enhanced)
description: A universal, 360° instruction set for Spring Framework, Spring Boot, and Spring Cloud projects. Use in `.github/copilot-instructions.md` (or path-specific `.instructions.md`) so GitHub Copilot Chat consistently follows your architecture, testing, security, and observability standards.
version: 2.0
lastUpdated: 2025-12-04
---

> **Why this file?** VS Code and GitHub Copilot support **repository** and **path-specific** instruction files. Storing this guidance here applies it automatically to Copilot Chat prompts across the workspace. Use `applyTo` globs to scope per-folder rules. citeturn5search118turn5search119

## 0) Copilot Usage Playbook
- **Prompting**: Start broad → list constraints → provide examples → break complex tasks (refactor + tests + docs) into steps; avoid ambiguity by naming exact classes/methods. citeturn5search112
- **Attach context**: In VS Code, use **Add Context…** (Open Editors, files) so Copilot sees the code under test; reuse saved prompts. citeturn5search99
- **Built-in commands**: Use `/explain`, `/fix`, `/tests` to accelerate common flows. citeturn5search130
- **Validate outputs**: You own correctness/security; review suggestions before committing. citeturn5search94
- **Public-code matches**: If enabled, review Copilot **code references** and licenses; attribute or replace as needed. citeturn5search100turn5search102

---

## 1) Spring Boot — Production‑Ready Baseline
**Auto‑configuration & Starters**
- Prefer official starters; avoid unnecessary custom auto-config unless required; keep BOMs aligned with release trains. citeturn7search62

**Profiles & Configuration**
- Use `application.yml` per environment; activate profiles (`spring.profiles.active`) and externalize secrets via config server or vault. citeturn7search60

**Actuator & Endpoint Security**
- Enable only needed endpoints; expose via `/actuator/**`; protect with Spring Security and role/authority checks; limit health detail. citeturn7search62
- Gate sensitive endpoints and prefer HTTP Basic/OAuth2 for management; restrict `shutdown`; avoid exposing `/env` broadly. citeturn7search67turn7search65

**Testing**
- Use `@SpringBootTest` for full-context tests; slice tests with `@WebMvcTest` or `@DataJpaTest`; prefer MockMvc/MockMvcTester for MVC tests; choose TestRestTemplate/WebTestClient for real HTTP. citeturn7search99turn7search98turn7search103

**Data Access (Spring Data JPA)**
- Use repositories, paging & sorting (`Pageable`, `Sort`), and `@Query` for specifics; design Page endpoints with predictable defaults. citeturn7search88turn7search86

**Security (Resource Servers)**
- For JWT‑secured APIs: configure `spring.security.oauth2.resourceserver.jwt.issuer-uri`; map scopes/authorities; validate tokens via JWK set. citeturn7search80turn7search85

**Observability (Boot 3)**
- Use **Micrometer Tracing** (Brave or OpenTelemetry bridges) instead of Spring Cloud Sleuth (EOL with Boot 3); configure exporters (Zipkin/Tempo). citeturn7search92turn7search93

---

## 2) Spring Cloud — Distributed Patterns
**Service Discovery**
- Use Netflix **Eureka** for registration/discovery; ensure heartbeat and HA server configuration; auto‑register via `spring-cloud-starter-netflix-eureka-client`. citeturn7search50turn7search53

**Config Server**
- Centralize properties in a Git‑backed **Spring Cloud Config Server**; clients fetch `/application/profile[/label]`; secure repository access. citeturn7search56

**API Gateway**
- Use **Spring Cloud Gateway** (WebFlux) for routing, predicates, and filters; avoid WAR/Servlet containers for Gateway; leverage rate limiting and CB filters. citeturn7search74

**Circuit Breakers & Resilience**
- Standardize on **Resilience4j** via Spring Cloud CircuitBreaker; configure `TimeLimiter`, CB thresholds, retries, bulkheads; add event handlers. citeturn7search69
- Prefer programmatic or YAML shared configs; pick reactive vs non-reactive starters per stack. citeturn7search69

**Messaging / Streaming**
- Use **Spring Cloud Stream** (Kafka/RabbitMQ) for eventing; define bindings and error channels; document schema evolution. citeturn7search76

**Contracts & Stubs**
- Adopt **Spring Cloud Contract** for CDC; generate producer tests and consumer stubs; use Stub Runner/WireMock for integration. citeturn7search104

**Load Balancing**
- Prefer **Spring Cloud LoadBalancer** for client‑side LB with discovery; configure retry policies per service. citeturn7search76

**Distributed Tracing & Metrics**
- Use **Micrometer Tracing** bridges (Brave/Otel); migrate off Sleuth; ensure W3C propagation and 128‑bit trace IDs in Boot 3. citeturn7search93turn7search96

---

## 3) Spring Framework — Core Practices
- Prefer **constructor injection**; annotate with `@Component/@Service/@Repository`; scope carefully; use `@Transactional` at service boundaries. citeturn7search2
- Use **AOP** for cross‑cutting concerns (`@Aspect`, `@Around`/`@Before`); avoid leaking business logic into aspects. citeturn7search2
- JDBC: use `JdbcTemplate` for simple work; JPA/Hibernate for ORM; manage transactions declaratively. citeturn7search2
- Web MVC: `@Controller`, `@RestController`, `@RequestMapping`; validate inputs with `@Valid`. citeturn7search2

---

## 4) Security Checklist (API & Actuator)
- Lock down `/actuator/**` with Spring Security; expose minimal endpoints; hide sensitive info (`env`, `configprops`). citeturn7search62turn7search65
- Configure **OAuth2 Resource Server** for APIs; validate JWTs via `issuer-uri`; map scopes to authorities and enforce on routes. citeturn7search80
- Prefer **BCrypt** hashing and role/authority checks; review CORS and CSRF depending on client type. citeturn7search2

---

## 5) Observability, Tracing, and Metrics (Boot 3+)
- **Micrometer Tracing** replaces **Sleuth**; use `micrometer-tracing-bridge-brave` or `micrometer-tracing-bridge-otel`; configure reporters (Zipkin/Wavefront). citeturn7search93
- Follow Sleuth → Micrometer **migration guide** to align ID formats and propagation. citeturn7search96
- Expose metrics via Actuator (`/actuator/metrics`); scrape with Prometheus; visualize in Grafana. citeturn7search62

---

## 6) Testing Strategy — Examples Copilot Should Generate
- **Slice tests**: `@WebMvcTest` + MockMvc/MockMvcTester for controllers; `@DataJpaTest` for repositories. citeturn7search98
- **Full‑context**: `@SpringBootTest` with `RANDOM_PORT` + TestRestTemplate/WebTestClient for end‑to‑end. citeturn7search99turn7search103
- **Contract tests**: Producer side with Spring Cloud Contract; consumer stubs via Stub Runner. citeturn7search104

---

## 7) Prompt Library — Copy into Copilot Chat
> Attach the relevant files via **Add Context…** before running these prompts. citeturn5search99

**Refactor + Tests**
- "Refactor `<ClassName>` (Spring Boot 3) for readability and performance; preserve behavior. Provide a **diff**, unit tests (`@WebMvcTest`, `@DataJpaTest` as needed), and a short rationale."

**Gateway Routes**
- "Define Spring Cloud Gateway routes for `<service>` with path predicate, rewrite filter, rate limiting, and circuit breaker fallback; include YAML and test stubs." citeturn7search74

**Eureka Registration**
- "Add Eureka client config for `<service>`; document heartbeat, zones, and serviceUrl; include test verifying discovery via mock registry." citeturn7search53

**Config Server Setup**
- "Create a Git‑backed Spring Cloud Config Server and client configuration for `<app>`; include sample `/application/profile` endpoints and bootstrap properties." citeturn7search56

**Resilience4j Policies**
- "Configure CircuitBreaker + TimeLimiter + Retry for `<downstream>`; add event logging and tests demonstrating open/half‑open transitions." citeturn7search69

**JWT‑secured API**
- "Configure OAuth2 Resource Server with `issuer-uri`, scope mapping, and role‑based access; add tests for happy/expired/invalid tokens." citeturn7search80

**Micrometer Tracing**
- "Migrate Sleuth to Micrometer Tracing; set W3C propagation, 128‑bit trace IDs; wire Zipkin. Provide before/after config and verification steps." citeturn7search92turn7search93

**Contract Testing**
- "Generate Spring Cloud Contract for `<endpoint>`; produce producer tests, consumer stubs, and WireMock‑based integration tests." citeturn7search104

---

## 8) Architecture & Code Review Checklist (Copilot should follow)
- **Configuration** externalized; profiles consistent; secrets not in code; Config Server usage documented. citeturn7search56
- **Discovery/Gateway** configured with health checks, predicates, filters, and fallbacks; no blocking calls in reactive flows. citeturn7search74
- **Resilience**: sensible CB thresholds/timeouts; retries with backoff; bulkheads to isolate; events monitored. citeturn7search69
- **Security**: resource server validates JWT, scopes enforced, Actuator protected, minimal exposed endpoints. citeturn7search80turn7search62
- **Observability**: Micrometer Tracing configured; metrics scraped; logs correlate with trace/span IDs. citeturn7search93
- **Testing**: slice + full‑context tests; contract tests; avoid over‑mocking; use MockMvc/MockMvcTester appropriately. citeturn7search98turn7search99

---

## 9) Notes on File Organization
- Repo‑wide rules: `.github/copilot-instructions.md`.
- Path‑specific rules: `.github/instructions/<topic>.instructions.md` with `applyTo` globs (e.g., `gateway/**`).
- Shared prompt library: `.github/prompts/*.md`. citeturn5search118

**Changelog**
- 2.0 — Enhanced guidance across Spring Boot/Cloud/Framework; added security, observability, resilience, testing strategies, and prompt library.
