# LangChain V1 — Practical Projects

## Project 1: Q&A Bot
**Goal:** Build a question-answering bot with a custom persona.
**Setup:**
1. Install: pip install langchain-openai langchain-core
2. Set OPENAI_API_KEY environment variable
3. Create prompt with system persona and human input variable
4. Chain with StrOutputParser for clean string output
**Key concepts:** ChatPromptTemplate, LCEL pipe operator, StrOutputParser
**Hints:**
- Use temperature=0 for consistent, deterministic answers
- Add domain restriction in system message (e.g., "only answer about Python")
- Test with a variety of question types: factual, how-to, conceptual
**Extension:** Add input validation, log all Q&A pairs to a file with timestamps

---

## Project 2: Text Summarizer
**Goal:** Summarize long texts in different styles (bullet points, executive summary, ELI5).
**Setup:**
1. Create a prompt with {style} and {text} variables
2. Define styles: "bullet_points", "executive_summary", "eli5", "one_sentence"
3. Build LCEL chain, test all four styles on the same input text
4. Use batch() to generate all summaries at once for efficiency
**Key concepts:** PromptTemplate variables, batch() for parallel calls
**Hints:**
- Use batch() to generate all styles simultaneously — much faster than sequential
- Experiment with max_tokens to control output length per style
- Try different temperatures: 0 for factual, 0.7 for ELI5 creative tone
**Extension:** Add a web scraper to fetch article text from URLs automatically

---

## Project 3: Text Classifier
**Goal:** Classify text into categories (news topic, sentiment, language detection).
**Setup:**
1. Define categories clearly in system prompt with examples
2. Use JsonOutputParser to get structured classification output
3. Test with 10+ sample texts from different categories
4. Build a batch classifier for CSV input
**Key concepts:** JsonOutputParser, structured output, category definition
**Hints:**
- Include category definitions in the prompt to reduce ambiguity
- Ask for confidence scores alongside the category label
- Use batch() to classify multiple texts efficiently in parallel
**Extension:** Build a CSV pipeline that reads input, classifies each row, writes results

---

## Project 4: SQL Chain
**Goal:** Natural language to SQL query generator with execution.
**Setup:**
1. Install: pip install langchain-community sqlalchemy
2. Create a SQLite database with sample data (employees, sales, etc.)
3. Build prompt that includes table schema description in system message
4. Parse SQL output and execute against database, show results
**Key concepts:** Prompt engineering for code generation, output parsing
**Hints:**
- Include table schemas and sample rows in the system prompt
- Validate generated SQL before execution using regex or a try/except block
- Handle edge cases: invalid queries, empty results, SQL injection attempts
**Extension:** Add error recovery — if SQL execution fails, ask model to fix the query

---

## Project 5: Chatbot with Memory
**Goal:** Build a persistent multi-turn chatbot that remembers conversation context.
**Setup:**
1. Use RunnableWithMessageHistory + InMemoryChatMessageHistory
2. Implement session management: each user gets a unique session_id
3. Add a CLI loop for interactive conversation with the bot
4. Display message count to show memory growing over the session
**Key concepts:** ChatMessageHistory, RunnableWithMessageHistory, MessagesPlaceholder
**Hints:**
- Implement a /clear command to reset history within CLI loop
- Implement a /history command to display all stored messages
- Save/load history to JSON file for cross-session persistence
**Extension:** Add user profiles (name, preferences) stored per session_id in a dict

---

## Project 6: Structured Data Extractor
**Goal:** Extract structured information from unstructured text (CVs, emails, articles).
**Setup:**
1. Define a Pydantic model for the target structure (e.g., PersonProfile, JobPosting)
2. Use with_structured_output() or PydanticOutputParser for clean extraction
3. Test on real-world examples: job postings from websites, news article headers
4. Handle missing fields gracefully
**Key concepts:** PydanticOutputParser, Pydantic models, with_structured_output()
**Hints:**
- Use Optional[str] = None for fields that may not always be present in input
- Add descriptive Field(description="...") to guide the model accurately
- Test with messy, poorly formatted real-world input texts to check robustness
**Extension:** Build a batch extractor that processes multiple documents and exports CSV

---

