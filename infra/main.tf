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

resource "google_compute_firewall" "cks-internal" {
  name    = "cks-allow-local"
  network = google_compute_network.cks_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

resource "google_compute_firewall" "cks-source" {
  name    = "cks-allow-ssh-from-source"
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

resource "google_compute_instance" "control-plane" {
  depends_on = [
    google_runtimeconfig_config.k8s-config
  ]
  name         = "control-plane"
  machine_type = var.machine_type
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
      kubernetes_minor_version = var.kubernetes_minor_version,
      kubernetes_community_ami_version = var.kubernetes_community_ami_version,
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

resource "google_compute_instance" "worker" {  
  depends_on = [
    google_runtimeconfig_config.k8s-config
  ]
  for_each     = var.workers
  name         = each.value.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "family/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.cluster.id
    network_ip = each.value.ip

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    node-type = "worker"
#    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup-worker.tftpl", { 
      kubernetes_minor_version = var.kubernetes_minor_version,
      kubernetes_community_ami_version = var.kubernetes_community_ami_version,
      hostname = each.value.name,  
      user = var.user,
      private_key = file("${path.module}/key/cluster"),
      public_key = file("${path.module}/key/cluster.pub")
    })

  service_account {
    email  = google_service_account.k8s.email
    scopes = ["cloud-platform"]
  }
}