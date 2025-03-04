variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "GCP zone within the region"
  type        = string
  default     = "us-east4-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "preemptible-gke-cluster"
}

variable "node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}

variable "service_account" {
  description = "Service account to use for GKE node pool"
  type        = string
  default     = ""
}
