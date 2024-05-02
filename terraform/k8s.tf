# K8s Ingress
module "k8s_ingress_nginx_internal" {
  source = "../modules/k8s_ingress_nginx"
}

# K8s Redis
module "k8s_redis" {
  source = "../modules/k8s_redis"
}
output "redis_password" {
  value     = module.k8s_redis.redis_password
  sensitive = true
}

# K8s PostgreSQL
module "k8s_postgres" {
  source = "../modules/k8s_postgres"
}
output "postgres_password" {
  value     = module.k8s_postgres.postgres_password
  sensitive = true
}

# K8s Postgres Backuper
module "k8s_postgres_backuper" {
  source          = "../modules/k8s_postgres_backuper"
  registry_secret = data.sops_file.main.data["registry_secret"]
  github_repo_url = data.sops_file.main.data["postgres_backuper_github_url"]
  postgres_url    = "${module.k8s_postgres.postgres_url}/pantry_tracker?sslmode=disable"
}
