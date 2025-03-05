terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.68.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
}

provider "google" {
  project = var.project_id
}

# Get current GCP authentication for k8s providers
data "google_client_config" "default" {}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Other cluster settings
  networking_mode = "VPC_NATIVE"
  
  # Required for VPC-native clusters
  ip_allocation_policy {
    # By not specifying ranges, GKE will auto-allocate from the VPC
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }
  
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
  cluster    = google_container_cluster.primary.id
  location   = var.location
  
  # Set initial node count
  initial_node_count = 1
  
  # Autoscaling configuration
  autoscaling {
    min_node_count = 0
    max_node_count = var.node_count
  }
  
  # Management configuration for auto-repair and auto-upgrade
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration is required and must have at least machine_type, disk_size_gb, and disk_type
  node_config {
    machine_type = "t2a-standard-1"
    disk_size_gb = 100
    disk_type    = "pd-standard"
    
    # Optional settings
    preemptible  = true
    image_type   = "COS_CONTAINERD"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      "architecture" = "arm64"
      "environment"  = var.environment
    }
  }
  
  # Ensure the creation happens serially after the cluster
  depends_on = [
    google_container_cluster.primary
  ]
}

# Configure Kubernetes provider to access GKE cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

# Conditionally deploy the monitoring module
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  namespace              = var.monitoring_namespace
  grafana_admin_password = var.grafana_admin_password
  grafana_expose_lb      = var.grafana_expose_lb
  
  depends_on = [
    google_container_node_pool.arm_nodes
  ]
}
