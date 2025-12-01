variable "resource_group_name" {
  description = "Resource group for AKS"
  type        = string
}

variable "location" {
  description = "Azure region for AKS"
  type        = string
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID for attaching to AKS (for future use)"
  type        = string
}
