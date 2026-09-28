# Dynamic outputs: whichever cloud was selected, its VM IP is exposed.
output "portfolio_vm_ip" {
  description = "Public IP of the $0 portfolio VM (k3s node)."
  value = (
    lower(var.cloud) == "aws" ? try(module.aws[0].vm_public_ip, null) :
    lower(var.cloud) == "gcp" ? try(module.gcp[0].vm_public_ip, null) :
    try(module.azure[0].vm_public_ip, null)
  )
}

output "site_url" {
  description = "Public URL of the portfolio site."
  value       = "https://www.${var.cloudflare_zone_name}"
}

output "cloudflare_www_hostname" { value = try(module.cloudflare_dns[0].www_hostname, null) }
output "cloudflare_cloud_hostnames" { value = try(module.cloudflare_dns[0].cloud_hostnames, null) }
