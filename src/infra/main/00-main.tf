terraform {
  required_version = "~> 1.6.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.11.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

locals {
  project = format("%s-%s", var.app_name, var.env_short)
}

data "aws_caller_identity" "current" {}

# appending random characters to some fields that need to be globally unique
resource "random_id" "name_suffix" {
  byte_length = 4
}




resource "aws_kms_key" "s3_key" {
  description = "S3 SSE key"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7
  enable_key_rotation     = false
  multi_region            = false
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-sse-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_kms_key" "vault_key" {
  description = "Vault Auto Unseal key"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7
  enable_key_rotation     = false
  multi_region            = false
}

resource "aws_kms_alias" "vault_key_alias" {
  name          = "alias/vault-auto-unseal-key"
  target_key_id = aws_kms_key.vault_key.key_id
}

#---------------------------
# S3
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "vault_s3_backend" {
  bucket        = "${var.s3_bucket_name}-${random_id.name_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_sse" {
  bucket = aws_s3_bucket.vault_s3_backend.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_block_public" {
  bucket = aws_s3_bucket.vault_s3_backend.id

  # block public bucket
  block_public_acls   = true
  block_public_policy = true

  # block public objects
  ignore_public_acls = true
}

