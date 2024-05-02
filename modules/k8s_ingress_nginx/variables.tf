variable "name" {
  type = string
  default = "ingress-nginx"
}

variable "namespace" {
  type = string
  default = "ingress-nginx"
}

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

variable "ingress_class_default" {
  type    = bool
  default = true
}

variable "timeout" {
  type    = number
  default = 300
}

