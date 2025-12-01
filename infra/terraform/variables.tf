variable "resource_group_name" {
  description = "Resource group for environment"
  type        = string
}

variable "location" {
  description = "Azure region for the environment"
  type        = string
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
}

variable "acr_name" {
  description = "ACR name"
  type        = string
}
