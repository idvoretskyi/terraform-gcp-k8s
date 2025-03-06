variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "arm-gke-module"
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to host the cluster in"
  type        = string
  default     = "us-central1-a"
}

variable "node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
  default     = 3
}
