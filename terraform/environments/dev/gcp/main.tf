module "platform" {
  source = "../../../modules/gcp-platform"

  project_id        = var.project_id
  name_prefix       = var.name_prefix
  environment       = var.environment
  region            = var.region
  zone              = var.zone
  subnet_cidr       = var.subnet_cidr
  node_count        = var.node_count
  node_machine_type = var.node_machine_type
  enable_vm         = var.enable_vm
  vm_machine_type   = var.vm_machine_type
  vm_image          = var.vm_image
  labels            = var.labels
}
