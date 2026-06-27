data "azurerm_client_config" "current" {}

# Key Vault with production-grade security settings
resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network access rules - restrict to specific networks in production
  network_acls {
    default_action = var.network_acls_default_action
    bypass         = var.network_acls_bypass
    ip_rules       = var.allowed_ip_ranges
  }

  # Enable public network access control
  public_network_access_enabled = var.public_network_access_enabled

  # Enable RBAC for access control (recommended over access policies)
  rbac_authorization_enabled = var.rbac_authorization_enabled

  tags = var.tags
}

# Private endpoint for Key Vault (if enabled)
# Note: Using enable_private_endpoint flag instead of checking subnet_id (which is computed)
resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id != null ? var.private_endpoint_subnet_id : null

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  # Private DNS Zone Group (configured inline)
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? { default = true } : {}
    content {
      name                 = "${var.key_vault_name}-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Grant current user/service principal access for initial setup (only if RBAC enabled)
resource "azurerm_role_assignment" "current_user_keyvault_admin" {
  count                = var.rbac_authorization_enabled ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Access policy for non-RBAC scenarios (fallback - deprecated, use RBAC instead)
resource "azurerm_key_vault_access_policy" "current_user_access" {
  count        = var.rbac_authorization_enabled ? 0 : 1
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

# Diagnostic settings for Key Vault monitoring
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "${var.key_vault_name}-diagnostics"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

