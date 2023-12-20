terraform {
  required_providers {
    aws = {
      version = "~> 3.26.0"
      source  = "hashicorp/aws"
    }
    vault = {
      version = "~> 3.18.0"
      source  = "hashicorp/vault"
    }
  }
  backend "s3" {
    # managed outside tf
    bucket  = var.s3_bucket_name
    key     = var.s3_bucket_key
    encrypt = true
    # managed outside tf
    dynamodb_table = var.s3_bucket_dynamodb_table
    region         = var.aws_region
  }
}

provider "aws" {
  region = var.aws_region
}

provider "vault" {
  # static pointer to node 0, it will auto redirect requests
  # toward the active node
  address = "http://vault-0.vault.private:8200"
}

# password to get a token for the internal tool that rotates the CRLs
# stored in SSM to avoid commiting secrets
data "aws_ssm_parameter" "crl_renewer_password" {
  name = "ca.eng-crl_renewer_password"
}
