# Comprehensive App Guides — Interview Preparation & Deep-Dive Reference

> **Author:** Raviteja Thota | EngX AI Coach Final Exam Prep
> **Covers:** All 6 AI/ML apps built during the EngX AI Coach program
> **Purpose:** Deep technical understanding, alternative solutions, and interview-ready Q&A

---

## Table of Contents

1. [App 1 — `agentic-ai-toggle-management`](#app-1--agentic-ai-toggle-management)
2. [App 2 — `vector-rag-app-v1`](#app-2--vector-rag-app-v1)
3. [App 3 — `vector-less-rag-app-v2`](#app-3--vector-less-rag-app-v2)
4. [App 4 — `vector-less-rag-app`](#app-4--vector-less-rag-app)
5. [App 5 — `vector-less-rag-agentic`](#app-5--vector-less-rag-agentic)
6. [App 6 — `transcript-notes-generator`](#app-6--transcript-notes-generator)
7. [Cross-App Interview Questions](#cross-app-interview-questions)

---

# App 1 — `agentic-ai-toggle-management`

## Overview

An **enterprise-grade multi-agent AI system** that automates the complete lifecycle of feature toggle management across 7 Java microservice repositories (CardPaymentEngine, Orchestrator, BusinessService, Console, MSOUI, DirectAPI, BatchSettlementService) in the Mastercard Payment Gateway Services (MPGS) platform.

### Business Problem Solved

Manual toggle analysis required engineers to:
- Manually grep 14,000+ Java files across 7 repos
- Cross-reference Confluence documentation manually
- Write impact reports per toggle by hand
- Repeat this for 73 registered toggles (334 in extended list)
- Cost: days per toggle, high error rate, hard to keep current after releases

**After:** ~15 minutes per toggle, reproducible, auditable, extensible.

---

## Architecture

```
User (Natural Language Command)
         │
         ▼
  toggle-orchestrator (Coordinator)
         │
    ┌────┴────┬──────────┬───────────┬───────────┐
    ▼         ▼          ▼           ▼           ▼
  SA-1      SA-2       SA-3        SA-4        SA-5
Analysis  Report    Confluence  Advisor    Workspace
 Engine   Writer    Enquiry    (on-req)    Manager
    │         │          │
  Scans     Writes    Fetches
  Java      6 report   Confluence
  repos     types      metadata
    │
  CSV/Registry
```

### Agent Responsibilities

| Agent | Role | Key Tools Used |
|-------|------|----------------|
| **toggle-orchestrator** | Central coordinator — routes commands, enforces guardrails, manages batch state | None (pure routing) |
| **SA-1 toggle-analysis-engine** | Registry build, Java source scan, ON/OFF impact analysis, S2A CSV enrichment | `toggle-search-utility.ps1`, `build-toggle-registry-lookup.ps1`, `lsp-java-impact-analyzer.py` |
| **SA-2 toggle-report-writer** | Generates 6 structured report types + polished Markdown | File write utilities, `toggle-publish-utility.ps1` |
| **SA-3 toggle-confluence-enquiry** | 4-tier Confluence search, metadata CSV output | Confluence MCP (Atlassian REST API) |
| **SA-4 toggle-advisor** | Decomposition planning, dry-run refactoring, stuck recovery | `lsp-call-graph-grep-fallback.ps1`, `lsp-java-impact-analyzer.py` |
| **SA-5 toggle-workspace-manager** | Session state, knowledge index, repo onboarding, workspace cleanup | File system ops, `archive-repo-data.ps1`, `repo-memory-mapper.ps1` |

---

## Key Design Principles

### 1. Single Responsibility Per Agent
Each agent owns one domain. SA-1 never writes reports. SA-2 never scans Java. The orchestrator never does leaf work.

### 2. Registry as Single Source of Truth
All analysis flows through `data/registry/toggle-registry-lookup.csv`. Every agent reads the same registry file. No agent builds its own private list of toggles.

### 3. Two Scan Strategies
- **Full scan**: Used for repos with <3000 Java files (CPE, Orchestrator, BusinessService, Console, MSOUI, BatchSettlementService). Scans all `.java` files.
- **Targeted scan**: Used for DirectAPI (~10,367 Java files). Uses a pre-computed list `direct-api-toggle-bearing-files.txt` — only scans files known to contain toggle references.

### 4. Confluence 4-Tier Search
```
Tier 1: exact_title_in_priority_spaces (MPGSIOG, MPGSIOGWIP)
   ↓ if no result
Tier 2: exact_title_all_spaces
   ↓ if no result
Tier 3: fuzzy_title_in_priority_spaces
   ↓ if no result
Tier 4: full_text_all_spaces
```
Starts with the most specific, most relevant search to avoid noise.

### 5. Dry-Run Before Destructive Operations
Toggle decomposition (removing toggle code from Java source) always runs in dry-run mode first. Actual source edits require explicit user confirmation.

### 6. Slash Commands as First-Class Citizens
Every workflow has both plain-English and `/slash-command` form:
- `analyze toggle "X"` ≡ `/analyse-toggle X`
- `rebuild registry` ≡ `/rebuild-registry`

### 7. Extensibility Without Agent Changes
New repositories: `onboard repo <name>` → no agent definitions change.
New toggles: append to input CSV → no agent definitions change.

---

## File Structure

```
agentic-ai-toggle-management/
├── .github/agents/           ← Agent definition files (.md)
├── .github/instructions/     ← Shared rules (changelog, guardrails)
├── knowledge/
│   ├── config.yml            ← All path/parameter configuration
│   ├── index.md              ← Quick reference: agents, data files, repos
│   └── tool-command-registry.yml
├── data/
│   ├── enquiry/              ← Input: 73/334 toggle CSV lists
│   ├── registry/             ← Toggle-to-Java-class mappings (per repo + combined)
│   ├── analysis/             ← ON/OFF impact CSVs (per repo + combined)
│   ├── temp/                 ← Intermediate scan results
│   └── archive/              ← Archived old data
├── tools/active/             ← PowerShell + Python utility scripts
├── reports/                  ← Generated reports (MD, HTML, CSV)
└── logs/                     ← Audit changelog
```

---

## 9 Supported Workflows

| Workflow | Command | What It Does |
|----------|---------|--------------|
| A | `analyze toggle <name>` | Locate Java usages + ON/OFF business & field impact |
| A-all | `analyze all remaining toggles` | Batch-process all unprocessed toggles |
| B | `rebuild registry` | Re-scan all repos, rebuild lookup CSV |
| C | `fetch confluence data for <name>` | Retrieve Confluence page metadata |
| D | `generate report` | Generate 6 structured report types |
| D-P | `generate polished report` | Final human-readable Markdown summary |
| E | `check for missing toggles` | Find gaps in analysis coverage |
| F | `onboard repo <name>` | Register a new Java repository |
| G | `check for toggle changes` | Detect additions/removals since last run |
| H | `clean up files` | Deduplicate, fix encoding, clean workspace |
| I | `backfill missing analysis` | Fill analysis gaps for unprocessed toggles |

---

## Alternative Solutions Considered

### Alternative 1: LangChain + LangGraph Multi-Agent
**Pros:** Mature ecosystem, built-in memory, LCEL chains
**Cons:** Overkill for a file-system workflow; LangGraph adds complexity for linear workflows; requires Python runtime integration with Java codebases
**Why not used:** The `.github/agents` framework (GitHub Copilot Agents) is already embedded in JetBrains IDE where Java repos are open — zero extra infra needed.

### Alternative 2: Single Large-Context LLM (Just Feed Everything to GPT-4)
**Pros:** Simplest approach
**Cons:** 14,000+ Java files far exceed any context window; no structured output; no audit trail; cannot be run incrementally
**Why not used:** Physical impossibility at scale.

### Alternative 3: CrewAI
**Pros:** Agent orchestration with role-playing, good for autonomous teams
**Cons:** Requires Python scaffolding, agent-to-agent messaging overhead; doesn't integrate with IDE tools natively
**Why not used:** Same as LangChain — unnecessary infra when IDE-native agents are available.

### Alternative 4: Simple Shell Script
**Pros:** Fastest to write
**Cons:** No intelligence; would need manual Confluence lookup; no ON/OFF impact analysis; no natural language interface; no session state management
**Why not used:** No AI = no value for the use case.

### Alternative 5: Vector-Based Code Search (RAG over Java files)
**Pros:** Semantic matching beyond exact grep
**Cons:** Toggle names are exact strings — grep is 100% reliable and faster; building a code embedding index for 14,000+ files adds significant overhead with no benefit for this task
**Why not used:** Problem is exact-match, not semantic search.

---

## Interview Q&A

**Q1: What is a multi-agent system and how does this app qualify?**
> A multi-agent system has multiple autonomous AI agents, each with a defined role, that collaborate to solve a task no single agent can handle alone. This app has 6 agents (1 orchestrator + 5 sub-agents), each with its own skills, owned data files, and decision domain. The orchestrator routes commands; sub-agents execute specialised tasks. Communication is through natural language prompts + shared file system state.

**Q2: Why did you use GitHub Copilot Agents instead of LangChain or LangGraph?**
> The Java repositories are open in JetBrains IDE, and the GitHub Copilot `.github/agents` framework is IDE-native — no separate runtime, no extra infrastructure. LangChain/LangGraph would require a separate Python process to interact with the IDE tools, adding latency and complexity. The agent definitions in `.md` files are also version-controlled alongside the codebase, which is a natural fit.

**Q3: How do you prevent agents from doing each other's work (scope creep)?**
> The orchestrator enforces guardrails through a strict routing table. Each sub-agent's definition explicitly states what it owns and what it must NOT do. For example, SA-1 is explicitly prohibited from writing reports; SA-2 is explicitly prohibited from scanning Java files. This is enforced in the agent `.md` instruction files, not at runtime.

**Q4: What is the toggle registry and why is it important?**
> The registry (`toggle-registry-lookup.csv`) maps each toggle name to its constant name, Java class, file path, line number, usage type, and repository. It's the pre-computed index that makes analysis instant — instead of scanning 14,000+ files at query time, the registry is built once (Workflow B) and reused for all analyses. It also enables cross-repo analysis: one lookup finds all usages of a toggle across all repos.

**Q5: How does ON/OFF impact analysis work?**
> SA-1 finds each Java class that references the toggle. It then reads ~60 lines of context (20 before + 40 after the toggle reference). From this context, the LLM infers: what business logic executes when the toggle is ON vs OFF, what database fields/API fields are affected, and what downstream services are impacted. The result is a structured CSV row per (toggle, class) pair.

**Q6: What is the "targeted scan strategy" for DirectAPI?**
> DirectAPI has 10,367 Java files — scanning all of them for every toggle query would be too slow. Instead, a one-time scan builds `direct-api-toggle-bearing-files.txt`: a list of only the files that contain at least one toggle reference. Future toggle analyses only scan this subset. This is a pre-filtering optimisation, equivalent to an index in a database.

**Q7: How would you scale this to 500 repositories?**
> Three changes needed: (1) Make the registry distributed — shard it by repository into separate files (already done); (2) Add parallel batch processing — the PowerShell tools already support batch runs, so add `ForEach-Object -Parallel` for multi-repo scans; (3) Cache Confluence results — avoid re-fetching unchanged documentation. The agent architecture doesn't change.

**Q8: What are the limitations of this system?**
> (1) Requires all Java repos to be cloned locally — not suitable for purely remote codebases. (2) Java-only — parser and registry builder are Java-specific. (3) Confluence access requires Atlassian MCP integration, which is not portable to all environments. (4) Context window limits mean very large Java classes (>500 lines) may get truncated impact analysis. (5) Agent definitions in `.md` files require human maintenance when tool paths change.

**Q9: What is "toggle decomposition" and why does it need a dry-run?**
> Decomposition means permanently removing a feature toggle from Java source code — changing `if (toggle.isEnabled(Feature.X)) { ... } else { ... }` to just the ON-state code path, deleting the else branch. This is irreversible source code modification affecting multiple files. A dry-run shows exactly which files/lines would change, letting the engineer review before committing. The actual run requires explicit `confirm actual run` command to prevent accidental changes.

**Q10: How do you handle rate limits from Confluence and LLMs?**
> SA-3 uses batch-size-5 for Confluence API calls with delays between batches. The orchestrator tracks failed calls and can retry individual toggles. For LLM calls, the system uses adaptive delays and session checkpointing — if a batch fails mid-way, the session state persists so work can resume from the last successful batch.

---

# App 2 — `vector-rag-app-v1`

## Overview

A **vector-based Retrieval-Augmented Generation (RAG) application** built with FastAPI that answers questions about uploaded documents using TF-IDF + Latent Semantic Analysis (LSA) for semantic vector search, with GitHub Copilot as the LLM backend.

**Key distinction:** Uses semantic vector search (TF-IDF + LSA, no HuggingFace/internet), multi-format document parsing (PDF, DOCX, XLSX, CSV, TXT, Markdown), and session-based context to maintain per-document state.

---

## Architecture

```
Browser (HTML/JS)
      │
      ▼ HTTP (FastAPI)
  server.py
      │
      ├─── POST /upload  ──────► parser.py ──► Page[]
      │                               │
      │                          vector_index.py
      │                         (TF-IDF + LSA → embeddings)
      │
      └─── POST /ask ─────────► rag.py
                                    │
                           vector_index.search()
                           (cosine similarity top-K)
                                    │
                               llm.py (GitHub Copilot)
                                    │
                               RAGResult (answer + sources)
```

---

## Key Components

### `parser.py` — Document Parser
Converts any document to `List[Page]`. Each `Page` is a natural document unit (PDF page, DOCX section, XLSX sheet, CSV batch, text/markdown section). No fixed-size chunking — boundaries follow the document's own structure.

Supported formats:
- **PDF**: `pdfplumber` (primary) → `PyPDF2` (fallback). Extracts text + tables as pipe-separated rows.
- **DOCX**: Uses Word Heading styles for section boundaries. Falls back to paragraph batching.
- **XLSX**: Each sheet becomes one page. Tables rendered as Markdown.
- **CSV**: 50 rows per page, Markdown table format.
- **TXT/MD**: Splits on Markdown headings first; falls back to 800-word paragraph batches.

### `vector_index.py` — Semantic Vector Index (No HuggingFace)
```
Page texts
    │
    ▼
TfidfVectorizer (max_features=15000, ngram_range=(1,2), sublinear_tf)
    │
    ▼
TruncatedSVD / LSA (n_components=128, reduces to dense semantic vectors)
    │
    ▼
L2-normalize → embeddings matrix (n_pages × 128)
    │
Query time: TF-IDF → SVD → normalize → dot product = cosine similarity
    │
top-K pages returned
```

**Why TF-IDF + LSA instead of sentence-transformers?**
- No model downloads (offline friendly)
- No GPU dependency
- LSA captures semantic similarity via co-occurrence patterns (e.g., "car" and "automobile" share similar LSA vectors)
- Fast to build and query even on CPU

### `rag.py` — RAG Pipeline
```python
class VectorRAGPipeline:
    # On init: parse file → build VectorIndex
    # On ask:  search top-K pages → build context string → call LLM → update chat_history
    # Supports: multi-turn conversation via chat_history list
```

### `llm.py` — LLM Client (GitHub Copilot)
Uses `openai` SDK with `base_url="https://models.inference.ai.azure.com"` and token from `gh auth token`. Supports model selection (claude-haiku-4.5, gpt-4o-mini, etc.)

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Vector library | sklearn TF-IDF + TruncatedSVD | No downloads, no GPU, works offline |
| Context window | 24,000 chars max | Balance between context richness and LLM token limits |
| Session management | `session_id` → in-memory `VectorIndex` | Avoids re-building index per question for same doc |
| Chat history | Appended to each LLM call | Enables follow-up questions referencing previous answers |
| Page granularity | Natural doc units (not fixed-size chunks) | Avoids breaking semantic units at arbitrary boundaries |

---

## Alternative Solutions

### Alternative 1: sentence-transformers (HuggingFace)
**Pros:** Much better semantic understanding (e.g., SBERT models); handles paraphrase matching better
**Cons:** 100+ MB model download; GPU for performance; latency on cold start
**When to prefer:** When high semantic accuracy is needed and internet/GPU is available

### Alternative 2: ChromaDB + sentence-transformers
**Pros:** Persistent vector store; scales to millions of documents; production-grade
**Cons:** Additional service to run; storage overhead; complex session management
**When to prefer:** When you need to persist indexed documents across sessions

### Alternative 3: OpenAI text-embedding-ada-002
**Pros:** High-quality embeddings; 8K token context per chunk
**Cons:** Cost per token; requires internet; privacy concerns for sensitive documents
**When to prefer:** Production SaaS apps with quality requirements and internet access

### Alternative 4: BM25 (no vectors)
**Pros:** Simpler, no math overhead, zero dependencies beyond rank-bm25
**Cons:** Purely keyword-based; misses synonyms; no semantic similarity
**When to prefer:** When documents use very specific technical terminology (see App 3/4)

### Alternative 5: FAISS
**Pros:** Highly optimised vector search; scales to billions of vectors; Meta open-source
**Cons:** Binary library, harder cross-platform; over-engineered for small docs
**When to prefer:** When searching across millions of documents at production scale

---

## Interview Q&A

**Q1: What is RAG and why is it needed?**
> RAG (Retrieval-Augmented Generation) grounds an LLM's answer in specific documents rather than its training data. Without RAG, an LLM either doesn't know your private document or hallucinates. RAG: (1) retrieves relevant sections from the document, (2) puts them in the LLM's context window, (3) the LLM synthesises an answer only from that context. This prevents hallucination for private/domain documents.

**Q2: What is LSA and how does it provide semantic search?**
> LSA (Latent Semantic Analysis) uses SVD (Singular Value Decomposition) on a TF-IDF matrix to find latent semantic dimensions that capture word co-occurrence patterns. Words that appear in similar contexts get similar vector representations. So "car" and "automobile" end up close in LSA space even if they never appear together. It's a classical NLP technique that predates neural embeddings but is computationally cheap.

**Q3: What is cosine similarity and why use it for vector search?**
> Cosine similarity measures the angle between two vectors rather than their magnitude. After L2-normalisation, `dot(v1, v2) = cos(angle)`. Two documents with similar topic proportions will have a small angle (high cosine similarity) even if one is longer than the other. It's direction-invariant, which makes it robust to document length differences.

**Q4: What are the limitations of TF-IDF + LSA vs neural embeddings?**
> TF-IDF+LSA: (1) Cannot understand word order or grammar (bag-of-words). (2) LSA dimensions are linear — cannot capture non-linear semantic relationships. (3) Out-of-vocabulary words are ignored. (4) Requires rebuilding when adding new documents. Neural embeddings (SBERT, OpenAI): contextual, capture syntax + semantics, handle OOV via subword tokenization. Trade-off: TF-IDF+LSA is fast and offline; neural embeddings are more accurate but need models.

**Q5: How does the context builder handle very long documents?**
> It iterates retrieved pages in descending relevance order. For each page, it checks if adding the full page would exceed `max_chars=24000`. If it would overflow but >300 chars remain, it appends a truncated version. Otherwise it stops. This ensures the most relevant content always fits while respecting LLM token limits.

**Q6: What is `session_id` and why does it exist?**
> When a user uploads a document, a `session_id` is generated (UUID). The `VectorIndex` for that document is stored in a server-side dictionary keyed by `session_id`. Subsequent questions reuse the same index without re-parsing/re-vectorising. This is a simple in-memory session cache — in production, it would need TTL eviction or a persistent store (Redis, etc.).

**Q7: Why use `sublinear_tf=True` in TfidfVectorizer?**
> Without sublinear_tf, TF grows linearly — a word appearing 100 times gets 100x the weight of one appearing once. With `sublinear_tf=True`, TF = 1 + log(term_frequency). This dampens the effect of very frequent terms and prevents any single high-frequency word from dominating the vector. It generally improves retrieval quality for documents with repeated terminology.

**Q8: What is `n_components=128` in TruncatedSVD and how to choose it?**
> `n_components` is the number of latent semantic dimensions. 128 is a good default: enough to capture meaningful topic clusters, few enough for fast computation. Too few (e.g., 10): overly coarse representation, topics blur together. Too many: slower, can overfit to noise. For production, it can be tuned using reconstruction error or retrieval accuracy on a test set.

**Q9: Why support 6 document formats instead of just PDF?**
> Real enterprise documents live in many formats: technical specs in PDF, contracts in DOCX, data in XLSX, logs in CSV, notes in TXT/Markdown. A format-agnostic parser makes the app universally useful. Each format has a different structure — PDF has pages, DOCX has heading styles, XLSX has sheets — so each needs a tailored parser that respects these natural boundaries.

**Q10: How would you make this production-ready?**
> (1) Replace in-memory session dict with Redis (TTL-based eviction). (2) Persist ChromaDB index to disk so it survives server restarts. (3) Add authentication (OAuth2 or API key). (4) Add rate limiting per user. (5) Replace TF-IDF+LSA with sentence-transformers for better quality. (6) Add structured logging and monitoring. (7) Dockerise the service. (8) Add streaming responses for long LLM outputs.

---

# App 3 — `vector-less-rag-app-v2`

## Overview

A **vector-free RAG application** (FastAPI) that eliminates all vector DB and embedding overhead by using **BM25 keyword search** directly over document pages. It's a direct simplification of App 2, removing ChromaDB, sentence-transformers, and the sklearn dependency.

**The core insight:** For technical documents with precise terminology (ISO specifications, API docs, legal contracts), BM25 keyword matching is often equal or superior to semantic vector search because the query terms appear verbatim in the document.

---

## Architecture

```
Browser (HTML/JS)
      │
      ▼ HTTP (FastAPI)
  server.py
      │
      ├─── POST /upload  ──────► parser.py ──► Page[]
      │                               │
      │                          page_index.py (BM25Okapi)
      │
      └─── POST /ask ─────────► rag.py
                                    │
                           page_index.search() → BM25 top-K
                                    │
                               llm.py (GitHub Copilot)
                                    │
                               RAGResult (answer + sources)
```

---

## Key Components

### `page_index.py` — BM25 Index
```python
class PageIndex:
    # Tokenizes all page texts (lowercase alphanumeric)
    # Builds BM25Okapi index over page-level tokens
    # search(query, top_k) → [(Page, score), ...]
    # Fallback: if all BM25 scores are 0 (query terms not in corpus), returns top_k pages
    # build_context() → formats pages as context string with page headers
    # build_toc() → generates a document table of contents
    # score_chart_data() → returns Altair-compatible data for visualising retrieval scores
```

### BM25Okapi Algorithm
```
BM25(q, d) = Σ IDF(qi) × (tf(qi,d) × (k1+1)) / (tf(qi,d) + k1 × (1-b + b×|d|/avgdl))
```
- `IDF`: Inverse Document Frequency — rare terms across pages score higher
- `tf`: Term frequency within the page
- `k1=1.5`: Controls TF saturation (diminishing returns for repeated terms)
- `b=0.75`: Controls length normalisation (longer pages get slight penalty)

### `rag.py` — RAG Pipeline
Same structure as App 2, but `VectorIndex` replaced by `PageIndex`. Notable: no session_id needed in v2 (simpler API).

---

## V1 → V2 Key Changes

| Aspect | V1 (vector-rag-app-v1) | V2 (vector-less-rag-app-v2) |
|--------|------------------------|------------------------------|
| Search | TF-IDF + LSA (semantic) | BM25 (keyword) |
| Dependencies | sklearn, numpy | rank-bm25 only |
| Setup time | Slower (matrix operations) | Instant |
| Semantic matching | Yes (synonyms, topics) | No (exact terms only) |
| Best for | Conceptual/conversational docs | Technical specs, exact terminology |
| Memory | Higher (embedding matrix) | Lower (token lists only) |
| Install size | Large (sklearn, scipy) | Tiny |

---

## Alternative Solutions

### Alternative 1: Hybrid BM25 + Vector (RRF Fusion)
**Approach:** Run both BM25 and vector search independently; combine rankings using Reciprocal Rank Fusion (RRF): `score = Σ 1/(k + rank_i)`
**Pros:** Best of both worlds — catches both exact-match and semantic relevance
**Cons:** Needs both a vector model and BM25; 2× the retrieval overhead; result de-duplication needed
**When to prefer:** Production RAG systems where recall is critical (e.g., enterprise search)

### Alternative 2: TF-IDF Without SVD (No LSA)
**Approach:** Skip the dimensionality reduction step; use raw TF-IDF cosine similarity
**Pros:** Even simpler than App 1; no LSA overhead
**Cons:** Very high-dimensional sparse vectors; exact-match like BM25 but less principled
**When to prefer:** This is essentially BM25 — prefer BM25's principled probabilistic model instead

### Alternative 3: Elasticsearch BM25
**Pros:** Production-grade; handles sharding, replication, multi-tenancy; REST API
**Cons:** Requires separate Elasticsearch cluster; far more infrastructure for a single-user app
**When to prefer:** Enterprise document search with multiple users and large corpora

### Alternative 4: SQLite FTS5 (Full-Text Search)
**Pros:** Zero extra dependencies; SQLite is embedded; supports BM25 natively via `rank` function
**Cons:** Not as flexible; harder to integrate with Python doc structures; limited to text
**When to prefer:** Embedded applications where an extra Python package is unacceptable

---

## Interview Q&A

**Q1: What is BM25 and why is it called "Okapi"?**
> BM25 (Best Match 25) is a probabilistic ranking function from information retrieval. "Okapi" refers to the Okapi IR system at City University London where it was developed. It's the algorithm behind many production search engines (Elasticsearch, Solr, Lucene). BM25 ranks documents by query term frequency (TF) and inverse document frequency (IDF), with normalisation for document length. "25" is just the version number in the BM research series.

**Q2: What is the difference between BM25 and TF-IDF?**
> Both use TF×IDF but differ in TF saturation and length normalisation. TF-IDF: raw term frequency, no saturation. BM25: uses `tf×(k1+1)/(tf+k1×(1-b+b×|d|/avgdl))` which saturates (adding the same term many times has diminishing returns) and normalises for document length. BM25 is empirically stronger for retrieval tasks and is the default in Elasticsearch.

**Q3: Why would keyword search outperform semantic search for ISO specifications?**
> Technical standards use precise terminology — "TVR" (Terminal Verification Result), "EMV", "ISO 8583 field 55". A user asking about "field 55" means exactly "field 55" — there's no semantic paraphrase. LSA might map "field 55" close to "transaction data element" which could dilute the result. BM25's exact term matching returns the pages that literally contain "field 55" with high confidence.

**Q4: What happens when the user asks a question whose terms aren't in the document?**
> `PageIndex.search()` returns `[(p, 0.0) for p in self.pages[:top_k]]` — the first N pages with score 0. This is the fallback that always returns *something* even for out-of-vocabulary queries. Ideally, the LLM is then instructed to say "this information is not in the document" when no relevant context is found. A better fallback would be to return the table of contents or summary sections.

**Q5: How do you tokenise text for BM25?**
> Simple lowercase alphanumeric tokenisation: `re.findall(r"[a-zA-Z0-9]+", text.lower())`. This strips punctuation and splits on non-alphanumeric characters. Advantages: simple, robust, handles mixed content. Limitations: loses hyphenated terms (`ISO-8583` becomes `["iso", "8583"]`); no stemming (so "runs" and "running" are different tokens). Stemming (Porter, Snowball) could improve recall.

**Q6: What is IDF and why does it matter for retrieval?**
> IDF (Inverse Document Frequency) = log(N / df(t)) where N = total documents and df(t) = documents containing term t. A term appearing in every page has IDF ≈ 0 — it's useless for distinguishing pages. A term appearing in only 1 page has high IDF — it strongly discriminates. This is why "the", "is", "of" get low scores even if they appear many times: they're in every page.

**Q7: What is the `score_chart_data` method used for?**
> It returns per-page BM25 scores normalised to percentage of the maximum score. This data feeds an Altair bar chart in the UI that shows which pages were retrieved and how confident the retrieval was. It's a transparency/explainability feature — the user can see exactly which pages the answer came from and how relevant each was.

**Q8: Why keep a TOC builder (`build_toc`)?**
> Before asking a question, the user may want to browse the document structure. The TOC lists all pages with their titles and word counts, giving an overview of what's in the document. It's particularly useful for large XLSX files where sheet names summarise major data categories, or for technical PDFs where chapter headings reveal content scope.

---

# App 4 — `vector-less-rag-app`

## Overview

A **Streamlit-based vector-less RAG application** with a ChatGPT-style dark-themed UI. Builds on App 3 but adds:
- **Multi-query retrieval** — searches with the full question AND each significant token independently, then merges results (crucial for short acronyms like "TVR", "EMV")
- **Chunker module** — for apps that need sub-page chunks instead of whole pages
- **Altair visualisation** — interactive retrieval score bar chart
- **ChatGPT-style UI** — dark theme, scrollable chat history, real-time streaming feel

---

## Architecture

```
Streamlit Browser UI (dark theme)
          │
          ▼
       app.py
          │
     ┌────┴────┐
     │         │
  Upload     Ask question
     │         │
  parser.py  rag.py
     │         │
   Page[]    ├── _multi_query_search()
             │    ├── BM25(full question)    → {page: score}
             │    ├── BM25("token1")         → {page: score}
             │    ├── BM25("token2")         → {page: score}
             │    └── merge (max score wins) → top-K pages
             │
          llm.py → GitHub Copilot
             │
          Answer + source citations
             │
          Altair score chart (optional)
```

---

## Multi-Query Retrieval — The Key Innovation

```python
def _multi_query_search(self, question: str) -> List[Tuple[Page, float]]:
    # Step 1: search with full question
    combined = {page.page_num: (page, score)
                for page, score in self.index.search(question, top_k=self.top_k * 2)}

    # Step 2: search with individual meaningful tokens
    STOP = {"the", "and", "for", ...}  # 22 common stop words
    tokens = [t for t in re.findall(r"[A-Za-z0-9]+", question)
              if len(t) >= 2 and t.lower() not in STOP]

    for token in tokens:
        for page, score in self.index.search(token, top_k=self.top_k):
            if score > combined.get(page.page_num, (None, -1))[1]:
                combined[page.page_num] = (page, score)  # keep max

    # Step 3: rank by max score, return top_k
    return sorted(combined.values(), key=lambda x: x[1], reverse=True)[:self.top_k]
```

**Why this matters:** For a question like "What does TVR mean?", BM25 on the full question may score "TVR" poorly because the full question includes stop words diluting the signal. Searching "TVR" alone as a separate query finds the exact pages that define it.

---

## `chunker.py` — Sub-Page Chunking

When full pages are too large for context, the chunker splits them:
- Splits on double newlines (paragraph boundaries) first
- Falls back to sentence splitting (`. `, `! `, `? `) for large paragraphs
- Overlap: last `overlap=50` chars carried to next chunk for continuity
- Default: `chunk_size=500`, `overlap=50`

This module enables a hybrid retrieval pipeline: page-level BM25 for coarse retrieval + chunk-level context for fine-grained LLM input.

---

## Streamlit UI Features

- **Dark ChatGPT-style theme**: Custom CSS, `#212121` background, `#ececec` text
- **Hidden Streamlit chrome**: `#MainMenu, footer, header` hidden
- **Real-time streaming feel**: Progress spinners during model inference
- **Source citations**: Each answer shows which pages were used with BM25 scores
- **Retrieval score chart**: Altair bar chart showing relevance per page
- **Model selector**: Dropdown with all available GitHub Copilot models + speed hints
- **Multi-provider support**: GitHub Copilot + Azure OpenAI endpoint support

---

## Alternative Solutions

### Alternative 1: Gradio UI instead of Streamlit
**Pros:** Simpler API for ML demos; auto-generates file upload widgets; Hugging Face native
**Cons:** Less control over CSS/theming; limited layout flexibility; worse for multi-step workflows
**When to prefer:** Quick prototypes for ML model demos

### Alternative 2: LlamaIndex Query Engine
**Pros:** Full RAG framework with multiple retrieval strategies; pluggable LLMs; persistence
**Cons:** Heavy dependency (>50 sub-packages); abstraction hides what's happening; steep learning curve
**When to prefer:** Production RAG systems where you need query routing, sub-question generation, etc.

### Alternative 3: Haystack Pipeline
**Pros:** Production-grade; modular pipeline; supports hybrid retrieval (BM25 + embedding); REST API
**Cons:** Requires Docker for full stack; complex configuration; slower to prototype
**When to prefer:** Enterprise document QA with multiple retrieval strategies and LLM backends

### Alternative 4: Query Expansion (HyDE — Hypothetical Document Embeddings)
**Approach:** First ask the LLM to generate a hypothetical answer to the question; then embed that hypothetical answer and search for similar document sections
**Pros:** Better semantic matching; the hypothetical answer uses terminology similar to the document
**Cons:** Requires one additional LLM call per question; needs embeddings; more latency
**When to prefer:** Semantic search scenarios where exact keyword matching is insufficient

---

## Interview Q&A

**Q1: What problem does multi-query retrieval solve that single-query BM25 does not?**
> Single-query BM25 tokenises the full question. For "What does TVR mean?", the tokens are `["what", "does", "tvr", "mean"]`. Stop words (`what`, `does`, `mean`) dilute the signal for `tvr`. The pages that define TVR may not score highly because BM25 distributes weight across all tokens. Multi-query re-runs BM25 with just `tvr` as the sole query, which gives 100% of the score weight to that term. The union of both searches is more robust.

**Q2: What is the "max score wins" merge strategy?**
> When a page appears in multiple sub-query results (e.g., from the full question AND from the individual token "TVR"), we keep the highest BM25 score it received across all queries. This is conservative: we don't sum scores (which could inflate scores for pages that match many individual tokens but are not genuinely relevant) — we take the most optimistic single-query assessment of each page's relevance.

**Q3: What is chunking and when is it needed vs page-level retrieval?**
> Chunking splits large pages into smaller overlapping segments. It's needed when: (1) individual pages are very long (e.g., a 50-page PDF has pages with 3000 words each), (2) the LLM context window is small, (3) the answer is likely in a specific paragraph rather than the whole page. Page-level retrieval is sufficient when pages are natural, self-contained units and fit comfortably in context. App 3/4 prefer page-level because ISO specification pages are well-scoped.

**Q4: Why use Streamlit instead of FastAPI for this version?**
> App 3 (FastAPI) serves a JavaScript frontend — suitable when you want a decoupled SPA frontend. Streamlit embeds UI state management in Python, eliminating the need for JavaScript. For a single-user local app, Streamlit's auto-refresh and widget state management is much faster to develop. The trade-off is that Streamlit is not suitable for high-concurrency production APIs — FastAPI is better for that.

**Q5: What is Altair and why use it for the score chart?**
> Altair is a declarative statistical visualisation library based on Vega-Lite. It's used because: (1) it's JSON-spec based, meaning charts are declarative and easy to compose, (2) it integrates natively with Streamlit via `st.altair_chart()`, (3) it supports interactive tooltips with minimal code. The retrieval score bar chart shows page-by-page BM25 relevance, helping users understand why certain pages were used as context.

**Q6: How does the overlap in chunking prevent information loss at boundaries?**
> When a paragraph is split at character 500, the sentence at the boundary may be split in the middle. If the next chunk starts fresh, the first sentence of the new chunk loses its preceding context. The overlap carries the last `n` characters from the previous chunk into the start of the next chunk. This ensures boundary sentences have enough context for BM25 to score them correctly.

**Q7: What is the STOP word list used for in multi-query retrieval?**
> Stop words are filtered out before running individual-token sub-queries. Searching for "the" or "what" individually would match every page equally (universal terms = IDF ≈ 0). The filter keeps only meaningful tokens — technical terms, proper nouns, numbers. The custom list (`{"the", "and", "for", ...}`) includes 22 common English words. Note: domain-specific stop words (e.g., "feature" in a toggle management context) are NOT filtered, preserving technical specificity.

---

# App 5 — `vector-less-rag-agentic`

## Overview

The most radical approach: **no retriever class, no BM25, no embeddings, no chunking**. Instead, documents are converted to a **structured JSON tree** and the **GitHub Copilot LLM itself acts as the retrieval agent** — it reads the full document structure and locates relevant information using its own reasoning.

**Key insight:** If the document fits in the LLM's context window (128K tokens for GPT-4o), you don't need retrieval at all. The LLM can read the whole document and find what's relevant — it's a retrieval agent by nature.

---

## Architecture

```
Document (PDF / DOCX / XLSX)
         │
         ▼
   convert.py                ← Step 1: Structure extraction
   (PyPDF2 / python-docx / openpyxl)
         │
         ▼
   JSON Tree File             ← { filename, file_type, has_toc, sections[], tables[] }
         │
         ▼
   ask.py                     ← Step 2: Question → Answer
   build_context(doc)         ← Formats JSON tree as readable Markdown prompt
         │
         ▼
   GitHub Copilot LLM         ← Reads FULL document, answers question
   (gpt-4o-mini, gpt-4o, etc.)
         │
         ▼
       Answer
```

---

## Key Components

### `convert.py` — Document to JSON Tree Converter

**Two modes for each format:**

For **PDF**:
- **With TOC (bookmarks)**: Uses PDF outline entries as section boundaries → accurate, structure-preserving
- **Without TOC**: Scans line-by-line for heading patterns → numbered headings (`1.`, `1.2`), ALL-CAPS short lines, Title Case short lines → auto-generates heading from first sentence if nothing detected

For **DOCX**:
- **With Heading styles**: Uses Word Heading 1/2/3 as section boundaries
- **Without Heading styles**: Same line-level heuristic as PDF; falls back to grouping every 10 paragraphs with auto-generated heading

For **XLSX**: Sheet names are always the headings.

**JSON Schema:**
```json
{
  "filename": "report.pdf",
  "file_type": "pdf",
  "has_toc": true,
  "sections": [
    {"id": 0, "heading": "Executive Summary", "level": 1, "content": "...", "page": 1}
  ],
  "tables": [
    {"id": 0, "section_id": 0, "headers": ["Col1", "Col2"], "rows": [["a", "b"]]}
  ]
}
```

### `ask.py` — LLM-as-Retriever

```python
def ask(json_path, question, model="gpt-4o-mini"):
    doc = json.loads(Path(json_path).read_text())
    context = build_context(doc)         # Full JSON → readable Markdown
    # context includes: all sections with headings + all tables in Markdown format
    
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},  # instructs LLM to use only doc content
            {"role": "user",   "content": f"Here is the document:\n\n{context}\n\n---\n\nQuestion: {question}"}
        ],
        temperature=0.2, max_tokens=1024
    )
```

The `SYSTEM_PROMPT` explicitly instructs: "Answer using only information from the document JSON. Do NOT use outside knowledge."

---

## Comparison with Other Apps

| Feature | vector-rag-v1 | vector-less-v2/v3 | **vector-less-agentic** |
|---------|--------------|-------------------|------------------------|
| Retrieval | LSA vectors | BM25 | None (LLM reads all) |
| Context | Top-K pages | Top-K pages | **Full document** |
| Setup code | VectorIndex class | PageIndex class | **2 scripts, 0 classes** |
| Works for | Any size | Any size | **Small-medium docs (<300p)** |
| Structure-aware | No | No | **Yes (sections + tables)** |
| Code complexity | High | Medium | **Minimal** |
| Token cost | Low | Low | **Higher (full doc)** |
| Multi-turn | Via RAGPipeline | Via RAGPipeline | **One-shot (CLI)** |

---

## Alternative Solutions

### Alternative 1: Keep BM25 with JSON Tree structure
**Approach:** Build BM25 index over the JSON sections instead of raw pages
**Pros:** Handles large documents; still benefits from structural headings as metadata
**Cons:** Loses the "LLM reads full context" advantage; sections may be too granular for BM25
**When to prefer:** When documents exceed LLM context window but you still want structure-awareness

### Alternative 2: LLM with Tool Call for Section Lookup
**Approach:** Define a `get_section(heading)` tool; the LLM calls the tool to fetch specific sections on-demand
**Pros:** True agentic retrieval; LLM decides which sections to read; handles very large documents
**Cons:** Multiple round-trips; more complex prompting; needs function calling support
**When to prefer:** Documents that exceed even 128K context; true long-document understanding tasks

### Alternative 3: GraphRAG (Microsoft)
**Approach:** Build a knowledge graph from the document; traverse graph for multi-hop questions
**Pros:** Handles relational questions across sections; better for entity-rich documents
**Cons:** Complex pipeline; requires LLM for graph construction; not suitable for simple QA
**When to prefer:** Documents with many inter-related entities (corporate knowledge bases, medical records)

### Alternative 4: ColBERT Late Interaction
**Approach:** Store per-token embeddings instead of per-page; compute query-document similarity at token level
**Pros:** Better precision; handles complex multi-part questions; supports MaxSim retrieval
**Cons:** High storage (per-token embeddings); complex to implement; needs GPU for inference speed
**When to prefer:** Production retrieval where precision is critical and storage is not a concern

---

## Interview Q&A

**Q1: What is "LLM as retriever" and why is it different from RAG?**
> Traditional RAG retrieves document chunks → feeds them to LLM. LLM-as-retriever removes the separate retrieval step: the entire document goes into the LLM's context, and the LLM uses its own attention mechanism to "retrieve" (locate and attend to) relevant information. It's only possible because modern LLMs have 128K+ token context windows. The trade-off: higher token cost per query but simpler architecture and better context coherence.

**Q2: Why convert to JSON tree instead of sending raw PDF text?**
> Raw PDF text is flat — just a stream of characters with no semantic structure. The JSON tree preserves the document's hierarchy (sections, headings, levels, tables) as structured data. This gives the LLM explicit section boundaries to navigate, table data in parseable form, and heading labels that aid retrieval reasoning. Sending "Section: Executive Summary → [content]" is more LLM-friendly than raw page text.

**Q3: What is the `has_toc` flag and how does it affect conversion?**
> `has_toc=true` means the document has its own structural outline (PDF bookmarks or DOCX Heading styles). In this case, the converter uses the document's own structure as section boundaries — it trusts the author's organisation. `has_toc=false` triggers heuristic heading detection (numbered lines, ALL-CAPS, Title Case patterns) + auto-heading generation from the first sentence of each section. TOC-present docs produce more accurate sections.

**Q4: What are the limitations of the agentic approach?**
> (1) Document size: documents >100K tokens (~300 pages) will exceed even GPT-4o's 128K context. (2) Cost: sending the full document every query is expensive at scale. (3) Latency: larger context = slower inference. (4) No multi-turn memory: each `ask()` call is a fresh conversation (CLI script). (5) Not suitable for streaming updates — if the document changes, no incremental index update, must re-convert. (6) Tables >100 rows are truncated to avoid token overflow.

**Q5: How does the authentication work without exposing a token?**
> `_resolve_github_token()` tries two strategies: (1) `subprocess.run(["gh", "auth", "token"])` — calls the GitHub CLI to get the currently authenticated user's token; (2) `os.environ.get("GITHUB_TOKEN")`. Neither approach stores the token in code or config files. This is a security best practice: tokens are never hardcoded, never in `.env` files that might be committed, and are resolved at runtime from the OS-level authentication state.

**Q6: What auto-heading logic does `convert.py` use for un-structured documents?**
> Four patterns checked in order: (1) Lines starting with "Chapter/Section/Part/Appendix" (case-insensitive). (2) Numbered headings: `1.`, `1.2`, `Chapter 3`. (3) ALL-CAPS short lines (3-80 chars). (4) Title Case lines ≤ 12 words without sentence-ending punctuation. If none match, `_auto_heading()` extracts the first sentence of the paragraph as the heading (truncated to 80 chars). This ensures every section has a human-readable heading for LLM navigation.

**Q7: Why limit table rows to 100 in `build_context()`?**
> A table with 10,000 rows would overflow the LLM context window. The limit of 100 rows is a pragmatic safety bound that keeps tables LLM-processable while preserving the most important data (typically headers and leading rows contain the most representative information). An improvement would be to filter rows that contain terms matching the question.

---

# App 6 — `transcript-notes-generator`

## Overview

A **Streamlit app** that converts spoken content (audio recordings or text transcripts) into structured, professional Markdown guides. It uses:
- **faster-whisper** for free, local, offline audio transcription (no OpenAI Whisper API cost)
- **GitHub Copilot LLM** for intelligent transcript → structured notes conversion
- A **multi-stage pipeline** with SHA-256 caching and run-state checkpointing for cost efficiency
- **System audio capture** (WASAPI loopback on Windows) for recording live audio

---

## Architecture

```
                    ┌──────────────┐
Audio Input ──────► │ audio_        │
(mic / upload /    │ transcriber.py│──► raw text transcript
 system capture)   │ faster-whisper│
                    └──────────────┘
                          │
                    ┌──────────────────────────────────────┐
Text Transcript ──► │         transcript_processor.py       │
                    │                                       │
                    │  Short (<8000c):  Single-pass LLM    │
                    │                                       │
                    │  Long (>8000c):                       │
                    │  chunk(15000c) → extract notes        │
                    │        ↓ (SHA-256 cache)              │
                    │  dedup → local compress               │
                    │        ↓ (if >70K chars)              │
                    │  LLM compress (batches of 5)          │
                    │        ↓                              │
                    │  Final synthesis → Markdown guide     │
                    └──────────────────────────────────────┘
                          │
                    Streamlit UI → Preview + Download (.md)
```

---

## Key Components

### `audio_transcriber.py` — Local Audio Transcription

```python
WhisperModel(model_size, device="cpu", compute_type="int8")
# int8 quantisation: 2-4× faster than float32, minimal accuracy loss
# VAD filter: skip silent gaps automatically
# beam_size=5: balance speed vs accuracy
# Language detection: automatic (or specify ISO code)
```

Available models:
| Model | Size | Use Case |
|-------|------|----------|
| tiny | ~75 MB | Fast prototype, lower accuracy |
| base | ~145 MB | Default — good balance (for technical content) |
| small | ~465 MB | Better accuracy for accented speech |
| medium | ~1.5 GB | High accuracy, slower |

### `transcript_processor.py` — Multi-Stage Processing Pipeline

**Stage 1 — Normalise:**
Strip timestamps (`[00:01:23]`, `(00:45)`), collapse multiple whitespace, clean punctuation artifacts.

**Stage 2 — Route by length:**
- `< 8,000 chars`: Single LLM call with synthesis prompt → direct Markdown output
- `≥ 8,000 chars`: Multi-stage pipeline

**Stage 3 — Chunk extraction (for long transcripts):**
```
Chunk 1 (15,000 chars) → LLM extract bullet notes → cache to disk
Chunk 2 (15,000 chars) → LLM extract bullet notes → cache to disk
... (adaptive delay: 2s normal, 65s after 403 rate limit)
```

Cache key: `SHA-256(chunk_text + model + temperature + PIPELINE_VERSION)`

**Stage 4 — Deduplication & Compression:**
- Python-level dedup: remove duplicate bullet lines within the combined notes
- If combined notes > 70,000 chars: LLM compression in batches of 5 chunk-notes
- Goal: fit synthesis input within 80,000 chars

**Stage 5 — Final Synthesis:**
Single LLM call with synthesis prompt → structured Markdown guide with:
- H1 title ("# Topic — A Complete Guide")
- H2 sections, H3 sub-sections, H4 details
- Tables only if explicitly needed
- ASCII diagrams only for flows/architectures
- Code blocks with language tags
- Key Takeaways section

**Caching & Checkpointing:**
- Each chunk result is disk-cached → re-running with same transcript = zero LLM calls
- Run-state checkpointing: saves progress after each stage to `output/cache/runs/`
- If the app crashes mid-processing, resuming picks up from last completed stage
- Three resume points: extraction stage, compression stage, synthesis stage

### `system_audio_recorder.py` — WASAPI Loopback Capture
Captures system audio (what's playing through speakers) using WASAPI loopback API — enables recording Zoom/Teams/YouTube audio without a virtual audio cable. Windows-only.

---

## Synthesis Prompt Structure

The synthesis LLM call uses a structured system prompt with strict rules:

```
STRUCTURE RULES:
- Exactly ONE H1: "# Topic — A Complete Guide"
- H2 for major sections, H3 for sub-sections, H4 sparingly
- Never skip heading levels
- "---" between every H2 section
- End with "## Key Takeaways" (bullet list)

CONDITIONAL FORMATTING (only if source supports it):
- Tables: ONLY when 2+ items compared side-by-side, minimum 3 data rows
- ASCII diagrams: ONLY when a flow/pipeline/architecture is described
- Code blocks: ONLY when actual code/commands present; always tag with language
- Blockquotes: For direct narrator quotes

QUALITY RULES:
- Preserve narrator's own phrasing and analogies
- Every concept touched must appear, even briefly mentioned
- No placeholder text, no invented examples
```

---

## Alternative Solutions

### Alternative 1: OpenAI Whisper API
**Pros:** No local model download; handles longer audio; potentially higher accuracy; simpler code
**Cons:** Costs $0.006/minute; requires internet; privacy concern for sensitive recordings; cannot capture system audio
**When to prefer:** Production apps, mobile apps, when local compute is unavailable

### Alternative 2: AssemblyAI / Rev.ai
**Pros:** Speaker diarisation (identifies who said what); timestamps per word; punctuation/capitalisation auto-correction; higher accuracy for diverse accents
**Cons:** Paid service; requires internet; privacy concerns
**When to prefer:** Meeting transcription apps where speaker identification matters

### Alternative 3: LangChain Document Summariser
**Pros:** Built-in map-reduce summarisation chain; handles arbitrary document length
**Cons:** Uses a generic summarise prompt; lacks the structured guide output format; no caching mechanism; no run-state recovery
**When to prefer:** Simple summarisation without structured output requirements

### Alternative 4: DeepGram
**Pros:** Real-time streaming transcription; speaker diarisation; 100+ languages; high accuracy
**Cons:** Paid API; network dependent; no local processing
**When to prefer:** Production real-time transcription (live meeting captions, voice assistants)

### Alternative 5: Whisper.cpp (C++ port)
**Pros:** Faster than Python faster-whisper on some systems; direct binary execution
**Cons:** Requires compilation; no Python integration without bindings; harder to maintain
**When to prefer:** Embedded systems, edge deployment without Python runtime

### Alternative 6: NotebookLM (Google)
**Pros:** Excellent structure extraction; supports multiple source documents; AI-generated podcast audio
**Cons:** Cloud-only; privacy concerns; no API for automation; cannot batch-process multiple files
**When to prefer:** Manual, one-off note-taking from public documents

---

## Interview Q&A

**Q1: What is faster-whisper and how is it different from OpenAI Whisper?**
> faster-whisper is a Python wrapper around CTranslate2 — a highly optimised inference engine for Whisper models. It runs the same OpenAI Whisper models (tiny/base/small/medium/large) but 2-4× faster on CPU using int8 quantisation. It doesn't use PyTorch — it uses CTranslate2's C++ engine with INT8-quantised weights. Whisper is the underlying model (OpenAI's speech recognition), faster-whisper is the optimised runtime.

**Q2: What is VAD (Voice Activity Detection) and why enable it?**
> VAD automatically detects segments of audio that contain human speech vs silence/noise. With `vad_filter=True`, faster-whisper skips silent gaps (meetings have many pauses) and only transcribes speech segments. This: (1) reduces transcription time (skipping silence), (2) improves accuracy (silence doesn't produce hallucinated text), (3) reduces token count in the output. The `min_silence_duration_ms=500` setting means pauses >500ms are treated as silence.

**Q3: What is INT8 quantisation and why does it speed up inference?**
> INT8 quantisation represents model weights as 8-bit integers instead of 32-bit floats. This reduces model size by ~4× and speeds up CPU matrix multiplication (modern CPUs have optimised INT8 SIMD instructions). The accuracy trade-off is minimal for ASR tasks — the model's speech recognition ability is preserved because the quantisation error is small relative to the variance in human speech. Result: 2-4× faster inference with <1% WER (Word Error Rate) increase.

**Q4: How does the SHA-256 caching work and why is it important?**
> Cache key = `SHA-256(chunk_text + model_name + temperature + PIPELINE_VERSION)`. If any of these inputs change, the cache key changes and the cached result is invalidated. Why important: A 1-hour transcript produces ~29 chunks (at 8k chars), each requiring an LLM call. Re-processing the same transcript costs ~29 API calls. With caching, the second run costs 0 API calls — instant replay. This is critical for iterative development (adjusting the synthesis prompt without re-processing all chunks).

**Q5: What is run-state checkpointing and when does it activate?**
> Checkpointing saves the pipeline's progress to `output/cache/runs/<hash>.json` after completing each stage. If the app crashes or hits a rate limit mid-processing, the next run loads the checkpoint and continues from where it stopped — either the extraction stage (resuming from last completed chunk), compression stage (skipping extraction), or synthesis stage (skipping everything). Without checkpoints, a crash at chunk 28 of 30 would force re-processing all 28 chunks.

**Q6: Why set `PIPELINE_VERSION = "2"` and when should you bump it?**
> The pipeline version is included in every cache key. Bumping it (to "3") automatically invalidates all existing chunk caches — forcing a full re-run. This is needed when: the extraction prompt changes (old cached bullets are structured differently), the normalisation logic changes (old cache captured timestamps that should now be stripped), or a bug fix changes the chunking boundaries. It prevents stale cache entries from silently producing wrong output.

**Q7: Why use 15,000-char chunks instead of 8,000?**
> Larger chunks (15K vs 8K) reduce the number of LLM API calls (~15 calls vs ~29 calls for a 1-hour transcript). Since each call has inherent latency (~5-10s) and rate limiting risk, fewer calls = faster processing and fewer 403 errors. 15K chars is ~3,750 words — still well within a 128K-token model's context. The downside: each LLM extraction call gets slightly more information to process, but modern models handle this easily.

**Q8: What is WASAPI loopback and how is it different from microphone capture?**
> WASAPI (Windows Audio Session API) is the Windows audio API. "Loopback mode" captures the audio that's being played through the speakers/headphones — the system's audio output stream. This lets you record: Zoom calls, YouTube videos, Teams meetings, etc. without a virtual audio cable. Normal microphone capture records the physical microphone input only. WASAPI loopback is Windows-only (macOS has different audio APIs like CoreAudio with BlackHole for similar functionality).

**Q9: What LLM prompt engineering techniques are used in the synthesis step?**
> (1) **Role assignment**: "You are an expert technical writer" — sets the expected expertise level. (2) **Explicit structure rules**: prescribes exact heading levels (H1/H2/H3/H4), separator usage, section order — eliminates guessing. (3) **Conditional formatting rules**: "ONLY add tables when..." — prevents hallucinated tables for non-comparative content. (4) **Negative constraints**: "No placeholder text", "No invented examples" — prevents padding. (5) **Output-only instruction**: "Output ONLY the Markdown — no preamble" — avoids wrapper text.

**Q10: How would you improve this app for real-time live transcription?**
> (1) Replace file-based processing with a streaming audio buffer — chunk incoming audio every 5-10 seconds. (2) Use faster-whisper's streaming transcription API. (3) Use an append-only notes buffer — process each audio chunk as it arrives and append bullets to a live notes panel. (4) Add incremental synthesis — regenerate the summary section after each N new bullet points. (5) WebRTC browser microphone capture for web deployment. (6) Switch from SHA-256 file caching to in-memory LRU cache for faster real-time access.

---

# Cross-App Interview Questions

These questions span multiple apps and test your understanding of the overall AI development journey.

**Q1: Describe the RAG evolution across your 4 RAG apps.**
> **V1 (vector-rag-app-v1):** TF-IDF + LSA semantic vectors → cosine similarity retrieval over pages. Best for conceptual documents. **V2 (vector-less-rag-app-v2):** BM25 keyword search, no vectors. Simpler, faster, better for precise technical terminology. **V3 (vector-less-rag-app):** BM25 + multi-query retrieval. Handles acronyms and short tokens that confuse single-query BM25. **V4 (vector-less-rag-agentic):** No retrieval at all — full document as JSON tree context. LLM is the retriever. Zero code complexity, structure-aware, but limited to documents that fit in context window. Each step removed complexity while solving a specific retrieval failure mode.

**Q2: What common patterns appear across all your apps?**
> (1) **GitHub Copilot as LLM backend** — all apps use `gh auth token` for zero-config authentication; (2) **Document parsing as a first-class concern** — all RAG apps share a similar parser (PDF/DOCX/XLSX/CSV/TXT); (3) **Multi-turn conversation history** — all RAG apps maintain `chat_history` for follow-up questions; (4) **Natural document units over fixed-size chunks** — pages, sections, sheets as retrieval units; (5) **Agent-based workflow** — agentic apps use `.github/agents` definitions; (6) **No cloud infrastructure** — all apps run locally with free GitHub Copilot access.

**Q3: What is the difference between agents, RAG, and LLMs?**
> **LLM**: A large neural network that generates text based on a prompt. It has no memory between calls, no ability to execute code, and only knows its training data. **RAG**: A pattern that augments an LLM's context with relevant retrieved documents — enables answering questions about documents the LLM wasn't trained on. **Agent**: An LLM that can take actions — call tools, read/write files, make decisions, delegate subtasks. RAG is a pattern; agents are systems. An agent can use RAG as one of its retrieval tools.

**Q4: How do you handle LLM hallucination across your apps?**
> Several strategies used: (1) **Explicit system prompt constraint**: "Answer using ONLY information from the document. Do NOT use outside knowledge." (2) **Source attribution**: Every RAG answer includes which pages were used as sources — users can verify. (3) **Low temperature** (0.2): Reduces creative/hallucinated output; keeps answers grounded in retrieved context. (4) **BM25 fallback to first N pages**: Rather than returning empty context, returns some document content — ensures the LLM always has document grounding even for unmatched queries.

**Q5: What would you change if you had to deploy these apps to 1,000 concurrent users?**
> **RAG apps**: (a) Move from in-memory session dict to Redis for session management; (b) Pre-compute and persist vector/BM25 indexes to disk (eliminate per-upload rebuild); (c) Add rate limiting + API key auth; (d) Dockerise + Kubernetes deployment; (e) Add async FastAPI endpoints with connection pooling; (f) Add observability (Prometheus + Grafana). **Multi-agent system**: (a) Distributed task queue (Celery + Redis) for batch toggle analysis; (b) Read-only replica of Java repos for parallel scanning; (c) Elasticsearch instead of PowerShell grep for faster registry building.

**Q6: What is prompt engineering and give examples from your apps?**
> Prompt engineering is the practice of crafting LLM inputs to reliably elicit desired outputs. Examples: (1) **Role assignment** — "You are an expert technical writer" (transcript app); (2) **Constraint injection** — "Answer using ONLY the document" (agentic RAG); (3) **Output format specification** — "Output ONLY compact bullet points — maximum 12 words per bullet" (transcript chunk extraction); (4) **Conditional rules** — "Add tables ONLY when 2+ items are compared" (prevents hallucinated tables); (5) **Negative examples** — "No placeholder text like [To be filled]"; (6) **Explicit structure** — prescribing H1/H2/H3/H4 heading nesting rules.

**Q7: Compare the tradeoffs between the multi-agent approach (App 1) vs a single-agent approach.**
> **Single agent**: Simpler to develop, easier to debug, no routing overhead, suitable for linear tasks. Limitations: context window fills quickly (one agent cannot hold 14,000 Java files in memory), hard to maintain as responsibilities grow, single point of failure. **Multi-agent**: Separation of concerns, each agent has focused context, parallel execution possible, independent testing, easier to extend (add new agent without changing others). Limitations: inter-agent communication complexity, harder to trace failures, orchestrator becomes a bottleneck if poorly designed. For the toggle management domain with 7 repos, 73 toggles, and 6 distinct workflow types, multi-agent is justified.

**Q8: How does GitHub Copilot's authentication work across all your apps?**
> All apps use the same 2-step resolution: (1) `subprocess.run(["gh", "auth", "token"])` — calls the GitHub CLI binary to get the currently logged-in user's OAuth token. This works silently after a one-time `gh auth login`. (2) If step 1 fails, reads `GITHUB_TOKEN` environment variable. The resolved token is then used as `api_key` with `openai.OpenAI(base_url="https://models.inference.ai.azure.com", api_key=token)`. This approach means no token is ever stored in code or config files — security best practice for local developer tools.

---

*Generated for EngX AI Coach Final Exam preparation — Raviteja Thota, May 2026*
