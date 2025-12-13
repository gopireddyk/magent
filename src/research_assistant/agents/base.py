"""Base agent class."""

from abc import ABC, abstractmethod
from typing import Any

from research_assistant.services import get_llm_service


class BaseAgent(ABC):
    """Abstract base class for all agents."""

    def __init__(self, name: str):
        self.name = name
        self._llm_service = get_llm_service()

    @abstractmethod
    def process(self, state: dict[str, Any]) -> dict[str, Any]:
        """Process the current state and return updates."""
        raise NotImplementedError

    def _generate(self, prompt: str, system_prompt: str | None = None) -> str:
        """Generate LLM response."""
        return self._llm_service.generate(prompt, system_prompt)

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(name='{self.name}')"
