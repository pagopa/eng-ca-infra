resource "aws_cloudwatch_log_group" "ecs_github_runner" {
  name = "github/runners"

  retention_in_days = var.ecs_logs_retention_days

  tags = {
    Name = "vault"
  }
}

# TODO: review
resource "aws_ecr_repository" "runner_ecr" {
  name                 = "github-runner"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_task_definition" "github_runner_def" {
  family                   = format("%s-githubrunner", local.project)
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_vault_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "githubrunner",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/github-runner:1",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_github_runner.id}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "run"
      }
    },
    "environment": [],
    "essential": true
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}