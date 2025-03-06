# Project Variables
variable "project_id" {
  description = "The GCP project ID (defaults to currently configured gcloud project if not specified)"
  type        = string
  default     = null
}

# Cluster Configuration
variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "arm-cluster"
}

variable "location" {
  description = "The location (region or zone) for the GKE cluster"
  type        = string
  default     = "us-central1-a"  # Default to a zone where T2A instances are available
}

variable "region" {
  description = "The region for the GKE cluster (derived from location if not specified)"
  type        = string
  default     = ""
}

variable "zone" {
  description = "The zone for node pools (derived from location if not specified)"
  type        = string
  default     = ""
}

# Network Configuration
variable "network" {
  description = "The VPC network to host the cluster"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster"
  type        = string
  default     = "default"
}

variable "ip_range_pods" {
  description = "The secondary IP range for pods"
  type        = string
  default     = ""
}

variable "ip_range_services" {
  description = "The secondary IP range for services"
  type        = string
  default     = ""
}

# Node Pool Configuration
variable "initial_node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 0
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 3
}

variable "preemptible" {
  description = "Whether to use preemptible nodes"
  type        = bool
  default     = true
}

variable "service_account" {
  description = "Service account for nodes (optional)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment label for the cluster"
  type        = string
  default     = "development"
}

# Monitoring Configuration
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
