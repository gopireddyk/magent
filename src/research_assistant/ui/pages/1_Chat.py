"""Chat page - main research interface."""

import streamlit as st
from research_assistant.ui.app import main

st.set_page_config(page_title="Chat", page_icon="💬")
main()
