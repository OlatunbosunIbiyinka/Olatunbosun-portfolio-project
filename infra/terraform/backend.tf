terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "olaportfolio001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true

  }
}