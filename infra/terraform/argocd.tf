# ArgoCD GitOps variables (root module)
# Kept in a dedicated file so Phase 2 from the VM gets them on git pull
variable "enable_argocd" {
  description = "Enable ArgoCD for GitOps deployments. Enterprise-grade: Cluster manages itself via Git, CI only pushes images."
  type        = bool
  default     = true
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD installation"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "ArgoCD version to install (use 'latest' for latest stable version)"
  type        = string
  default     = "latest"
}
