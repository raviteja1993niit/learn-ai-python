# AI Terminology for Engineers — A Complete Guide
> *Based on: YouTube — "Commonly Used Terms in the AI Space" by GKCS*
> *Generated: 2026-04-28 | Audience: Software engineers building AI-powered applications*

---

## 🧭 What This Guide Covers

GKCS walks through 20 essential AI terms that every engineer building AI applications needs to understand — not just to implement them, but to communicate clearly with teammates and external collaborators. This guide follows the narrator's deliberate progression: the terms are presented in an order where each one builds on the one before it, so that by the end you have a connected mental model, not a disconnected glossary.

> 💬 *"If you know these terms, then it is also easier to learn the deeper subjects around AI. You'll have a list of terms whose definitions you understand quite well."*

---

## 💡 The Big Picture

Large language models — and the ecosystem around them — can look dauntingly complex from the outside. But the narrator's central insight is that every AI term in common use today traces back to one simple problem: **how do you make a machine understand and generate human language?**

Every term in this guide is either a solution to a piece of that problem, or a way of making that solution cheaper, faster, or more capable. Once you see each term through that lens, the entire ecosystem becomes coherent.

> 💬 *"The core problem for the large language model is to truly understand human language so that it can speak it really well."*

The narrator uses a single running example throughout the foundational concepts: the phrase **"all that glitters is not gold"**. When fed to an LLM, it is tokenised, converted to vectors, and its contextual meaning is resolved through attention — demonstrating all three foundational mechanisms with one concrete phrase.

---

## 📚 Core Concepts — How LLMs Process Language

These four terms describe what happens every time you send a query to a language model.

### 1. Large Language Model (LLM)

A **large language model** is a neural network trained to predict the next token of an input sequence.

Send in *"all that glitters"* and the model predicts *"is"*, then *"not"*, then *"gold"* — token by token — until it reaches a stop condition and returns the full response.

> 💬 *"A large language model is something which predicts the next token given an input sequence."*

**Why this matters:** every downstream term — tokenization, attention, fine-tuning, RAG — is either a component of this system or a way of making it better at this one task.

---

### 2. Tokenization

Before the LLM can process any text, it must break the input into **tokens** — the smallest discrete units from which meaning can be derived.

*"All that glitters"* becomes: `all` · ` ` · `that` · ` ` · `glitters`. But why not just split on spaces? Because human language is built on meaningful sub-word patterns:

| Suffix | Meaning Encoded | Examples |
|--------|----------------|---------|
| `-ers` | agent performing an action | glitters, shimmers, murmurs, flickers |
| `-ing` | ongoing action | eating, dancing, singing |
| `-tion` | the result of an action | tokenization, vectorization |

> 💬 *"Tokenization is an essential part of truly understanding human language. Its end result is that the input text is broken into tokens."*

A model that understands `-ers` as a suffix pattern does not need to have seen every possible verb form during training — it can generalise from the pattern.

---

### 3. Vectorization

Tokens tell you *what* to focus on. **Vectors** tell you *what it means*.

A vector is a coordinate in an n-dimensional space. The LLM maps every word into this space such that words with similar meanings end up close together, and opposite-meaning words end up far apart.

```
n-dimensional vector space (conceptual):
                        ┌─ king ─── queen
  similar meaning ──▶   │   │         │
  close in space         monarch    royalty
                        │   
              ──▶  dog ─── cat ─── pet
              
              ──▶  hot ─────────── cold  ◀── opposite meaning, far apart
```

> 💬 *"Vectors can encapsulate semantic meaning, which means documents which store similar words are going to be similar or close in distance."*

Once the LLM has vectorised its vocabulary, it knows the inherent meaning of every word in the English language — represented as a coordinate. It can now construct sentences by navigating this space.

---

### 4. Attention

Vectors give a word its base meaning. But what about the word **apple**?

| Phrase | Meaning of "apple" |
|--------|-------------------|
| *"a tasty apple"* | the fruit |
| *"Apple's revenue"* | the company |
| *"apple of my eye"* | a beloved person |

The spelling is identical. The meaning is entirely different. This is the problem that **attention** solves — and it is the breakthrough that made LLMs the dominant AI paradigm.

