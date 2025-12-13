"""Writer agent - synthesizes responses."""

from typing import Any

from research_assistant.agents.base import BaseAgent
from research_assistant.config.prompts import WRITER_PROMPT


class WriterAgent(BaseAgent):
    """Agent that writes research responses."""

    def __init__(self):
        super().__init__("writer")

    def process(self, state: dict[str, Any]) -> dict[str, Any]:
        """Generate a response based on findings."""
        query = state.get("query", "")
        findings = state.get("findings", "")
        revision_requested = state.get("revision_requested", False)
        previous_critique = state.get("critique", {})

        if revision_requested and previous_critique:
            findings += f"\n\nPrevious feedback: {previous_critique.get('feedback', '')}"

        prompt = WRITER_PROMPT.format(query=query, findings=findings)
        response = self._generate(prompt)

        return {
            "response": response,
            "revision_requested": False,
        }
