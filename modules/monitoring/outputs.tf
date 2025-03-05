output "prometheus_server_endpoint" {
  description = "Prometheus server endpoint within the cluster"
  value       = "http://prometheus-server.${var.namespace}.svc.cluster.local"
}

output "grafana_endpoint" {
  description = "Grafana endpoint within the cluster"
  value       = "http://grafana.${var.namespace}.svc.cluster.local"
}

output "grafana_lb_ip" {
  description = "External IP of the Grafana LoadBalancer (if enabled)"
  value       = var.grafana_expose_lb ? kubernetes_service.grafana_lb[0].status[0].load_balancer[0].ingress[0].ip : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "monitoring_namespace" {
  description = "Kubernetes namespace used for monitoring"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}
