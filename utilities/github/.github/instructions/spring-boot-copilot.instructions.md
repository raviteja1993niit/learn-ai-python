
---
applyTo: "**/*.java,**/*.kt"
title: Spring Boot — Copilot Custom Instructions (Enhanced)
description: A universal, 360° instruction set for Spring Boot 3 projects—configuration, security, observability, testing, and performance. Use in `.github/copilot-instructions.md` or path‑specific `.instructions.md`.
version: 2.0
lastUpdated: 2025-12-04
---

> **Usage with Copilot**: Start broad → add constraints/examples → attach **Open Editors**/**files** for context; use `/explain`, `/fix`, `/tests`; **validate outputs** before committing. citeturn5search112turn5search99turn5search94

## 1) Configuration & Profiles
- Prefer `application.yml` with per‑profile overrides; activate via `spring.profiles.active`; externalize secrets to config server / vault. citeturn7search60
- Bind settings to `@ConfigurationProperties` and document defaults. (Boot reference covers configuration properties and Actuator.) citeturn7search62

## 2) Actuator & Production Readiness
- Enable only needed endpoints; HTTP exposure at `/actuator/**`; secure endpoints with Spring Security and minimize health details; avoid exposing `/env` / `/configprops` broadly. citeturn7search62turn7search65
- For custom health or metrics, add **HealthIndicator**/**Meter** and restrict access. citeturn7search66

## 3) Web MVC / WebFlux & API Design
- Prefer **REST controllers** with validation (`@Valid` / constraint annotations), global exception handling (ControllerAdvice), and standardized error payloads. (Boot/Web MVC docs.) citeturn7search62
- For reactive stacks, ensure non‑blocking I/O and avoid blocking calls. (Gateway/WebFlux cautions.) citeturn7search74

## 4) Data Access (Spring Data JPA) & Migrations
- Use repositories with **paging & sorting** (`Pageable`, `Sort`) for large results; add indices and deterministic sort defaults. citeturn7search88turn7search86
- Use Flyway/Liquibase for schema changes; seed data via testcontainers or `data.sql`. (Boot reference.) citeturn7search62

## 5) Security (Resource Server)
- When securing APIs with JWT: add `spring-boot-starter-oauth2-resource-server`; set `spring.security.oauth2.resourceserver.jwt.issuer-uri` so Boot auto‑discovers JWKs; map scopes to authorities and enforce at route level. citeturn7search80turn7search85

## 6) Observability (Boot 3)
- Use **Micrometer Tracing** (Brave or OpenTelemetry bridges) in place of **Spring Cloud Sleuth** (EOL for Boot 3); configure exporters (Zipkin/Wavefront/Tempo). citeturn7search92turn7search93
- Expose metrics via Actuator (`/actuator/metrics`), scrape with Prometheus, and visualize in Grafana. citeturn7search62

## 7) Testing Strategy
- **Slice tests**: `@WebMvcTest` + MockMvc/MockMvcTester for controllers; `@DataJpaTest` for repositories. citeturn7search98
- **Full‑context**: `@SpringBootTest` (`MOCK`, `RANDOM_PORT`) + TestRestTemplate/WebTestClient for end‑to‑end. citeturn7search99turn7search103
- Prefer deterministic seeds, test containers for infra, and contract tests (see Spring Cloud section). citeturn7search99

## 8) Performance & Resilience (in‑app)
- Use connection pools, timeouts, and back‑pressure; profile with Actuator metrics and tracing. (Boot/Micrometer docs.) citeturn7search62turn7search93

---

## Prompt Library — Copy into Copilot Chat
> Attach the relevant controllers/entities **via Add Context…** before running. citeturn5search99
- **Refactor + tests**: "Refactor `<ClassName>` for readability & performance; preserve behavior; return a **diff** plus `@WebMvcTest` / `@DataJpaTest` tests."
- **JWT protection**: "Configure resource server (`issuer-uri`) and add tests for valid/expired/invalid tokens; enforce `SCOPE_admin` for `/admin/**`." citeturn7search80
- **Pagination**: "Add `Pageable` to `<Repository>` and controller; document defaults; unit & integration tests for sorting and page sizes." citeturn7search88
- **Actuator hardening**: "Restrict `/actuator/**`, hide sensitive endpoints, add custom health indicator with role checks; include security tests." citeturn7search62

---

## Checklist (Copilot should follow)
- Config externalized; secrets not in code; profiles documented. citeturn7search60
- Actuator locked down; minimal exposure; custom endpoints constrained. citeturn7search62
- JWT Resource Server configured and tested. citeturn7search80
- Observability: micrometer tracing configured; metrics scraped. citeturn7search93
- Tests: slice + full‑context; deterministic data; coverage of edge cases. citeturn7search98turn7search99
