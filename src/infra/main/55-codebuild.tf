locals {
  code_build_project_name = "${local.project}-vault-build"
}

resource "aws_security_group" "codebuild_security_group" {
  name        = "codebuild-security-group"
  description = "Security group for CodeBuild."

  vpc_id = module.vpc.vpc_id

  // Outbound rules
  // Example: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


module "codebuild" {
  source                = "../modules/codebuild"
  project_name          = local.code_build_project_name
  github_repository_url = "https://github.com/pagopa/eng-ca"

  buildspec = "./src/builds/vault-buildspecs.yml"

  log_group_name = "builds/${local.code_build_project_name}"

  vpc_config = {
    vpc_id             = module.vpc.vpc_id
    subnets            = module.vpc.private_subnets
    security_group_ids = [aws_security_group.codebuild_security_group.id]
  }

}

data "aws_iam_policy_document" "terraform" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    # TODO: reference the remote state.
    resources = [
      "arn:aws:s3:::ca-eng-dev-tfstate-927384502041",
      "arn:aws:s3:::ca-eng-dev-tfstate-927384502041/*"
    ]
  }
}

resource "aws_iam_policy" "terraform" {
  name        = "${local.project}-terraform-policy"
  description = "Policy that allows terraform to interact with the remote state."
  policy      = data.aws_iam_policy_document.terraform.json
}

resource "aws_iam_role_policy_attachment" "terraform" {
  role       = module.codebuild.role_name
  policy_arn = aws_iam_policy.terraform.arn
}


