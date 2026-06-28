variable "resource_group_name" {
  description = "Resource group for environment"
  type        = string
}

variable "location" {
  description = "Azure region for the environment"
  type        = string
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
}

variable "acr_name" {
  description = "ACR name (must be globally unique)"
  type        = string
}

variable "acr_georeplications" {
  description = "Azure regions for ACR geo-replication (Premium SKU only). Use for production DR — e.g. [\"northeurope\"] as UK paired region."
  type        = list(string)
  default     = []
}

variable "key_vault_name" {
  description = "Key Vault name (must be globally unique)"
  type        = string
  default     = null
}

variable "key_vault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "key_vault_purge_protection" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_network_default_action" {
  description = "Default action for Key Vault network ACLs (Deny for enterprise-grade)"
  type        = string
  default     = "Deny"
}

variable "key_vault_network_bypass" {
  description = "Bypass option for Key Vault network ACLs (None for strict security)"
  type        = string
  default     = "None"
}

variable "key_vault_allowed_ips" {
  description = "List of allowed IP ranges for Key Vault access (empty when using private endpoints)"
  type        = list(string)
  default     = []
}

variable "key_vault_public_access" {
  description = "Enable public network access for Key Vault (false for enterprise-grade)"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave null for latest)"
  type        = string
  default     = null
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace"
  type        = bool
  default     = true
}

variable "enable_aks_monitoring_addon" {
  description = "Attach Container Insights (oms_agent) to AKS. Set false for initial cluster bootstrap to avoid Helm timeout on private clusters; enable in a second apply once the cluster is Succeeded."
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "disable_local_accounts" {
  description = "Disable local accounts (use Azure AD only)"
  type        = bool
  default     = true
}

variable "admin_group_names" {
  description = "Azure AD admin group names (for cluster admin access). Production-Grade: Use group names instead of Object IDs for better maintainability. Groups are looked up dynamically via data sources."
  type        = list(string)
  default     = []
}

variable "admin_group_object_ids" {
  description = "Azure AD admin group object IDs (for cluster admin access). Legacy: Use admin_group_names instead for production-grade configuration. Kept for backward compatibility."
  type        = list(string)
  default     = []
}

variable "operator_group_names" {
  description = "Azure AD operator group names (for cluster operator access - read-only). Production-Grade: Use group names instead of Object IDs for better maintainability. Groups are looked up dynamically via data sources."
  type        = list(string)
  default     = []
}

variable "operator_group_object_ids" {
  description = "Azure AD operator group object IDs (for cluster operator access - read-only). Legacy: Use operator_group_names instead for production-grade configuration. Kept for backward compatibility."
  type        = list(string)
  default     = []
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for AKS"
  type        = bool
  default     = true
}

variable "aks_private_cluster_enabled" {
  description = "Enable private AKS cluster (API server only accessible from VNet) - Enterprise-grade: Enabled by default"
  type        = bool
  default     = true
}

variable "aks_api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for AKS API server (only used if aks_private_cluster_enabled = false)"
  type        = list(string)
  default     = []
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "system"
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in default node pool"
  type        = number
  default     = 1
}

variable "default_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for default node pool"
  type        = number
  default     = 128
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for node pools (compliance: enabled for cost optimization and availability)"
  type        = bool
  default     = true
}

# Auto-scaler profile variables - Enterprise-grade: Compliance-focused defaults
variable "auto_scaler_balance_similar_node_groups" {
  description = "Balance similar node groups in cluster autoscaler (compliance: false for predictable scaling)"
  type        = bool
  default     = false
}

variable "auto_scaler_max_graceful_termination_sec" {
  description = "Maximum graceful termination time in seconds (compliance: 600s for safe pod termination)"
  type        = string
  default     = "600"
}

variable "auto_scaler_scale_down_delay_after_add" {
  description = "Time to wait before scaling down after adding nodes (compliance: 10m for stability)"
  type        = string
  default     = "10m"
}

