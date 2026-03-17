# ─── Terraform Configuration ───
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

# ─── AWS Provider ───
provider "aws" {
    region = var.aws_region
}

# ─── VPC ───
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Lab7-VPC"
    }
}