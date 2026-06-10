output "bastion_id" {
  description = "ID of the Azure Bastion resource"
  value       = azurerm_bastion_host.bastion.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion resource"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_public_ip" {
  description = "Public IP address of Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

output "jumpbox_vm_id" {
  description = "ID of the jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.id
}

output "jumpbox_vm_name" {
  description = "Name of the jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.name
}

output "jumpbox_private_ip" {
  description = "Private IP address of the jumpbox VM"
  value       = azurerm_network_interface.jumpbox.private_ip_address
}

output "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM"
  value       = var.jumpbox_admin_username
}

output "jumpbox_password" {
  description = "DEPRECATED: Azure AD login is used instead. This output is kept for backward compatibility."
  sensitive   = true
  value       = null
}

output "operations_vm_managed_identity_id" {
  description = "Managed Identity ID for the operations VM (Trusted Execution Zone)"
  value       = azurerm_user_assigned_identity.operations_vm.id
}

output "operations_vm_managed_identity_principal_id" {
  description = "Managed Identity Principal ID for role assignments"
  value       = azurerm_user_assigned_identity.operations_vm.principal_id
}

output "operations_vm_managed_identity_client_id" {
  description = "Managed Identity Client ID"
  value       = azurerm_user_assigned_identity.operations_vm.client_id
}

output "connection_instructions" {
  description = "Instructions for connecting to the Trusted Execution Zone VM via Azure AD login"
  value       = <<-EOT
    ============================================
    Trusted Execution Zone - Operations VM
    ============================================
    
    This VM is configured as:
    ✓ Operations Box - Day-to-day cluster management
    ✓ kubectl Box - Secure access to private AKS cluster
    ✓ CI/CD Execution Engine - Runs GitHub Actions, deployments
    
    Enterprise-Grade Authentication: Azure AD Login
    ================================================
    No SSH keys needed! Access is controlled via Azure RBAC.
    
    Method 1: Azure Portal (Recommended)
    ------------------------------------
    1. Go to Azure Portal -> Virtual Machines -> ${var.jumpbox_vm_name}
    2. Click "Connect" -> "Bastion"
    3. Authenticate with your Azure AD credentials
    4. Click "Connect"
    
    Method 2: Azure CLI (az ssh vm)
    --------------------------------
    1. Ensure you're logged in: az login
    2. Connect via SSH: az ssh vm --name ${var.jumpbox_vm_name} --resource-group ${var.resource_group_name}
    3. Authenticate with your Azure AD credentials when prompted
    
    Required Azure RBAC Roles:
    - Virtual Machine Administrator Login (for sudo access)
    - Virtual Machine User Login (for regular user access)
    
    These roles are assigned to Azure AD users/groups via Terraform.
    Contact your administrator if you need access.
    
    Once connected, the VM is pre-configured with:
    - Azure CLI (authenticated via Managed Identity)
    - kubectl, kubelogin, Helm
    - Docker (for CI/CD builds)
    - GitHub Actions Runner (if configured)
    - Terraform, Node.js, and other CI/CD tools
    
    Quick Start:
    # Azure CLI is already authenticated via Managed Identity
    az account show
    
    # Get AKS credentials
    az aks get-credentials --resource-group <rg> --name <cluster>
    kubectl get nodes
    
    # Docker is ready for builds
    docker ps
    
    # GitHub Actions Runner (if configured)
    sudo systemctl status actions.runner.*.service
    
    Managed Identity:
    - Client ID: ${azurerm_user_assigned_identity.operations_vm.client_id}
    - Principal ID: ${azurerm_user_assigned_identity.operations_vm.principal_id}
    - Roles: AKS Admin, ACR Contributor, Key Vault Secrets User, Contributor
  EOT
}
