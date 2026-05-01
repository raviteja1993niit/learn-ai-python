# Agent Skills & Context Engineering — A Complete Guide
> *Based on: YouTube Podcast — "How to Use AI Agents Better" featuring Ross Mike, published 2026*
> *Generated: 2026-04-28 | Audience: Intermediate — developers and power users building production agents*

---

## 🧭 What This Guide Covers

Ross Mike — a self-described "skills maxi" — shares a practitioner's framework for getting consistent, high-quality output from AI agents. This guide covers how context windows are built, why most people waste tokens on agent.md files, how to craft skills that actually work, and how to scale from one agent to a multi-agent system without losing productivity. By the end, you will understand why **context engineering beats prompt engineering** and how to build agents that improve themselves over time.

---

## 💡 The Big Picture

The models are good. Exceptionally good. Opus 4.6 and GPT 5.4 are at a point where the model quality is rarely the bottleneck. What separates a productive agent from a frustrating one is **what you put around the model** — the context you give it, the tools you attach, and the skills you teach it through lived experience.

> 💬 *"You have the power to steer the models in a direction where you can get quality or you can get slop. And that's what I really want to talk about."*

Think of it this way: you hired the smartest new employee in the world. They have read every book, every codebase, every contract ever written. But they have never met you, do not know your workflow, and do not know what "a report" means in your business context. The models know everything — except the thing that matters most: **your specific way of working**.

The only way to make them productive is to stop treating them like magic black boxes and start treating them like very capable new employees who need context-specific training.

---

## 📚 Core Concepts

### The Models Are Good — Context Is the Only Variable

The arms race between Opus 4.6 and GPT 5.4 is largely irrelevant for most practical work. Both models are exceptional. The productivity gap between a mediocre agent setup and a high-performing one has almost nothing to do with which model you chose and everything to do with the quality of context you provide.

> 💬 *"Context still matters and you have the power to steer the models in a direction where you can get quality or you can get slop."*

The model's job is to predict the next most-likely token given its context. It does not think. It does not understand. It maps your English onto a vector graph and finds the closest resemblance. This is why vague instructions produce vague results — not because the model is weak, but because the input vector has no strong signal.

**Why this matters:** once you internalise that models are token predictors, not thinkers, you stop blaming the model and start engineering the context.

---

### How Context Windows Are Assembled

Every time an agent runs, it assembles a context window from multiple layers stacked on top of each other:

```
┌─────────────────────────────────────────────┐
│         CONTEXT WINDOW (e.g. 250k tokens)   │
├─────────────────────────────────────────────┤
│ 1. System Prompt      (model provider)      │  ← always present; leaked recently for Claude Code
│ 2. Agent.md / CLAUDE.md  (your rules)       │  ← added EVERY turn if present
│ 3. Skill names + descriptions               │  ← tiny; full content loaded on demand only
│ 4. Tool definitions   (read/write/search)   │  ← required for tool-calling harness
│ 5. Codebase / working files                 │  ← the actual code/data being worked on
│ 6. User conversation  (growing each turn)   │  ← accumulates with every message
└─────────────────────────────────────────────┘
```

At the start of a session this can total around 20,000 tokens. As the conversation grows, you approach the model's limit (around 250,000 tokens), at which point tools like Claude Code and OpenAI Codex trigger automatic compaction.

> 💬 *"This is what the complete context window is filled with, and this can total up to maybe 20,000 tokens at the beginning, and as the conversation continues you might reach your limit."*

**Why this matters:** every decision about what to include in your context setup is a budget decision. Wasteful inclusions leave less room for the actual work.

---

### The Agent.md File: The 95% Trap

Most content about agent.md (or CLAUDE.md) files tells you to fill them with instructions. Ross's counter-intuitive take: **95% of people do not need one at all**.

The reason is simple: these files are injected into context **on every single turn**. A 1,000-line agent.md file at roughly 7,000 tokens means you burn 7,000 tokens before the conversation even begins — and you burn them again and again with every reply.

> 💬 *"If you have a specific currency then you like oh use this currency — that's when you have your agent.mds. But honestly, these are a force. You don't need them."*

The analogy: imagine you brief your colleague before every meeting by reading them a full instruction manual — including that they need a microphone. They already know. You are wasting time.

**The 5% case where you DO need agent.md:**
- Proprietary company information that must be referenced in every single conversation
- Methodologies so specific to your organisation that the model genuinely cannot infer them from the codebase

For almost everything else — including tech stack, coding style, output format — the model either already knows it from the code in context or it belongs in a skill file.

