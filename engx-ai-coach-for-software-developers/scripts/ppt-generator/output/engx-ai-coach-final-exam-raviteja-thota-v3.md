# How to Develop Your Own Multi-Agentic Solution

Raviteja Thota (613491)  |  Senior Software Engineer  |  EPAM  |  May 2026

---

# How to Develop Your Own Multi-Agentic Solution


**Raviteja Thota (613491)**  |  Senior Software Engineer  |  EPAM

EngX AI Coach — Final Exam Presentation  |  May 2026

- Use Case 1  ·  Multi-Agentic Solution
- Use Case 2  ·  RAG Evolution Journey

## Agenda


### Use Case 1 — Multi-Agentic Solution
- 01   What is a Multi-Agent System?
- 02   Architecture Flow Diagram
- 03   Agent Roles & Responsibilities
- 04   Code: Agent Definition
- 05   Real-World Results

### Use Case 2 — RAG Evolution Journey
- 06   Why RAG Needed to Evolve
- 07   RAG Evolution Flow  (V1 › V2 › V3)
- 08   Agentic RAG Architecture
- 09   Code Demo: ask.py
- 10   Comparison & When to Use Each

*Practical Task  ·  Key Takeaways  ·  Q&A*


---

## Use Case 1 — Multi-Agentic Solution

*Real-World Problem — Developers waste days manually tracking feature toggle impact*


**Real-World Problem:**
- >  100+ feature toggles across 16,000+ Java files in 7 repos
- >  Devs manually grep code, check stale Confluence, write impact notes — days per toggle
- >  No automated way to answer: "What breaks if I flip this toggle OFF in production?"
- >  Multi-agent system solves this end-to-end in minutes

### Real-World Problem: Feature Toggle Chaos

*Managing 100+ toggles across 16K+ Java files — manually — every sprint*

#### The Developer's Daily Struggle  →  What the System Must Do

| Left | Right |
|------|-------|
| **A developer is asked: "Is toggle MPGS_3DS_V2 safe to remove?"** | **User types: "analyse toggle MPGS_3DS_V2"** |
| **Step 1 — Manual code hunt**<br>Grep 16K+ Java files across 7 repos. Miss one → production incident. | **Scan all repos**<br>Find every ON/OFF branch, impacted service and field automatically. |
| **Step 2 — Stale documentation**<br>Confluence pages are outdated. BA notes contradict codebase reality. | **Fetch live Confluence docs**<br>Always current. No stale pages. Metadata extracted per toggle. |
| **Step 3 — Hand-written impact report**<br>Engineer writes a Word doc. No standard format. Takes 2–3 days. | **Generate structured report**<br>CSV + Markdown in minutes. Reproducible across the team. |
| **Step 4 — Review cycle**<br>Back-and-forth with BA and QA to validate. Error-prone each time. | **Advise on safe removal**<br>Decomposition plan. Refactored Java. Zero manual effort. |
| **Result**<br>Days of effort per toggle. Inconsistent. Impossible to scale. | **Outcome**<br>Minutes per toggle. Consistent. Scalable to 1000+ toggles. |

### Agent Roles & Responsibilities

*Each agent owns exactly one domain — clear input/output contracts*


**toggle-orchestrator**
  Session entry point. Routes all commands. NEVER does leaf work.

**SA-1  analysis-engine**
  Java source scan across 7 repos. Builds ON/OFF business & field-level impact.

**SA-2  report-writer**
  Generates 6 structured report types from analysis data.

**SA-3  confluence-enquiry**
  4-tier Confluence search. Extracts page metadata for each toggle.

**SA-4  advisor  ★**
  Plans & executes Java toggle decomposition (on-request only).

**SA-5  workspace-manager**
  Session state, toggle registry, workspace cleanup, repo onboarding.

### Results: What the System Delivered

*MPGS Payment Gateway — production implementation*

| 100+ | 7 | 16K+ | 6 | 5 |
|---|---|---|---|---|
| Feature Toggles Tracked | Repos Scanned | Java Files Analysed | Report Types Generated | Specialist Sub-Agents |

**Before (Manual)**
- Engineer reads Java files manually
- Checks Confluence (often stale)
- Writes impact notes by hand
- Days per toggle  ·  Error-prone

