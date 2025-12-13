"""Vector search tool for agents."""

from langchain_core.tools import tool

from research_assistant.services import get_vector_store
from research_assistant.core.schemas import RetrievedDocument


@tool
def search_documents(query: str, top_k: int = 5) -> list[dict]:
    """
    Search the knowledge base for relevant documents.

    Args:
        query: The search query
        top_k: Number of results to return

    Returns:
        List of relevant documents with content and metadata
    """
    vector_store = get_vector_store()
    results = vector_store.search(query, top_k=top_k)

    return [
        {
            "content": doc.content,
            "source": doc.metadata.source,
            "score": doc.score,
        }
        for doc in results
    ]


def format_search_results(documents: list[RetrievedDocument]) -> str:
    """Format search results for display in prompts."""
    if not documents:
        return "No relevant documents found."

    formatted = []
    for i, doc in enumerate(documents, 1):
        formatted.append(
            f"[{i}] Source: {doc.metadata.filename}\n"
            f"    Score: {doc.score:.2f}\n"
            f"    Content: {doc.content[:500]}..."
        )

    return "\n\n".join(formatted)
