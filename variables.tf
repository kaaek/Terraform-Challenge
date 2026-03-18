variable "aws_region" {
    description = "AWS region to deploy resources"
    type = string
    default = "eu-central-1"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "172.16.0.0/16"
}

variable "public_subnet_cidr_az1" {
    description = "CIDR block for the public subnet in AZ 1"
    type = string
    default = "172.16.1.0/24"
}

variable "public_subnet_cidr_az2" {
    description = "CIDR block for the public subnet in AZ 2"
    type = string
    default = "172.16.2.0/24"
}

variable "private_subnet_cidr_az1" {
    description = "CIDR block for the private subnet in AZ 1"
    type = string
    default = "172.16.10.0/24"
}

variable "private_subnet_cidr_az2" {
    description = "CIDR block for the private subnet in AZ 2"
    type = string
    default = "172.16.11.0/24"
}

variable "key_name" {
    description = "Name of the SSH key pair"
    type = string
}

variable "my_ip" {
    description = "Your public IP for SSH access (e.g., 203.0.113.50/32)"
    type = string
}

variable "app_secret" {
    description = "Application secret value"
  type        = string
  sensitive   = true
}