# Optimal Agent Design Guide
### How to Build LLM Agents That Are Fast, Cheap, and Correct

**Project:** pgs-acquirer-elavon-interface-service  
**Date:** 2026-04-01  
**Applies To:** All Claude agents, sub-agents, and skills in this repository

---

## Table of Contents

1. [The Core Problem — Why Agents Overspend](#1-the-core-problem)
2. [The Mental Model — Tokens Are Money](#2-the-mental-model)
3. [Agent Architecture Principles](#3-agent-architecture-principles)
4. [Bounded Context Design](#4-bounded-context-design)
5. [The 3-Phase Execution Model](#5-the-3-phase-execution-model)
6. [Skill Design — The Knowledge Pre-Load Pattern](#6-skill-design)
7. [MCP Server Selection & Usage](#7-mcp-server-selection--usage)
8. [Sub-Agent Prompt Engineering](#8-sub-agent-prompt-engineering)
9. [Tool Call Discipline](#9-tool-call-discipline)
10. [Output Design](#10-output-design)
11. [Anti-Pattern Catalogue](#11-anti-pattern-catalogue)
12. [Cost Benchmarks — Before vs After](#12-cost-benchmarks)
13. [Checklist — Build a New Agent](#13-checklist-build-a-new-agent)

---

## 1. The Core Problem

Most LLM agent implementations waste **60–80% of their token budget** before producing a
single line of output. The waste comes from four root causes:

```
ROOT CAUSE 1 — Exploratory Reading
  Agent opens files "to understand the structure" before knowing
  what it needs to change. A 500-line file read to find one
  constant value costs ~800 tokens. A grep costs ~5 tokens.
  Waste factor: 160×

ROOT CAUSE 2 — Re-Reading
  Agent reads the same file twice in the same session because
  it didn't retain content from the first read.
  Waste factor: 2× per file

ROOT CAUSE 3 — Sequential Tool Calls
  Agent reads File A, then reads File B, then reads File C —
  three sequential round trips where one parallel batch suffices.
  Waste factor: 3× latency, same token cost

ROOT CAUSE 4 — Narrating Reasoning
  Agent produces paragraph-length explanations of each step
  before taking action. This consumes output tokens and delays
  the user.
  Waste factor: 2–5× output token cost
```

**The fix is not a smarter model. The fix is a better agent design.**

---

## 2. The Mental Model — Tokens Are Money

Every token consumed = real cost. Treat context like RAM: finite,
non-renewable per session, and directly proportional to invoice.

```
┌─────────────────────────────────────────────────────────────┐
│  CONTEXT WINDOW — COST TIERS                                │
│                                                             │
│  TIER 0 — FREE        0 tokens                              │
│  ├─ Values in skill cheat-sheets                            │
│  ├─ Field index maps                                        │
│  ├─ File ownership maps                                     │
│  └─ Decision rules                                          │
│                                                             │
│  TIER 1 — CHEAP       1–20 tokens                           │
│  ├─ grep / ripgrep for one symbol                           │
│  ├─ Read a 10-line targeted range                           │
│  └─ list_dir to confirm path                                │
│                                                             │
│  TIER 2 — MODERATE    20–150 tokens                         │
│  ├─ Read a 50-line method block                             │
│  ├─ Read an import section                                  │
│  └─ get_errors on one file                                  │
│                                                             │
│  TIER 3 — COSTLY      150–600 tokens                        │
│  ├─ Read a full 200-line file                               │
│  └─ Read a full 400-line file (last resort)                 │
│                                                             │
│  TIER 4 — FORBIDDEN   600+ tokens per file                  │
│  └─ Full read of any file > 400 lines unless it             │
│     is the direct target of an edit                         │
└─────────────────────────────────────────────────────────────┘
```

**Target budget per typical task:**

| Task Type | Target Tokens | Acceptable Max |
|---|---|---|
| Value-only field fix (1–5 files) | < 2,000 | 4,000 |
| Single-file code change | < 3,000 | 6,000 |
| Multi-file feature implementation | < 8,000 | 15,000 |
| Full planning + code + review cycle | < 20,000 | 35,000 |

---

## 3. Agent Architecture Principles

### 3.1 Single Responsibility per Agent

Each agent does **one thing**. It does not explore, plan, implement, review,
and push in the same session.

```
WRONG — Monolithic agent
  Agent A: fetches Jira → reads all files → plans →
           implements → reviews → pushes → merges

RIGHT — Specialized agents with handoff
  task-discovery  →  planning  →  code-development
       →  code-review  →  code-push  →  merge-closure
```

Benefits:
- Each agent's context window starts clean
- Each agent loads only the skills it needs
- Failed agents restart without re-doing prior phases
- Token cost per agent is bounded and predictable

### 3.2 Skill-First Loading

**Skills are pre-loaded knowledge.** They eliminate the need to read source files
to answer questions the skill already answers.

```
Session startup order (mandatory):

1. llm-cost-optimizer  — universal cost discipline
2. domain skill        — cheat-sheets, field maps, ownership maps
3. task input          — the actual work item
4. NOTHING ELSE        — until Phase B identifies a specific unknown
```

Every fact you put in a skill cheat-sheet is a file read you never have to do again.

### 3.3 Change-Plan-Before-Action

The agent must build a **complete change plan** (which file, which line, which
change) **before opening any file**. This is the single most effective cost-reduction
technique available.

```
BAD sequence (no plan):
  open file → "let me see what's here" → find something →
  think about it → open another file → "just to check" →
  maybe make a change

GOOD sequence (plan first):
  parse input → map to file/field → resolve unknowns (min reads) →
  open ONE file → apply ALL changes → validate once
```

### 3.4 Minimal Agent Frontmatter Template

Every agent definition starts with this minimal frontmatter:

```yaml
---
name: {agent-name}
description: >
  {One sentence: what it does, when it runs, what it reports.}
argument-hint: >
  {One sentence example of input.}
tools:
  - {only tools this agent actually needs}
skills:
  - llm-cost-optimizer    # ALWAYS first — priority-0
  - {domain-specific-skill}
---
```

Rules:
- **No tools listed that the agent never calls** — each extra tool declaration
  adds cognitive overhead
- **`llm-cost-optimizer` always first** — it governs how all other skills execute
- **Description is one sentence** — not a paragraph

---

## 4. Bounded Context Design

### 4.1 What Bounded Context Means for LLM Agents

Borrowed from Domain-Driven Design: each agent operates within a **clearly defined
boundary** of information it is allowed to load. Information outside that boundary
is accessed only through explicit, minimal queries — never by loading the whole
context of the adjacent domain.

```
┌─────────────────────────────────────────────────────────────┐
│  code-development agent                                     │
│  Bounded Context:                                           │
│  ✓ plan-<story-id>.md          (its instruction set)        │
│  ✓ The specific files listed in the plan                    │
│  ✓ Import blocks of files being edited                      │
│  ✗ Mapper classes (not being edited)                        │
│  ✗ Base configuration classes (not being edited)            │
│  ✗ Parent model classes (not being edited)                  │
│  ✗ Other stories' plans                                     │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 The Boundary Enforcement Rules

| Information Type | Loading Rule |
|---|---|
| Skill cheat-sheets | Always in context — zero cost |
| Files being edited | Load once, edit, do not re-read |
| Files being read for reference | Line range only (±10 lines around the symbol) |
| Files NOT in the task | Never load |
| Parent/base classes | Never load unless they are the edit target |
| Full constants files | Never — use grep to find one value |

### 4.3 Eviction After Each Logical Step

After completing each step, mentally release:

- Full content of files you've finished editing
- Tool call outputs that have been processed
- Intermediate reasoning that led to a decision
- Any re-stated versions of the problem

Retain only:
- Original task / input data
- Remaining items in the change plan
- Content of the file currently being edited

---

## 5. The 3-Phase Execution Model

Apply this to **every task** regardless of size. It is the core protocol of
`llm-cost-optimizer`.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE A — DECIDE                    Target: < 5 seconds
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INPUT:  Task description / mismatch JSON / plan file
  TOOLS:  ZERO
  OUTPUT: Change Plan  =  Map<File → List<Change>>
          Unknown List =  items that block execution

  Rules:
  • Parse the entire input before touching any tool
  • Map every item to: which file, which field/line, what change
  • Use skill cheat-sheets to resolve as many unknowns as possible
  • Only items NOT in cheat-sheets go on the Unknown List

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE B — RESOLVE                   Target: 1–3 tool calls
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INPUT:  Unknown List from Phase A
  TOOLS:  grep (Tier 1) first, then line-range read (Tier 2)
  OUTPUT: Fully resolved Change Plan (zero unknowns)

  Rules:
  • One grep per unknown — do not read the full file
  • Batch parallel reads for unrelated unknowns
  • Update the skill cheat-sheet with each resolved value
  • Stop when the Change Plan is complete — do not explore further

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE C — EXECUTE                   Target: 1 edit per file
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INPUT:  Resolved Change Plan
  TOOLS:  read file (once) → edit (once) → get_errors (once, batched)
  OUTPUT: Compact results table

  Rules:
  • Open each file ONCE
  • Apply ALL changes for that file in ONE edit call
  • Run get_errors on ALL edited files together (one call)
  • Fix any compile errors → re-validate once
  • Emit results table — no narrative
```

---

## 6. Skill Design — The Knowledge Pre-Load Pattern

### 6.1 What a Skill Is

A skill is a **pre-compiled knowledge base** that an agent loads at startup.
Its purpose is to answer questions **without any tool calls**.

Think of it as the difference between:
- A surgeon who memorises anatomy → operates confidently and quickly
- A surgeon who reads the textbook mid-operation → slow and error-prone

### 6.2 The Four Sections Every Domain Skill Must Have

```
Section 1: FILE OWNERSHIP MAP
  Maps test/class name → which file to edit
  Eliminates: directory traversal, grep-for-class searches

Section 2: CONSTANT VALUE CHEAT-SHEET
  Maps actual value (e.g. "250524120515") → constant name → file
  Eliminates: opening TestConstants.java (550 lines) to find one value

Section 3: FIELD INDEX MAP
  Maps ISO/domain field number → constant name → file
  Eliminates: opening message body classes to resolve field indices

Section 4: DECISION RULES
  Deterministic routing: given X, always do Y
  Eliminates: reasoning from first principles every session
```

### 6.3 The Self-Improving Skill Pattern

Every time a new unknown is resolved during a session, the skill cheat-sheet
**must be updated immediately**.

```
Cost of updating cheat-sheet: ~10 tokens (one line added)
Cost saved per future session: ~400 tokens (full file read avoided)
Break-even point: after 1 future session
Net saving after 10 sessions: 3,990 tokens per unknown resolved
```

This transforms agent cost from **constant** (pays the same every session) to
**amortised declining** (cheaper with every session).

### 6.4 Skill Frontmatter That Enforces Universal Loading

```yaml
---
name: llm-cost-optimizer
triggers:
  - always           # ← loaded by every agent automatically
  - onAgentStart
  - onSubAgentStart
priority: 0          # ← loaded before any other skill
---
```

The `always` trigger and `priority: 0` ensure this skill is active even
for dynamically created sub-agents that don't explicitly declare it.

---

## 7. MCP Server Selection & Usage

MCP (Model Context Protocol) servers are external tools that the agent calls
instead of reading files. The right MCP server can replace an expensive file read
with a 5-token query.

### 7.1 MCP Server Selection Matrix

| MCP Server | Primary Use Case | Token Cost | Replaces (Token Cost) | Savings |
|---|---|---|---|---|
| **ripgrep / grep** | Find a symbol, constant, method definition | ~5 | Full file read: ~500 | **99×** |
| **filesystem** (line range) | Read 10–30 targeted lines | ~30 | Full file read: ~500 | **16×** |
| **git** (blame / show) | Find when/what changed in one file | ~15 | Manual investigation | N/A |
| **jvm-tools** | Resolve class members, method signatures | ~10 | Reading message classes: ~400 | **40×** |
| **shell** (mvn compile) | Validate compile in one batched call | ~20 | Trial-and-error cycle | N/A |
| **jira** | Fetch story details directly | ~50 | Agent asking user | ∞ |

### 7.2 The Grep-First Protocol

Before opening any file to find a value, always try grep first:

```bash
# Step 1: Find the constant definition (5 tokens)
grep --include="*.java" -rn "CONSTANT_NAME" src/

# Returns: path/to/File.java:47:  public static final String CONSTANT_NAME = "value";
# Done — you have the value. No file read needed.

# Step 2: Only if you need surrounding context (30 tokens)
# Read File.java lines 44–52 (±5 lines around line 47)
```

**Total cost: ~35 tokens**
**vs full file read: ~500 tokens**
**Saving: 93%**

### 7.3 MCP Server Configuration Recommendations

For this project, configure these MCP servers in `.claude/settings.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "purpose": "targeted line-range reads and file writes",
      "maxLinesPerRead": 100,
      "enforceLineRange": true
    },
    "ripgrep": {
      "purpose": "symbol and constant lookup — use before any file read",
      "includePattern": "**/*.java",
      "maxResults": 5
    },
    "git-local": {
      "purpose": "branch management, blame, diff",
      "allowedCommands": ["status", "diff", "log", "blame", "checkout", "commit", "push"]
    },
    "shell": {
      "purpose": "Maven compile and test validation",
      "allowedCommands": ["mvn clean compile -q", "mvn test -q", "mvn verify -q"]
    }
  }
}
```

### 7.4 What MCP Servers Cannot Replace

| Task | Why MCP Doesn't Help | Better Approach |
|---|---|---|
| Understanding business logic | No MCP knows domain semantics | Skill cheat-sheet |
| Deciding which file to edit | No MCP knows ownership | File ownership map in skill |
| Resolving constant→value mapping | Grep helps but skill is faster | Skill cheat-sheet (zero tokens) |
| Routing mismatch to correct scenario class | Domain knowledge required | Decision rules in skill |

---

## 8. Sub-Agent Prompt Engineering

### 8.1 The Minimal Prompt Principle

Every token in a sub-agent prompt is paid twice:
1. Once to send the prompt to the sub-agent
2. Once as the sub-agent's input context

A bloated 1,500-token parent→child prompt can cost more than the actual work.

**Target sub-agent prompt size: < 300 tokens**

### 8.2 Minimal Sub-Agent Prompt Template

```
TASK: {one imperative sentence — what to do}
INPUT:
  file: {exact relative path}
  change: {field} from {old} to {new}
SKILLS: llm-cost-optimizer, {domain-skill}
OUTPUT: compact table only
```

That's it. Everything else comes from the skill files.

### 8.3 What to NEVER Include in Sub-Agent Prompts

| What | Why Not |
|---|---|
| Background context on the project | Sub-agent loads CLAUDE.md automatically |
| Explanation of WHY the change is needed | Not required to make the change |
| Examples of expected output format | Skill defines the format |
| Chain-of-thought instructions | Skill defines the execution protocol |
| Full file paths (when relative works) | Waste tokens on path prefixes |
| Politeness filler ("please", "could you") | Tokens with zero information content |
| Re-stating information already in a skill | Duplication — the skill is in context |

### 8.4 Context Injection Priority (Stop When Enough)

When a parent agent passes context to a sub-agent, inject in this order and
**stop as soon as the sub-agent has enough to execute**:

```
1. Task definition          (required — always small)
2. Change plan              (required — structured, compact)
3. Resolved unknowns        (prevents sub-agent re-resolving)
4. Relevant cheat-sheet row (only the matching row, not whole table)
── STOP HERE for most tasks ──────────────────────────────────────
5. Specific file content    (only if sub-agent must edit it)
6. Full skill excerpt       (only if sub-agent invokes a new skill type)
```

---

## 9. Tool Call Discipline

### 9.1 The Pre-Flight Check (5 Seconds, Zero Tokens)

Before every tool call, answer these 5 questions:

```
Q1: Is this value already in a skill cheat-sheet?
    YES → use it; skip the tool call entirely

Q2: Can grep answer this in 1 call instead of reading a full file?
    YES → use grep; do not read the full file

Q3: Have I already read this file this session?
    YES → reuse the content; do not re-read

Q4: Is this read necessary or am I being cautious?
    CAUTIOUS → skip it; act on what you know

Q5: Can I batch multiple unknowns into one parallel read?
    YES → batch them; one call instead of N
```

### 9.2 Batching Rules

```
PARALLEL reads (same time, no dependency):
  ✓ Reading File A and File B when neither depends on the other
  ✓ get_errors on 4 edited files simultaneously
  ✓ Multiple grep searches on different symbols

SEQUENTIAL reads (must wait for result):
  ✓ Read file → then edit it  (need content before editing)
  ✓ Edit file → then validate (need edit result before checking)
  ✓ Fix error → then re-validate (need fix applied first)

BATCHED edits (one call per file):
  ✓ All changes to File A in ONE edit call
  ✓ All changes to File B in ONE edit call
  ✗ NEVER: one edit call per field change in same file
```

### 9.3 Validation Discipline

```
BAD pattern (validate after every edit):
  edit Field 1 → validate → edit Field 2 → validate →
  edit Field 3 → validate   (3 validation calls)

GOOD pattern (batch edits, validate once):
  edit Field 1 + Field 2 + Field 3 in ONE call →
  validate ALL at once   (1 validation call)
  
  If errors: fix all errors → validate once more
  Maximum validation cycles: 2
```

---

## 10. Output Design

### 10.1 The Silent Execution Principle

During task execution, the agent produces **no output** until the task is complete.
No status updates. No "I'm now reading file X". No progress narration.

```
FORBIDDEN during execution:
  "I'll now open the file to check..."       ← narration (waste)
  "Let me analyze the structure first..."    ← delay (waste)
  "I found that the constant is..."          ← premature output (waste)
  "Now I'll apply the fix to..."             ← narration (waste)
  "Great! The fix has been applied..."       ← filler (waste)

ALLOWED during execution:
  [tool calls — silent]
  [final output table — after all work is done]
```

### 10.2 Standard Output Table Format

Every agent produces output in this format:

```
┌─────────────────────────────────────────────────────────────────┐
│  {AGENT NAME} — RESULT                                          │
├───────────────────────┬──────────────┬──────────────┬──────────┤
│ File                  │ Change       │ Before       │ After    │
├───────────────────────┼──────────────┼──────────────┼──────────┤
│ {filename}            │ {field/op}   │ {old value}  │ {new}    │
└───────────────────────┴──────────────┴──────────────┴──────────┘
Files touched: N  |  Tool calls: N  |  Errors: 0  |  Est. tokens: ~N
```

The last line — **token estimate** — creates accountability and trains the
habit of measuring cost per task.

### 10.3 Error Output Format

```
ERROR: {File}:{Line} — {description}
FIX:   {what was changed}
STATUS: ✓ Resolved
```

No paragraph explanations. No stack traces in the table.

---

## 11. Anti-Pattern Catalogue

The 15 most expensive agent behaviours, with root cause and prevention:

| # | Anti-Pattern | Token Waste | Root Cause | Prevention |
|---|---|---|---|---|
| 1 | Open full file to find one constant | ~500 tokens | No cheat-sheet | Skill §4: constant cheat-sheet |
| 2 | Re-read a file already in context | 2× file cost | No eviction discipline | §4.2 re-read rule |
| 3 | 5+ sequential reads before first edit | ~2,000 tokens | No Phase A planning | §5 Phase A must complete first |
| 4 | Ask user a clarifying question mid-task | 1 full round trip | Ambiguity tolerance too low | §3 pre-flight Q4 |
| 5 | Narrate each step to the user | ~500 output tokens | Bad output design | §10.1 silent execution |
| 6 | One edit call per field change | N×edit overhead | No batching | §9.2 batching rules |
| 7 | Read mapper/base class for value-only fix | ~400 tokens | Over-investigation | §4.2 boundary rules |
| 8 | Compile after each file edit | N×compile cost | No batch validation | §9.3 validation discipline |
| 9 | Bloated sub-agent prompts (>500 tokens) | 2× on send+receive | No minimal prompt discipline | §8.2 template |
| 10 | Confirm a known value with a tool call | ~20 tokens wasted | Distrust of cheat-sheet | §9.1 pre-flight Q1 |
| 11 | Load 400+ lines when 10 lines suffice | ~400 wasted | No line-range discipline | §2 Tier hierarchy |
| 12 | Discovered constant not saved to cheat-sheet | Future sessions re-pay | No accumulation habit | §6.3 self-improving |
| 13 | Do parallel reads sequentially | 2–3× latency | No parallel batching | §9.2 parallel rules |
| 14 | Verbose error explanations to user | ~200 output tokens | No output template | §10.3 error format |
| 15 | New agent created without cost-optimizer skill | Full waste on every call | No meta-agent rule | meta-agent-creator enforces it |

---

## 12. Cost Benchmarks — Before vs After

Real measurements from the flow-test-fixer task (21 mismatches, 4 files):

### Before llm-cost-optimizer (observed session)

| Step | What Happened | Token Cost |
|---|---|---|
| Read `BaseElavon.java` (414 lines) | "To understand the base interaction structure" | ~830 |
| Read `ElavonVoidTransactions.java` (145 lines) | "To understand void model" | ~290 |
| Re-read `TestConstants.java` (550 lines) | Second read after first pass | ~1,100 |
| Read `ElavonVerifyTransactions.java` (192 lines) | "To understand verify structure" | ~384 |
| Read `ElavonAcquirerConstants.java` (253 lines) | "To find APPLICATION_ID constant" | ~506 |
| Mid-task narration × 8 explanations | User-facing reasoning output | ~800 |
| Sequential tool calls (12 separate reads) | Not batched | ~300 overhead |
| **TOTAL** | | **~4,210 tokens wasted** |
| Actual work tokens | The 4 file edits themselves | ~1,800 |
| **Session total** | | **~6,010 tokens** |

### After llm-cost-optimizer (optimized session)

| Step | What Happened | Token Cost |
|---|---|---|
| Load skill cheat-sheets | Constant map, field map, ownership map | 0 (pre-loaded) |
| Phase A: Parse 21 mismatches, build change plan | Zero tool calls | 0 |
| Phase B: 2 grep calls for 2 unknowns | `CARD_ACCEPTOR` and `DEFAULT_APPROVAL_CODE` | ~10 |
| Phase C: Open 4 files (targeted), apply all edits | One edit call per file | ~600 |
| get_errors on 4 files (one call) | Batched validation | ~30 |
| Output table (no narrative) | Final results only | ~80 |
| **Session total** | | **~720 tokens** |

### Summary

| Metric | Before | After | Improvement |
|---|---|---|---|
| Total tokens | ~6,010 | ~720 | **88% reduction** |
| Time to first edit | ~8 minutes | ~15 seconds | **32× faster** |
| Tool calls | 18 | 7 | **61% fewer** |
| Files read unnecessarily | 5 | 0 | **100% eliminated** |
| Estimated cost (Claude Sonnet) | ~$0.018 | ~$0.0022 | **8× cheaper** |

---

## 13. Checklist — Build a New Agent

Use this when creating any new agent in this project.

### Design Phase

- [ ] **Single responsibility defined** — one verb, one domain, one output
- [ ] **Scope boundaries documented** — what the agent is NOT allowed to load
- [ ] **Required tools listed** — only tools it will actually call
- [ ] **`llm-cost-optimizer` as first skill** — always priority-0
- [ ] **Domain skill exists** — or will be created with the 4 required sections
- [ ] **Skill cheat-sheets populated** — at least 10 common values pre-mapped
- [ ] **File ownership map included** — every relevant file mapped to its scenario class

### Implementation Phase

- [ ] **Frontmatter is minimal** — description ≤ 1 sentence, no bloat
- [ ] **3-phase execution model documented** — Phase A/B/C in agent body
- [ ] **Output table format specified** — compact, with token estimate line
- [ ] **Silent execution rule stated** — no mid-task narration
- [ ] **Batching rules stated** — one edit per file, parallel reads where possible
- [ ] **Sub-agent prompts use minimal template** — ≤ 300 tokens per prompt
- [ ] **MCP servers listed** — grep/ripgrep included for symbol lookups

### Quality Gate

- [ ] **Token budget target stated** — explicit number for this agent type
- [ ] **Anti-pattern list referenced** — agent body explicitly forbids the top 5
- [ ] **Self-improvement hook included** — new cheat-sheet values saved after discovery
- [ ] **meta-agent-creator notified** — if this agent was created manually, update the creator's template

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│  OPTIMAL AGENT — QUICK REFERENCE                                │
├─────────────────────────────────────────────────────────────────┤
│  ALWAYS                                                         │
│  ✓ Load llm-cost-optimizer first (priority-0)                   │
│  ✓ Build change plan BEFORE any tool call (Phase A)             │
│  ✓ Use grep before opening any file (Tier 1 first)              │
│  ✓ Batch all edits per file into one call                       │
│  ✓ Validate all files in one get_errors call                    │
│  ✓ Save new constants to cheat-sheet after discovery            │
│  ✓ Output compact table only — no narration                     │
├─────────────────────────────────────────────────────────────────┤
│  NEVER                                                          │
│  ✗ Read a full file to find one constant                        │
│  ✗ Re-read a file already in context                            │
│  ✗ Produce output before task is complete                       │
│  ✗ Make sequential reads when parallel works                    │
│  ✗ Include background context in sub-agent prompts              │
│  ✗ Compile/validate after each individual file edit             │
│  ✗ Create an agent without llm-cost-optimizer skill             │
├─────────────────────────────────────────────────────────────────┤
│  WHEN IN DOUBT                                                  │
│  → Check skill cheat-sheet first (0 tokens)                     │
│  → If not there: grep (5 tokens)                                │
│  → If still unclear: read 10-line range (30 tokens)             │
│  → If still unclear: the cheat-sheet needs updating             │
└─────────────────────────────────────────────────────────────────┘
```

---

*This document is the living specification for agent design in this project.*
*Update it whenever a new optimization pattern is discovered.*
*Last updated: 2026-04-01*
