variable "namespace" {
  type    = string
  default = "postgres-backuper"
}

variable "registry_secret" {
  type      = string
  sensitive = true
}

variable "git_email" {
  type = string
}

variable "github_repo_url" {
  description = "Default repository to push backups to"
  type        = string
  sensitive   = true
}

variable "backups" {
  description = "Databases to back up, keyed by name. The dump is saved to <name>/backup.sql unless backup_path is set."
  type = map(object({
    postgres_url    = string
    schedule        = optional(string, "0 0 * * *")
    backup_path     = optional(string)
    github_repo_url = optional(string)
  }))
  sensitive = true
}
