locals {
  cloud = lower(var.cloud)
}

module "cloudflare_dns" {
  count  = var.enable_cloudflare_dns ? 1 : 0
  source = "../../modules/cloudflare-dns"

  zone_name      = var.cloudflare_zone_name
  aws_origin     = var.cloudflare_aws_origin
  gcp_origin     = var.cloudflare_gcp_origin
  azure_origin   = var.cloudflare_azure_origin
  primary_origin = var.cloudflare_primary_origin
}

module "aws" {
  count  = local.cloud == "aws" ? 1 : 0
  source = "../../modules/aws-platform"
  name_prefix = var.name_prefix
  environment = var.environment
  region = var.aws_region
  vpc_cidr = var.aws_vpc_cidr
  availability_zones = var.aws_availability_zones
  private_subnets = var.aws_private_subnets
  public_subnets = var.aws_public_subnets
  enable_nat_gateway = var.enable_nat_gateway
  enable_vm = var.enable_aws_vm
  vm_ami_id = var.aws_vm_ami_id
  tags = var.tags
}

module "gcp" {
  count  = local.cloud == "gcp" ? 1 : 0
  source = "../../modules/gcp-platform"
  project_id = var.gcp_project_id
  name_prefix = var.name_prefix
  environment = var.environment
  region = var.gcp_region
  zone = var.gcp_zone
  subnet_cidr = var.gcp_subnet_cidr
  enable_vm = var.enable_gcp_vm
  labels = var.tags
}

module "azure" {
  count  = local.cloud == "azure" ? 1 : 0
  source = "../../modules/azure-platform"
  name_prefix = var.name_prefix
  environment = var.environment
  location = var.azure_location
  vnet_cidr = var.azure_vnet_cidr
  aks_subnet_cidr = var.azure_aks_subnet_cidr
  enable_vm = var.enable_azure_vm
  vm_admin_password = var.azure_vm_admin_password
  tags = var.tags
}