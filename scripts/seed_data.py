#!/usr/bin/env python3
"""
Seed Data Script - Creates sample documents for testing.

Usage:
    python scripts/seed_data.py
    # OR
    make seed-data
"""

import os
from pathlib import Path

# Sample documents content
SAMPLE_DOCUMENTS = {
    "machine_learning_intro.txt": """
Introduction to Machine Learning

Machine learning is a subset of artificial intelligence (AI) that enables
systems to learn and improve from experience without being explicitly programmed.
It focuses on developing computer programs that can access data and use it to
learn for themselves.

Types of Machine Learning:

1. Supervised Learning
In supervised learning, the algorithm learns from labeled training data.
The model makes predictions based on input-output pairs provided during training.
Common algorithms include linear regression, decision trees, and neural networks.

2. Unsupervised Learning
Unsupervised learning works with unlabeled data. The algorithm tries to find
patterns and relationships in the data without prior knowledge of outcomes.
Clustering and dimensionality reduction are common unsupervised techniques.

3. Reinforcement Learning
Reinforcement learning involves an agent learning to make decisions by
interacting with an environment. The agent receives rewards or penalties
based on its actions and learns to maximize cumulative reward.

Applications:
- Image and speech recognition
- Natural language processing
- Recommendation systems
- Autonomous vehicles
- Medical diagnosis

Machine learning continues to evolve rapidly, with deep learning and
transformer architectures driving recent breakthroughs in AI capabilities.
""",

    "research_methodology.txt": """
Research Methodology Guide

Research methodology refers to the systematic approach used to conduct
research and gather data. Choosing the right methodology is crucial for
obtaining valid and reliable results.

Qualitative vs Quantitative Research:

Qualitative Research:
- Focuses on understanding concepts, thoughts, and experiences
- Uses interviews, observations, and text analysis
- Results in descriptive, non-numerical data
- Suitable for exploratory research questions

Quantitative Research:
- Focuses on measuring and quantifying phenomena
- Uses surveys, experiments, and statistical analysis
- Results in numerical data and statistics
- Suitable for testing hypotheses

Common Research Methods:

1. Literature Review
Systematic analysis of existing research on a topic.
Helps identify gaps and establish theoretical framework.

2. Case Study
In-depth investigation of a specific instance or phenomenon.
Useful for exploring complex issues in real-world context.

3. Survey Research
Collection of data from a sample population using questionnaires.
Enables generalization to larger populations.

4. Experimental Research
Controlled investigation to establish cause-effect relationships.
Involves manipulation of variables and random assignment.

5. Action Research
Collaborative inquiry aimed at improving practices.
Combines research with practical problem-solving.

Best Practices:
- Clearly define research questions
- Choose appropriate methodology
- Ensure ethical considerations
- Document procedures thoroughly
- Validate findings through triangulation
""",

    "academic_writing_tips.txt": """
Academic Writing: Best Practices

Academic writing is a formal style of writing used in universities
and scholarly publications. It requires clarity, precision, and
adherence to specific conventions.

Key Principles:

1. Clarity and Precision
- Use clear, concise language
- Avoid ambiguous statements
- Define technical terms
- Be specific rather than general

2. Evidence-Based Arguments
- Support claims with evidence
- Cite sources properly
- Distinguish facts from opinions
- Acknowledge limitations

3. Logical Structure
- Organize ideas coherently
- Use clear topic sentences
- Provide smooth transitions
- Build arguments progressively

4. Formal Tone
- Avoid colloquialisms
- Use third person perspective
- Maintain objectivity
- Be respectful of other viewpoints

Citation Styles:

APA (American Psychological Association):
Used in social sciences, education, and psychology.
Format: (Author, Year)

MLA (Modern Language Association):
Used in humanities and liberal arts.
Format: (Author Page)

Chicago/Turabian:
Used in history and some humanities.
Uses footnotes or author-date format.

Common Mistakes to Avoid:
- Plagiarism (always cite sources)
- Overgeneralization
- Weak thesis statements
- Poor paragraph structure
- Inconsistent citation style
- Grammatical errors

Remember: Good academic writing takes practice.
Revise multiple times and seek feedback.
"""
}


def create_sample_documents():
    """Create sample documents in the data/documents directory."""
    docs_dir = Path("data/documents")
    docs_dir.mkdir(parents=True, exist_ok=True)

    print("Creating sample documents...")

    for filename, content in SAMPLE_DOCUMENTS.items():
        filepath = docs_dir / filename
        filepath.write_text(content.strip())
        print(f"  Created: {filepath}")

    print(f"\nCreated {len(SAMPLE_DOCUMENTS)} sample documents in {docs_dir}/")
    print("\nYou can now ingest these documents with:")
    print("  make ingest")
    print("  # OR")
    print("  python -m research_assistant.cli ingest --dir data/documents")


if __name__ == "__main__":
    create_sample_documents()
