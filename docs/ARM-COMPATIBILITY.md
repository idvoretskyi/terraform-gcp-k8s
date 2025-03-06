# Running Workloads on ARM-based GKE Clusters

This guide explains how to properly configure your workloads to run on ARM-based (arm64) GKE nodes.

## Understanding the Architecture Taint

ARM-based nodes in GKE automatically have the taint:
```
kubernetes.io/arch=arm64:NoSchedule
```

This taint prevents pods that aren't explicitly compatible with ARM architecture from being scheduled on these nodes, which helps prevent application failures.

## Making Your Workloads Compatible

To run workloads on ARM nodes, you need to:

1. Use container images that support ARM64 architecture
2. Add appropriate tolerations to your deployments
3. Verify resource compatibility

### 1. Container Images for ARM64

Ensure your container images support ARM64:

- Use multi-architecture images (support multiple architectures)
- Look for images with `arm64` or `aarch64` variants
- Build your own images with multi-architecture support using Docker buildx

Examples of multi-arch images:
```
nginx:latest             # Official images often support multiple architectures
ubuntu:20.04             # Most base OS images support ARM64
bitnami/nginx:latest     # Bitnami images are typically multi-arch
```

Check image architecture support:
```bash
docker manifest inspect nginx:latest
```

### 2. Adding Tolerations

Add a toleration for ARM architecture to your pod specifications:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      tolerations:
      - key: "kubernetes.io/arch"
        operator: "Equal"
        value: "arm64"
        effect: "NoSchedule"
      containers:
      - name: my-container
        image: my-arm64-compatible-image
```

### 3. Node Affinity (Optional but Recommended)

To ensure your pods only schedule on ARM nodes:

```yaml
spec:
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

## Debugging Architecture Issues

If you see the error:
```
0/1 nodes are available: 1 node(s) had untolerated taint {kubernetes.io/arch: arm64}
```

This means your pod doesn't have the necessary toleration for ARM architecture.

### Checking Node Taints

```bash
kubectl describe nodes | grep -A 5 Taints
```

### Checking Image Compatibility

For an existing container:
```bash
kubectl exec -it my-pod -- uname -m
```

Should return `aarch64` or `arm64` for ARM architecture.

## Common ARM64 Compatibility Issues

1. **JVM applications**: Ensure you're using Java 11+ with ARM64 support
2. **Node.js applications**: Use Node.js 14.x+ which has improved ARM support
3. **Go applications**: Ensure they're compiled for ARM64 with `GOARCH=arm64`
4. **Python applications**: Most are architecture-agnostic, but C extensions may need ARM64 versions

## Tools and Resources

- [Multiarch Image Support](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [ARM64 Developer Resources](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/containers)
