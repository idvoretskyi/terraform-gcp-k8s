# ARM-based GKE Terraform Configuration

This repository contains Terraform configurations for setting up a cost-efficient Google Kubernetes Engine (GKE) cluster using ARM-based instances.

## Key Features

* Uses ARM-based Tau T2A instances (t2a-standard-1) for optimal price/performance
* Located in us-central1 region where T2A instances are available
* Includes autoscaling configuration from 0 to 3 nodes (configurable)
* Uses the latest available Kubernetes version via RAPID release channel
* Properly configured for VPC-native networking
* **Now using the official Google-maintained GKE module** for improved reliability and best practices

## Prerequisites

*   Google Cloud Platform (GCP) account
*   Terraform installed (v1.0.0+)
*   GCP project ID (will use your current gcloud project if not specified)

## Usage

1.  Clone this repository.
2.  Initialize Terraform:

    ```bash
    terraform init
    ```

3.  Apply the Terraform configuration:

    ```bash
    # Uses your current gcloud project automatically
    terraform apply
    
    # OR specify a project ID manually
    terraform apply -var="project_id=YOUR_PROJECT_ID"
    ```

    The configuration will automatically use your currently configured gcloud project if you don't specify one.

4.  Once the cluster is created, connect to it using the command provided in the outputs:
    ```bash
    gcloud container clusters get-credentials CLUSTER_NAME --location LOCATION --project PROJECT_ID
    ```

5.  Apply recommended Pod Disruption Budgets for critical components:
    ```bash
    # The exact command will be shown in the Terraform outputs
    kubectl apply -f pdb.yaml
    ```

## Architecture Overview

We use the [terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest) module maintained by Google. This provides several advantages:

* More reliable deployment with industry best practices
* Better handling of complex GKE features
* Proper support for ARM-based node pools
* Regular updates to match GCP's API changes

## Kubernetes Version Management

This configuration ensures you're always using the latest Kubernetes version available on GKE by:

1. Setting the Kubernetes version to "latest"
2. Using the "RAPID" release channel

The RAPID release channel provides access to the newest stable Kubernetes versions as soon as they're available on GKE. This ensures you can leverage the latest features, security updates, and bug fixes.

If you prefer more stability over having the latest features:

- Change to the "REGULAR" release channel for a balance of new features and stability
- Change to the "STABLE" release channel for maximum stability (but older versions)

Example configuration:
```hcl
module "gke_cluster" {
  # ...other settings...
  
  # For stability (alternatives to our default "RAPID" setting)
  release_channel = "REGULAR"  # or "STABLE" for even more stability
}
```

## ARM-based Instances

This configuration uses a single node pool with T2A ARM-based instances which offer several advantages:

* **Cost efficiency**: Save up to 40% compared to x86 instances of similar size
* **Better performance per dollar**: Excellent for containerized workloads
* **Reduced carbon footprint**: ARM processors typically have better power efficiency

### T2A Instance Availability

T2A instances are only available in specific regions/zones. As of the latest update, they are available in:

* us-central1 (zones a, b, f)
* us-south1 (zones a, b, c)
* europe-west4 (zones a, b, c)
* asia-southeast1 (zones a, b, c)

### Application Compatibility

When using ARM-based instances, ensure your container images support the ARM64 architecture:

* Use multi-architecture images when available
* Add appropriate tolerations for ARM architecture
* Test your applications thoroughly on ARM architecture

Example pod configuration with ARM compatibility:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: arm-compatible-pod
spec:
  containers:
  - name: your-container
    image: your-arm64-image
  tolerations:
  - key: "kubernetes.io/arch"
    operator: "Equal"
    value: "arm64"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - arm64
