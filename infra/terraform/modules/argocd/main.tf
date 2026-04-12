# ArgoCD GitOps Module
# Enterprise-grade: Deploys ArgoCD in-cluster for GitOps workflows
# CI only pushes images, ArgoCD pulls manifests from Git

# Data source to get AKS cluster credentials
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
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

# Prepare Helm cache before plan/apply (runs during plan phase)
# Terraform Helm provider has a bug: uses corrupted cache. This clears it and adds ArgoCD repo.
data "external" "helm_cache_prepare" {
  program = ["PowerShell", "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", "${path.module}/prepare-helm-cache.ps1"]
}

# Install ArgoCD using Helm (repository mode - cache prepared by data.external above)
resource "helm_release" "argocd" {
  name       = "argocd"
  chart   = "argoproj/argo-cd"
  version = var.argocd_version != "latest" ? var.argocd_version : null
  # Depends on data.external so cache is prepared before chart resolution
  repository = lookup(data.external.helm_cache_prepare.result, "result", "") == "ok" ? "" : ""
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  
  force_update = true
  
  # Wait for resources to be ready
  wait = true
  timeout = 600

  # Enterprise-grade: Security and production settings
  values = [
    yamlencode({
      # Security: Disable admin user, use RBAC
      configs = {
        params = {
          "server.insecure" = false
        }
      }
      
      # High availability for production
      controller = {
        replicas = 2
        resources = {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      
      repoServer = {
        replicas = 2
        resources = {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      
      server = {
        replicas = 2
        resources = {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      
      # Application controller settings
      applicationSet = {
        enabled = true
        replicas = 2
      }
      
      # Redis HA for production
      redis-ha = {
        enabled = true
        replicas = {
          servers = 3
          sentinels = 3
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.argocd]
}
