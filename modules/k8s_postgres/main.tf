terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
    }
  }
}


resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "random_password" "postgres_password" {
  length  = 30
  special = false
}

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "15.2.5"
  namespace  = var.namespace
  atomic     = true
  lint       = true
  values = [
    yamlencode(
      {
        global = {
          postgresql = {
            auth = {
              enablePostgresUser = true
              postgresPassword   = resource.random_password.postgres_password.result
              database           = "postgres"
            }
          }
        }
        architecture = "standalone"
        primary = {
          resources = {
            limits = {
              memory = "512Mi"
              cpu    = "200m"
            }
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
          persistence = {
            enabled     = true
            size        = "1Gi"
            accessModes = ["ReadWriteOnce"]
          }
          service = {
            ports = {
              postgresql = var.port
            }
          }
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }
    )
  ]
  depends_on = [
    kubernetes_namespace.namespace,
    random_password.postgres_password
  ]
}
