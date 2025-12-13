"""Main LangGraph workflow."""

from functools import lru_cache
from typing import Any

from langgraph.graph import StateGraph, END

from research_assistant.config import get_settings
from research_assistant.core.exceptions import ResearchAssistantError
from research_assistant.graph.state import ResearchState
from research_assistant.graph.nodes import (
    supervisor_node,
    researcher_node,
    writer_node,
    critic_node,
    should_continue,
)


def build_research_graph() -> StateGraph:
    """Build the research workflow graph."""
    graph = StateGraph(ResearchState)

    # Add nodes
    graph.add_node("supervisor", supervisor_node)
    graph.add_node("researcher", researcher_node)
    graph.add_node("writer", writer_node)
    graph.add_node("critic", critic_node)

    # Set entry point
    graph.set_entry_point("supervisor")

    # Add conditional edges from supervisor
    graph.add_conditional_edges(
        "supervisor",
        should_continue,
        {
            "researcher": "researcher",
            "writer": "writer",
            "critic": "critic",
            "end": END,
        },
    )

    # Add edges back to supervisor
    graph.add_edge("researcher", "supervisor")
    graph.add_edge("writer", "supervisor")
    graph.add_edge("critic", "supervisor")

    return graph


@lru_cache
def get_research_workflow():
    """Get compiled research workflow."""
    graph = build_research_graph()
    return graph.compile()


def run_research(query: str) -> dict[str, Any]:
    """Run the research workflow."""
    workflow = get_research_workflow()
    settings = get_settings()

    initial_state: ResearchState = {
        "query": query,
        "iteration": 0,
        "revision_requested": False,
    }

    try:
        result = workflow.invoke(initial_state)
        return {
            "query": query,
            "response": result.get("response", ""),
            "sources": result.get("sources", []),
            "iterations": result.get("iteration", 0),
        }
    except Exception as exc:
        # Surface error gracefully to callers (UI/CLI)
        return {
            "query": query,
            "response": "",
            "sources": [],
            "iterations": initial_state["iteration"],
            "error": f"Workflow failed: {exc}",
        }
