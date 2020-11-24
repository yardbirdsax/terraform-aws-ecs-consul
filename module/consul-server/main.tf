resource "aws_efs_file_system" "consul_server_efs" {
  tags = {
    "name" = var.deployment_name
  }
}

resource "aws_security_group" "consul_server_efs_access" {
  name = join("-",[var.deployment_name,"consul-server-efs-access"])
  vpc_id = var.vpc_id
}

resource "aws_security_group" "consul_server_efs" {
  name = join("-",[var.deployment_name,"consul-server-efs"])
  vpc_id = var.vpc_id
  ingress {
    from_port = 2049
    protocol = "tcp"
    security_groups = [ aws_security_group.consul_server_efs_access.id ]
    to_port = 2049
  }
}

resource "aws_efs_mount_target" "consul_server_efs" {
  count = length(var.subnet_ids)
  file_system_id = aws_efs_file_system.consul_server_efs.id
  subnet_id = var.subnet_ids[count.index]
  security_groups = [ aws_security_group.consul_server_efs.id ]
}

resource "aws_efs_access_point" "consul_server_efs_access_point" {
  count = var.server_task_count
  file_system_id = aws_efs_file_system.consul_server_efs.id
  root_directory {
    path = join("/",["","consul_server",count.index])
  }
}

resource "aws_ecs_task_definition" "consul_server" {
  family = join("-",[var.deployment_name,"consul-server"])

  cpu = var.cpu
  memory = var.memory
  network_mode = "awsvpc"
  volume {
    name = "consul-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.consul_server_efs.id
      transit_encryption = "ENABLED"
      root_directory = "/"
    }
  }
  container_definitions = <<EOT
[
  {
    "name" : "consule-server",
    "image": "consul:${var.consul_version}",
    "mountPoints": [
      {
        "sourceVolume": "consul-data",
        "containerPath": "/mnt/efs"
      }
    ],
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
    security_groups = concat(var.security_group_ids,[aws_security_group.consul_server_efs_access.id])
  }
  platform_version = "1.4.0"
}