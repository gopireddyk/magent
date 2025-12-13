# ============================================================================
# TERRAFORM KUBERNETES MODULE - Outputs
# ============================================================================

output "app_service_name" {
  description = "Application service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "ollama_service_endpoint" {
  description = "Ollama service endpoint"
  value       = "http://${kubernetes_service.ollama.metadata[0].name}:11434"
}

output "chromadb_service_endpoint" {
  description = "ChromaDB service endpoint"
  value       = "http://${kubernetes_service.chromadb.metadata[0].name}:8000"
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.enable_ingress ? var.ingress_host : null
}
