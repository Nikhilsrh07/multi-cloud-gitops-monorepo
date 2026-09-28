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

  # Only clouds with a discovered IP get records — fully dynamic.
  cloud_ips = { for cloud, ip in var.cloud_ips : cloud => ip if trimspace(ip) != "" }

  redirect_hosts = [
    for cloud in keys(local.cloud_ips) : "${cloud}.${var.zone_name}"
  ]
}

# Per-cloud subdomains (A records to the $0 VM IPs).
resource "cloudflare_record" "cloud" {
  for_each = local.cloud_ips

  zone_id = local.zone_id
  name    = each.key
  content = each.value
  type    = "A"
  proxied = var.proxied
  ttl     = 1
}

# One DNS hostname for the site — points at the primary cloud's VM IP.
resource "cloudflare_record" "www" {
  zone_id = local.zone_id
  name    = "www"
  content = lookup(local.cloud_ips, var.primary_cloud, "")
  type    = "A"
  proxied = var.proxied
  ttl     = 1

  lifecycle {
    precondition {
      condition     = lookup(local.cloud_ips, var.primary_cloud, "") != ""
      error_message = "No VM IP discovered for primary_cloud '${var.primary_cloud}'."
    }
  }
}

# Redirect every per-cloud subdomain to the single www hostname.
resource "cloudflare_ruleset" "cloud_redirects" {
  count   = var.enable_cloud_redirects && length(local.redirect_hosts) > 0 ? 1 : 0
  zone_id = local.zone_id
  name    = "redirect cloud subdomains to www"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    action      = "redirect"
    description = "Redirect per-cloud subdomains to the single www hostname"
    expression  = join(" or ", [for h in local.redirect_hosts : "(http.host eq \"${h}\")"])

    action_parameters {
      from_value {
        status_code = 301
        target_url {
          expression = "concat(\"https://www.${var.zone_name}\", http.request.uri.path)"
        }
        preserve_query_string = true
      }
    }
  }
}
