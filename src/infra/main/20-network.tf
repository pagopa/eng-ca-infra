module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "5.1.1"
  name                  = format("%s-vpc", local.project)
  cidr                  = var.vpc_cidr
  azs                   = var.azs
  private_subnets       = var.vpc_private_subnets_cidr
  private_subnet_suffix = "private"
  public_subnets        = var.vpc_public_subnets_cidr
  public_subnet_suffix  = "public"
  intra_subnets         = var.vpc_internal_subnets_cidr
  enable_nat_gateway    = var.enable_nat_gateway
  single_nat_gateway    = true
  reuse_nat_ips         = false


  enable_dns_hostnames          = true
  enable_dns_support            = true
  map_public_ip_on_launch       = true
  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false

}

#---------------------------
## Vault
#---------------------------
resource "aws_security_group" "vault" {
  name        = "Vault server required ports"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for HashiCorp Vault"
}

resource "aws_security_group_rule" "vault_api_tcp" {
  type                     = "ingress"
  description              = "Vault API/UI"
  security_group_id        = aws_security_group.vault.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "vault_internal" {
  type              = "ingress"
  description       = "Vault Internal"
  security_group_id = aws_security_group.vault.id
  self              = true
  from_port         = 8200
  to_port           = 8201
  protocol          = "tcp"
}

resource "aws_security_group_rule" "vault_github_runner" {
  type                     = "ingress"
  description              = "Vault Github Runner"
  security_group_id        = aws_security_group.vault.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.github_runner.id
}

resource "aws_security_group_rule" "codebuild" {
  type                     = "ingress"
  description              = "Code build project."
  security_group_id        = aws_security_group.vault.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.codebuild.id

}

resource "aws_security_group_rule" "egress_web" {
  type              = "egress"
  description       = "Internet access"
  security_group_id = aws_security_group.vault.id
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
}

#---------------------------
## Lambda
#---------------------------

resource "aws_security_group" "frontend" {
  name        = "Frontend security group 01"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for AWS Lambda"
}

resource "aws_security_group_rule" "ingress_ssm" {
  type              = "ingress"
  description       = "Ingress to 443 port"
  security_group_id = aws_security_group.frontend.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}


resource "aws_security_group_rule" "egress_web_frontend" {
  type                     = "egress"
  description              = "Connection between Lambda and Vault inside ECS"
  security_group_id        = aws_security_group.frontend.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vault.id
}


resource "aws_security_group_rule" "egress_ssm" {
  type              = "egress"
  description       = "Egress to 443 port"
  security_group_id = aws_security_group.frontend.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}


#---------------------------
## VPC endpoints
#---------------------------
# Needed to make Lambda talk to SSM.
resource "aws_vpc_endpoint" "ssm" {
  for_each = toset([
    format("com.amazonaws.%s.ssm", var.aws_region),
    format("com.amazonaws.%s.ec2messages", var.aws_region),
  ])
  vpc_id             = module.vpc.vpc_id
  service_name       = each.key
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [aws_security_group.frontend.id]

  private_dns_enabled = true
}

# Needed to make Lambda talk to SNS.
resource "aws_vpc_endpoint" "sns" {
  vpc_id             = module.vpc.vpc_id
  service_name       = format("com.amazonaws.%s.sns", var.aws_region)
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [aws_security_group.frontend.id]

  private_dns_enabled = true
}

