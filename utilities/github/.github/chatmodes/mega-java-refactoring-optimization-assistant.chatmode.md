
---
applyTo: "java"
title: Java Refactoring & Optimization Assistant — Copilot Chat Instructions (Consolidated)
description: Universal, engineer-authored guide to make GitHub Copilot Chat behave like a senior Java refactoring and performance assistant. Drop into `.github/copilot-instructions.md` (or path‑specific `.instructions.md`) to apply automatically across conversations.
version: 1.0
lastUpdated: 2025-12-04
---

> **Why this file?** Copilot supports **repository** and **path-specific** instruction files, so your optimization and refactoring standards are applied to every prompt automatically—no retyping. Use `.github/copilot-instructions.md` for repo‑wide rules, or `.github/instructions/*.instructions.md` with `applyTo` globs to scope by folders. citeturn3search99turn3search98

## 0) How to work with Copilot (Prompting & Context)
- **Prompt strategy**: Start general → list specifics → provide examples → split complex tasks. Avoid ambiguity and reference the exact files, classes, or functions. citeturn3search50
- **Choose the right tool**: Use Chat for explanations, large edits, and reasoning; use inline suggestions for small repetitive edits. Always review and validate. citeturn3search56
- **Attach context**: Add files/PRs/issues via mentions; use *Add Context…* (e.g., **Open Editors**, @workspace) for broader scope. citeturn3search76turn3search98
- **Slash commands**: `/explain`, `/fix`, `/tests` accelerate common tasks; use them on selections or with attached context. citeturn3search76
- **Public-code matches**: If enabled, Copilot may show **code references** (source repos + licenses). Review, attribute, or block matching suggestions per policy. citeturn3search62turn3search63

---

## 1) Refactoring Principles (Behavior-Preserving)
- **Goals**: Improve **readability**, **maintainability**, **testability** without changing external behavior.
- **Constraints**: Keep public APIs stable unless explicitly allowed; prefer small, safe increments; explain uncertainties.
- **Guidelines**: Split long methods; extract cohesive helpers; improve naming; remove duplication; isolate side effects; avoid God classes; ensure null-safety and explicit error handling.
- **Workflow**: 1) Select scope → 2) `/explain` to confirm intent → 3) Request diff + tests → 4) run tests & static analysis → 5) iterate with `/fix`. citeturn3search47turn3search56

### Example (OrderService)
```java
public class OrderService {
    private final Database db;
    public double calculateTotal(List<Integer> prices) {
        double total = 0.0;
        for (Integer p : prices) { total += p; }
        db.save("total", total); // side effect in hot path
        return total * 0.18; // hard-coded tax
    }
    public void printReceipt(Order order) {
        System.out.println("Receipt:" + order.getId());
    }
}
```

**Ask Copilot**
```
/explain
Refactor for clarity, testability, and performance; preserve behavior. Extract constants; add null checks; avoid side effects in hot paths; use Streams only if they improve clarity.
```

**Possible refactor (diff)**
```diff
@@
 public class OrderService {
     private final Database db;
+    private static final double TAX_RATE = 0.18; // externalize if configurable
 
-    public double calculateTotal(List<Integer> prices) {
-        double total = 0.0;
-        for (Integer p : prices) { total += p; }
-        db.save("total", total);
-        return total * 0.18;
-    }
+    public double calculateTotal(List<Integer> prices) {
+        Objects.requireNonNull(prices, "prices");
+        double total = prices.stream().mapToDouble(Integer::doubleValue).sum();
+        db.save("total", total);
+        return total * TAX_RATE;
+    }
@@
-    public void printReceipt(Order order) {
-        System.out.println("Receipt:" + order.getId());
-    }
+    public void printReceipt(Order order) {
+        Objects.requireNonNull(order, "order");
+        System.out.println(formatReceipt(order));
+    }
+
+    private String formatReceipt(Order order) {
+        return "Receipt:" + order.getId();
+    }
 }
```
(Use `/tests` to generate edge-case tests; iterate with `/fix` on failures.) citeturn3search47

---

## 2) Performance Optimization (Backend)
### General Principles
- **Measure First**: Profile and benchmark before optimizing (guessing is the enemy). Prefer JFR/JMC or IDE profilers for low-overhead tracing. citeturn3search56turn3search88
- **Optimize for the Common Case**: Focus on hot paths and remove unnecessary work and allocations. Use cookbook prompts to identify hotspots. citeturn3search44
- **Prefer Simplicity**: simpler algorithms/data structures are easier to optimize and maintain; split large tasks. citeturn3search50
- **Document assumptions**: cache TTLs, batching sizes, retry/backoff choices; keep instruction files concise and specific. citeturn3search66
- **Automate perf testing**: JMH microbenchmarks and CI performance alerts guard against regressions. citeturn3search68turn3search72

### Algorithms & Data Structures
- Pick the right structure: arrays for sequential scans; `HashMap` for O(1) lookups; trees for ordered/hierarchical data; measure before switching to Streams. citeturn3search56
- Avoid **O(n²)** or worse; refactor naïve loops; batch operations; reduce temporary allocations. citeturn3search44

### Concurrency & Parallelism
- Prefer **async I/O**; manage concurrency with `ExecutorService`/`CompletableFuture`; profile for contention. Use bounded pools and backpressure. citeturn3search56
- Guard against races with locks only when needed; favor immutable DTOs; document threading assumptions. citeturn3search56

