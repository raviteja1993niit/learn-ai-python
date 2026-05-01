---
name: transcript-processing
description: >-
  Skill for processing transcripts into white-paper quality learning guides.
  Provides the core pipeline: analyse narrator style → chunk transcript →
  incrementally build guide → validate output.
  Used by the transcript-guide agent.
user-invocable: false
---

# Transcript Processing Skill

This skill encapsulates the full transcript-to-guide pipeline used by `transcript-guide`.

---

## Pipeline Overview

```
[Transcript File]
      │
      ▼
transcript-analyzer.ps1  ─────► narrator style fingerprint + topic map
      │                          materials/output/<slug>_analysis.json
      ▼
transcript-chunker.ps1   ─────► 5-sentence JSON chunks
      │                          materials/output/chunks/<slug>_chunks.json
      ▼
[Agent: 5-line chunk loop]
      │  READ → ASSESS → CLASSIFY → EXTRACT → WRITE → LOG
      │  Incremental edits to working guide file
      ▼
claude/Materials/<slug>-guide.md   (working draft)
      │
      ▼
guide-validator.ps1      ─────► completeness / voice / formatting report
      │                          materials/output/<slug>_validation.json
      ▼
claude/Materials/<slug>-guide.md   (final, validated)
```

---

## Script Reference

### `transcript-analyzer.ps1`

**Purpose:** Extracts the narrator's style fingerprint and builds a topic map.

**Input:** `materials/transcripts/transcript.txt` (or custom path via `-TranscriptPath`)

**Output:** `materials/output/<slug>_analysis.json`

```powershell
# Basic usage (reads default transcript.txt)
.\.github\tools\powershell-scripts\transcript-analyzer.ps1 -TopicSlug "ai-agents"

# Custom transcript file
.\.github\tools\powershell-scripts\transcript-analyzer.ps1 `
  -TopicSlug "spring-security" `
  -TranscriptPath "materials/input/spring-security.txt"
```

**Output schema:**
```json
{
  "topicSlug": "ai-agents",
  "analysedAt": "2025-01-15T10:30:00",
  "styleFingerprint": {
    "analogyDomain": "restaurants / factories / post offices",
    "explanationRhythm": "concept → example → gotcha",
    "vocabularyRegister": "casual practitioner",
    "structuralCues": ["now the interesting part", "here's the thing"],
    "complexityLayering": "overview → drill-down",
    "caveatStyle": "now this only works when..."
  },
  "topicMap": ["LLMs", "Context Windows", "Tokens", "Embeddings", "RAG"],
  "totalSentences": 580,
  "estimatedChunks": 116
}
```

---

### `transcript-chunker.ps1`

**Purpose:** Splits transcript into 5-sentence JSON chunks for agent consumption.

**Input:** `materials/transcripts/transcript.txt` (or custom path)

**Output:** `materials/output/chunks/<slug>_chunks.json`

```powershell
# Basic usage
.\.github\tools\powershell-scripts\transcript-chunker.ps1 -TopicSlug "ai-agents"

# Custom transcript, custom chunk size
.\.github\tools\powershell-scripts\transcript-chunker.ps1 `
  -TopicSlug "spring-security" `
  -TranscriptPath "materials/input/spring.txt" `
  -ChunkSize 5
```

**Output schema:**
```json
[
  {
    "chunkIndex": 1,
    "startLine": 1,
    "endLine": 5,
    "sentences": [
      "First sentence of chunk.",
      "Second sentence.",
      "Third sentence.",
      "Fourth sentence.",
      "Fifth sentence."
    ],
    "rawText": "First sentence. Second sentence. ..."
  }
]
```

---

### `guide-validator.ps1`

**Purpose:** Validates a generated guide against white-paper quality rules.

**Input:** Path to guide file + topic slug

**Output:** `materials/output/<slug>_validation.json` + exit code (0 = PASS, 1 = FAIL)

```powershell
# Validate a generated guide
.\.github\tools\powershell-scripts\guide-validator.ps1 `
  -GuidePath "claude/Materials/ai-agents-guide.md" `
  -TopicSlug "ai-agents"
```

**Checks performed:**
| Check | Rule |
|-------|------|
| H1 count | Exactly 1 H1 heading |
| H2 count | Minimum 7 H2 sections |
| Title format | Must match `# <Topic> — A Complete Guide` |
| Source citation | Must contain `> *Based on:` |
| Footer | Must contain `Guide synthesised from:` |
| Placeholders | Zero `[To be filled]` or `<placeholder>` remaining |
| Narrator quotes | Minimum 3 `> 💬` inline quotes |
| Narrator section | `📖` section must be non-empty |

**Output schema:**
```json
{
  "guidePath": "claude/Materials/ai-agents-guide.md",
  "validatedAt": "2025-01-15T12:00:00",
  "passed": true,
  "checks": {
    "completeness": { "passed": true, "details": "All 9 sections present" },
    "voice": { "passed": true, "details": "4 narrator quotes found" },
    "formatting": { "passed": true, "details": "1 H1, 9 H2, correct title" }
  }
}
```

---

## Input / Output Folder Conventions

| Folder | What Goes Here |
|--------|---------------|
| `materials/input/` | Transcript files dropped by the user before processing |
| `materials/transcripts/` | Default transcript location (`transcript.txt`) |
| `materials/output/chunks/` | JSON chunk files from `transcript-chunker.ps1` |
| `materials/output/logs/` | Per-run processing logs |
| `materials/output/` | Analysis + validation JSON reports |
| `claude/Materials/` | Final published guides (validator-approved only) |

---

## Naming Conventions

| Artifact | Pattern | Example |
|----------|---------|---------|
| Guide file | `<topic-slug>-guide.md` | `ai-agents-guide.md` |
| Chunks JSON | `<topic-slug>_chunks.json` | `ai-agents_chunks.json` |
| Analysis JSON | `<topic-slug>_analysis.json` | `ai-agents_analysis.json` |
| Validation JSON | `<topic-slug>_validation.json` | `ai-agents_validation.json` |
| Topic slug | `kebab-case-lowercase` | `spring-security`, `event-driven-arch` |

---

## Quality Gates

A guide is **only complete** when `guide-validator.ps1` reports `PASS` on all three checks:

- ✅ **Completeness** — all 9 required sections present, no placeholder text
- ✅ **Voice** — ≥3 narrator quotes, 📖 section populated
- ✅ **Formatting** — exactly 1 H1, ≥7 H2, correct title + source citation + footer

Do not commit any guide to `claude/Materials/` without a passing validation report.
