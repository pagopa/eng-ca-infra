terraform {
  required_providers {
    aws = {
      version = "~> 3.26.0"
      source  = "hashicorp/aws"
    }
    vault = {
      version = "~> 2.18.0"
      source  = "hashicorp/vault"
    }
  }
  backend "s3" {
    # managed outside tf
    bucket  = "ca-secops-pagopa-it-vault-config-state"
    key     = "vault/terraform.tfstate"
    encrypt = true
    # managed outside tf
    dynamodb_table = "ca-secops-pagopa-it-vault-config-lock-table"
    region         = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "vault" {
  # connect with a SSH tunnel
  address = "https://vault01:8200"
}

# password to get a token for the internal tool that rotates the CRLs
# stored in SSM to avoid commiting secrets
data "aws_ssm_parameter" "crl_renewer_password" {
  name = "ca.secops-crl_renewer_password"
}
