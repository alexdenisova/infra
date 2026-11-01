terraform {
  backend "local" {}
  required_providers {
    ansible = {
      source  = "nbering/ansible"
      version = "1.0.4"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

data "sops_file" "main" {
  source_file = "${path.root}/main.sops.yaml"
}
