# Transcript Guide — Instructions & Formatting Standards

> These instructions apply when the `transcript-guide` agent generates learning guides.
> They enforce white-paper quality structure, folder conventions, and script usage.

---

## 1. Folder Conventions

| Folder | Purpose |
|--------|---------|
| `materials/input/` | Drop transcript files here before running the agent |
| `materials/transcripts/` | Default transcript location (`transcript.txt`) |
| `materials/output/chunks/` | JSON chunk files produced by `transcript-chunker.ps1` |
| `materials/output/logs/` | Processing run logs |
| `materials/output/` | Analysis JSON and validation reports |
| `claude/Materials/` | Final published guides |

**Rule:** The agent reads from `materials/input/` or `materials/transcripts/transcript.txt`.  
It always writes final guides to `claude/Materials/<topic-slug>-guide.md`.

---

## 2. Script Usage (Run Before Processing)

Always run the PowerShell scripts in order before the agent processes:

```powershell
# Step 1 — Analyse narrator style and build topic map
.\.github\tools\powershell-scripts\transcript-analyzer.ps1 -TopicSlug "my-topic"

# Step 2 — Split transcript into 5-sentence chunks
.\.github\tools\powershell-scripts\transcript-chunker.ps1 -TopicSlug "my-topic"

# Step 3 — (After guide is generated) Validate output
.\.github\tools\powershell-scripts\guide-validator.ps1 -GuidePath "claude/Materials/my-topic-guide.md" -TopicSlug "my-topic"
```

The scripts output to:
- `materials/output/<topic>_analysis.json` → consumed by agent in Step 1
- `materials/output/chunks/<topic>_chunks.json` → consumed by agent in Step 3
- `materials/output/<topic>_validation.json` → final review report

---

## 3. White-Paper Document Structure Rules

Every guide generated MUST follow this white-paper structure. No exceptions.

### 3.1 Title Block

```markdown
# <Topic Name> — A Complete Guide
> *Based on: <Source — e.g. "YouTube: 'Title' by Author">*
> *Generated: <YYYY-MM-DD> | Audience: <Beginner / Intermediate / Advanced>*

---
```

### 3.2 Mandatory Section Hierarchy

Use **exactly** this section order and heading levels:

```
H1  — Document Title (exactly ONE per document)
H2  — Major sections (🧭 💡 📚 ⚙️ 🔧 ⚠️ 🔗 🎯 📖)
H3  — Sub-sections within a major section (individual concepts)
H4  — Deep-dive details within a sub-section (optional)
```

**Never skip heading levels.** H4 must be inside H3, H3 must be inside H2.

### 3.3 Required Major Sections (H2)

| Emoji | Section | Purpose |
|-------|---------|---------|
| 🧭 | `## What This Guide Covers` | 2–3 sentence scope statement |
| 💡 | `## The Big Picture` | Narrator's opening mental model / core analogy |
| 📚 | `## Core Concepts` | All key concepts — each as its own H3 |
| ⚙️ | `## How It Works — Under the Hood` | Internal mechanics, architecture diagrams |
| 🔧 | `## Practical Usage & Implementation` | Step-by-step labs, code, configuration |
| ⚠️ | `## Gotchas & Common Mistakes` | Warning table — mandatory table format |
| 🔗 | `## How It Connects to Other Concepts` | Dependency/relationship map |
| 🎯 | `## Key Takeaways` | Bullet list, narrator's voice |
| 📖 | `## Narrator's Own Words` | 3–5 blockquote verbatim quotes |

### 3.4 Concept Block Template (under H3)

Every core concept section must follow this pattern:

```markdown
### <Concept Name>

<Opening paragraph: narrator's explanation in their own voice.>

> 💬 *"<Direct quote or close paraphrase from the narrator>"*

<Elaboration paragraph or bullet list.>

```<language>
<code snippet exactly as narrator showed — never rewritten>
```

**Why this matters:**
<1–2 sentences in the narrator's tone explaining significance.>
```

### 3.5 Gotchas Table Format

```markdown
## ⚠️ Gotchas & Common Mistakes

| Gotcha | Why It Happens | Narrator's Advice |
|--------|---------------|-------------------|
| **Issue name** | Clear cause | Specific fix or alternative |
```

### 3.6 Section Separators

Place `---` (horizontal rule) between every H2 section. Never between H3 sub-sections.

### 3.7 Document Footer

Every guide must end with:

```markdown
---

*Guide synthesised from: <source> | Agent: transcript-guide v1.0.0 | Validated: <date>*
```

---

## 4. Typography & Formatting Rules

| Element | Rule |
|---------|------|
| **Bold** | Key terms on first use, important warnings |
| *Italic* | Narrator quotes within prose (not blockquotes) |
| `code` | Tool names, file paths, API names, technical identifiers |
| `> 💬 *"..."*` | Narrator's direct quote (blockquote + speech bubble) |
| `> *"..."*` | Narrator's quote in the 📖 section |
| Tables | Use for comparisons, gotchas, component lists — minimum 3 rows |
| Code blocks | Always specify language tag (```python, ```powershell, ```json) |
| Bullet lists | 3–7 items max per list before breaking into sub-sections |

---

## 5. Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Guide file | `<topic-slug>-guide.md` | `ai-agents-guide.md` |
| Chunk JSON | `<topic-slug>_chunks.json` | `ai-agents_chunks.json` |
| Analysis JSON | `<topic-slug>_analysis.json` | `ai-agents_analysis.json` |
| Validation report | `<topic-slug>_validation.json` | `ai-agents_validation.json` |
| Topic slug | kebab-case, lowercase | `spring-security`, `event-driven-arch` |

---

## 6. Quality Gates

A guide is only considered complete when `guide-validator.ps1` reports `PASS` for all three checks:

- ✅ **Completeness** — all 9 required sections present, no `[To be filled]` placeholders
- ✅ **Voice** — ≥3 inline narrator quotes (`> 💬`), narrator quotes section populated
- ✅ **Formatting** — exactly 1 H1, ≥7 H2, correct title pattern, source citation, footer present

Run the validator before committing any guide to `claude/Materials/`.
