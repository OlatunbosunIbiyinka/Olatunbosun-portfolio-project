output "application_client_id" {
  description = "Client ID (Application ID) of the Azure AD application"
  value       = azuread_application.github_actions.client_id
}

output "application_object_id" {
  description = "Object ID of the Azure AD application"
  value       = azuread_application.github_actions.object_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal"
  value       = azuread_service_principal.github_actions.object_id
}

output "federated_credential_id" {
  description = "ID of the federated identity credential"
  value       = azuread_application_federated_identity_credential.github_actions_main.id
}
