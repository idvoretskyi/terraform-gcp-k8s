variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-east1"  # Updated to us-east1 for cost efficiency
}

variable "zone" {
  description = "The GCP zone where the cluster will be created"
  type        = string
  default     = "us-east1-b"  # Updated to us-east1-b
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "arm-gke-cluster"  # Updated to reflect ARM architecture
}

variable "node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}

variable "service_account" {
  description = "The service account to use for the GKE nodes"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment for the cluster (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
