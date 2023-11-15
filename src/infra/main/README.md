## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | =5.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | =5.11.0 |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.api_validation](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.api_validation](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_base_path_mapping.api](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.api](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.get](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.get](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.get](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.get](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_resource.ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.get_revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.intermediate](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.intermediate_param_path](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.v1](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_event_rule.hourly_event](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.invoke_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.api_v1](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ecs_github_runner](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ecs_vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.frontend_application_log](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.functions_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.functions_notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_dynamodb_table.certificate_information](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.vault_data](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/dynamodb_table) | resource |
| [aws_ecr_repository.runner_ecr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.vault_ecr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecr_repository) | resource |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.ecs_cluster_capacity](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.vault_svc](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.ecs_task_def](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.github_runner_def](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.vault-user-policy](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vault_task_exec_policy](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vault_task_policy](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_vault_task_exec_role](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_vault_task_role](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role.expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role.notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.allow_publish_sns_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ca_lambda_cw](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ca_lambda_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ca_lambda_vpc](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ca_lambda_x_ray](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cw_logs_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cw_logs_notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.dynamodb_table_read_scan](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.dynamodb_table_write](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.vault_task_exec_role_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vault_task_role_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.s3_key_alias](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_alias) | resource |
| [aws_kms_alias.vault_key_alias](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_key) | resource |
| [aws_kms_key.vault_key](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/kms_key) | resource |
| [aws_lambda_function.expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_function) | resource |
| [aws_lambda_function.notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_function) | resource |
| [aws_lambda_layer_version.lambda_layer](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_layer_version) | resource |
| [aws_lambda_permission.event_bridge](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.get_revoke](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.int_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.int_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.list](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.login](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.root_ca](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.root_crl](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.sign_csr](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.sns](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/lambda_permission) | resource |
| [aws_route53_record.api](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/route53_record) | resource |
| [aws_route53_record.api_validation](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/route53_record) | resource |
| [aws_route53_record.env_link](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.vault_s3_backend](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.s3_block_public](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_sse](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.frontend](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group) | resource |
| [aws_security_group.vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_web](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_web_frontend](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vault_api_tcp](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/security_group_rule) | resource |
| [aws_service_discovery_private_dns_namespace.vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.vault](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/service_discovery_service) | resource |
| [aws_sns_topic.notifications](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.notifications](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/sns_topic_subscription) | resource |
| [aws_vpc_endpoint.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/resources/vpc_endpoint) | resource |
| [null_resource.deps_installer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.expiring_cert_checker_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.layer](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.notifications_handler_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.allow_publish_sns_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ca_lambda_cw](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ca_lambda_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ca_lambda_vpc](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ca_lambda_x_ray](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_logs_expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cw_logs_notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dynamodb_table_read_scan](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dynamodb_table_write](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.expiring_cert_checker](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.frontend_lambda](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.notifications_handler](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.slack_webhook](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.smtp_password](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.smtp_username](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.vault_active_address](https://registry.terraform.io/providers/hashicorp/aws/5.11.0/docs/data-sources/ssm_parameter) | data source |
| [external_external.get_ns_next](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.get_ns_primary](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apigw_ca_path"></a> [apigw\_ca\_path](#input\_apigw\_ca\_path) | n/a | `string` | `"ca"` | no |
| <a name="input_apigw_crl_path"></a> [apigw\_crl\_path](#input\_apigw\_crl\_path) | n/a | `string` | `"crl"` | no |
| <a name="input_apigw_get_revoke_path"></a> [apigw\_get\_revoke\_path](#input\_apigw\_get\_revoke\_path) | n/a | `string` | `"serial_number"` | no |
| <a name="input_apigw_intermediate_param_path"></a> [apigw\_intermediate\_param\_path](#input\_apigw\_intermediate\_param\_path) | n/a | `string` | `"intermediate_id"` | no |
| <a name="input_apigw_intermediate_path"></a> [apigw\_intermediate\_path](#input\_apigw\_intermediate\_path) | n/a | `string` | `"intermediate"` | no |
| <a name="input_apigw_list_path_certificates"></a> [apigw\_list\_path\_certificates](#input\_apigw\_list\_path\_certificates) | n/a | `string` | `"certificates"` | no |
| <a name="input_apigw_login_path"></a> [apigw\_login\_path](#input\_apigw\_login\_path) | n/a | `string` | `"login"` | no |
| <a name="input_apigw_name"></a> [apigw\_name](#input\_apigw\_name) | ------------------------- AWS API GATEWAY ------------------------- | `string` | `"certification-authority"` | no |
| <a name="input_apigw_revoke_path"></a> [apigw\_revoke\_path](#input\_apigw\_revoke\_path) | n/a | `string` | `"serial_number"` | no |
| <a name="input_apigw_root_ca_path"></a> [apigw\_root\_ca\_path](#input\_apigw\_root\_ca\_path) | n/a | `string` | `"00"` | no |
| <a name="input_apigw_sign_path"></a> [apigw\_sign\_path](#input\_apigw\_sign\_path) | n/a | `string` | `"certificate"` | no |
| <a name="input_apigw_stage_name"></a> [apigw\_stage\_name](#input\_apigw\_stage\_name) | n/a | `string` | `"v1"` | no |
| <a name="input_app_api_subdomain_name"></a> [app\_api\_subdomain\_name](#input\_app\_api\_subdomain\_name) | n/a | `string` | `"api"` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | App name. | `string` | `"ca"` | no |
| <a name="input_app_next_env_domain_name"></a> [app\_next\_env\_domain\_name](#input\_app\_next\_env\_domain\_name) | n/a | `string` | `""` | no |
| <a name="input_app_primary_domain_name"></a> [app\_primary\_domain\_name](#input\_app\_primary\_domain\_name) | ------------------------- DNS ------------------------- region DNS | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to create resources. Default Milan | `string` | `"eu-west-1"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Availability zones | `list(string)` | <pre>[<br>  "eu-west-1a",<br>  "eu-west-1b",<br>  "eu-west-1c"<br>]</pre> | no |
| <a name="input_dns_record_ttl"></a> [dns\_record\_ttl](#input\_dns\_record\_ttl) | Dns record ttl (in sec) | `number` | `86400` | no |
| <a name="input_ecr_name"></a> [ecr\_name](#input\_ecr\_name) | Name of Elastic Container Registry repo. | `string` | `"vault"` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of ECS Cluster | `string` | `"vault-ecs-cluster"` | no |
| <a name="input_ecs_logs_retention_days"></a> [ecs\_logs\_retention\_days](#input\_ecs\_logs\_retention\_days) | ECS log group retention in days | `number` | `5` | no |
| <a name="input_ecs_service_name"></a> [ecs\_service\_name](#input\_ecs\_service\_name) | n/a | `string` | `"vault"` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Enable/Create nat gateway | `bool` | `true` | no |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | Evnironment short. | `string` | `"d"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | `"dev"` | no |
| <a name="input_frontend_handler_name"></a> [frontend\_handler\_name](#input\_frontend\_handler\_name) | Lambda function name | `string` | `"frontend.__init__.lambda_handler"` | no |
| <a name="input_lambda_arch"></a> [lambda\_arch](#input\_lambda\_arch) | n/a | `string` | `"x86_64"` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | ------------------------- AWS Lambda ------------------------- | `string` | `"certification_authority"` | no |
| <a name="input_project_root"></a> [project\_root](#input\_project\_root) | Relative path to the root of the project | `string` | `"../../.."` | no |
| <a name="input_public_dns_zones"></a> [public\_dns\_zones](#input\_public\_dns\_zones) | Route53 Hosted Zone | `map(any)` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of S3 Storage Bucket used for Vault backend | `string` | `"vault-storage"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | <pre>{<br>  "CreatedBy": "Terraform"<br>}</pre> | no |
| <a name="input_vault_ca_path"></a> [vault\_ca\_path](#input\_vault\_ca\_path) | n/a | `string` | `"/v1/intermediate-{}/ca"` | no |
| <a name="input_vault_crl_path"></a> [vault\_crl\_path](#input\_vault\_crl\_path) | n/a | `string` | `"/v1/intermediate-{}/crl"` | no |
| <a name="input_vault_list_path"></a> [vault\_list\_path](#input\_vault\_list\_path) | n/a | `string` | `"/v1/intermediate-{}/certs"` | no |
| <a name="input_vault_login_path"></a> [vault\_login\_path](#input\_vault\_login\_path) | n/a | `string` | `"/v1/auth/github/login"` | no |
| <a name="input_vault_read_path"></a> [vault\_read\_path](#input\_vault\_read\_path) | n/a | `string` | `"/v1/intermediate-{}/cert/"` | no |
| <a name="input_vault_revoke_path"></a> [vault\_revoke\_path](#input\_vault\_revoke\_path) | n/a | `string` | `"/v1/intermediate-{}/revoke"` | no |
| <a name="input_vault_root_ca_path"></a> [vault\_root\_ca\_path](#input\_vault\_root\_ca\_path) | n/a | `string` | `"/v1/pki/ca"` | no |
| <a name="input_vault_root_crl_path"></a> [vault\_root\_crl\_path](#input\_vault\_root\_crl\_path) | n/a | `string` | `"/v1/pki/crl"` | no |
| <a name="input_vault_sign_path"></a> [vault\_sign\_path](#input\_vault\_sign\_path) | n/a | `string` | `"/v1/intermediate-{}/sign-verbatim/client-certificate"` | no |
| <a name="input_vault_version"></a> [vault\_version](#input\_vault\_version) | ------------------------- HashiCorp Vault ------------------------- | `string` | `"1.14.6"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC cidr. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_internal_subnets_cidr"></a> [vpc\_internal\_subnets\_cidr](#input\_vpc\_internal\_subnets\_cidr) | Internal subnets list of cidr. Mainly for private endpoints | `list(string)` | <pre>[<br>  "10.0.201.0/24",<br>  "10.0.202.0/24",<br>  "10.0.203.0/24"<br>]</pre> | no |
| <a name="input_vpc_private_subnets_cidr"></a> [vpc\_private\_subnets\_cidr](#input\_vpc\_private\_subnets\_cidr) | Private subnets list of cidr. | `list(string)` | <pre>[<br>  "10.0.1.0/24",<br>  "10.0.2.0/24",<br>  "10.0.3.0/24"<br>]</pre> | no |
| <a name="input_vpc_public_subnets_cidr"></a> [vpc\_public\_subnets\_cidr](#input\_vpc\_public\_subnets\_cidr) | Private subnets list of cidr. | `list(string)` | <pre>[<br>  "10.0.101.0/24",<br>  "10.0.102.0/24",<br>  "10.0.103.0/24"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_route53_zone_this_ns"></a> [aws\_route53\_zone\_this\_ns](#output\_aws\_route53\_zone\_this\_ns) | n/a |
| <a name="output_docker_build_and_push"></a> [docker\_build\_and\_push](#output\_docker\_build\_and\_push) | n/a |
| <a name="output_login_ecr"></a> [login\_ecr](#output\_login\_ecr) | n/a |
