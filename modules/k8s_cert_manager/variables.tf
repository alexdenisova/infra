variable "name" {
  type    = string
  default = "cert-manager"
}

variable "namespace" {
  type    = string
  default = "cert-manager"
}

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

variable "certificates" {
  type = list(object({
    name     = string,
    dns_name = string,
  }))
}

variable "acme_email" {
  type    = string
  default = "alexadenisova@gmail.com"
}
