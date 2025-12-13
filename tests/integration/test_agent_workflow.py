"""Integration tests for agent workflow."""

import pytest

from research_assistant.agents import ResearcherAgent, WriterAgent, CriticAgent
from research_assistant.core.schemas import DocumentMetadata, RetrievedDocument


class _FakeVectorStore:
    def search(self, query: str):
        metadata = DocumentMetadata(
            source="doc.txt",
            filename="doc.txt",
            file_type=".txt",
        )
        return [
            RetrievedDocument(
                id="1",
                content="content about ML",
                metadata=metadata,
                score=0.9,
            )
        ]


@pytest.mark.integration
def test_complete_agent_flow(monkeypatch):
    """Simulate research -> write -> critique flow."""
    researcher = ResearcherAgent()
    researcher._vector_store = _FakeVectorStore()
    writer = WriterAgent()
    critic = CriticAgent()

    monkeypatch.setattr(
        CriticAgent,
        "_generate",
        lambda self, prompt, system_prompt=None: "Approved response.",
    )

    state: dict = {"query": "What is ML?"}
    state.update(researcher.process(state))
    state.update(writer.process(state))
    state.update(critic.process(state))

    assert "response" in state
    assert state["critique"]["approved"] is True


@pytest.mark.integration
def test_revision_requested(monkeypatch):
    """Critic requesting revision loops back to writer."""
    researcher = ResearcherAgent()
    researcher._vector_store = _FakeVectorStore()
    writer = WriterAgent()
    critic = CriticAgent()

    monkeypatch.setattr(
        CriticAgent,
        "_generate",
        lambda self, prompt, system_prompt=None: "Needs revision.",
    )

    state: dict = {"query": "What is ML?"}
    state.update(researcher.process(state))
    state.update(writer.process(state))
    critique_state = critic.process(state)
    assert critique_state["critique"]["approved"] is False
    assert critique_state["iteration"] == 1
