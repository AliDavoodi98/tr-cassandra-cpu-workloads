resource "aws_ecr_repository" "ansible_repo" {
  name = "ansible-playbook-repo"
}

# ecs_cluster
resource "aws_ecs_cluster" "ansible_cluster" {
  name = "ansible-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": { "Service": "ecs-tasks.amazonaws.com" },
        "Effect": "Allow",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# ecs_task
resource "aws_ecs_task_definition" "ansible_task" {
  family                   = "ansible-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name       = "ansible-container"
      image      = "${aws_ecr_repository.ansible_repo.repository_url}:latest"
      essential  = true
      command    = ["ansible-playbook", "/playbooks/your_playbook.yml"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ansible-playbook"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


# ecs_service.tf

resource "aws_ecs_service" "ansible_service" {
  name            = "ansible-service"
  cluster         = aws_ecs_cluster.ansible_cluster.id
  task_definition = aws_ecs_task_definition.ansible_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["10.0.1.0/16"] # Replace with your subnet ID(s)
    security_groups = [var.security_group_id] # Replace with your security group ID
    assign_public_ip = true
  }
}
