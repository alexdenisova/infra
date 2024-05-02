output "redis_password" {
  value = resource.random_password.redis_password.result
}
