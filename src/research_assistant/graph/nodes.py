"""LangGraph node functions."""

from typing import Any

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
    return _supervisor.process(state)


def researcher_node(state: ResearchState) -> dict[str, Any]:
    """Researcher searches knowledge base."""
    return _researcher.process(state)


def writer_node(state: ResearchState) -> dict[str, Any]:
    """Writer generates response."""
    return _writer.process(state)


def critic_node(state: ResearchState) -> dict[str, Any]:
    """Critic reviews response."""
    return _critic.process(state)


def should_continue(state: ResearchState) -> str:
    """Determine if workflow should continue."""
    next_agent = state.get("next", "FINISH")
    if next_agent == "FINISH":
        return "end"
    return next_agent
