# Debugging Notes for Node Pool Issues

## Issue Description

Received error when creating the node pool:

```
Error: googleapi: Error 400: At least one of ['node_version', 'image_type', ...] must be specified.
```

## Resolution Steps

1. Created a test node pool with minimal configuration
   - Kept only the most essential attributes: `machine_type`, `disk_type`, `disk_size_gb`
   - Ensured `initial_node_count` was explicitly set

2. Found that simplifying the node_config resolved the issue
   - Removed complex configuration like kubelet_config which might be causing issues
   - Used only basic oauth_scopes

3. Possible root causes:
   - Provider version may have specific requirements for node_config
   - Some attribute combinations might be incompatible
   - The structure of nested blocks may need to be simplified

## Working Configuration

The working minimal node pool configuration:

```hcl
resource "google_container_node_pool" "arm_nodes" {
  name             = "arm-pool"
  location         = var.location
  cluster          = google_container_cluster.primary.id
  initial_node_count = 1
  
  node_config {
    machine_type = "t2a-standard-1"
    disk_size_gb = 100
    disk_type    = "pd-standard"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
```

Once basic configuration is working, you can gradually add more complex settings to identify problematic attributes.

## References

- [Google Container Node Pool Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool)
- [Node Config Block Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_node_config)
