terraform {
  required_providers {
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

resource "helm_release" "postgres_backuper" {
  name      = "postgres-backuper"
  chart     = "${path.module}/charts/postgres-backuper"
  namespace = kubernetes_namespace.namespace.metadata[0].name
  atomic    = true
  lint      = true
  values = [
    yamlencode(
      {
        registry_secret = {
          data = var.registry_secret
        }
        postgresBackuper = {
          env = {
            PB__GIT_EMAIL = var.git_email
          }
          secretValues = {
            PB__GITHUB_REPO_URL = var.github_repo_url
          }
        }
        backups = {
          for name, b in var.backups : name => {
            schedule = b.schedule
            env = b.backup_path == null ? {} : {
              PB__BACKUP_PATH = b.backup_path
            }
            secretValues = merge(
              { PB__DB_URL = b.postgres_url },
              b.github_repo_url == null ? {} : { PB__GITHUB_REPO_URL = b.github_repo_url },
            )
          }
        }
      }
    )
  ]
}
