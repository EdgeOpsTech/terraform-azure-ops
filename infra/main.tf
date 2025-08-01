terraform {
  required_version = ">= 1.6"

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "edgeopstechtfstate"
    container_name       = "terraform-azure-ops"
    key                  = "terraform.tfstate"
    use_oidc             = true
    client_id            = "fb40e7aa-7931-4675-9295-b0d7620ebf9a"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "edgeopstech-rg-infra"
  location = "eastus"
}

