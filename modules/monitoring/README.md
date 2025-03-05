# Monitoring Module for GKE

This module installs Prometheus and Grafana on your GKE cluster using Helm. It's designed to work with ARM-based clusters.

## Features

- Deploys Prometheus for metrics collection and storage
- Deploys Grafana for dashboards and visualization
- Configures Grafana to use Prometheus as a data source
- Supports persistence for both Prometheus and Grafana
- Optimized for ARM64 architecture
- Optional LoadBalancer exposure for Grafana

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  # Optional customizations
  namespace             = "monitoring"
  grafana_admin_password = "secure-password"
  grafana_expose_lb     = true
}
```

## Requirements

- Kubernetes provider configured to access your cluster
- Helm provider configured
- The GKE cluster should be up and running

## Accessing the dashboards

### Without LoadBalancer (default)

To access Grafana without exposing it via LoadBalancer:

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Then access Grafana at http://localhost:3000

### With LoadBalancer

If you set `grafana_expose_lb = true`, you can access Grafana at the external IP:

```bash
kubectl get svc grafana-lb -n monitoring
```

## Pre-installed dashboards

The Grafana installation comes with several pre-configured dashboards for monitoring:

1. Kubernetes cluster overview
2. Node metrics
3. Pod and container metrics

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| namespace | Namespace to install Prometheus and Grafana | string | "monitoring" |
| prometheus_chart_version | Version of the Prometheus Helm chart | string | "19.7.2" |
| prometheus_storage_size | Storage size for Prometheus server | string | "8Gi" |
| prometheus_retention | Data retention period for Prometheus | string | "10d" |
| prometheus_additional_values | Additional values to pass to the Prometheus Helm chart | string | "" |
| grafana_chart_version | Version of the Grafana Helm chart | string | "6.52.4" |
| grafana_storage_size | Storage size for Grafana | string | "2Gi" |
| grafana_admin_password | Admin password for Grafana | string | "admin" |
| grafana_additional_values | Additional values to pass to the Grafana Helm chart | string | "" |
| grafana_expose_lb | Whether to expose Grafana with a LoadBalancer service | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| prometheus_server_endpoint | Prometheus server endpoint within the cluster |
| grafana_endpoint | Grafana endpoint within the cluster |
| grafana_lb_ip | External IP of the Grafana LoadBalancer (if enabled) |
| grafana_admin_password | Grafana admin password |
| monitoring_namespace | Kubernetes namespace used for monitoring |

## Customization

### Adding custom Grafana dashboards

You can add custom dashboards by setting `grafana_additional_values`:

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  grafana_additional_values = <<EOF
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default
dashboards:
  default:
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
EOF
}
```

### Adding custom Prometheus scrape configurations

You can add custom scrape configurations by setting `prometheus_additional_values`:

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  prometheus_additional_values = <<EOF
server:
  global:
    scrape_interval: 15s
  extraScrapeConfigs: |
    - job_name: 'custom-endpoint'
      static_configs:
      - targets: ['custom-service:8080']
EOF
}
```
