resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Enable anonymous pull (optional, for public images)
  anonymous_pull_enabled = false

  # Enable data endpoint (only for Premium SKU, optional for private endpoints)
  # Note: Private endpoints work without data endpoint, but data endpoint is required for Premium SKU features
  data_endpoint_enabled = var.sku == "Premium" ? (var.enable_private_endpoint ? true : var.data_endpoint_enabled) : false

  # Public network access (configurable)
  public_network_access_enabled = var.public_network_access_enabled

  # Network rule bypass option
  # Enterprise-grade: "None" prevents Azure services from bypassing network rules
  # Options: "AzureServices" (allows Azure services to bypass) or "None" (no bypass)
  network_rule_bypass_option = var.network_rule_bypass

  # Network rules (if public access enabled and IP restrictions specified)
  dynamic "network_rule_set" {
    for_each = var.public_network_access_enabled && length(var.allowed_ip_ranges) > 0 ? { default = true } : {}
    content {
      default_action = "Deny"
      dynamic "ip_rule" {
        for_each = var.allowed_ip_ranges
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  # Georeplications (Premium SKU only)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location = georeplications.value
    }
  }

  tags = var.tags
}

# Private endpoint for ACR (if enabled)
# Note: Using enable_private_endpoint flag instead of checking subnet_id (which is computed)
resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.acr_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id != null ? var.private_endpoint_subnet_id : null

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  # Private DNS Zone Group (configured inline)
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? { default = true } : {}
    content {
      name                 = "${var.acr_name}-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
