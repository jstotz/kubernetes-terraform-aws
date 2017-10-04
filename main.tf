provider "aws" {
  region = "${var.aws_region}"

  assume_role {
    role_arn = "${var.aws_role}"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.240.0.0/16"

  tags {
    Name = "${var.name}"
  }

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "${var.aws_region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.240.0.0/16"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route" "r" {
  route_table_id         = "${aws_route_table.main.id}"
  gateway_id             = "${aws_internet_gateway.main.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "main" {
  name        = "${var.name}"
  description = "Kubernetes"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_security_group_rule" "egress_all" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "self_ingress_all" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  self              = true
}

resource "aws_security_group_rule" "private_ingress_all" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["10.240.0.0/16"]
}

resource "aws_security_group_rule" "public_ingress_ssh" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_ingress_k8s" {
  security_group_id = "${aws_security_group.main.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 6443
  to_port           = 6443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_elb" "k8s" {
  name            = "${var.name}"
  subnets         = ["${aws_subnet.main.id}"]
  security_groups = ["${aws_security_group.main.id}"]

  listener {
    lb_protocol       = "tcp"
    lb_port           = 6443
    instance_protocol = "tcp"
    instance_port     = 6443
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.name}"
  public_key = "${var.public_key}"
}

resource "aws_iam_role" "main" {
  name = "${var.name}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {"Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole"}
    ]
}
EOF
}

resource "aws_iam_role_policy" "main" {
  name = "${var.name}"
  role = "${aws_iam_role.main.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {"Effect": "Allow", "Action": ["ec2:*"], "Resource": ["*"]},
        {"Effect": "Allow", "Action": ["elasticloadbalancing:*"], "Resource": ["*"]},
        {"Effect": "Allow", "Action": ["route53:*"], "Resource": ["*"]},
        {"Effect": "Allow", "Action": ["ecr:*"], "Resource": "*"}
    ]
}
EOF
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.name}"
  role = "${var.name}"
}

resource "aws_instance" "controllers" {
  count                       = 3
  ami                         = "${var.ami_id}"
  instance_type               = "t2.small"
  iam_instance_profile        = "${var.name}"
  associate_public_ip_address = true
  private_ip                  = "10.240.0.${10 + count.index}"
  subnet_id                   = "${aws_subnet.main.id}"
  key_name                    = "${var.name}"
  vpc_security_group_ids      = ["${aws_security_group.main.id}"]
  source_dest_check           = false

  tags {
    Name = "${var.name}-controller-${count.index}"
  }
}

resource "aws_instance" "workers" {
  count                       = 3
  ami                         = "${var.ami_id}"
  instance_type               = "t2.small"
  iam_instance_profile        = "${var.name}"
  associate_public_ip_address = true
  private_ip                  = "10.240.0.${20 + count.index}"
  subnet_id                   = "${aws_subnet.main.id}"
  key_name                    = "${var.name}"
  vpc_security_group_ids      = ["${aws_security_group.main.id}"]
  source_dest_check           = false

  tags {
    Name = "${var.name}-worker-${count.index}"
  }
}
