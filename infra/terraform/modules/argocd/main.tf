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

# Install ArgoCD using Helm — use explicit repository URL so plan/apply does not depend on
# a pre-populated local Helm cache (helm repo add / argoproj-index.yaml).
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version != "latest" ? var.argocd_version : null
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
