# ============================================================================
# TERRAFORM KUBERNETES MODULE - Variables
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "app_version" {
  description = "Application version"
  type        = string
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
}

variable "app_image" {
  description = "Application Docker image"
  type        = string
}

variable "app_image_tag" {
  description = "Application Docker image tag"
  type        = string
}

variable "app_cpu_request" {
  description = "CPU request for application"
  type        = string
}

variable "app_cpu_limit" {
  description = "CPU limit for application"
  type        = string
}

variable "app_memory_request" {
  description = "Memory request for application"
  type        = string
}

variable "app_memory_limit" {
  description = "Memory limit for application"
  type        = string
}

variable "ollama_model" {
  description = "Ollama model to use"
  type        = string
}

variable "ollama_cpu_request" {
  description = "CPU request for Ollama"
  type        = string
}

variable "ollama_cpu_limit" {
  description = "CPU limit for Ollama"
  type        = string
}

variable "ollama_memory_request" {
  description = "Memory request for Ollama"
  type        = string
}

variable "ollama_memory_limit" {
  description = "Memory limit for Ollama"
  type        = string
}

variable "ollama_storage_size" {
  description = "Storage size for Ollama"
  type        = string
}

variable "chromadb_storage_size" {
  description = "Storage size for ChromaDB"
  type        = string
}

variable "documents_storage_size" {
  description = "Storage size for documents"
  type        = string
}

variable "storage_class_name" {
  description = "Kubernetes storage class name"
  type        = string
}

variable "enable_ingress" {
  description = "Whether to enable ingress"
  type        = bool
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
}

variable "enable_tls" {
  description = "Whether to enable TLS"
  type        = bool
}

variable "tls_secret_name" {
  description = "TLS secret name"
  type        = string
}

variable "app_settings" {
  description = "Application environment settings"
  type        = map(string)
}
