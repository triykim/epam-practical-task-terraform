variable "region" {
  description = "Region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Name of AWS profile to use"
  type        = string
  default     = "default"
}

variable "vpc_name" {
  description = "Name for VPC"
  type        = string
  default     = "custom-vpc"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Resources tags"
  type        = map(string)
  default     = {
    Terraform = "true"
    Environment = "dev"
    Project = "epam"
  }
}

variable "instance_name_prefix" {
  description = "Value of the EC2 instance's Name prefix"
  type        = string
  default     = "web-server"
}

variable "instance_type" {
  description = "The EC2 instance's type"
  type        = string
  default     = "t3.small"
}