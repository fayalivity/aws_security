# Plugins
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider
provider "aws" {
  region  = "us-east-1"
  profile = "default"

  default_tags {
    tags = {
      Name            = var.tag_prefix
      Environment     = "dev"
      Learning-Course = "security"
      ManagedBy       = "terraform"
    }
  }
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "sn-${var.tag_prefix}-vpc"
  }
}

# Subnets
# Public 1a
resource "aws_subnet" "subnet_public_1a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_1a_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn-${var.tag_prefix}-public-1a"
  }
}

# Public 1b
resource "aws_subnet" "subnet_public_1b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_1b_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "sn-${var.tag_prefix}-public-1b"
  }
}

# Private 1a
resource "aws_subnet" "subnet_private_1a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_1a_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn-${var.tag_prefix}-private-1a"
  }
}

# Private 1b
resource "aws_subnet" "subnet_private_1b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_1b_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "sn-${var.tag_prefix}-private-1b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Public Route Table
resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rtb-${var.tag_prefix}-public"
  }
}

# Private Route Table
resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "rtb-${var.tag_prefix}-private"
  }
}

# Public Route Tables associations
resource "aws_route_table_association" "rtb_assoc_public_1a" {
  route_table_id = aws_route_table.rtb_public.id
  subnet_id      = aws_subnet.subnet_public_1a.id
}

resource "aws_route_table_association" "rtb_assoc_public_1b" {
  route_table_id = aws_route_table.rtb_public.id
  subnet_id      = aws_subnet.subnet_public_1b.id
}

# Private Route Tables associations
resource "aws_route_table_association" "rtb_assoc_private_1a" {
  route_table_id = aws_route_table.rtb_private.id
  subnet_id      = aws_subnet.subnet_private_1a.id
}

resource "aws_route_table_association" "rtb_assoc_private_1b" {
  route_table_id = aws_route_table.rtb_private.id
  subnet_id      = aws_subnet.subnet_private_1b.id
}

# Elastic IP
resource "aws_eip" "nat_eip" {
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_public_1a.id
}

# KeyPair
resource "aws_key_pair" "keypair" {
  key_name   = var.public_key_name
  public_key = file("./${var.public_key_name}.pub")
}

# Bastion Security Group and rules
resource "aws_security_group" "sg_bastion" {
  name        = "secgr-bastion"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security Group attached to Bastion instance"

  tags = {
    Name = "secgr-${var.tag_prefix}-bastion"
  }
}

resource "aws_security_group_rule" "ssh_from_anywhere" {
  security_group_id = aws_security_group.sg_bastion.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egree_anywhere_bastion" {
  security_group_id = aws_security_group.sg_bastion.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}



# App Security Group and rules
resource "aws_security_group" "sg_app" {
  name        = "secgr-app"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security Group attached to App instance"

  tags = {
    Name = "secgr-${var.tag_prefix}-app"
  }
}

resource "aws_security_group_rule" "ssh_from_bastion" {
  security_group_id        = aws_security_group.sg_app.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_bastion.id
}

resource "aws_security_group_rule" "http_from_alb" {
  security_group_id        = aws_security_group.sg_app.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_alb.id
}

resource "aws_security_group_rule" "egree_anywhere_app" {
  security_group_id = aws_security_group.sg_app.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# EC2 Instances
# Bastion
resource "aws_instance" "bastion" {
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.amazon_linux_2023.image_id
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]
  subnet_id                   = aws_subnet.subnet_public_1a.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.key_name

  root_block_device {
    encrypted             = true
    kms_key_id            = data.aws_kms_key.key_lab.arn
    delete_on_termination = true
  }

    provisioner "file" {
        source = "lab-key"
        destination = "~/.ssh/authorized_keys"

        connection {
          type = "ssh"
          user = "ec2-user"
          private_key = "~/.ssh/id_rsa"
          host = "${self.public_dns}"
        }
    }

  tags = {
    Name = "${var.tag_prefix}-bastion"
  }
}

# EC2 Instances
# App
resource "aws_instance" "app" {
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.amazon_linux_2023.image_id
  vpc_security_group_ids      = [aws_security_group.sg_app.id]
  subnet_id                   = aws_subnet.subnet_private_1a.id
  associate_public_ip_address = false
  user_data_base64            = base64encode(file("./app-userdata.sh"))
  user_data_replace_on_change = true
  key_name                    = aws_key_pair.keypair.key_name

  root_block_device {
    encrypted             = true
    kms_key_id            = data.aws_kms_key.key_lab.arn
    delete_on_termination = true
  }

  tags = {
    Name = "${var.tag_prefix}-app"
  }
}


# Load balancer
resource "aws_lb" "alb" {
  name               = "${var.tag_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.subnet_public_1a.id, aws_subnet.subnet_public_1b.id]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.tag_prefix}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# Load balancer security group
resource "aws_security_group" "sg_alb" {
  name        = "secgr-alb"
  description = "Security Group attached to Application Load Balancer"
  vpc_id      = aws_vpc.main_vpc.id
}

resource "aws_security_group_rule" "http_from_anywhere" {
  security_group_id = aws_security_group.sg_alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "tcp"
}

resource "aws_security_group_rule" "egress_anywhere_alb" {
  security_group_id = aws_security_group.sg_alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
}