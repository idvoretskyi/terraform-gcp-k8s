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

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  version                    = "~> 25.0"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = [var.zone]
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  create_service_account     = true
  remove_default_node_pool   = true
  initial_node_count         = 1
  release_channel            = "RAPID"
  
  node_pools = [
    {
      name               = "arm-pool"
      machine_type       = "t2a-standard-1"
      min_count          = 0
      max_count          = var.node_count
      local_ssd_count    = 0
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = true
    }
  ]
}
