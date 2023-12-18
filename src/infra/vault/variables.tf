variable "aws_region" {
  type        = string
  description = "AWS region to create resources. Default Milan"
  default     = "eu-west-1"
}

#-------------------------
# S3
#-------------------------
variable "s3_bucket_name" {
  description = "Name of S3 Storage Bucket used for Vault backend"
  default     = ""
  type        = string
}

#-------------------------
# DNS
#-------------------------
#region DNS
variable "app_primary_domain_name" {
  type    = string
  default = ""
}


#-------------------------
# HashiCorp Vault
#-------------------------
variable "vault_version" {
  default = "1.14.6"
  type    = string
}

variable "vault_log_level" {
  type        = string
  default     = "debug"
  description = "To specify the Vault server's log level"

}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}
