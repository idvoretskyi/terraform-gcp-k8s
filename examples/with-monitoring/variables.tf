variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "arm-cluster"
}

variable "location" {
  description = "The location (region or zone) of the cluster"
  type        = string
  default     = "us-central1-a"
}

variable "node_count" {
  description = "The maximum number of nodes in the cluster"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment for the GKE cluster"
  type        = string
  default     = "dev"
}

variable "service_account" {
  description = "The service account to use for the GKE node pool"
  type        = string
  default     = ""
}
