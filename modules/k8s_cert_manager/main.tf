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

resource "helm_release" "cert_manager" {
  name            = var.name
  chart           = "${path.module}/charts/cert-manager"
  namespace       = var.namespace
  atomic          = true
  cleanup_on_fail = true
  values = [
    yamlencode({
      ingress_class_name = var.ingress_class
      certificates       = var.certificates
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
      }
    })
  ]
}
