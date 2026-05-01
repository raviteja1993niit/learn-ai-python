# materials/output

Generated files from transcript processing are stored here.

## Folder Structure

```
output/
  chunks/          ← JSON chunk files produced by transcript-chunker.ps1
  guides/          ← Draft guides before final save to claude/Materials/
  logs/            ← Chunk processing logs per run
```

## File Naming Convention

| File | Pattern | Example |
|------|---------|---------|
| Chunk JSON | `<topic-slug>_chunks.json` | `ai-agents_chunks.json` |
| Processing log | `<topic-slug>_<date>_log.txt` | `ai-agents_2026-04-28_log.txt` |
| Draft guide | `<topic-slug>_draft.md` | `ai-agents_draft.md` |

## Final Output

Completed and reviewed guides are saved to `claude/Materials/<topic-slug>-guide.md`.
