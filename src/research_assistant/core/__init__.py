"""Core package - schemas and exceptions."""

from research_assistant.core.schemas import (
    DocumentChunk,
    DocumentMetadata,
    RetrievedDocument,
    SearchResult,
    Citation,
    ResearchFindings,
    CritiqueResult,
)
from research_assistant.core.exceptions import (
    ResearchAssistantError,
    DocumentProcessingError,
    VectorStoreError,
    LLMError,
    EmbeddingError,
    ConfigurationError,
)

__all__ = [
    "DocumentChunk",
    "DocumentMetadata",
    "RetrievedDocument",
    "SearchResult",
    "Citation",
    "ResearchFindings",
    "CritiqueResult",
    "ResearchAssistantError",
    "DocumentProcessingError",
    "VectorStoreError",
    "LLMError",
    "EmbeddingError",
    "ConfigurationError",
]
