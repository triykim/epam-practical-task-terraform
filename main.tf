provider "aws" {
  region  = local.region
  profile = "default"
}

locals {
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Terraform = "true"
    Environment = "dev"
    Project = "epam"
  }
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

  name = "custom-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]

  tags = local.tags
}

resource "aws_instance" "app_server" {
  count = 2
  ami           = data.aws_ami.al_latest.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id = module.vpc.private_subnets[count.index]

  tags = merge(
    local.tags,
    {
      Name = "app_server${count.index + 1}"
    }
  )
}