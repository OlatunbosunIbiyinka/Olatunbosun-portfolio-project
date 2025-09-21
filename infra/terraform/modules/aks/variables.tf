variable "resource_group_name" {
  description = "Resource group for dev environment"
  default     = "ola-rg"
  type        = string
}


variable "location" {
  description = "Azure region for the dev environment"
  default     = "uksouth"
  type        = string
}


variable "aks_name" {
  description = "AKS cluster name for dev environment"
  default     = "ola-aks"
  type        = string
}

variable "acr_name" {
  description = "ACR name for dev environment"
  default     = "olaacr01"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID for attaching to AKS"
  type        = string
}