variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet"
  type        = string
}

variable "jumpbox_subnet_id" {
  description = "ID of the subnet for the jumpbox VM (can be same as AKS subnet or dedicated)"
  type        = string
}

variable "jumpbox_vm_name" {
  description = "Name of the jumpbox VM"
  type        = string
  default     = "aks-jumpbox"
}

variable "jumpbox_vm_size" {
  description = "VM size for the jumpbox (Standard_B2s is sufficient for kubectl operations)"
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_ssh_public_key" {
  description = "SSH public key for the jumpbox VM (DEPRECATED: Azure AD login is used instead). Kept for backward compatibility."
  type        = string
  default     = null
  sensitive   = true
}

variable "bastion_name" {
  description = "Name of the Azure Bastion resource"
  type        = string
  default     = "aks-bastion"
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "bastion_sku must be 'Basic' or 'Standard'."
  }
}

variable "enable_copy_paste" {
  description = "Enable copy/paste feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_ip_connect" {
  description = "Enable IP connect feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_shareable_link" {
  description = "Enable shareable link feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "enable_tunneling" {
  description = "Enable tunneling feature in Azure Bastion (Standard SKU only)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Trusted Execution Zone Configuration
variable "aks_cluster_id" {
  description = "AKS cluster resource ID for role assignment (enables kubectl operations)"
  type        = string
  default     = null
}

variable "acr_id" {
  description = "ACR resource ID for role assignment (enables CI/CD image builds)"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault resource ID for role assignment (enables CI/CD secret access)"
  type        = string
  default     = null
}

variable "resource_group_id" {
  description = "Resource group ID for Contributor role assignment (enables resource management)"
  type        = string
  default     = null
}

# Boolean flags to control role assignment creation (known at plan time)
# These allow Terraform to determine for_each keys even when IDs are unknown
variable "enable_aks_role_assignment" {
  description = "Enable AKS Cluster Admin role assignment for operations VM (set to false if aks_cluster_id is not provided)"
  type        = bool
  default     = true
}

variable "enable_acr_role_assignment" {
  description = "Enable ACR Contributor role assignment for operations VM (set to false if acr_id is not provided)"
  type        = bool
  default     = true
}

variable "enable_keyvault_role_assignment" {
  description = "Enable Key Vault Secrets User role assignment for operations VM (set to false if key_vault_id is not provided)"
  type        = bool
  default     = true
}

variable "enable_rg_role_assignment" {
  description = "Enable Resource Group Contributor role assignment for operations VM (set to false if resource_group_id is not provided)"
  type        = bool
  default     = true
}

variable "disk_encryption_set_id" {
  description = "Disk encryption set ID for OS disk encryption (enterprise-grade security)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Azure Monitor Agent (monitoring and logging)"
  type        = string
  default     = null
}

variable "github_repository_url" {
  description = "GitHub repository URL for Actions Runner (e.g., https://github.com/owner/repo)"
  type        = string
  default     = null
}

variable "github_runner_token" {
  description = "GitHub Actions runner registration token (sensitive, for CI/CD execution)"
  type        = string
  default     = null
  sensitive   = true
}

# Enterprise-Grade: Installation Control
variable "install_docker" {
  description = "Install Docker (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "install_terraform" {
  description = "Install Terraform (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "install_nodejs" {
  description = "Install Node.js (can be installed later if needed)"
  type        = bool
  default     = true
}

variable "install_github_runner" {
  description = "Install GitHub Actions Runner (can be installed later if needed)"
  type        = bool
  default     = true
}

# Azure AD Login Configuration (Enterprise-grade)
variable "vm_admin_login_principal_ids" {
  description = "List of Azure AD user/group Object IDs with Virtual Machine Administrator Login role (full sudo access)"
  type        = list(string)
  default     = []
}

variable "vm_user_login_principal_ids" {
  description = "List of Azure AD user/group Object IDs with Virtual Machine User Login role (regular user access, no sudo)"
  type        = list(string)
  default     = []
}

# OS Image Configuration (Best Practice: Parameterize for flexibility)
variable "vm_os_image_publisher" {
  description = "Publisher for the VM OS image"
  type        = string
  default     = "Canonical"
}

variable "vm_os_image_offer" {
  description = "Offer for the VM OS image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_os_image_sku" {
  description = "SKU for the VM OS image"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "vm_os_image_version" {
  description = "Version for the VM OS image (use 'latest' for latest version)"
  type        = string
  default     = "latest"
}

# Storage Configuration
variable "vm_os_disk_storage_account_type" {
  description = "Storage account type for OS disk (Premium_LRS, StandardSSD_LRS, Standard_LRS)"
  type        = string
  default     = "Premium_LRS"
  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS"], var.vm_os_disk_storage_account_type)
    error_message = "vm_os_disk_storage_account_type must be one of: Premium_LRS, StandardSSD_LRS, Standard_LRS."
  }
}

# Tool Versions (Best Practice: Parameterize for version control and updates)
variable "kubelogin_version" {
  description = "Version of kubelogin to install (e.g., v0.0.29)"
  type        = string
  default     = "v0.0.29"
}

variable "terraform_version" {
  description = "Version of Terraform to install (e.g., 1.6.0)"
  type        = string
  default     = "1.6.0"
}

variable "github_runner_version" {
  description = "Version of GitHub Actions Runner to install (e.g., v2.311.0)"
  type        = string
  default     = "v2.311.0"
}

variable "nodejs_version" {
  description = "Node.js major version to install (e.g., 20 for 20.x)"
  type        = string
  default     = "20"
}

# Azure AD Extension Configuration
variable "aad_ssh_login_extension_version" {
  description = "Version of the AADSSHLoginForLinux extension"
  type        = string
  default     = "1.0"
}