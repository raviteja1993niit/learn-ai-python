"""
app.py — Streamlit chatbot UI demonstrating LangChain vs LangGraph.

Two modes (selectable in sidebar):
  • LangChain  — LCEL chain with in-memory ChatMessageHistory
  • LangGraph  — Compiled StateGraph with MemorySaver checkpointing
"""
import uuid

import streamlit as st
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from src.graph import CopilotGraph
from src.llm import COPILOT_MODELS, DEFAULT_MODEL, CopilotChatModel, get_gh_token

# ── Page config ───────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Copilot Chatbot",
    page_icon="🤖",
    layout="wide",
)

# ── Session state bootstrap ───────────────────────────────────────────────────
if "session_id"      not in st.session_state: st.session_state["session_id"]      = str(uuid.uuid4())
if "lc_history"      not in st.session_state: st.session_state["lc_history"]      = []   # LangChain messages
if "lg_graph"        not in st.session_state: st.session_state["lg_graph"]        = None  # CopilotGraph instance
if "lg_display"      not in st.session_state: st.session_state["lg_display"]      = []   # [(role, content)]
if "current_model"   not in st.session_state: st.session_state["current_model"]   = DEFAULT_MODEL
if "current_mode"    not in st.session_state: st.session_state["current_mode"]    = "LangGraph"

# ── Sidebar ───────────────────────────────────────────────────────────────────
with st.sidebar:
    st.header("⚙️ Settings")

    # Token
    _token = get_gh_token()
    if _token:
        st.success(f"🔑 Token auto-detected from gh CLI")
    else:
        st.error("❌ No token found — run `gh auth login`")

    # Model
    model_choice = st.selectbox(
        "Model",
        COPILOT_MODELS,
        index=COPILOT_MODELS.index(DEFAULT_MODEL),
        help="All models served via api.githubcopilot.com",
    )

    # System prompt
    system_prompt = st.text_area(
        "System Prompt",
        value="You are a helpful, concise AI assistant powered by GitHub Copilot.",
        height=100,
    )

    # Mode
    st.markdown("---")
    mode = st.radio(
        "Framework Mode",
        ["LangChain", "LangGraph"],
        index=1,
        help="Switch between LangChain LCEL chain and LangGraph stateful graph.",
    )

    # Reset on model/mode change
    if model_choice != st.session_state["current_model"] or mode != st.session_state["current_mode"]:
        st.session_state["lc_history"]    = []
        st.session_state["lg_graph"]      = None
        st.session_state["lg_display"]    = []
        st.session_state["session_id"]    = str(uuid.uuid4())
        st.session_state["current_model"] = model_choice
        st.session_state["current_mode"]  = mode

    # Clear
    if st.button("🗑️ Clear Chat", use_container_width=True):
        st.session_state["lc_history"]  = []
        st.session_state["lg_graph"]    = None
        st.session_state["lg_display"]  = []
        st.session_state["session_id"]  = str(uuid.uuid4())
        st.rerun()

    st.markdown("---")

    # Mode info
    if mode == "LangChain":
        st.markdown("""
**🔗 LangChain Mode**

Uses `ChatPromptTemplate` + `LCEL chain` + `ChatMessageHistory`

```
Prompt → LLM → StrOutputParser
```

History stored in `st.session_state` as a plain list of LangChain messages.
""")
    else:
        st.markdown("""
**🕸️ LangGraph Mode**

Uses a compiled `StateGraph` with `MemorySaver` checkpointing.

```
START → [chatbot node] → END
```

State (full message list) is stored inside the graph's checkpointer, keyed by `thread_id`.
""")
        st.code(CopilotGraph.ascii_diagram(), language=None)


# ── LLM factory ───────────────────────────────────────────────────────────────
@st.cache_resource(show_spinner=False)
def get_llm(model: str, temperature: float = 0.2) -> CopilotChatModel:
    return CopilotChatModel(model=model, temperature=temperature)


