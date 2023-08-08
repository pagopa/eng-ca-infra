## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | =5.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | =5.11.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.ecs_vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_dynamodb_table.vault-data](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/dynamodb_table) | resource |
| [aws_ecr_repository.vault_ecr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecr_repository) | resource |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.ecs_cluster_capacity](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.vault-svc](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.ecs-task-def](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_access_key.vault-user](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.vault-user-policy](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vault_task_policy](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_vault_task_role](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.vault_task_role_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.vault-user](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.vault-user-policy-attach](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_user_policy_attachment) | resource |
| [aws_kms_alias.s3_key_alias](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.vault_key_alias](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_key) | resource |
| [aws_kms_key.vault_key](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_key) | resource |
| [aws_s3_bucket.vault_s3_backend](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.s3_block_public](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_sse](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_web](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vault_api_tcp](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_service_discovery_http_namespace.vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/service_discovery_http_namespace) | resource |
| [random_id.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | App name. | `string` | `"ca"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to create resources. Default Milan | `string` | `"eu-west-1"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Availability zones | `list(string)` | <pre>[<br>  "eu-west-1a",<br>  "eu-west-1b",<br>  "eu-west-1c"<br>]</pre> | no |
| <a name="input_dns_record_ttl"></a> [dns\_record\_ttl](#input\_dns\_record\_ttl) | Dns record ttl (in sec) | `number` | `86400` | no |
| <a name="input_ecr_name"></a> [ecr\_name](#input\_ecr\_name) | Name of Elastic Container Registry repo. | `string` | `"vault"` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of ECS Cluster | `string` | `"vault-ecs-cluster"` | no |
| <a name="input_ecs_logs_retention_days"></a> [ecs\_logs\_retention\_days](#input\_ecs\_logs\_retention\_days) | ECS log group retention in days | `number` | `5` | no |
| <a name="input_ecs_service_name"></a> [ecs\_service\_name](#input\_ecs\_service\_name) | n/a | `string` | `"vault-ecs-service"` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Enable/Create nat gateway | `bool` | `true` | no |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | Evnironment short. | `string` | `"d"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | `"dev"` | no |
| <a name="input_public_dns_zones"></a> [public\_dns\_zones](#input\_public\_dns\_zones) | Route53 Hosted Zone | `map(any)` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of S3 Storage Bucket used for Vault backend | `string` | `"vault-storage"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | <pre>{<br>  "CreatedBy": "Terraform"<br>}</pre> | no |
| <a name="input_vault_version"></a> [vault\_version](#input\_vault\_version) | ------------------------- HashiCorp Vault ------------------------- | `string` | `"1.14.6"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC cidr. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_internal_subnets_cidr"></a> [vpc\_internal\_subnets\_cidr](#input\_vpc\_internal\_subnets\_cidr) | Internal subnets list of cidr. Mainly for private endpoints | `list(string)` | <pre>[<br>  "10.0.201.0/24",<br>  "10.0.202.0/24",<br>  "10.0.203.0/24"<br>]</pre> | no |
| <a name="input_vpc_private_subnets_cidr"></a> [vpc\_private\_subnets\_cidr](#input\_vpc\_private\_subnets\_cidr) | Private subnets list of cidr. | `list(string)` | <pre>[<br>  "10.0.1.0/24",<br>  "10.0.2.0/24",<br>  "10.0.3.0/24"<br>]</pre> | no |
| <a name="input_vpc_public_subnets_cidr"></a> [vpc\_public\_subnets\_cidr](#input\_vpc\_public\_subnets\_cidr) | Private subnets list of cidr. | `list(string)` | <pre>[<br>  "10.0.101.0/24",<br>  "10.0.102.0/24",<br>  "10.0.103.0/24"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_docker_build_and_push"></a> [docker\_build\_and\_push](#output\_docker\_build\_and\_push) | n/a |
| <a name="output_login_ecr"></a> [login\_ecr](#output\_login\_ecr) | n/a |
