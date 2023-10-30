data "aws_caller_identity" "current" {}

data "aws_iam_role" "main" {
  count = var.role_name == null ? 0 : 1
  name  = var.role_name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "main" {
  count              = var.role_name == null ? 1 : 0
  name               = "${var.project_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "main" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "main" {
  count       = var.role_name == null ? 1 : 0
  name        = "${var.project_name}-cloudwatch-policy"
  description = "Policy to run pipelines inside the vpc."
  policy      = data.aws_iam_policy_document.main.json
}

resource "aws_iam_role_policy_attachment" "main" {
  count      = var.role_name == null ? 1 : 0
  role       = aws_iam_role.main[0].name
  policy_arn = aws_iam_policy.main[0].arn
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DeleteNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission",
    ]

    resources = ["*"]
  }

  # TODO.
  /*
  statement  {
    effect =  "Allow"
    actions = [
        ""
      ]
      resources =  ["arn:aws:ec2:region:${data.aws_caller_identity.current.account_id}:network-interface/*"]
    }
  */

}

resource "aws_iam_policy" "codebuild" {
  count       = var.vpc_config != null ? 1 : 0
  name        = "${var.project_name}-policy"
  description = "Policy to run pipelines inside the vpc."
  policy      = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = var.role_name == null ? 1 : 0
  role       = aws_iam_role.main[0].name
  policy_arn = aws_iam_policy.codebuild[0].arn
}


resource "aws_cloudwatch_log_group" "codebuild_log_group" {
  count = var.log_group_name != null ? 1 : 0
  name  = var.log_group_name

  retention_in_days = var.log_retention_in_days
}

resource "aws_codebuild_project" "main" {
  name          = var.project_name
  description   = "AWS CodeBuild project for ${var.project_name}"
  build_timeout = 15

  service_role = var.role_name != null ? data.aws_iam_role.main[0].arn : aws_iam_role.main[0].arn

  source {
    type            = "GITHUB"
    location        = var.github_repository_url
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }

    buildspec = var.buildspec
  }


  artifacts {
    type = "NO_ARTIFACTS"
  }


  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = { for e in var.environment_variables : e.name => e }
      iterator = e
      content {
        name  = e.key
        value = e.value.value
        type  = e.value.type
      }
    }
  }

  # VPC configuration (if provided)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = var.log_group_name
      stream_name = "build"
    }
  }
}
