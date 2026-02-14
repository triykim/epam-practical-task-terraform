provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

data "aws_availability_zones" "available" {}

data "aws_ami" "al_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 100)]
  enable_nat_gateway = true
  tags = var.tags
}

resource "aws_security_group" "lb-sg" {
  name        = "lb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "lb-sg"
  })
}

resource "aws_security_group" "instance-sg" {
  name        = "instance-sg"
  description = "Allow HTTP from LB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from LB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "instance-sg"
  })
}

resource "aws_instance" "web_server" {
  count = 2
  ami           = data.aws_ami.al_latest.id
  instance_type = var.instance_type
  subnet_id = module.vpc.private_subnets[count.index]

  security_groups = [aws_security_group.instance-sg.id]
  user_data = file("${path.module}/userdata.sh")

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name_prefix}${count.index + 1}"
    }
  )
}

resource "aws_elb" "my-elb" {
  name               = "my-elb"
  subnets = module.vpc.public_subnets[*]
  security_groups = [aws_security_group.lb-sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = aws_instance.web_server[*].id

  tags = merge(
    var.tags,
    {
      Name = "my-elb"
    }
  )
}