## Project 7: Multi-Language Translator
**Goal:** Translate text to multiple languages simultaneously using parallel chains.
**Setup:**
1. Create a prompt with {text} and {target_language} variables
2. Use RunnableParallel to run all translations at once in a single call
3. Output a dictionary mapping language name to translated text
4. Measure and compare latency: parallel vs sequential approaches
**Key concepts:** RunnableParallel, batch(), performance comparison
**Hints:**
- Test with 5+ target languages to see parallelism benefit
- Measure time: parallel should be 4-5x faster than sequential for 5 languages
- Add language detection as a pre-processing step to identify source language
**Extension:** Add back-translation (translate back to English) to verify accuracy

---

## Project 8: Document Formatter
**Goal:** Reformat documents into different styles (formal, casual, technical, marketing).
**Setup:**
1. Create a style-transformation prompt with {original_text} and {target_style} variables
2. Define 4+ output styles with examples in the system message
3. Build a formatting pipeline with validation of word count constraints
4. Test on the same document with all 4 styles
**Key concepts:** Few-shot prompting, style transfer, output validation
**Hints:**
- Use few-shot examples to define each style clearly with concrete samples
- Add a verification step: re-read output and score style compliance (1-5)
- Consider word count constraints per style (e.g., marketing = 50 words max)
**Extension:** Add custom style definitions that users can provide as freeform descriptions

---

## Project 9: Sentiment Analyzer
**Goal:** Analyze sentiment with confidence scores and detailed reasoning.
**Setup:**
1. Use PydanticOutputParser with a SentimentResult schema
2. Schema fields: sentiment (str), score (float 0-1), reasoning (str), key_phrases (List[str])
3. Test on product reviews, social media posts, news headlines
4. Batch process 10+ examples
**Key concepts:** Pydantic schemas, structured output, batch processing
**Hints:**
- Include aspect-based sentiment: score price, quality, and service separately
- Test edge cases: sarcasm ("Oh great, another outage..."), mixed sentiment, neutral text
- Batch process a dataset of 20 reviews and compute aggregate statistics
**Extension:** Add trend analysis: compare sentiment across multiple reviews over time

---

## Project 10: Research Assistant
**Goal:** Multi-step research pipeline: query -> plan -> research -> synthesize -> format.
**Setup:**
1. Step 1: Generate research plan from user query — output list of sub-questions as JSON
2. Step 2: Answer each sub-question with separate LLM calls (use batch())
3. Step 3: Synthesize all answers into coherent final report
4. Use LCEL chains for each step, connect them with | operator
**Key concepts:** Multi-step chaining, RunnableParallel, StrOutputParser, batch()
**Hints:**
- Parse Step 1 output as JSON list of questions using JsonOutputParser
- Use batch() in Step 2 to answer all sub-questions in parallel
- Add source/citation tracking placeholder in the final synthesis step
**Extension:** Add a web search tool (via DuckDuckGo) to fetch real information per question

---

## Project 11: Code Review Bot
**Goal:** Automated code review with structured, actionable feedback.
**Setup:**
1. Define Pydantic schema: CodeReview with issues (List[str]), suggestions (List[str]), score (int), summary (str)
2. System prompt defines review criteria: readability, efficiency, security, best practices
3. Use with_structured_output(CodeReview) for clean, validated parsing
4. Test on intentionally buggy code snippets with known issues
**Key concepts:** Structured output, code analysis prompts, Pydantic validation
**Hints:**
- Specify the programming language in the prompt for language-specific advice
- Define severity levels in the schema: critical, warning, info per issue
- Test on code with SQL injection, hardcoded credentials, O(n^2) loops
**Extension:** Integrate with git pre-commit hooks to automatically review staged changes

---

## Project 12: Streaming Story Generator
**Goal:** Generate creative stories with real-time token streaming display.
**Setup:**
1. Use ChatOpenAI with streaming=True
2. Implement stream() loop to display tokens as they are generated
3. Add {genre}, {length}, {protagonist}, and {setting} variables to prompt
4. Display running word count as the story generates
**Key concepts:** Streaming, creative prompting, real-time output
**Hints:**
- Show a word counter that updates every 50 tokens during streaming
- Allow user to specify genre (fantasy, sci-fi, mystery), protagonist name, setting
- Save completed stories automatically to a .txt file with timestamp in filename
**Extension:** Add interactive branching: after 200 words, pause and ask user to choose direction