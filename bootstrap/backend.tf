terraform {
  required_version = ">= 1.6"

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "edgeopstechtfstate"
    container_name       = "terraform-azure-ops"
    key                  = "bootstrap-tfstate.tfstate"
    use_oidc             = true
    client_id            = "fb40e7aa-7931-4675-9295-b0d7620ebf9a"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
