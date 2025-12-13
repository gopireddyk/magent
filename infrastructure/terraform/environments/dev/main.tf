# ============================================================================
# TERRAFORM - Development Environment
# ============================================================================
# Student Research Assistant - Dev Configuration
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context != "" ? var.kubeconfig_context : null
}

# ============================================================================
# ROOT MODULE
# ============================================================================

module "research_assistant" {
  source = "../../"

  # Environment
  environment      = "dev"
  namespace        = "research-assistant-dev"
  create_namespace = true

  # Application (reduced for development)
  app_name      = "research-assistant"
  app_version   = "1.0.0-dev"
  app_replicas  = 1
  app_image     = "student-research-assistant"
  app_image_tag = "dev"

  # Reduced resources for development
  app_cpu_request    = "250m"
  app_cpu_limit      = "1000m"
  app_memory_request = "512Mi"
  app_memory_limit   = "2Gi"

  # Ollama (reduced for development)
  ollama_model          = "llama3.2"
  ollama_cpu_request    = "1000m"
  ollama_cpu_limit      = "2000m"
  ollama_memory_request = "4Gi"
  ollama_memory_limit   = "8Gi"
  ollama_storage_size   = "30Gi"

  # ChromaDB
  chromadb_storage_size = "10Gi"

  # Storage
  documents_storage_size = "5Gi"
  storage_class_name     = ""  # Use default

  # Ingress
  enable_ingress     = true
  ingress_host       = "research-dev.local"
  ingress_class_name = "nginx"
  enable_tls         = false
  tls_secret_name    = ""

  # Development settings
  app_settings = {
    RESEARCH_LOG_LEVEL           = "DEBUG"
    RESEARCH_LOG_JSON            = "false"
    RESEARCH_DEBUG               = "true"
    RESEARCH_LLM_TEMPERATURE     = "0.7"
    RESEARCH_MAX_ITERATIONS      = "3"
    RESEARCH_RETRIEVAL_TOP_K     = "5"
  }

  # Kubernetes connection
  kubeconfig_path    = var.kubeconfig_path
  kubeconfig_context = var.kubeconfig_context
}

# ============================================================================
# VARIABLES
# ============================================================================

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace"
  value       = module.research_assistant.namespace
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.research_assistant.ingress_host}"
}

output "access_instructions" {
  description = "Instructions to access the application"
  value       = <<-EOT

    ========================================
    Development Environment Deployed!
    ========================================

    1. Add to /etc/hosts:
       127.0.0.1 research-dev.local

    2. Port forward (if no ingress controller):
       kubectl -n research-assistant-dev port-forward svc/research-app-svc 8501:8501

    3. Access the application:
       http://research-dev.local (with ingress)
       http://localhost:8501 (with port-forward)

    4. Pull Ollama models (if not done):
       kubectl -n research-assistant-dev exec -it ollama-0 -- ollama pull llama3.2

  EOT
}
