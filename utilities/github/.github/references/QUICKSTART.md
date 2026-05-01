# 🚀 Quick Start: Generate Your First Agent

> Generate a production-ready GitHub Copilot agent in 15 minutes using the Meta-Agent.

---

## ⚡ 3-Step Process

### Step 1: Initiate Interview
```bash
@meta-agent generate
```

### Step 2: Answer 4-Phase Questions

**Phase 1: Discovery (PLAN)**
- What's the core problem?
- Who uses this agent?
- What domain/tools?

**Phase 2: Capabilities (DO)**
- Top 3-5 capabilities?
- What tools needed?
- What data formats?

**Phase 3: Constraints (CHECK)**
- Security boundaries?
- Performance requirements?
- Data sensitivity?

**Phase 4: Behavior (ACT)**
- Step-by-step workflow?
- Edge cases?
- Real example?

### Step 3: Deploy Agent
Meta-Agent generates your `agent-name.md` in `.github/agents/`

---

## 📋 Generated Agent Structure

Every agent includes:
```
# Agent Name           (clear title)
Mission               (1 sentence)
Identity             (role, domain, version, mode)
Capabilities         (3-5 with triggers)
Workflows            (1-3 numbered step lists)
Constraints          (MUST/MUST NOT)
Example              (real scenario)
Invocation           (@agent-name command)
```

**Token Budget:** Minimal, focused, no redundancy.

---

## ✅ Quality Gates (Auto-Checked)

- ✅ Clear 2-3 sentence mission
- ✅ 3-5 capabilities with triggers
- ✅ All tool dependencies listed
- ✅ 1-3 workflow with numbered steps
- ✅ MUST/MUST NOT constraints
- ✅ At least 1 real example
- ✅ Invocation pattern defined
- ✅ No redundancy

---

## 📂 Output Location

Generated agent file: `.github/agents/[agent-name].md`

Registered in: `.github/agents/AGENT_REGISTRY.md`

---

## 🎯 Common Examples

### Example 1: Code Review Agent
```
Mission: Reviews code changes autonomously against project standards
Capabilities: Static analysis, compliance check, performance audit
Tools: Git, Linter, Code Parser
Workflows: Fetch commit → Analyze → Report
```

### Example 2: Documentation Agent
```
Mission: Generates docs from code comments and patterns
Capabilities: Parse code, extract docs, format markdown
Tools: Parser, Markdown, Template Engine
Workflows: Read source → Extract → Generate → Validate
```

---

## 🔄 Interview Tips

- **Be specific:** "API validation" not "validation"
- **Provide examples:** Share actual payloads or scenarios
- **List constraints early:** Security, compliance, limits
- **Keep focused:** 3-5 capabilities max per agent
- **Define workflows:** Step-by-step, numbered lists only

---

## ❓ FAQ

**Q: How long does generation take?**  
A: ~15 minutes for the interview, instant file generation.

**Q: Can I refine the agent later?**  
A: Yes, use `@meta-agent refine [agent-name]`

**Q: Do I need a template?**  
A: No, Meta-Agent guides you through the interview.

**Q: Can agents coordinate?**  
A: Yes, document coordination in workflows & constraints.

**Q: What if I'm missing info?**  
A: Meta-Agent will ask clarifying questions.

---

## 🎓 Next Steps

1. Generate first agent: `@meta-agent generate`
2. Review generated `.md` file
3. Test invocation pattern: `@[agent-name] [command]`
4. Iterate using: `@meta-agent refine [agent-name]`
5. Check registry: `.github/agents/AGENT_REGISTRY.md`

---

*Ready to build? Start with: `@meta-agent generate`*

