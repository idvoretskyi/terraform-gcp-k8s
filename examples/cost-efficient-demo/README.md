# Cost-Efficient GKE Demo Cluster

This example creates a minimal, cost-efficient GKE cluster ideal for demonstration purposes. It uses ARM-based T2A instances with preemptible VMs for maximum cost savings.

## Cost-Saving Features

* **ARM-based T2A instances** - Up to 40% cheaper than equivalent x86 instances
* **Preemptible VMs** - ~70% discount compared to standard VMs
* **Autoscaling to zero** - Scales down completely when not in use
* **Minimal disk size** - Uses only 50GB of storage per node
* **Standard storage** - Uses pd-standard instead of more expensive SSD storage
* **Single zone deployment** - No redundancy costs for a demo environment
* **Minimal control plane** - Uses regular release channel for stability

## Quick Start

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Deploy the cluster:
   ```bash
   # Uses your currently configured gcloud project
   terraform apply
   
   # Or specify a project
   terraform apply -var="project_id=YOUR_PROJECT_ID"
   ```

3. Connect to your cluster:
   ```bash
   # Use the command from the terraform output
   terraform output -raw connect_command | bash
   ```

## Preemptible Nodes and ARM Architecture

This configuration uses preemptible VMs which have two important characteristics:

1. **24-hour maximum lifetime** - VMs will be terminated after 24 hours
2. **Can be reclaimed at any time** - VMs may be terminated if GCP needs capacity

It also uses ARM-based T2A instances, which require:
- Container images with ARM64/aarch64 support
- Proper tolerations for the ARM architecture

For details on running workloads on ARM nodes, see [ARM-COMPATIBILITY.md](../../docs/ARM-COMPATIBILITY.md).

## Cost Estimates

| Component | Approximate Monthly Cost |
|-----------|--------------------------|
| GKE Control Plane | ~$70 |
| 3× t2a-standard-1 preemptible VMs | ~$40 |
| Storage (50GB per node) | ~$7 |
| **Total** | **~$117/month** |

**Note:** Actual costs may vary. If you scale to zero nodes during periods of inactivity, you can reduce costs to just the control plane (~$70/month).

## Cleaning Up

To avoid continued charges, delete the cluster when not in use:

```bash
terraform destroy
```
