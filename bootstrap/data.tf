# Current Azure AD client configuration
data "azuread_client_config" "current" {}

# Current Azure subscription
data "azurerm_subscription" "current" {}