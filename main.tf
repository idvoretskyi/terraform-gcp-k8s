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
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Other cluster settings
  networking_mode = "VPC_NATIVE"
  
  # Use RAPID release channel for latest Kubernetes versions
  release_channel {
    channel = "RAPID"
  }
  
  # Set minimum Kubernetes version to latest available
  min_master_version = "latest"
}

# Use a single node pool with ARM instances
resource "google_container_node_pool" "arm_nodes" {
  name       = "${var.cluster_name}-arm-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.location
  
  # Autoscaling configuration
  autoscaling {
    min_node_count = 0  # Allow scaling down to 0 when idle
    max_node_count = var.node_count
    location_policy = "BALANCED"
  }
  
  # Management configuration for auto-repair and auto-upgrade
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    # Use ARM-based T2A instance
    machine_type = "t2a-standard-1"
    
    # Configure preemptible VMs for cost savings
    preemptible  = true
    
    # Add disk configurations
    disk_size_gb = 100
    disk_type    = "pd-standard"
    
    # Use Containerd runtime
    image_type   = "COS_CONTAINERD"
    
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
