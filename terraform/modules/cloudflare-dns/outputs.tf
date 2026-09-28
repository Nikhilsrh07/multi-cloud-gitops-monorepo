output "vm_public_ip" {
  description = "Public IP of the $0 portfolio VM (k3s node). Feeds Cloudflare DNS dynamically."
  value       = azurerm_public_ip.portfolio.ip_address
}

output "vm_public_dns" {
  description = "Public FQDN of the $0 portfolio VM."
  value       = azurerm_public_ip.portfolio.fqdn
}

output "resource_group_name" {
  value = azurerm_resource_group.platform.name
}
