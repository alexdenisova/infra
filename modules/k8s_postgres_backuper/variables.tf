variable "namespace" {
  type    = string
  default = "postgres-backuper"
}

variable "registry_secret" {
  type      = string
  sensitive = true
}

variable "schedule" {
  type    = string
  default = "0,12 * * * *"
}

variable "git_email" {
  type    = string
  default = "alexadenisova@gmail.com"
}

variable "github_repo_url" {
  type      = string
  sensitive = true
}

variable "postgres_url" {
  type      = string
  sensitive = true
}
