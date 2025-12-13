"""Document processing service."""

import hashlib
from pathlib import Path
from functools import lru_cache
from datetime import datetime

from langchain_text_splitters import RecursiveCharacterTextSplitter

from research_assistant.config import get_settings
from research_assistant.core.schemas import DocumentChunk, DocumentMetadata
from research_assistant.core.exceptions import DocumentProcessingError


class DocumentService:
    """Service for loading and processing documents."""

    SUPPORTED_EXTENSIONS = {".txt", ".md", ".pdf"}

    def __init__(self):
        settings = get_settings()
        self.chunk_size = settings.chunk_size
        self.chunk_overlap = settings.chunk_overlap
        self.upload_dir = Path(settings.upload_dir)
        self._splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=len,
        )

    def process_file(self, file_path: Path) -> list[DocumentChunk]:
        """Process a single file into chunks."""
        if not file_path.exists():
            raise DocumentProcessingError(f"File not found: {file_path}")

        ext = file_path.suffix.lower()
        if ext not in self.SUPPORTED_EXTENSIONS:
            raise DocumentProcessingError(
                f"Unsupported file type: {ext}",
                {"supported": list(self.SUPPORTED_EXTENSIONS)},
            )

        try:
            content = self._read_file(file_path)
            return self._chunk_content(content, file_path)
        except Exception as e:
            raise DocumentProcessingError(f"Failed to process {file_path}: {e}")

    def _read_file(self, file_path: Path) -> str:
        """Read file content based on type."""
        ext = file_path.suffix.lower()

        if ext in {".txt", ".md"}:
            return file_path.read_text(encoding="utf-8")
        elif ext == ".pdf":
            return self._read_pdf(file_path)
        else:
            raise DocumentProcessingError(f"Unsupported: {ext}")

    def _read_pdf(self, file_path: Path) -> str:
        """Read PDF file content."""
        try:
            from pypdf import PdfReader

            reader = PdfReader(file_path)
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        except ImportError:
            raise DocumentProcessingError("pypdf not installed. Run: pip install pypdf")

    def _chunk_content(self, content: str, file_path: Path) -> list[DocumentChunk]:
        """Split content into chunks."""
        texts = self._splitter.split_text(content)
        chunks = []

        for i, text in enumerate(texts):
            chunk_id = self._generate_id(file_path, i)
            metadata = DocumentMetadata(
                source=str(file_path),
                filename=file_path.name,
                file_type=file_path.suffix,
                created_at=datetime.now(),
            )
            chunks.append(
                DocumentChunk(
                    id=chunk_id,
                    content=text,
                    metadata=metadata,
                )
            )

        return chunks

    def _generate_id(self, file_path: Path, chunk_index: int) -> str:
        """Generate unique ID for a chunk."""
        content = f"{file_path}:{chunk_index}"
        return hashlib.md5(content.encode()).hexdigest()

    def process_directory(self, directory: Path | None = None) -> list[DocumentChunk]:
        """Process all documents in a directory."""
        directory = directory or self.upload_dir
        all_chunks = []

        for ext in self.SUPPORTED_EXTENSIONS:
            for file_path in directory.glob(f"*{ext}"):
                chunks = self.process_file(file_path)
                all_chunks.extend(chunks)

        return all_chunks


@lru_cache
def get_document_service() -> DocumentService:
    """Get cached document service instance."""
    return DocumentService()
