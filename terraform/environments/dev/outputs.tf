output "aws_cluster_name" { value = try(module.aws[0].cluster_name, null) }
output "gcp_cluster_name" { value = try(module.gcp[0].cluster_name, null) }
output "azure_cluster_name" { value = try(module.azure[0].cluster_name, null) }
output "cloudflare_www_hostname" { value = try(module.cloudflare_dns[0].www_hostname, null) }
output "cloudflare_cloud_hostnames" { value = try(module.cloudflare_dns[0].cloud_hostnames, null) }