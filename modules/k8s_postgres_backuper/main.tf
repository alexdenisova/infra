terraform {
  required_providers {
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

resource "helm_release" "postgres_backuper" {
  name      = "postgres-backuper"
  chart     = "${path.module}/charts/postgres-backuper"
  namespace = var.namespace
  atomic    = true
  lint      = true
  values = [
    yamlencode(
      {
        registry_secret = {
          data = var.registry_secret
        }
        postgresBackuper = {
          schedule = var.schedule
          env      = {
            PB__GIT_EMAIL = var.git_email
          }
          secretValues = {
            PB__GITHUB_REPO_URL = var.github_repo_url
            PB__DB_URL = var.postgres_url
          }
        }
      }
    )
  ]
  depends_on = [
    kubernetes_namespace.namespace
  ]
}
