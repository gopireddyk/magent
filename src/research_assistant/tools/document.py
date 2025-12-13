"""Document processing tools."""

from pathlib import Path

from research_assistant.services import (
    get_document_service,
    get_vector_store,
)


def ingest_documents(directory: str | Path | None = None) -> dict:
    """
    Ingest documents from a directory into the vector store.

    Args:
        directory: Directory path (uses default if None)

    Returns:
        Dictionary with ingestion stats
    """
    doc_service = get_document_service()
    vector_store = get_vector_store()

    dir_path = Path(directory) if directory else None
    chunks = doc_service.process_directory(dir_path)

    if chunks:
        added = vector_store.add_documents(chunks)
        return {
            "files_processed": len({c.metadata.filename for c in chunks}),
            "chunks_added": added,
            "status": "success",
        }

    return {"files_processed": 0, "chunks_added": 0, "status": "no_files"}


def get_document_stats() -> dict:
    """Get document store statistics."""
    return get_vector_store().get_stats()
