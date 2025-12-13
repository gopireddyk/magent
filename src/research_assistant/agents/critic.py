"""Critic agent - reviews responses."""

from typing import Any

from research_assistant.agents.base import BaseAgent
from research_assistant.config.prompts import CRITIC_PROMPT


class CriticAgent(BaseAgent):
    """Agent that critiques research responses."""

    def __init__(self):
        super().__init__("critic")

    def process(self, state: dict[str, Any]) -> dict[str, Any]:
        """Review the response quality."""
        query = state.get("query", "")
        response = state.get("response", "")
        iteration = state.get("iteration", 0)

        prompt = CRITIC_PROMPT.format(query=query, response=response)
        critique_text = self._generate(prompt)

        approved = any(
            word in critique_text.lower()
            for word in ["approved", "satisfactory", "good", "well-written"]
        )

        if iteration >= 2:
            approved = True

        return {
            "critique": {
                "approved": approved,
                "feedback": critique_text,
            },
            "iteration": iteration + 1,
        }
