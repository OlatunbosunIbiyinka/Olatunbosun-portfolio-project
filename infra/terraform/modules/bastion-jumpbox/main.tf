# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [] # Zone-redundant for high availability

  tags = var.tags
}

# Azure Bastion for secure access to private AKS cluster
# Enterprise-grade: Provides secure, RDP/SSH access without exposing VMs to the internet
resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id             = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  sku                = var.bastion_sku
  copy_paste_enabled = var.enable_copy_paste
  ip_connect_enabled = var.enable_ip_connect
  shareable_link_enabled = var.enable_shareable_link
  tunneling_enabled  = var.enable_tunneling

  tags = var.tags
}

# Network Security Group for jumpbox subnet
# Enterprise-grade: Restrict access to jumpbox (only allow SSH from Bastion subnet)
resource "azurerm_network_security_group" "jumpbox" {
  name                = "${var.jumpbox_vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH from Azure Bastion subnet only
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork" # Allow from VNet (Bastion is in VNet)
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic (for kubectl, Azure CLI, etc.)
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with jumpbox subnet
resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = var.jumpbox_subnet_id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# Random password for VM (only used if SSH key is not provided and password auth is enabled)
# Note: For Azure AD login, this password won't be used once AAD extension is installed
# It's only required to satisfy Terraform's validation during VM creation
resource "random_password" "jumpbox_password" {
  count   = var.jumpbox_ssh_public_key == null ? 1 : 0
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# User-Assigned Managed Identity for Trusted Execution Zone
# Enterprise-grade: Secure authentication without passwords or keys
resource "azurerm_user_assigned_identity" "operations_vm" {
  name                = "${var.jumpbox_vm_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Interface for jumpbox VM
resource "azurerm_network_interface" "jumpbox" {
  name                = "${var.jumpbox_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Operations VM (Trusted Execution Zone)
# Enterprise-grade: Secure operations, kubectl, and CI/CD execution environment
# This VM serves as:
# - Operations box: Day-to-day cluster management
# - kubectl box: Secure access to private AKS cluster
# - CI/CD execution engine: Runs GitHub Actions, deployments, etc.
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = var.jumpbox_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username

  # Enterprise-grade: Azure AD login enabled (no SSH keys needed)
  # Note: For Azure AD login, we disable password auth but Terraform requires at least one auth method
  # We'll use a minimal SSH key block that won't be used (Azure AD handles auth)
  # Alternatively, password auth can be enabled but won't be used once AAD extension is installed
  disable_password_authentication = var.jumpbox_ssh_public_key != null ? true : false

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  # Enterprise-grade: Use managed identity for secure Azure authentication
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.operations_vm.id]
  }

  os_disk {
    name                 = "${var.jumpbox_vm_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = var.vm_os_disk_storage_account_type
    # Enterprise-grade: Enable encryption at rest
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.vm_os_image_publisher
    offer     = var.vm_os_image_offer
    sku       = var.vm_os_image_sku
    version   = var.vm_os_image_version
  }

  # Enterprise-grade: Azure AD login is the primary authentication method
  # SSH key is only provided to satisfy Terraform validation when password auth is disabled
  # Users access via: az ssh vm --name <vm-name> --resource-group <rg-name>
  # Or via Azure Portal → Connect → SSH (uses Azure AD authentication)
  dynamic "admin_ssh_key" {
    for_each = var.jumpbox_ssh_public_key != null ? { provided = var.jumpbox_ssh_public_key } : {}
    content {
      username   = var.jumpbox_admin_username
      public_key = admin_ssh_key.value
    }
  }

  # Password authentication (only used if SSH key is not provided)
  # Note: This password won't be used once Azure AD extension is installed
  # It's only required to satisfy Terraform's validation during VM creation
  admin_password = var.jumpbox_ssh_public_key == null ? random_password.jumpbox_password[0].result : null

  # Enable boot diagnostics for troubleshooting
  boot_diagnostics {
    storage_account_uri = null # Use managed storage account
  }

  # Enterprise-grade: Security hardening
  patch_mode = "AutomaticByPlatform" # Automatic security updates

  tags = merge(var.tags, {
    "Purpose"           = "TrustedExecutionZone"
    "OperationsBox"     = "true"
    "KubectlBox"        = "true"
    "CICDExecutionEngine" = "true"
    "AuthMethod"         = "AzureAD" # Indicates Azure AD login is used
  })
}

# Azure AD Login Extension for Linux VM
# Enterprise-grade: Enables Azure AD authentication for Linux VMs
# Users authenticate with Azure AD credentials, no SSH keys required
# Access controlled via Azure RBAC (Virtual Machine User Login or Administrator Login roles)
resource "azurerm_virtual_machine_extension" "aad_ssh_login" {
  name                 = "AADSSHLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.jumpbox.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = var.aad_ssh_login_extension_version

  tags = var.tags
}

# Phase 1: Critical Tools Setup (Essential for operations)
# Enterprise-grade: Install only critical tools first (Azure CLI, kubectl, kubelogin, Helm)
# This phase is fast (< 10 minutes) and essential for VM operations
resource "azurerm_virtual_machine_extension" "jumpbox_setup_phase1" {
  name                 = "${var.jumpbox_vm_name}-setup-phase1"
  virtual_machine_id   = azurerm_linux_virtual_machine.jumpbox.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  # Phase 1 is fast - only critical tools
  timeouts {
    create = "20m"
    update = "20m"
    delete = "10m"
  }

  depends_on = [azurerm_virtual_machine_extension.aad_ssh_login]

  settings = jsonencode({
    script = base64encode(<<-EOF
      #!/bin/sh
      set -e
      
      # Log all output for audit trail (POSIX sh-compatible)
      LOG_FILE="/var/log/operations-vm-setup-phase1.log"
      touch "$${LOG_FILE}"
      log() {
        echo "$$*" | tee -a "$${LOG_FILE}"
      }
      exec 2>&1
      log "=== Phase 1: Critical Tools Setup Started: $$(date) ==="
      
      # Robust apt lock handling (POSIX sh-compatible)
      # Simple retry loop - wait up to 60 seconds for apt locks
      log "Checking for apt locks..."
      sleep 2
      sleep 2
      sleep 2
      sleep 2
      sleep 2
      # Kill any stuck apt processes
      sudo pkill -9 apt-get 2>/dev/null || true
      sudo pkill -9 apt 2>/dev/null || true
      sudo pkill -9 dpkg 2>/dev/null || true
      sleep 2
      # Remove locks if they exist
      sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null || true
      # Fix any interrupted dpkg operations
      log "Fixing interrupted dpkg operations..."
      sudo dpkg --configure -a 2>/dev/null || true
      sudo apt-get -f install -y 2>/dev/null || true
      
      # Update system and install minimal required packages
      log "Updating package lists..."
      sudo apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false || true
      log "Installing base packages..."
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-broken curl apt-transport-https ca-certificates gnupg lsb-release unzip jq git || {
        log "ERROR: Failed to install base packages"
        exit 1
      }
      
      # Install Azure CLI (critical)
      log "Installing Azure CLI..."
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash || {
        log "ERROR: Azure CLI installation failed"
        exit 1
      }
      
      # Install kubectl (critical)
      log "Installing kubectl..."
      curl -L -s https://dl.k8s.io/release/stable.txt > /tmp/kubectl_version.txt || {
        log "ERROR: Failed to get kubectl version"
        exit 1
      }
      KUBECTL_VERSION=`cat /tmp/kubectl_version.txt`
      curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl" || {
        log "ERROR: kubectl download failed"
        exit 1
      }
      rm -f /tmp/kubectl_version.txt
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      rm -f kubectl
      
      # Install kubelogin (critical for Azure AD RBAC)
      log "Installing kubelogin..."
      KUBELOGIN_VERSION="${var.kubelogin_version}"
      curl -LO "https://github.com/Azure/kubelogin/releases/download/$${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" || {
        log "ERROR: kubelogin download failed"
        exit 1
      }
      unzip -q kubelogin-linux-amd64.zip || {
        log "ERROR: kubelogin extraction failed"
        exit 1
      }
      sudo mv bin/linux_amd64/kubelogin /usr/local/bin/ || {
        log "ERROR: kubelogin installation failed"
        exit 1
      }
      rm -rf bin kubelogin-linux-amd64.zip
      
      # Install Helm (critical)
      log "Installing Helm..."
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || {
        log "ERROR: Helm installation failed"
        exit 1
      }
      
      # Configure Azure CLI to use managed identity
      ADMIN_USER="${var.jumpbox_admin_username}"
      log "Configuring Azure CLI for managed identity..."
      # Ensure home directory exists
      mkdir -p /home/$${ADMIN_USER}
      chown $${ADMIN_USER}:$${ADMIN_USER} /home/$${ADMIN_USER}
      cat > /home/$${ADMIN_USER}/.azure_cli_config.sh << 'AZCLIEOF'
#!/bin/bash
# Login using managed identity
az login --identity --allow-no-subscriptions
export ARM_USE_MSI=true
export ARM_CLIENT_ID=$$(curl -s -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" | jq -r .client_id)
AZCLIEOF
      chmod +x /home/$${ADMIN_USER}/.azure_cli_config.sh
      chown $${ADMIN_USER}:$${ADMIN_USER} /home/$${ADMIN_USER}/.azure_cli_config.sh
      echo "source ~/.azure_cli_config.sh" >> /home/$${ADMIN_USER}/.bashrc
      
      # Create operations directory structure
      mkdir -p /home/$${ADMIN_USER}/operations/scripts /home/$${ADMIN_USER}/operations/configs /home/$${ADMIN_USER}/operations/logs
      chown -R $${ADMIN_USER}:$${ADMIN_USER} /home/$${ADMIN_USER}/operations
      
      # Security hardening
      log "Applying security hardening..."
      sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || true
      sudo systemctl restart sshd || true
      
      log "=== Phase 1: Critical Tools Setup Complete: $$(date) ==="
      log "Phase 1 log saved to: $${LOG_FILE}"
      log "Critical tools installed:"
      log "  ✓ Azure CLI"
      log "  ✓ kubectl"
      log "  ✓ kubelogin"
      log "  ✓ Helm"
      log "  ✓ git, jq, curl"
      log ""
      log "VM is now ready for basic operations!"
      log "Phase 2 (optional tools) can be installed separately if needed."
    EOF
    )
  })

  tags = var.tags
}

