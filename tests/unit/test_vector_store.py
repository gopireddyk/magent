"""Tests for Vector Store service."""

from research_assistant.services.vector_store import VectorStore
from research_assistant.core.schemas import DocumentChunk, DocumentMetadata


class FakeEmbeddingService:
    """Fake embedding service for vector store tests."""

    def embed_texts(self, texts):
        return [[0.1, 0.2, 0.3] for _ in texts]

    def embed_text(self, text):
        return [0.1, 0.2, 0.3]


class FakeCollection:
    """Fake ChromaDB collection."""

    def __init__(self):
        self.add_called = False

    def add(self, ids, embeddings, documents, metadatas):
        self.add_called = True
        self._store = list(zip(ids, embeddings, documents, metadatas))

    def query(self, query_embeddings, n_results, include):
        return {
            "ids": [["doc-1"]],
            "documents": [["Content"]],
            "metadatas": [[{"source": "file.txt", "filename": "file.txt", "file_type": ".txt"}]],
            "distances": [[0.1]],
        }

    def count(self):
        return 1


class FakeClient:
    """Fake ChromaDB client."""

    def __init__(self, collection: FakeCollection):
        self.collection = collection

    def get_or_create_collection(self, name, metadata=None):
        return self.collection

    def delete_collection(self, name):
        self.collection = None


def _build_chunks():
    metadata = DocumentMetadata(
        source="path/file.txt",
        filename="file.txt",
        file_type=".txt",
    )
    return [
        DocumentChunk(id="1", content="hello", metadata=metadata),
        DocumentChunk(id="2", content="world", metadata=metadata),
    ]


def test_add_documents(monkeypatch):
    """Ensure documents are added to collection."""
    vs = VectorStore()
    fake_collection = FakeCollection()
    vs._collection = fake_collection
    vs._client = FakeClient(fake_collection)
    vs._embedding_service = FakeEmbeddingService()

    added = vs.add_documents(_build_chunks())

    assert added == 2
    assert fake_collection.add_called is True


def test_search_returns_results(monkeypatch):
    """Search returns RetrievedDocument instances."""
    vs = VectorStore()
    fake_collection = FakeCollection()
    vs._collection = fake_collection
    vs._client = FakeClient(fake_collection)
    vs._embedding_service = FakeEmbeddingService()

    results = vs.search("query", top_k=1, score_threshold=0.0)
    assert len(results) == 1
    assert results[0].content == "Content"


def test_get_stats(monkeypatch):
    """Collection stats include name and count."""
    vs = VectorStore()
    fake_collection = FakeCollection()
    vs._collection = fake_collection
    vs._client = FakeClient(fake_collection)
    vs._embedding_service = FakeEmbeddingService()

    stats = vs.get_stats()
    assert stats["collection_name"] == vs.collection_name
    assert stats["document_count"] == 1
