## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.codebuild_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_buildspec"></a> [buildspec](#input\_buildspec) | The build spec declaration to use for this build project's related builds | `string` | n/a | yes |
| <a name="input_github_repository_url"></a> [github\_repository\_url](#input\_github\_repository\_url) | GitHub repository URL for source code | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name for the CodeBuild project | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Map of environment variables to set in the CodeBuild project | `map(string)` | `{}` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Name of the CloudWatch Logs group for build logs (optional) | `string` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Retention period for CloudWatch Logs (optional) | `number` | `7` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | The ARN of the IAM role that CodeBuild should assume (optional) | `any` | `null` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | VPC configuration for CodeBuild project (optional) | <pre>object({<br>    vpc_id             = string<br>    subnets            = list(string)<br>    security_group_ids = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_code_build_project_arn"></a> [code\_build\_project\_arn](#output\_code\_build\_project\_arn) | n/a |
| <a name="output_code_build_project_name"></a> [code\_build\_project\_name](#output\_code\_build\_project\_name) | n/a |
