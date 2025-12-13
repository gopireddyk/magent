"""Tests for LangGraph workflow utilities."""

from research_assistant.graph.nodes import should_continue
from research_assistant.graph import workflow


def test_should_continue_routes_to_end():
    """Workflow stops when next is FINISH."""
    state = {"next": "FINISH"}
    assert should_continue(state) == "end"

    state = {"next": "writer"}
    assert should_continue(state) == "writer"


def test_run_research_uses_compiled_workflow(monkeypatch):
    """run_research returns structured result from workflow invoke."""

    class FakeWorkflow:
        def invoke(self, state):
            return {"response": "ok", "sources": [{"source": "file.txt"}], "iteration": 2}

    monkeypatch.setattr(workflow, "get_research_workflow", lambda: FakeWorkflow())

    result = workflow.run_research("Question?")
    assert result["response"] == "ok"
    assert result["iterations"] == 2
    assert result["sources"][0]["source"] == "file.txt"
