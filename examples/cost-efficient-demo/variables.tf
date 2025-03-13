variable "project_id" {
  description = "GCP Project ID (will use current gcloud config if not specified)"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "arm-demo-cluster"
}

variable "zone" {
  description = "Zone for the GKE cluster (must support T2A ARM instances)"
  type        = string
  default     = "us-central1-a"
}

variable "region" {
  description = "Region derived from zone"
  type        = string
  default     = "us-central1"
}
