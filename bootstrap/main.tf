# Resource Group for Terraform State
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}


# Storage Containers for each GitHub repository
resource "azurerm_storage_container" "tfstate" {
  for_each              = local.container_names
  name                  = each.value
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Additional container for shared/main state
resource "azurerm_storage_container" "tfstate_main" {
  name                  = "tf-state-submgmt-np-main"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
