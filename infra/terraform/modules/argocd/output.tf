output "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "Name of the ArgoCD server service"
  value       = "argocd-server"
}

output "argocd_server_service_namespace" {
  description = "Namespace of the ArgoCD server service"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_helm_release_name" {
  description = "Name of the Helm release for ArgoCD"
  value       = helm_release.argocd.name
}

output "argocd_helm_release_version" {
  description = "Version of the ArgoCD Helm chart installed"
  value       = helm_release.argocd.version
}
