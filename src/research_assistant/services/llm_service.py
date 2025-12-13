"""Ollama LLM service."""

from functools import lru_cache
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, SystemMessage
from tenacity import retry, stop_after_attempt, wait_fixed

from research_assistant.config import get_settings
from research_assistant.core.exceptions import LLMError


class LLMService:
    """Service for LLM interactions via Ollama."""

    def __init__(self):
        settings = get_settings()
        self.model_name = settings.ollama_model
        self.base_url = settings.ollama_base_url
        self.timeout = settings.ollama_timeout
        self.temperature = settings.temperature
        self._llm: ChatOllama | None = None

    @property
    def llm(self) -> ChatOllama:
        """Lazy load the LLM."""
        if self._llm is None:
            try:
                self._llm = ChatOllama(
                    model=self.model_name,
                    base_url=self.base_url,
                    temperature=self.temperature,
                    timeout=self.timeout,
                )
            except Exception as e:
                raise LLMError(f"Failed to initialize LLM: {e}")
        return self._llm

    @retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
    def generate(self, prompt: str, system_prompt: str | None = None) -> str:
        """Generate a response from the LLM with basic retry."""
        try:
            messages = []
            if system_prompt:
                messages.append(SystemMessage(content=system_prompt))
            messages.append(HumanMessage(content=prompt))

            response = self.llm.invoke(messages)
            return response.content
        except Exception as e:
            raise LLMError(f"LLM generation failed: {e}")

    def stream(self, prompt: str, system_prompt: str | None = None):
        """Stream a response from the LLM."""
        try:
            messages = []
            if system_prompt:
                messages.append(SystemMessage(content=system_prompt))
            messages.append(HumanMessage(content=prompt))

            for chunk in self.llm.stream(messages):
                yield chunk.content
        except Exception as e:
            raise LLMError(f"LLM streaming failed: {e}")

    def is_available(self) -> bool:
        """Check if the LLM service is available."""
        try:
            self.llm.invoke([HumanMessage(content="ping")])
            return True
        except Exception:
            return False


@lru_cache
def get_llm_service() -> LLMService:
    """Get cached LLM service instance."""
    return LLMService()