variable "auto_scaler_scale_down_unneeded" {
  description = "Time before unneeded nodes are removed (compliance: 10m for cost optimization)"
  type        = string
  default     = "10m"
}

variable "auto_scaler_scale_down_utilization_threshold" {
  description = "Node utilization threshold for scale down (compliance: 0.5 for efficient resource usage)"
  type        = string
  default     = "0.5"
}

variable "auto_scaler_scan_interval" {
  description = "How often cluster autoscaler scans for changes (compliance: 10s for responsive scaling)"
  type        = string
  default     = "10s"
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes (for system pool)"
  type        = number
  default     = 3
}

variable "system_pool_taints" {
  description = "Taints for system node pool (not supported in default_node_pool, use for additional system pools). Production-grade: CriticalAddonsOnly=true:NoSchedule"
  type        = list(string)
  default     = ["CriticalAddonsOnly=true:NoSchedule"]
}

variable "network_plugin_mode" {
  description = "Network plugin mode for Azure CNI (overlay or None). Enterprise-grade: Use 'overlay' for better IP management and scalability."
  type        = string
  default     = "overlay"
  validation {
    condition     = contains(["overlay", "None"], var.network_plugin_mode)
    error_message = "network_plugin_mode must be 'overlay' or 'None'."
  }
}

variable "pod_cidr" {
  description = "CIDR for Kubernetes pods (required for Azure CNI Overlay). Default: 10.244.0.0/16"
  type        = string
  default     = "10.244.0.0/16"
}

variable "network_dataplane" {
  description = "Network dataplane. REQUIRED: Must be 'cilium' when network_policy = 'cilium'. Enterprise-grade: Use 'cilium' for Cilium dataplane."
  type        = string
  default     = "cilium"
  validation {
    condition     = contains(["azure", "cilium"], var.network_dataplane)
    error_message = "network_dataplane must be 'azure' or 'cilium'."
  }
}

variable "create_dedicated_system_pool" {
  description = "Create a dedicated system node pool with mode=System and taints. Production-grade: Recommended for true separation."
  type        = bool
  default     = false # Set to true for production-grade separation
}

variable "workload_node_pools" {
  description = "Configuration for workload node pools (separate from system pool). Production-grade: Separate system and workload pools."
  type = map(object({
    vm_size             = string
    node_count          = number
    os_disk_size_gb     = number
    os_sku              = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string # "User" for workload pools, "System" for system pools
  }))
  default = {}
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "default"
}

variable "workload_identity_service_account_name" {
  description = "Service account name for Workload Identity"
  type        = string
  default     = "workload-identity-sa"
}

variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC integration"
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'OlatunbosunIbiyinka/Olatunbosun-portfolio-project')"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch name for OIDC (default: main)"
  type        = string
  default     = "main"
}

variable "github_oidc_app_name" {
  description = "Display name for GitHub OIDC Azure AD application"
  type        = string
  default     = "github-actions-oidc"
}

variable "github_oidc_credential_name" {
  description = "Name for GitHub OIDC federated credential"
  type        = string
  default     = "github-actions-federated-credential"
}

variable "github_oidc_additional_subjects" {
  description = "Additional subjects for GitHub OIDC (e.g., for environments or pull requests)"
  type        = list(string)
  default     = []
}

variable "github_oidc_role_assignments" {
  description = "List of role definition names for GitHub OIDC service principal at resource group scope. Enterprise-grade: Use 'Reader' instead of 'Contributor' (least privilege). Specific service roles (AcrPush, AKS Cluster User) are granted separately."
  type        = list(string)
  default     = ["Reader"] # Enterprise-grade: Least privilege (was Contributor)
}

variable "enable_github_oidc_tfstate_access" {
  description = "Grant GitHub OIDC SP Storage Blob Data Contributor on the remote state storage account (required for terraform plan in CI)"
  type        = bool
  default     = true
}

variable "tfstate_resource_group_name" {
  description = "Resource group containing the Terraform remote state storage account (bootstrap stack)"
  type        = string
  default     = "tfstate-rg"
}