The attention mechanism looks at the nearby contextual words and performs an operation (not simple addition, but a learned weighted combination) that *pushes* the ambiguous word's vector towards its contextually correct meaning:

```
vector(apple) + attention(revenue)  →  pushes apple towards: Google, Microsoft, Meta
vector(apple) + attention(tasty)    →  pushes apple towards: banana, guava, chiku
```

> 💬 *"The moment I said tasty, you know that it's some sort of food that is going to be talked about. That's how humans derive meaning, and large language models can derive meaning this way."*

The attention paper was published in 2017. GPT-2 in 2022 showed the world what this mechanism was capable of at scale — and the quality of responses exceeded anything previously seen.

---

## 🏗️ Core Concepts — How LLMs Are Built

These three terms describe how models are created and adapted for specific purposes.

### 5. Self-Supervised Learning

To predict the next token reliably, the model must be trained. The question is: trained on what, labelled by whom?

**Supervised learning** would require humans to label every training example: *"given this input, the correct next word is this."* That is impossibly expensive at scale.

**Self-supervised learning** is the architectural breakthrough that made scale possible. The structure of the input data itself generates the training tasks — no humans required.

Take any sentence: *"Et tu, Brutus?"*

The model is given three simultaneous puzzles:
1. What comes after *"Et"*? → `tu`
2. What comes after *"Et tu"*? → `Brutus`
3. What comes after *"Et tu, Brutus"*? → `,` or `?`

All three puzzles run in parallel. If the model answers correctly, weights stay the same. If it answers incorrectly, the neural network weights are updated (loss increases → backpropagation → adjustment).

> 💬 *"What you're doing is looking at text which already exists in the world and creating multiple challenges for yourself without human intervention. This is what makes the model self-supervised."*

The scalability implication: you can scrape the entire internet and have the model train on all of it without a single human labelling a single example. This is why modern LLMs have been trained on trillions of tokens.

Self-supervised learning has now spread beyond text: image models mask patches of images and try to reconstruct them; video models predict how objects move.

---

### 6. Transformer

People often conflate **transformer** with **LLM**. The narrator is precise: an LLM is the *product* (the car); the transformer is the *engine*.

A transformer is a specific algorithm for predicting the next token. Its architecture:

```
INPUT TOKENS
     │
     ▼
┌─────────────────┐
│  Attention Block │  ← Layer 1: disambiguates words (apple → fruit or company)
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  Feedforward Network │
└────────┬────────────┘
         │
         ▼
┌─────────────────┐
│  Attention Block │  ← Layer 2: finds complex relationships (sarcasm, implication)
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  Feedforward Network │
└────────┬────────────┘
         │  (stacked 12–100s of times)
         ▼
     OUTPUT VECTORS
```

Each stacked layer finds increasingly abstract patterns. Layer 1 resolves *crane* (bird vs. metal structure). Layer 2 infers that the crab the crane is hunting is *fearful*, and the crane is *hungry*.

> 💬 *"The large language model is actually the product. You can think of it as a car. And the transformer is the engine. The internal algorithm can be different."*

Modern GPT architectures stack hundreds of these layers. The transformer is not the only possible engine — state space models and diffusion-based text models are active areas of research that could replace it.

---

### 7. Fine-tuning

A base LLM trained via self-supervised learning can predict the next token generally. But what if you want it to answer medical questions in medical jargon? Or handle customer support queries for a specific company?

**Fine-tuning** is the process of taking a base model and training it on a domain-specific set of questions and answers — so that its internal weights shift toward generating responses in that domain's style and vocabulary.

```
Base LLM (general)
     │
     │  Fine-tuning: Q&A pairs in target domain
     ▼
Fine-tuned LLM (domain-specific)
     ├── Medical LLM  ← trained on diagnosis Q&A
     ├── Finance LLM  ← trained on financial reporting Q&A
     └── Customer LLM ← trained on company-specific queries
```

A key part of fine-tuning is **penalising undesirable responses** — not just wrong ones. If someone asks *"Who is the president of the USA?"*, the base model might respond *"I would like to know that too"* — technically not wrong, but completely unhelpful. Fine-tuning teaches the model: give a direct answer, or confess you don't know.

