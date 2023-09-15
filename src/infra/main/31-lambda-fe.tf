#---------------------------
# AWS Lambda Function
#---------------------------

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
  output_path = "${local.full_path_root_project}/app.zip"
  excludes = [
    "functions/",
    "tests/",
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
  handler       = var.handler_name
  architectures = [var.lambda_arch]

  environment {
    variables = {
      #   AWS_SNS_TOPIC        = aws_sns_topic.notifications.arn #TODO insert when it's time
      BLUEPRINT_API_PREFIX = var.blueprint_api_prefix
      VAULT_1_ADDR         = "https://vault1:8200" #TODO make parametric
      VAULT_2_ADDR         = "https://vault2:8200" #TODO make parametric
      VAULT_LIST_PATH      = var.vault_list_path
      VAULT_LOGIN_PATH     = var.vault_login_path
      VAULT_SIGN_PATH      = var.vault_sign_path
      VAULT_READ_PATH      = var.vault_read_path
      VAULT_REVOKE_PATH    = var.vault_revoke_path
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




#---------------------------
# Invocation Permission
#---------------------------
#TODO comment until apigw is not available


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

#arn/<stage_name>/<sign_csr.http_method>/login
resource "aws_lambda_permission" "login" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ca.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/${var.apigw_stage_name}/${aws_api_gateway_method.login.http_method}/${var.apigw_login_path}"

}


#---------------------------
# Security Group
#---------------------------
resource "aws_security_group" "frontend" {
  #   tags   = merge(var.common_tags, { Name = "frontend-sg" }) #todo is it useful
  vpc_id = module.vpc.vpc_id
}



#---------------------------
# Cloudwatch log group
#---------------------------
#TODO remember to modify those in packer/cw-config.json! ugly, but packer comes first than cloud-init (still valid (?)).
resource "aws_cloudwatch_log_group" "frontend_application_log" {
  name              = "/lambda/${aws_lambda_function.lambda_ca.function_name}"
  retention_in_days = 90
}


#---------------------------
# IAM Roles & Policies
#---------------------------
#TODO replace with the same pattern present in 30-ecs.tf
resource "aws_iam_role" "lambda_ca" {
  name               = "frontend_lambda"
  assume_role_policy = data.aws_iam_policy_document.frontend_lambda.json
}

data "aws_iam_policy_document" "frontend_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ca_lambda_cw" {
  name   = "ca_lambda_cw"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.ca_lambda_cw.json
}

data "aws_iam_policy_document" "ca_lambda_cw" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.frontend_application_log.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "ca_lambda_vpc" {
  name   = "ca_lambda_vpc"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.ca_lambda_vpc.json
}

data "aws_iam_policy_document" "ca_lambda_vpc" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = [
      "*"
    ]
  }
}
