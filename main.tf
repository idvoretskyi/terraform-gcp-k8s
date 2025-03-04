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
  name     = var.cluster_name
  location = var.zone
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"

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

resource "google_container_node_pool" "preemptible_nodes" {
  name       = "${var.cluster_name}-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  
  # Replace node_count with autoscaling block
  autoscaling {
    min_node_count = 0  # Allow scaling down to 0 when idle
    max_node_count = 3  # Maximum of 3 nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"  # Changed from f1-micro to e2-medium

    # Google recommends custom service accounts with minimal permissions
    service_account = var.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