variable "tfstate_storage_account_name" {
  description = "Storage account name for Terraform remote state (must match backend.tf)"
  type        = string
  default     = "olaportfolio001"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}

# Private Endpoint Configuration (Enterprise-Grade: Enabled by Default)
variable "enable_acr_private_endpoint" {
  description = "Enable private endpoint for ACR (true for enterprise-grade)"
  type        = bool
  default     = true
}

variable "enable_keyvault_private_endpoint" {
  description = "Enable private endpoint for Key Vault (true for enterprise-grade)"
  type        = bool
  default     = true
}

variable "acr_public_network_access" {
  description = "Enable public network access for ACR (false for enterprise-grade)"
  type        = bool
  default     = false
}

variable "acr_allowed_ip_ranges" {
  description = "List of allowed IP ranges for ACR access (when public access is enabled)"
  type        = list(string)
  default     = []
}

# VNet Configuration (Enterprise-Grade Network Isolation)
variable "vnet_name" {
  description = "Name of the Virtual Network (auto-generated if null)"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space for the VNet (CIDR notation)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_name" {
  description = "Name of the subnet for AKS nodes"
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for AKS subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_endpoint_subnet_name" {
  description = "Name of the subnet for private endpoints"
  type        = string
  default     = "private-endpoints"
}

variable "private_endpoint_subnet_address_prefixes" {
  description = "Address prefixes for private endpoints subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "enable_private_dns" {
  description = "Enable Azure Private DNS Zones for private endpoints"
  type        = bool
  default     = true
}

variable "enable_nsg" {
  description = "Enable Network Security Groups for private endpoints subnet"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for predictable egress IPs. Enterprise-grade: Recommended for production."
  type        = bool
  default     = true
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway (empty list = zone-redundant, recommended for high availability)"
  type        = list(string)
  default     = []
}

variable "network_policy" {
  description = "Specifies the Kubernetes network policy engine for the AKS cluster. Options include 'azure' or 'cilium'. Cilium enables eBPF-powered networking, advanced isolation, and observability."
  type        = string
  default     = "cilium"
}

# Trusted Execution Zone (Operations VM) Configuration
variable "enable_bastion" {
  description = "Enable Azure Bastion and Operations VM (Trusted Execution Zone) for secure cluster access"
  type        = bool
  default     = false
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for Azure Bastion subnet (must be /26 or larger, e.g., 10.0.3.0/26)"
  type        = list(string)
  default     = ["10.0.3.0/26"]
}

variable "jumpbox_subnet_address_prefixes" {
  description = "Address prefixes for operations/jumpbox subnet (Trusted Execution Zone)"
  type        = list(string)
  default     = ["10.0.4.0/24"]
}

variable "jumpbox_vm_size" {
  description = "VM size for the operations VM (Trusted Execution Zone). Standard_D2s_v3 recommended for operations and CI/CD."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "jumpbox_ssh_public_key" {
  description = "SSH public key for the operations VM (DEPRECATED: Azure AD login is used instead). Kept for backward compatibility."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.jumpbox_ssh_public_key == null ? true : trimspace(var.jumpbox_ssh_public_key) != ""
    error_message = "jumpbox_ssh_public_key must be omitted/null or a non-empty SSH public key — do not set jumpbox_ssh_public_key = \"\" in terraform.tfvars."
  }
}

variable "jumpbox_vm_name" {
  description = "Name of the operations VM (Trusted Execution Zone)"
  type        = string
  default     = "aks-operations-vm"
}

variable "jumpbox_admin_username" {
  description = "Admin username for the operations VM"
  type        = string
  default     = "azureuser"
}

variable "github_repository_url" {
  description = "GitHub repository URL for Actions Runner (e.g., https://github.com/owner/repo). Optional, for CI/CD execution."
  type        = string
  default     = null
}

variable "github_runner_token" {
  description = "GitHub Actions runner registration token (sensitive). Get from: GitHub repo → Settings → Actions → Runners → New self-hosted runner"
  type        = string
  default     = null
  sensitive   = true
}