> 💬 *"The fine tuning process forces the model to take a question and give answers as expected. The internal weights will be updated in such a way that it will learn to speak in medical jargon or medical terms."*

The same base model (e.g. LLaMA) can be fine-tuned by different companies on different Q&A datasets to produce multiple specialised models.

---

## 🔧 Practical Usage — Building AI Applications

These five terms are the building blocks engineers use daily when building AI-powered systems.

### 8. Few-shot Prompting

When your server sends a user query to an LLM, you do not have to send just the query. **Few-shot prompting** means augmenting the query with examples of the format and style of response you want — at inference time, in production.

```
User query:  "Where is my parcel?"

Few-shot augmented query sent to LLM:
  ┌─────────────────────────────────────────────┐
  │ Example 1: Q: "Where is my order?"          │
  │            A: "Your order is in transit..."  │
  │ Example 2: Q: "When will it arrive?"         │
  │            A: "Expected delivery is..."      │
  │                                              │
  │ Now answer: "Where is my parcel?"            │
  └─────────────────────────────────────────────┘
```

> 💬 *"The quality of the response goes up. This is called few-shot prompting. It's basically example-in-prompt — that's it."*

The LLM uses these examples to infer the expected format, tone, and domain — without any weight updates. This is pure inference-time context augmentation.

---

### 9. Retrieval Augmented Generation (RAG)

Few-shot gives the model format examples. **RAG** gives the model company-specific factual context — documents retrieved in real time from your data store.

The flow:

```
User Query: "I am upset with your payment system. I expect a refund."
     │
     ▼
Server fetches relevant documents from Vector DB
  (finds: refund policy, payment escalation guide, compensation terms)
     │
     ▼
Augmented context sent to LLM:
  ┌──────────────────────────────────────────────┐
  │ System prompt:  [company persona]            │
  │ Few-shot examples: [format guidance]         │
  │ Retrieved documents: [refund policy, etc.]   │
  │ User query: "I am upset... I expect a refund"│
  └──────────────────────────────────────────────┘
     │
     ▼
LLM generates high-quality, policy-accurate response
```

> 💬 *"You retrieve the context, augment the query, and then generate a response."*

Where to store the documents? Usually a **vector database** — because the retrieval is a similarity search, and vectors make that efficient. (Graph databases and in-memory caches are alternatives, but vector DBs dominate the RAG stack.)

Note: some in the industry claim RAG is already being superseded. The narrator acknowledges this but notes the pattern — retrieve relevant context → augment → generate — remains foundational regardless of implementation.

---

### 10. Vector Database

The vector database is what makes RAG's retrieval step fast and accurate. The problem it solves:

A user says *"I am upset with your payment system."* Your company policy document never uses the word "upset" — it uses *"low rating"* and *"drop off"*. A keyword search would return nothing. A vector similarity search works because *upset* and *low rating* are **semantically close** in the vector space.

```
Query vector: "I am upset"
     │
     ▼  similarity search (e.g. HNSW algorithm)
Vector DB returns documents closest in meaning:
  → "user gives low rating" (distance: 0.12)
  → "user drops off" (distance: 0.18)
  → "user requests refund" (distance: 0.21)

These documents are sent to the LLM as context.
```

> 💬 *"The vector database is like a black box to you. You can store documents and you can quickly retrieve them when you need them."*

Popular algorithms for vector similarity search include HNSW (Hierarchical Navigable Small World). Popular vector databases: Pinecone, Weaviate, Qdrant, pgvector. The choice of storage mechanism matters less than the semantic search capability.

---

### 11. Model Context Protocol (MCP)

RAG gives an LLM access to your internal documents. **MCP** gives it access to the outside world — real-time data from external systems and the ability to take actions.

```
User: "Book me the cheapest flight to Mumbai tomorrow"
     │
     ▼
LLM (via MCP client) identifies: needs live flight data
     │
     ├──▶ MCP Server: IndiGo API  →  returns flight options
     └──▶ MCP Server: Air India API  →  returns flight options
     │
     ▼
LLM selects: IndiGo 1020 (cheapest)
     │
     ▼
MCP client calls IndiGo booking API → flight booked
     │
     ▼
Final response to user: "Your flight IndiGo 1020 has been booked."
```

