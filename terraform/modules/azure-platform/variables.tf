variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "vnet_cidr" { type = string }
variable "aks_subnet_cidr" { type = string }
variable "kubernetes_version" {
	type    = string
	default = null
}
variable "node_count" {
	type    = number
	default = 1
}
variable "node_vm_size" {
	type    = string
	default = "Standard_B2s"
}
variable "enable_vm" {
	type    = bool
	default = false
}
variable "vm_size" {
	type    = string
	default = "Standard_B1s"
}
variable "vm_admin_username" {
	type    = string
	default = "portfolioadmin"
}
variable "vm_admin_password" {
	type      = string
	sensitive = true
	default   = null
}
variable "tags" {
	type    = map(string)
	default = {}
}