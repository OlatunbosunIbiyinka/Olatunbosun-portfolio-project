# ArgoCD GitOps Module
# Enterprise-grade: Deploys ArgoCD in-cluster for GitOps workflows
# CI only pushes images, ArgoCD pulls manifests from Git

locals {
  # Bootstrap/dev: single-node clusters cannot schedule HA Argo CD (2x controller/server/repo + redis-ha x3).
  argocd_values = var.high_availability ? {
    configs = {
      params = {
        "server.insecure" = false
      }
    }
    controller = {
      replicas = 2
      resources = {
        limits   = { cpu = "1000m", memory = "1Gi" }
        requests = { cpu = "500m", memory = "512Mi" }
      }
    }
    repoServer = {
      replicas = 2
      resources = {
        limits   = { cpu = "1000m", memory = "1Gi" }
        requests = { cpu = "500m", memory = "512Mi" }
      }
    }
    server = {
      replicas = 2
      resources = {
        limits   = { cpu = "1000m", memory = "1Gi" }
        requests = { cpu = "500m", memory = "512Mi" }
      }
    }
    applicationSet = {
      enabled  = true
      replicas = 2
    }
    redis-ha = {
      enabled  = true
      replicas = 3
    }
    } : {
    configs = {
      params = {
        "server.insecure" = false
      }
    }
    controller = {
      replicas = 1
      resources = {
        limits   = { cpu = "500m", memory = "512Mi" }
        requests = { cpu = "100m", memory = "256Mi" }
      }
    }
    repoServer = {
      replicas = 1
      resources = {
        limits   = { cpu = "500m", memory = "512Mi" }
        requests = { cpu = "100m", memory = "256Mi" }
      }
    }
    server = {
      replicas = 1
      resources = {
        limits   = { cpu = "500m", memory = "512Mi" }
        requests = { cpu = "100m", memory = "256Mi" }
      }
    }
    applicationSet = {
      enabled  = false
      replicas = 1
    }
    redis = {
      enabled = true
    }
    redis-ha = {
      enabled = false
    }
  }
}

# Create ArgoCD namespace
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "argocd"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/component"  = "server"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install ArgoCD using Helm — use explicit repository URL so plan/apply does not depend on
# a pre-populated local Helm cache (helm repo add / argoproj-index.yaml).
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version != "latest" ? var.argocd_version : null
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  force_update = true

  wait    = true
  timeout = var.high_availability ? 600 : 900

  values = [yamlencode(local.argocd_values)]

  depends_on = [kubernetes_namespace_v1.argocd]
}
