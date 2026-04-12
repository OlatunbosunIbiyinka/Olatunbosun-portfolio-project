terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Allow resource group deletion even if it contains resources (e.g., ContainerInsights solution)
      # This is safe for dev environments where we want easy cleanup
      # For production, consider setting this to true and manually cleaning up resources first
      prevent_deletion_if_contains_resources = false
    }
  }
  use_oidc = true
}

provider "azuread" {
  use_oidc  = true
  tenant_id = data.azurerm_client_config.current.tenant_id
}

data "azurerm_client_config" "current" {}

# Azure AD Group Data Sources (Production-Grade: Lookup by name instead of hardcoding Object IDs)
# This allows groups to be referenced by name, making configuration more maintainable
data "azuread_group" "aks_cluster_admins" {
  count            = var.enable_azure_rbac && length(var.admin_group_names) > 0 ? length(var.admin_group_names) : 0
  display_name     = var.admin_group_names[count.index]
  security_enabled = true
}

data "azuread_group" "aks_cluster_operators" {
  count            = var.enable_azure_rbac && length(var.operator_group_names) > 0 ? length(var.operator_group_names) : 0
  display_name     = var.operator_group_names[count.index]
  security_enabled = true
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Virtual Network for enterprise-grade network isolation
module "vnet" {
  source = "./modules/vnet"

  vnet_name                                = var.vnet_name != null ? var.vnet_name : "${var.resource_group_name}-vnet"
  location                                 = var.location
  resource_group_name                      = azurerm_resource_group.rg.name
  address_space                            = var.vnet_address_space
  aks_subnet_name                          = var.aks_subnet_name
  aks_subnet_address_prefixes              = var.aks_subnet_address_prefixes
  private_endpoint_subnet_name             = var.private_endpoint_subnet_name
  private_endpoint_subnet_address_prefixes = var.private_endpoint_subnet_address_prefixes
  enable_bastion                           = var.enable_bastion # Enable Bastion for Trusted Execution Zone
  bastion_subnet_address_prefixes         = var.bastion_subnet_address_prefixes
  jumpbox_subnet_name                     = "operations-subnet"
  jumpbox_subnet_address_prefixes        = var.jumpbox_subnet_address_prefixes
  enable_private_dns                       = var.enable_private_dns
  enable_nsg                               = var.enable_nsg
  enable_nat_gateway                       = var.enable_nat_gateway
  nat_gateway_zones                        = var.nat_gateway_zones
  tags                                     = var.tags
}

# Data source for AKS cluster credentials (used by Kubernetes/Helm providers for ArgoCD)
data "azurerm_kubernetes_cluster" "aks_for_argocd" {
  name                = var.aks_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [module.aks]
}

# Kubernetes provider for ArgoCD installation
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_for_argocd.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_for_argocd.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_for_argocd.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_for_argocd.kube_config[0].cluster_ca_certificate)
}

# Helm provider for ArgoCD installation
# Helm provider automatically uses the Kubernetes provider configuration above
# No explicit configuration needed - it will use the kubernetes provider settings

# ArgoCD GitOps Configuration
# Enterprise-grade: GitOps with ArgoCD - cluster manages itself via Git
# CI only pushes images, ArgoCD pulls manifests from Git repository
module "argocd" {
  count  = var.enable_argocd ? 1 : 0
  source = "./modules/argocd"

  aks_cluster_id      = module.aks.cluster_id
  aks_cluster_name    = var.aks_name
  resource_group_name = azurerm_resource_group.rg.name
  namespace          = var.argocd_namespace
  argocd_version     = var.argocd_version
  tags               = var.tags
  
