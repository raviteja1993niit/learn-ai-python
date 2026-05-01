# Introduction to AI Agents — A Complete Guide
> *Based on: YouTube Tutorial - "Introduction to AI Agents"*

---

## 🧭 what this guide covers

This guide takes you from zero knowledge to a complete understanding of modern AI systems. The narrator assumes you know "absolutely nothing" and explains everything through a single cohesive project. You'll learn AI fundamentals, RAG, vector databases, LangChain, LangGraph, MCP, prompt engineering, and how to put it all together in a complete system. By the end, you'll understand everything happening with AI today.

---

## 💡 the big picture

The narrator frames the current AI landscape as an overwhelming collection of concepts: "Prompt engineering, context windows, tokens, embeddings, RAG, vector DB, MCPs, agents, LangChain, LangGraph, Claude, Gemini, and more." If you felt left out, this is the catch-up guide.

The core insight: AI models work like human memory with limitations. Just as you might struggle to memorize π to 15 digits all at once (3.141592653589791), LLMs have limits on how much context they can hold. The challenge is giving AI access to large knowledge bases (like TechCorp's 500 GB of internal documents) when it can only "see" a tiny fraction at any moment — think of it as trying to work with an entire library while only being able to read one chapter at a time.

---

## 📚 core concepts

### Large Language Models (LLMs)

When you ask an AI a question, it's typically answered by a subset of AI called **large language models**. LLMs got popular around late 2022 when ChatGPT was released, as we started seeing language models get larger because of obvious performance benefits.

> 💬 *"Popular LLMs like OpenAI's GPT, Anthropic's Claude, and Google's Gemini are all transformer models that are trained on large sets of data."*

The scale is massive: training token counts go up to **tens of trillions of tokens** from thousands of different domains—healthcare, law, coding, science, and more.

**The TechCorp problem:** Your company has 500 GB of internal documents that weren't part of the LLM's training data. To ask questions about these documents, you need the ability to pass data into the LLM at runtime.

**Why this matters:**  
LLMs know about public knowledge but know nothing about your private data. The challenge is bridging that gap efficiently.

### Context Windows and Tokens

One way to pass data to an LLM is by adding it to the **conversation history**, which functions like short-term memory. During a conversation, all context is kept in memory — this memory is called the **context window**.

**How tokens work:**  
Context windows are measured in **tokens**, which is roughly 3/4 of a word for English text. The window size is limited and varies by model:

- **XAI Grok 4**: 256,000 tokens  
- **Anthropic Claude Opus 4**: 200,000 tokens  
- **Google Gemini 2.5 Pro**: 1 million tokens  

**The π analogy:**  
> 💬 *"If I asked you to memorize the pi digits 3.141592653589791 and asked you to recite it, some of you might have a hard time committing that many numbers all at once, which is similar to how LLM's context window works."*

**Practical sizing:**
- **Small models** (nano, mini, flash): 2,000–4,000 tokens ≈ 1,500–3,000 words
- **Large models** (GPT-4, Gemini Pro): up to 1 million tokens ≈ 750,000 words or 50,000 lines of code

**Why this matters:**  
Choosing the right model depends on your task. Need to process a full novel? Use a large context window. Need fast responses on small documents? Use flash/nano variants for lower latency.

### RAG (Retrieval Augmented Generation)

**The Core Question:**  
Instead of searching through the entire 500 GB of documents, can an AI assistant fit them into their context window and generate output? This is called **RAG**.

**The Three Steps of RAG:**

1. **Retrieval:**  
   When someone asks *"What's our remote work policy for international employees?"*, the system:
   - Converts the question into vector embeddings (just like documents)
   - Uses **semantic search** to find relevant contents based on meaning and context, not static keywords

2. **Augmentation:**  
   The retrieved data is **injected into the prompt at runtime**.  
   
   > 💬 *"Typically, AI assistants rely on what they learned during pre-training, which is static knowledge that can become outdated. Instead, our goal is to have the AI assistant rely on up-to-date, real-time data."*
   
   The semantic search results are appended to the prompt as **augmented knowledge**. The AI assistant is given details from the company's documents — real, up-to-date, and private data — all without needing to fine-tune or modify the LLM with custom data.

3. **Generation:**  
   The AI assistant generates a response using the semantically relevant data retrieved from the vector database. Since the prompt specifies "international employees," the generation step uses its reasoning to answer with relevant context.

**RAG's Power:**  
RAG can instantly improve the depth of knowledge beyond training data.

**The Trade-off:**  
> 💬 *"Setting up a RAG system will look different from one system to another because it heavily depends on the data set you're trying to store."*

Examples:
- **Legal documents:** Require different chunking strategies than customer support transcripts. Legal docs have long structured paragraphs that need to be preserved intact.
- **Conversational transcripts:** Fine with sentence-level chunking with high overlap to preserve context.

**Why this matters:**  
RAG bridges the gap between an LLM's static training data and your company's dynamic, private knowledge base—without retraining the model.

### Vector Databases

**The Fundamental Shift:**  
We learned LLMs have context windows measured in tokens. We learned embeddings convert meaning into numbers. Now we need a system that ties everything together.

**The Problem:**  
Even with embeddings, TechCorp's 500 GB of documents create an immediate problem. How do we efficiently search through them based on **meaning** rather than exact keywords?

**What Vector Databases Do:**  
Instead of searching by exact wording (like SQL's `WHERE` clause), vector databases let you **search by meaning**. 

> 💬 *"When you search the database by sending the question itself — 'can I request time off on a holiday?' — based on the meaning of those words contained in the question, the database returns only relevant data back."*

**Popular implementations:** Pinecone, ChromaDB

**Key Concepts:**

1. **Embeddings as Storage Medium:**  
   In SQL, you store values as-is. In vector databases, you convert values into **semantic meanings** (embeddings) before storage.  
   - "holiday" and "vacation" share similar vector space since their meanings are close
   - Before "employee shall not request time off on holidays" gets stored, it's converted into a long vector of numbers (typically **1,536 dimensions**)

2. **Dimensions:**  
   More dimensions = more context captured (tone, formality, nuance). 1,536 dimensions is a good balance between size and depth.

3. **Retrieval Scoring:**  
   Since we're not using `WHERE` queries, we need to decide what counts as a match and by how much. This involves:
   - **Similarity scoring** (cosine similarity)
   - **Chunk overlap** (so context doesn't get lost when documents are split)

4. **Chunk Overlap:**  
   Documents are often chunked before storage. Overlap prevents meaning from getting split. Example: 500-character chunks with 100-character overlap can improve retrieval accuracy by **40%**.

**The Trade-off:**  
> 💬 *"While a properly set up vector database is extremely powerful, it requires significant upfront tweaking and configuration."*

**Why this matters:**  
With vector databases, the burden is on you (setting up the database) to make it easier for someone searching. But once set up, the LLM can freely search based on meaning and have confidence that the database returns relevant data.

### Embeddings

**The "Irrelevant Information" Problem:**  
> 💬 *"Sally and Bob own an apple farm. Sally has 14 apples. Apples are often red. 12 is a nice number. Bob has no red apple, but he has two green apples. Green apples often taste bad. How many apples do they all have?"*

This requires filtering out irrelevant information. The narrator uses this to show that even large context windows struggle with noise — the fact that apples are red or green has nothing to do with counting the total (the answer is 16).

**The Real Problem:**  
Even Gemini 2.5 Pro's 1 million token window can only hold about 50 typical business documents at once. TechCorp needs to understand all 500 GB of documents, but the model can only see a tiny fraction at any moment.

**How Embeddings Solve This:**  
Embeddings transform how we think about information. Instead of storing text as words, we **convert meaning into numbers**. 

> 💬 *"The sentence 'employee vacation policy' and 'staff time off guidelines' use completely different words, but they mean essentially the same thing. Embeddings capture that semantic similarity."*

**How it works:**  
An embedding model takes text and converts it into a **vector** — typically **1,536 numbers** that represent the meaning. Similar concepts end up with similar number patterns:
- "vacation" and "holiday" have vectors mathematically close to each other
- When someone asks "Can I wear jeans to work?", the system finds the dress code policy even if it never mentions "jeans" specifically

**Why this matters:**  
You can find relevant documents based on what someone **means**, not just the exact words they used.

### LangChain and LangGraph

**The Problem Lang Chain Solves:**  
TechCorp needs a chatbot where customers can ask questions about company policy, product information, and support issues. The chatbot needs to:
- Remember conversation history
- Access the company knowledge base
- Handle complex multi-step interactions

Your first instinct might be to use OpenAI's SDK to build a quick chat interface. But you quickly realize **massive missing pieces**: storing chat messages, maintaining conversation context, connecting to TechCorp's internal knowledge base, and handling the possibility that the company might switch from OpenAI to Anthropic or Google in the future.

> 💬 *"What seemed like a simple project becomes a massive undertaking."*

**Enter LangChain:**  
Lang Chain is an **abstraction layer** that helps you build AI agents with minimal code. It addresses all those pain points using pre-built components and standardized interfaces.

**LLM vs. Agent — The Crucial Difference:**
- **LLM**: A static brain that answers questions based on training data
- **Agent**: Has autonomy, memory, and tools to perform whatever task it thinks is necessary to complete your request

**Example:**  
When a customer asks *"What's your company's policy on refunding my product that arrived damaged?"*, an agent will **self-determine** how it should answer that request autonomously, instead of traditional software that requires conditional statements.

**LangChain's Pre-Built Components:**

| Component | What It Does | Code Example |
|-----------|--------------|--------------|
| **Chat Models** | Direct LLM access | `LLM = ChatOpenAI(model="gpt-3.5-turbo")` → Switch to Anthropic with one line: `LLM = ChatAnthropic(model="claude-3-sonnet")` |
| **Memory Management** | Uses `MemorySaver` to auto-store chat history | No need to build database schema or session management |
| **Vector DB Integration** | Standardized APIs for Pinecone, ChromaDB, etc. | Consistent interface regardless of which vector DB you choose |
| **Text Embedding** | Converts documents into vectors | Single function call instead of managing API connections |
| **Tool Integration** | Lets agents access external systems | Query TechCorp's customer database when needed |

**Without LangChain**, you'd need to build:
- API management for multiple LLM providers
- Vector database SDKs
- Embedding pipelines
- Semantic search logic
- State management
- Memory systems
- Tool routing

**The complexity grows exponentially.** LangChain handles all of it.

**Why this matters:**  
The agent orchestrates these components based on conversation context. Depending on the question asked, the agent autonomously uses tools like vector databases, conversation memory, and system prompts to handle requests.

### MCP (Model Context Protocol)

**The Final Piece:**  
TechCorp's AI agent needs to connect to multiple external systems: customer database, support tickets, inventory system, notification service, etc. Writing custom integrations for all these API connections would take a huge amount of time.

**What is MCP?**  
> 💬 *"MCP functions like an API, but with crucial differences that make it perfect for AI agents."*

**Traditional APIs vs. MCP:**
- **Traditional APIs**: Expose endpoints that require you to understand implementation details, leading to rigid integrations tied to specific systems
- **MCP**: Doesn't just expose tools—it provides **self-describing interfaces** that AI agents can understand and use autonomously

**The Key Advantage:**  
> 💬 *"Unlike traditional APIs, MCP puts the burden on the AI agent rather than the developer."*

**The USB Analogy:**  
Think of MCP as a universal port like USB that allows AI systems to connect to any tool, database, or API in a standardized way:
- **Protocol** = Port
- **Server** = Device
- **Tools** = Functions
- **LangGraph** = Computer that uses them

**How It Works:**  
When you start an MCP server, an instance starts and establishes a connection with your AI agent. For example:

**Customer Database MCP:** When someone asks *"What's the status of order 1234?"*, the AI uses MCP to:
1. Query TechCorp's order management system
2. Retrieve the current status
3. Provide a complete response

**The Real Power:**  
The MCP server code only needs to be written **once**, and it doesn't necessarily have to be you. A community of MCP developers might have written custom MCP servers for popular tools like GitHub, GitLab, or SQL databases — you can simply use them directly on your agent without writing code yourself.

**Why this matters:**  
MCP creates a **plug-and-play ecosystem** where agents can dynamically discover and use tools without custom integration code for each service.

### AI Agents

**LLM vs. Agent — The Crucial Difference:**
- **LLM**: A static brain that answers questions based on training data
- **Agent**: Has **autonomy, memory, and tools** to perform whatever task it thinks is necessary to complete your request

**Autonomous Decision-Making:**  
When a customer asks *"What's your company's policy on refunding my product that arrived damaged?"*, an agent will **self-determine** how to answer that request autonomously, instead of traditional software that requires conditional statements determining how a program should execute.

**Agent Capabilities:**  
The agent orchestrates components based on conversation context:
- Uses vector databases for semantic search
- Accesses conversation memory
- Applies system prompts
- Calls external tools (MCP servers)
- Routes between multiple specialized tools

**Dynamic Tool Orchestration:**  
Agents can integrate tools like:
- Custom database access
- Web search
- Local file system access
- Calculator functions
- Weather services
- And more

The system retrieves available tools, creates an agent with access to all of them, and intelligently routes queries. If a user asks a math question, the calculator responds. If they ask about weather, the weather tool responds.

**Why this matters:**  
This is where the shift happens from static software to **living intelligent systems** that don't just answer questions, but actively solve problems before employees can even ask.

### Prompt Engineering

**Core Techniques:**

1. **Zero-Shot Prompting:**  
   Asking the LLM to perform a task without any examples. The model relies entirely on its training.

2. **One-Shot Prompting:**  
   Providing **one example** to guide the model's response format or style.

3. **Few-Shot Prompting:**  
   Providing **multiple examples** to help the model understand patterns and context better. This is **few-shot learning** from the user's perspective — learning from examples you provide.

4. **Chain-of-Thought Prompting:**  
   Providing the model with a trail of steps to think through how to solve specific problems.

   **Bad prompt:** "Fix our data retention policy"
   
   **Chain-of-thought prompt:** 
   > "Analyze current gaps in data retention. Research industry best practices for similar companies. Finally, draft specific recommendations with implementation steps. Now fix our customer policy."
   
   > 💬 *"Providing how LLM should go through breaking down a specific request gives an exact blueprint for how the LLM should then fix the customer policy."*

**Why this matters:**  
Chain-of-thought encourages the AI to show its reasoning step-by-step. Instead of vague one-line answers, the AI breaks problems into steps and works through them systematically — resulting in clearer, more reliable, and more accurate outputs, particularly for complex reasoning tasks.

---

## ⚙️ how it works — under the hood

**The Complete System Architecture:**

1. **User Query Arrives** → "What's our remote work policy for international employees?"

2. **Embedding Layer** → Query is converted into 1,536-dimensional vector using embedding model

3. **Vector Database Search** → ChromaDB performs semantic search across all stored document embeddings, returns top 3 most relevant chunks based on cosine similarity

4. **RAG Augmentation** → Retrieved documents are injected into the prompt at runtime, providing up-to-date, company-specific context

5. **Agent Decision** → LangGraph agent determines which tools to use:
   - Need customer data? → Call Customer Database MCP server
   - Need calculation? → Call Calculator MCP server
   - Need web search? → Call DuckDuckGo MCP server

6. **LLM Generation** → OpenAI/Claude/Gemini (via LangChain abstraction) generates response using:
   - Original query
   - Retrieved context from vector DB
   - System prompt instructions
   - Conversation memory (maintained by MemorySaver)

7. **Response + Attribution** → Answer is returned with source attribution pointing to original documents

**State Management:**  
State Graph maintains context throughout the workflow — topic, documents, compliance scores, gaps, recommendations all persist across nodes.

**Conditional Routing:**  
Based on intermediate results (e.g., compliance score), the agent can loop back to gather more data or proceed to final generation.

**The narrator's mental model:**  
Think of it like a restaurant kitchen where:
- **LLM** = Chef (skilled but needs ingredients)
- **Vector DB** = Pantry (organized by meaning, not just labels)
- **RAG** = Prep cook (fetches exactly what's needed)
- **Agent** = Kitchen manager (orchestrates everything autonomously)
- **MCP** = Universal adapters (connects to any appliance/service)
- **LangChain** = Kitchen infrastructure (handles the plumbing)

---

## 🔧 practical usage / implementation

The narrator walks through hands-on labs throughout the tutorial:

### Lab 1: Your First AI API Call
1. **Environment setup**: Activate virtual environment, check Python, ensure OpenAI library is available, confirm API keys are set
2. **Import libraries**: `import openai` and `import os`
3. **Initialize client**: Pass `OPENAI_API_KEY` and `OPENAI_API_BASE` environment variables
4. **Make first API call**: Use chat completions with system/user/assistant roles
5. **Extract response**: Navigate response path: `response.choices.message.content`
6. **Calculate costs**: Extract token usage (prompt tokens, completion tokens, total tokens). **Important**: Output tokens are more expensive than input tokens.

### Lab 2: LangChain Basics
**The key idea:** Instead of being locked into one provider's SDK and rewriting code whenever you switch, LangChain offers one interface that works everywhere.

Switch from OpenAI to Google's Gemini or XAI's Grok by changing **just a single word**.

### Lab 3: Prompt Engineering
Run the same problem through zero-shot, one-shot, few-shot, and chain-of-thought prompts to see the difference in output quality.

### Lab 4: Vector Databases & Semantic Search
**The mission**: Fix TechCorp's keyword search (95% failure rate) by building a search system that understands meaning.

1. **Install libraries**: `sentence-transformers`, `langchain`, `chromadb`, `numpy`
2. **Task 1 — Embeddings**: Initialize mini-LM model, encode queries and documents, calculate similarity using cosine similarity
3. **Task 2 — Chunking**: Use LangChain's `RecursiveCharacterTextSplitter` with chunk size of 500 characters and 100-character overlap (improves retrieval accuracy by **40%**)
4. **Task 3 — Vector Store**: Create ChromaDB instance, configure embedding model
5. **Task 4 — Semantic Search**: Implement full pipeline: convert user query → search Chroma → retrieve relevant chunks → return to user

**Result**: Built a production-ready search engine with **95% success rate**.

### Lab 5: RAG Implementation
**The goal**: Transform semantic search into a complete Q&A engine.

1. **Set up vector store**: Initialize ChromaDB client, create collection
2. **Document processing**: Chunk documents intelligently
3. **System prompt**: Make it clear answers must come only from retrieved documents. If information isn't in context, respond with "I don't have that information in the provided documents" (prevents hallucinations)
4. **Complete RAG pipeline**: Embed user query → search ChromaDB → retrieve top 3 chunks → build context-aware prompt → generate answer using LLM
5. **Source attribution**: Every answer points back to the document it was derived from

### Lab 6: LangGraph Workflows
**Key concepts**: Nodes, Edges, State Management

- **Nodes**: Individual processing units (gather documents, extract content, evaluate compliance, generate recommendations)
- **Edges**: Define flow between nodes (conditional routing based on compliance score)
- **State Graph**: Stores information throughout entire workflow

**Example flow**: 
- If compliance score < 75% → route back to gather more documents
- If score ≥ 75% → proceed to final report generation

**Tool integration**: Combine calculator with web search (DuckDuckGo). System decides whether to perform calculation, run web search, or handle text normally.

### Lab 7: MCP Integration
1. **Create MCP server**: Initialize server (e.g., "calculator"), define function with `@MCP.tool` decorator, run with STDIO transport
2. **Integrate with LangGraph**: Configure client, fetch tools from server, create agent that can call calculator when needed
3. **Multiple MCP servers**: Add weather service. LangGraph orchestrates between both — math questions go to calculator, weather questions go to weather tool

**Result**: Universal, extendable system that can connect any tool to any AI.

---

## ⚠️ gotchas & common mistakes

| Gotcha | Why It Happens | Narrator's Advice |
|--------|---------------|-------------------|
| **Context window overflow** | Trying to fit too much data into the context window | Choose the right model for the task. Large documents need large context windows (Gemini 2.5 Pro's 1M tokens). Small documents with fast response needs use flash/nano variants. |
| **Irrelevant information in context** | Including noise that distracts the LLM (like the apple farm example) | Use RAG to retrieve only relevant chunks. Don't dump entire documents into context. |
| **Poor chunking strategy** | One-size-fits-all chunking breaks meaning | Legal documents need long structured chunks kept intact. Conversational transcripts work with sentence-level chunking. Adjust based on your data type. |
| **No chunk overlap** | Context gets lost at chunk boundaries | Use 100-character overlap with 500-character chunks — can improve retrieval accuracy by 40%. |
| **Hallucinations in RAG** | LLM invents answers when it doesn't find relevant data | Add explicit system prompt: "If information isn't in the provided documents, respond with 'I don't have that information.'" |
| **Token costs spiraling** | Not tracking prompt vs completion tokens | Output tokens are more expensive than input tokens. Be concise. Monitor usage fields in API responses. |
| **Vendor lock-in** | Writing custom code for each LLM provider | Use LangChain's abstraction layer. Switch from `ChatOpenAI(model="gpt-3.5-turbo")` to `ChatAnthropic(model="claude-3-sonnet")` with one line change. |
| **Manual tool integration** | Writing custom API wrappers for every external service | Use MCP servers. Community-written integrations for GitHub, GitLab, SQL databases already exist — just plug them in. |
| **Static knowledge** | LLM only knows what it was trained on | Implement RAG to inject real-time, company-specific data at runtime without retraining the model. |

---

## 🔗 how it connects to other concepts

The narrator shows how everything interconnects:

- **Context Windows** → limit how much data you can pass → leads to need for **Embeddings**
- **Embeddings** → convert meaning to numbers → stored in **Vector Databases**
- **Vector Databases** → enable semantic search → power **RAG**
- **RAG** → retrieves relevant context → augments **LLM prompts**
- **Prompt Engineering** → optimizes how you communicate → improves **Agent** performance
- **Agents** → need to orchestrate tools → simplified by **LangChain**
- **LangChain** → abstracts complexity → integrates with **LangGraph** for workflows
- **LangGraph** → manages state and routing → connects to external systems via **MCP**
- **MCP** → pluggable tool ecosystem → extends **Agent** capabilities

> The narrator emphasizes: *"This is the same architecture that powers tools like ChatGPT, Claude, and Gemini."*

---

## 🎯 key takeaways

- Context windows are like human short-term memory — limited in size, struggles with noise
- Embeddings convert meaning into math — "vacation" and "holiday" become numerically similar vectors
- Vector databases let you search by meaning, not keywords — semantic search vs exact match
- RAG = Retrieval + Augmentation + Generation — inject real-time data without retraining
- LangChain abstracts away infrastructure complexity — one line to switch between OpenAI and Claude
- Agents have autonomy — they self-determine how to solve problems, not just answer questions
- MCP creates a plug-and-play ecosystem — universal adapters for any tool or service
- Chain-of-thought prompting dramatically improves reasoning — show the model how to think step-by-step
- TechCorp's transformation: **30 minutes → 30 seconds** for document search with **95% success rate**
- The shift from static documents to **living intelligent systems** marks a turning point for how businesses unlock the full value of their knowledge

---

## 📖 narrator's own words — quotable moments

> *"If you felt left out, this is the only video you'll need to watch to catch up."*

> *"We assume you know absolutely nothing and try to explain all of these concepts through a single project."*

> *"If I asked you to memorize the pi digits 3.141592653589791 and asked you to recite it, some of you might have a hard time committing that many numbers all at once, which is similar to how LLM's context window works."*

> *"The sentence 'employee vacation policy' and 'staff time off guidelines' use completely different words, but they mean essentially the same thing. Embeddings capture that semantic similarity."*

> *"What seemed like a simple project becomes a massive undertaking."*

> *"MCP functions like an API, but with crucial differences that make it perfect for AI agents."*

> *"Unlike traditional APIs, MCP puts the burden on the AI agent rather than the developer."*

> *"Setting up a RAG system will look different from one system to another because it heavily depends on the data set you're trying to store."*

> *"The shift from static documents to living intelligent systems marks a turning point not just for TechCorp, but for how every other business can unlock the full value of its knowledge."*

---

*Guide synthesised from: YouTube Tutorial - "Introduction to AI Agents" | Agent: transcript-guide v1.0.0*
