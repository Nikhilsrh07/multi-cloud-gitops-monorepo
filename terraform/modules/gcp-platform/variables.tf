variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "region" {
  description = "GCP region. e2-micro is always-free in us-central1, us-east1, us-west1."
  type        = string
}
variable "zone" { type = string }
variable "subnet_cidr" { type = string }

variable "image_repository" {
  description = "Container image repository for the portfolio app (e.g. ghcr.io/nikhilsrh07/portfolio-website)."
  type        = string
}

variable "image_tag" {
  description = "Immutable container image tag deployed by the CI workflow."
  type        = string
}

variable "site_hostname" {
  description = "Public hostname served by the Traefik ingress."
  type        = string
}

variable "acme_email" {
  description = "Contact email used when Traefik requests a Let's Encrypt certificate."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
