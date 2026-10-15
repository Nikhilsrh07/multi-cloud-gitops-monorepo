terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Cloud-specific auth is intentionally configured by the selected module/CLI,
# not by the shared environment root. Keeping Azure/Cloudflare providers here
# caused Terraform to validate all cloud credentials even when only GCP was used.
# Azure auth is supplied by `az login` or ARM_* env vars when the Azure module runs.
# Cloudflare auth is supplied by CLOUDFLARE_API_TOKEN when DNS is enabled.