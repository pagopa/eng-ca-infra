resource "aws_cloudwatch_log_group" "ecs_vault_sd" {
  name = "ecs/vault-sc"

  retention_in_days = var.ecs_logs_retention_days

  tags = {
    Name = "vault"
  }
}



#---------------------------
# ECS Cluster
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "ecs_cluster_sd" {
  name = format("%s-sd", var.ecs_cluster_name)
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_sd" {
  cluster_name = aws_ecs_cluster.ecs_cluster_sd.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


#---------------------------
# ECS Task Definition
#---------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition

resource "aws_ecs_task_definition" "ecs-task-def_sd" {
  count                    = 2
  family                   = "vault-ecs-task-def-${count.index}_sd"
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
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_vault_sd.id}",
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

resource "aws_service_discovery_private_dns_namespace" "vault_sd" {
  name        = "vault.local"
  description = "Vault private DNS namespace"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "vault_sd" {
  count = 2
  name  = format("%s%s", var.ecs_service_name, count.index)

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.vault_sd.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  /*
  health_check_config {
    failure_threshold = 10
    resource_path     = "/v1/sys/health"
    type              = "HTTP"
  }
  */
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "vault-svc_sd" {
  count           = 2
  name            = "${var.ecs_service_name}-${count.index}"
  cluster         = aws_ecs_cluster.ecs_cluster_sd.arn
  task_definition = aws_ecs_task_definition.ecs-task-def_sd[count.index].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = module.vpc.public_subnets
    security_groups = [
      aws_security_group.vault.id
    ]
    assign_public_ip = "true"
  }

  /*
   service_discovery {
      namespace_id = aws_servicediscovery_private_dns_namespace.vault_sd.id
      name = "vault_ns_sd"
    }

  */

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.vault_sd.arn
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

    #TODO: this does not work.If you recreate the service discovery you need to delete the service before.
    /*
    triggers = {
      redeployment = aws_service_discovery_service.vault_sd[count.index].arn
    }
    */

  }

  service_registries {
    registry_arn = aws_service_discovery_service.vault_sd[count.index].arn
  }

  depends_on = [aws_service_discovery_service.vault_sd]

}

