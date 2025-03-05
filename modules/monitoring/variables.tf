variable "namespace" {
  description = "Namespace to install Prometheus and Grafana"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Version of the Prometheus Helm chart"
  type        = string
  default     = "19.7.2"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus server"
  type        = string
  default     = "8Gi"
}

variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "10d"
}

variable "prometheus_additional_values" {
  description = "Additional values to pass to the Prometheus Helm chart"
  type        = string
  default     = ""
}

variable "grafana_chart_version" {
  description = "Version of the Grafana Helm chart"
  type        = string
  default     = "6.52.4"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "2Gi"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_additional_values" {
  description = "Additional values to pass to the Grafana Helm chart"
  type        = string
  default     = ""
}

variable "grafana_expose_lb" {
  description = "Whether to expose Grafana with a LoadBalancer service"
  type        = bool
  default     = false
}
