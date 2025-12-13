"""Pytest configuration and fixtures."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path
from typing import Generator

import pytest


@pytest.fixture(autouse=True)
def reset_settings_cache():
    """Ensure settings cache is cleared between tests."""
    from research_assistant.config.settings import get_settings

    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture
def temp_dir() -> Generator[Path, None, None]:
    """Create a temporary directory for tests."""
    dir_path = Path(tempfile.mkdtemp())
    try:
        yield dir_path
    finally:
        shutil.rmtree(dir_path, ignore_errors=True)


@pytest.fixture
def sample_document(temp_dir: Path) -> Path:
    """Create a sample document file."""
    doc_path = temp_dir / "sample.txt"
    doc_path.write_text(
        "Machine learning enables systems to learn from data without being explicitly "
        "programmed. It powers recommendations, NLP, and computer vision."
    )
    return doc_path


@pytest.fixture
def mock_llm(monkeypatch):
    """Provide a mocked LLM client to avoid real calls."""
    from research_assistant.services import llm_service

    class _FakeResponse:
        def __init__(self, content: str):
            self.content = content

    class _FakeLLM:
        def invoke(self, messages):
            return _FakeResponse("Mocked LLM response.")

        def stream(self, messages):
            yield "Mocked chunk"

    fake_llm = _FakeLLM()
    monkeypatch.setattr(
        llm_service.LLMService,
        "llm",
        property(lambda self: fake_llm),
    )
    return fake_llm


@pytest.fixture
def mock_generate(monkeypatch):
    """Patch BaseAgent._generate to return deterministic text."""
    from research_assistant.agents.base import BaseAgent

    def _mock_generate(self, prompt: str, system_prompt: str | None = None) -> str:
        return "Mocked generation"

    monkeypatch.setattr(BaseAgent, "_generate", _mock_generate)
    return _mock_generate
