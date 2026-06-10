variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "location" {
  description = "Azure region for the VNet"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "address_space" {
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

variable "enable_bastion" {
  description = "Enable Azure Bastion subnet (required for Bastion deployment)"
  type        = bool
  default     = false
}

variable "bastion_subnet_name" {
  description = "Name of the subnet for Azure Bastion (must be 'AzureBastionSubnet')"
  type        = string
  default     = "AzureBastionSubnet"
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for Azure Bastion subnet (must be /26 or larger)"
  type        = list(string)
  default     = ["10.0.3.0/26"]
}

variable "jumpbox_subnet_name" {
  description = "Name of the subnet for operations/jumpbox VM (Trusted Execution Zone)"
  type        = string
  default     = "operations-subnet"
}

variable "jumpbox_subnet_address_prefixes" {
  description = "Address prefixes for operations/jumpbox subnet"
  type        = list(string)
  default     = ["10.0.4.0/24"]
}

variable "enable_private_dns" {
  description = "Enable Azure Private DNS Zones for private endpoints"
  type        = bool
  default     = true
}

variable "enable_nsg" {
  description = "Enable Network Security Group for private endpoints subnet"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for predictable egress IPs. Enterprise-grade: Recommended for production."
  type        = bool
  default     = true
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway (empty list = zone-redundant)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to VNet resources"
  type        = map(string)
  default     = {}
}
