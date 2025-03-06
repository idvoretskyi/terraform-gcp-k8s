terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.68.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
  required_version = ">= 1.0.0"
}

locals {
  # Use either the explicitly provided project_id or the one from gcloud config
  project_id = var.project_id != null ? var.project_id : data.external.gcloud_project.result.project
  
  # Default region from location if not specified
  region = var.region != "" ? var.region : (
    length(split("-", var.location)) > 2 ? var.location : join("-", slice(split("-", var.location), 0, 2))
  )
  
  # Default zone from location if not specified
  zone = length(split("-", var.location)) > 2 ? var.location : null
}

provider "google" {
  project = local.project_id
}

data "google_client_config" "default" {}

# Use the Google-maintained GKE module instead of direct resources
module "gke_cluster" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  version                    = "~> 25.0"
  
  # Project settings
  project_id                 = local.project_id
  name                       = var.cluster_name
  regional                   = var.zone == null ? true : false
  region                     = local.region
  zones                      = var.zone != null ? [var.zone] : []
  
  # Network settings
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  
  # Cluster settings
  kubernetes_version         = "latest"
  release_channel            = "RAPID"
  create_service_account     = true
  remove_default_node_pool   = true
  initial_node_count         = 1
  
  # ARM-based node pool
  node_pools = [
    {
      name                   = "arm-pool"
      machine_type           = "t2a-standard-1"
      min_count              = var.min_node_count
      max_count              = var.max_node_count
      initial_node_count     = var.initial_node_count
      disk_size_gb           = 100
      disk_type              = "pd-standard"
      image_type             = "COS_CONTAINERD"
      auto_repair            = true
      auto_upgrade           = true
      preemptible            = var.preemptible
      
      # Custom labels to identify ARM nodes
      node_labels = {
        "arm-architecture" = "true"
        "environment"      = var.environment
      }
    }
  ]
}

# Configure Kubernetes provider to access GKE cluster
provider "kubernetes" {
  host                   = "https://${module.gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_cluster.ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = "https://${module.gke_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke_cluster.ca_certificate)
  }
}

# Conditionally deploy the monitoring module
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  namespace              = var.monitoring_namespace
  grafana_admin_password = var.grafana_admin_password
  grafana_expose_lb      = var.grafana_expose_lb
  
  depends_on = [module.gke_cluster]
}
