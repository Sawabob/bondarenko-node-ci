terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "optima-devops-12"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_ssm_parameter" "ubuntu" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "deploy" {
  key_name   = var.key_name
  public_key = trimspace(file("${path.module}/${var.public_key_path}"))
}

resource "aws_security_group" "web" {
  name_prefix = "optima-devops-12-"
  description = "SSH deployment and public HTTP on port 3000"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH for GitHub Actions"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "Node.js HTTP"
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.ubuntu[0].insecure_value
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deploy.key_name
  user_data_replace_on_change = true

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-BOOTSTRAP
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -o Acquire::Retries=3
    apt-get install -y -o Acquire::Retries=3 docker.io docker-compose-v2 curl
    systemctl enable --now docker
    docker compose version
    printf 'OPTIMA_ED25519_HOST_KEY %s\n' "$(cut -d ' ' -f 1,2 /etc/ssh/ssh_host_ed25519_key.pub)" > /dev/console
  BOOTSTRAP

  tags = {
    Name = "optima-devops-12"
  }
}
