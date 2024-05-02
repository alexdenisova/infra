output "postgres_password" {
  value = resource.random_password.postgres_password.result
}

output "postgres_url" {
  value = "postgresql://postgres:${resource.random_password.postgres_password.result}@postgres-postgresql.${var.namespace}:5432"
}
