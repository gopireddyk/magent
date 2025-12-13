"""Integration tests for RAG pipeline."""

import pytest

from research_assistant.services.document_service import DocumentService
from research_assistant.services.vector_store import VectorStore
from research_assistant.core.schemas import DocumentMetadata, DocumentChunk, RetrievedDocument


class _FakeEmbeddingService:
    def embed_texts(self, texts):
        return [[0.1, 0.2, 0.3] for _ in texts]

    def embed_text(self, text):
        return [0.1, 0.2, 0.3]


class _FakeCollection:
    def __init__(self):
        self.docs = []

    def add(self, ids, embeddings, documents, metadatas):
        self.docs.extend(zip(ids, documents, metadatas))

    def query(self, query_embeddings, n_results, include):
        return {
            "ids": [[doc_id for doc_id, _, _ in self.docs]],
            "documents": [[doc for _, doc, _ in self.docs]],
            "metadatas": [[meta for *_, meta in self.docs]],
            "distances": [[0.1 for _ in self.docs]],
        }

    def count(self):
        return len(self.docs)


class _FakeClient:
    def __init__(self, collection):
        self.collection = collection

    def get_or_create_collection(self, name, metadata=None):
        return self.collection

    def delete_collection(self, name):
        self.collection = None


@pytest.mark.integration
def test_document_ingestion_and_search(sample_document, monkeypatch):
    """Test processing, storing, and searching a document."""
    doc_service = DocumentService()
    vector_store = VectorStore()

    fake_collection = _FakeCollection()
    vector_store._collection = fake_collection
    vector_store._client = _FakeClient(fake_collection)
    vector_store._embedding_service = _FakeEmbeddingService()

    chunks = doc_service.process_file(sample_document)
    added = vector_store.add_documents(chunks)
    assert added == len(chunks)

    results = vector_store.search("machine learning", top_k=1, score_threshold=0.0)
    assert results
    assert isinstance(results[0], RetrievedDocument)
