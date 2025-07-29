############################################
# 0)  Providers are the same …             #
############################################

# ──────────────────────────────────────────
# 1) Microsoft Graph service-principal
# ──────────────────────────────────────────
data "azuread_service_principal" "msgraph" {
  application_id = "00000003-0000-0000-c000-000000000000"
}

# ──────────────────────────────────────────
# 2) Role GUIDs we need
# ──────────────────────────────────────────
locals {
  graph_roles = {
    DirectoryReadAll              = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
    ApplicationReadWriteAll       = "06da0dbc-49e2-44d2-8312-53f166ab848a"
    AppRoleAssignmentReadWriteAll = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"
  }
}

# ──────────────────────────────────────────
# 3) Assign them to the GitHub-OIDC SP
# ──────────────────────────────────────────
resource "azuread_app_role_assignment" "github_oidc_graph_perms" {
  for_each = local.graph_roles

  app_role_id         = each.value
  principal_object_id = azuread_service_principal.github_oidc.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
