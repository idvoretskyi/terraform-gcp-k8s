# Cluster Information
output "cluster_name" {
  description = "GKE Cluster Name"
  value       = module.gke_cluster.name
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = module.gke_cluster.endpoint
}

output "cluster_location" {
  description = "GKE Cluster Location"
  value       = module.gke_cluster.location
}

output "cluster_id" {
  description = "GKE Cluster ID"
  value       = module.gke_cluster.id
}

output "kubernetes_version" {
  description = "Kubernetes version deployed"
  value       = module.gke_cluster.master_version
}

# Access Commands
output "get_credentials_command" {
  description = "Command to get credentials for kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke_cluster.name} --location ${module.gke_cluster.location} --project ${local.project_id}"
}

output "pdb_creation_command" {
  description = "Command to create a basic PodDisruptionBudget"
  value       = <<-EOT
    # Run after connecting to the cluster with the command above
    kubectl apply -f - <<EOF
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: system-components-pdb
      namespace: kube-system
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          k8s-app: kube-dns
    EOF
    EOT
}

# Project Information
output "project_id" {
  description = "The GCP project ID being used"
  value       = local.project_id
}

output "project_source" {
  description = "Source of the project ID (user-specified or gcloud config)"
  value       = var.project_id != null ? "user-specified" : "gcloud-config"
}

# Monitoring Information (conditional)
output "grafana_url" {
  description = "URL for Grafana dashboard (if monitoring is enabled)"
  value       = var.enable_monitoring ? (
    var.grafana_expose_lb ? "http://${module.monitoring[0].grafana_lb_ip}" : 
    "Run: kubectl port-forward svc/grafana 3000:80 -n ${module.monitoring[0].monitoring_namespace}"
  ) : "Monitoring is disabled"
}
