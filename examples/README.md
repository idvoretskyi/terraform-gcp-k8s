# Terraform GCP Kubernetes Examples

This directory contains examples demonstrating different ways to use the ARM-based GKE Terraform configurations.

## Available Examples

### [With Monitoring](./with-monitoring)

This example demonstrates how to:

- Deploy an ARM-based GKE cluster
- Enable the monitoring module for Prometheus and Grafana
- Configure appropriate settings for monitoring stack

To use this example:

```bash
cd with-monitoring
terraform init
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

## Common Usage Patterns

### Setting Required Variables

All examples require at least your GCP project ID:

```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

### Customizing Configurations

Each example can be customized by modifying the corresponding variables:

```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID" \
                -var="cluster_name=custom-name" \
                -var="node_count=5"
```

### Connecting to Your Cluster

After applying any example, connect to your GKE cluster using the provided command:

```bash
# This command is provided in the terraform outputs
gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID
```

## Creating Your Own Examples

To create your own example:

1. Create a new directory under `examples/`
2. Copy the basic structure from an existing example
3. Modify the configuration to showcase your specific use case
4. Include a README.md explaining what your example demonstrates

For a minimal example, include these files:
- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `README.md` - Documentation
