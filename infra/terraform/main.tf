terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "rap_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "rap-production-vpc"
  }
}

resource "aws_subnet" "rap_subnet" {
  vpc_id                  = aws_vpc.rap_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "rap-public-subnet"
  }
}

resource "aws_security_group" "rap_sg" {
  name        = "rap-cloud-sg"
  description = "Security group for Remote Access Platform signaling & TURN relay"
  vpc_id      = aws_vpc.rap_vpc.id

  ingress {
    description = "Signaling Server"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "P2P TURN/STUN Relay"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