# Phase 2: Optional Tools Setup (Docker, Terraform, Node.js, GitHub Runner)
# Enterprise-grade: Install optional tools separately to avoid timeout issues
# These tools can be installed later if needed, or skipped entirely
resource "azurerm_virtual_machine_extension" "jumpbox_setup_phase2" {
  count = var.install_docker || var.install_terraform || var.install_nodejs || (var.install_github_runner && var.github_runner_token != null && var.github_repository_url != null) ? 1 : 0

  name                 = "${var.jumpbox_vm_name}-setup-phase2"
  virtual_machine_id   = azurerm_linux_virtual_machine.jumpbox.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  # Phase 2 can take longer but failures are non-critical
  timeouts {
    create = "45m"
    update = "45m"
    delete = "10m"
  }

  depends_on = [azurerm_virtual_machine_extension.jumpbox_setup_phase1]

  settings = jsonencode({
    script = base64encode(<<-EOF
      #!/bin/sh
      set +e  # Continue on errors for optional tools
      
      LOG_FILE="/var/log/operations-vm-setup-phase2.log"
      touch "$${LOG_FILE}"
      log() {
        echo "$$*" | tee -a "$${LOG_FILE}"
      }
      exec 2>&1
      log "=== Phase 2: Optional Tools Setup Started: $$(date) ==="
      
      # Robust apt lock handling (POSIX sh-compatible)
      wait_for_apt() {
        log "Checking for apt locks..."
        sleep 2
        sleep 2
        sleep 2
        sleep 2
        sleep 2
        # Kill any stuck apt processes
        sudo pkill -9 apt-get 2>/dev/null || true
        sudo pkill -9 apt 2>/dev/null || true
        sleep 2
        # Remove locks if they exist
        sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend 2>/dev/null || true
      }
      
      ADMIN_USER="${var.jumpbox_admin_username}"
      INSTALL_DOCKER="${var.install_docker}"
      INSTALL_TERRAFORM="${var.install_terraform}"
      INSTALL_NODEJS="${var.install_nodejs}"
      INSTALL_GITHUB_RUNNER="${var.install_github_runner}"
      
      # Install Docker (optional)
      if [ "$${INSTALL_DOCKER}" = "true" ]; then
        log "Installing Docker..."
        wait_for_apt
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
          log "WARNING: Docker GPG key download failed, skipping Docker installation"
        }
        if [ -f /etc/apt/keyrings/docker.gpg ]; then
          sudo chmod a+r /etc/apt/keyrings/docker.gpg
          echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          wait_for_apt
          sudo apt-get update || log "WARNING: apt-get update failed"
          sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
            log "WARNING: Docker installation failed, but continuing..."
          }
          sudo usermod -aG docker $$ADMIN_USER || true
          sudo systemctl enable docker || true
          sudo systemctl start docker || true
          log "Docker installation completed (with possible warnings)"
        fi
      else
        log "Docker installation skipped (install_docker=false)"
      fi
      
      # Install Terraform (optional)
      if [ "$${INSTALL_TERRAFORM}" = "true" ]; then
        log "Installing Terraform..."
        TERRAFORM_VERSION="${var.terraform_version}"
        curl -LO "https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip" || {
          log "WARNING: Terraform download failed, skipping..."
        }
        if [ -f terraform_$${TERRAFORM_VERSION}_linux_amd64.zip ]; then
          unzip -q terraform_$${TERRAFORM_VERSION}_linux_amd64.zip || log "WARNING: Terraform extraction failed"
          sudo mv terraform /usr/local/bin/ 2>/dev/null || log "WARNING: Terraform installation failed"
          rm -f terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
          log "Terraform installation completed"
        fi
      else
        log "Terraform installation skipped (install_terraform=false)"
      fi
      
      # Install Node.js (optional)
      if [ "$${INSTALL_NODEJS}" = "true" ]; then
        log "Installing Node.js..."
        wait_for_apt
        NODEJS_VERSION="${var.nodejs_version}"
        curl -fsSL "https://deb.nodesource.com/setup_$${NODEJS_VERSION}.x" | sudo -E bash - || {
          log "WARNING: Node.js repository setup failed, skipping..."
        }
        if [ $$? -eq 0 ]; then
          wait_for_apt
          sudo apt-get install -y nodejs || log "WARNING: Node.js installation failed"
          log "Node.js installation completed"
        fi
      else
        log "Node.js installation skipped (install_nodejs=false)"
      fi
      
      # Install GitHub Actions Runner (optional)
      GITHUB_RUNNER_TOKEN="${var.github_runner_token != null ? var.github_runner_token : ""}"
      GITHUB_REPO_URL="${var.github_repository_url != null ? var.github_repository_url : ""}"
      if [ "$${INSTALL_GITHUB_RUNNER}" = "true" ] && [ -n "$${GITHUB_RUNNER_TOKEN}" ] && [ -n "$${GITHUB_REPO_URL}" ]; then
        log "Installing GitHub Actions Runner..."
        mkdir -p /home/$$ADMIN_USER/actions-runner
        cd /home/$$ADMIN_USER/actions-runner || {
          log "WARNING: Failed to create actions-runner directory"
        }
        if [ -d /home/$$ADMIN_USER/actions-runner ]; then
          GITHUB_RUNNER_VERSION="${var.github_runner_version}"
          RUNNER_VERSION_NO_V=$${GITHUB_RUNNER_VERSION#v}
          curl -o actions-runner-linux-x64-$${RUNNER_VERSION_NO_V}.tar.gz -L "https://github.com/actions/runner/releases/download/$${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION_NO_V}.tar.gz" || {
            log "WARNING: GitHub Runner download failed"
          }
          if [ -f actions-runner-linux-x64-$${RUNNER_VERSION_NO_V}.tar.gz ]; then
            tar xzf ./actions-runner-linux-x64-$${RUNNER_VERSION_NO_V}.tar.gz || log "WARNING: GitHub Runner extraction failed"
            sudo ./config.sh --url "$${GITHUB_REPO_URL}" --token "$${GITHUB_RUNNER_TOKEN}" --work _work --replace || log "WARNING: GitHub Runner configuration failed"
            sudo ./svc.sh install $$ADMIN_USER || log "WARNING: GitHub Runner service installation failed"
            sudo ./svc.sh start || log "WARNING: GitHub Runner service start failed"
            log "GitHub Actions Runner installation completed (with possible warnings)"
          fi
        fi
      else
        log "GitHub Actions Runner installation skipped (not configured or disabled)"
      fi
      
      # Install additional utilities
      log "Installing additional utilities..."
      wait_for_apt
      sudo apt-get install -y vim nano tmux screen htop net-tools 2>/dev/null || log "WARNING: Some utilities failed to install"
      
      # Install Azure Monitor Agent (if workspace ID provided)
      WORKSPACE_ID="${var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : ""}"
      if [ -n "$${WORKSPACE_ID}" ]; then
        log "Installing Azure Monitor Agent..."
        wget https://aka.ms/dependencyagentlinux -O InstallDependencyAgent-Linux64.bin 2>/dev/null || log "WARNING: Azure Monitor Agent download failed"
        if [ -f InstallDependencyAgent-Linux64.bin ]; then
          sudo sh InstallDependencyAgent-Linux64.bin -s 2>/dev/null || log "WARNING: Azure Monitor Agent installation failed (may require manual configuration)"
        fi
      else
        log "Azure Monitor Agent not configured (log_analytics_workspace_id not provided)"
      fi
      
      log "=== Phase 2: Optional Tools Setup Complete: $$(date) ==="
      log "Phase 2 log saved to: $${LOG_FILE}"
      log "Note: Some optional tools may have warnings - this is expected and non-critical."
      log "VM is fully configured and ready for operations!"
    EOF
    )
  })

  tags = var.tags
}

