# Resource Group Configuration
resource_group_name = "ola-rg-dev"
location            = "uksouth"

# AKS Configuration
aks_name           = "ola-aks-dev"
kubernetes_version = null # Use latest if null

# Network Configuration (Enterprise-Grade: Azure CNI Overlay + Cilium)
# Azure CNI Overlay provides better IP management and scalability
# Cilium provides advanced network policies and observability
# Note: These are set as defaults in the AKS module, but can be overridden here if needed
# Network Configuration (Enterprise-Grade: Azure CNI Overlay with Cilium)
network_plugin_mode = "overlay"  # Azure CNI Overlay (default)
network_policy      = "cilium"   # Cilium network policy engine (default)
network_dataplane   = "cilium"   # REQUIRED: Must be "cilium" when network_policy = "cilium"
pod_cidr            = "10.244.0.0/16"  # Pod CIDR for overlay mode (default)

# System Node Pool (Dedicated for system workloads: CoreDNS, metrics-server, etc.)
# Production-grade: Separate system pool with taints to prevent user workloads
default_node_pool_name            = "system"
default_node_pool_vm_size         = "Standard_D2s_v3" # Smaller size for system pods
default_node_pool_node_count      = 1
default_node_pool_os_disk_size_gb = 128
enable_auto_scaling               = true
min_node_count                    = 1
max_node_count                    = 3
# System pool taints prevent user workloads from scheduling on system nodes
system_pool_taints = ["CriticalAddonsOnly=true:NoSchedule"]

# Workload Node Pools (Dedicated for application workloads)
# Production-grade: Separate workload pools from system pool
workload_node_pools = {
  "workload" = {
    vm_size             = "Standard_D4s_v3" # Larger size for application workloads
    node_count          = 1
    os_disk_size_gb     = 128
    os_sku              = "Ubuntu"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    max_pods            = 30
    node_labels = {
      "node.kubernetes.io/role" = "workload"
      "pool.type"               = "user"        # Custom label (kubernetes.azure.com/* is reserved)
      "workload"                = "application"
      "workload.type"           = "application" # Additional label for workload scheduling
    }
    node_taints = []     # No taints - accepts all workloads
    mode        = "User" # User mode for application workloads
  }
}

# ACR Configuration
acr_name = "olaacr01dev" # Must be globally unique, lowercase alphanumeric only

# Key Vault Configuration (Enterprise-Grade)
key_vault_name                   = "ola-kv-dev" # Must be globally unique
key_vault_sku                    = "standard"
key_vault_purge_protection       = false  # Disabled for dev to allow easy terraform destroy
key_vault_public_access          = false  # Enterprise-grade: Disabled
key_vault_network_default_action = "Deny" # Enterprise-grade: Deny by default
key_vault_network_bypass         = "None" # Enterprise-grade: No bypass
key_vault_allowed_ips            = []     # Not needed with private endpoints

# Monitoring Configuration
enable_log_analytics = true

# Security Configuration
enable_azure_policy    = true
disable_local_accounts = true
enable_azure_rbac      = true
# Production-Grade: Use group names instead of Object IDs (groups are looked up dynamically)
# This is more maintainable and follows best practices
admin_group_names = ["AKS-Cluster-Admins"] # Group names (preferred - production-grade)
# Legacy: admin_group_object_ids can still be used for backward compatibility
# admin_group_object_ids = [] # Use only if admin_group_names is not available
# Operator groups (read-only access)
operator_group_names = [] # Example: ["AKS-Cluster-Operators"]
# operator_group_object_ids = [] # Legacy: Use operator_group_names instead

# AKS API Server Security (Enterprise-Grade)
aks_private_cluster_enabled = true # Enterprise-grade: Private cluster enabled (API server only accessible from VNet)
# aks_api_server_authorized_ip_ranges = []  # Not needed with private cluster (only used if private_cluster_enabled = false)

# Workload Identity Configuration
k8s_namespace                          = "default"
workload_identity_service_account_name = "workload-identity-sa"

# GitHub Actions OIDC Configuration (Enterprise-Grade: GitOps - CI Only Pushes Images)
# CI/CD only needs ACR push access - cluster manages itself via GitOps (ArgoCD)
enable_github_oidc              = true
github_repository               = "OlatunbosunIbiyinka/Olatunbosun-portfolio-project" # Format: owner/repo
github_branch                   = "main"
github_oidc_app_name            = "github-actions-oidc-dev"
github_oidc_credential_name     = "github-actions-federated-credential-dev"
github_oidc_additional_subjects = []
# Enterprise-grade GitOps: CI only needs ACR push (no cluster access)
# ArgoCD in-cluster pulls manifests from Git, CI never talks to cluster
github_oidc_role_assignments = ["Reader"] # Base role for resource access
# ACR push role is granted separately (see modules/github-oidc)

