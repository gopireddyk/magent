#!/usr/bin/env python3
"""
Export Documentation Script - Exports chat history and answers.

Usage:
    python scripts/export_docs.py --format markdown --output export.md
    python scripts/export_docs.py --format json --output export.json
"""

import argparse
import json
from datetime import datetime
from pathlib import Path


def export_to_markdown(data: dict, output_path: Path) -> None:
    """Export chat history to Markdown format."""
    with open(output_path, "w") as f:
        f.write("# Research Assistant Export\n\n")
        f.write(f"Exported: {datetime.now().isoformat()}\n\n")
        f.write("---\n\n")

        for i, item in enumerate(data.get("conversations", []), 1):
            f.write(f"## Conversation {i}\n\n")
            f.write(f"**Question:** {item.get('question', 'N/A')}\n\n")
            f.write(f"**Answer:**\n\n{item.get('answer', 'N/A')}\n\n")

            if item.get("sources"):
                f.write("**Sources:**\n\n")
                for source in item["sources"]:
                    f.write(f"- {source}\n")
                f.write("\n")

            f.write("---\n\n")

    print(f"Exported to: {output_path}")


def export_to_json(data: dict, output_path: Path) -> None:
    """Export chat history to JSON format."""
    export_data = {
        "exported_at": datetime.now().isoformat(),
        "version": "1.0.0",
        **data
    }

    with open(output_path, "w") as f:
        json.dump(export_data, f, indent=2)

    print(f"Exported to: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Export research assistant data")
    parser.add_argument(
        "--format",
        choices=["markdown", "json"],
        default="markdown",
        help="Export format (default: markdown)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("export.md"),
        help="Output file path"
    )
    parser.add_argument(
        "--input",
        type=Path,
        help="Input JSON file with chat history (optional)"
    )

    args = parser.parse_args()

    # Load data (placeholder - would integrate with actual chat storage)
    if args.input and args.input.exists():
        with open(args.input) as f:
            data = json.load(f)
    else:
        # Sample data for demonstration
        data = {
            "conversations": [
                {
                    "question": "What is machine learning?",
                    "answer": "Machine learning is a subset of AI...",
                    "sources": ["machine_learning_intro.txt"]
                }
            ]
        }
        print("Note: Using sample data. Provide --input for actual data.")

    # Export
    if args.format == "markdown":
        export_to_markdown(data, args.output)
    else:
        export_to_json(data, args.output)


if __name__ == "__main__":
    main()