The key shift: the user no longer receives a *recipe* ("here are your options, go book one"). The agent **executes** on their behalf.

> 💬 *"The user is no longer just able to get data. They do not have to do things themselves after being given the recipe. The recipe can be completely executed by the MCP client."*

MCP (the protocol) standardises how LLMs connect to external data sources and APIs — making it much easier for tool providers to expose their services to any LLM that supports MCP.

---

### 12. Context Engineering

**Context engineering** is the umbrella term for all the techniques that shape what the LLM knows before it generates a response. It encompasses everything above and adds two newer engineering challenges:

| Technique | What It Adds to Context |
|-----------|------------------------|
| Few-shot prompting | Format and style examples |
| RAG | Relevant company documents |
| MCP | Real-time external data + actions |
| User preferences | Declared long-term preferences per user |
| Context summarization | Compressed history to preserve space |

The distinction between **prompt engineering** and **context engineering**:

```
Prompt Engineering:   stateless · one prompt · same system prompt every time
Context Engineering:  stateful · evolves per user · incorporates chat history
```

> 💬 *"Context engineering evolves as per the user's declared preferences and also the previous chat history — similar to what it was earlier, but this is more long term."*

The **context summarization** challenge: LLMs have a token limit. As conversations grow, you cannot send the full history. Common strategies include a sliding window (last N messages verbatim + everything older summarised into 5 sentences), or keyword extraction. A cheap small language model can do the summarisation before the expensive LLM receives the compressed context.

---

## ⚙️ How It Works — Advanced Architectures

### 13. Agents

An **agent** is a long-running process — think of it as a server — that receives an API call and orchestrates multiple capabilities to meet the user's requirement:

```
                    ┌─────────────────────────────┐
                    │          AGENT               │
                    │  (long-running process)      │
                    ├─────────────────────────────┤
     User Request ─▶│  can query: LLM             │
                    │  can query: external systems │
                    │  can query: other agents     │
                    └─────────────────────────────┘
```

Example: a travel agent that books flights when prices drop, books hotels based on your preferences, and manages your email while you are away — autonomously, without waiting for each instruction.

> 💬 *"You can think of this as a server which is getting an API call and has many capabilities. It can go and query an LLM, query external systems, and other agents to meet the user's requirements."*

Agents are the most hyped term in the AI space right now — and the most powerful application of everything else in this guide.

---

### 14. Reinforcement Learning (RLHF)

**Reinforcement learning** is a training technique where a model learns which outputs are good or bad based on feedback — without being told the exact right answer upfront.

In practice (Reinforcement Learning from Human Feedback, or RLHF):
1. The model generates two responses to a query
2. A human selects the better one (+1) and the worse one (-1)
3. These scores are mapped back to the token paths that produced each response
4. The model learns to favour paths through the vector space that lead to positive scores

```
Query ─▶ LLM ─┬─▶ Response A: good → score +1 → reinforce this path
              └─▶ Response B: bad  → score -1 → penalise this path

Over thousands of examples:
  Vector space develops regions of positive and negative value
  Model learns to navigate toward positive regions (hill climbing)
```

> 💬 *"If the end user experience is good, then the model is trained to make users happy. That's reinforcement learning with human feedback."*

The classic analogy: Pavlov's dog. A bell is rung, food arrives — the dog learns to salivate at the bell alone. Behaviours are reinforced.

**The important limitation:** reinforcement learning observes outcomes and reinforces paths. It cannot build mental models. If a fair coin comes up heads ten times in a row, a human knows the next flip is still 50/50 — because they have a model of how coins work. An RL model would predict heads because that is what got reinforced. RLHF makes models useful, but it does not make them reason.

---

### 15. Chain of Thought

**Chain of thought** is a training and prompting approach where the model is explicitly walked through a step-by-step reasoning process before arriving at an answer.

Instead of: `Question → Answer`

Chain of thought: `Question → Step 1 → Step 2 → Step 3 → ... → Answer`

> 💬 *"Chain of thought is where the model goes through a series of deductions or inferences and comes up with the final response. The quality of this response is usually much higher than a direct response."*

The key difference from few-shot prompting: in few-shot, examples provide format. In chain of thought, examples provide *reasoning steps* — and the model learns to generate new intermediate steps as problems get harder. DeepSeek demonstrated this empirically: harder problems → more reasoning steps added by the model; easier problems → fewer steps.

