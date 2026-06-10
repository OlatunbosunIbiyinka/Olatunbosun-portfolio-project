output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "azure_subscription_id" {
  description = "Subscription ID this stack uses (for argocd-stack / cross-stack alignment)"
  value       = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.acr_login_server
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "workload_identity_client_id" {
  description = "Client ID of the Workload Identity"
  value       = azurerm_user_assigned_identity.workload_identity.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the Workload Identity"
  value       = azurerm_user_assigned_identity.workload_identity.principal_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity"
  value       = module.aks.oidc_issuer_url
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.monitoring[0].id : null
}

output "github_oidc_client_id" {
  description = "Client ID for GitHub Actions OIDC (to be set as GitHub secret: AZURE_CLIENT_ID)"
  value       = var.enable_github_oidc && var.github_repository != "" ? module.github_oidc[0].application_client_id : null
}

output "github_oidc_tenant_id" {
  description = "Tenant ID for GitHub Actions OIDC (to be set as GitHub secret: AZURE_TENANT_ID)"
  value       = var.enable_github_oidc && var.github_repository != "" ? data.azurerm_client_config.current.tenant_id : null
}

output "github_oidc_subscription_id" {
  description = "Subscription ID for GitHub Actions OIDC (to be set as GitHub secret: AZURE_SUBSCRIPTION_ID)"
  value       = var.enable_github_oidc && var.github_repository != "" ? data.azurerm_client_config.current.subscription_id : null
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed (null if enable_argocd=false)."
  value       = var.enable_argocd ? module.argocd[0].argocd_namespace : null
}

output "argocd_server_service_name" {
  description = "Argo CD server Service name (null if enable_argocd=false)."
  value       = var.enable_argocd ? module.argocd[0].argocd_server_service_name : null
}

output "argocd_helm_release_version" {
  description = "Installed Helm chart version (null if enable_argocd=false)."
  value       = var.enable_argocd ? module.argocd[0].argocd_helm_release_version : null
}

# Trusted Execution Zone (Operations VM) Outputs
output "operations_vm_name" {
  description = "Name of the operations VM (Trusted Execution Zone)"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].jumpbox_vm_name : null
}

output "operations_vm_private_ip" {
  description = "Private IP address of the operations VM"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].jumpbox_private_ip : null
}

output "operations_vm_managed_identity_client_id" {
  description = "Managed Identity Client ID for the operations VM"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].operations_vm_managed_identity_client_id : null
}

output "operations_vm_managed_identity_principal_id" {
  description = "Managed Identity Principal ID for the operations VM (for role assignments)"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].operations_vm_managed_identity_principal_id : null
}

output "bastion_name" {
  description = "Name of the Azure Bastion resource"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].bastion_name : null
}

output "jumpbox_password" {
  description = "DEPRECATED: Azure AD login is used instead. This output is kept for backward compatibility."
  value       = null
  sensitive   = true
}

output "operations_vm_connection_instructions" {
  description = "Instructions for connecting to the Trusted Execution Zone VM"
  value       = var.enable_bastion ? module.bastion_jumpbox[0].connection_instructions : null
  sensitive   = true
}

