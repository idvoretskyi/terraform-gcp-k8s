# Get the currently configured gcloud project
data "external" "gcloud_project" {
  program = ["bash", "-c", <<EOF
    set -e
    PROJECT=$(gcloud config get-value project --format="value" 2>/dev/null || echo "")
    echo "{\"project\": \"$PROJECT\"}"
EOF
  ]
}

# Get additional information about the current GCP configuration
data "google_client_config" "current" {}
