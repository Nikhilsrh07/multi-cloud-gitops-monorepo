variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "location" {
  description = "Azure region. B1s is free-tier eligible (750 hrs/month, 12 months)."
  type        = string
}
variable "vnet_cidr" { type = string }
variable "subnet_cidr" { type = string }

variable "image_repository" {
  description = "Container image repository for the portfolio app (e.g. ghcr.io/nikhilsrh07/portfolio-website)."
  type        = string
}

variable "image_tag" {
  description = "Container image tag for the portfolio app."
  type        = string
  default     = "latest"
}

variable "vm_admin_username" {
  type    = string
  default = "portfolioadmin"
}
variable "vm_admin_password" {
  description = "Admin password for the VM (use a strong value via tfvars; never commit it)."
  type        = string
  sensitive   = true
  default     = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
