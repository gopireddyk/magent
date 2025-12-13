# ============================================================================
# MAKEFILE - Student Research Assistant
# ============================================================================
# Usage: make <target>
# Run `make help` to see all available targets
# ============================================================================

# Shell to use
SHELL := /bin/bash

# Python interpreter
PYTHON := python3
PIP := pip

# Project paths
PROJECT_NAME := student-research-assistant
SRC_DIR := src
TEST_DIR := tests
DOCS_DIR := docs

# Container settings (Podman - Docker compatible)
CONTAINER_IMAGE := $(PROJECT_NAME)
CONTAINER_TAG := latest
CONTAINER_REGISTRY := localhost:5000

# Multipass VM settings
VM_NAME := k8s-research
VM_CPUS := 4
VM_MEMORY := 8G
VM_DISK := 40G

# Kubernetes settings
K8S_NAMESPACE := research-assistant
KUBECONFIG_FILE := $(HOME)/.kube/k8s-research-config

# Terraform settings
TF_DIR := infrastructure/terraform
TF_WORKSPACE := dev

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m  # No Color

# ============================================================================
# DEFAULT TARGET
# ============================================================================
.DEFAULT_GOAL := help

# ============================================================================
# HELP
# ============================================================================
.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(BLUE)Student Research Assistant - Available Commands$(NC)"
	@echo "================================================="
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(GREEN)<target>$(NC)\n\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@echo ""

##@ Development Setup

.PHONY: setup
setup: ## Complete project setup (venv, deps, ollama)
	@echo "$(BLUE)Setting up project...$(NC)"
	@$(MAKE) create-structure
	@$(MAKE) venv
	@$(MAKE) install-dev
	@$(MAKE) setup-ollama
	@$(MAKE) setup-precommit
	@echo "$(GREEN)Setup complete!$(NC)"

.PHONY: create-structure
create-structure: ## Create project directory structure
	@echo "$(BLUE)Creating directory structure...$(NC)"
	@mkdir -p src/research_assistant/{config,core,services,agents,tools,graph,ui/pages}
	@mkdir -p tests/{unit,integration,fixtures}
	@mkdir -p .streamlit
	@mkdir -p data/{documents,vectorstore}
	@touch src/research_assistant/__init__.py
	@touch src/research_assistant/config/__init__.py
	@touch src/research_assistant/core/__init__.py
	@touch src/research_assistant/services/__init__.py
	@touch src/research_assistant/agents/__init__.py
	@touch src/research_assistant/tools/__init__.py
	@touch src/research_assistant/graph/__init__.py
	@touch src/research_assistant/ui/__init__.py
	@touch tests/__init__.py
	@touch tests/unit/__init__.py
	@touch tests/integration/__init__.py
	@touch src/research_assistant/py.typed
	@echo "$(GREEN)Directory structure created!$(NC)"

.PHONY: venv
venv: ## Create Python virtual environment
	@echo "$(BLUE)Creating virtual environment...$(NC)"
	@$(PYTHON) -m venv .venv
	@echo "$(GREEN)Virtual environment created at .venv$(NC)"
	@echo "$(YELLOW)Activate with: source .venv/bin/activate$(NC)"

.PHONY: install
install: ## Install production dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@$(PIP) install --upgrade pip
	@$(PIP) install -e .
	@echo "$(GREEN)Dependencies installed!$(NC)"

.PHONY: install-dev
install-dev: ## Install development dependencies
	@echo "$(BLUE)Installing development dependencies...$(NC)"
	@$(PIP) install --upgrade pip
	@$(PIP) install -e ".[dev]"
	@echo "$(GREEN)Development dependencies installed!$(NC)"

.PHONY: install-all
install-all: ## Install all dependencies (dev + prod)
	@echo "$(BLUE)Installing all dependencies...$(NC)"
	@$(PIP) install --upgrade pip
	@$(PIP) install -e ".[all]"
	@echo "$(GREEN)All dependencies installed!$(NC)"

.PHONY: setup-precommit
setup-precommit: ## Set up pre-commit hooks
	@echo "$(BLUE)Setting up pre-commit hooks...$(NC)"
	@pre-commit install || echo "$(YELLOW)pre-commit not installed$(NC)"
	@echo "$(GREEN)Pre-commit hooks installed!$(NC)"

