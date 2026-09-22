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

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = var.tags
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = local.name
  cluster_version = var.kubernetes_version
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.private_subnets

  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }
  tags = var.tags
}

resource "aws_iam_role" "workload" {
  name = "${local.name}-workload"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_instance" "portfolio_vm" {
  count                       = var.enable_vm ? 1 : 0
  ami                         = var.vm_ami_id
  instance_type               = var.vm_instance_type
  subnet_id                   = module.network.private_subnets[0]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.workload[0].name
  tags                        = merge(var.tags, { Name = "${local.name}-vm" })
}

resource "aws_iam_instance_profile" "workload" {
  count = var.enable_vm ? 1 : 0
  name  = "${local.name}-profile"
  role  = aws_iam_role.workload.name
}