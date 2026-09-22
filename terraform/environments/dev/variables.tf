variable "name_prefix" {
	type    = string
	default = "portfolio"
}
variable "environment" {
	type    = string
	default = "dev"
}
variable "enable_aws" {
	type    = bool
	default = false
}
variable "enable_gcp" {
	type    = bool
	default = false
}
variable "enable_azure" {
	type    = bool
	default = false
}
variable "aws_region" {
	type    = string
	default = "us-east-1"
}
variable "gcp_project_id" {
	type    = string
	default = ""
}
variable "gcp_region" {
	type    = string
	default = "us-central1"
}
variable "gcp_zone" {
	type    = string
	default = "us-central1-a"
}
variable "azure_location" {
	type    = string
	default = "East US"
}
variable "aws_vpc_cidr" {
	type    = string
	default = "10.10.0.0/16"
}
variable "aws_availability_zones" {
	type    = list(string)
	default = ["us-east-1a", "us-east-1b"]
}
variable "aws_private_subnets" {
	type    = list(string)
	default = ["10.10.1.0/24", "10.10.2.0/24"]
}
variable "aws_public_subnets" {
	type    = list(string)
	default = ["10.10.101.0/24", "10.10.102.0/24"]
}
variable "enable_nat_gateway" {
	type    = bool
	default = false
}
variable "gcp_subnet_cidr" {
	type    = string
	default = "10.20.0.0/24"
}
variable "azure_vnet_cidr" {
	type    = string
	default = "10.30.0.0/16"
}
variable "azure_aks_subnet_cidr" {
	type    = string
	default = "10.30.1.0/24"
}
variable "enable_aws_vm" {
	type    = bool
	default = false
}
variable "enable_gcp_vm" {
	type    = bool
	default = false
}
variable "enable_azure_vm" {
	type    = bool
	default = false
}
variable "aws_vm_ami_id" {
	type    = string
	default = ""
}
variable "azure_vm_admin_password" {
	type      = string
	sensitive = true
	default   = null
}
variable "tags" {
	type    = map(string)
	default = { app = "portfolio" }
}