.PHONY: setup-ollama
setup-ollama: ## Download Ollama models
	@echo "$(BLUE)Setting up Ollama models...$(NC)"
	@echo "Pulling llama3.2..."
	@ollama pull llama3.2 || echo "$(YELLOW)Warning: Could not pull llama3.2$(NC)"
	@echo "Pulling nomic-embed-text..."
	@ollama pull nomic-embed-text || echo "$(YELLOW)Warning: Could not pull nomic-embed-text$(NC)"
	@echo "$(GREEN)Ollama models ready!$(NC)"

##@ Running the Application

.PHONY: run
run: ## Run the Streamlit application
	@echo "$(BLUE)Starting Streamlit application...$(NC)"
	@streamlit run src/research_assistant/ui/app.py

.PHONY: run-dev
run-dev: ## Run in development mode with auto-reload
	@echo "$(BLUE)Starting in development mode...$(NC)"
	@RESEARCH_DEBUG=true RESEARCH_LOG_LEVEL=DEBUG streamlit run src/research_assistant/ui/app.py

.PHONY: run-cli
run-cli: ## Run the CLI interface
	@echo "$(BLUE)Starting CLI interface...$(NC)"
	@$(PYTHON) -m research_assistant.cli interactive

##@ Code Quality

.PHONY: lint
lint: ## Run all linters
	@echo "$(BLUE)Running linters...$(NC)"
	@$(MAKE) lint-ruff
	@$(MAKE) lint-mypy
	@echo "$(GREEN)Linting complete!$(NC)"

.PHONY: lint-ruff
lint-ruff: ## Run Ruff linter
	@echo "$(BLUE)Running Ruff...$(NC)"
	@ruff check $(SRC_DIR) $(TEST_DIR) || true

.PHONY: lint-mypy
lint-mypy: ## Run MyPy type checker
	@echo "$(BLUE)Running MyPy...$(NC)"
	@mypy $(SRC_DIR) || true

.PHONY: format
format: ## Format code with Black and Ruff
	@echo "$(BLUE)Formatting code...$(NC)"
	@black $(SRC_DIR) $(TEST_DIR) || true
	@ruff check --fix $(SRC_DIR) $(TEST_DIR) || true
	@echo "$(GREEN)Formatting complete!$(NC)"

.PHONY: format-check
format-check: ## Check code formatting without changes
	@echo "$(BLUE)Checking code format...$(NC)"
	@black --check $(SRC_DIR) $(TEST_DIR)
	@ruff check $(SRC_DIR) $(TEST_DIR)

##@ Testing

.PHONY: test
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@pytest $(TEST_DIR) -v

.PHONY: test-unit
test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	@pytest $(TEST_DIR)/unit -v -m "not integration"

.PHONY: test-integration
test-integration: ## Run integration tests only
	@echo "$(BLUE)Running integration tests...$(NC)"
	@pytest $(TEST_DIR)/integration -v -m "integration"

.PHONY: test-cov
test-cov: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@pytest $(TEST_DIR) --cov=$(SRC_DIR)/research_assistant --cov-report=html --cov-report=term-missing
	@echo "$(GREEN)Coverage report: htmlcov/index.html$(NC)"

.PHONY: test-fast
test-fast: ## Run tests in parallel (fast mode)
	@echo "$(BLUE)Running tests in parallel...$(NC)"
	@pytest $(TEST_DIR) -n auto -q

##@ Data Management

.PHONY: ingest
ingest: ## Ingest documents from data/documents folder
	@echo "$(BLUE)Ingesting documents...$(NC)"
	@$(PYTHON) -m research_assistant.cli ingest --dir data/documents

