# This is a test file to debug the node pool issue
# Remove this file after the issue is resolved

resource "google_container_node_pool" "test_arm_nodes" {
  name       = "test-arm-pool"
  location   = var.location
  cluster    = google_container_cluster.primary.id
  
  # Explicitly set initial_node_count
  initial_node_count = 1
  
  node_config {
    machine_type = "t2a-standard-1"
    disk_size_gb = 100
    disk_type    = "pd-standard"
    
    # Keep it minimal for troubleshooting
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
