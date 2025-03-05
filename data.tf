# Get the currently configured gcloud project
data "external" "gcloud_project" {
  program = ["bash", "-c", "gcloud config get-value project --format=json 2>/dev/null || echo '{\"project\":\"\"}'"]
}

# Get additional information about the current GCP configuration
data "google_client_config" "current" {}
