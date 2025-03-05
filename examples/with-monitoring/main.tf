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

# Use GCP provider
provider "google" {
  project = var.project_id
}

# Get current GCP authentication for k8s providers
data "google_client_config" "default" {}

# Create the GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  networking_mode = "VPC_NATIVE"
  
  # Required for VPC-native clusters
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }
  
  release_channel {
    channel = "RAPID"
  }
  
  min_master_version = "latest"
}

# ARM-based node pool
resource "google_container_node_pool" "arm_nodes" {
  name       = "${var.cluster_name}-arm-pool"
  cluster    = google_container_cluster.primary.id
  
  autoscaling {
    min_node_count = 0
    max_node_count = var.node_count
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "t2a-standard-1"
    preemptible  = true
    disk_size_gb = 100
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      "architecture" = "arm64"
    }
  }
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

# Add monitoring using our module
module "monitoring" {
  source = "../../modules/monitoring"
  
  # Optional customizations
  namespace              = "monitoring"
  grafana_admin_password = "changeme" # Change this to a secure password
  grafana_expose_lb      = true
  
  # Ensure this module runs after the node pool is created
  depends_on = [google_container_node_pool.arm_nodes]
}
