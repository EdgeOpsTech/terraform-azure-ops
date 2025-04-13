terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "edgeopstechtfstate" # ← from bootstrap output
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
    client_id            = "fb40e7aa-7931-4675-9295-b0d7620ebf9a" # ← from bootstrap output
  }
}

