"""Pydantic data models."""

from datetime import datetime
from typing import Any
from pydantic import BaseModel, Field


class DocumentMetadata(BaseModel):
    """Metadata for a document."""

    source: str
    filename: str
    file_type: str
    created_at: datetime = Field(default_factory=datetime.now)
    page_number: int | None = None
    total_pages: int | None = None
    extra: dict[str, Any] = Field(default_factory=dict)

    def model_dump_for_vectorstore(self) -> dict[str, Any]:
        """Serialize metadata for vector store compatibility.

        ChromaDB only accepts str, int, float, bool values (NOT None).
        This method flattens nested structures and excludes None values.
        """
        data = {}
        data["source"] = self.source
        data["filename"] = self.filename
        data["file_type"] = self.file_type
        if self.created_at:
            data["created_at"] = self.created_at.isoformat()
        if self.page_number is not None:
            data["page_number"] = self.page_number
        if self.total_pages is not None:
            data["total_pages"] = self.total_pages
        # Flatten extra dict - only include simple scalar values (no None)
        for key, value in self.extra.items():
            if isinstance(value, (str, int, float, bool)):
                data[f"extra_{key}"] = value
        return data

    def model_dump(self, **kwargs) -> dict[str, Any]:
        """Serialize metadata with ISO datetimes for vector store compatibility."""
        data = super().model_dump(**kwargs)
        created = data.get("created_at")
        if isinstance(created, datetime):
            data["created_at"] = created.isoformat()
        return data


class DocumentChunk(BaseModel):
    """A chunk of a document with its embedding."""

    id: str
    content: str
    metadata: DocumentMetadata
    embedding: list[float] | None = None

    model_config = {"frozen": False}


class RetrievedDocument(BaseModel):
    """A document retrieved from the vector store."""

    id: str
    content: str
    metadata: DocumentMetadata
    score: float

    @property
    def source(self) -> str:
        return self.metadata.source


class SearchResult(BaseModel):
    """Result of a search query."""

    query: str
    documents: list[RetrievedDocument]
    total_found: int


class Citation(BaseModel):
    """A citation reference."""

    source: str
    page: int | None = None
    quote: str | None = None


class ResearchFindings(BaseModel):
    """Findings from the researcher agent."""

    query: str
    summary: str
    sources: list[RetrievedDocument]
    citations: list[Citation] = Field(default_factory=list)


class CritiqueResult(BaseModel):
    """Result of the critic agent's review."""

    approved: bool
    feedback: str
    suggestions: list[str] = Field(default_factory=list)
