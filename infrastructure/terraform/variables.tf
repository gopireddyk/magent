# ============================================================================
# TERRAFORM VARIABLES
# ============================================================================
# Student Research Assistant - Variable Definitions
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "research-assistant"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "research-assistant"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "1.0.0"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2

  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "App replicas must be between 1 and 10."
  }
}

variable "app_image" {
  description = "Application Docker image"
  type        = string
  default     = "student-research-assistant"
}

variable "app_image_tag" {
  description = "Application Docker image tag"
  type        = string
  default     = "latest"
}

# ============================================================================
# APPLICATION RESOURCES
# ============================================================================

variable "app_cpu_request" {
  description = "CPU request for application"
  type        = string
  default     = "500m"
}

variable "app_cpu_limit" {
  description = "CPU limit for application"
  type        = string
  default     = "2000m"
}

variable "app_memory_request" {
  description = "Memory request for application"
  type        = string
  default     = "1Gi"
}

variable "app_memory_limit" {
  description = "Memory limit for application"
  type        = string
  default     = "4Gi"
}

# ============================================================================
# OLLAMA CONFIGURATION
# ============================================================================

variable "ollama_model" {
  description = "Default Ollama model to use"
  type        = string
  default     = "llama3.2"
}

variable "ollama_cpu_request" {
  description = "CPU request for Ollama"
  type        = string
  default     = "2000m"
}

variable "ollama_cpu_limit" {
  description = "CPU limit for Ollama"
  type        = string
  default     = "4000m"
}

variable "ollama_memory_request" {
  description = "Memory request for Ollama"
  type        = string
  default     = "8Gi"
}

variable "ollama_memory_limit" {
  description = "Memory limit for Ollama"
  type        = string
  default     = "16Gi"
}

variable "ollama_storage_size" {
  description = "Storage size for Ollama models"
  type        = string
  default     = "50Gi"
}

# ============================================================================
# CHROMADB CONFIGURATION
# ============================================================================

variable "chromadb_storage_size" {
  description = "Storage size for ChromaDB"
  type        = string
  default     = "20Gi"
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "documents_storage_size" {
  description = "Storage size for documents"
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "Kubernetes storage class name"
  type        = string
  default     = ""  # Empty means use default storage class
}

# ============================================================================
# INGRESS CONFIGURATION
# ============================================================================

variable "enable_ingress" {
  description = "Whether to create an ingress resource"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = "research.local"
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "enable_tls" {
  description = "Whether to enable TLS for ingress"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "research-assistant-tls"
}

# ============================================================================
# APPLICATION SETTINGS
# ============================================================================

variable "app_settings" {
  description = "Application environment settings"
  type        = map(string)
  default = {
    RESEARCH_LOG_LEVEL          = "INFO"
    RESEARCH_LOG_JSON           = "true"
    RESEARCH_LLM_TEMPERATURE    = "0.7"
    RESEARCH_LLM_MAX_TOKENS     = "2048"
    RESEARCH_CHUNK_SIZE         = "1000"
    RESEARCH_CHUNK_OVERLAP      = "200"
    RESEARCH_MAX_ITERATIONS     = "5"
    RESEARCH_RETRIEVAL_TOP_K    = "5"
    RESEARCH_RETRIEVAL_THRESHOLD = "0.5"
  }
}

# ============================================================================
# KUBERNETES PROVIDER CONFIGURATION
# ============================================================================

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""  # Empty means use current context
}
