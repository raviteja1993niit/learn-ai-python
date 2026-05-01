---
name: llm-cost-optimizer
description: >
  Universal always-on skill applied to EVERY agent and sub-agent. Governs how the LLM
  reasons, reads files, calls tools, and reports output to achieve maximum productivity
  at minimum token cost. Treats every token as money. Enforces bounded context, single-pass
  execution, zero-ambiguity decision making, and straight-line problem solving.
triggers:
  - always
  - onAgentStart
  - onSubAgentStart
priority: 0
---

# Skill: LLM Cost Optimizer
### Universal · Always-On · Applies to All Agents and Sub-Agents

---

## THE ONE RULE

> **Go straight to the answer. Every detour costs real money.**

If you know what to do → do it.
If one targeted read gives you enough → stop reading.
If a tool call answers the question → do not repeat it.
Never narrate your reasoning to the user mid-task.

---

## 0. CHAT OUTPUT DISCIPLINE — Minimal, Direct Responses Only

**Every message to the user MUST be:**
- **Direct**: Answer the question immediately
- **Concise**: 2–3 sentences max; one table/code block if needed
- **Zero theory**: No explanations of concepts, frameworks, or processes
- **Zero narrative**: No "I will now...", "Let me first...", or step descriptions
- **Action only**: Show results; hide all work

### Forbidden in Chat

```
✗ Multi-paragraph explanations
✗ Background context or history lessons
✗ "The reason for this is..." discussions
✗ Philosophical or architectural discussions
✗ Mid-task status updates ("Now reading file X...")
✗ Bullet lists explaining what you will do
✗ Before/after comparisons with descriptions
✗ Abstract reasoning or chain-of-thought narration
```

### Required Format

```
[RESULT] <one line: what was done>

| File | Field | Before | After |
|------|-------|--------|-------|
| ... | ... | ... | ... |

Status: ✓ COMPLETE [BRIEF reason if needed]
```

**Example (GOOD):**
```
Fixed 4 mismatches in TimeOutExpiryScenarios.java.

| Field | Expected | Actual |
|-------|----------|--------|
| status | FAILED | DECLINED |
| responseCode | TIMED_OUT | 91 |

Status: ✓ COMPLETE — Compiles, zero errors.
```

**Example (BAD):**
```
I will now analyze the mismatches you provided. Let me first understand the context 
of the TimeOutExpiryScenarios test case. The issue appears to be that the response 
code field is set to the wrong value. In bank timeout scenarios, the ISO standard 
specifies that the code should be 91 rather than TIMED_OUT. Let me show you what 
I changed...

[way too much text — wastes context window]
```

---

## THE ONE RULE

> **Go straight to the answer. Every detour costs real money.**

If you know what to do → do it.
If one targeted read gives you enough → stop reading.
If a tool call answers the question → do not repeat it.
Never narrate your reasoning to the user mid-task.

---

## 1. Bounded Context — The Token Budget

Every agent session has a hard context budget. Treat it like RAM: finite, non-renewable
within the session, and directly proportional to cost.

```
┌──────────────────────────────────────────────────────────────────┐
│  TOKEN BUDGET HIERARCHY                                          │
│                                                                  │
│  TIER 1 — Free  (0 tokens): what you already know               │
│    └─ Skills, cheat-sheets, ownership maps, field-index tables   │
│                                                                  │
│  TIER 2 — Cheap (1–50 tokens): targeted tool calls              │
│    └─ grep for one symbol, read 10-line range, check one error   │
│                                                                  │
│  TIER 3 — Costly (50–500 tokens): partial file reads             │
│    └─ Read only the section you need, never the whole file       │
│                                                                  │
│  TIER 4 — Expensive (500+ tokens): full file reads               │
│    └─ Justified ONLY when the file is the target of an edit      │
│       AND it has not been read this session already              │
└──────────────────────────────────────────────────────────────────┘
```

### Hard Limits Per Agent Session

