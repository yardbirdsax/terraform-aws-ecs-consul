resource "aws_ecs_task_definition" "consul_server" {
  family = join("-",[var.deployment_name,"consul-server"])

  cpu = var.cpu
  memory = var.memory
  network_mode = "awsvpc"
  container_definitions = <<EOT
[
  {
    "name" : "consule-server",
    "image": "consul:${var.consul_version}",
    "portMappings": [
      {
        "containerPort": 8600
      },
      {
        "containerPort": 8500
      },
      {
        "containerPort": 8301
      },
      {
        "containerPort": 8302
      },
      {
        "containerPort": 8300
      }
    ]
  }
]
EOT

  tags = {
    "name" = var.deployment_name
  }
}

resource "aws_ecs_service" "ecs_service" {
  name = join("-",[var.deployment_name,"-consul-server"])
  cluster = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.consul_server.arn
  desired_count = var.server_task_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    assign_public_ip = var.assign_public_ips
    security_groups = var.security_group_ids
  }
}