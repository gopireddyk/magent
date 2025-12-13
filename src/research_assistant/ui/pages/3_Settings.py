"""Settings page - configuration display."""

import streamlit as st
from research_assistant.config import get_settings
from research_assistant.services import get_llm_service

st.set_page_config(page_title="Settings", page_icon="⚙️")
st.title("⚙️ Settings")

settings = get_settings()
llm = get_llm_service()

st.subheader("LLM Configuration")
st.json(
    {
        "model": settings.ollama_model,
        "base_url": settings.ollama_base_url,
        "temperature": settings.temperature,
        "available": llm.is_available(),
    }
)

st.subheader("Document Processing")
st.json(
    {
        "chunk_size": settings.chunk_size,
        "chunk_overlap": settings.chunk_overlap,
        "upload_dir": settings.upload_dir,
    }
)

st.subheader("Vector Store")
st.json(
    {
        "persist_dir": settings.chroma_persist_dir,
        "collection": settings.chroma_collection_name,
        "top_k": settings.search_top_k,
    }
)
