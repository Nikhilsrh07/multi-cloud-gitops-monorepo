variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "subnet_cidr" { type = string }
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
	default = {}
}