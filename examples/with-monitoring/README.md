# GKE Cluster with Monitoring Example

This example demonstrates how to deploy an ARM-based GKE cluster with Prometheus and Grafana monitoring enabled.

## Features

* Creates an ARM-based GKE cluster using T2A instances
* Deploys Prometheus for metrics collection
* Deploys Grafana for visualization dashboards
* Exposes Grafana via a LoadBalancer for easy access
* Configures Grafana with Prometheus as a data source

## Usage

### Prerequisites

* Google Cloud SDK installed and configured
* Terraform installed
* A GCP project with necessary APIs enabled
  * Kubernetes Engine API
  * Compute Engine API

### Deployment

1. Initialize Terraform:

```bash
terraform init
```

2. Apply the configuration:

```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

3. Access your cluster:

```bash
# Use the command from the terraform output
terraform output connection_command
```

4. Access Grafana:

```bash
# Get the Grafana URL
terraform output grafana_url
```

Use the following credentials to log in:
- Username: `admin`
- Password: Value of `grafana_admin_password` (default is "changeme")

### Customization

You can customize the deployment by setting variables:

```bash
terraform apply \
  -var="project_id=YOUR_GCP_PROJECT_ID" \
  -var="cluster_name=custom-cluster" \
  -var="node_count=5" \
  -var="location=us-central1-a"
```

## Architecture

This example creates:

1. A GKE cluster with VPC-native networking
2. An ARM-based node pool using T2A instances
3. A monitoring stack with:
   - Prometheus for metrics collection
   - Grafana for metrics visualization
   - LoadBalancer service for accessing Grafana

## Important Notes

* This example deploys to `us-central1-a` by default, which supports ARM-based T2A instances
* The Grafana admin password is set to "changeme" - you should change this for production use
* The monitoring tools are configured to work with ARM architecture
