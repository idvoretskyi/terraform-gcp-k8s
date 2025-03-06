# Troubleshooting Persistent Node Pool Issues

## Current Error

```
Error: googleapi: Error 400: At least one of ['node_version', 'image_type', ...] must be specified.
```

## Troubleshooting Steps

1. **Simplify configuration**: We've reduced the node pool to the most minimal configuration possible with only the essential attributes.

2. **Check for provider version issues**: 
   ```
   terraform providers
   ```
   
   Make sure you're using Google provider 4.x (ideally 4.68.0 or newer).

3. **Try different region/zone**: Some features may not be available in all regions.

4. **Check for GKE API issues**:
   ```
   gcloud container operations list
   ```

5. **Examine API request payload**: 
   ```
   export TF_LOG=DEBUG
   terraform apply
   ```
   
   This will show the exact API request being sent.

6. **Verify project permissions**:
   ```
   gcloud auth list
   gcloud projects get-iam-policy [PROJECT_ID]
   ```

## Alternative Approaches

1. **Use gcloud directly** to create a minimal cluster and export to Terraform:

   ```bash
   gcloud container clusters create test-arm-cluster \
     --zone=us-central1-a \
     --machine-type=t2a-standard-1 \
     --num-nodes=1 \
     --no-enable-autoupgrade
   
   gcloud container clusters describe test-arm-cluster --zone=us-central1-a --format=json
   ```

2. **Try creating cluster and node pool together** instead of removing default node pool:

   ```hcl
   resource "google_container_cluster" "primary" {
     name     = var.cluster_name
     location = var.location
     
     # Don't remove default node pool
     initial_node_count = 1
     
     node_config {
       machine_type = "t2a-standard-1"
       image_type   = "COS_CONTAINERD"
       disk_size_gb = 100
     }
     
     # Other settings...
   }
   ```

3. **Check for service quota limits** that might be preventing node pool creation:
   ```
   gcloud compute project-info describe
   ```

## Common Issues with ARM Node Pools

1. **ARM limitations**: Some features might not be fully supported with ARM nodes
2. **Image compatibility**: Ensure image_type is compatible with ARM architecture
3. **Zone restrictions**: ARM instances are only available in specific zones
4. **Terraform provider issues**: There might be issues with how the provider handles ARM node pools

## Next Steps

If the simplified configuration doesn't work:

1. Try creating the cluster through the GCP Console
2. Import existing resources into Terraform
3. File a bug report with the Terraform Google provider
