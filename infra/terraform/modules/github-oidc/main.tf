# Azure AD App Registration for GitHub OIDC
resource "azuread_application" "github_actions" {
  display_name = var.app_display_name
  description  = "GitHub Actions OIDC for ${var.github_repository}"

  # Convert map tags to set of strings for Azure AD
  tags = [for k, v in var.tags : "${k}:${v}"]
}

# Service Principal for the App Registration
resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false

  # Convert map tags to set of strings for Azure AD
  tags = [for k, v in var.tags : "${k}:${v}"]
}

# Federated Identity Credential for GitHub OIDC (main branch)
resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "${var.federated_credential_name}-main"
  description    = "Federated credential for GitHub Actions OIDC - main branch"

  audiences = ["api://AzureADTokenExchange"]

  issuer  = "https://token.actions.githubusercontent.com"
  subject = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"

  lifecycle {
    # If the parent application is deleted, this resource will fail to destroy
    # This is expected behavior - the credential will be automatically deleted with the application
    # If you encounter 404 errors during destroy, the resource may already be deleted
    create_before_destroy = false
  }
}

# Additional federated identity credentials for additional subjects
resource "azuread_application_federated_identity_credential" "github_actions_additional" {
  for_each = toset(var.additional_subjects)

  application_id = azuread_application.github_actions.id
  display_name   = "${var.federated_credential_name}-${substr(md5(each.value), 0, 8)}"
  description    = "Federated credential for GitHub Actions OIDC - ${each.value}"

  audiences = ["api://AzureADTokenExchange"]

  issuer  = "https://token.actions.githubusercontent.com"
  subject = each.value

  lifecycle {
    # If the parent application is deleted, this resource will fail to destroy
    # This is expected behavior - the credential will be automatically deleted with the application
    # If you encounter 404 errors during destroy, the resource may already be deleted
    create_before_destroy = false
  }
}

# Role assignments for the service principal
resource "azurerm_role_assignment" "contributor" {
  for_each = toset(var.role_assignments)

  scope                = var.scope
  role_definition_name = each.value
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Optional: Grant ACR pull permissions
resource "azurerm_role_assignment" "acr_pull" {
  count = var.enable_acr_access ? 1 : 0

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Optional: Grant ACR push permissions (for CI/CD to push images)
resource "azurerm_role_assignment" "acr_push" {
  count = var.enable_acr_push ? 1 : 0

  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Optional: Grant AKS permissions
resource "azurerm_role_assignment" "aks_contributor" {
  count = var.enable_aks_access ? 1 : 0

  scope                = var.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Optional: Grant remote state storage access for terraform plan in GitHub Actions CI
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  count = var.enable_tfstate_access && var.tfstate_storage_account_id != null ? 1 : 0

  scope                = var.tfstate_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
