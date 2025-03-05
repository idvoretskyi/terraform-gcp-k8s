output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "get_credentials_command" {
  description = "Command to get credentials for kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
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

output "project_id" {
  description = "The GCP project ID being used"
  value       = local.project_id
}

output "project_source" {
  description = "Source of the project ID (user-specified or gcloud config)"
  value       = var.project_id != null ? "user-specified" : "gcloud-config"
}
