# ARM-based GKE Terraform Configuration

This repository contains Terraform configurations for setting up a cost-efficient Google Kubernetes Engine (GKE) cluster using ARM-based instances.

## Key Features

* Uses ARM-based Tau T2A instances (t2a-standard-1) for optimal price/performance
* Located in US East region for cost efficiency
* Includes autoscaling configuration from 0-3 nodes
* Configured with Pod Disruption Budgets for reliable scaling

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

5.  Once the cluster is created, you can retrieve the cluster name and endpoint from the Terraform outputs.

## ARM-based Instances

This configuration uses the T2A ARM-based instances which offer several advantages:

* **Cost efficiency**: Save up to 40% compared to x86 instances of similar size
* **Better performance per dollar**: Excellent for containerized workloads
* **Reduced carbon footprint**: ARM processors typically have better power efficiency

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

## Destroy

To destroy the cluster, run:

```bash
terraform destroy
```
## Notes
*   Preemptible nodes are significantly cheaper than regular nodes but can be terminated by GCP at any time.
*   Ensure that your workloads can tolerate interruptions when using preemptible nodes.
*   For production workloads, consider using a mix of preemptible and regular nodes.
## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
## Author
*   [Ihor Dvoretskyi](https://github.com/idvoretskyi)