# ARM-based GKE Terraform Configuration

This repository contains Terraform configurations for setting up a cost-efficient Google Kubernetes Engine (GKE) cluster using ARM-based instances.

## Key Features

* Uses ARM-based Tau T2A instances (t2a-standard-1) for optimal price/performance
* Located in us-central1 region where T2A instances are available
* Includes autoscaling configuration from 0 to 3 nodes (configurable)
* Uses a single, simplified ARM-based node pool
* Uses the latest available Kubernetes version via RAPID release channel
* Properly configured for VPC-native networking

## Prerequisites

*   Google Cloud Platform (GCP) account
*   Terraform installed
*   GCP project ID

## Usage

1.  Clone this repository.
2.  Initialize Terraform:

    ```bash
    terraform init
    ```
3.  Set the `project_id` variable in `terraform.tfvars` or pass it via the command line:

    ```bash
    terraform apply -var="project_id=YOUR_PROJECT_ID"
    ```

4.  Apply the Terraform configuration:

    ```bash
    terraform apply
    ```

5.  Once the cluster is created, connect to it using the command provided in the outputs:
    ```bash
    gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID
    ```

6.  Apply recommended Pod Disruption Budgets for critical components:
    ```bash
    # The exact command will be shown in the Terraform outputs
    kubectl apply -f pdb.yaml
    ```

## Kubernetes Version Management

This configuration ensures you're always using the latest Kubernetes version available on GKE by:

1. Setting the `min_master_version` to "latest"
2. Using the "RAPID" release channel

The RAPID release channel provides access to the newest stable Kubernetes versions as soon as they're available on GKE. This ensures you can leverage the latest features, security updates, and bug fixes.

If you prefer more stability over having the latest features:

- Change to the "REGULAR" release channel for a balance of new features and stability
- Change to the "STABLE" release channel for maximum stability (but older versions)
- Specify a concrete version like `min_master_version = "1.27"` instead of "latest"

Example configuration:
```hcl
resource "google_container_cluster" "primary" {
  # ...other settings...
  
  # For stability (alternatives to our default "RAPID" setting)
  release_channel {
    channel = "REGULAR"  # or "STABLE" for even more stability
  }
  
  # Specific version instead of latest
  min_master_version = "1.27"  # Replace with desired version
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

If you encounter the "machine type not found" error, you need to modify the region/zone in your Terraform configuration to use one of the supported locations.

### Application Compatibility

When using ARM-based instances, ensure your container images support the ARM64 architecture:

* Use multi-architecture images when available
* Set node affinity rules for workloads that require specific architectures
* Test your applications thoroughly on ARM architecture

Example node selector for ARM-compatible workloads:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: arm-compatible-pod
spec:
  containers:
  - name: your-container
    image: your-arm64-image
  nodeSelector:
    kubernetes.io/arch: arm64
```

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

### Troubleshooting Scale-Down Issues

If you notice nodes not scaling down despite low utilization:

1. Check if pods are blocking eviction:
   ```
   kubectl get pods --all-namespaces -o wide | grep <node-name>
   ```

2. Verify existing PDBs:
   ```
   kubectl get pdb --all-namespaces
   ```

3. Look for eviction messages:
   ```
   kubectl describe node <node-name> | grep -A10 Events:
   ```

## Troubleshooting

### Machine Type Not Found Error

If you encounter an error like:
```
Error: error creating NodePool: googleapi: Error 400: Invalid machine type t2a-standard-1 in zone [zone]: resource not found
```

This means the T2A ARM-based instances are not available in your selected region/zone. To fix this:

1. Modify your Terraform configuration to use a region that supports T2A instances:

```hcl
resource "google_container_cluster" "primary" {
  name     = "arm-cluster"
  location = "us-central1"  # Change to a T2A-supported region
  # ...other configuration...
}
```

2. Check the latest documentation for [Tau T2A VM availability](https://cloud.google.com/compute/docs/regions-zones#available) to ensure you're using a supported region.

## Customization

The cluster can be customized by modifying the variables in `terraform.tfvars`:

```hcl
project_id   = "your-gcp-project-id"
cluster_name = "arm-cluster"
location     = "us-central1-a"
node_count   = 5  # Adjust maximum node count as needed
environment  = "production"
```

## Destroy

To destroy the cluster, run:

```bash
terraform destroy
```

## Network Configuration

This cluster uses VPC-native networking (alias IP) which provides:
- Better network performance
- Native integration with Google Cloud load balancers
- Support for larger pod density per node

The configuration automatically assigns IP ranges for pods and services using GKE's automatic IP allocation feature.

## Optional Monitoring with Prometheus and Grafana

This repository includes an optional monitoring module that deploys Prometheus and Grafana on your ARM-based GKE cluster.

### Enabling Monitoring

To enable monitoring, add the following to your Terraform configuration:

```hcl
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

module "monitoring" {
  source = "./modules/monitoring"
  
  # Optional customizations
  namespace              = "monitoring"
  grafana_admin_password = var.grafana_password
  grafana_expose_lb      = true
}
```

### Monitoring Features

* **Prometheus**: Collects and stores metrics from your Kubernetes cluster
* **Grafana**: Provides visualization and dashboards for the collected metrics
* **ARM-optimized**: Configured to work with ARM64 architecture
* **Persistence**: Both Prometheus and Grafana have persistent storage

### Accessing Grafana

If you enable the LoadBalancer (`grafana_expose_lb = true`), you can access Grafana at the external IP shown in the Terraform outputs:

```bash
terraform output -module=monitoring grafana_lb_ip
```

Login using:
* Username: admin
* Password: The value of `grafana_admin_password` (default: "admin")

For more details, see the [monitoring module documentation](./modules/monitoring/README.md).

## Notes
*   Preemptible nodes are significantly cheaper than regular nodes but can be terminated by GCP at any time.
*   Ensure that your workloads can tolerate interruptions when using preemptible nodes.
*   For production workloads, consider using a mix of preemptible and regular nodes.
## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
## Author
*   [Ihor Dvoretskyi](https://github.com/idvoretskyi)