# ── Header ────────────────────────────────────────────────────────────────────
col1, col2 = st.columns([3, 1])
with col1:
    framework_badge = "🔗 LangChain" if mode == "LangChain" else "🕸️ LangGraph"
    st.title(f"🤖 GitHub Copilot Chatbot")
    st.caption(f"**{framework_badge}** · Model: `{model_choice}` · Session: `{st.session_state['session_id'][:8]}…`")

with col2:
    if mode == "LangGraph":
        st.info("Stateful graph\nMemorySaver checkpointing", icon="🕸️")
    else:
        st.info("LCEL chain\nIn-memory history", icon="🔗")


# ══════════════════════════════════════════════════════════════════════════════
#  LangChain Mode
# ══════════════════════════════════════════════════════════════════════════════
def render_langchain_chat():
    llm = get_llm(model_choice)

    # LCEL chain: system + history + human → LLM → string
    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}"),
    ])
    chain = prompt | llm | StrOutputParser()

    # Display history
    for msg in st.session_state["lc_history"]:
        role = "user" if isinstance(msg, HumanMessage) else "assistant"
        with st.chat_message(role):
            st.write(msg.content)

    # Input
    user_input = st.chat_input("Type a message…", disabled=not _token)
    if user_input:
        with st.chat_message("user"):
            st.write(user_input)

        with st.chat_message("assistant"):
            with st.spinner(f"Thinking with **{model_choice}**…"):
                try:
                    response = chain.invoke({
                        "input":   user_input,
                        "history": st.session_state["lc_history"],
                    })
                    st.write(response)
                    # Append to history
                    st.session_state["lc_history"].append(HumanMessage(content=user_input))
                    st.session_state["lc_history"].append(AIMessage(content=response))
                except Exception as e:
                    st.error(f"❌ {e}")

    # Stats
    if st.session_state["lc_history"]:
        turns = len(st.session_state["lc_history"]) // 2
        st.caption(f"💬 {turns} turn{'s' if turns != 1 else ''} · history stored in `st.session_state['lc_history']`")


# ══════════════════════════════════════════════════════════════════════════════
#  LangGraph Mode
# ══════════════════════════════════════════════════════════════════════════════
def render_langgraph_chat():
    llm = get_llm(model_choice)

    # Lazily build/reuse the graph (1 per session)
    if st.session_state["lg_graph"] is None:
        # system_prompt is injected inside the graph node per-call — no LLM priming needed
        st.session_state["lg_graph"] = CopilotGraph(llm, system_prompt=system_prompt)

    graph: CopilotGraph = st.session_state["lg_graph"]

    # Display chat from our display list (avoids showing SystemMessage)
    for role, content in st.session_state["lg_display"]:
        with st.chat_message(role):
            st.write(content)

    # Input
    user_input = st.chat_input("Type a message…", disabled=not _token)
    if user_input:
        with st.chat_message("user"):
            st.write(user_input)

        with st.chat_message("assistant"):
            with st.spinner(f"Thinking with **{model_choice}** via LangGraph…"):
                try:
                    response = graph.chat(user_input, thread_id=st.session_state["session_id"])
                    st.write(response)
                    st.session_state["lg_display"].append(("user",      user_input))
                    st.session_state["lg_display"].append(("assistant", response))
                except Exception as e:
                    st.error(f"❌ {e}")

    # Graph state info
    if st.session_state["lg_display"]:
        turns   = len(st.session_state["lg_display"]) // 2
        history = graph.get_history(st.session_state["session_id"])
        st.caption(
            f"💬 {turns} turn{'s' if turns != 1 else ''} · "
            f"{len(history)} messages in graph state · "
            f"thread_id: `{st.session_state['session_id'][:8]}…`"
        )

        with st.expander("🔍 Inspect LangGraph State", expanded=False):
            st.markdown("**Full message history stored in `MemorySaver`:**")
            for i, msg in enumerate(history):
                role = type(msg).__name__.replace("Message", "")
                st.markdown(f"`[{i}]` **{role}**: {str(msg.content)[:200]}")


# ── Render active mode ────────────────────────────────────────────────────────
if not _token:
    st.warning("⚠️ No GitHub token found. Run `gh auth login` in your terminal.")
elif mode == "LangChain":
    render_langchain_chat()
else:
    render_langgraph_chat()
