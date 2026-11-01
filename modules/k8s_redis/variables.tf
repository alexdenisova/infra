variable "namespace" {
  type    = string
  default = "redis"
}

variable "redis_version" {
  type    = string
  default = "8.2.1"
}

variable "port" {
  type    = number
  default = 6379
}
