##
## SNS topic and lambda for email and Slack notifications
##

resource "aws_sns_topic" "notifications" {
  name = "ca-eng-pagopa-it-notifications-topic"
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifications_handler.arn
}

##
## Zip lambdas
##

data "archive_file" "notifications_handler_zip" {
  type        = "zip"
  source_dir  = "${local.relative_path_app}/notifications-handler/"
  output_path = "${local.full_path_root_project}/notifications_handler.zip"
}

data "archive_file" "expiring_cert_checker_zip" {
  type        = "zip"
  source_dir  = "${local.relative_path_app}/expiring-cert-checker/"
  output_path = "${local.full_path_root_project}/expiring_cert_checker.zip"
}

#TODO update with a better path for the zip and the files
data "archive_file" "rotate_crl_zip" {
  type        = "zip"
  source_dir  = "${local.relative_path_app}/"
  output_path = "${local.full_path_root_project}/rotate_crl.zip"
  excludes = [
    "frontend",
    "expiring-cert-checker",
    "notifications-handler",
    "tests",
    "requirements.txt",
    "requirements-dev.txt"
  ]
}

##
## Lambda functions
##

resource "aws_lambda_function" "notifications_handler" {
  depends_on       = [data.archive_file.notifications_handler_zip]
  runtime          = "python${local.python_version}"
  function_name    = "notifications_handler"
  role             = aws_iam_role.notifications_handler.arn
  filename         = data.archive_file.notifications_handler_zip.output_path
  source_code_hash = data.archive_file.notifications_handler_zip.output_base64sha256
  handler          = "main.handler"
  timeout          = 6 # we have 3s for SMTP connection
  environment {
    variables = {
      "ENV"                = upper("${var.environment}")
      "SLACK_CHANNEL"      = var.slack_channel_name
      "SLACK_USERNAME"     = "Internal CA Notifier"
      "SLACK_WEBHOOK"      = data.aws_ssm_parameter.slack_webhook.value
      "SMTP_HOST"          = "smtp.gmail.com"
      "SMTP_PORT"          = "587"
      "SMTP_USERNAME"      = var.environment == "prod" ? data.aws_ssm_parameter.smtp_username[0].value : "dummy"
      "SMTP_PASSWORD"      = var.environment == "prod" ? data.aws_ssm_parameter.smtp_password[0].value : "dummy"
      "AWS_DYNAMODB_TABLE" = aws_dynamodb_table.certificate_information.name
    }
  }
}

resource "aws_lambda_function" "expiring_cert_checker" {
  depends_on       = [data.archive_file.expiring_cert_checker_zip]
  runtime          = "python${local.python_version}"
  function_name    = "expiring_cert_checker"
  role             = aws_iam_role.expiring_cert_checker.arn
  filename         = data.archive_file.expiring_cert_checker_zip.output_path
  source_code_hash = data.archive_file.expiring_cert_checker_zip.output_base64sha256
  handler          = "main.handler"
  timeout          = 6 # we have 3s for DynamoDB and SNS connections
  environment {
    variables = {
      "AWS_SNS_TOPIC"                      = aws_sns_topic.notifications.arn
      "AWS_DYNAMODB_TABLE"                 = aws_dynamodb_table.certificate_information.name
      "AWS_DYNAMODB_TABLE_SECONDARY_INDEX" = aws_dynamodb_table.certificate_information.global_secondary_index.*.name[0]
    }
  }
}

resource "aws_lambda_function" "rotate_crl" {
  depends_on    = [data.archive_file.rotate_crl_zip]
  filename      = data.archive_file.rotate_crl_zip.output_path
  function_name = "rotate_crl"
  role          = aws_iam_role.rotate_crl.arn
  handler       = "rotate_crl.main.lambda_handler"
  architectures = [var.lambda_arch]
  timeout       = 6

  environment {
    variables = {
      VAULT_0_ADDR              = "http://${aws_service_discovery_service.vault[0].name}.${aws_service_discovery_private_dns_namespace.vault.name}:8200"
      VAULT_1_ADDR              = "http://${aws_service_discovery_service.vault[1].name}.${aws_service_discovery_private_dns_namespace.vault.name}:8200"
      VAULT_INTERNAL_LOGIN_PATH = var.vault_internal_login_path
      VAULT_LIST_MOUNTS         = var.vault_list_mounts
      VAULT_ROTATE_CRL          = var.vault_rotate_crl
      VAULT_TIDY                = var.vault_tidy
      VAULT_TMP_PATH            = var.vault_tmp_path
      VAULT_CA_CERT             = var.vault_ca_cert
      VAULT_CRL_USERNAME        = var.vault_crl_username
      PASSWORD                  = data.aws_ssm_parameter.crl_renewer_password.value
      SLACK_CHANNEL_NAME        = var.slack_channel_name
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets[*]
    security_group_ids = [aws_security_group.rotate_crl.id]
  }

  source_code_hash = data.archive_file.rotate_crl_zip.output_base64sha256

  layers = [aws_lambda_layer_version.lambda_layer.arn]

  runtime = "python${local.python_version}"

}

##
## Trigger lambda from SNS
##
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifications_handler.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notifications.arn
}

##
## Trigger lambda from Event Bridge daily
##

resource "aws_cloudwatch_event_rule" "daily_event" {
  name                = "daily_event"
  schedule_expression = "rate(1 day)"
}

# Expiring cert cheker
resource "aws_cloudwatch_event_target" "invoke_expiring_cert_checker" {
  rule      = aws_cloudwatch_event_rule.daily_event.name
  target_id = "expiring_cert_checker"
  arn       = aws_lambda_function.expiring_cert_checker.arn
}

resource "aws_lambda_permission" "event_bridge_expire_cert_checker" {
  statement_id  = "AllowExecutionFromCloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.expiring_cert_checker.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_event.arn
}

# Rotate CRL
resource "aws_cloudwatch_event_target" "invoke_rotate_crl" {
  rule      = aws_cloudwatch_event_rule.daily_event.name
  target_id = "rotate_crl"
  arn       = aws_lambda_function.rotate_crl.arn
}

resource "aws_lambda_permission" "event_bridge_rotate_crl" {
  statement_id  = "AllowExecutionFromCloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_crl.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_event.arn
}

##
## Cloudwatch log groups (each lambda function will create a log stream on update)
##

resource "aws_cloudwatch_log_group" "functions_expiring_cert_checker" {
  name              = "/lambda/${aws_lambda_function.expiring_cert_checker.function_name}"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "functions_notifications_handler" {
  name              = "/lambda/${aws_lambda_function.notifications_handler.function_name}"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "rotate_crl_application_log" {
  name              = "/lambda/${aws_lambda_function.rotate_crl.function_name}"
  retention_in_days = 90
}
