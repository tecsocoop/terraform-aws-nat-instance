variable "name" {
  description = "Base name for the created resources, e.g. sit-tecso"
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet id where the network interface is placed"
  type        = string
}

variable "private_route_table_id" {
  description = "Private route table id where the 0.0.0.0/0 route to the NAT instance is added"
  type        = string
}

variable "ami_id" {
  description = "AMI id for the NAT instance"
  type        = string
  default     = "ami-07e37c8abeea5202c" # Debian 13
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3a.nano"
}

variable "ssh_key_name" {
  description = "AWS key pair name for SSH access (optional; not required when using SSM Session Manager)"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region, used for the SSM agent download endpoint"
  type        = string
  default     = "us-east-1"
}
