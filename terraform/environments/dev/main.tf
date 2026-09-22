module "aws" {
  count  = var.enable_aws ? 1 : 0
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
  count  = var.enable_gcp ? 1 : 0
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
  count  = var.enable_azure ? 1 : 0
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