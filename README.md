# Magent – Student Research Assistant

Multi-agent RAG assistant built with LangChain, LangGraph, Streamlit, ChromaDB, and Ollama. Students can upload documents, ask research questions, and get cited answers from a supervisor/researcher/writer/critic agent team.

## Quick start
- Install deps: `python3 -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"` (Ollama + models required: `ollama pull llama3.2`).
- Seed sample docs: `python scripts/seed_data.py` then ingest with `python -m research_assistant.cli ingest --dir data/documents`.
- Ask via CLI: `python -m research_assistant.cli query "What is machine learning?" --show-sources`.
- Run UI: `streamlit run src/research_assistant/ui/app.py`.
- Tests/quality: `pytest tests/ -v` and optional `pre-commit run --all-files`.

## Branches
- `main` – Stable
- `gk_poc` – GK POC
- `sv_poc` – SV POC (current)
- `dev` – Shared development
