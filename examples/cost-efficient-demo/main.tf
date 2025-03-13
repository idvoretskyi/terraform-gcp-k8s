terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.68.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Use either provided project_id or get from gcloud config
data "external" "gcloud_project" {
  program = ["bash", "-c", <<EOF
    set -e
    PROJECT=$(gcloud config get-value project --format="value" 2>/dev/null || echo "")
    echo "{\"project\": \"$PROJECT\"}"
EOF
  ]
}

locals {
  project_id = var.project_id != null ? var.project_id : data.external.gcloud_project.result.project
}

provider "google" {
  project = local.project_id
}

module "demo_gke_cluster" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  version                    = "~> 25.0"
  
  # Project settings
  project_id                 = local.project_id
  name                       = var.cluster_name
  regional                   = false
  zones                      = [var.zone]
  
  # Network settings (using default for simplicity)
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  
  # Cluster settings - minimal control plane
  kubernetes_version         = "latest"
  release_channel            = "REGULAR"  # More stable for demos
  create_service_account     = true
  remove_default_node_pool   = true
  initial_node_count         = 1
  
  # Cost-saving configurations
  maintenance_start_time     = "03:00"  # Maintenance during off-hours
  
  # ARM-based preemptible node pool - cost efficient
  node_pools = [
    {
      name                   = "arm-demo-pool"
      machine_type           = "t2a-standard-1"  # ARM-based machines (cheaper)
      min_count              = 0                 # Scale to zero when not in use
      max_count              = 3                 # Maximum 3 nodes as requested
      initial_node_count     = 3                 # Start with 3 nodes
      disk_size_gb           = 50                # Smaller disk to save costs
      disk_type              = "pd-standard"     # Standard disk is cheaper
      image_type             = "COS_CONTAINERD"
      auto_repair            = true
      auto_upgrade           = true
      preemptible            = true              # Preemptible VMs for ~70% discount
      spot                   = false             # Use either preemptible or spot
      
      # Labels for organizing resources
      node_labels = {
        "env"               = "demo"
        "arm-architecture"  = "true"
      }
      
      # Efficient resource utilization  
      node_locations        = var.zone
      enable_gcfs          = false   # Disable GCFS to save resources
      enable_secure_boot   = false   # Disable for demo to save resources
    }
  ]
  
  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Get credentials for kubectl configuration
data "google_client_config" "default" {}

# Output useful connection information
output "connect_command" {
  value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${local.project_id}"
}

output "cluster_info" {
  value = "Demo GKE cluster with 3 preemptible ARM nodes created. To connect, run the command above."
}
