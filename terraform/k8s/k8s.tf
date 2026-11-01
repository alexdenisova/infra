locals {
  ingress_class = "ingress-nginx"
}

# Outputs of the vm stack, read straight from its encrypted state
data "sops_file" "vm_state" {
  source_file = "${path.root}/../vm/tfstate.sops.json"
}

# K8s Ingress
module "k8s_ingress_nginx" {
  source        = "../../modules/k8s_ingress_nginx"
  external_ip   = nonsensitive(data.sops_file.vm_state.data["outputs.vm_ip.value"])
  ingress_class = local.ingress_class
}

# K8s Certificate Manager
module "k8s_cert_manager" {
  source        = "../../modules/k8s_cert_manager"
  ingress_class = local.ingress_class
  acme_email    = local.contact_email
  certificates = [{
    name     = "pantry-tracker"
    dns_name = "pantry-tracker.alexdenisova.com"
  }]
}

# K8s Redis
module "k8s_redis" {
  source = "../../modules/k8s_redis"
}
output "redis_password" {
  value     = module.k8s_redis.redis_password
  sensitive = true
}

# K8s PostgreSQL
module "k8s_postgres" {
  source = "../../modules/k8s_postgres"
}
output "postgres_password" {
  value     = module.k8s_postgres.postgres_password
  sensitive = true
}

# K8s Postgres Backuper
module "k8s_postgres_backuper" {
  source          = "../../modules/k8s_postgres_backuper"
  registry_secret = data.sops_file.main.data["registry_secret"]
  github_repo_url = data.sops_file.main.data["postgres_backuper_github_url"]
  git_email       = local.contact_email
  backups = {
    "pantry-tracker" = {
      postgres_url = "${module.k8s_postgres.postgres_url}/pantry_tracker?sslmode=disable"
      schedule     = "0 0 * * *"
    }
  }
}
