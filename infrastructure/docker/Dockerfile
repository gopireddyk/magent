# ============================================================================
# DOCKERFILE - Student Research Assistant
# ============================================================================
# Multi-stage build for optimized production image
# ============================================================================

# ============================================================================
# STAGE 1: Builder
# ============================================================================
FROM python:3.11-slim as builder

# Set build arguments
ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Set working directory for builder
WORKDIR /build

# Copy project files needed for installation
COPY pyproject.toml README.md ./
COPY src/ ./src/

# Install production dependencies into venv (not editable for multi-stage builds)
RUN pip install --no-cache-dir .

# ============================================================================
# STAGE 2: Production
# ============================================================================
FROM python:3.11-slim as production

# Labels
LABEL maintainer="your.email@example.com"
LABEL version="1.0.0"
LABEL description="Student Research Assistant - Multi-Agent AI Application"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appgroup src/ ./src/

# Copy .streamlit config
COPY --chown=appuser:appgroup .streamlit/ ./.streamlit/

# Create data directories
RUN mkdir -p /app/data/documents /app/data/vectorstore && \
    chown -R appuser:appgroup /app/data

# Switch to non-root user
USER appuser

# Expose Streamlit port
EXPOSE 8501

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command
CMD ["streamlit", "run", "src/research_assistant/ui/app.py", \
     "--server.port=8501", \
     "--server.address=0.0.0.0", \
     "--server.headless=true"]

# ============================================================================
# STAGE 3: Development (optional)
# ============================================================================
FROM production as development

# Switch to root for installing dev tools
USER root

# Install development dependencies
RUN pip install --no-cache-dir -e ".[dev]"

# Install additional dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    git \
    && rm -rf /var/lib/apt/lists/*

# Switch back to appuser
USER appuser

# Override command for development
CMD ["streamlit", "run", "src/research_assistant/ui/app.py", \
     "--server.port=8501", \
     "--server.address=0.0.0.0", \
     "--server.runOnSave=true"]
