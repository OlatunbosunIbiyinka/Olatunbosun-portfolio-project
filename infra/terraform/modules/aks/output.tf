output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}


output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
