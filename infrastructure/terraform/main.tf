# ============================================================================
# TERRAFORM MAIN CONFIGURATION
# ============================================================================
# Student Research Assistant - Infrastructure as Code
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration - uncomment for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "research-assistant/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# ============================================================================
# LOCALS
# ============================================================================
locals {
  common_labels = {
    "app.kubernetes.io/name"       = var.app_name
    "app.kubernetes.io/version"    = var.app_version
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
  }

  namespace = var.namespace
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# Get current Kubernetes cluster info
data "kubernetes_namespace" "existing" {
  count = var.create_namespace ? 0 : 1
  metadata {
    name = local.namespace
  }
}

# ============================================================================
# MODULES
# ============================================================================

module "kubernetes" {
  source = "./modules/kubernetes"

  namespace       = local.namespace
  create_namespace = var.create_namespace
  common_labels   = local.common_labels
  environment     = var.environment

  # Application configuration
  app_name        = var.app_name
  app_version     = var.app_version
  app_replicas    = var.app_replicas
  app_image       = var.app_image
  app_image_tag   = var.app_image_tag

  # Resource configuration
  app_cpu_request    = var.app_cpu_request
  app_cpu_limit      = var.app_cpu_limit
  app_memory_request = var.app_memory_request
  app_memory_limit   = var.app_memory_limit

  # Ollama configuration
  ollama_cpu_request    = var.ollama_cpu_request
  ollama_cpu_limit      = var.ollama_cpu_limit
  ollama_memory_request = var.ollama_memory_request
  ollama_memory_limit   = var.ollama_memory_limit
  ollama_storage_size   = var.ollama_storage_size
  ollama_model          = var.ollama_model

  # ChromaDB configuration
  chromadb_storage_size = var.chromadb_storage_size

  # Storage configuration
  documents_storage_size = var.documents_storage_size
  storage_class_name     = var.storage_class_name

  # Ingress configuration
  enable_ingress     = var.enable_ingress
  ingress_host       = var.ingress_host
  ingress_class_name = var.ingress_class_name
  enable_tls         = var.enable_tls
  tls_secret_name    = var.tls_secret_name

  # Application settings
  app_settings = var.app_settings
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace"
  value       = local.namespace
}

output "app_service_name" {
  description = "Application service name"
  value       = module.kubernetes.app_service_name
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.enable_ingress ? var.ingress_host : "N/A (ingress disabled)"
}

output "ollama_service_endpoint" {
  description = "Ollama service endpoint (internal)"
  value       = module.kubernetes.ollama_service_endpoint
}

output "chromadb_service_endpoint" {
  description = "ChromaDB service endpoint (internal)"
  value       = module.kubernetes.chromadb_service_endpoint
}
