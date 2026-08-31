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

variable "tags" {
  description = "Additional tags applied to all resources created by the module."
  type        = map(string)
  default     = {}
}

variable "additional_security_group_ids" {
  description = "Extra security group ids attached to the NAT instance network interface, in addition to the one created by this module"
  type        = list(string)
  default     = []
}

variable "additional_ingress_rules" {
  description = "Extra ingress rules appended to the NAT instance security group, keyed by rule name. See aws_vpc_security_group_ingress_rule for the argument reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule"
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}
