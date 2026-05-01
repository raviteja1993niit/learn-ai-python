"""
graph.py — LangGraph conversation graph for GitHub Copilot chatbot.

Graph structure:
  START ──► [chatbot] ──► END

The chatbot node calls the LLM with the full message history.
MemorySaver checkpointer persists state across Streamlit reruns using thread_id.
"""
from __future__ import annotations

from typing import Annotated

from langchain_core.messages import BaseMessage
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict

from src.llm import CopilotChatModel


class ChatState(TypedDict):
    """State container for the conversation graph."""
    messages: Annotated[list[BaseMessage], add_messages]


class CopilotGraph:
    """
    Compiled LangGraph chatbot graph with in-memory checkpointing.
    One instance per Streamlit session (stored in st.session_state).

    system_prompt is prepended to every LLM call inside the node so we
    never invoke the API with a system-only message (which returns 403).
    """

    def __init__(self, llm: CopilotChatModel, system_prompt: str = "") -> None:
        self.llm = llm
        self.system_prompt = system_prompt
        self._memory = MemorySaver()
        self._graph = self._build()

    def _build(self):
        from langchain_core.messages import SystemMessage as _SystemMessage

        def chatbot_node(state: ChatState) -> dict:
            messages = list(state["messages"])
            # Prepend system prompt without storing it in graph state
            if self.system_prompt:
                messages = [_SystemMessage(content=self.system_prompt)] + messages
            response = self.llm.invoke(messages)
            return {"messages": [response]}

        builder = StateGraph(ChatState)
        builder.add_node("chatbot", chatbot_node)
        builder.add_edge(START, "chatbot")
        builder.add_edge("chatbot", END)
        return builder.compile(checkpointer=self._memory)

    def chat(self, user_input: str, thread_id: str) -> str:
        """
        Send a message and return the assistant reply.
        The graph automatically appends to the stored history for this thread_id.
        """
        from langchain_core.messages import HumanMessage

        config = {"configurable": {"thread_id": thread_id}}
        result = self._graph.invoke(
            {"messages": [HumanMessage(content=user_input)]},
            config=config,
        )
        return result["messages"][-1].content

    def get_history(self, thread_id: str) -> list[BaseMessage]:
        """Return the full message history stored in the graph state."""
        config = {"configurable": {"thread_id": thread_id}}
        snapshot = self._graph.get_state(config)
        return snapshot.values.get("messages", []) if snapshot else []

    def clear(self, thread_id: str) -> None:
        """Clear conversation history for a thread by reinitialising the graph."""
        self._memory = MemorySaver()
        self._graph = self._build()

    @staticmethod
    def ascii_diagram() -> str:
        return (
            "┌─────────────────────────────────┐\n"
            "│         LangGraph Flow          │\n"
            "├─────────────────────────────────┤\n"
            "│  [START]                        │\n"
            "│     │                           │\n"
            "│     ▼                           │\n"
            "│  [chatbot]  ◄── LLM invoke      │\n"
            "│   • reads full message history  │\n"
            "│   • appends AI reply to state   │\n"
            "│     │                           │\n"
            "│     ▼                           │\n"
            "│   [END]                         │\n"
            "└─────────────────────────────────┘"
        )
