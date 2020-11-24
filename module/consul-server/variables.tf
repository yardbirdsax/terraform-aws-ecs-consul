variable "deployment_name" {
  type = string
  description = "The name used to generate unique names for various resources."
}

variable "cpu" {
  type = string
  description = "The CPU configuration to use for the task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size."
  validation {
    condition = contains(["256","512","1024","2048","4096"],var.cpu)
    error_message = "You must specify a valid value for the CPU variable. See the description for details."
  }
}

variable "memory" {
  type = string
  description = "The memory configuration for the task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size."
}

variable "consul_version" {
  type = string
  description = "The version of Consul to use."
  default = "1.8.5"
}

variable "ecs_cluster_id" {
  type = string
  description = "The ID of the ECS cluster to deploy the service on."
}

variable "server_task_count" {
  type = number
  description = "The number of Consul server tasks to run."
}

variable "subnet_ids" {
  type = list(string)
  description = "The subnets to provision the tasks in."
}

variable "assign_public_ips" {
  type = bool
  description = "If 'true', the tasks will be assigned public IPs and must be present in a subnet with an internet gateway assigned to it."
  default = false
}

variable "security_group_ids" {
  type = list(string)
  description = "The security groups to attach to the tasks."
}

variable "vpc_id" {
  type = string
  description = "The ID of the VPC where the ECS tasks will be provisioned."
}