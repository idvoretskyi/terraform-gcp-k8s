output "kubernetes_endpoint" {
  description = "The cluster endpoint"
  sensitive   = true
  value       = module.gke.endpoint
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "location" {
  description = "Cluster location"
  value       = module.gke.location
}

output "get_credentials_command" {
  description = "Command to get the cluster credentials"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id}"
}
