resource "aws_cloudwatch_log_group" "ecs_vault" {
  name = "ecs/vault"

  retention_in_days = var.ecs_logs_retention_days

  tags = {
    Name = "vault"
  }
}


#---------------------------
# ECR
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "vault_ecr" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

#---------------------------
# ECS Cluster
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


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
        Resource = aws_dynamodb_table.vault-data.arn
      },

    ]
  })
}


resource "aws_iam_role_policy_attachment" "vault_task_role_attachment" {
  policy_arn = aws_iam_policy.vault_task_policy.arn
  role       = aws_iam_role.ecs_vault_task_role.name
}


#---------------------------
# ECS Task Definition
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition

resource "aws_ecs_task_definition" "ecs-task-def" {
  count                    = 2
  family                   = "vault-ecs-task-def-${count.index}"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_vault_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "vault-docker",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/vault:${var.vault_version}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_vault.id}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${var.ecs_service_name}"
      }
    },
    "portMappings": [
      {
        "name": "vault${count.index}",
        "hostPort": 8200,
        "protocol": "tcp",
        "containerPort": 8200
      },
      {
        "name": "cluster-vault${count.index}",
        "hostPort": 8201,
        "protocol": "tcp",
        "containerPort": 8201
      }
    ],
    "environment": [
      {
          "name": "VAULT_ADDR",
          "value": "http://0.0.0.0:8200"
      },
      {
          "name": "VAULT_API_ADDR",
          "value": "http://vault${count.index}:8200"
      },
      {
        "name": "VAULT_CLUSTER_ADDR",
        "value": "http://cluster-vault${count.index}:8201"
      },
      {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "value": "${aws_iam_access_key.vault-user.secret}"
      },
      {
        "name": "VAULT_SEAL_TYPE",
        "value": "awskms"
      },
      {
        "name": "VAULT_AWSKMS_SEAL_KEY_ID",
        "value": "${aws_kms_key.vault_key.key_id}"
      },
      {
        "name": "VAULT_DISABLE_MLOCK",
        "value": "false"
      }
    ],
    "essential": true
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_service_discovery_http_namespace" "vault" {
  name        = "vault"
  description = "Namespace for hashicorp vault."
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "vault-svc" {
  count           = 2
  name            = "${var.ecs_service_name}-${count.index}"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.ecs-task-def[count.index].arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets = module.vpc.public_subnets
    security_groups = [
      aws_security_group.vault.id
    ]
    assign_public_ip = "true"
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.vault.arn
    service {
      client_alias {
        dns_name = "vault${count.index}"
        port     = 8200
      }
      port_name = "vault${count.index}"
    }

    service {
      client_alias {
        dns_name = "cluster-vault${count.index}"
        port     = 8201
      }
      port_name = "cluster-vault${count.index}"
    }

  }
}

