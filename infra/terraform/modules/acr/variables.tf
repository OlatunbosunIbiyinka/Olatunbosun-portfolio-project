variable "resource_group_name" {
  description = "Resource group where ACR will be created"
  type        = string
}

variable "location" {
  description = "Azure region for ACR"
  type        = string
}

variable "acr_name" {
  description = "ACR name"
  type        = string
}
