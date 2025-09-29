# # Import existing storage account resources (unchanged - these already exist)
# import {
#   to = azurerm_resource_group.tfstate
#   id = "/subscriptions/bba7ddf1-057e-4d04-afd9-4032cd79dc9d/resourceGroups/rg-tfstate"
# }

# import {
#   to = azurerm_storage_account.tfstate
#   id = "/subscriptions/bba7ddf1-057e-4d04-afd9-4032cd79dc9d/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/edgeopstechtfstate"
# }

# import {
#   to = azurerm_storage_container.tfstate["azure-vm-setup"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/azure-vm-setup"
# }

# import {
#   to = azurerm_storage_container.tfstate["edgeops-keyvault-module"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/edgeops-keyvault-module"
# }

# import {
#   to = azurerm_storage_container.tfstate["edgeops-sub-mgmt"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/edgeops-sub-mgmt"
# }

# import {
#   to = azurerm_storage_container.tfstate["kv-rbac-setup"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/kv-rbac-setup"
# }

# import {
#   to = azurerm_storage_container.tfstate["super-webapp"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/super-webapp"
# }

# import {
#   to = azurerm_storage_container.tfstate["terraform-azure-ops"]
#   id = "https://edgeopstechtfstate.blob.core.windows.net/terraform-azure-ops"
# }

# import {
#   to = azurerm_storage_container.tfstate_main
#   id = "https://edgeopstechtfstate.blob.core.windows.net/tf-state-submgmt-np-main"
# }

# Note: The old single Azure AD application will be replaced with multiple apps
# The new multi-app approach will automatically handle the 20 federated credential limit