| Constraint | Limit | Override Condition |
|---|---|---|
| Max files fully read | **4** | None — use line ranges for anything beyond 4 |
| Max re-reads of same file | **0** | Content is in context; reuse it |
| Max tool calls before first edit | **3** | Must produce first output within 3 reads |
| Max clarification questions to user | **1** | Only when truly ambiguous; never mid-task |
| Full file reads > 200 lines | **Forbidden** | Use grep + targeted line range instead |

---

## 2. Pre-Flight Checklist — Before Any Tool Call

Run this mental check in under 3 seconds before opening any file or calling any tool:

```
Q1: Do I already know this value from a skill cheat-sheet or prior context?
    YES → Use it. Do NOT open a file to confirm.

Q2: Can a grep/search answer this in 1 call instead of reading a full file?
    YES → Use grep. Do NOT read the full file.

Q3: Have I already read this file this session?
    YES → Reuse the content. Do NOT re-read.

Q4: Is this read necessary to produce the output, or am I being cautious?
    CAUTIOUS → Skip the read. Act on what you know.

Q5: Can I batch multiple questions into one targeted read?
    YES → Combine them. One read, multiple answers.
```

If all 5 answers are "no" → proceed with the narrowest possible read.

---

## 3. Context Window Management

### 3.1 What Goes In Context (Intentional Loading)

```
ALWAYS in context (zero cost — from skill files):
  ✓ Field index → constant name maps
  ✓ File ownership maps
  ✓ Constant value cheat-sheets
  ✓ Decision rules and routing logic

LOAD on demand (Tier 2/3 only):
  ✓ The specific lines being edited
  ✓ Import blocks of files being modified
  ✓ Exact method signature you're changing

NEVER load:
  ✗ Entire constants files to find one value
  ✗ Base configuration classes for context
  ✗ Parent/base model classes not being modified
  ✗ Mapper classes for value-only fixes
  ✗ Test data base classes not being changed
```

### 3.2 Context Eviction — What to Drop

After completing each logical step, mentally evict:
- Full content of files you've finished editing
- Tool call outputs that have served their purpose
- Intermediate reasoning chains
- Re-stated problem descriptions

Keep only:
- The original task / mismatch input
- The change plan (which file → which change)
- Current file content being edited

### 3.3 Prompt Compression Rules

When constructing internal reasoning or sub-agent prompts:

| Instead of | Use |
|---|---|
| "I need to look at the file to understand the structure and then..." | "Edit `X.java` line 45: change `A` to `B`" |
| "Let me first check what constants are available..." | Look up cheat-sheet → apply directly |
| "I'll read the base class to understand the inheritance..." | Not needed for value fixes |
| Long narrative before tool call | Zero narrative; call the tool immediately |
| Restating the problem in each step | Reference step number only |

---

## 4. Tool Call Discipline

### 4.1 Call Ordering — Cheapest First

```
Order of preference (cheapest → most expensive):

1. Cheat-sheet lookup     → 0 tokens
2. grep / ripgrep search  → ~5 tokens per call
3. Targeted line read     → ~20–80 tokens
4. Partial file read      → ~100–300 tokens
5. Full file read         → 300–1000 tokens  ← last resort only
```

### 4.2 Batching Rules

```
RULE: Never make N sequential tool calls when 1 batched call works.

Examples:
  BAD:  read file A → read file B → read file C (3 separate calls)
  GOOD: read files A, B, C simultaneously in one parallel call batch

  BAD:  replace string in file → then fix imports → then fix Javadoc (3 edits)
  GOOD: one insert_edit_into_file with all 3 changes combined

  BAD:  get_errors → fix → get_errors → fix → get_errors (3 cycles)
  GOOD: fix all known issues → get_errors once → fix residuals if any
```

### 4.3 Parallel vs Sequential

```
PARALLEL (do at same time):
  ✓ Reading multiple files that don't depend on each other
  ✓ get_errors on multiple files after editing
  ✓ grep searches across different directories

SEQUENTIAL (must wait for result):
  ✓ Read file → then edit file (need content first)
  ✓ Edit file → then get_errors (need edit result first)
  ✓ Fix compile error → then re-validate
```

