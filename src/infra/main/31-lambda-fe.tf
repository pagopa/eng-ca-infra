#---------------------------
# AWS Lambda Function
#---------------------------
#region

#Build app dependencies 
# null_resource used for its field "triggers" 
resource "null_resource" "deps_installer" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
    chmod +x deps_installer.sh
    ./deps_installer.sh ${local.relative_path_layer} ${var.lambda_arch} ${local.python_version} ${local.relative_path_requirements}
    EOT
  }
}

# Create zip for Lambda layer
data "archive_file" "layer" {
  depends_on  = [null_resource.deps_installer]
  type        = "zip"
  source_dir  = local.relative_path_layer
  output_path = "${local.full_path_root_project}/python.zip"
  excludes    = ["__pycache__"]

}

# Create zip for Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${local.relative_path_app}/"
  output_path = "${local.full_path_root_project}/frontend.zip"
  excludes = [
    "expiring-cert-checker",
    "notifications-handler",
    "tests",
    "requirements.txt",
    "requirements-dev.txt"
  ]
}

# Declare Aws Lambda Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  depends_on = [data.archive_file.layer]
  filename   = "${local.full_path_root_project}/python.zip"
  layer_name = "ca-libs"

  source_code_hash = data.archive_file.layer.output_base64sha256

  compatible_runtimes      = ["python${local.python_version}"]
  compatible_architectures = [var.lambda_arch]
}

# Declare Aws Lambda function
resource "aws_lambda_function" "lambda_ca" {
  depends_on    = [data.archive_file.lambda, data.archive_file.layer]
  filename      = data.archive_file.lambda.output_path
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_ca.arn
  handler       = var.frontend_handler_name
  architectures = [var.lambda_arch]
  timeout       = 30

  environment {
    variables = {
      AWS_SNS_TOPIC       = aws_sns_topic.notifications.arn
      VAULT_0_ADDR        = "http://${aws_service_discovery_service.vault[0].name}.${aws_service_discovery_private_dns_namespace.vault.name}:8200"
      VAULT_1_ADDR        = "http://${aws_service_discovery_service.vault[1].name}.${aws_service_discovery_private_dns_namespace.vault.name}:8200"
      VAULT_LIST_PATH     = var.vault_list_path
      VAULT_READ_PATH     = var.vault_read_path
      VAULT_SIGN_PATH     = var.vault_sign_path
      VAULT_REVOKE_PATH   = var.vault_revoke_path
      VAULT_CRL_PATH      = var.vault_crl_path
      VAULT_CA_PATH       = var.vault_ca_path
      VAULT_LOGIN_PATH    = var.vault_login_path
      VAULT_ROOT_CRL_PATH = var.vault_root_crl_path
      VAULT_ROOT_CA_PATH  = var.vault_root_ca_path
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets[*]
    security_group_ids = [aws_security_group.frontend.id]
  }


  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python${local.python_version}"

  layers = [aws_lambda_layer_version.lambda_layer.arn]

}
#endregion


#---------------------------
# Invocation Permission
#---------------------------
#region

#arn/<stage_name>/<list.http_method>/intermediate/{intermediate_id}/certificates
resource "aws_lambda_permission" "list" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.list.http_method}/${var.apigw_intermediate_path}/{${var.apigw_intermediate_param_path}}/${var.apigw_list_path_certificates}"
}

#arn/<stage_name>/*/intermediate/{intermediate_id}/certificate/{serial_number}
#lambda_ca resource covers get and revoke endpoint
resource "aws_lambda_permission" "get_revoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/*/${var.apigw_intermediate_path}/{${var.apigw_intermediate_param_path}}/${var.apigw_sign_path}/{${var.apigw_get_revoke_path}}"

}

#arn/<stage_name>/<sign_csr.http_method>/intermediate/{intermediate_id}/certificate
resource "aws_lambda_permission" "sign_csr" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.sign_csr.http_method}/${var.apigw_intermediate_path}/{${var.apigw_intermediate_param_path}}/${var.apigw_sign_path}"
}

#arn/<stage_name>/<crl.http_method>/intermediate/{intermediate_id}/crl
resource "aws_lambda_permission" "int_crl" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.int_crl.http_method}/${var.apigw_intermediate_path}/{${var.apigw_intermediate_param_path}}/${var.apigw_crl_path}"
}

#arn/<stage_name>/<crl.http_method>/intermediate/{intermediate_id}/ca
resource "aws_lambda_permission" "int_ca" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.int_ca.http_method}/${var.apigw_intermediate_path}/{${var.apigw_intermediate_param_path}}/${var.apigw_ca_path}"
}

#arn/<stage_name>/<sign_csr.http_method>/login
resource "aws_lambda_permission" "login" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.login.http_method}/${var.apigw_login_path}"

}

#arn/<stage_name>/<crl.http_method>/00/crl
resource "aws_lambda_permission" "root_crl" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.root_ca.http_method}/${var.apigw_root_ca_path}/${var.apigw_crl_path}"
}

#arn/<stage_name>/<crl.http_method>/00/ca
resource "aws_lambda_permission" "root_ca" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.root_ca.http_method}/${var.apigw_root_ca_path}/${var.apigw_ca_path}"
}
#endregion


#---------------------------
# Cloudwatch log group
#---------------------------
resource "aws_cloudwatch_log_group" "frontend_application_log" {
  name              = "/lambda/${aws_lambda_function.lambda_ca.function_name}"
  retention_in_days = 90
}

