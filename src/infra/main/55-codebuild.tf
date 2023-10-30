locals {
  code_build_project_name = "${local.project}-vault-build"
}

resource "aws_security_group" "codebuild_security_group" {
  name        = "codebuild-security-group"
  description = "Security group for CodeBuild"

  vpc_id = "your_vpc_id" # Replace with your VPC ID

  // Inbound rules
  // Example: Allow HTTP (port 80) access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    security_group_ids = ["sg-003ca1613e8b3d445"] #TODO
  }

}