output "postgres_password" {
  value = random_password.postgres_password.result
}

output "postgres_url" {
  value = "postgresql://postgres:${random_password.postgres_password.result}@${helm_release.postgres.name}-postgresql.${var.namespace}:${var.port}"
}
