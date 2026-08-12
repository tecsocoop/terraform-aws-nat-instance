data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_instance" "nat_instance" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.ssh_key_name
  iam_instance_profile = aws_iam_instance_profile.nat_instance.name
  source_dest_check = false
  primary_network_interface {
    network_interface_id = aws_network_interface.nat_instance.id
  }
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp3"
    delete_on_termination = true
  }
  user_data = templatefile("${path.module}/ec2_user_data.tpl", {
    vpc_cidr = data.aws_vpc.selected.cidr_block
    region   = var.region
  })
  tags = {
    Name = "${var.name}-nat-instance"
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
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_instance" {
  name = "${var.name}-nat-instance-ssm"
  role = aws_iam_role.nat_instance.name
}

resource "aws_network_interface" "nat_instance" {
  subnet_id         = var.public_subnet_id
  source_dest_check = false
  security_groups   = [aws_security_group.nat_instance.id]
  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_route" "private" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat_instance.id
}

resource "aws_eip" "nat_instance" {
  network_interface = aws_network_interface.nat_instance.id
  depends_on        = [aws_network_interface.nat_instance, aws_instance.nat_instance]
  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_security_group" "nat_instance" {
  name        = "${var.name}-nat-instance"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Ingress CIDR"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [data.aws_vpc.selected.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "Default egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}
