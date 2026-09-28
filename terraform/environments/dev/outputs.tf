output "vm_public_ip" {
  description = "Public IP of the $0 portfolio VM (k3s node). Feeds Cloudflare DNS dynamically."
  value       = aws_instance.portfolio.public_ip
}

output "vm_public_dns" {
  description = "Public DNS of the $0 portfolio VM."
  value       = aws_instance.portfolio.public_dns
}

output "vpc_id" {
  value = module.network.vpc_id
}
