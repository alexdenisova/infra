locals {
  files_dir = "${abspath("files")}"
  kubeconfig_path = "${abspath("files/generated.kubeconfig")}"
}

generate "kubeconfig" {
  path      = local.kubeconfig_path
  if_exists = "overwrite_terragrunt"
  contents  = sops_decrypt_file("files/kubeconfig")
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
