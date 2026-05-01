# OpenAI API — Practical Projects (12 Projects)

`ash
pip install openai python-dotenv tiktoken streamlit requests pypdf2 pydub textstat
`

---

## Project 1 — Interactive CLI Chatbot
**Goal**: Terminal chatbot with history, commands, and token tracking.
**Features**: /clear (reset), /save (export JSON), /tokens (usage), /quit
**Key concepts**: messages list, tiktoken, file I/O
**Hint**: Append to history list each turn; trim oldest messages if >4000 tokens
`python
history = [{"role":"system","content":"You are helpful."}]
while True:
    user = input("You: ")
    if user=="/quit": break
    history.append({"role":"user","content":user})
    r = client.chat.completions.create(model="gpt-4o-mini", messages=history)
    reply = r.choices[0].message.content
    history.append({"role":"assistant","content":reply})
    print(f"AI: {reply}")
`

---

## Project 2 — Document Summariser (Map-Reduce)
**Goal**: Summarise long PDFs/TXT files using chunking.
**Features**: chunk by tokens, map (summarise each chunk), reduce (final summary)
**Key concepts**: tiktoken chunking, prompt engineering, pypdf2
**Hint**: Map prompt = "Summarise this section in 3 sentences."; Reduce prompt = "Write an executive summary from these section summaries."
**Expected output**: Executive summary + bullet-point key findings

---

## Project 3 — Mini RAG Q&A System
**Goal**: Answer questions about local documents using embeddings.
**Features**: index 10+ text files, top-3 retrieval, cited answers
**Key concepts**: embeddings, cosine similarity, context injection
**Hint**:
`python
# Index: {filename: (text, vector)}
# Query: embed question -> cosine sort -> inject top-3 as context -> ask GPT
context = "\n\n".join(text for text,_ in top_chunks)
msgs = [{"role":"system","content":f"Answer using this context:\n{context}"},
        {"role":"user","content":question}]
`

---

## Project 4 — Image Analyser with Structured Extraction
**Goal**: Upload any image; get structured JSON analysis.
**Features**: objects, scene, colours, mood, text found — output to CSV
**Key concepts**: vision API, base64, Pydantic structured outputs
**Hint**: Use client.beta.chat.completions.parse() with a Pydantic model that has Optional fields

---

## Project 5 — TTS Podcast Generator
**Goal**: Convert blog post text to podcast-style MP3.
**Features**: rewrite in conversational style, multi-voice paragraphs, audio concat
**Key concepts**: TTS API, pydub AudioSegment, text splitting
**Hint**:
`python
from pydub import AudioSegment
segments = []
for i, para in enumerate(paragraphs):
    client.audio.speech.create(model="tts-1", voice="nova", input=para).stream_to_file(f"seg{i}.mp3")
    segments.append(AudioSegment.from_mp3(f"seg{i}.mp3"))
sum(segments).export("podcast.mp3", format="mp3")
`

---

## Project 6 — Semantic Search Engine
**Goal**: Searchable knowledge base with embeddings.
**Features**: 100+ passages indexed, CLI search, top-5 results, follow-up answers
**Key concepts**: batch embeddings, numpy similarity, retrieval + generation
**Hint**: Embed in batches of 20 to respect rate limits; cache embeddings to JSON file

---

## Project 7 — Multi-Tool Agent
**Goal**: Conversational agent with 4 tools.
**Tools**: calculator, get_time(tz), save_note(content), web_search(query)
**Features**: agentic loop, tool logging, multi-step reasoning
**Key concepts**: function calling, dispatch loop, tool_choice="auto"
**Hint**: Keep running until finish_reason == "stop"; log each tool call with args + result

---

## Project 8 — Automated Code Review Bot
**Goal**: Review Python files for bugs, security, performance, style.
**Features**: severity ratings, batch directory review, markdown report
**Key concepts**: structured outputs, prompt engineering, file processing
**Hint**:
`python
class Issue(BaseModel):
    severity: str       # high/medium/low
    category: str       # bug/security/performance/style
    description: str
    suggestion: str
class Review(BaseModel):
    issues: list[Issue]
    overall_score: int  # 0-100
    summary: str
`

---

## Project 9 — Receipt / Invoice Parser
**Goal**: Extract structured data from receipt images.
**Features**: store, date, items (name/qty/price), totals — saves to CSV
**Key concepts**: vision API, structured output, batch processing
**Hint**: Use Optional[str] for fields that might be missing; handle multiple image formats

---

## Project 10 — Content Moderation Pipeline
**Goal**: Production-ready text moderation with logging.
**Features**: moderation API + GPT fallback for borderline cases, SQLite log, statistics
**Key concepts**: moderation API, decision thresholds, sqlite3, dashboard
**Hint**:
`python
import sqlite3, datetime
conn = sqlite3.connect("moderation.db")
conn.execute("CREATE TABLE IF NOT EXISTS logs(id INTEGER PRIMARY KEY, text TEXT, flagged BOOLEAN, cats TEXT, ts TEXT)")
def moderate(text):
    r = client.moderations.create(input=text).results[0]
    conn.execute("INSERT INTO logs VALUES(NULL,?,?,?,?)",
        (text[:200], r.flagged, str(r.categories), datetime.datetime.now().isoformat()))
    conn.commit()
    return r
`

---

## Project 11 — Streamlit Chat App
**Goal**: Polished web chat UI with model/temperature controls.
**Features**: chat interface, sidebar settings, token display, export JSON
**Key concepts**: Streamlit session_state, streaming, UI layout
**Hint**:
`python
import streamlit as st
if "messages" not in st.session_state:
    st.session_state.messages = []
if prompt := st.chat_input("Message"):
    st.session_state.messages.append({"role":"user","content":prompt})
    with st.chat_message("assistant"):
        # stream and collect response
        pass
`

---

## Project 12 — Style Transfer Writing Assistant
**Goal**: Rewrite text in multiple styles simultaneously.
**Styles**: formal, casual, Hemingway, Shakespearean, academic, emoji-rich
**Features**: 3-column side-by-side output, readability scores, CSV batch processing
**Key concepts**: parallel API calls (async), textstat, prompt engineering
**Hint**: Write system prompts like "Rewrite maintaining the exact meaning but in the style of Hemingway: short sentences, direct, no adverbs."
**Extension**: Add a Flesch-Kincaid readability score to each variant using textstat.flesch_reading_ease()