---

### 16. Reasoning Models

A **reasoning model** (also called an LRM — Large Reasoning Model) is a model trained to figure out, given any problem, how to break it down step by step before answering.

Chain of thought is one mechanism. Others include:
- **Tree of Thought** — explores multiple reasoning branches simultaneously
- **Graph of Thought** — models complex interdependencies between reasoning steps
- **Tool use** — calls external tools mid-reasoning to verify facts

> 💬 *"A model that can reason, a model that can figure out how to solve that problem step by step, is a reasoning model. Examples: DeepSeek, OpenAI O1, O3."*

Reasoning models represent the current frontier of capability improvement. They do not just predict plausible next tokens — they plan the path to a correct answer.

---

## 🔬 Model Variants & Efficiency

### 17. Multi-modal Models

Most LLMs operate on text. **Multi-modal models** accept and generate multiple types of input: text, images, and video.

Applications:
- *Image understanding:* count apples in a photo, describe a scene, answer questions about an image
- *Image generation:* create or modify images from text descriptions
- *Video analysis/generation:* analyse footage, create ads, synthesise scenes

> 💬 *"If you train a model on cat and feline and then show it images of cats, the performance of the model is usually better. They have a deeper understanding of the meaning of objects."*

Cross-modal training improves all modalities: a model trained on both text describing cats and images of cats develops a richer representation of "cat" than either modality alone. Multi-modal training is now standard for frontier models.

---

### 18. Small Language Models (SLMs)

**Small language models** have far fewer parameters than LLMs — typically 3 million to 300 million, versus 3 to 300 **billion** for large models.

| | Small Language Model | Large Language Model |
|-|---------------------|---------------------|
| Parameters | 3M – 300M | 3B – 300B |
| Training data | Company/task-specific | Broad internet-scale |
| Capability | Expert in narrow domain | General purpose |
| Cost to run | Low | High |
| Data privacy | Stays in-house | Potentially exposed |

> 💬 *"Smaller language models are being trained by companies on their specific data, on proprietary data, to come up with reasonably good responses for specific use cases."*

A sales bot trained exclusively on customer service conversations will not know weather analysis — but for most companies, that is perfectly fine. NASA builds a foundation model for weather prediction; a retail company builds one for sales queries.

SLMs are increasingly preferred for production deployments where data privacy, latency, and cost are constraints.

---

### 19. Distillation

The standard way to build an SLM is **distillation** — a teacher-student approach where a large model trains a small one.

```
Input Query
     │
     ├──▶ Large LLM (teacher) ──▶ Output A
     │
     └──▶ Small LLM (student) ──▶ Output B
                                      │
                                  compare A vs B
                                      │
                         ┌────────────┴────────────┐
                         │ match: no weight update │
                         │ mismatch: update student│
                         │ weights (backprop)      │
                         └─────────────────────────┘
```

> 💬 *"What you are basically trying to do is condense this information, the complex neural network, into the most reasonable representation you can have — such that your performance is okay but the costs are significantly reduced."*

The student is constrained to 3–300M parameters. The goal is the most accurate compression of the teacher's knowledge that fits in that parameter budget. The result is a model that responds faster, costs less to host, and handles the domain it was distilled on with near-LLM quality.

---

### 20. Quantization

Even a distilled SLM has weights stored as high-precision numbers. **Quantization** reduces the bit-width of those weights to cut inference cost.

```
Standard model:    weights stored as 32-bit floats
Quantized (INT8):  weights stored as 8-bit integers
Expected saving:   ~75% reduction in memory footprint
```

Key facts the narrator is precise about:

| Aspect | Detail |
|--------|--------|
| What is reduced | Memory footprint and inference cost |
| What is NOT reduced | Training cost (quantization applied after training) |
| Where it applies | Primarily feedforward neural network weights |
| What is unaffected | Attention mechanism |
| When to apply | After the model is fully trained |

> 💬 *"Initially you come up with a really good model with zero quantization. Once the model is completely trained, that's when you apply quantization. So the training cost does not reduce. This is mainly to reduce inference cost."*

