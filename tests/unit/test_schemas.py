"""Tests for schema models."""

from datetime import datetime

from research_assistant.core.schemas import (
    DocumentMetadata,
    DocumentChunk,
    RetrievedDocument,
    SearchResult,
    Citation,
    ResearchFindings,
    CritiqueResult,
)


def test_document_metadata_defaults():
    """Ensure metadata populates defaults."""
    metadata = DocumentMetadata(
        source="/path/to/doc.pdf",
        filename="doc.pdf",
        file_type=".pdf",
    )
    assert metadata.source == "/path/to/doc.pdf"
    assert isinstance(metadata.created_at, datetime)


def test_document_chunk_creation():
    """Create a document chunk with metadata."""
    metadata = DocumentMetadata(
        source="test.txt",
        filename="test.txt",
        file_type=".txt",
    )
    chunk = DocumentChunk(id="chunk-1", content="Test content", metadata=metadata)
    assert chunk.id == "chunk-1"
    assert chunk.content == "Test content"
    assert chunk.metadata.filename == "test.txt"


def test_retrieved_document_source_property():
    """RetrievedDocument exposes source property."""
    metadata = DocumentMetadata(
        source="docs/file.txt",
        filename="file.txt",
        file_type=".txt",
    )
    retrieved = RetrievedDocument(
        id="abc",
        content="content",
        metadata=metadata,
        score=0.9,
    )
    assert retrieved.source == "docs/file.txt"


def test_search_result_model():
    """SearchResult holds query and documents."""
    metadata = DocumentMetadata(
        source="s.txt",
        filename="s.txt",
        file_type=".txt",
    )
    doc = RetrievedDocument(
        id="1",
        content="c",
        metadata=metadata,
        score=0.8,
    )
    result = SearchResult(query="q", documents=[doc], total_found=1)
    assert result.query == "q"
    assert result.total_found == 1


def test_citation_and_findings_models():
    """Citation and ResearchFindings models store references."""
    metadata = DocumentMetadata(
        source="s.txt",
        filename="s.txt",
        file_type=".txt",
    )
    doc = RetrievedDocument(
        id="1",
        content="c",
        metadata=metadata,
        score=0.8,
    )
    citation = Citation(source="s.txt", page=1, quote="quote")
    findings = ResearchFindings(
        query="What is ML?",
        summary="summary",
        sources=[doc],
        citations=[citation],
    )
    assert findings.sources[0].id == "1"
    assert findings.citations[0].quote == "quote"


def test_critique_result_model():
    """CritiqueResult defaults suggestions to list."""
    critique = CritiqueResult(approved=True, feedback="Looks good")
    assert critique.approved is True
    assert critique.suggestions == []
