# $0 portfolio environment: one code path, cloud selected via var.cloud.
# VM IPs are discovered from module outputs — no static IPs anywhere.

variable "cloud" {
  description = "Cloud platform to provision ($0 free tier)."
  type        = string
  default     = "gcp"

  validation {
    condition     = contains(["aws", "gcp", "azure"], lower(var.cloud))
    error_message = "cloud must be one of: aws, gcp, azure."
  }
}

variable "name_prefix" {
  type    = string
  default = "portfolio"
}
variable "environment" {
  type    = string
  default = "dev"
}

# --- Portfolio container image (injected by the pipeline via TF_VAR_image_*) ---
variable "image_repository" {
  description = "Container image repository (free: ghcr.io public repo)."
  type        = string
  default     = "ghcr.io/nikhilsrh07/portfolio-website"
}
variable "image_tag" {
  description = "Container image tag (pipeline passes BUILD_NUMBER)."
  type        = string
  default     = "latest"
}

# --- AWS ($0: t3.micro free tier, no NAT gateway) ---
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "aws_availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "aws_private_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}
variable "aws_public_subnets" {
  type    = list(string)
  default = ["10.10.101.0/24", "10.10.102.0/24"]
}

# --- GCP ($0: e2-micro always-free in us-central1/us-east1/us-west1) ---
variable "gcp_project_id" {
  description = "GCP project (create with your Gmail; free tier needs no billing surprises)."
  type        = string
  default     = ""
}
variable "gcp_region" {
  type    = string
  default = "us-central1"
}
variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}
variable "gcp_subnet_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

# --- Azure ($0: B1s 750 hrs/month) ---
variable "azure_location" {
  type    = string
  default = "East US"
}
variable "azure_vnet_cidr" {
  type    = string
  default = "10.30.0.0/16"
}
variable "azure_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}
variable "azure_vm_admin_password" {
  description = "Admin password for the Azure VM (pass via tfvars; never commit)."
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  type    = map(string)
  default = { app = "portfolio" }
}

# --- Cloudflare DNS (you already set up the zone) ---
variable "enable_cloudflare_dns" {
  type    = bool
  default = false
}
variable "cloudflare_zone_name" {
  type    = string
  default = "nikhilsrh07.com"
}
variable "enable_cloudflare_redirects" {
  description = "301-redirect aws./gcp./azure. subdomains to https://www.<zone>."
  type        = bool
  default     = true
}
