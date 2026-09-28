# $0 AWS platform: free-tier t3.micro running k3s (single-node Kubernetes).
# No EKS control plane ($73/mo), no NAT gateway ($32/mo), no ALB.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name = "${var.name_prefix}-${var.environment}"
}

# Ubuntu AMI resolved dynamically — no static AMI IDs.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # $0: NAT gateway disabled; the portfolio VM lives in a public subnet.
  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_security_group" "portfolio" {
  name        = "${local.name}-portfolio-sg"
  description = "Portfolio k3s node ($0 free tier)"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "portfolio" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro" # free tier: 750 hrs/month
  subnet_id                   = module.network.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.portfolio.id]

  user_data = templatefile("${path.module}/templates/portfolio-user-data.sh.tpl", {
    image_repository = var.image_repository
    image_tag        = var.image_tag
  })
  # New image tag => new VM with the fresh image baked in.
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 30 # free tier: 30 GB EBS
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, { Name = "${local.name}-portfolio" })
}
