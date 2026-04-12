output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet"
  value       = var.enable_bastion ? azurerm_subnet.bastion[0].id : null
}

output "jumpbox_subnet_id" {
  description = "ID of the operations/jumpbox subnet (Trusted Execution Zone)"
  value       = var.enable_bastion ? azurerm_subnet.jumpbox[0].id : null
}

output "keyvault_private_dns_zone_id" {
  description = "ID of the Key Vault Private DNS Zone"
  value       = var.enable_private_dns ? azurerm_private_dns_zone.keyvault[0].id : null
}

output "acr_private_dns_zone_id" {
  description = "ID of the ACR Private DNS Zone"
  value       = var.enable_private_dns ? azurerm_private_dns_zone.acr[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.nat_gateway[0].id : null
}

output "nat_gateway_public_ip_address" {
  description = "Public IP address of the NAT Gateway (predictable egress IP)"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat_gateway[0].ip_address : null
}

output "nat_gateway_public_ip_id" {
  description = "ID of the NAT Gateway public IP"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat_gateway[0].id : null
}

output "aks_subnet_route_table_association_id" {
  description = "ID of the route table association for AKS subnet. Used to ensure route table is associated before AKS cluster creation."
  value       = var.enable_nat_gateway ? azurerm_subnet_route_table_association.aks_subnet[0].id : null
}