terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

locals {
  postgres_run_volume = "postgresql-run"
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
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.12.16"
  namespace  = kubernetes_namespace.namespace.metadata[0].name
  atomic     = true
  lint       = true
  values = [
    yamlencode(
      {
        global = {
          postgresql = {
            auth = {
              enablePostgresUser = true
              postgresPassword   = random_password.postgres_password.result
              database           = "postgres"
            }
          }
        }
        image = {
          registry   = ""
          repository = "postgres"
          tag        = "16-alpine"
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
          extraVolumes = [{
            name     = local.postgres_run_volume
            emptyDir = {}
          }]
          extraVolumeMounts = [{
            name      = local.postgres_run_volume
            mountPath = "/var/run/postgresql"
          }]
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
}
