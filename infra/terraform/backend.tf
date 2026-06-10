terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "olaportfolio001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
    subscription_id      = "cd258f56-ee0f-45e2-976a-a78ae7e93d8c"
    tenant_id            = "5ee10fdc-b731-4ee9-9181-0dad7378a345" # Your tenant ID
  }
}