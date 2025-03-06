# GKE Cluster Using Official GKE Module

This example demonstrates creating an ARM-based GKE cluster using the official Google-maintained Terraform GKE module.

## Why Use This Module?

The official GKE module:

1. Is maintained by Google
2. Handles all the complexities of GKE cluster creation
3. Follows Google best practices
4. Often resolves issues with direct resource creation

## Usage

```bash
# Initialize Terraform
terraform init

# Apply the configuration
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

## Features

- ARM-based GKE cluster using T2A instances
- Auto-scaling from 0 to 3 nodes (configurable)
- Located in us-central1-a (configurable)
- RAPID release channel for latest Kubernetes versions
- Preemptible nodes for cost efficiency

## Next Steps After Creating the Cluster

1. Connect to the cluster:
   ```bash
   $(terraform output -raw get_credentials_command)
   ```

2. Deploy workloads with ARM64 support:
   - Use container images with ARM64 support
   - Add architecture tolerations
   - See the ARM-COMPATIBILITY.md guide for details