### Caching
- Cache expensive computations (in-memory) and data (Redis/Memcached) with clear TTLs and invalidation strategy; mitigate stampedes via request coalescing. citeturn3search56

### API & Network
- Minimize payloads; compress (gzip/br); paginate; reuse connection pools; select protocols (HTTP/2, gRPC, WebSockets) by latency/streaming needs. citeturn3search56

### Logging & Monitoring
- Use **structured logs** with key-value fields; avoid verbose logging on hot paths; propagate trace IDs; set alerts on latency/throughput/errors. Use JFR/JMC/APM where possible. citeturn3search88turn3search56

---

## 3) Java/JVM Focus
- **Collections & Streams**: prefer `ArrayList`/`HashMap`; avoid boxing/unboxing overhead in Streams unless clarity outweighs cost. citeturn3search56
- **Profiling**: use **JFR/JMC** for production‑grade low-overhead profiling; **VisualVM** for local investigations; capture flame graphs and allocation hotspots. citeturn3search88turn3search86
- **GC choice & tuning**: start with defaults; set heap sizes (`-Xms`, `-Xmx`); enable unified GC logging (`-Xlog:gc*`). For low latency, consider **ZGC** (enable **generational ZGC** on JDK 21+); G1 remains the general‑purpose default—measure before switching. citeturn3search95turn3search80turn3search82
- **Async & structured concurrency**: use `CompletableFuture`; document assumptions; test for deadlocks/timeouts. citeturn3search56

---

## 4) Database Performance
- **Queries**: index frequent filters/joins; avoid `SELECT *`; fetch only needed columns; use parameterized queries; inspect plans with `EXPLAIN`. citeturn3search56
- **Schema**: normalize for writes; **denormalize** for read-heavy workloads when justified; understand FK trade-offs under high write rates. citeturn3search56
- **Transactions**: keep transactions short; minimal isolation level that meets consistency; avoid long-running transactions. citeturn3search56
- **Caching & Replication**: add read replicas; cache hot queries (Redis) with careful invalidation; consider sharding for scale; monitor replication lag. citeturn3search56

---

## 5) Observability & Continuous Performance
- **Flight Recorder (JFR)**: record low‑overhead events (GC, allocations, I/O, thread states) and analyze with **JMC**; use templates (default/profile) and automate captures for incident analysis. citeturn3search88
- **Microbenchmarks (JMH)**: write controlled, warmed benchmarks; compare before/after changes; integrate into CI; avoid misbenchmarking. citeturn3search68turn3search72

---

## 6) Prompt Library — Refactoring & Optimization (Copy into Copilot Chat)
> Attach relevant files or select **Add Context… → Open Editors** for precise scope. citeturn3search98

- **Refactor for clarity**: 
  "You are a senior Java engineer. Refactor the selected class to improve readability and testability while preserving behavior. Provide a **diff**, a short rationale per change, and **unit tests** for edge cases."
- **Optimize hot path**:
  "Analyze and optimize the highlighted loop for time/allocations. Keep behavior identical. Show diff + a **JMH microbenchmark** comparing before/after." citeturn3search68
- **DB batching**:
  "Find database calls inside tight loops. Propose batching/pagination and a caching plan (TTL, invalidation). Explain trade‑offs and how to measure improvements." citeturn3search47
- **GC pauses**:
  "Review attached GC logs and recommend minimal JVM tuning for low latency (G1 vs generational ZGC). Provide flags, pros/cons, and monitoring plan with JFR." citeturn3search80turn3search82
- **Async I/O**:
  "Refactor blocking I/O to async (`CompletableFuture`) without changing APIs. Add tests and JFR steps to validate reduced contention/latency." citeturn3search88

---

## 7) Code Review Checklist (Refactoring + Performance)
- [ ] Any **algorithmic inefficiencies** (O(n²) or worse)? citeturn3search44
- [ ] Data structures appropriate and minimal allocations? citeturn3search56
- [ ] Duplicated logic removed; naming clarified; side effects isolated?
- [ ] Null-safety and explicit exception handling present?
- [ ] DB queries optimized and indexed; no `SELECT *`? citeturn3search56
- [ ] Large payloads paginated/streamed/chunked? citeturn3search56
- [ ] Network requests pooled, retried, and timeouts configured? citeturn3search56
- [ ] Logging structured; hot paths not verbose; trace IDs propagated? citeturn3search56
- [ ] Perf‑critical code documented; microbenchmarks/profiling traces added? citeturn3search68turn3search88
- [ ] Alerts or SLO monitors exist for regressions (latency/throughput/errors)? citeturn3search88

---

## 8) Governance, Security, and Compliance
- **Review responsibility**: Copilot accelerates work but doesn’t replace human review. Validate correctness, security, and performance before merging. citeturn3search56
- **Code referencing & licensing**: If public-code matching is allowed, examine Copilot’s references and licenses; decide to attribute, depend, or replace. citeturn3search62turn3search63
- **Trust & policy**: Refer to the GitHub **Copilot Trust Center** for security, privacy, and compliance posture and configure organization policies accordingly. citeturn1search15

---

**Changelog**
- 1.0 — First consolidated edition: refactoring workflow, optimization strategies, JVM/GC/db guidance, observability, prompt library, and governance.
