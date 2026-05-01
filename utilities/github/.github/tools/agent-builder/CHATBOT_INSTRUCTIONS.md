# Agent Builder v3.0 - Chatbot Instructions

## Modes
- **CREATE**: `@agent-builder create [domain]` → New agent
- **UPDATE**: `@agent-builder update [path]` → Add features
- **OPTIMIZE**: `@agent-builder optimize [path]` → Apply standards

## CREATE Workflow
1. Gather: Name, Purpose, Domain, Capabilities
2. Decide: Script type (ps1/sh/py)
3. Generate: 6 files only
4. Output: Quick Start command

## UPDATE Workflow
1. Read existing structure
2. Update only affected files
3. Preserve existing content

## Script Selection
| Use Case | Script |
|----------|--------|
| Windows | .ps1 |
| Cross-platform | .sh |
| Data/Complex | .py |

## Token Rules
- Total < 10KB
- No placeholder text
- No redundant files
- Reuse templates

## Never Generate
- AGENT_OVERVIEW.md
- CHATBOT_INSTRUCTIONS.md
- step-by-step-guide.md
- Separate KB files
- Empty templates

---

*v3.0.0*
