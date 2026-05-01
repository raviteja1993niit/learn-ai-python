# 📚 Internal Documentation

This folder contains the internal system documentation for administrators and developers.

## For Administrators/Developers

### System Documentation
- **[system-documentation.md](system-documentation.md)** - Complete system overview, all agents, detailed usage

### Agent System
- **[agents/MASTER_INDEX.md](agents/MASTER_INDEX.md)** - Master documentation for all operational agents
- **[agents/AGENT_REGISTRY.md](agents/AGENT_REGISTRY.md)** - Full registry of all agents with metadata
- **[tools/](tools/)** - Tool builders and meta-tools

### Operational Agents
- **[agents/code-analysis-docs/](agents/code-analysis-docs/)** - PR Documentation Generator
- **[agents/architecture-diagrams/](agents/architecture-diagrams/)** - Architecture Diagram Creator

### SDLC Pipeline Agents
Core pipeline agents (task-discovery → planning → code-development → code-review → code-push → build-fix → merge-closure) are in `agents/`. Invoke via `@<agent-name>` in Copilot Chat.

### Tool Builders
- **[tools/agent-builder/](tools/agent-builder/)** - Creates new agents on demand

---

**Note:** This is an internal AI utilities repository for the Mastercard PGS Elavon S2A modernization project.

