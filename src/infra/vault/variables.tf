locals {
  full_path_root_project     = "${path.cwd}/${var.project_root}"                           # ${path.cwd}/../../.. 
  relative_path_app          = "${var.project_root}/src/app"                               # ../../../src/app 
  relative_path_functions    = "${var.project_root}/src/app/functions"                     # ../../../src/app/functions 
  relative_path_frontend     = "${var.project_root}/src/app/frontend"                      # ../../../src/app/frontend 
  relative_path_requirements = "${local.relative_path_app}/requirements.txt"               # ../../../src/app/requirements.txt
  relative_path_layer        = "${path.cwd}/../layer"                                      # ${path.cwd}/../layer
  python_version             = file("${local.full_path_root_project}/src/.python-version") # content of .python-version file
}

variable "project_root" {
  description = "Relative path to the root of the project"
  default     = "../../.."
}

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
