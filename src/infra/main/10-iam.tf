
#---------------------------
# ECS
#---------------------------
#region
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations_Amazon_Simple_Storage_Service.html
# https://docs.aws.amazon.com/kms/latest/APIReference/API_Operations.html
resource "aws_iam_policy" "vault-user-policy" {
  name        = "vault-ecs-policy"
  description = "ECS Vault user IAM policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:DeleteObjects",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ListKeys",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
# IAM Roles
#region
resource "aws_iam_role" "ecs_vault_task_role" {
  name = "PPAVaultTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

## Ecs task role
resource "aws_iam_role" "ecs_vault_task_exec_role" {
  name = "PPAVaultExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
#endregion

# IAM Policies
#region
resource "aws_iam_policy" "vault_task_policy" {
  name        = "PPAEcsTaskVaultKMS"
  description = "Policy for ECS task vault role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "KMSAccess"
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = [
          aws_kms_key.vault_key.arn
        ]
      },
      {
        Sid = "DynamoDBARW"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
          "dynamodb:BatchWriteItem",
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.vault_data.arn
      },

    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault_task_role_attachment" {
  policy_arn = aws_iam_policy.vault_task_policy.arn
  role       = aws_iam_role.ecs_vault_task_role.name
}




resource "aws_iam_policy" "vault_task_exec_policy" {
  name        = "PPAEcsVaultExecPolicy"
  description = "Policy for ECS execution role."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ecr"
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Resource = ["*"]
      },
      {
        Sid    = "cloudwatch"
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = ["*"]
      },
      {
        Sid    = "kms"
        Effect = "Allow",
        Action = [
          "kms:GetPublicKey",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = [
          aws_kms_key.vault_key.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault_task_exec_role_attachment" {
  policy_arn = aws_iam_policy.vault_task_exec_policy.arn
  role       = aws_iam_role.ecs_vault_task_exec_role.name
}
#endregion

#endregion

#---------------------------
# Common Resources for Lambda functions
#---------------------------
#region
data "aws_iam_policy_document" "lambda_x_ray" {
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "vault_address_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
    ]
    resources = [
      "${data.aws_ssm_parameter.vault_active_address.arn}"
    ]
  }
}

data "aws_iam_policy_document" "lambda_vpc" {
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
#endregion

#---------------------------
# Lambda Frontend
#---------------------------
#region
# IAM Role
resource "aws_iam_role" "lambda_ca" {
  name               = "frontend_lambda"
  assume_role_policy = data.aws_iam_policy_document.frontend_lambda.json
}

# IAM Policies
#region
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
  policy = data.aws_iam_policy_document.lambda_vpc.json
}

resource "aws_iam_role_policy" "ca_lambda_x_ray" {
  name   = "ca_lambda_x_ray"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.lambda_x_ray.json
}

resource "aws_iam_role_policy" "vault_address_ssm" {
  name   = "ca_lambda_ssm"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.ca_lambda_ssm.json
}

resource "aws_iam_role_policy" "ca_lambda_publish_sns" {
  name   = "ca_lambda_publish_sns"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.ca_lambda_publish_sns.json
}

data "aws_iam_policy_document" "ca_lambda_publish_sns" {
  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      "${aws_sns_topic.notifications.arn}"
    ]
  }
}
#endregion
#endregion


#---------------------------
# Lambda Rotate CRL
#---------------------------
#region
resource "aws_iam_role" "rotate_crl" {
  name               = "rotate_crl"
  assume_role_policy = data.aws_iam_policy_document.rotate_crl.json
}

# IAM Policies
#region
data "aws_iam_policy_document" "rotate_crl" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "rotate_crl_cw" {
  name   = "rotate_crl_cw"
  role   = aws_iam_role.rotate_crl.id
  policy = data.aws_iam_policy_document.rotate_crl_cw.json
}

