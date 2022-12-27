terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.47.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.47.0"
    }
  }
}

provider "google" {
}

provider "google-beta" {
}

data "google_project" "project" {
}

resource "google_project_service" "runtimeconfig" {
  service = "runtimeconfig.googleapis.com"
}

resource "google_compute_network" "cks_network" {
  name = "cks-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cluster" {
  name          = "cluster-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.cks_network.id
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.cks_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080"]
  }

  source_ranges = ["${var.your_ip}/32"]
}

resource "google_compute_network" "default" {
  name = "test-network"
}

resource "google_service_account" "k8s" {
  account_id   = "k8s-sa"
  display_name = "Kubernetes Service Account"
}

resource "google_project_iam_member" "project" {
  project = data.google_project.project.number
  role    = "roles/editor"
  member  = google_service_account.k8s.member
}

resource "google_runtimeconfig_config" "k8s-config" {
  provider    = google-beta
  depends_on = [
    google_project_service.runtimeconfig
  ]
  name        = "k8s-config"
  description = "Runtime configuration values for k8s initialization"
}

resource "google_runtimeconfig_variable" "join-command" {
  provider = google-beta
  parent   = google_runtimeconfig_config.k8s-config.name
  name     = "join-command"
  text     = "waiting"
}

resource "google_compute_instance" "control-plane" {
  name         = "control-plane"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "family/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.cluster.id
    network_ip = "10.0.0.100"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    node-type = "control-plane"
#    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup-control-plane.tftpl", { 
      kubernetes_minor_version = "1.24",
      kubernetes_community_ami_version = "1.24.3",
      hostname = "control-plane",  
      user = var.user,
      private_key = file("${path.module}/key/cluster"),
      public_key = file("${path.module}/key/cluster.pub")
    })

  service_account {
    email  = google_service_account.k8s.email
    scopes = ["cloud-platform"]
  }
}