```

For details on ARM64 architecture with GKE, see the [Google documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/arm-on-gke).

## Pod Disruption Budgets

Note: Pod Disruption Budgets should be created AFTER the cluster is running.

### Understanding Scale-Down Blocking

Pod Disruption Budgets (PDBs) are Kubernetes resources that limit the number of pods that can be down simultaneously during voluntary disruptions. When a cluster needs to scale down, it needs to evict pods from nodes being removed. Without proper PDB configurations, pods may block the scale-down process.

### Best Practices for PDBs

1. **Create PDBs for all critical workloads**:
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: app-pdb
   spec:
     minAvailable: 1  # or use maxUnavailable: 1
     selector:
       matchLabels:
         app: your-app
   ```

2. **Set reasonable values**: 
   - For stateless applications, consider using `maxUnavailable: 25%`
   - For stateful applications, use `minAvailable: 1` or higher as needed

3. **Add PDBs to your Helm charts or deployment manifests**:
   Make sure each application deployed has an appropriate PDB defined.

### Creating PDBs Post-Deployment

After deploying your cluster, use the commands provided in the Terraform outputs to:
1. Connect to the cluster
2. Create a default PDB for system components

For your own applications, create PDBs using either:

```bash
# Using kubectl directly
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
  namespace: default
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: your-application
EOF
```

Or using Helm by including PDBs in your application charts.

## Customization

The cluster can be customized by modifying the variables in `terraform.tfvars`:

```hcl
# Required (will use gcloud default project if not specified)
# project_id = "your-gcp-project-id"

# Cluster Configuration
cluster_name = "arm-gke-cluster"
location     = "us-central1-a"  # Must be a region/zone with T2A support
environment  = "staging"

# Node Pool Configuration
initial_node_count = 1
min_node_count     = 0
max_node_count     = 3
preemptible        = true  # Set to false for production workloads

# Monitoring Configuration
enable_monitoring       = true
grafana_admin_password  = "secure-password"  # Change for production
grafana_expose_lb       = false  # Set to true to expose Grafana via LoadBalancer
```

## Optional Monitoring with Prometheus and Grafana

This repository includes an optional monitoring module that deploys Prometheus and Grafana on your ARM-based GKE cluster.

### Enabling/Disabling Monitoring

Monitoring is **enabled by default**. You can control this by setting the `enable_monitoring` variable:

```hcl
# In your terraform.tfvars file:
enable_monitoring = true  # or false to disable
```

You can also disable it from the command line:

```bash
terraform apply -var="enable_monitoring=false"
```

### Monitoring Configuration Options

You can configure the monitoring setup with the following variables:

```hcl
# In your terraform.tfvars file:
grafana_admin_password = "secure-password"  # Default: "admin"
monitoring_namespace   = "monitoring"       # Default: "monitoring" 
grafana_expose_lb      = true              # Default: false
```

### Monitoring Features

* **Prometheus**: Collects and stores metrics from your Kubernetes cluster
* **Grafana**: Provides visualization and dashboards for the collected metrics
* **ARM-optimized**: Configured to work with ARM64 architecture
* **Persistence**: Both Prometheus and Grafana have persistent storage

### Accessing Grafana

If you enable the LoadBalancer (`grafana_expose_lb = true`), you can access Grafana at the external IP shown in the Terraform outputs:

```bash
terraform output grafana_url
```

Login using:
* Username: admin
* Password: The value of `grafana_admin_password` (default: "admin")

For more details, see the [monitoring module documentation](./modules/monitoring/README.md).

## Examples

See the [examples](./examples) directory for additional configurations and use cases:

* [With Monitoring](./examples/with-monitoring) - Example with monitoring enabled
* [Using GKE Module](./examples/using-gke-module) - Example using the Google-maintained GKE module
* [Cost-Efficient Demo](./examples/cost-efficient-demo) - Low-cost setup for demos and testing

## Notes

*   Preemptible nodes are significantly cheaper than regular nodes but can be terminated by GCP at any time.
*   Ensure that your workloads can tolerate interruptions when using preemptible nodes.
*   For production workloads, consider using a mix of preemptible and regular nodes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

*   [Ihor Dvoretskyi](https://github.com/idvoretskyi)
