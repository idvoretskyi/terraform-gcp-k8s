output "kubernetes_cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "kubernetes_cluster_host" {
  description = "GKE Cluster Host"
  value       = google_container_cluster.primary.endpoint
}

output "grafana_url" {
  description = "URL for Grafana dashboard (if LoadBalancer is enabled)"
  value       = module.monitoring.grafana_expose_lb ? "http://${module.monitoring.grafana_lb_ip}" : "Run: kubectl port-forward svc/grafana 3000:80 -n ${module.monitoring.monitoring_namespace}"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "connection_command" {
  description = "Command to configure kubectl to connect to the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
}
