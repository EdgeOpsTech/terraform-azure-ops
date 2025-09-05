# Role Assignment: Subscription Contributor
resource "azurerm_role_assignment" "sub_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.id

  depends_on = [azuread_service_principal.github_oidc]
}

# Role Assignment: Storage Blob Data Contributor
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_oidc.id

  depends_on = [azuread_service_principal.github_oidc]
}

# Role Assignment: User Access Administrator (for RBAC operations)
resource "azurerm_role_assignment" "rbac_assigner" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_oidc.id

  depends_on = [azuread_service_principal.github_oidc]
}