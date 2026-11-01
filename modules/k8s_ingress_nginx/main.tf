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


resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "ingress_nginx" {
  name            = var.name
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  version         = "4.10.0"
  namespace       = kubernetes_namespace.ingress_nginx.metadata[0].name
  atomic          = true
  cleanup_on_fail = true
  values = [
    yamlencode({
      controller = {
        name         = var.name
        ingressClass = var.ingress_class
        ingressClassResource = {
          enabled = true
          name    = var.ingress_class
          default = var.ingress_class_default
        }
        hostNetwork = true
        hostPort = {
          enabled = true
        }
        kind = "DaemonSet"
        service = {
          enabled     = true
          type        = "LoadBalancer"
          externalIPs = [var.external_ip]
        }
        config = {
          proxy-buffer-size = "20k"
        }
      }
    })
  ]
}
