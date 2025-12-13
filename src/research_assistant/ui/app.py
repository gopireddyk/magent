"""Main Streamlit application."""

import streamlit as st

from research_assistant.ui.components import render_header, render_sidebar
from research_assistant.graph import run_research
from research_assistant.services import get_llm_service


def main():
    """Main application entry point."""
    render_header()
    settings = render_sidebar()

    # Check LLM availability
    llm = get_llm_service()
    if not llm.is_available():
        st.error("⚠️ Ollama is not running. Start it with: ollama serve")
        return

    # Initialize chat history
    if "messages" not in st.session_state:
        st.session_state.messages = []

    # Display chat history
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])
            if msg.get("sources"):
                with st.expander("Sources"):
                    for src in msg["sources"]:
                        st.caption(f"📄 {src}")

    # Chat input
    if prompt := st.chat_input("Ask a research question..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)

        # Generate response
        with st.chat_message("assistant"):
            with st.spinner("Researching..."):
                result = run_research(prompt)

            st.markdown(result["response"])

            if result.get("sources"):
                with st.expander("Sources"):
                    for src in result["sources"]:
                        st.caption(f"📄 {src.get('source', 'Unknown')}")

        st.session_state.messages.append(
            {
                "role": "assistant",
                "content": result["response"],
                "sources": [s.get("source") for s in result.get("sources", [])],
            }
        )


if __name__ == "__main__":
    main()
