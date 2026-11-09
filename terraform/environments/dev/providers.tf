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

# AzureRM is initialized only when the Azure module is selected. This keeps
# GCP/AWS deployments from requiring an Azure CLI tenant or subscription.
provider "azurerm" {
  alias = "portfolio"
  features {}
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

provider "cloudflare" {
  api_token = var.enable_cloudflare_dns ? var.cloudflare_api_token : "cfut_0000000000000000000000000000000000000000"
}

# AzureRM requires `features {}` even when the Azure module is not selected.
# The Cloudflare placeholder is unused while DNS is disabled; the GitOps script
# passes the sensitive real token only when the DNS module is enabled.