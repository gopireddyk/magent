"""Supervisor agent - orchestrates the workflow."""

from typing import Any, Literal

from research_assistant.agents.base import BaseAgent
from research_assistant.config.prompts import SUPERVISOR_PROMPT


class SupervisorAgent(BaseAgent):
    """Agent that coordinates the research workflow."""

    VALID_ROUTES = {"researcher", "writer", "critic", "FINISH"}

    def __init__(self):
        super().__init__("supervisor")

    def process(self, state: dict[str, Any]) -> dict[str, Any]:
        """Decide which agent should act next."""
        query = state.get("query", "")
        has_findings = bool(state.get("findings"))
        has_response = bool(state.get("response"))
        has_critique = bool(state.get("critique"))

        # Simple routing logic
        if not has_findings:
            next_agent = "researcher"
        elif not has_response:
            next_agent = "writer"
        elif not has_critique:
            next_agent = "critic"
        else:
            critique = state.get("critique", {})
            if critique.get("approved", False):
                next_agent = "FINISH"
            else:
                next_agent = "writer"
                state["revision_requested"] = True

        # Store supervisor decision in state (prompt available if needed later)
        state["supervisor_prompt"] = SUPERVISOR_PROMPT.format(
            state=state, query=query
        )

        return {"next": next_agent}

    def route(
        self, state: dict[str, Any]
    ) -> Literal["researcher", "writer", "critic", "FINISH"]:
        """Return the next agent to invoke."""
        result = self.process(state)
        return result["next"]
