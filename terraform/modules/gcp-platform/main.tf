terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals { name = "${var.name_prefix}-${var.environment}" }

resource "google_compute_network" "platform" {
  name                    = local.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "platform" {
  name          = "${local.name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.platform.id
}

resource "google_service_account" "workload" {
  account_id   = substr(replace("${local.name}-sa", "_", "-"), 0, 30)
  display_name = "${local.name} workload identity"
}

resource "google_project_iam_member" "workload_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_container_cluster" "platform" {
  name                     = local.name
  location                 = var.region
  network                  = google_compute_network.platform.name
  subnetwork               = google_compute_subnetwork.platform.name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  ip_allocation_policy {}
  workload_identity_config { workload_pool = "${var.project_id}.svc.id.goog" }
}

resource "google_container_node_pool" "default" {
  name       = "${local.name}-nodes"
  location   = var.region
  cluster    = google_container_cluster.platform.name
  node_count = var.node_count
  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.workload.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_instance" "portfolio_vm" {
  count        = var.enable_vm ? 1 : 0
  name         = "${local.name}-vm"
  machine_type = var.vm_machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.platform.id
  }
  labels = var.labels
}