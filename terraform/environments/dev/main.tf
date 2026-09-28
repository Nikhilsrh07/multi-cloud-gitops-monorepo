# $0 portfolio: single code path for all clouds.
# Only the selected cloud's module is created; its VM public IP is discovered
# dynamically and fed to Cloudflare DNS — no static IPs or hostnames.

locals {
  cloud = lower(var.cloud)

  # VM public IPs discovered from whichever cloud module was created.
  cloud_ips = {
    for cloud, ip in {
      aws   = try(module.aws[0].vm_public_ip, "")
      gcp   = try(module.gcp[0].vm_public_ip, "")
      azure = try(module.azure[0].vm_public_ip, "")
    } : cloud => ip if trimspace(ip) != ""
  }
}

module "cloudflare_dns" {
  count  = var.enable_cloudflare_dns ? 1 : 0
  source = "../../modules/cloudflare-dns"

  zone_name              = var.cloudflare_zone_name
  primary_cloud          = local.cloud
  cloud_ips              = local.cloud_ips
  enable_cloud_redirects = var.enable_cloudflare_redirects
}

module "aws" {
  count  = local.cloud == "aws" ? 1 : 0
  source = "../../modules/aws-platform"

  name_prefix        = var.name_prefix
  environment        = var.environment
  region             = var.aws_region
  vpc_cidr           = var.aws_vpc_cidr
  availability_zones = var.aws_availability_zones
  private_subnets    = var.aws_private_subnets
  public_subnets     = var.aws_public_subnets
  image_repository   = var.image_repository
  image_tag          = var.image_tag
  tags               = var.tags
}

module "gcp" {
  count  = local.cloud == "gcp" ? 1 : 0
  source = "../../modules/gcp-platform"

  project_id       = var.gcp_project_id
  name_prefix      = var.name_prefix
  environment      = var.environment
  region           = var.gcp_region
  zone             = var.gcp_zone
  subnet_cidr      = var.gcp_subnet_cidr
  image_repository = var.image_repository
  image_tag        = var.image_tag
  labels           = var.tags
}

module "azure" {
  count  = local.cloud == "azure" ? 1 : 0
  source = "../../modules/azure-platform"

  name_prefix       = var.name_prefix
  environment       = var.environment
  location          = var.azure_location
  vnet_cidr         = var.azure_vnet_cidr
  subnet_cidr       = var.azure_subnet_cidr
  image_repository  = var.image_repository
  image_tag         = var.image_tag
  vm_admin_password = var.azure_vm_admin_password
  tags              = var.tags
}
