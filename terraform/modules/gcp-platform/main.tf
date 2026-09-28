# $0 GCP platform: always-free e2-micro running k3s (single-node Kubernetes).
# No GKE node-pool bills; e2-micro + 30GB pd-standard are free-tier eligible.

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

resource "google_compute_firewall" "portfolio" {
  name    = "${local.name}-portfolio-fw"
  network = google_compute_network.platform.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["portfolio"]
}

# Ubuntu image resolved dynamically — no static image names.
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "portfolio" {
  name         = "${local.name}-portfolio"
  machine_type = "e2-micro" # always-free tier (eligible regions)
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30 # free tier: 30 GB pd-standard
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.platform.id
    access_config {
      # Ephemeral public IP ($0 while attached to a running VM)
    }
  }

  # Runs on first boot; image updates via: terraform apply -replace=google_compute_instance.portfolio
  metadata_startup_script = templatefile("${path.module}/templates/portfolio-user-data.sh.tpl", {
    image_repository = var.image_repository
    image_tag        = var.image_tag
  })

  tags   = ["portfolio", "http-server", "https-server"]
  labels = var.labels
}
