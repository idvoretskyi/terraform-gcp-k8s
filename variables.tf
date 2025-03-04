variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "arm-cluster"
}

variable "location" {
  description = "The region/zone for the GKE cluster"
  type        = string
  default     = "us-central1-a"  # Default to a zone where T2A instances are available
}

variable "zone" {
  description = "The zone for node pools if different from cluster location"
  type        = string
  default     = ""
}

variable "service_account" {
  description = "Service account for nodes"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment label for the cluster"
  type        = string
  default     = "development"
}

variable "node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}