data "aws_iam_policy_document" "rotate_crl_cw" {
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
      "${aws_cloudwatch_log_group.rotate_crl_application_log.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "rotate_crl_lambda_vpc" {
  name   = "rotate_crl_lambda_vpc"
  role   = aws_iam_role.rotate_crl.id
  policy = data.aws_iam_policy_document.lambda_vpc.json
}

resource "aws_iam_role_policy" "rotate_crl_x_ray" {
  name   = "rotate_crl_x_ray"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.lambda_x_ray.json
}
resource "aws_iam_role_policy" "rotate_crl_ssm" {
  name   = "rotate_crl_ssm"
  role   = aws_iam_role.lambda_ca.id
  policy = data.aws_iam_policy_document.vault_address_ssm.json
}



#endregion

#endregion

#---------------------------
# Lambda Notifications Handler
#---------------------------
#region
# IAM Role
resource "aws_iam_role" "notifications_handler" {
  name               = "notifications_handler"
  assume_role_policy = data.aws_iam_policy_document.notifications_handler.json
  tags               = var.tags
}

# IAM Policies
#region
data "aws_iam_policy_document" "notifications_handler" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cw_logs_notifications_handler" {
  name   = "cw_logs_notifications_handler"
  policy = data.aws_iam_policy_document.cw_logs_notifications_handler.json
  role   = aws_iam_role.notifications_handler.name
}

data "aws_iam_policy_document" "cw_logs_notifications_handler" {
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
      "${aws_cloudwatch_log_group.functions_notifications_handler.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_table_write" {
  name   = "dynamodb_table_write"
  policy = data.aws_iam_policy_document.dynamodb_table_write.json
  role   = aws_iam_role.notifications_handler.name
}

data "aws_iam_policy_document" "dynamodb_table_write" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "${aws_dynamodb_table.certificate_information.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_table_read_scan" {
  name   = "dynamodb_table_read_scan"
  policy = data.aws_iam_policy_document.dynamodb_table_read_scan.json
  role   = aws_iam_role.expiring_cert_checker.name
}

data "aws_iam_policy_document" "dynamodb_table_read_scan" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [
      "${aws_dynamodb_table.certificate_information.arn}/index/${aws_dynamodb_table.certificate_information.global_secondary_index.*.name[0]}"
    ]
  }
}

resource "aws_iam_role_policy" "notifications_handler_x_ray" {
  name   = "notifications_handler_x_ray"
  role   = aws_iam_role.notifications_handler.id
  policy = data.aws_iam_policy_document.lambda_x_ray.json
}
#endregion
#endregion


#---------------------------
# Lambda Expiring Certificate Checker
#---------------------------
#region
# IAM Role
resource "aws_iam_role" "expiring_cert_checker" {
  name               = "expiring_cert_checker"
  assume_role_policy = data.aws_iam_policy_document.expiring_cert_checker.json
  tags               = var.tags
}

# IAM Policies
#region
data "aws_iam_policy_document" "expiring_cert_checker" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "allow_publish_sns_expiring_cert_checker" {
  name   = "allow_publish_sns_expiring_cert_checker"
  policy = data.aws_iam_policy_document.allow_publish_sns_expiring_cert_checker.json
  role   = aws_iam_role.expiring_cert_checker.id
}

data "aws_iam_policy_document" "allow_publish_sns_expiring_cert_checker" {
  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]
    resources = [
      "${aws_sns_topic.notifications.arn}"
    ]
  }
}

resource "aws_iam_role_policy" "cw_logs_expiring_cert_checker" {
  name   = "cw_logs_expiring_cert_checker"
  policy = data.aws_iam_policy_document.cw_logs_expiring_cert_checker.json
  role   = aws_iam_role.expiring_cert_checker.name
}

data "aws_iam_policy_document" "cw_logs_expiring_cert_checker" {
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
      "${aws_cloudwatch_log_group.functions_expiring_cert_checker.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "expiring_cert_checker_x_ray" {
  name   = "expiring_cert_checker_x_ray"
  role   = aws_iam_role.expiring_cert_checker.id
  policy = data.aws_iam_policy_document.lambda_x_ray.json
}

#endregion

#endregion

