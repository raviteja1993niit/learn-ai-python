# Universal Agent Features v3.0

## Structure (6 Files)
```
[agent]/
├── README.md              # Quick Start + Guide
├── [handle].chatmode.md   # Copilot
├── agent-config.yaml      # Config
├── run-agent.[ext]        # Script (.ps1/.sh/.py)
├── knowledge-base/data.md # KB
└── examples/usage.md      # Examples
```

## Script Selection
| Use Case | Extension |
|----------|-----------|
| Windows | .ps1 |
| Cross-platform | .sh |
| Data/Complex | .py |

## Templates

### README.md
```markdown
# [Name]
> [Purpose]

## Quick Start
@[handle] [command]

## Usage
1. [Step]
2. [Step]

## Config
Edit `agent-config.yaml`
```

### agent-config.yaml
```yaml
agent:
  name: "[Name]"
  version: "1.0.0"
  domain: "[Domain]"
features:
  self_learning: true
  version_tracking: true
```

### data.md
```markdown
# KB
## Patterns
| ID | Pattern | Used |
## History
| Date | Action | Status |
## Changes
### [ID]-[DATE]-001
Before: [code]
After: [code]
```

## Token Targets
| File | Max |
|------|-----|
| README | 2KB |
| chatmode | 3KB |
| config | 1KB |
| script | 2KB |
| data | 1KB |
| usage | 1KB |
| **Total** | **10KB** |

## Never Generate
- AGENT_OVERVIEW.md
- CHATBOT_INSTRUCTIONS.md
- step-by-step-guide.md
- quality-standards.md
- coding-standards.md
- Separate KB files

---
*v3.0.0*