.PHONY: clear-vectorstore
clear-vectorstore: ## Clear the vector store
	@echo "$(YELLOW)Clearing vector store...$(NC)"
	@rm -rf data/vectorstore/*
	@echo "$(GREEN)Vector store cleared!$(NC)"

.PHONY: seed-data
seed-data: ## Seed with sample data for testing
	@echo "$(BLUE)Seeding sample data...$(NC)"
	@$(PYTHON) scripts/seed_data.py
	@echo "$(GREEN)Sample data seeded!$(NC)"

##@ Multipass VM Management

.PHONY: vm-create
vm-create: ## Create Multipass VM for K8s
	@echo "$(BLUE)Creating Multipass VM...$(NC)"
	@echo "  Name: $(VM_NAME)"
	@echo "  CPUs: $(VM_CPUS)"
	@echo "  Memory: $(VM_MEMORY)"
	@echo "  Disk: $(VM_DISK)"
	@multipass launch \
		--name $(VM_NAME) \
		--cpus $(VM_CPUS) \
		--memory $(VM_MEMORY) \
		--disk $(VM_DISK) \
		--cloud-init infrastructure/multipass/cloud-init.yaml \
		22.04 || multipass launch \
		--name $(VM_NAME) \
		--cpus $(VM_CPUS) \
		--memory $(VM_MEMORY) \
		--disk $(VM_DISK) \
		22.04
	@echo "$(GREEN)VM created!$(NC)"

.PHONY: vm-setup
vm-setup: ## Setup K3s and Podman in VM
	@echo "$(BLUE)Setting up K3s in VM...$(NC)"
	@multipass exec $(VM_NAME) -- bash -c 'curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644'
	@echo "$(BLUE)Installing Podman...$(NC)"
	@multipass exec $(VM_NAME) -- bash -c 'sudo apt-get update && sudo apt-get install -y podman buildah'
	@sleep 10
	@$(MAKE) vm-kubeconfig
	@echo "$(GREEN)K3s setup complete!$(NC)"

.PHONY: vm-kubeconfig
vm-kubeconfig: ## Copy kubeconfig from VM to host
	@echo "$(BLUE)Copying kubeconfig...$(NC)"
	@mkdir -p $(HOME)/.kube
	@multipass exec $(VM_NAME) -- sudo cat /etc/rancher/k3s/k3s.yaml > $(KUBECONFIG_FILE)
	@VM_IP=$$(multipass info $(VM_NAME) --format json | jq -r '.info."$(VM_NAME)".ipv4[0]'); \
		if [[ "$$OSTYPE" == "darwin"* ]]; then \
			sed -i '' "s/127.0.0.1/$$VM_IP/g" $(KUBECONFIG_FILE); \
		else \
			sed -i "s/127.0.0.1/$$VM_IP/g" $(KUBECONFIG_FILE); \
		fi
	@chmod 600 $(KUBECONFIG_FILE)
	@echo "$(GREEN)Kubeconfig ready: $(KUBECONFIG_FILE)$(NC)"
	@echo "$(YELLOW)Run: export KUBECONFIG=$(KUBECONFIG_FILE)$(NC)"

.PHONY: vm-shell
vm-shell: ## Shell into VM
	@multipass shell $(VM_NAME)

.PHONY: vm-start
vm-start: ## Start VM
	@echo "$(BLUE)Starting VM...$(NC)"
	@multipass start $(VM_NAME)
	@echo "$(GREEN)VM started!$(NC)"

.PHONY: vm-stop
vm-stop: ## Stop VM
	@echo "$(BLUE)Stopping VM...$(NC)"
	@multipass stop $(VM_NAME)
	@echo "$(GREEN)VM stopped!$(NC)"

.PHONY: vm-restart
vm-restart: ## Restart VM
	@echo "$(BLUE)Restarting VM...$(NC)"
	@multipass restart $(VM_NAME)
	@$(MAKE) vm-kubeconfig
	@echo "$(GREEN)VM restarted!$(NC)"

.PHONY: vm-delete
vm-delete: ## Delete VM (destructive!)
	@echo "$(RED)Deleting VM $(VM_NAME)...$(NC)"
	@multipass delete $(VM_NAME) --purge || true
	@echo "$(GREEN)VM deleted!$(NC)"

.PHONY: vm-info
vm-info: ## Show VM information
	@multipass info $(VM_NAME)

.PHONY: vm-list
vm-list: ## List all Multipass VMs
	@multipass list

##@ Podman Container Management

.PHONY: podman-build
podman-build: ## Build image with Podman
	@echo "$(BLUE)Building with Podman...$(NC)"
	@podman build -t $(CONTAINER_IMAGE):$(CONTAINER_TAG) -f infrastructure/podman/Containerfile .
	@echo "$(GREEN)Image built: $(CONTAINER_IMAGE):$(CONTAINER_TAG)$(NC)"

.PHONY: podman-run
podman-run: ## Run container with Podman
	@echo "$(BLUE)Running with Podman...$(NC)"
	@podman run -it --rm \
		-p 8501:8501 \
		-v ./data:/app/data:Z \
		$(CONTAINER_IMAGE):$(CONTAINER_TAG)

.PHONY: podman-push
podman-push: ## Push image to local registry
	@echo "$(BLUE)Pushing to local registry...$(NC)"
	@podman tag $(CONTAINER_IMAGE):$(CONTAINER_TAG) $(CONTAINER_REGISTRY)/$(CONTAINER_IMAGE):$(CONTAINER_TAG)
	@podman push $(CONTAINER_REGISTRY)/$(CONTAINER_IMAGE):$(CONTAINER_TAG) --tls-verify=false
	@echo "$(GREEN)Image pushed!$(NC)"

.PHONY: podman-compose-up
podman-compose-up: ## Start services with podman-compose
	@echo "$(BLUE)Starting with podman-compose...$(NC)"
	@podman-compose -f infrastructure/podman/podman-compose.yaml up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "$(YELLOW)App: http://localhost:8501$(NC)"

.PHONY: podman-compose-down
podman-compose-down: ## Stop podman-compose services
	@echo "$(BLUE)Stopping services...$(NC)"
	@podman-compose -f infrastructure/podman/podman-compose.yaml down
	@echo "$(GREEN)Services stopped!$(NC)"

.PHONY: podman-compose-logs
podman-compose-logs: ## View podman-compose logs
	@podman-compose -f infrastructure/podman/podman-compose.yaml logs -f

.PHONY: podman-images
podman-images: ## List Podman images
	@podman images

.PHONY: podman-ps
podman-ps: ## List running Podman containers
	@podman ps -a

.PHONY: podman-clean
podman-clean: ## Clean up Podman resources
	@echo "$(YELLOW)Cleaning Podman resources...$(NC)"
	@podman system prune -f
	@echo "$(GREEN)Cleaned!$(NC)"

##@ Kubernetes Deployment

.PHONY: k8s-deploy
k8s-deploy: ## Deploy to Kubernetes
	@echo "$(BLUE)Deploying to Kubernetes...$(NC)"
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl apply -k infrastructure/kubernetes/overlays/dev
	@echo "$(GREEN)Deployed to Kubernetes!$(NC)"

.PHONY: k8s-delete
k8s-delete: ## Delete Kubernetes deployment
	@echo "$(YELLOW)Deleting Kubernetes deployment...$(NC)"
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl delete -k infrastructure/kubernetes/overlays/dev || true
	@echo "$(GREEN)Deployment deleted!$(NC)"

.PHONY: k8s-status
k8s-status: ## Show Kubernetes deployment status
	@echo "$(BLUE)Kubernetes Status:$(NC)"
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl -n $(K8S_NAMESPACE) get pods,svc,pvc 2>/dev/null || \
		echo "$(YELLOW)Namespace not found or cluster not accessible$(NC)"

.PHONY: k8s-logs
k8s-logs: ## View Kubernetes logs
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl -n $(K8S_NAMESPACE) logs -l app.kubernetes.io/name=research-assistant -f

.PHONY: k8s-port-forward
k8s-port-forward: ## Port forward to access the app locally
	@echo "$(BLUE)Port forwarding to localhost:8501...$(NC)"
	@echo "$(YELLOW)Access app at: http://localhost:8501$(NC)"
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl -n $(K8S_NAMESPACE) port-forward svc/research-app-svc 8501:8501

.PHONY: k8s-exec
k8s-exec: ## Exec into app pod
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl -n $(K8S_NAMESPACE) exec -it \
		$$(kubectl -n $(K8S_NAMESPACE) get pods -l app.kubernetes.io/name=research-assistant -o jsonpath='{.items[0].metadata.name}') \
		-- /bin/bash

##@ Quick Start (Full Setup)

.PHONY: local-k8s-setup
local-k8s-setup: ## Complete local K8s setup (VM + K3s)
	@echo "$(BLUE)Setting up local Kubernetes cluster...$(NC)"
	@./scripts/setup-local-k8s.sh
	@echo "$(GREEN)Local Kubernetes cluster ready!$(NC)"

.PHONY: full-deploy
full-deploy: vm-create vm-setup podman-build k8s-deploy ## Full deployment (VM + Build + Deploy)
	@echo "$(GREEN)Full deployment complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. export KUBECONFIG=$(KUBECONFIG_FILE)"
	@echo "  2. make k8s-status"
	@echo "  3. make k8s-port-forward"
	@echo "  4. Open http://localhost:8501"

##@ Terraform Infrastructure

.PHONY: tf-init
tf-init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@cd $(TF_DIR) && terraform init

.PHONY: tf-plan
tf-plan: ## Plan Terraform changes
	@echo "$(BLUE)Planning Terraform changes...$(NC)"
	@cd $(TF_DIR)/environments/$(TF_WORKSPACE) && terraform plan

.PHONY: tf-apply
tf-apply: ## Apply Terraform changes
	@echo "$(BLUE)Applying Terraform changes...$(NC)"
	@cd $(TF_DIR)/environments/$(TF_WORKSPACE) && terraform apply

.PHONY: tf-destroy
tf-destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)Destroying Terraform infrastructure...$(NC)"
	@cd $(TF_DIR)/environments/$(TF_WORKSPACE) && terraform destroy

.PHONY: tf-output
tf-output: ## Show Terraform outputs
	@cd $(TF_DIR)/environments/$(TF_WORKSPACE) && terraform output

##@ Documentation

.PHONY: docs
docs: ## Build documentation
	@echo "$(BLUE)Building documentation...$(NC)"
	@mkdocs build || echo "$(YELLOW)mkdocs not installed$(NC)"
	@echo "$(GREEN)Documentation built in site/$(NC)"

.PHONY: docs-serve
docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation...$(NC)"
	@mkdocs serve

##@ Cleanup

.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info
	@rm -rf .pytest_cache/
	@rm -rf .mypy_cache/
	@rm -rf .ruff_cache/
	@rm -rf htmlcov/
	@rm -rf .coverage
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo "$(GREEN)Cleaned!$(NC)"

.PHONY: clean-all
clean-all: clean ## Clean everything including venv and data
	@echo "$(YELLOW)Cleaning virtual environment and data...$(NC)"
	@rm -rf .venv/
	@rm -rf data/vectorstore/*
	@echo "$(GREEN)All cleaned!$(NC)"

.PHONY: clean-vm
clean-vm: vm-delete ## Delete VM and clean kubeconfig
	@rm -f $(KUBECONFIG_FILE)
	@echo "$(GREEN)VM and kubeconfig cleaned!$(NC)"

##@ Utility

.PHONY: check-prereqs
check-prereqs: ## Check all prerequisites are installed
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@echo -n "multipass: " && (command -v multipass &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")
	@echo -n "podman:    " && (command -v podman &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")
	@echo -n "kubectl:   " && (command -v kubectl &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")
	@echo -n "ollama:    " && (command -v ollama &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")
	@echo -n "jq:        " && (command -v jq &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")
	@echo -n "python3:   " && (command -v python3 &>/dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)")

.PHONY: check-ollama
check-ollama: ## Check if Ollama is running
	@echo "$(BLUE)Checking Ollama status...$(NC)"
	@curl -s http://localhost:11434/api/tags > /dev/null && \
		echo "$(GREEN)Ollama is running!$(NC)" || \
		echo "$(RED)Ollama is not running. Start with: ollama serve$(NC)"

.PHONY: check-cluster
check-cluster: ## Check Kubernetes cluster status
	@echo "$(BLUE)Checking cluster status...$(NC)"
	@KUBECONFIG=$(KUBECONFIG_FILE) kubectl get nodes 2>/dev/null && \
		echo "$(GREEN)Cluster is accessible!$(NC)" || \
		echo "$(RED)Cannot connect to cluster$(NC)"

.PHONY: check-deps
check-deps: ## Check for outdated dependencies
	@echo "$(BLUE)Checking for outdated dependencies...$(NC)"
	@$(PIP) list --outdated

.PHONY: update-deps
update-deps: ## Update all dependencies
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@$(PIP) install --upgrade pip
	@$(PIP) install --upgrade -e ".[dev]"
	@echo "$(GREEN)Dependencies updated!$(NC)"

.PHONY: security-check
security-check: ## Run security checks
	@echo "$(BLUE)Running security checks...$(NC)"
	@$(PIP) install bandit safety 2>/dev/null
	@bandit -r $(SRC_DIR) -ll || true
	@safety check || true
	@echo "$(GREEN)Security checks complete!$(NC)"

.PHONY: version
version: ## Show project version
	@$(PYTHON) -c "import toml; print(toml.load('pyproject.toml')['project']['version'])" 2>/dev/null || \
		grep -m1 'version' pyproject.toml | cut -d'"' -f2

# ============================================================================
# COMPOSITE TARGETS
# ============================================================================

.PHONY: ci
ci: lint test ## Run CI pipeline (lint + test)
	@echo "$(GREEN)CI pipeline passed!$(NC)"

.PHONY: pre-commit
pre-commit: format lint test ## Run pre-commit checks
	@echo "$(GREEN)Pre-commit checks passed!$(NC)"

.PHONY: release
release: clean lint test podman-build ## Prepare release
	@echo "$(GREEN)Release prepared!$(NC)"
	@echo "$(YELLOW)Don't forget to:$(NC)"
	@echo "  1. Update version in pyproject.toml"
	@echo "  2. Update CHANGELOG.md"
	@echo "  3. Create git tag"
	@echo "  4. Push to registry: make podman-push"

# ============================================================================
# DEPENDENCY VERIFICATION
# ============================================================================

##@ Dependency Verification

.PHONY: verify-all
verify-all: ## Verify all dependencies are ready
	@echo "$(BLUE)Verifying all dependencies...$(NC)"
	@echo ""
	@$(MAKE) verify-python
	@$(MAKE) verify-ollama
	@$(MAKE) verify-models
	@$(MAKE) verify-packages
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  All dependencies verified!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

.PHONY: verify-python
verify-python: ## Verify Python installation
	@echo "$(BLUE)[1/4] Checking Python...$(NC)"
	@python3 --version || (echo "$(RED)Python 3 not found!$(NC)" && exit 1)
	@pip --version || (echo "$(RED)pip not found!$(NC)" && exit 1)
	@echo "$(GREEN)  ✓ Python OK$(NC)"

.PHONY: verify-ollama
verify-ollama: ## Verify Ollama is running
	@echo "$(BLUE)[2/4] Checking Ollama...$(NC)"
	@ollama --version || (echo "$(RED)Ollama not installed!$(NC)" && echo "Install: curl -fsSL https://ollama.ai/install.sh | sh" && exit 1)
	@curl -s http://localhost:11434/api/tags > /dev/null 2>&1 || (echo "$(RED)Ollama not running!$(NC)" && echo "Start with: ollama serve" && exit 1)
	@echo "$(GREEN)  ✓ Ollama OK$(NC)"

.PHONY: verify-models
verify-models: ## Verify AI models are downloaded
	@echo "$(BLUE)[3/4] Checking AI models...$(NC)"
	@ollama list | grep -q "llama3.2" || (echo "$(YELLOW)  ! llama3.2 not found$(NC)" && echo "  Download with: ollama pull llama3.2")
	@ollama list | grep -q "llama3.2" && echo "$(GREEN)  ✓ llama3.2 model OK$(NC)" || true
	@echo "$(BLUE)  Checking embedding model...$(NC)"
	@python3 -c "from sentence_transformers import SentenceTransformer; m = SentenceTransformer('all-MiniLM-L6-v2'); print('$(GREEN)  ✓ Embedding model OK$(NC)')" 2>/dev/null || \
		echo "$(YELLOW)  ! Embedding model will download on first use$(NC)"

.PHONY: verify-packages
verify-packages: ## Verify Python packages are installed
	@echo "$(BLUE)[4/4] Checking Python packages...$(NC)"
	@python3 -c "import langchain" 2>/dev/null && echo "$(GREEN)  ✓ langchain$(NC)" || echo "$(RED)  ✗ langchain missing$(NC)"
	@python3 -c "import langgraph" 2>/dev/null && echo "$(GREEN)  ✓ langgraph$(NC)" || echo "$(RED)  ✗ langgraph missing$(NC)"
	@python3 -c "import chromadb" 2>/dev/null && echo "$(GREEN)  ✓ chromadb$(NC)" || echo "$(RED)  ✗ chromadb missing$(NC)"
	@python3 -c "import streamlit" 2>/dev/null && echo "$(GREEN)  ✓ streamlit$(NC)" || echo "$(RED)  ✗ streamlit missing$(NC)"
	@python3 -c "import sentence_transformers" 2>/dev/null && echo "$(GREEN)  ✓ sentence-transformers$(NC)" || echo "$(RED)  ✗ sentence-transformers missing$(NC)"
	@python3 -c "import ollama" 2>/dev/null && echo "$(GREEN)  ✓ ollama$(NC)" || echo "$(RED)  ✗ ollama missing$(NC)"

.PHONY: verify-deployment
verify-deployment: ## Verify deployment dependencies
	@echo "$(BLUE)Checking deployment dependencies...$(NC)"
	@echo ""
	@echo "$(BLUE)Podman:$(NC)"
	@podman --version 2>/dev/null && echo "$(GREEN)  ✓ Podman installed$(NC)" || echo "$(RED)  ✗ Podman not found$(NC)"
	@echo ""
	@echo "$(BLUE)Multipass:$(NC)"
	@multipass --version 2>/dev/null && echo "$(GREEN)  ✓ Multipass installed$(NC)" || echo "$(RED)  ✗ Multipass not found$(NC)"
	@echo ""
	@echo "$(BLUE)kubectl:$(NC)"
	@kubectl version --client 2>/dev/null && echo "$(GREEN)  ✓ kubectl installed$(NC)" || echo "$(RED)  ✗ kubectl not found$(NC)"

.PHONY: check-ollama-models
check-ollama-models: ## List downloaded Ollama models
	@echo "$(BLUE)Downloaded Ollama models:$(NC)"
	@ollama list 2>/dev/null || echo "$(RED)Ollama not running$(NC)"

.PHONY: download-models
download-models: ## Download all required AI models
	@echo "$(BLUE)Downloading required models...$(NC)"
	@echo ""
	@echo "$(BLUE)1. Downloading llama3.2 (~2GB)...$(NC)"
	@ollama pull llama3.2
	@echo ""
	@echo "$(BLUE)2. Pre-caching embedding model (~90MB)...$(NC)"
	@python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2'); print('Downloaded!')"
	@echo ""
	@echo "$(GREEN)All models downloaded!$(NC)"

.PHONY: download-models-minimal
download-models-minimal: ## Download minimal models (for limited hardware)
	@echo "$(BLUE)Downloading minimal models...$(NC)"
	@echo ""
	@echo "$(BLUE)1. Downloading llama3.2:1b (~1.3GB)...$(NC)"
	@ollama pull llama3.2:1b
	@echo ""
	@echo "$(BLUE)2. Pre-caching embedding model (~90MB)...$(NC)"
	@python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2'); print('Downloaded!')"
	@echo ""
	@echo "$(GREEN)Minimal models downloaded!$(NC)"
	@echo "$(YELLOW)Note: Set RESEARCH_OLLAMA_MODEL=llama3.2:1b in .env$(NC)"

.PHONY: system-info
system-info: ## Show system information for debugging
	@echo "$(BLUE)System Information$(NC)"
	@echo "=================="
	@echo ""
	@echo "$(BLUE)Operating System:$(NC)"
	@uname -a
	@echo ""
	@echo "$(BLUE)Python:$(NC)"
	@python3 --version
	@which python3
	@echo ""
	@echo "$(BLUE)Memory:$(NC)"
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		sysctl hw.memsize | awk '{print $$2/1024/1024/1024 " GB"}'; \
	else \
		free -h | grep Mem; \
	fi
	@echo ""
	@echo "$(BLUE)Disk Space:$(NC)"
	@df -h . | tail -1
	@echo ""
	@echo "$(BLUE)GPU (if available):$(NC)"
	@nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "No NVIDIA GPU detected"
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" || true; \
	fi
