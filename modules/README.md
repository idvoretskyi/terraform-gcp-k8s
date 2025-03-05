# Terraform GCP Kubernetes Modules

This directory contains reusable Terraform modules for GKE cluster configurations. These modules can be used individually or together to create customized Kubernetes deployments on GCP.

## Available Modules

### [Monitoring](./monitoring)

The monitoring module deploys a complete monitoring stack with Prometheus and Grafana:

- Prometheus for collecting and storing metrics
- Grafana for metrics visualization and dashboards
- Pre-configured integration between the two
- Support for ARM64 architecture
- Optional LoadBalancer exposure for Grafana

Example usage:

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  namespace              = "monitoring"
  grafana_admin_password = "secure-password"
  grafana_expose_lb      = true
}
```

## Using These Modules

### Direct Reference

You can directly reference these modules in your Terraform configuration:

```hcl
module "my_monitoring" {
  source = "/path/to/terraform-gcp-k8s/modules/monitoring"
  
  # Variables specific to the module
  namespace = "custom-monitoring"
}
```

### Module Composition

You can create your own modules that combine or extend the functionality of these modules:

```hcl
module "monitoring" {
  source = "/path/to/terraform-gcp-k8s/modules/monitoring"
  
  namespace = var.monitoring_namespace
}

# Add your own resources that depend on the module
resource "kubernetes_namespace" "application" {
  # ...
  
  depends_on = [module.monitoring]
}
```

## Creating New Modules

When creating new modules for this repository, follow these guidelines:

1. Create a new directory under `modules/`
2. Include a README.md with usage instructions
3. Create `main.tf`, `variables.tf`, and `outputs.tf` files
4. Document all variables and outputs
5. Ensure the module is reusable and configurable
6. Add an example to the `examples/` directory
