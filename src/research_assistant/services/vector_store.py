"""ChromaDB vector store service."""

from functools import lru_cache
from typing import Any
import chromadb
from chromadb.config import Settings as ChromaSettings

from research_assistant.config import get_settings
from research_assistant.core.schemas import (
    DocumentChunk,
    RetrievedDocument,
    DocumentMetadata,
)
from research_assistant.core.exceptions import VectorStoreError
from research_assistant.services.embeddings import get_embedding_service


class VectorStore:
    """ChromaDB vector store wrapper."""

    def __init__(self):
        settings = get_settings()
        self.persist_dir = settings.chroma_persist_dir
        self.collection_name = settings.chroma_collection_name
        self._client: chromadb.PersistentClient | None = None
        self._collection = None
        self._embedding_service = get_embedding_service()

    @property
    def client(self) -> chromadb.PersistentClient:
        """Lazy load the ChromaDB client."""
        if self._client is None:
            try:
                self._client = chromadb.PersistentClient(
                    path=self.persist_dir,
                    settings=ChromaSettings(anonymized_telemetry=False),
                )
            except Exception as e:
                raise VectorStoreError(f"Failed to initialize ChromaDB: {e}")
        return self._client

    @property
    def collection(self):
        """Get or create the collection."""
        if self._collection is None:
            self._collection = self.client.get_or_create_collection(
                name=self.collection_name,
                metadata={"hnsw:space": "cosine"},
            )
        return self._collection

    def add_documents(self, chunks: list[DocumentChunk]) -> int:
        """Add document chunks to the vector store."""
        if not chunks:
            return 0

        try:
            texts = [chunk.content for chunk in chunks]
            embeddings = self._embedding_service.embed_texts(texts)

            self.collection.add(
                ids=[chunk.id for chunk in chunks],
                embeddings=embeddings,
                documents=texts,
                metadatas=[chunk.metadata.model_dump() for chunk in chunks],
            )
            return len(chunks)
        except Exception as e:
            raise VectorStoreError(f"Failed to add documents: {e}")

    def search(
        self,
        query: str,
        top_k: int | None = None,
        score_threshold: float | None = None,
    ) -> list[RetrievedDocument]:
        """Search for similar documents."""
        settings = get_settings()
        top_k = top_k or settings.search_top_k
        score_threshold = score_threshold or settings.search_score_threshold

        try:
            query_embedding = self._embedding_service.embed_text(query)
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k,
                include=["documents", "metadatas", "distances"],
            )

            documents = []
            for i, doc_id in enumerate(results["ids"][0]):
                distance = results["distances"][0][i]
                score = 1 - distance  # Convert distance to similarity

                if score >= score_threshold:
                    metadata_dict = results["metadatas"][0][i]
                    documents.append(
                        RetrievedDocument(
                            id=doc_id,
                            content=results["documents"][0][i],
                            metadata=DocumentMetadata(**metadata_dict),
                            score=score,
                        )
                    )

            return documents
        except Exception as e:
            raise VectorStoreError(f"Search failed: {e}")

    def get_stats(self) -> dict[str, Any]:
        """Get collection statistics."""
        return {
            "collection_name": self.collection_name,
            "document_count": self.collection.count(),
            "persist_dir": self.persist_dir,
        }

    def clear(self) -> None:
        """Clear all documents from the collection."""
        self.client.delete_collection(self.collection_name)
        self._collection = None


@lru_cache
def get_vector_store() -> VectorStore:
    """Get cached vector store instance."""
    return VectorStore()
