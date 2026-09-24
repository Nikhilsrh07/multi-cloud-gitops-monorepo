terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "portfolio" {
  name = var.zone_name
}

locals {
  zone_id = data.cloudflare_zone.portfolio.id
}

resource "cloudflare_record" "aws" {
  zone_id = local.zone_id
  name    = "aws"
  content = var.aws_origin
  type    = "CNAME"
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_record" "gcp" {
  zone_id = local.zone_id
  name    = "gcp"
  content = var.gcp_origin
  type    = "CNAME"
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_record" "azure" {
  zone_id = local.zone_id
  name    = "azure"
  content = var.azure_origin
  type    = "CNAME"
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_record" "www" {
  zone_id = local.zone_id
  name    = "www"
  content = var.primary_origin
  type    = "CNAME"
  proxied = var.proxied
  ttl     = 1
}