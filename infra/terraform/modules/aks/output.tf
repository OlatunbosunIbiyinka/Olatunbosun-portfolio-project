output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = azurerm_kubernetes_cluster.aks.kubernetes_version
}
