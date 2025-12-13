"""LangGraph state schema."""

from typing import TypedDict, Any


class ResearchState(TypedDict, total=False):
    """State for the research workflow."""

    # Input
    query: str

    # Research findings
    findings: str
    sources: list[dict[str, Any]]

    # Generated response
    response: str

    # Critique results
    critique: dict[str, Any]

    # Control flow
    next: str
    iteration: int
    revision_requested: bool

    # Errors
    error: str | None
