# Context Window Tracker — User Guide

**Scripts:**
| Script | Purpose |
|--------|---------|
| `context-window-tracker.ps1` | Measures token cost of **files on disk** before a session |
| `chat-token-tracker.ps1` | Measures token cost of the **live conversation** (files + messages + AI replies) |

**Location:** `C:\Users\e135408\Downloads\personal-work\learn-ai\utilities\`

---

## Two Scripts — When to Use Which

| Situation | Script to use |
|-----------|--------------|
| Before starting a session — how heavy are my source files? | `context-window-tracker.ps1` |
| Mid-session — how much context have I used so far? | `chat-token-tracker.ps1` |
| Deciding which files to attach | `context-window-tracker.ps1 -Files ...` |
| Estimating when to save & start a new session | `chat-token-tracker.ps1 -Turns N` |

---

## Script 1 — `context-window-tracker.ps1` (Files on Disk)

Scans a folder or list of files and estimates their token cost.
Use this **before** opening a chat.

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Path` | string | current dir | Root folder to scan recursively |
| `-Files` | string[] | _(none)_ | Specific files to check |
| `-Limit` | long | `200000` | Model context window size |
| `-Include` | string[] | `*.java,*.md,*.ps1,*.json,*.yaml,*.yml,*.xml,*.txt` | File patterns |
| `-Verbose` | switch | off | Show full file-by-file table |

### Common Commands

```powershell
# Whole project — source files only (recommended for Java projects)
.\context-window-tracker.ps1 `
  -Path "C:\IdeaProjects\...\my-project" `
  -Include "*.java","*.md","*.yaml","*.yml" `
  -Limit 200000 -Verbose

# Check specific files before attaching them
.\context-window-tracker.ps1 -Files `
  "C:\...\AvsScenarios.java","C:\...\CHANGELOG.md"

# For GitHub Copilot (128K limit)
.\context-window-tracker.ps1 -Path "C:\...\my-project" -Limit 128000
```

---

## Script 2 — `chat-token-tracker.ps1` (Live Conversation)

Measures the token cost of your **current running conversation** across 4 sources:

```
[A] System prompt / mode rules   ← fixed overhead (~3–5K tokens)
[B] Attached files               ← files you gave the AI
[C] Your messages                ← everything you typed
[D] AI responses                 ← everything the AI replied
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ChatLog` | string | _(none)_ | Path to exported chat log .txt file |
| `-AttachedFiles` | string[] | _(none)_ | Files attached to the session |
| `-Turns` | int | `0` | Number of message turns (if no chat log) |
| `-AvgUserCharsPerTurn` | int | `300` | Avg chars per user message |
| `-AvgAiCharsPerTurn` | int | `1200` | Avg chars per AI response |
| `-UserMessageChars` | long | `0` | Override: exact user message char count |
| `-AiResponseChars` | long | `0` | Override: exact AI response char count |
| `-SystemPromptTokens` | int | `3000` | Estimated system prompt size |
| `-Limit` | long | `200000` | Model context window size |
| `-Verbose` | switch | off | Show per-file breakdown |

### Usage Modes

#### Mode 1 — Estimate from number of turns (quickest, mid-session check)

```powershell
.\chat-token-tracker.ps1 `
  -AttachedFiles "C:\...\CHANGELOG.md","C:\...\AvsScenarios.java" `
  -Turns 20 `
  -Limit 200000
```

Use this when you've been chatting for a while and want a quick estimate.
Count your message turns (each time you hit send = 1 turn).

#### Mode 2 — Load an exported chat log (most accurate)

```powershell
.\chat-token-tracker.ps1 -ChatLog "C:\temp\my-chat.txt" -Limit 200000
```

**How to export your chat:**
- **JetBrains AI Assistant**: Right-click in chat panel → `Export Conversation` → save as `.txt`
- **GitHub Copilot / Claude**: Select all chat text (Ctrl+A), copy, paste into a `.txt` file

#### Mode 3 — Manual char counts (precise)

```powershell
# Count chars of your messages in PowerShell:
("your entire conversation text pasted here").Length

