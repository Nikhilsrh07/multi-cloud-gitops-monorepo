output "www_hostname" {
  description = "The single DNS hostname serving the site."
  value       = "www.${var.zone_name}"
}

output "primary_cloud" {
  description = "Cloud currently serving www."
  value       = var.primary_cloud
}

output "cloud_hostnames" {
  description = "Per-cloud subdomains (redirect to www when enable_cloud_redirects is true)."
  value = {
    for cloud in keys(cloudflare_record.cloud) : cloud => "${cloud}.${var.zone_name}"
  }
}
