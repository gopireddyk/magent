"""Application settings using Pydantic BaseSettings."""

from functools import lru_cache
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application configuration from environment variables."""

    # Ollama settings
    ollama_base_url: str = Field(
        default="http://localhost:11434",
        description="Ollama API base URL",
    )
    ollama_model: str = Field(
        default="llama3.2",
        description="Ollama model name",
    )
    ollama_timeout: int = Field(
        default=120,
        description="Ollama request timeout in seconds",
    )

    # Embedding settings
    embedding_model: str = Field(
        default="all-MiniLM-L6-v2",
        description="Sentence transformer model name",
    )

    # ChromaDB settings
    chroma_host: str | None = Field(
        default=None,
        description="ChromaDB server host (if using HTTP client)",
    )
    chroma_port: int = Field(
        default=8000,
        description="ChromaDB server port",
    )
    chroma_persist_dir: str = Field(
        default="./data/vectorstore",
        description="ChromaDB persistence directory (for local mode)",
    )
    chroma_collection_name: str = Field(
        default="research_documents",
        description="ChromaDB collection name",
    )

    # Document processing
    chunk_size: int = Field(default=1000, ge=100, le=4000)
    chunk_overlap: int = Field(default=200, ge=0, le=500)
    upload_dir: str = Field(default="./data/documents")

    # Search settings
    search_top_k: int = Field(default=5, ge=1, le=20)
    search_score_threshold: float = Field(default=0.3, ge=0.0, le=1.0)

    # Agent settings
    max_iterations: int = Field(default=10, ge=1, le=50)
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)

    model_config = {
        "env_prefix": "RESEARCH_",
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Convenience alias
settings = get_settings()
