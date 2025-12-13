"""Documents page - upload and manage documents."""

import streamlit as st
from pathlib import Path

from research_assistant.tools.document import ingest_documents, get_document_stats
from research_assistant.config import get_settings

st.set_page_config(page_title="Documents", page_icon="📄")
st.title("📄 Document Management")

# Stats
stats = get_document_stats()
col1, col2 = st.columns(2)
col1.metric("Documents Indexed", stats.get("document_count", 0))
col2.metric("Collection", stats.get("collection_name", "N/A"))

st.divider()

# Upload
st.subheader("Upload Documents")
uploaded_files = st.file_uploader(
    "Choose files",
    type=["pdf", "txt", "md"],
    accept_multiple_files=True,
)

if uploaded_files and st.button("Process Documents"):
    settings = get_settings()
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(parents=True, exist_ok=True)

    for file in uploaded_files:
        # Sanitize filename to avoid path traversal
        safe_name = Path(file.name).name
        file_path = upload_dir / safe_name
        file_path.write_bytes(file.read())

    with st.spinner("Processing..."):
        result = ingest_documents()

    st.success(
        f"Processed {result['files_processed']} files, "
        f"added {result['chunks_added']} chunks"
    )
    st.rerun()
