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