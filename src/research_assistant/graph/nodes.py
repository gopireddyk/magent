"""LangGraph node functions."""

from typing import Any

from research_assistant.config import get_settings
from research_assistant.graph.state import ResearchState
from research_assistant.agents import (
    SupervisorAgent,
    ResearcherAgent,
    WriterAgent,
    CriticAgent,
)

# Singleton agents
_supervisor = SupervisorAgent()
_researcher = ResearcherAgent()
_writer = WriterAgent()
_critic = CriticAgent()


def supervisor_node(state: ResearchState) -> dict[str, Any]:
    """Supervisor decides next step."""
    try:
        return _supervisor.process(state)
    except Exception as exc:
        return {"error": f"supervisor failed: {exc}", "next": "FINISH"}


def researcher_node(state: ResearchState) -> dict[str, Any]:
    """Researcher searches knowledge base."""
    try:
        return _researcher.process(state)
    except Exception as exc:
        return {"error": f"researcher failed: {exc}", "next": "FINISH"}


def writer_node(state: ResearchState) -> dict[str, Any]:
    """Writer generates response."""
    try:
        return _writer.process(state)
    except Exception as exc:
        return {"error": f"writer failed: {exc}", "next": "FINISH"}


def critic_node(state: ResearchState) -> dict[str, Any]:
    """Critic reviews response."""
    try:
        return _critic.process(state)
    except Exception as exc:
        return {"error": f"critic failed: {exc}", "next": "FINISH"}


def should_continue(state: ResearchState) -> str:
    """Determine if workflow should continue."""
    settings = get_settings()
    max_iterations = settings.max_iterations

    # Guardrail: stop if iterations exceed cap
    if state.get("iteration", 0) >= max_iterations:
        return "end"

    next_agent = state.get("next", "FINISH")
    if next_agent == "FINISH":
        return "end"
    return next_agent
