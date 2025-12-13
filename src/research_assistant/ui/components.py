"""Reusable Streamlit components."""

import streamlit as st


def render_header():
    """Render the application header."""
    st.set_page_config(
        page_title="Research Assistant",
        page_icon="📚",
        layout="wide",
    )
    st.title("📚 Student Research Assistant")
    st.caption("AI-powered research with your documents")


def render_sidebar():
    """Render the sidebar."""
    with st.sidebar:
        st.header("Settings")

        st.subheader("Model")
        model = st.selectbox(
            "LLM Model",
            ["llama3.2", "llama3.1", "mistral"],
            index=0,
        )

        st.subheader("Search")
        top_k = st.slider("Results to retrieve", 1, 10, 5)

        return {"model": model, "top_k": top_k}


def render_chat_message(role: str, content: str, sources: list | None = None):
    """Render a chat message."""
    with st.chat_message(role):
        st.markdown(content)
        if sources:
            with st.expander("Sources"):
                for src in sources:
                    st.caption(f"📄 {src.get('source', 'Unknown')}")


def render_document_upload():
    """Render document upload widget."""
    uploaded_files = st.file_uploader(
        "Upload Documents",
        type=["pdf", "txt", "md"],
        accept_multiple_files=True,
    )
    return uploaded_files
