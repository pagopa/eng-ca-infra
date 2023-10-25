resource "aws_ecs_task_definition" "github_runner_def" {
  count                    = 2
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
    "image": "ghcr.io/actions/actions-runner:2.311.0",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "github/runners",
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