  depends_on = [module.aks]
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "monitoring" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${var.resource_group_name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Azure Container Registry
module "acr" {
  source                        = "./modules/acr"
  acr_name                      = var.acr_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku                           = "Premium" # Enterprise-grade: Premium SKU for advanced features
  admin_enabled                 = false
  enable_private_endpoint       = var.enable_acr_private_endpoint
  private_endpoint_subnet_id    = module.vnet.private_endpoint_subnet_id
  private_dns_zone_id           = var.enable_private_dns ? module.vnet.acr_private_dns_zone_id : null
  public_network_access_enabled = var.acr_public_network_access
  allowed_ip_ranges             = var.acr_allowed_ip_ranges
  tags                          = var.tags
}

# Azure Key Vault
module "keyvault" {
  source                        = "./modules/keyvault"
  key_vault_name                = var.key_vault_name != null ? var.key_vault_name : "${var.resource_group_name}-kv"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = var.key_vault_sku
  purge_protection_enabled      = var.key_vault_purge_protection
  rbac_authorization_enabled    = true
  enable_diagnostics            = var.enable_log_analytics
  log_analytics_workspace_id    = var.enable_log_analytics ? azurerm_log_analytics_workspace.monitoring[0].id : null
  network_acls_default_action   = var.key_vault_network_default_action
  network_acls_bypass           = var.key_vault_network_bypass
  allowed_ip_ranges             = var.key_vault_allowed_ips
  public_network_access_enabled = var.key_vault_public_access
  enable_private_endpoint       = var.enable_keyvault_private_endpoint
  private_endpoint_subnet_id    = module.vnet.private_endpoint_subnet_id
  private_dns_zone_id           = var.enable_private_dns ? module.vnet.keyvault_private_dns_zone_id : null
  tags                          = var.tags
}

# Azure Kubernetes Service
module "aks" {
  source                            = "./modules/aks"
  aks_name                          = var.aks_name
  location                          = var.location
  resource_group_name               = azurerm_resource_group.rg.name
  acr_id                            = module.acr.acr_id
  vnet_subnet_id                    = module.vnet.aks_subnet_id # Attach AKS to VNet subnet
  
  # CRITICAL: Ensure route table is associated with subnet BEFORE AKS cluster creation
  # Required when using userDefinedRouting with NAT Gateway
  # This prevents "ExistingRouteTableNotAssociatedWithSubnet" error
  depends_on = [
    module.vnet.aks_subnet_route_table_association_id, # Wait for route table association
  ]
  # Outbound configuration:
  # - When NAT Gateway is enabled (enterprise-grade): use userDefinedRouting for predictable egress IPs
  # - When NAT Gateway is disabled (dev simplification): fall back to loadBalancer for simpler, more resilient outbound during bootstrap
  outbound_type                      = var.enable_nat_gateway ? "userDefinedRouting" : "loadBalancer"
  kubernetes_version                = var.kubernetes_version
  enable_log_analytics              = var.enable_log_analytics
  log_analytics_workspace_id        = var.enable_log_analytics ? azurerm_log_analytics_workspace.monitoring[0].id : null
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = var.enable_azure_policy
  local_account_disabled            = var.disable_local_accounts
  # Production-Grade: Use group names (looked up via data sources) or fallback to Object IDs
  admin_group_object_ids            = concat(
    # Lookup groups by name (preferred - production-grade)
    length(var.admin_group_names) > 0 ? [for group in data.azuread_group.aks_cluster_admins : group.object_id] : [],
    # Fallback to Object IDs for backward compatibility
    var.admin_group_object_ids
  )
  azure_rbac_enabled                = var.enable_azure_rbac
  private_cluster_enabled           = var.aks_private_cluster_enabled
  api_server_authorized_ip_ranges   = var.aks_api_server_authorized_ip_ranges
  default_node_pool_name            = var.default_node_pool_name
  default_node_pool_vm_size         = var.default_node_pool_vm_size
  default_node_pool_node_count      = var.default_node_pool_node_count
  default_node_pool_os_disk_size_gb = var.default_node_pool_os_disk_size_gb
  enable_auto_scaling               = var.enable_auto_scaling
  min_node_count                    = var.min_node_count
  max_node_count                    = var.max_node_count
  system_pool_taints                = var.system_pool_taints
  additional_node_pools             = var.workload_node_pools
  # Auto-scaler profile - Enterprise-grade: Compliance-focused configuration
  auto_scaler_balance_similar_node_groups      = var.auto_scaler_balance_similar_node_groups
  auto_scaler_max_graceful_termination_sec     = var.auto_scaler_max_graceful_termination_sec
  auto_scaler_scale_down_delay_after_add       = var.auto_scaler_scale_down_delay_after_add
  auto_scaler_scale_down_unneeded              = var.auto_scaler_scale_down_unneeded
  auto_scaler_scale_down_utilization_threshold = var.auto_scaler_scale_down_utilization_threshold
  auto_scaler_scan_interval                    = var.auto_scaler_scan_interval
  network_plugin_mode                          = var.network_plugin_mode
  network_policy                               = var.network_policy
  pod_cidr                                     = var.pod_cidr
  network_dataplane                            = var.network_dataplane
  tags                                         = var.tags
}

# User-assigned managed identity for Workload Identity (for pod-level access)
# Note: AKS cluster identity does NOT need direct Key Vault access (least privilege)
# Only the Workload Identity (below) needs access for pods to retrieve secrets
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "${var.aks_name}-workload-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# Grant Workload Identity access to Key Vault
resource "azurerm_role_assignment" "workload_identity_keyvault_secrets_user" {
  depends_on           = [module.keyvault, azurerm_user_assigned_identity.workload_identity]
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

# Federated identity credential for Workload Identity
resource "azurerm_federated_identity_credential" "workload_identity" {
  depends_on = [module.aks, azurerm_user_assigned_identity.workload_identity]
  name       = "${var.aks_name}-federated-credential"
  # Note: resource_group_name is deprecated and no longer needed - inferred from parent_id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = module.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.workload_identity.id
  subject   = "system:serviceaccount:${var.k8s_namespace}:${var.workload_identity_service_account_name}"
}

# Azure RBAC role assignments for AKS cluster access (when Azure RBAC is enabled)
# Production-Grade: Use data sources to lookup groups by name instead of hardcoding Object IDs
# This makes configuration more maintainable and follows best practices

# Cluster Admin Role - Full administrative access to the cluster
# Supports both group names (preferred) and Object IDs (backward compatibility)
resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each = var.enable_azure_rbac ? toset(
    concat(
      # Lookup groups by name (production-grade approach)
      length(var.admin_group_names) > 0 ? [for group in data.azuread_group.aks_cluster_admins : group.object_id] : [],
      # Fallback to Object IDs for backward compatibility
      var.admin_group_object_ids
    )
  ) : toset([])

  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = each.value
}

# Cluster User Role - Read-only access to the cluster
# Supports both group names (preferred) and Object IDs (backward compatibility)
resource "azurerm_role_assignment" "aks_cluster_user" {
  for_each = var.enable_azure_rbac ? toset(
    concat(
      # Lookup groups by name (production-grade approach)
      length(var.operator_group_names) > 0 ? [for group in data.azuread_group.aks_cluster_operators : group.object_id] : [],
      # Fallback to Object IDs for backward compatibility
      var.operator_group_object_ids
    )
  ) : toset([])

  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
}

# GitHub Actions OIDC Configuration
# Note: Only create if enabled and repository is specified
module "github_oidc" {
  count  = var.enable_github_oidc && var.github_repository != "" ? 1 : 0
  source = "./modules/github-oidc"

  depends_on = [module.vnet] # Ensure VNet is created first

  app_display_name          = var.github_oidc_app_name
  github_repository         = var.github_repository
  github_branch             = var.github_branch
  federated_credential_name = var.github_oidc_credential_name
  additional_subjects       = var.github_oidc_additional_subjects
  scope                     = azurerm_resource_group.rg.id
  role_assignments          = var.github_oidc_role_assignments
  acr_id                    = module.acr.acr_id
  enable_acr_access         = true # Pull images for security scans
  enable_acr_push           = true # Push images for CI/CD (GitOps: CI only pushes, ArgoCD deploys)
  # GitOps Architecture: CI does NOT access AKS cluster
  # ArgoCD in-cluster manages deployments by pulling manifests from Git
  aks_id                    = null
  enable_aks_access         = false # Enterprise-grade GitOps: No CI access to cluster
  tags                      = var.tags
}

# Trusted Execution Zone - Operations VM
# Enterprise-grade: Secure operations, kubectl, and CI/CD execution environment
# This VM serves as:
# - Operations Box: Day-to-day cluster management
# - kubectl Box: Secure access to private AKS cluster
# - CI/CD Execution Engine: Runs GitHub Actions, deployments, etc.
module "bastion_jumpbox" {
  count  = var.enable_bastion ? 1 : 0
  source = "./modules/bastion-jumpbox"

  depends_on = [
    module.vnet,    # Ensure VNet and subnets are created
    module.aks,     # Ensure AKS cluster exists for role assignments
    module.acr,     # Ensure ACR exists for role assignments
    module.keyvault # Ensure Key Vault exists for role assignments
  ]

  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  vnet_name           = module.vnet.vnet_name
  bastion_subnet_id   = module.vnet.bastion_subnet_id
  jumpbox_subnet_id   = module.vnet.jumpbox_subnet_id

  # VM Configuration
  jumpbox_vm_name         = var.jumpbox_vm_name
  jumpbox_vm_size         = var.jumpbox_vm_size
  jumpbox_admin_username  = var.jumpbox_admin_username
  jumpbox_ssh_public_key  = var.jumpbox_ssh_public_key

  # Bastion Configuration
  bastion_name            = "${var.resource_group_name}-bastion"
  bastion_sku             = var.bastion_sku
  enable_copy_paste       = var.enable_bastion_copy_paste
  enable_ip_connect       = var.enable_bastion_ip_connect
  enable_shareable_link   = var.enable_bastion_shareable_link
  enable_tunneling        = var.enable_bastion_tunneling

  # Trusted Execution Zone Configuration
  # Role assignments for Managed Identity
  aks_cluster_id          = module.aks.cluster_id
  acr_id                  = module.acr.acr_id
  key_vault_id            = module.keyvault.key_vault_id
  resource_group_id       = azurerm_resource_group.rg.id

  # Optional: Monitoring
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.monitoring[0].id : null

  # Optional: GitHub Actions Runner
  github_repository_url = var.github_repository_url
  github_runner_token  = var.github_runner_token

  # Optional: Disk encryption (if you have a disk encryption set)
  disk_encryption_set_id = null

  # Azure AD Login Configuration (Enterprise-grade)
  # Access is controlled via Azure RBAC - no SSH keys needed
  vm_admin_login_principal_ids = var.vm_admin_login_principal_ids
  vm_user_login_principal_ids  = var.vm_user_login_principal_ids

  # Tool Versions (Best Practice: Parameterized for version control)
  kubelogin_version  = var.jumpbox_kubelogin_version
  terraform_version   = var.jumpbox_terraform_version
  github_runner_version = var.jumpbox_github_runner_version
  nodejs_version      = var.jumpbox_nodejs_version

  # OS Image Configuration (Best Practice: Parameterized for flexibility)
  vm_os_image_publisher = var.jumpbox_os_image_publisher
  vm_os_image_offer     = var.jumpbox_os_image_offer
  vm_os_image_sku       = var.jumpbox_os_image_sku
  vm_os_image_version   = var.jumpbox_os_image_version

  # Storage Configuration
  vm_os_disk_storage_account_type = var.jumpbox_os_disk_storage_account_type

  # Azure AD Extension Configuration
  aad_ssh_login_extension_version = var.jumpbox_aad_ssh_login_extension_version

  # Enterprise-Grade: Installation Control (Phase 2 - Optional Tools)
  # Set to false to skip optional tools and avoid timeout issues
  # Tools can be installed later manually or via separate extension
  install_docker        = var.jumpbox_install_docker
  install_terraform     = var.jumpbox_install_terraform
  install_nodejs        = var.jumpbox_install_nodejs
  install_github_runner = var.jumpbox_install_github_runner

  tags = var.tags
}
