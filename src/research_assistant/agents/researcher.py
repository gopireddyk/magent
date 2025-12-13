"""Researcher agent - searches knowledge base."""

from typing import Any

from research_assistant.agents.base import BaseAgent
from research_assistant.config.prompts import RESEARCHER_PROMPT
from research_assistant.tools.search import search_documents, format_search_results
from research_assistant.services import get_vector_store


class ResearcherAgent(BaseAgent):
    """Agent that searches the knowledge base."""

    def __init__(self):
        super().__init__("researcher")
        self._vector_store = get_vector_store()

    def process(self, state: dict[str, Any]) -> dict[str, Any]:
        """Search for relevant documents."""
        query = state.get("query", "")

        documents = self._vector_store.search(query)

        if not documents:
            findings = "No relevant documents found in the knowledge base."
        else:
            docs_text = format_search_results(documents)
            prompt = RESEARCHER_PROMPT.format(query=query, documents=docs_text)
            findings = self._generate(prompt)

        return {
            "findings": findings,
            "sources": [doc.model_dump() for doc in documents],
        }
