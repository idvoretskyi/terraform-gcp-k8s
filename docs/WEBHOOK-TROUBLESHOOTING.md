# GKE Admission Webhook Troubleshooting Guide

This guide helps diagnose and fix issues with admission webhooks in your GKE cluster, particularly when you see the warning:

```
This cluster has no available endpoints to serve an admission webhook installed on this cluster.
Webhooks with no endpoints can degrade performance and impact availability of the GKE Control Plane.
```

## What are Admission Webhooks?

Admission webhooks are HTTP callbacks that receive admission requests for resources being created/updated/deleted in your cluster. There are two types:

1. **Validating Admission Webhooks**: Can accept or reject requests but cannot modify them
2. **Mutating Admission Webhooks**: Can modify requests before they're persisted

## Why do Webhook Endpoints Matter?

When an admission webhook is registered but has no endpoints:

- The Kubernetes API server still attempts to call the webhook
- This leads to timeouts and retries
- These delays can degrade API server performance
- In extreme cases, it can impact GKE control plane availability

## Diagnosing Webhook Issues

Run the included webhook diagnostic script:

```bash
chmod +x ./scripts/diagnose-webhooks.sh
./scripts/diagnose-webhooks.sh
```

The script checks for:
- All validating and mutating webhooks in your cluster
- Whether their service references exist
- Whether those services have endpoints
- Matching pods and their status

## Common Issues and Solutions

### 1. Architecture Mismatch

**Problem**: Webhook pods don't start because they're not compatible with ARM architecture.

**Solution**:
- Ensure webhook containers are built for ARM64 architecture
- Use multi-arch images where possible
- Add architecture-specific node affinity to deployment manifests

### 2. Missing or Failing Pods

**Problem**: The pods backing the webhook service are not running.

**Solution**:
- Check pod status: `kubectl get pods -n <namespace> -l <selector>`
- View pod logs: `kubectl logs -n <namespace> <pod-name>`
- Check for resource constraints: `kubectl describe pod -n <namespace> <pod-name>`

### 3. Service Selector Issues

**Problem**: The service selector doesn't match any pods.

**Solution**:
- Verify the service selector: `kubectl get svc <service> -n <namespace> -o jsonpath='{.spec.selector}'`
- Ensure pods have matching labels: `kubectl get pods -n <namespace> --show-labels`
- Fix service selector or pod labels as needed

## Solutions

### Option 1: Fix the Webhook Implementation

If you're using the webhook:
1. Ensure its pods are running and healthy
2. Make sure container images are compatible with ARM64
3. Fix any resource constraints or configuration issues

### Option 2: Remove Unused Webhooks

If you're not using the webhook or it was left behind:

```bash
# Delete validating webhook
kubectl delete validatingwebhookconfigurations <name>

# Delete mutating webhook
kubectl delete mutatingwebhookconfigurations <name>
```

### Option 3: Set FailurePolicy to Ignore

If you can't fix or remove the webhook immediately:

```bash
kubectl get validatingwebhookconfigurations <name> -o yaml > webhook.yaml
# Edit webhook.yaml to set failurePolicy: Ignore
kubectl apply -f webhook.yaml
```

## Best Practices for Webhooks in ARM-based GKE

1. **Use multi-arch container images** that support ARM64
2. **Use node affinity instead of node selectors** for architecture compatibility:
   ```yaml
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
   Note: You can use the built-in `kubernetes.io/arch` label in pod specifications, but you can't apply it manually to nodes.
3. **Set reasonable resource requests/limits** to ensure webhook pods are scheduled
4. **Configure appropriate failure policy** for webhooks:
   ```yaml
   failurePolicy: Ignore  # Less disruptive but potentially less secure
   # or
   failurePolicy: Fail    # More secure but can block operations if webhook is down
   ```
5. **Set timeout appropriately**:
   ```yaml
   timeoutSeconds: 5  # Balance between responsiveness and allowing sufficient processing time
   ```

## References

- [Kubernetes Admission Controllers Documentation](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
