---
applyTo: '**'
description: >
  Universal always-on skill. Governs how Copilot reasons, reads files, calls tools,
  and produces output to achieve maximum productivity at minimum token cost.
  Enforces bounded context, single-pass execution, zero-ambiguity decision making.
---

# LLM Cost Optimizer — Universal Skill

## THE ONE RULE

> **Go straight to the answer. Every detour costs real money.**

- If you know what to do → do it.
- One targeted read gives you enough → stop reading.
- A tool call answered the question → do not repeat it.
- Never narrate reasoning to the user mid-task.

---

## Chat Output Discipline

Every response **must** be:
- **Direct** — answer immediately
- **Concise** — 2–3 sentences max; one table/code block if needed
- **Zero narrative** — no "I will now…", "Let me first…", or step descriptions
- **Action only** — show results; hide all work

**Forbidden:**
- Multi-paragraph explanations
- Background context or history lessons
- Mid-task status updates
- Restating the user's question

**Required format:**
```
[Result headline]

| Column A | Column B |
|----------|----------|
| ...      | ...      |

Status: ✓ COMPLETE
```

---

## Token Budget (Hard Limits Per Session)

| Constraint | Limit |
|---|---|
| Max files fully read | 4 |
| Max re-reads of same file | 0 — reuse from context |
| Max tool calls before first edit | 3 |
| Max clarification questions | 1 |
| Full reads > 200 lines | Forbidden — use grep + line range |

---

## Pre-Flight Before Any Tool Call

1. Do I already know this from context / prior read? → **Use it. Don't open a file.**
2. Can grep answer this in 1 call? → **Use grep. Don't read the full file.**
3. Have I already read this file this session? → **Reuse content. Don't re-read.**
4. Is this read necessary, or just cautious? → **If cautious, skip it.**
5. Can I batch multiple questions into one read? → **Combine them.**

---

## Execution Model (3 Phases)

```
PHASE A — DECIDE (0 tool calls)
  Parse input → map every item to file + change → build full change plan

PHASE B — RESOLVE UNKNOWNS (1–3 tool calls)
  grep → read only the targeted lines needed

PHASE C — EXECUTE (1 edit call per file, then validate once)
```

---

## Tool Call Discipline

- **Parallel**: read independent files simultaneously
- **Sequential**: only when result depends on prior call
- **Batching**: all edits to one file in one call
- **Grep-first**: ~5 tokens vs ~400 for full file read

---

## Sub-Agent Prompt Template (max 200 tokens)

```
TASK: {verb} {noun}. {one constraint}.
INPUT: {file} | {field}={old}→{new}
OUTPUT: table only, no narrative
```
