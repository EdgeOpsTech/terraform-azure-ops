# RBAC assignments for multiple Azure AD applications
# Each application gets the same permissions to maintain consistency

# Role Assignment: Subscription Contributor (for all apps)
resource "azurerm_role_assignment" "sub_contributor_multi" {
  for_each = azuread_service_principal.github_oidc_multi
  
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = each.value.id

  depends_on = [azuread_service_principal.github_oidc_multi]
}

# Role Assignment: Storage Blob Data Contributor (for all apps)
resource "azurerm_role_assignment" "storage_blob_data_contributor_multi" {
  for_each = azuread_service_principal.github_oidc_multi
  
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.id

  depends_on = [azuread_service_principal.github_oidc_multi]
}

# Role Assignment: User Access Administrator (for RBAC operations, all apps)
resource "azurerm_role_assignment" "rbac_assigner_multi" {
  for_each = azuread_service_principal.github_oidc_multi
  
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator" 
  principal_id         = each.value.id

  depends_on = [azuread_service_principal.github_oidc_multi]
}