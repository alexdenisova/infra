# Shared by every stack in terraform/
generate "common" {
  path      = "~common.g.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
locals {
  aws_region    = "us-east-2"
  contact_email = "alexadenisova@gmail.com"
}
EOF
}
