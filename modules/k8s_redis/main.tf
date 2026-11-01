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


resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "random_password" "redis_password" {
  length  = 30
  special = false
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "28.3.10"
  namespace  = kubernetes_namespace.namespace.metadata[0].name
  atomic     = true
  lint       = true
  values = [
    yamlencode(
      {
        global = {
          redis = {
            password = random_password.redis_password.result
          }
        }
        architecture = "standalone"
        image = {
          repository = "bitnamilegacy/redis"
          tag        = var.redis_version
        }
        master = {
          resources = {
            limits = {
              memory = "128Mi"
              cpu    = "200m"
            }
            requests = {
              memory = "64Mi"
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
              redis = var.port
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
}