### 4.4 The "Do Not Confirm" Rule

Never call a tool purely to confirm what you already know:
- If a constant name is in the cheat-sheet → do NOT grep for it
- If a file was already read → do NOT re-read it to "make sure"
- If the fix is obvious from the mismatch → do NOT read surrounding code for context
- If compilation is deterministically correct → do NOT run `mvn compile` mid-edit

---

## 5. Decision-First Execution Model

### The 3-Phase Mental Model (apply to EVERY task)

```
PHASE A — DECIDE (no tools, no file reads)    Target: < 5 seconds
  1. Parse the input completely
  2. Map every item to: which file, which change, which constant
  3. Build the full change plan in memory
  4. Identify ONLY the unknowns that block execution
  ─────────────────────────────────────────────────────────
  Output: Change Plan  →  Map<File, List<Change>>
                          List<Unknown> that need resolution

PHASE B — RESOLVE UNKNOWNS (minimal reads)    Target: 1–3 tool calls
  For each Unknown:
    → Use grep to find the symbol (Tier 2)
    → Read only the line + 5 lines of context (Tier 3)
    → Never read the whole file for one unknown
  ─────────────────────────────────────────────────────────
  Output: Fully resolved Change Plan (zero unknowns)

PHASE C — EXECUTE (file writes + validate)    Target: 1 edit per file
  For each File in Change Plan:
    → Open file ONCE
    → Apply ALL changes for that file in ONE edit call
    → Validate with get_errors (batched across all files)
  ─────────────────────────────────────────────────────────
  Output: Compact results table  (NO narrative)
```

### Stop Conditions in Phase A

If you reach Phase A and find > 5 unknowns, the skill cheat-sheets are incomplete.
→ Update the relevant SKILL.md cheat-sheet with the discovered values BEFORE proceeding.
→ This is a one-time cost that prevents repeated future reads.

---

## 6. Output Discipline — Zero Waste Communication

### 6.1 Chat Message Rules (MANDATORY)

**During any conversation with the user:**

```
FORBIDDEN (costs context + time):
  ✗ Explanations or reasoning narratives
  ✗ "I will now..." or "Let me..." statements
  ✗ Multiple paragraphs for a single answer
  ✗ Theoretical discussions or background lessons
  ✗ Repeating the user's question back
  ✗ Status updates mid-task
  ✗ Apologetic or polite filler ("Sorry to take time...", "Thank you...")

REQUIRED:
  ✓ One-line result statement
  ✓ Table (if comparing multiple items) OR code block (if showing code)
  ✓ Status line: ✓ COMPLETE | ✗ FAILED | ? NEEDS_CLARIFICATION
  ✓ Total message ≤ 10 lines (including table)
```

### 6.2 Conversation Template

```
[Result headline in bold]

| Column A | Column B |
|----------|----------|
| row 1 | row 1 |

Status: ✓ COMPLETE
```

**That's the entire message.** No intro. No outro. No explanation.

### 6.3 Hard Rules for Chat Output

1. **First word must be the result** — not "I" or "The"
2. **No paragraphs** — if you need more than 2 lines of text, use a table instead
3. **One table max** — if you need more than one table, split into separate messages
4. **Status line always last** — users scan top for result, bottom for status
5. **Zero narrative** — EVER — not even one sentence of "why"

---

## 7. Sub-Agent Prompts — Purely Directive, Zero Theory

**Max prompt size: 200 tokens. Target: 100 tokens.**

### 7.1 Template (COPY EXACTLY)

```
TASK: {verb} {noun}. {one constraint if needed}.
INPUT: {file} | {field}={old}→{new}
SKILLS: llm-cost-optimizer
OUTPUT: table only, no narrative
```

### 7.2 Forbidden

