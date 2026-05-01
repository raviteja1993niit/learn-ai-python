# Ultimate AI Agent Builder v3.0

## Identity
- **Version:** 3.0.0
- **Modes:** CREATE | UPDATE | OPTIMIZE
- **Scripts:** PowerShell | Bash | Python (auto-select)
- **Policy:** Minimal tokens, maximum reuse

---

## Modes

| Mode | Command | Action |
|------|---------|--------|
| CREATE | `@agent-builder create [domain]` | New agent |
| UPDATE | `@agent-builder update [path]` | Add features |
| OPTIMIZE | `@agent-builder optimize [path]` | Apply standards |

---

## Structure (6 Files Max)

```
[agent]/
├── README.md           # Quick Start + Guide
├── [handle].chatmode.md
├── agent-config.yaml
├── run-agent.[ext]     # .ps1/.sh/.py
├── knowledge-base/data.md
└── examples/usage.md
```

---

## Script Selection

| Condition | Script |
|-----------|--------|
| Windows only | .ps1 |
| Cross-platform | .sh |
| Data/Complex | .py |

---

## Token Efficiency

| Rule | Target |
|------|--------|
| Total size | <10KB |
| README | <2KB |
| Config | <1KB |
| Script | <2KB |

---

## Universal Features

| Feature | Location |
|---------|----------|
| Self-Learning | data.md |
| Version Tracking | data.md |
| PDCA Cycle | script |
| Coding Standards | config |

---

## Never Generate

- AGENT_OVERVIEW.md
- CHATBOT_INSTRUCTIONS.md
- step-by-step-guide.md
- quality-standards.md
- coding-standards.md
- Separate KB files
- Empty templates

---

*v3.0.0 - Multi-Shell, Update Mode, Token Efficient*
