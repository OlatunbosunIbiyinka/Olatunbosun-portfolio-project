# Production-grade AKS cluster configuration
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.aks_name}-dns"
  kubernetes_version  = var.kubernetes_version

  # System-assigned managed identity (recommended for production)
  identity {
    type = "SystemAssigned"
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Azure AD integration for RBAC
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.azure_rbac_enabled
  }

  # Network configuration - Enterprise-grade: Azure CNI Overlay with Cilium
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode # "overlay" for Azure CNI Overlay
    network_policy      = var.network_policy      # "cilium" for Cilium network policy engine
    network_data_plane  = var.network_dataplane   # REQUIRED: "cilium" when network_policy = "cilium" (note: underscore in attribute name)
    load_balancer_sku   = var.load_balancer_sku
    outbound_type       = var.outbound_type
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    pod_cidr            = var.pod_cidr # Required for overlay mode
  }

  # Default node pool (dedicated system pool)
  # System pool is reserved for critical system pods (CoreDNS, metrics-server, etc.)
  # Note: mode and node_taints are not supported in default_node_pool block
  # We'll use labels to identify it as system pool, and create a separate system pool if needed
  default_node_pool {
    name                 = var.default_node_pool_name
    vm_size              = var.default_node_pool_vm_size
    os_disk_size_gb      = var.default_node_pool_os_disk_size_gb
    type                 = "VirtualMachineScaleSets"
    max_pods             = var.max_pods_per_node
    os_sku               = var.os_sku
    vnet_subnet_id       = var.vnet_subnet_id # Attach to VNet subnet
    auto_scaling_enabled = var.enable_auto_scaling
    # When autoscaling is enabled: node_count must be null, min_count and max_count must be set
    # When autoscaling is disabled: node_count must be set, min_count and max_count must be null
    node_count = var.enable_auto_scaling ? null : var.default_node_pool_node_count
    min_count  = var.enable_auto_scaling ? var.min_node_count : null
    max_count  = var.enable_auto_scaling ? var.max_node_count : null

    # Node labels for system workloads identification
    # Note: kubernetes.azure.com/* prefix is reserved by AKS, use custom labels instead
    node_labels = merge(
      {
        "node.kubernetes.io/role" = "system"
        "pool.type"               = "system" # Custom label for system pool identification
        "workload.type"           = "system" # Additional label for workload scheduling
      },
      var.node_labels
    )
  }

  # Enable OIDC issuer for Workload Identity
  oidc_issuer_enabled = var.oidc_issuer_enabled

  # Enable Workload Identity
  workload_identity_enabled = var.workload_identity_enabled

  # Auto-scaler profile - Enterprise-grade: Optimized for compliance and performance
  # Ensures proper autoscaling behavior following Azure best practices
  auto_scaler_profile {
    balance_similar_node_groups      = var.auto_scaler_balance_similar_node_groups
    max_graceful_termination_sec     = var.auto_scaler_max_graceful_termination_sec
    scale_down_delay_after_add       = var.auto_scaler_scale_down_delay_after_add
    scale_down_unneeded              = var.auto_scaler_scale_down_unneeded
    scale_down_utilization_threshold = var.auto_scaler_scale_down_utilization_threshold
    scan_interval                    = var.auto_scaler_scan_interval
  }

  # SKU Tier - Enterprise-grade: Standard (production-ready with SLA)
  # Free tier has limitations and is not suitable for production
  sku_tier = var.sku_tier

  # Enable private cluster (optional, for enhanced security)
  private_cluster_enabled = var.private_cluster_enabled

  # API server authorized IP ranges (only if not private cluster)
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Logging and monitoring
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Azure Policy addon with admission control
  # Enterprise-grade: Enables guardrails for pod security, image policies, etc.
  azure_policy_enabled = var.azure_policy_enabled

  # HTTP application routing (optional)
  http_application_routing_enabled = var.http_application_routing_enabled

  # Enable ingress application gateway (optional)
  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway_id != null ? [1] : []
    content {
      gateway_id = var.ingress_application_gateway_id
    }
  }

  # Maintenance window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window_day != null ? [1] : []
    content {
      allowed {
        day   = var.maintenance_window_day
        hours = var.maintenance_window_hours
      }
    }
  }

  # Enable local accounts (disable for better security)
  local_account_disabled = var.local_account_disabled

  # Key Vault Secrets Provider (CSI) — must be explicit or Terraform omits the block and Azure API treats the add-on as disabled,
  # which fails with: "AzureKeyvaultSecretsProvider addon cannot be disabled due to more than 0 Secret Provider Classes"
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = var.key_vault_secret_rotation_enabled
    }
  }

  # Tags
  tags = var.tags

  # Timeout configuration for long-running operations
  # Significantly increased timeout for default node pool updates
  # Default node pool updates can take 90-120+ minutes, especially with:
  # - Network configuration changes (route tables, NAT Gateway, private clusters)
  # - Node provisioning and API server connectivity
  # - Complex network routing scenarios
  timeouts {
    create = "240m" # Significantly increased for initial cluster creation with complex network setup
    # Initial creation with private cluster + NAT Gateway + Cilium can take 120-180+ minutes
    update = "180m" # Significantly increased for default node pool updates (can take 90-120+ minutes)
    delete = "90m"  # Increased for cluster deletion
    read   = "5m"   # Standard read timeout
  }

  # Lifecycle: Ignore upgrade_settings changes on default node pool
  # AKS automatically manages upgrade_settings, which can cause Terraform to detect drift
  # and trigger unnecessary updates that timeout. Ignoring these prevents recurring timeout errors.
  lifecycle {
    ignore_changes = [
      # Note: Terraform doesn't support ignoring nested block attributes directly,
      # but we can prevent unnecessary updates by ensuring configuration stability
      # The timeout increase above handles legitimate long-running operations
    ]
  }
}

# Attach ACR to AKS (grant AKS pull permissions)
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Additional node pools (for application workloads)
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_sku                = each.value.os_sku
  auto_scaling_enabled  = each.value.enable_auto_scaling
  # When autoscaling is enabled: node_count must be null, min_count and max_count must be set
  # When autoscaling is disabled: node_count must be set, min_count and max_count must be null
  node_count     = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count      = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count      = each.value.enable_auto_scaling ? each.value.max_count : null
  max_pods       = each.value.max_pods
  node_labels    = each.value.node_labels
  node_taints    = each.value.node_taints
  mode           = each.value.mode
  vnet_subnet_id = var.vnet_subnet_id # Attach additional node pools to same VNet subnet

  # Lifecycle: Ignore upgrade_settings changes to prevent automatic upgrade conflicts
  # AKS may automatically update upgrade_settings, causing Terraform to detect drift
  # Ignoring these changes prevents unnecessary updates and timeout issues
  lifecycle {
    ignore_changes = [
      upgrade_settings,
    ]
  }
}
