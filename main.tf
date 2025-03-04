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
    # Adding location policy for better scale down behavior
    location_policy = "BALANCED"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true  # This setting is already in place
    machine_type = "e2-medium"  # Changed from f1-micro to e2-medium
    
    # Add disk configurations
    disk_size_gb = 100
    disk_type    = "pd-standard"

    # Google recommends custom service accounts with minimal permissions
    service_account = var.service_account == "" ? null : var.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Add labels to help with pod affinity/anti-affinity
    labels = {
      "node-pool"   = "${var.cluster_name}-node-pool"
      "environment" = var.environment
    }

    # Add kubelet config to improve pod eviction behavior
    kubelet_config {
      cpu_manager_policy   = "static"
      cpu_cfs_quota        = true
      pod_pids_limit       = 4096
    }
    
    # Kubelet eviction thresholds are managed by GKE default settings
    # or can be configured post-deployment through Kubernetes directly
  }
}

resource "google_container_node_pool" "arm_nodes" {
  name       = "${var.cluster_name}-arm-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  
  autoscaling {
    min_node_count = 0
    max_node_count = 3
    location_policy = "BALANCED"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "t2a-standard-1"  # ARM-based instance type
    
    # Add disk configurations
    disk_size_gb = 100
    disk_type    = "pd-standard"

    # Google recommends custom service accounts with minimal permissions
    service_account = var.service_account == "" ? null : var.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Add labels to help with pod affinity/anti-affinity
    labels = {
      "node-pool"   = "${var.cluster_name}-arm-pool"
      "environment" = var.environment
      "architecture" = "arm64"
    }

    # Add kubelet config to improve pod eviction behavior
    kubelet_config {
      cpu_manager_policy   = "static"
      cpu_cfs_quota        = true
      pod_pids_limit       = 4096
    }
  }
}

# Add a default PDB for system components
resource "kubernetes_pod_disruption_budget" "system_components_pdb" {
  depends_on = [google_container_cluster.primary]
  
  metadata {
    name = "system-components-pdb"
    namespace = "kube-system"
  }
  
  spec {
    selector {
      match_labels = {
        k8s-app = "kube-dns"  # Example for CoreDNS, adapt as needed
      }
    }
    
    # Allow disruption of at most 1 pod at a time (maxUnavailable)
    max_unavailable = "1"
  }
}
