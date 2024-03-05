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
  single_nat_gateway    = var.env_short == "d" ? true : false
  reuse_nat_ips         = false


  enable_dns_hostnames          = true
  enable_dns_support            = true
  map_public_ip_on_launch       = true
  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false

}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

#---------------------------
## Vault
#---------------------------
resource "aws_security_group" "vault" {
  name        = "Vault server required ports"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for HashiCorp Vault"
}

resource "aws_security_group_rule" "vault_api_tcp_frontend" {
  type                     = "ingress"
  description              = "Vault API/UI - Frontend Lambda"
  security_group_id        = aws_security_group.vault.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "vault_api_tcp_rotate_crl" {
  type                     = "ingress"
  description              = "Vault API/UI - Rotate CRL Lambda"
  security_group_id        = aws_security_group.vault.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rotate_crl.id
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
## Lambda Frontend
#---------------------------

resource "aws_security_group" "frontend" {
  name        = "Frontend security group"
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
## Lambda Rotate CRL
#---------------------------
resource "aws_security_group" "rotate_crl" {
  name        = "Rotate CRL Lambda security group"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for AWS Lambda"
}

resource "aws_security_group_rule" "rotate_crl_ingress_ssm" {
  type              = "ingress"
  description       = "Ingress to 443 port"
  security_group_id = aws_security_group.rotate_crl.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "rotate_crl_egress_ssm" {
  type              = "egress"
  description       = "Egress to 443 port"
  security_group_id = aws_security_group.rotate_crl.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "rotate_crl_egress_vault" {
  type                     = "egress"
  description              = "Connection between Rotate CRL Lambda and Vault inside ECS"
  security_group_id        = aws_security_group.rotate_crl.id
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vault.id
}

#---------------------------
## VPC endpoints
#---------------------------
# Needed to make Lambdas talk to SSM.
# resource "aws_vpc_endpoint" "ssm" {
#   for_each = toset([
#     format("com.amazonaws.%s.ssm", var.aws_region),
#     format("com.amazonaws.%s.ec2messages", var.aws_region),
#   ])
#   vpc_id             = module.vpc.vpc_id
#   service_name       = each.key
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = module.vpc.private_subnets[*]
#   security_group_ids = [aws_security_group.frontend.id, aws_security_group.rotate_crl.id]

#   private_dns_enabled = true
# }

# # Needed to make Lambda talk to SNS.
# resource "aws_vpc_endpoint" "sns" {
#   vpc_id             = module.vpc.vpc_id
#   service_name       = format("com.amazonaws.%s.sns", var.aws_region)
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = module.vpc.private_subnets[*]
#   security_group_ids = [aws_security_group.frontend.id]

#   private_dns_enabled = true
# }

# # Needed to avoid routing through internet for DynamoDB
# resource "aws_vpc_endpoint" "dynamo_db" {
#   vpc_id             = module.vpc.vpc_id
#   service_name       = format("com.amazonaws.%s.dynamodb", var.aws_region)
#   vpc_endpoint_type  = "Gateway"
#   subnet_ids         = module.vpc.private_subnets[*]
#   security_group_ids = [aws_security_group.rotate_crl.id, aws_security_group.vault.id]

#   private_dns_enabled = true
# }

# # Needed to avoid routing through internet for Cloudwatch
# resource "aws_vpc_endpoint" "cloudwatch" {
#   vpc_id             = module.vpc.vpc_id
#   service_name       = format("com.amazonaws.%s.logs", var.aws_region)
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = module.vpc.private_subnets[*]
#   security_group_ids = [aws_security_group.frontend.id, aws_security_group.rotate_crl.id, aws_security_group.vault.id]

#   private_dns_enabled = true
# }


module "vpc_endpoints" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//modules/vpc-endpoints?ref=41da6881e295ff5e94bbf97b41018e7c550c7285"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [data.aws_security_group.default.id, aws_security_group.frontend.id, aws_security_group.rotate_crl.id, aws_security_group.vault.id]

  endpoints = {
    sns = {
      service             = "sns"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.frontend.id]
      tags                = { Name = "sns-vpc-endpoint" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.frontend.id, aws_security_group.rotate_crl.id]
      tags                = { Name = "ssm-vpc-endpoint" }
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.frontend.id, aws_security_group.rotate_crl.id]
      tags                = { Name = "ec2messages-vpc-endpoint" }
    },
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.frontend.id, aws_security_group.rotate_crl.id, aws_security_group.vault.id]
      tags                = { Name = "logs-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
  }
}
