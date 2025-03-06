# GKE Autoscaler Troubleshooting Guide

This guide helps diagnose and fix common issues with GKE node autoscaling, particularly when nodes are not scaling up to accommodate pending pods.

## Common Autoscaling Issue: Cannot Meet Pod Requirements

If you see an error message like:
```
Cannot scale up managed instance group as it does not meet the predicate requirements of the pending Pods
```

This typically means that the autoscaler can't find a node configuration that satisfies all the requirements of the pending pods.

## Step 1: Diagnose Specific Issues

Run the included diagnostic script to gather information:

```bash
./scripts/diagnose-autoscaler.sh
```

The script checks for:
- Pending pods and their scheduling errors
- Pod resource requests
- Node selectors and affinity rules
- Node pool configuration
- Autoscaler events and logs

## Step 2: Check for Common Problems

### Architecture Mismatch

Since this cluster uses ARM-based nodes (`t2a-standard-1`), pods must be compatible with ARM architecture.

**Problem:** Pods requesting `amd64` architecture won't schedule on ARM nodes.

**Solution:** Ensure your container images support ARM64, or use node selectors to target ARM nodes:

```yaml
nodeSelector:
  kubernetes.io/arch: arm64
```

### Resource Requests Too Large

**Problem:** Pods requesting more resources (CPU/memory) than a single node can provide.

**Solution:**
- Reduce resource requests to fit within node capacity
- Use a larger machine type (e.g., `t2a-standard-2` or higher)

### Node Selectors/Affinity Not Matching

**Problem:** Pods have node selectors or affinity rules that don't match available nodes.

**Solution:** Check pod specifications and ensure node pools have the required labels:
```bash
kubectl get nodes --show-labels
```

### Insufficient Quotas

**Problem:** GCP resource quotas preventing new nodes from being created.

**Solution:** Check quota usage and request increases if needed:
```bash
gcloud compute project-info describe --project YOUR_PROJECT_ID
```

## Step 3: Update Node Pool Configuration

If needed, update the node pool configuration in Terraform:

```hcl
resource "google_container_node_pool" "arm_nodes" {
  # ...
  node_config {
    # Update machine type if needed
    machine_type = "t2a-standard-2"
    
    # Add appropriate labels
    labels = {
      "kubernetes.io/arch" = "arm64"
      # Other labels...
    }
  }
}
```

## Step 4: Additional Diagnostic Commands

### Check Why Pods Aren't Scheduling

```bash
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Events:
```

### Check Autoscaler Logs

```bash
kubectl logs -n kube-system -l k8s-app=cluster-autoscaler
```

### Check Node Utilization

```bash
kubectl top nodes
```

### Check Pod Resource Requests

```bash
kubectl get pod <pod-name> -o json | jq '.spec.containers[].resources'
```

## References

- [GKE Cluster Autoscaler Documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler)
- [Kubernetes Pod Scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [ARM64 Compatibility in Kubernetes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#arm64)