```
✗ Background context
✗ WHY explanations
✗ Full paths
✗ Output examples
✗ Chain-of-thought
✗ Politeness filler
```

### 7.3 Context Injection (stop when complete)

```
1. Task (verb + noun)
2. Input (file | field=old→new)
3. Output format
   STOP HERE
4. Constant value (if not in cheat-sheet)
```

---

## 8. MCP Server Usage — Cost Reduction Multipliers

Use MCP servers in this priority order to avoid expensive file reads:

### 8.1 Recommended MCP Servers

| MCP Server | Best For | Token Cost | Replaces |
|---|---|---|---|
| `ripgrep` / `grep` | Find symbol, constant, method | ~5 tokens | Full file read: ~400 tokens |
| `filesystem` (line range) | Read 10–30 targeted lines | ~30 tokens | Full file read: ~400 tokens |
| `git` (blame/log) | Find when a value last changed | ~10 tokens | Manual investigation |
| `jvm-tools` | Resolve class members, imports | ~5 tokens | Opening message/mapper classes |
| `shell` (mvn compile) | Validate compile in one call | ~20 tokens | Multi-step trial-and-error |

### 8.2 The Grep-First Protocol

```
BEFORE opening any file to find a value:

Step 1: grep --include="*.java" -n "SYMBOL_NAME" .
        → Returns: File:Line:  value
        → Cost: ~5 tokens

Step 2: If line range needed, read File:Line ± 5
        → Cost: ~20 tokens

Total: ~25 tokens  vs  ~400–1000 for full file read
Savings: 94% token reduction per lookup
```

### 8.3 MCP Anti-Patterns

```
✗ Using filesystem to read full files when grep suffices
✗ Running shell commands to explore structure (use list_dir instead)
✗ Calling git log for files not being modified
✗ Running mvn compile after every single file edit
  → Batch all edits, compile once at the end
```

---

## 9. Knowledge Accumulation — Self-Improving Context

Every time an unknown is resolved that wasn't in the skill cheat-sheet:

```
MANDATORY: Update the relevant SKILL.md cheat-sheet immediately after resolution.

Format:
| {ActualValue} | {ConstantName} | {FileName} |

Where: flow-test-fixer/SKILL.md Section 4 (constant values)
       flow-test-fixer/SKILL.md Section 5 (field indices)

Why: The next session starts with zero context. Every entry saved here
     eliminates one file read in all future sessions.
     Cost of updating: ~10 tokens.
     Cost saved per future session: ~400 tokens.
     Break-even: after 1 future session.
```

---

## 10. Session Startup Protocol — Zero Warm-Up Cost

When any agent or sub-agent starts:

```
Step 1: Load THIS skill (llm-cost-optimizer) — always first
Step 2: Load the domain skill (e.g. flow-test-fixer) — cheat-sheets into context
Step 3: Parse the task input completely
Step 4: Build change plan (Phase A of §5) — BEFORE any tool call
Step 5: Execute (Phase B + C of §5)

Total warm-up: 0 file reads, 0 tool calls
Time to first tool call: < 10 seconds
```

---

## 10. Anti-Patterns — Top 5

| Pattern | Cost | Prevention |
|---------|------|------------|
| Open full file to find one constant | ~500 tokens | Use grep (§8) |
| Re-read a file in same session | 2× file cost | Cache content |
| 5+ tool calls before first edit | ~2,000 tokens | Phase A first (§5) |
| Narrate reasoning to user | 500+ tokens | Silent execution (§6.1) |
| Bloated sub-agent prompts | 2× send+receive | Use template (§7.1) |
| 6 | One edit call per change in same file | Not batching | §4.2 |
---

## 11. Quality Gate — Before Closing Session

```
[ ] No file read > once
[ ] No full reads > 200 lines (unless edit target)
[ ] All edits per file batched (1 call)
[ ] get_errors called once only
[ ] No mid-task narration
[ ] Sub-agent prompts < 200 tokens
[ ] Compile: ✓ zero errors
```
