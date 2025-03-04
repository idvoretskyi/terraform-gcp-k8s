terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.68.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name     = "preemptible-cluster"
  location = var.zone
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools.  So we create a minimal initial node pool
  # and immediately delete it.
  initial_node_count = 1
  remove_default_node_pool = true

  # Use the most recent Kubernetes version in the RAPID channel
  release_channel {
    channel = "RAPID"
  }

  # https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  network_policy {
    enabled = true
  }
  # Empty ip_allocation_policy block enables VPC-native cluster
  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "preemptible-nodes"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 3

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "f1-micro"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
