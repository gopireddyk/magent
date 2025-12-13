# ============================================================================
# TERRAFORM KUBERNETES MODULE
# ============================================================================
# Student Research Assistant - Kubernetes Resources
# ============================================================================

# ============================================================================
# NAMESPACE
# ============================================================================

resource "kubernetes_namespace" "research_assistant" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace
    labels = var.common_labels
  }
}

# ============================================================================
# CONFIGMAP
# ============================================================================

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
    labels    = var.common_labels
  }

  data = merge({
    RESEARCH_OLLAMA_BASE_URL     = "http://ollama-svc:11434"
    RESEARCH_OLLAMA_MODEL        = var.ollama_model
    RESEARCH_CHROMA_HOST         = "chromadb-svc"
    RESEARCH_CHROMA_PORT         = "8000"
    RESEARCH_ENVIRONMENT         = var.environment
    STREAMLIT_SERVER_PORT        = "8501"
    STREAMLIT_SERVER_ADDRESS     = "0.0.0.0"
    STREAMLIT_SERVER_HEADLESS    = "true"
  }, var.app_settings)

  depends_on = [kubernetes_namespace.research_assistant]
}

# ============================================================================
# PERSISTENT VOLUME CLAIMS
# ============================================================================

resource "kubernetes_persistent_volume_claim" "documents" {
  metadata {
    name      = "documents-pvc"
    namespace = var.namespace
    labels    = var.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.documents_storage_size
      }
    }
    storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
  }

  depends_on = [kubernetes_namespace.research_assistant]
}

# ============================================================================
# SERVICE ACCOUNT
# ============================================================================

resource "kubernetes_service_account" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels    = var.common_labels
  }

  depends_on = [kubernetes_namespace.research_assistant]
}

# ============================================================================
# APPLICATION DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels    = var.common_labels
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = var.app_name
        "app.kubernetes.io/component" = "app"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          "app.kubernetes.io/component" = "app"
        })
      }

      spec {
        service_account_name = kubernetes_service_account.app.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
        }

        container {
          name  = "app"
          image = "${var.app_image}:${var.app_image_tag}"

          port {
            name           = "http"
            container_port = 8501
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.app_cpu_request
              memory = var.app_memory_request
            }
            limits = {
              cpu    = var.app_cpu_limit
              memory = var.app_memory_limit
            }
          }

          volume_mount {
            name       = "documents"
            mount_path = "/app/data/documents"
          }

          liveness_probe {
            http_get {
              path = "/_stcore/health"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/_stcore/health"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
          }
        }

        volume {
          name = "documents"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.documents.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.research_assistant,
    kubernetes_config_map.app_config,
    kubernetes_persistent_volume_claim.documents
  ]
}

# ============================================================================
# APPLICATION SERVICE
# ============================================================================

resource "kubernetes_service" "app" {
  metadata {
    name      = "research-app-svc"
    namespace = var.namespace
    labels    = var.common_labels
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name"      = var.app_name
      "app.kubernetes.io/component" = "app"
    }

    port {
      name        = "http"
      port        = 8501
      target_port = "http"
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment.app]
}

# ============================================================================
# OLLAMA STATEFULSET
# ============================================================================

resource "kubernetes_stateful_set" "ollama" {
  metadata {
    name      = "ollama"
    namespace = var.namespace
    labels    = merge(var.common_labels, {
      "app.kubernetes.io/component" = "ollama"
    })
  }

  spec {
    service_name = "ollama"
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = var.app_name
        "app.kubernetes.io/component" = "ollama"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          "app.kubernetes.io/component" = "ollama"
        })
      }

      spec {
        container {
          name  = "ollama"
          image = "ollama/ollama:latest"

          port {
            name           = "http"
            container_port = 11434
            protocol       = "TCP"
          }

          env {
            name  = "OLLAMA_HOST"
            value = "0.0.0.0"
          }

          resources {
            requests = {
              cpu    = var.ollama_cpu_request
              memory = var.ollama_memory_request
            }
            limits = {
              cpu    = var.ollama_cpu_limit
              memory = var.ollama_memory_limit
            }
          }

          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }

          liveness_probe {
            http_get {
              path = "/api/tags"
              port = "http"
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/tags"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "ollama-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.ollama_storage_size
          }
        }
        storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
      }
    }
  }

  depends_on = [kubernetes_namespace.research_assistant]
}

# ============================================================================
# OLLAMA SERVICE
# ============================================================================

resource "kubernetes_service" "ollama" {
  metadata {
    name      = "ollama-svc"
    namespace = var.namespace
    labels    = merge(var.common_labels, {
      "app.kubernetes.io/component" = "ollama"
    })
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name"      = var.app_name
      "app.kubernetes.io/component" = "ollama"
    }

    port {
      name        = "http"
      port        = 11434
      target_port = "http"
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_stateful_set.ollama]
}

# ============================================================================
# CHROMADB STATEFULSET
# ============================================================================

resource "kubernetes_stateful_set" "chromadb" {
  metadata {
    name      = "chromadb"
    namespace = var.namespace
    labels    = merge(var.common_labels, {
      "app.kubernetes.io/component" = "chromadb"
    })
  }

  spec {
    service_name = "chromadb"
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = var.app_name
        "app.kubernetes.io/component" = "chromadb"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          "app.kubernetes.io/component" = "chromadb"
        })
      }

      spec {
        container {
          name  = "chromadb"
          image = "chromadb/chroma:latest"

          port {
            name           = "http"
            container_port = 8000
            protocol       = "TCP"
          }

          env {
            name  = "IS_PERSISTENT"
            value = "TRUE"
          }
          env {
            name  = "PERSIST_DIRECTORY"
            value = "/chroma/chroma"
          }
          env {
            name  = "ANONYMIZED_TELEMETRY"
            value = "FALSE"
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }

          volume_mount {
            name       = "chroma-data"
            mount_path = "/chroma/chroma"
          }

          liveness_probe {
            http_get {
              path = "/api/v1/heartbeat"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/v1/heartbeat"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "chroma-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.chromadb_storage_size
          }
        }
        storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
      }
    }
  }

  depends_on = [kubernetes_namespace.research_assistant]
}

# ============================================================================
# CHROMADB SERVICE
# ============================================================================

resource "kubernetes_service" "chromadb" {
  metadata {
    name      = "chromadb-svc"
    namespace = var.namespace
    labels    = merge(var.common_labels, {
      "app.kubernetes.io/component" = "chromadb"
    })
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name"      = var.app_name
      "app.kubernetes.io/component" = "chromadb"
    }

    port {
      name        = "http"
      port        = 8000
      target_port = "http"
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_stateful_set.chromadb]
}

# ============================================================================
# INGRESS
# ============================================================================

resource "kubernetes_ingress_v1" "app" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = var.namespace
    labels    = var.common_labels

    annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = var.tls_secret_name
      }
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 8501
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.app]
}
