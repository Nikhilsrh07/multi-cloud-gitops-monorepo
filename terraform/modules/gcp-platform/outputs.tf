output "vm_public_ip" {
  description = "Public IP of the $0 portfolio VM (k3s node). Feeds Cloudflare DNS dynamically."
  value       = google_compute_instance.portfolio.network_interface[0].access_config[0].nat_ip
}

output "network_name" {
  value = google_compute_network.platform.name
}
