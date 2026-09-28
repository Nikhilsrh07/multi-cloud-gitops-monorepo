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
  description = "Container image tag for the portfolio app."
  type        = string
  default     = "latest"
}

variable "labels" {
  type    = map(string)
  default = {}
}