**After (Multi-Agent)**
- User types:  "analyze toggle <name>"
- Orchestrator routes to SA-1 (analysis)
- SA-1 scans repos  ·  SA-3 fetches docs
- Minutes per toggle  ·  Reproducible


---

## Use Case 2 — RAG Evolution Journey

*Real-World Problem — BAs can't track changes in versioned external acquirer specs*


**Real-World Problem:**
- >  Acquirer specs (Visa, Mastercard, bank APIs) are 200+ page PDFs updated quarterly
- >  BAs manually diff v2.3 vs v2.4 — hours of reading to find what changed
- >  No unified way to query: "What changed in Section 4 between versions?"
- >  RAG evolution (V1 → V2 → V3) solves this — ending with LLM-as-retriever

### Real-World Problem: Acquirer Spec Intelligence

*BAs drowning in versioned third-party spec documents — no smart search, no diff, no Q&A*


**Pain 1 — Version Diff Is Manual**
  BA must open two 200-page PDFs side-by-side.
  No tooling to highlight what changed between v2.3 and v2.4.
  Barrier: misses critical field-level changes every release.
  

**Pain 2 — Multi-Acquirer Fragmentation**
  Visa, Mastercard, and local bank specs use different formats.
  BAs switch between 5+ documents with no unified search layer.
  Barrier: slow, error-prone cross-spec comparisons.
  

**Pain 3 — No Natural Language Q&A**
  BAs can't ask: "What are the retry rules for declined transactions?"
  Must CTRL+F keywords and read surrounding context manually.
  Barrier: no intelligent extraction from spec documents.
  

**How each generation solved these pains:**

| Version | What Changed |
|---------|-------------|
| V1 › V2 | Dropped ChromaDB + embeddings entirely. BM25 keyword search over acquirer spec pages — zero infra cost. BAs can now search any versioned spec without GPU or vector DB setup.  |
| V2 › V3 | Dropped BM25 + all retrieval code. LLM reads full acquirer spec as JSON — section-aware, version-aware answers. BAs ask "What changed in Auth flow from v2.3 to v2.4?" and get a direct answer.  |
| V3 + Agents | Added .github/agents for multi-turn Q&A on versioned specs. Orchestrate: convert → ask → summarise → diff across acquirer versions. BA gets a structured change report in minutes instead of days.  |

### Comparison: V1 vs V2 vs V3 — When to Use Which?


| Feature | V1 — Vector RAG | V2 — Vector-less RAG | V3 — Agentic RAG |
|---|---|---|---|
| Setup complexity | High — ChromaDB, GPU, model | Low — BM25 only | Very low — 3 files |
| Infrastructure required | Vector DB + GPU | None | None |
| Semantic search quality | Best (embeddings) | Partial (keyword) | Best (LLM reasoning) |
| Large docs (>100 pages) | Best — chunked | Good | Limited by context |
| Small–medium docs | Overkill | Good | Best |
| Code to maintain | Chunker+Embedder+DB | Retriever+Index | Zero retrieval code |
| Multi-turn agent support | Manual wiring | Manual wiring | Built-in via agents |
| Best for | Enterprise, large corpus | Mid-size, fast POC | Structured docs, RAG POC |

## Key Takeaways

1. Multi-Agent = Orchestrator + Specialists — separation of concerns at the agent level
2. GitHub Copilot Agents (.github/agents) is a real, production-ready framework
3. Choose multi-agent when tasks naturally decompose into parallel specialist work
4. RAG evolved to remove complexity — V3 Agentic RAG needs zero retrieval code
5. Agentic RAG is best for structured docs (acquirer specs, API refs, versioned PDFs)
6. Both use cases share the same principle: LLM-as-orchestrator + specialists


---

## Thank You!


*Questions & Discussion Welcome*

**Raviteja Thota (613491)**  |  Senior Software Engineer  |  EPAM

EngX AI Coach — Final Exam Presentation  |  May 2026
- Use Case 1 — Multi-Agentic Solution (MPGS Feature Toggle Management)
- Use Case 2 — RAG Evolution Journey (Acquirer Spec Intelligence)

📧 OrgEngXSoftwareDevelopersCoach@epam.com
