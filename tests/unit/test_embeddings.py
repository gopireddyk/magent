"""Tests for Embedding service."""

from research_assistant.services.embeddings import EmbeddingService


class FakeModel:
    """Simple fake embedding model for tests."""

    def encode(self, texts, convert_to_numpy=True):
        if isinstance(texts, list):
            return [[0.1, 0.2, 0.3] for _ in texts]
        return [0.1, 0.2, 0.3]

    def get_sentence_embedding_dimension(self) -> int:
        return 3


def test_embed_single_text(monkeypatch):
    """Embedding a single text returns a vector."""
    service = EmbeddingService(model_name="fake-model")
    service._model = FakeModel()

    vector = service.embed_text("hello")
    assert len(vector) == 3


def test_embed_multiple_texts(monkeypatch):
    """Embedding multiple texts returns list of vectors."""
    service = EmbeddingService(model_name="fake-model")
    service._model = FakeModel()

    vectors = service.embed_texts(["a", "b"])
    assert len(vectors) == 2
    assert len(vectors[0]) == 3


def test_embedding_dimension(monkeypatch):
    """Dimension property reflects model dimension."""
    service = EmbeddingService(model_name="fake-model")
    service._model = FakeModel()

    assert service.dimension == 3