| Scenario | agent.md? | Skill? |
|----------|-----------|--------|
| `This codebase uses React` | ❌ Not needed | ❌ Not needed (it can read the code) |
| `Use TypeScript strict mode` | ❌ Not needed | ❌ Not needed (inferred from tsconfig) |
| `Our internal API auth flow` | ✅ If referenced every turn | ✅ Better as skill |
| `Proprietary reporting format` | ✅ If truly every turn | ✅ Better as skill |
| `Code structure review process` | ❌ Not every turn | ✅ Skill (loaded on demand) |

---

### Skills & Progressive Disclosure

Skills are the core pattern Ross advocates above everything else. A skill file has three components:

```
┌────────────────────────────────────┐
│  SKILL FILE STRUCTURE              │
├────────────────────────────────────┤
│  name:        code-structure       │
│  description: Use when multiple    │
│               workflows duplicate  │
│               the same operational │
│               logic...             │
├────────────────────────────────────┤
│  [detailed instructions: 116 lines]│
│  [full workflow steps]             │
│  [edge cases and examples]         │
└────────────────────────────────────┘
         ↑ only this gets added      ↑ loaded only when
         to context (53 tokens)       agent decides it needs it
```

This is **progressive disclosure**: only the name and description sit in the context window at all times. The full 116-line skill body — worth 944 tokens — is only loaded when the agent recognises it needs that skill.

> 💬 *"What's in the context is the name and the description, but that's enough for the agent to be like, 'Oh, this is a skill I need. Let me go use it.'"*

The contrast with agent.md is stark: 53 tokens versus 944 tokens, and the 944 only appears when actually needed rather than burning on every exchange.

**Why this matters:** skills let you codify every workflow, style guide, and process you have — without the penalty of loading it all at startup. The agent fetches exactly what it needs, exactly when it needs it.

---

### The Fundamental Law: Token Economics

The context window degrades as it fills. This is not a technical limitation to work around — it is a fundamental behavioural property of transformer models.

```
Context window fill level vs. agent quality:

  0%  ─── Fresh start                               │
 10%  ─── System prompt + tool definitions loaded   │  ← OPTIMAL ZONE
 30%  ─── Mid-session, skills loading on demand     │     (fresh → ~70%)
 70%  ─── Approaching degradation threshold         │
 80%  ─── Quality starting to drop                  │  ← WARNING ZONE
 90%  ─── Noticeably degraded                       │  ← AVOID
100%  ─── Compaction triggers (Claude Code/Codex)   │  ← DANGER ZONE
```

> 💬 *"The closer you get to 99, 90, 80% it starts to get dumb. You can think of this like a human — imagine you throw a bunch of information again and again and again."*

The last-minute-cramming analogy: someone who ignored their coursework all year and tries to absorb polynomials, graphs, and notation in one night. The capacity was always there; the context is just overloaded.

**The implication:** every token you waste on unnecessary agent.md content, on tech-stack reminders the model already knows, on boilerplate the codebase already contains — that is a token stolen from the productive portion of your session.

---

## ⚙️ How It Works — Under the Hood

### The Full Context Window Stack in Practice

When you invoke an agent in Claude Code or OpenAI Codex:

1. The **model provider's system prompt** loads first — this is large, fixed, and not under your control (Claude Code's was leaked and studied by developers)
2. Your **agent.md / CLAUDE.md** appends next — if present, every single turn, regardless of relevance
3. **Skill index** loads — just the `name:` and `description:` of every skill file (tiny)
4. **Tool schema** loads — the JSON definitions of every tool the agent harness exposes
5. **Codebase context** loads — files in scope, recently edited files, referenced files
6. **Conversation history** grows — your messages and the agent's replies accumulate

At the beginning of a new session: ~20,000 tokens. After an hour of active coding: potentially 150,000–200,000+ tokens. When you hit the ceiling: compaction happens automatically.

### The Skill Progressive Disclosure Mechanism

When you say "clean up the code structure," the agent:

1. Scans the skill index in its context — finds `name: code-structure`
2. Reads the description: *"use when multiple workflows duplicate the same operational logic..."*
3. Recognises relevance — triggers a tool call to load the full skill file
4. Executes using the 116 lines of detailed instructions
5. Full skill body is now in context — but only for this exchange

Next exchange: if the skill is not needed again, it fades from active context. It was never permanently burning tokens.

---

## 🔧 Practical Usage & Implementation

### How to Build a Skill the Right Way

This is where most people go wrong. The intuitive approach:

```
❌ WRONG APPROACH:
Identify workflow → immediately write skill.md → give to agent
```

