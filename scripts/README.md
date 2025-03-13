# Diagnostic Scripts for GKE Clusters

This directory contains scripts to help diagnose and troubleshoot issues with your GKE cluster.

## Available Scripts

### diagnose-autoscaler.sh

Helps identify issues with the cluster autoscaler, especially when nodes aren't scaling up properly to accommodate pending pods.

Usage:
```bash
./diagnose-autoscaler.sh
```

Requirements:
- kubectl configured to access your GKE cluster
- jq installed for JSON processing

### diagnose-webhooks.sh

Helps identify issues with admission webhooks in the cluster, particularly when webhook endpoints are not available.

Usage:
```bash
./diagnose-webhooks.sh
```

Requirements:
- kubectl configured to access your GKE cluster
- jq installed for JSON processing

## Making Scripts Executable

If the scripts aren't executable, run:
```bash
chmod +x *.sh
```
