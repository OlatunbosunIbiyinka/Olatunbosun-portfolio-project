variable "aks_cluster_id" {
  description = "Azure Kubernetes Service cluster resource ID"
  type        = string
}

variable "aks_cluster_name" {
  description = "Azure Kubernetes Service cluster name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where AKS cluster is located"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD installation"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "ArgoCD version to install (use 'latest' for latest stable version)"
  type        = string
  default     = "latest"
}

variable "high_availability" {
  description = "HA Argo CD (multi-replica + redis-ha). false for dev/single-node bootstrap clusters."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
