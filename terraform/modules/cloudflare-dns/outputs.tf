output "www_hostname" {
  value = "www.${var.zone_name}"
}

output "cloud_hostnames" {
  value = {
    aws   = "aws.${var.zone_name}"
    gcp   = "gcp.${var.zone_name}"
    azure = "azure.${var.zone_name}"
  }
}