# Private Endpoint Configuration (Enterprise-Grade: Enabled by Default)
# VNet and private endpoints are automatically created for enterprise-grade security
enable_acr_private_endpoint      = true  # Enterprise-grade: Enabled
enable_keyvault_private_endpoint = true  # Enterprise-grade: Enabled
acr_public_network_access        = false # Enterprise-grade: Disabled

# VNet Configuration (Auto-created)
# vnet_name = null  # Auto-generated as "${resource_group_name}-vnet"
# vnet_address_space = ["10.0.0.0/16"]
# aks_subnet_address_prefixes = ["10.0.1.0/24"]
# private_endpoint_subnet_address_prefixes = ["10.0.2.0/24"]
enable_private_dns = true # Enterprise-grade: Enabled for DNS resolution
enable_nsg         = true # Enterprise-grade: Enabled for network security

# NAT Gateway Configuration (Enterprise-Grade: Predictable Egress IPs)
enable_nat_gateway = false # Dev simplification: disable NAT Gateway to use AKS-managed load balancer egress and avoid vmssCSE timeout during cluster bootstrap
# nat_gateway_zones = []   # Empty = zone-redundant (recommended for high availability in environments where NAT Gateway is enabled)

# GitOps Configuration (Enterprise-Grade: ArgoCD)
# ArgoCD will be deployed in-cluster to manage application deployments
# CI only pushes images to ACR, cluster pulls manifests from Git
# Requires Helm CLI. Run: helm repo add argoproj https://argoproj.github.io/argo-helm
enable_argocd = true
argocd_namespace = "argocd"
argocd_version = "latest" # Use latest stable version

# Trusted Execution Zone (Operations VM) Configuration
# Enterprise-grade: Secure operations, kubectl, and CI/CD execution environment
# This VM serves as:
# - Operations Box: Day-to-day cluster management
# - kubectl Box: Secure access to private AKS cluster
# - CI/CD Execution Engine: Runs GitHub Actions, deployments, etc.
enable_bastion = true
bastion_subnet_address_prefixes = ["10.0.3.0/26"]
jumpbox_subnet_address_prefixes = ["10.0.4.0/24"]
jumpbox_vm_size = "Standard_D2s_v3"  # Sufficient for operations and CI/CD
# Enterprise-Grade: Azure AD Login (No SSH keys needed!)
# Access is controlled via Azure RBAC roles (Virtual Machine Administrator/User Login)
# 
# BEST PRACTICES (IMPLEMENTED):
# ✅ Using Azure AD Groups instead of individual users (better for team management)
# ✅ Admin Login: Full sudo access (use sparingly, only for operations team)
# ✅ User Login: Regular user access without sudo (for developers/operators)
#
# Get Azure AD group Object IDs:
#   az ad group show --group "Operations VM Admins" --query id -o tsv
#   az ad group show --group "Your Group Name" --query id -o tsv
#
# Get individual user Object IDs (for reference, but use groups instead):
#   az ad signed-in-user show --query id -o tsv
#
# SECURITY NOTE: These Object IDs grant access to the Operations VM via Azure AD authentication.
# Access is logged and audited. Remove users from groups when they leave or change roles.
# To add/remove users: az ad group member add/remove --group "Operations VM Admins" --member-id <user-object-id>
vm_admin_login_principal_ids = [
  "015ac72c-ae21-46a9-8f87-7d21dcc94166"  # Operations VM Admins group (full sudo access)
  # Individual user Object IDs removed - using Azure AD group instead (best practice)
]
vm_user_login_principal_ids = [
  # Add your Azure AD group Object IDs here for regular user access (no sudo)
  # Example: "00000000-0000-0000-0000-000000000000"
  # PRODUCTION BEST PRACTICE: Always use Azure AD group Object IDs instead of individual users
]

# DEPRECATED: SSH key is no longer used (Azure AD login is used instead)
# Kept for backward compatibility only
jumpbox_ssh_public_key = null
jumpbox_admin_username = "azureuser"

# Optional: GitHub Actions Runner (for self-hosted CI/CD)
# Get runner token from: GitHub repo → Settings → Actions → Runners → New self-hosted runner
github_repository_url = "https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project"
# github_runner_token = "..."  # Add when ready to configure self-hosted runner

# Enterprise-Grade: Phase 2 Installation Control (Optional Tools)
# NOTE: Azure doesn't allow multiple CustomScript extensions on the same VM
# Phase 2 tools can be installed manually after Phase 1 completes
# Set all to false to skip Phase 2 (recommended - install tools manually later)
jumpbox_install_docker        = false  # Install Docker (for CI/CD builds) - Install manually after Phase 1
jumpbox_install_terraform     = false  # Install Terraform (for IaC) - Install manually after Phase 1
jumpbox_install_nodejs        = false  # Install Node.js (for frontend builds) - Install manually after Phase 1
jumpbox_install_github_runner = false  # Install GitHub Runner (requires github_runner_token) - Install manually after Phase 1

# Tags - Development Environment (NOT production)
tags = {
  Environment = "development"
  Project     = "portfolio"
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
}
