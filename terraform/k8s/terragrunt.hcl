include "root" {
  path = find_in_parent_folders()
}

locals {
  kubeconfig_path = "${get_terragrunt_dir()}/files/generated.kubeconfig"
}

generate "kubeconfig" {
  path      = local.kubeconfig_path
  if_exists = "overwrite_terragrunt"
  contents  = sops_decrypt_file("${get_terragrunt_dir()}/files/kubeconfig")
}

generate "locals" {
  path      = "~locals.g.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
locals {
  kubeconfig_path = "${local.kubeconfig_path}"
}
EOF
}
