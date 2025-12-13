"""Tests for settings module."""

from research_assistant.config.settings import Settings, get_settings


def test_default_settings():
    """Test default settings values."""
    settings = Settings()
    assert settings.ollama_model == "llama3.2"
    assert settings.chunk_size == 1000
    assert settings.search_top_k == 5


def test_env_override(monkeypatch):
    """Test environment variables override defaults."""
    monkeypatch.setenv("RESEARCH_OLLAMA_MODEL", "mistral")
    monkeypatch.setenv("RESEARCH_CHUNK_SIZE", "500")
    get_settings.cache_clear()

    settings = get_settings()
    assert settings.ollama_model == "mistral"
    assert settings.chunk_size == 500
