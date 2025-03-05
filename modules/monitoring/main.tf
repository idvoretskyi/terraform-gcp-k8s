resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# Deploy Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.prometheus_chart_version

  set {
    name  = "server.persistentVolume.size"
    value = var.prometheus_storage_size
  }

  set {
    name  = "server.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/arch"
    value = "arm64"
    type  = "string"
  }

  values = [
    var.prometheus_additional_values
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Deploy Grafana using Helm
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.grafana_chart_version

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/arch"
    value = "arm64"
    type  = "string"
  }

  # Default Prometheus data source configuration
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = 1
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.${var.namespace}.svc.cluster.local"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = true
  }

  values = [
    var.grafana_additional_values
  ]

  depends_on = [helm_release.prometheus]
}

# Create a LoadBalancer service for Grafana if enabled
resource "kubernetes_service" "grafana_lb" {
  count = var.grafana_expose_lb ? 1 : 0
  
  metadata {
    name      = "grafana-lb"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
      "app.kubernetes.io/instance" = "grafana"
    }
    
    port {
      port        = 80
      target_port = 3000
    }
    
    type = "LoadBalancer"
  }
  
  depends_on = [helm_release.grafana]
}