.\chat-token-tracker.ps1 `
  -AttachedFiles "C:\...\CHANGELOG.md" `
  -UserMessageChars 4500 `
  -AiResponseChars  18000 `
  -SystemPromptTokens 4000
```

---

## Understanding the Output

```
  ╔══════════════════════════════════════════════════╗
  ║       Chat Conversation Token Tracker            ║
  ╚══════════════════════════════════════════════════╝

  Model limit : 200,000 tokens

  ┌─────────────────────────────────────────┬────────────┬──────────┐
  │ Source                                  │   Tokens   │  % Limit │
  ├─────────────────────────────────────────┼────────────┼──────────┤
  │ [A] System prompt / mode rules          │      4,000 │       2% │
  │ [B] Attached files (3 files)            │     28,430 │    14.2% │
  │ [C] Your messages                       │      6,250 │     3.1% │
  │ [D] AI responses                        │     25,000 │    12.5% │
  ├─────────────────────────────────────────┼────────────┼──────────┤
  │ TOTAL                                   │     63,680 │    31.8% │
  └─────────────────────────────────────────┴────────────┴──────────┘

  Remaining capacity : 136,320 tokens

  Usage  [##############------------------------------]

  Risk   : 🟡 MEDIUM — comfortable, continue the session
```

### Risk Ratings

| Rating | Usage | Action |
|--------|-------|--------|
| 🟢 LOW | < 30% | Attach freely, long session ahead |
| 🟡 MEDIUM | 30–60% | Continue normally |
| 🟠 HIGH | 60–80% | Avoid attaching more large files |
| 🔴 CRITICAL | 80–95% | Save CHANGELOG now, plan to start new session |
| 💀 OVER LIMIT | > 95% | Context is being silently truncated |

---

## Recommended Daily Workflow

### Before starting a session
```powershell
# Step 1 — check project file weight
.\context-window-tracker.ps1 `
  -Path "C:\IdeaProjects\...\my-project" `
  -Include "*.java","*.md","*.yaml","*.yml" -Verbose

# Step 2 — check just the files you'll attach
.\context-window-tracker.ps1 -Files "File1.java","CHANGELOG.md"
```

### Mid-session (every ~15–20 turns)
```powershell
# Quick estimate — just count your message turns
.\chat-token-tracker.ps1 `
  -AttachedFiles "C:\...\CHANGELOG.md","C:\...\SomeFile.java" `
  -Turns 18 `
  -Limit 200000
```

### When risk hits 🔴 CRITICAL
1. Tell the AI: *"update CHANGELOG.md with today's progress and pending tasks"*
2. Start a new chat session
3. Attach only `CHANGELOG.md` as the starting context

---

## Token Estimation Accuracy

| File Type | Chars per Token | Accuracy |
|-----------|----------------|----------|
| `.java`, `.ps1`, `.js`, `.ts`, `.py` | 3.5 | ±8% |
| `.xml`, `.yaml`, `.yml` | 3.8 | ±8% |
| `.md`, `.txt`, chat prose | 4.0 | ±10% |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Attaching `target/` build folders | Use `-Include "*.java","*.md"` |
| Attaching `.idea/` IDE files | Always exclude `.idea/` |
| Attaching `3rdpartylicenses.txt` | Never attach build-generated files |
| Not tracking mid-session | Run `chat-token-tracker.ps1` every 15–20 turns |

---

## File Locations

| File | Path |
|------|------|
| File scanner script | `...\utilities\context-window-tracker.ps1` |
| Chat tracker script | `...\utilities\chat-token-tracker.ps1` |
| This guide | `...\utilities\docs\context-window-tracker-guide.md` |
| CSV output | Saved in scanned project as `context-token-report.csv` |


---

## Why This Matters

Every AI model has a **context window limit** — the maximum number of tokens it can hold in a single conversation, including:
- Your messages
- AI responses
- All attached files

| Model | Context Limit |
|-------|--------------|
| GitHub Copilot (GPT-4o) | ~128,000 tokens |
| Claude 3.5 Sonnet | ~200,000 tokens |
| Claude 3 Opus | ~200,000 tokens |
| GPT-4 Turbo | ~128,000 tokens |

When you exceed the limit, the model **silently drops older context** — it forgets earlier files, decisions, and code you showed it. This causes wrong answers, repeated fixes, and wasted time.

**Rule of thumb:** Keep attached files under **40–50% of the limit** to leave room for the conversation itself.

---

## Quick Start

Open PowerShell and run:

```powershell
cd "C:\Users\e135408\Downloads\personal-work\learn-ai\utilities"

.\context-window-tracker.ps1 -Path "C:\path\to\your\project"
```

That's it. You'll see a usage bar, risk rating, and a CSV report.

---

## All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Path` | string | current dir | Root folder to scan recursively |
| `-Files` | string[] | _(none)_ | Specific files to check instead of scanning a folder |
| `-Limit` | long | `200000` | Model context window size in tokens |
| `-Include` | string[] | `*.java,*.md,*.ps1,*.json,*.yaml,*.yml,*.xml,*.txt` | File patterns to include |
| `-Verbose` | switch | off | Show full file-by-file table |

---

## Usage Scenarios

### Scenario 1 — Check a whole project before a session

```powershell
.\context-window-tracker.ps1 -Path "C:\...\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test"
```

Scans all matching source files in the project recursively and shows total token estimate.

---

### Scenario 2 — Check only source files (exclude `target/` and `.idea/`)

Build artefacts and IDE state files inflate the count with useless tokens. Exclude them:

```powershell
.\context-window-tracker.ps1 `
  -Path "C:\...\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test" `
  -Include "*.java","*.md","*.yaml","*.yml"
```

This is the **recommended command for Java projects** — focuses on code and docs only.

---

### Scenario 3 — Check specific files you plan to attach

Before attaching files to a chat:

```powershell
.\context-window-tracker.ps1 -Files `
  "C:\...\AvsScenarios.java", `
  "C:\...\ElavonAvsTransactions.java", `
  "C:\...\CHANGELOG.md", `
  "C:\...\TestConstants.java"
```

You get the exact token cost of just those 4 files before attaching them.

---

### Scenario 4 — Set model limit for GitHub Copilot (128K)

```powershell
.\context-window-tracker.ps1 `
  -Path "C:\...\my-project" `
  -Include "*.java","*.md" `
  -Limit 128000
```

---

### Scenario 5 — Full verbose table + CSV report

```powershell
.\context-window-tracker.ps1 `
  -Path "C:\...\my-project" `
  -Include "*.java","*.md","*.yaml" `
  -Verbose
```

Shows every file sorted by token count (heaviest first) and saves `context-token-report.csv` in the scanned folder.

---

## Understanding the Output

```
  Context Window Tracker
  Model limit : 200,000 tokens
  Scanned     : 42 files

  Total estimated tokens : 87,450  (43.7% of limit)
  Remaining              : 112,550

  Usage  [#################-----------------------]

  Risk   : 🟡 MEDIUM — comfortable but plan ahead

  Top 5 heaviest files:
      9,790 tokens  (  4.9%)  .\constant\TestConstants.java
      8,815 tokens  (  4.4%)  .\model\ElavonWalletTransactions.java
      6,881 tokens  (  3.4%)  .\CHANGELOG.md
      6,654 tokens  (  3.3%)  .\config\BaseElavon.java
      5,961 tokens  (  3.0%)  .\constant\Fields.java

  Report saved: C:\...\context-token-report.csv
```

### Risk Ratings

| Colour | Usage | Meaning | Action |
|--------|-------|---------|--------|
| 🟢 LOW | < 30% | Plenty of room | Attach freely |
| 🟡 MEDIUM | 30–60% | Comfortable | Be selective about what you add |
| 🟠 HIGH | 60–80% | Getting tight | Attach only essential files |
| 🔴 CRITICAL | 80–95% | Near limit | Start session with minimal files; use CHANGELOG summary instead |
| 💀 OVER LIMIT | > 95% | Will be truncated | Do NOT attach all files — pick top-priority ones only |

---

## Recommended Workflow Before Every AI Session

Follow these 4 steps before opening a new chat:

### Step 1 — Run the tracker on source files only

```powershell
cd "C:\Users\e135408\Downloads\personal-work\learn-ai\utilities"

.\context-window-tracker.ps1 `
  -Path "C:\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test" `
  -Include "*.java","*.md","*.yaml","*.yml" `
  -Limit 200000 `
  -Verbose
```

### Step 2 — Review the top heaviest files

From the `-Verbose` table, identify files that cost the most tokens but are **not needed** for the session's goal.

Example: If you're fixing AVS scenarios today, you don't need:
- `ElavonWalletTransactions.java` (8,815 tokens)
- `ElavonCredentialOnFileTransactions.java` (5,324 tokens)

### Step 3 — Check only the files you'll actually attach

```powershell
.\context-window-tracker.ps1 -Files `
  "C:\...\AvsScenarios.java", `
  "C:\...\ElavonAvsTransactions.java", `
  "C:\...\CHANGELOG.md"
```

Aim for **under 80,000 tokens** for attached files (leaves 120K for conversation).

### Step 4 — Open the AI session with context-lean attachments

If the total is still too high:
- Attach **CHANGELOG.md** instead of all source files — it has the full context in condensed form
- Ask the AI to `read_file` specific files on demand rather than pre-attaching everything

---

## Token Estimation Accuracy

The script uses character-count-based estimates, which are accurate within ±10%:

| File Type | Chars per Token | Accuracy |
|-----------|----------------|----------|
| `.java`, `.ps1`, `.js`, `.ts`, `.py` | 3.5 | ±8% |
| `.xml`, `.yaml`, `.yml` | 3.8 | ±8% |
| `.md`, `.txt`, prose | 4.0 | ±10% |

For exact counts, tools like [tiktoken](https://github.com/openai/tiktoken) (Python) can be used,
but the character-based estimate is sufficient for planning purposes.

---

## Common Mistakes to Avoid

| Mistake | Impact | Fix |
|---------|--------|-----|
| Attaching `target/` build folders | Wastes 20K+ tokens on bytecode/reports | Exclude with `-Include "*.java","*.md"` |
| Attaching `.idea/` IDE files | Wastes 5K–10K tokens on XML state | Always exclude `.idea/` |
| Attaching `3rdpartylicenses.txt` | Single file = 28K tokens | Never attach build-generated licence files |
| Attaching the entire project at once | May exceed limit before conversation starts | Use `-Files` to cherry-pick |
| Forgetting to account for conversation tokens | Conversation itself uses ~20–40K tokens | Budget 50K tokens for chat; keep files under 150K |

---

## Quick Reference Card

```powershell
# ── FULL PROJECT SCAN (source only) ──────────────────────────
.\context-window-tracker.ps1 `
  -Path "C:\<project>" `
  -Include "*.java","*.md","*.yaml","*.yml" `
  -Limit 200000

# ── SPECIFIC FILES CHECK ──────────────────────────────────────
.\context-window-tracker.ps1 -Files "File1.java","File2.md","CHANGELOG.md"

# ── VERBOSE TABLE + CSV EXPORT ───────────────────────────────
.\context-window-tracker.ps1 -Path "C:\<project>" -Include "*.java","*.md" -Verbose

# ── GITHUB COPILOT LIMIT ─────────────────────────────────────
.\context-window-tracker.ps1 -Path "C:\<project>" -Include "*.java","*.md" -Limit 128000
```

---

## File Locations

| File | Path |
|------|------|
| Script | `C:\Users\e135408\Downloads\personal-work\learn-ai\utilities\context-window-tracker.ps1` |
| This guide | `C:\Users\e135408\Downloads\personal-work\learn-ai\utilities\docs\context-window-tracker-guide.md` |
| CSV output | Saved inside the scanned project folder as `context-token-report.csv` |

