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

resource "random_password" "redis_password" {
  length  = 30
  special = false
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "17.3.18"
  namespace  = var.namespace
  atomic     = true
  lint       = true
  values = [
    yamlencode(
      {
        global = {
          redis = {
            password = resource.random_password.redis_password.result
          }
        }
        architecture = "standalone"
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
  depends_on = [
    kubernetes_namespace.namespace,
    random_password.redis_password
  ]
}
