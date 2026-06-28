# Argo CD: set enable_argocd=false for routine plan/apply (core infra only). On the operations VM,
# after AKS is up, set enable_argocd=true (or -var) and apply -target=module.argocd if you want only GitOps.
variable "enable_argocd" {
  description = "Install Argo CD in-cluster. Recommended false until AKS exists; enable from the VM for private API access."
  type        = bool
  default     = false
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD."
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "argo-cd Helm chart version (use 'latest' for newest)."
  type        = string
  default     = "latest"
}

variable "argocd_high_availability" {
  description = "HA Argo CD (multi-replica + redis-ha). false for dev/single-node clusters."
  type        = bool
  default     = false
}
