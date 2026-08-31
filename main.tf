data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_instance" "nat_instance" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.ssh_key_name
  iam_instance_profile = aws_iam_instance_profile.nat_instance.name
  primary_network_interface {
    network_interface_id = aws_network_interface.nat_instance.id
  }
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp3"
    delete_on_termination = true
    tags = merge(var.tags, {
      Name = "${var.name}-nat-instance"
    })
  }
  user_data = templatefile("${path.module}/ec2_user_data.tpl", {
    vpc_cidr = data.aws_vpc.selected.cidr_block
    region   = var.region
  })
  tags = merge(var.tags, {
    Name = "${var.name}-nat-instance"
  })
  # The provider forbids setting source_dest_check alongside primary_network_interface.
  # Source/destination check is disabled on the dedicated ENI (device 0) below, which
  # is what governs NAT forwarding. Ignore the instance-level attribute so Terraform
  # does not revert it to its default (true) and break the NAT.
  # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#ignore_changes
  lifecycle {
    ignore_changes = [source_dest_check]
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nat_instance" {
  name               = "${var.name}-nat-instance-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_instance" {
  name = "${var.name}-nat-instance-ssm"
  role = aws_iam_role.nat_instance.name
  tags = var.tags
}

resource "aws_network_interface" "nat_instance" {
  subnet_id         = var.public_subnet_id
  source_dest_check = false
  security_groups   = concat([aws_security_group.nat_instance.id], var.additional_security_group_ids)
  tags = merge(var.tags, {
    Name = "${var.name}-nat-instance"
  })
}

resource "aws_route" "private" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat_instance.id
}

resource "aws_eip" "nat_instance" {
  network_interface = aws_network_interface.nat_instance.id
  depends_on        = [aws_network_interface.nat_instance, aws_instance.nat_instance]
  tags = merge(var.tags, {
    Name = "${var.name}-nat-instance"
  })
}

# Rules are managed with dedicated aws_vpc_security_group_{ingress,egress}_rule
# resources instead of the inline ingress/egress attributes on
# aws_security_group, per the current AWS provider guidance (v5+):
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule
resource "aws_security_group" "nat_instance" {
  name        = "${var.name}-nat-instance"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "vpc_cidr" {
  security_group_id = aws_security_group.nat_instance.id
  description       = "Ingress CIDR"
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  ip_protocol       = "-1"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "default" {
  security_group_id = aws_security_group.nat_instance.id
  description       = "Default egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags              = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "additional" {
  for_each = var.additional_ingress_rules

  security_group_id            = aws_security_group.nat_instance.id
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  tags                         = var.tags
}
