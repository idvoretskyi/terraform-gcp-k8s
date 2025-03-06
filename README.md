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

## Architecture Changes

We now use the [terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest) module maintained by Google. This provides several advantages:

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

For a detailed guide on ARM64 compatibility, see [ARM-COMPATIBILITY.md](./docs/ARM-COMPATIBILITY.md).

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
