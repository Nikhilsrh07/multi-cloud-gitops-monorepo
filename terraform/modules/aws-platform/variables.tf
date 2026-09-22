variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "enable_nat_gateway" {
	type    = bool
	default = false
}
variable "kubernetes_version" {
	type    = string
	default = "1.30"
}
variable "cluster_endpoint_public_access" {
	type    = bool
	default = false
}
variable "node_instance_types" {
	type    = list(string)
	default = ["t3.small"]
}
variable "node_min_size" {
	type    = number
	default = 1
}
variable "node_max_size" {
	type    = number
	default = 2
}
variable "node_desired_size" {
	type    = number
	default = 1
}
variable "enable_vm" {
	type    = bool
	default = false
}
variable "vm_ami_id" {
	type    = string
	default = ""
}
variable "vm_instance_type" {
	type    = string
	default = "t3.micro"
}
variable "tags" {
	type    = map(string)
	default = {}
}