# Stage 1 (laptop): leave null — VM deploys without AKS. Stage 2 (ops VM): set to cluster resource ID after AKS exists.
variable "jumpbox_aks_cluster_id" {
  description = "AKS cluster resource ID for ops VM role assignments. Null on stage 1 (VM before cluster)."
  type        = string
  default     = null
}

# Azure AD Login Configuration (Enterprise-grade)
# Access to the Trusted Execution Zone VM is controlled via Azure RBAC
# No SSH keys needed - users authenticate with Azure AD credentials
variable "vm_admin_login_principal_ids" {
  description = "List of Azure AD user/group Object IDs with Virtual Machine Administrator Login role (full sudo access to the operations VM)"
  type        = list(string)
  default     = []
}

variable "vm_user_login_principal_ids" {
  description = "List of Azure AD user/group Object IDs with Virtual Machine User Login role (regular user access, no sudo)"
  type        = list(string)
  default     = []
}

# Bastion Configuration (Best Practice: Parameterize for flexibility)
variable "bastion_sku" {
  description = "SKU for Azure Bastion (Basic or Standard). Standard recommended for production."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "bastion_sku must be 'Basic' or 'Standard'."
  }
}

variable "enable_bastion_copy_paste" {
  description = "Enable copy/paste feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_bastion_ip_connect" {
  description = "Enable IP connect feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_bastion_shareable_link" {
  description = "Enable shareable link feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_bastion_tunneling" {
  description = "Enable tunneling feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

# Tool Versions (Best Practice: Parameterize for version control)
variable "jumpbox_kubelogin_version" {
  description = "Version of kubelogin to install on operations VM (e.g., v0.0.29)"
  type        = string
  default     = "v0.0.29"
}

variable "jumpbox_terraform_version" {
  description = "Version of Terraform to install on operations VM (e.g., 1.6.0)"
  type        = string
  default     = "1.6.0"
}

variable "jumpbox_github_runner_version" {
  description = "Version of GitHub Actions Runner to install on operations VM (e.g., v2.311.0)"
  type        = string
  default     = "v2.311.0"
}

variable "jumpbox_nodejs_version" {
  description = "Node.js major version to install on operations VM (e.g., 20 for 20.x)"
  type        = string
  default     = "20"
}

# OS Image Configuration (Best Practice: Parameterize for flexibility)
variable "jumpbox_os_image_publisher" {
  description = "Publisher for the operations VM OS image"
  type        = string
  default     = "Canonical"
}

variable "jumpbox_os_image_offer" {
  description = "Offer for the operations VM OS image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "jumpbox_os_image_sku" {
  description = "SKU for the operations VM OS image"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "jumpbox_os_image_version" {
  description = "Version for the operations VM OS image (use 'latest' for latest version)"
  type        = string
  default     = "latest"
}

# Storage Configuration
variable "jumpbox_os_disk_storage_account_type" {
  description = "Storage account type for operations VM OS disk (Premium_LRS, StandardSSD_LRS, Standard_LRS)"
  type        = string
  default     = "Premium_LRS"
  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS"], var.jumpbox_os_disk_storage_account_type)
    error_message = "jumpbox_os_disk_storage_account_type must be one of: Premium_LRS, StandardSSD_LRS, Standard_LRS."
  }
}

# Azure AD Extension Configuration
variable "jumpbox_aad_ssh_login_extension_version" {
  description = "Version of the AADSSHLoginForLinux extension"
  type        = string
  default     = "1.0"
}

# Enterprise-Grade: Installation Control (Phase 2 - Optional Tools)
# These tools can be installed later if needed, or skipped to avoid timeout issues
variable "jumpbox_install_docker" {
  description = "Install Docker in Phase 2 (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "jumpbox_install_terraform" {
  description = "Install Terraform in Phase 2 (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "jumpbox_install_nodejs" {
  description = "Install Node.js in Phase 2 (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "jumpbox_install_github_runner" {
  description = "Install GitHub Actions Runner in Phase 2 (can be installed later if needed)"
  type        = bool
  default     = true
}
