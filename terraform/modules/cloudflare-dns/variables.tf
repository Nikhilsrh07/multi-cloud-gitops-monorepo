variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }

variable "image_repository" {
  description = "Container image repository for the portfolio app (e.g. ghcr.io/nikhilsrh07/portfolio-website)."
  type        = string
}

variable "image_tag" {
  description = "Container image tag for the portfolio app."
  type        = string
  default     = "latest"
}

variable "tags" {
  type    = map(string)
  default = {}
}
