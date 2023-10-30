variable "project_name" {
  type        = string
  description = "Name for the CodeBuild project"
}

variable "github_repository_url" {
  type        = string
  description = "GitHub repository URL for source code"
}

variable "environment_variables" {
  description = "Map of environment variables to set in the CodeBuild project"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch Logs group for build logs (optional)"
  default     = null
}

variable "log_retention_in_days" {
  description = "Retention period for CloudWatch Logs (optional)"
  type        = number
  default     = 7
}

variable "vpc_config" {
  description = "VPC configuration for CodeBuild project (optional)"
  type = object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "role_name" {
  description = "The name of the IAM role that CodeBuild should assume."
  default     = null
}


variable "buildspec" {
  type        = string
  description = "The build spec declaration to use for this build project's related builds"

}
