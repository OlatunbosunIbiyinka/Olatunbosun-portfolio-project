output "acr_id" {
  value = azurerm_container_registry.acr_name.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr_name.login_server
}
