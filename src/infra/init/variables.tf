variable "aws_region" {
  type        = string
  description = "AWS region (default is Milan)"
  default     = "eu-south-1"
}

variable "environment" {
  type        = string
  description = "Environment. Possible values are: Dev, Uat, Prod"
  default     = "Uat"
}

variable "github_repository" {
  type        = string
  description = "This github repository"
  default     = "pagopa/eng-ca"
}

variable "create_backend" {
  type        = bool
  description = "Crate S3 bucket and Dynamodb table to store the state file."
  default     = true
}



variable "tags" {
  type = map(any)
  default = {
    "CreatedBy" : "Terraform",
    "Environment" : "Uat"
  }
}