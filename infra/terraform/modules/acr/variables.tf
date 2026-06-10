variable "resource_group_name" {
  description = "Resource group where ACR will be created"
  type        = string
}

variable "location" {
  description = "Azure region for ACR"
  type        = string
}

variable "acr_name" {
  description = "ACR name (must be globally unique, lowercase alphanumeric only)"
  type        = string
}

variable "sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "List of Azure regions for geo-replication"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to ACR"
  type        = map(string)
  default     = {}
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for ACR"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (required if enable_private_endpoint is true)"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access for ACR"
  type        = bool
  default     = true
}

variable "data_endpoint_enabled" {
  description = "Enable data endpoint for ACR (required for private endpoints)"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for ACR access (when public access is enabled)"
  type        = list(string)
  default     = []
}

variable "network_rule_bypass" {
  description = "Whether Azure services can bypass network rules. Options: 'AzureServices' (allows Azure services to bypass) or 'None' (no bypass - enterprise-grade)."
  type        = string
  default     = "None" # Enterprise-grade: No bypass by default
  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass)
    error_message = "network_rule_bypass must be either 'AzureServices' or 'None'."
  }
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for ACR (optional, for private endpoint DNS resolution)"
  type        = string
  default     = null
}
