# Virtual Network for enterprise-grade network isolation
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = var.tags
}

# Subnet for AKS nodes
# Enterprise-grade: Explicitly enable network policies for AKS nodes
# This is the correct setting for compute workloads (not private endpoints)
resource "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_address_prefixes

  # EXPLICIT: Enable private endpoint network policies for AKS nodes
  # This is the correct setting for compute workloads
  # Only private endpoints subnet should have this set to "Disabled"
  private_endpoint_network_policies = "Enabled"
}

# Subnet for private endpoints (ACR, Key Vault, etc.)
# Enterprise-grade: private_endpoint_network_policies MUST be "Disabled" for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoint_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_endpoint_subnet_address_prefixes

  # REQUIRED: Disable private endpoint network policies for private endpoints to work
  # This setting is ONLY on the private endpoints subnet, NOT on AKS subnet
  private_endpoint_network_policies = "Disabled"
}

# Subnet for Azure Bastion (required for secure access to private AKS)
# Enterprise-grade: Dedicated subnet for Azure Bastion (must be named 'AzureBastionSubnet')
# Minimum size: /26 (64 IP addresses)
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = var.bastion_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.bastion_subnet_address_prefixes

  # Bastion subnet does not require special network policy settings
}

# Subnet for Operations VM (Trusted Execution Zone)
# Enterprise-grade: Dedicated subnet for operations, kubectl, and CI/CD execution
resource "azurerm_subnet" "jumpbox" {
  count                = var.enable_bastion ? 1 : 0
  name                 = var.jumpbox_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.jumpbox_subnet_address_prefixes

  # Operations subnet does not require special network policy settings
}

# Azure Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "${var.vnet_name}-keyvault-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault[0].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}

# Azure Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "${var.vnet_name}-acr-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}

# Network Security Group for private endpoints subnet
# Enterprise-grade: Separate rules for better management and auditing
resource "azurerm_network_security_group" "private_endpoints" {
  count               = var.enable_nsg ? 1 : 0
  name                = "${var.private_endpoint_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Enterprise-grade NSG Rule: Allow HTTPS inbound from AKS subnet only (least privilege)
# Tightened: Only allow from AKS subnet (10.0.1.0/24), not entire VNet
# This enables secure communication between AKS nodes and private endpoints
resource "azurerm_network_security_rule" "allow_aks_subnet_https_inbound" {
  count                       = var.enable_nsg ? 1 : 0
  name                        = "AllowAksSubnetHttpsInbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = var.aks_subnet_address_prefixes[0]              # Only AKS subnet, not entire VNet
  destination_address_prefix  = var.private_endpoint_subnet_address_prefixes[0] # Private endpoints subnet
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_endpoints[0].name
}

# Enterprise-grade NSG Rule: Deny all other inbound traffic (default deny)
resource "azurerm_network_security_rule" "deny_all_inbound" {
  count                       = var.enable_nsg ? 1 : 0
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_endpoints[0].name
}

# Enterprise-grade NSG Rule: Allow outbound to Azure services
# Required for private endpoints to communicate with Azure services
resource "azurerm_network_security_rule" "allow_azure_outbound" {
  count                       = var.enable_nsg ? 1 : 0
  name                        = "AllowAzureOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_endpoints[0].name
}

# Associate NSG with private endpoints subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  count                     = var.enable_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints[0].id
}

# Enterprise-grade: NAT Gateway for predictable egress IPs
# Public IP for NAT Gateway (static, predictable egress IP)
resource "azurerm_public_ip" "nat_gateway" {
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = "${var.vnet_name}-nat-gateway-pip"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  sku                     = "Standard"
  zones                   = var.nat_gateway_zones
  idle_timeout_in_minutes = 4

  tags = var.tags
}

# NAT Gateway for predictable egress IPs
# Enterprise-grade: Provides static public IPs for outbound traffic
resource "azurerm_nat_gateway" "nat_gateway" {
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = "${var.vnet_name}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  zones                   = var.nat_gateway_zones

  tags = var.tags
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway" {
  count                = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}

# Route Table for AKS subnet (required for userDefinedRouting)
# Enterprise-grade: Required when using NAT Gateway with userDefinedRouting outbound type
# CRITICAL: Route table must allow VNet and Azure services traffic for private AKS clusters
# NAT Gateway handles internet traffic, but VNet and Azure services use Azure's default routing
resource "azurerm_route_table" "aks_subnet" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.aks_subnet_name}-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Route for VNet traffic (allows AKS nodes to communicate within VNet)
  # This ensures internal VNet traffic uses Azure's default routing, not NAT Gateway
  route {
    name           = "VNetLocal"
    address_prefix = var.address_space[0] # VNet address space (e.g., 10.0.0.0/16)
    next_hop_type  = "VnetLocal"
  }

  # CRITICAL: For private AKS clusters with NAT Gateway, Azure services traffic
  # (AKS API server private endpoint, Azure management APIs) must use Azure's default routing.
  # Traffic that doesn't match any route uses Azure's default routing automatically.
  # NAT Gateway only handles internet-bound traffic (mcr.microsoft.com, packages.microsoft.com, etc.)
  #
  # Note: We don't add an explicit route for Azure services because:
  # 1. Azure services use private IPs that don't match VNet or internet routes
  # 2. Unmatched traffic automatically uses Azure's default routing
  # 3. This allows AKS nodes to reach the API server private endpoint and Azure APIs

  tags = var.tags
}

# Associate Route Table with AKS subnet
# Required for userDefinedRouting outbound type
# This must be done BEFORE NAT Gateway association to avoid conflicts
resource "azurerm_subnet_route_table_association" "aks_subnet" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks_subnet[0].id
  
  # Ensure route table is associated before NAT Gateway
  depends_on = [azurerm_route_table.aks_subnet]
}

# Associate NAT Gateway with AKS subnet
# This enables all outbound traffic from AKS nodes to use the NAT Gateway
# Must be done AFTER route table association
resource "azurerm_subnet_nat_gateway_association" "aks_subnet" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
  
  # Ensure route table is associated first
  depends_on = [azurerm_subnet_route_table_association.aks_subnet]
}
