"""Custom exception classes."""


class ResearchAssistantError(Exception):
    """Base exception for the application."""

    def __init__(self, message: str, details: dict | None = None):
        super().__init__(message)
        self.message = message
        self.details = details or {}


class DocumentProcessingError(ResearchAssistantError):
    """Error during document processing."""


class VectorStoreError(ResearchAssistantError):
    """Error with vector store operations."""


class LLMError(ResearchAssistantError):
    """Error with LLM operations."""


class EmbeddingError(ResearchAssistantError):
    """Error generating embeddings."""


class ConfigurationError(ResearchAssistantError):
    """Error in application configuration."""