Quantization is the final step in making a model production-deployable — smaller in memory, cheaper per request, without retraining from scratch.

---

## 🔗 How the 20 Terms Connect

Every term in this guide is solving the same fundamental problem at a different layer of the stack:

```
FOUNDATIONAL LAYER (how language is understood)
  LLM → Tokenization → Vectorization → Attention → Transformer

TRAINING LAYER (how models learn)
  Self-Supervised Learning → Fine-tuning → Reinforcement Learning
  Chain of Thought → Reasoning Models

APPLICATION LAYER (how engineers use models)
  Few-shot Prompting → RAG → Vector Database → MCP → Context Engineering → Agents

EFFICIENCY LAYER (how models are made cheaper)
  Small Language Models → Distillation → Quantization → Multi-modal Models
```

Context engineering sits at the intersection of application and training layers — it is how you give runtime-assembled knowledge to a model trained on static data.

---

## ⚠️ Gotchas & Common Misconceptions

| Misconception | Reality | Narrator's Clarification |
|---------------|---------|--------------------------|
| **"Transformer = LLM"** | LLM is the product; transformer is one possible engine | "A car, many people say, is just the engine. But no." |
| **"Vector = just a word embedding"** | Vectors are coordinates in n-dimensional space where semantic proximity equals spatial proximity | "The mapping of a word in n-dimensional space such that nearby words, similar meaning words, are all clustered together." |
| **"Self-supervised = unsupervised"** | Self-supervised still has right/wrong answers — they are generated from the input structure itself | "The structure of the input data is such that the model knows what it should do." |
| **"Fine-tuning changes the architecture"** | Fine-tuning updates weights only; architecture stays the same | "The base model can be fine-tuned to answer in a specific way." |
| **"RAG is dead"** | The retrieve-augment-generate pattern remains foundational; specific implementations evolve | Narrator acknowledges the claim but focuses on the principle |
| **"RL makes models think"** | RL reinforces good output paths; it cannot build mental models | "While reinforcement learning cannot build mental models, they can just tell you based on outcomes what is more likely." |
| **"Quantization reduces training cost"** | Quantization only reduces inference cost; applied post-training | "The training cost does not reduce. This is mainly to reduce inference cost." |
| **"SLMs are just weaker LLMs"** | SLMs are task/domain experts; they outperform LLMs on their specific domain | "A bot trained on just customer queries is likely to perform decently well — an expert at sales." |

---

## 🎯 Key Takeaways

- An LLM is a neural network that predicts the next token — tokenization, vectorization, and attention are the three mechanisms that make this prediction meaningful
- Attention was the 2017 breakthrough: it allows a model to derive context-dependent meaning from ambiguous words by looking at surrounding words
- Self-supervised learning made LLMs scalable: training data labels itself from its own structure — no humans required
- The transformer is the engine; the LLM is the car — the engine can be replaced
- Fine-tuning shifts a base model's output distribution toward a specific domain without changing its architecture
- Few-shot prompting, RAG, MCP, and context engineering are the application-layer toolkit — each adds a different kind of context to the LLM's input
- Agents are long-running processes that orchestrate LLMs, tools, and other agents to execute on behalf of users
- RLHF makes models helpful; it does not make them reason — reasoning models are a separate and newer capability
- SLMs, distillation, and quantization are the efficiency toolkit — making models cheaper to run without retraining from scratch
- Knowing these 20 terms turns AI hype into recognisable engineering patterns

---

## 📖 Narrator's Own Words

> *"If you know these terms, then it is also easier to learn the deeper subjects around AI."*

> *"The core problem for the large language model is to truly understand human language so that it can speak it really well. Tokenization is an essential part of that."*

> *"Vectors can encapsulate semantic meaning, which means documents which store similar words are going to be similar or close in distance. Remember, vectors are basically coordinates."*

> *"While reinforcement learning cannot build mental models, they can just tell you based on outcomes what is more likely and what is a more beneficial path."*

> *"All of the hype and nonsense which is going on in this space — they become hype and nonsense to you. You are able to recognise it much better."*

---

*Guide synthesised from: YouTube — "Commonly Used Terms in the AI Space" by GKCS | Agent: transcript-guide v1.0.0 | Validated: 2026-04-28*