The problem: the agent has no context of what a successful run looks like. It will fail at API calls, misformat data, skip validation steps — because the skill is an abstract specification, not a learned pattern.

> 💬 *"A lot of people will identify they have a workflow and then they'll jump to create the skill right away. This is the worst thing you can do."*

```
✅ RIGHT APPROACH:
Identify workflow
    ↓
Teach the agent step-by-step through a LIVE conversation
    ↓
Walk it through the full workflow with real data
    ↓
Correct it when it goes wrong — tell it why
    ↓
Achieve a SUCCESSFUL RUN (the agent completed the task correctly)
    ↓
THEN tell it: "Review what you just did. Create the skill.md file."
    ↓
Agent generates skill WITH the context of what success looks like
```

The sponsor analysis example:

Ross wanted his agent to evaluate incoming sponsor emails. First attempt: just told the agent to "research and evaluate." Every sponsor came back as "legit, legit, legit" — no rejections, no depth.

Why? The model had no context of what *good evaluation* looked like.

The fix: Ross walked through a real email together — *check their Twitter, their YouTube, their Trustpilot, check if they've raised money. If two of these don't exist or aren't in good standing: automatic rejection.* He did this live in conversation. The agent learned. Then he said: "Now create the skill."

> 💬 *"I actually walk with it step by step on doing the workflow. Once I've had that back and forth, then I tell the AI — review what you did and create the skill. Now it has actual context of how it worked."*

**The employee analogy:** you would not hand a new employee a 50-page procedure manual on day one and walk away. You would sit with them, do the work together, correct in real time, and only once they have had a successful run do you say: "Write that up as a standard operating procedure."

---

### The Recursive Skill Improvement Loop

A skill created after one successful run is version 1.0 — functional but imperfect. The real methodology is recursive improvement:

```
                    ┌─────────────────────────────────┐
                    │         SKILL v1.0               │
                    └──────────────┬──────────────────┘
                                   │ agent uses skill
                                   ▼
                    ┌─────────────────────────────────┐
                    │     SKILL FAILS (expected)       │
                    │  API error, wrong format, etc.   │
                    └──────────────┬──────────────────┘
                                   │ DON'T get angry
                                   ▼
                    ┌─────────────────────────────────┐
                    │  ASK: "Why did you fail?"        │
                    │  Agent: "Got a 500 error —       │
                    │  insufficient credits"           │
                    └──────────────┬──────────────────┘
                                   │ identify + fix
                                   ▼
                    ┌─────────────────────────────────┐
                    │  "Fix it. Now UPDATE the skill   │
                    │   so this doesn't happen again"  │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │         SKILL v1.1               │
                    └──────────────┬──────────────────┘
                                   │ repeat 3–5 times
                                   ▼
                    ┌─────────────────────────────────┐
                    │    SKILL v1.N (PRODUCTION)       │
                    │ Executes flawlessly, every time  │
                    └─────────────────────────────────┘
```

Ross's YouTube analytics report skill — pulls from Notion, Dub Analytics, YouTube Analytics, Twitter, and five other data sources — took **five recursive iterations** to reach production quality. It now executes in around 10 minutes, every time, without intervention.

> 💬 *"When it messes up, you thank God. You don't complain. This is the moment where you identify the error. Tell it this is the error. Fix it. Tell it to update the skill file so this doesn't happen again."*

The mindset shift: failures are data. Each failure is an opportunity to make the skill specification more precise. After 3–5 loops, the skill has encoded not just the happy path but the actual failure modes encountered in your specific environment.

---

### Building Up to Sub Agents (the Scaling Ladder)

Ross's rule: **start with one agent, build up skills, only then introduce sub agents**.

```
WEEK 1–2:   One agent, no skills
            Do workflows manually in conversation
            Identify what repeats → candidates for skills

WEEK 2–4:   One agent, growing skill library
            Each skill refined through 2–5 iterations
            Agent becomes reliable at core workflows

MONTH 2+:   Multiple proven workflows → introduce first sub agent
            Sub agent has its own skills + context
            Main agent orchestrates, sub agents specialise

MATURE:     Main agent + 3–5 sub agents (marketing, business, personal...)
            Each sub agent has domain-specific skills
            System scales for PRODUCTIVITY not for how cool it looks
```

> 💬 *"I have one for marketing, one for business, one for personal, and that's it. I'm willing to bet if I went OpenClaw to OpenClaw with anyone, my system is more productive because I didn't scale for what looks cool. I scaled for productivity."*

