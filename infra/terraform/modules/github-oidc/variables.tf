variable "app_display_name" {
  description = "Display name for the Azure AD application"
  type        = string
  default     = "github-actions-oidc"
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'OlatunbosunIbiyinka/Olatunbosun-portfolio-project')"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch name (default: main)"
  type        = string
  default     = "main"
}

variable "federated_credential_name" {
  description = "Name for the federated identity credential"
  type        = string
  default     = "github-actions-federated-credential"
}

variable "additional_subjects" {
  description = "Additional subjects for federated credentials (e.g., for environments or pull requests)"
  type        = list(string)
  default     = []
}

variable "scope" {
  description = "Scope for role assignments (resource group ID or subscription ID)"
  type        = string
}

variable "role_assignments" {
  description = "List of role definition names to assign (e.g., ['Contributor', 'Reader'])"
  type        = list(string)
  default     = ["Contributor"]
}

variable "acr_id" {
  description = "Azure Container Registry resource ID (optional)"
  type        = string
  default     = null
}

variable "enable_acr_access" {
  description = "Enable ACR pull permissions for GitHub Actions (requires acr_id to be set)"
  type        = bool
  default     = false
}

variable "enable_acr_push" {
  description = "Enable ACR push permissions for GitHub Actions to push images (requires acr_id to be set)"
  type        = bool
  default     = false
}

variable "aks_id" {
  description = "Azure Kubernetes Service resource ID (optional)"
  type        = string
  default     = null
}

variable "enable_aks_access" {
  description = "Enable AKS permissions for GitHub Actions (requires aks_id to be set)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