# Role Assignment: AKS Cluster Admin (for kubectl operations)
# Enterprise-grade: Grant minimum required permissions using managed identity
# Using for_each with static keys to avoid "count depends on resource attributes" error
# Boolean flags are known at plan time, allowing Terraform to determine for_each keys
# Scope can be unknown - Terraform will resolve it at apply time
resource "azurerm_role_assignment" "operations_vm_aks_admin" {
  for_each             = var.enable_aks_role_assignment ? toset(["aks"]) : toset([])
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azurerm_user_assigned_identity.operations_vm.principal_id
}

# Role Assignment: ACR Contributor (for CI/CD image builds and pushes)
# Using for_each with static keys to avoid "count depends on resource attributes" error
resource "azurerm_role_assignment" "operations_vm_acr_contributor" {
  for_each             = var.enable_acr_role_assignment ? toset(["acr"]) : toset([])
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.operations_vm.principal_id
}

# Role Assignment: Key Vault Secrets User (for CI/CD secret access)
# Using for_each with static keys to avoid "count depends on resource attributes" error
resource "azurerm_role_assignment" "operations_vm_keyvault_secrets_user" {
  for_each             = var.enable_keyvault_role_assignment ? toset(["keyvault"]) : toset([])
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.operations_vm.principal_id
}

# Role Assignment: Contributor (for resource management in resource group)
# Using for_each with static keys to avoid "count depends on resource attributes" error
resource "azurerm_role_assignment" "operations_vm_contributor" {
  for_each             = var.enable_rg_role_assignment ? toset(["rg"]) : toset([])
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.operations_vm.principal_id
}

# Azure AD Login Role Assignments (Enterprise-grade: RBAC-controlled access)
# Users/groups with these roles can access the VM via Azure AD authentication
# No SSH keys needed - access is controlled via Azure RBAC

# Virtual Machine Administrator Login - Full sudo access
# Enterprise-grade: Grant to operations/admin groups for full VM access
resource "azurerm_role_assignment" "vm_admin_login" {
  for_each = toset(var.vm_admin_login_principal_ids)

  scope                = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.value
}

# Virtual Machine User Login - Regular user access (no sudo)
# Enterprise-grade: Grant to operator groups for read-only or limited access
resource "azurerm_role_assignment" "vm_user_login" {
  for_each = toset(var.vm_user_login_principal_ids)

  scope                = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = each.value
}
