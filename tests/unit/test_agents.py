"""Tests for AI Agents."""

from research_assistant.agents.supervisor import SupervisorAgent
from research_assistant.agents.researcher import ResearcherAgent
from research_assistant.agents.writer import WriterAgent
from research_assistant.agents.critic import CriticAgent
from research_assistant.core.schemas import DocumentMetadata, RetrievedDocument


class FakeVectorStore:
    """Fake vector store for researcher tests."""

    def search(self, query: str):
        metadata = DocumentMetadata(
            source="file.txt",
            filename="file.txt",
            file_type=".txt",
        )
        return [
            RetrievedDocument(
                id="1",
                content="content about machine learning",
                metadata=metadata,
                score=0.9,
            )
        ]


def test_supervisor_routing():
    """Supervisor chooses next agent based on state."""
    sup = SupervisorAgent()

    state = {"query": "What is ML?"}
    assert sup.process(state)["next"] == "researcher"

    state = {"query": "?", "findings": "facts"}
    assert sup.process(state)["next"] == "writer"

    state = {"query": "?", "findings": "facts", "response": "answer"}
    assert sup.process(state)["next"] == "critic"

    state = {
        "query": "?",
        "findings": "facts",
        "response": "answer",
        "critique": {"approved": True},
    }
    assert sup.process(state)["next"] == "FINISH"


def test_researcher_returns_sources(monkeypatch, mock_generate):
    """Researcher returns findings and sources."""
    researcher = ResearcherAgent()
    researcher._vector_store = FakeVectorStore()

    result = researcher.process({"query": "ML?"})
    assert "findings" in result
    assert len(result["sources"]) == 1


def test_writer_resets_revision_flag(mock_generate):
    """Writer clears revision flag after processing."""
    writer = WriterAgent()
    state = {"query": "Q", "findings": "facts", "revision_requested": True}

    result = writer.process(state)
    assert result["revision_requested"] is False
    assert "response" in result


def test_critic_approval_logic(monkeypatch):
    """Critic approves when feedback contains approval keywords."""
    def _mock_generate(self, prompt: str, system_prompt=None):
        return "This response is approved and satisfactory."

    monkeypatch.setattr(CriticAgent, "_generate", _mock_generate)
    critic = CriticAgent()

    result = critic.process({"query": "Q", "response": "A", "iteration": 0})
    assert result["critique"]["approved"] is True
