"""Tests for Document service."""

from pathlib import Path
import pytest

from research_assistant.services.document_service import DocumentService
from research_assistant.core.exceptions import DocumentProcessingError


def test_process_text_file(sample_document):
    """Processing a text file yields chunks."""
    service = DocumentService()
    chunks = service.process_file(sample_document)
    assert len(chunks) >= 1
    assert chunks[0].metadata.filename == sample_document.name


def test_process_unsupported_extension(temp_dir):
    """Unsupported file types raise an error."""
    service = DocumentService()
    file_path = temp_dir / "notes.docx"
    file_path.write_text("content")

    with pytest.raises(DocumentProcessingError):
        service.process_file(file_path)


def test_process_directory(temp_dir):
    """Directory processing ingests supported files."""
    service = DocumentService()
    txt_path = temp_dir / "one.txt"
    txt_path.write_text("hello world")

    chunks = service.process_directory(temp_dir)
    assert chunks
    assert all(isinstance(c.content, str) for c in chunks)
