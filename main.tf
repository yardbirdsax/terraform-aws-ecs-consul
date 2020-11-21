locals {
  deployment_name = "terraform-aws-ecs-consul"
  subnet_cidr_ranges = [
    "10.250.0.0/25",
    "10.250.0.128/25",
    "10.250.1.0/25"
  ]
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.250.0.0/23"
  enable_dns_hostnames = true

  tags = {
    "name" = local.deployment_name
  }
}

data "aws_availability_zones" "availability_zones" {
  state = "available"
}

resource "aws_subnet" "subnet" {
  count = 3

  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.availability_zones.names[count.index]
  cidr_block = local.subnet_cidr_ranges[count.index]

  tags = {
    "name" = join("-",[local.deployment_name,data.aws_availability_zones.availability_zones.names[count.index]])
  }
}
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  count = length(aws_subnet.subnet)
  subnet_id = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "consul" {
  name = "consul-server"
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    "name" = join("-",[local.deployment_name,"consul-server"])
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Consul server API"
    from_port = 8500
    protocol = "tcp"
    to_port = 8500
  } 
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.deployment_name

  tags = {
    "name" = local.deployment_name
  }
}

module "consul_server" {
  source = "./module/consul-server"
  providers = {
    "aws" = "aws"
  }
  deployment_name = local.deployment_name
  cpu = "256"
  memory = "512"
  server_task_count = 1
  subnet_ids = aws_subnet.subnet.*.id
  ecs_cluster_id = aws_ecs_cluster.ecs_cluster.id
  assign_public_ips = true
  security_group_ids = [ aws_security_group.consul.id ]
}