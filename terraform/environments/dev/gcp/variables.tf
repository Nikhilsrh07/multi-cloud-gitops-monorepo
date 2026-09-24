variable "project_id" {
  description = "GCP project used for the selected environment."
  type        = string
}

variable "name_prefix" {
  type    = string
  default = "portfolio"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "enable_vm" {
  type    = bool
  default = false
}

variable "vm_machine_type" {
  type    = string
  default = "e2-micro"
}

variable "vm_image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "labels" {
  type    = map(string)
  default = { app = "portfolio" }
}
