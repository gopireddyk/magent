"""Command-line interface."""

import argparse
import sys
from pathlib import Path

from research_assistant.graph import run_research
from research_assistant.tools.document import ingest_documents, get_document_stats


def cmd_query(args):
    """Handle query command."""
    result = run_research(args.query)
    print(f"\n{'='*60}")
    print(f"Query: {args.query}")
    print(f"{'='*60}\n")
    print(result["response"])

    if result.get("sources") and args.show_sources:
        print(f"\n{'='*60}")
        print("Sources:")
        for src in result["sources"]:
            print(f"  - {src.get('source', 'Unknown')}")


def cmd_ingest(args):
    """Handle ingest command."""
    directory = Path(args.dir) if args.dir else None
    print(f"Ingesting documents from: {directory or 'default'}")

    result = ingest_documents(directory)
    print(f"Files processed: {result['files_processed']}")
    print(f"Chunks added: {result['chunks_added']}")


def cmd_stats(args):
    """Handle stats command."""
    stats = get_document_stats()
    print("Vector Store Statistics:")
    for key, value in stats.items():
        print(f"  {key}: {value}")


def cmd_interactive(args):
    """Interactive chat mode."""
    print("Research Assistant - Interactive Mode")
    print("Type 'quit' to exit\n")

    while True:
        try:
            query = input("You: ").strip()
            if query.lower() in ("quit", "exit", "q"):
                break
            if not query:
                continue

            result = run_research(query)
            print(f"\nAssistant: {result['response']}\n")

        except KeyboardInterrupt:
            break

    print("\nGoodbye!")


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        prog="research_assistant",
        description="Student Research Assistant CLI",
    )
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Query command
    query_parser = subparsers.add_parser("query", help="Ask a question")
    query_parser.add_argument("query", help="The question to ask")
    query_parser.add_argument(
        "--show-sources",
        "-s",
        action="store_true",
        help="Show source documents",
    )
    query_parser.set_defaults(func=cmd_query)

    # Ingest command
    ingest_parser = subparsers.add_parser("ingest", help="Ingest documents")
    ingest_parser.add_argument("--dir", "-d", help="Directory containing documents")
    ingest_parser.set_defaults(func=cmd_ingest)

    # Stats command
    stats_parser = subparsers.add_parser("stats", help="Show statistics")
    stats_parser.set_defaults(func=cmd_stats)

    # Interactive command
    interactive_parser = subparsers.add_parser(
        "interactive", help="Interactive chat mode"
    )
    interactive_parser.set_defaults(func=cmd_interactive)

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    args.func(args)


def ingest():
    """Standalone ingest entry point for ra-ingest command."""
    import argparse
    parser = argparse.ArgumentParser(
        prog="ra-ingest",
        description="Ingest documents into the vector store",
    )
    parser.add_argument("--dir", "-d", help="Directory containing documents")
    args = parser.parse_args()
    cmd_ingest(args)


def query():
    """Standalone query entry point for ra-query command."""
    import argparse
    parser = argparse.ArgumentParser(
        prog="ra-query",
        description="Query the research assistant",
    )
    parser.add_argument("query", help="The question to ask")
    parser.add_argument(
        "--show-sources",
        "-s",
        action="store_true",
        help="Show source documents",
    )
    args = parser.parse_args()
    cmd_query(args)


if __name__ == "__main__":
    main()
