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

variable "enable_monitoring" {
  description = "Whether to enable Prometheus and Grafana monitoring"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring tools"
  type        = string
  default     = "monitoring"
}

variable "grafana_expose_lb" {
  description = "Whether to expose Grafana with a LoadBalancer"
  type        = bool
  default     = false
}
