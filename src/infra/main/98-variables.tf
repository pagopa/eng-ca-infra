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

variable "app_name" {
  type        = string
  description = "App name."
  default     = "ca"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment"
}

variable "env_short" {
  type        = string
  default     = "d"
  description = "Evnironment short."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC cidr."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "vpc_private_subnets_cidr" {
  type        = list(string)
  description = "Private subnets list of cidr."
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_public_subnets_cidr" {
  type        = list(string)
  description = "Private subnets list of cidr."
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "vpc_internal_subnets_cidr" {
  type        = list(string)
  description = "Internal subnets list of cidr. Mainly for private endpoints"
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable/Create nat gateway"
  default     = true
}

## Public Dns zones
variable "public_dns_zones" {
  type        = map(any)
  description = "Route53 Hosted Zone"
  default     = null
}

variable "dns_record_ttl" {
  type        = number
  description = "Dns record ttl (in sec)"
  default     = 86400 # 24 hours
}

#-------------------------
# DNS
#-------------------------
#region DNS
variable "app_primary_domain_name" {
  type    = string
  default = ""
}

variable "app_api_subdomain_name" {
  type    = string
  default = "api"
}

variable "app_next_env_domain_name" {
  type    = string
  default = ""
}

#-------------------------
# AWS API GATEWAY
#-------------------------
variable "apigw_name" {
  type    = string
  default = "certification-authority"
}


variable "apigw_stage_name" {
  type    = string
  default = "v1"
}

variable "apigw_intermediate_path" {
  type    = string
  default = "intermediate"
}

variable "apigw_intermediate_param_path" {
  type    = string
  default = "intermediate_id"
}

variable "apigw_list_path_certificates" {
  type    = string
  default = "certificates"
}

variable "apigw_get_revoke_path" {
  type    = string
  default = "serial_number"
}

variable "apigw_sign_path" {
  type    = string
  default = "certificate"
}

variable "apigw_revoke_path" {
  type    = string
  default = "serial_number"
}

variable "apigw_crl_path" {
  type    = string
  default = "crl"
}

variable "apigw_login_path" {
  type    = string
  default = "login"
}

#-------------------------
# AWS Lambda
#-------------------------
variable "lambda_name" {
  type    = string
  default = "certification_authority"
}

variable "lambda_arch" {
  type    = string
  default = "x86_64"
}
variable "frontend_handler_name" {
  description = "Lambda function name"
  default     = "frontend.__init__.lambda_handler"
}


variable "vault_list_path" {
  type    = string
  default = "/v1/intermediate-{}/certs"
}

variable "vault_read_path" {
  type    = string
  default = "/v1/intermediate-{}/cert/"
}

variable "vault_sign_path" {
  type    = string
  default = "/v1/intermediate-{}/sign-verbatim/client-certificate"
}

variable "vault_revoke_path" {
  type    = string
  default = "/v1/intermediate-{}/revoke"
}

variable "vault_crl_path" {
  type    = string
  default = "/v1/intermediate-{}/crl"
}

variable "vault_login_path" {
  type    = string
  default = "/v1/auth/github/login"
}

#-------------------------
# ECR
#-------------------------
variable "ecr_name" {
  description = "Name of Elastic Container Registry repo."
  default     = "vault"
  type        = string
}


#-------------------------
# S3
#-------------------------
variable "s3_bucket_name" {
  description = "Name of S3 Storage Bucket used for Vault backend"
  default     = "vault-storage"
  type        = string
}


#-------------------------
# ECS
#-------------------------
variable "ecs_cluster_name" {
  description = "Name of ECS Cluster"
  default     = "vault-ecs-cluster"
  type        = string
}

variable "ecs_service_name" {
  default = "vault"
  type    = string
}

variable "ecs_logs_retention_days" {
  type        = number
  description = "ECS log group retention in days"
  default     = 5
}


#-------------------------
# HashiCorp Vault
#-------------------------
variable "vault_version" {
  default = "1.14.6"
  type    = string
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}