The company analogy: starting a company by hiring 10 employees on day one when you have never managed anyone. It looks ambitious. It will be chaos. Starting with one person, learning to manage, proving one workflow, then hiring the second — this is how functional companies are built.

---

### On Downloading Other People's Skills

The short answer: don't.

> 💬 *"I don't download skills because your agent needs the context of a successful run, which you then turn into skills."*

A skill built by someone else was trained on their workflow, their data formats, their API credentials, their definition of "success." It does not have the context of a successful run in *your* environment. At best it is a useful reference. At worst it is a security vector.

The correct use of a public skill: read it, learn from it, use it to inspire your own — but build yours through the workflow-first methodology.

---

## ⚠️ Gotchas & Common Mistakes

| Gotcha | Why It Happens | Narrator's Advice |
|--------|----------------|-------------------|
| **Writing skill.md before doing the workflow** | People assume the AI just needs a spec document | Do the workflow live in conversation first; only create the skill after a successful run |
| **Filling agent.md with things the model already knows** | Copying advice from blogs/tutorials | Strip it back; the model knows React, TypeScript, dollar signs — don't waste tokens |
| **Blaming the model when the skill fails** | Expectation that version 1 will be perfect | Failures are the data you need; ask "why did you fail?" and update the skill |
| **Installing skills from marketplaces** | Looks like a shortcut to a complete setup | Built-for-someone-else skills lack your workflow context; also a security risk |
| **Scaling to sub agents before workflows are proven** | Sub agents look impressive | Each sub agent needs working skills; build and prove workflows first |
| **Treating agent.md as a catch-all config** | It's the first file everyone mentions | 95% of content belongs in skills or nowhere; agent.md is for genuinely proprietary always-on context |
| **Not checking why the agent failed** | Frustration → abandon | Ask the agent to explain the error; it will describe it precisely; then feed that back as a fix |
| **Letting context fill above ~70%** | Long sessions, lots of back-and-forth | Start a new session for major new tasks; don't push the context to compaction during critical work |

---

## 🔗 How It Connects to Other Concepts

**Context engineering vs. prompt engineering:** prompt engineering is about *what you say in the moment*; context engineering is about *what the model knows before you say anything*. Skills are the primary instrument of context engineering for recurring workflows.

**Templates are making a comeback:** as code itself becomes the primary context signal for coding agents, a well-structured template codebase is now as valuable as a well-crafted agent.md used to be. The model reads the code, infers the patterns, and builds on top of them — no explicit instruction needed.

**The harness matters as much as the model:** benchmarks showing differences between Cursor, Claude Code, and OpenAI Codex outputs tell you something important. Same underlying model, different harness quality → different output quality. The tools, context assembly, and skill-loading mechanism are now competitive moats.

**Memory layers (OpenClaw, etc.):** persistent memory systems are an extension of the same principle — the more relevant prior context the agent has access to, the more it can align to your specific way of working. But like skills, the memory is most valuable when it was built through actual successful runs in your environment.

---

## 🎯 Key Takeaways

- The models are already excellent — your context quality is the bottleneck, not the model itself
- Agent.md files burn tokens on every turn; 95% of use cases do not need them
- Skills use progressive disclosure — only name+description (53 tokens) sit in context; full body (944 tokens) loads on demand
- Never write a skill before doing the workflow live in conversation — the agent needs the context of a successful run
- Failures are not failures; they are improvement data — identify the error, fix it, update the skill
- Build the recursive improvement loop: workflow → skill v1 → failure → fix → skill v2 → repeat until production-grade
- Scale from one agent upward: prove workflows, then add sub agents that own their domain
- Downloading other people's skills skips the contextual learning that makes a skill actually work in your environment
- Less is more: simple context, minimal agent.md, well-built skills beats any complex multi-agent setup without proven workflows
- The permanent competitive advantage is knowing *your* workflow well enough to codify it — models can predict tokens; only you know your business

---

## 📖 Narrator's Own Words

> *"I'm a skills maxi. People do it wrong and I'm going to share the right way on how to create skills."*

> *"The models are really really good now, but the context matters more than anything."*

> *"You don't download skills. Your agent needs the context of a successful run which you then turn into skills."*

> *"When it messes up, you thank God. You don't complain. This is the moment where you identify the error."*

> *"I didn't scale for what looks cool. I scaled for productivity. That was a bar."*

> *"If you can't explain it in a few sentences, you probably don't really understand it. Less is more, simple is better."*

---

*Guide synthesised from: YouTube Podcast — "How to Use AI Agents Better" featuring Ross Mike | Agent: transcript-guide v1.0.0 | Validated: 2026-04-28*
