# Multi-App GitHub OIDC Configuration to handle 20 federated credential limit
# This approach creates multiple Azure AD applications based on environment groupings

locals {
  # Define environment-specific applications to handle 20 credential limit
  app_configs = {
    dev = {
      name_suffix  = "dev"
      environments = ["dev"]
      branches     = ["dev", "feature"]
      include_pr   = true
      description  = "Development workflows"
    }
    stage = {
      name_suffix  = "nonprod"
      environments = ["test", "stage"]
      branches     = ["release"]
      include_pr   = false
      description  = "Non-production workflows"
    }
    prod = {
      name_suffix  = "prod"
      environments = ["prod"]
      branches     = ["main"]
      include_pr   = false
      description  = "Production workflows"
    }
  }

  # Calculate which apps are needed based on current tfvars
  needed_apps = {
    for app_key, app_config in local.app_configs : app_key => app_config
    if(
      length(setintersection(var.environments, app_config.environments)) > 0 ||
      length([for branch in var.branches : branch if contains(app_config.branches, branch) || can(regex("${branch}/.*", "feature/test"))]) > 0 ||
      (var.pull_request && app_config.include_pr)
    )
  }

  # Simplified tracking - actual counts will be shown in outputs
  app_summary = {
    for app_key, app_config in local.needed_apps : app_key => {
      environments = app_config.environments
      branches     = app_config.branches
      include_pr   = app_config.include_pr
      description  = app_config.description
    }
  }
}

# Azure AD Applications for GitHub OIDC (environment-specific)
resource "azuread_application" "github_oidc_multi" {
  for_each = local.needed_apps

  display_name            = "github-${var.github_owner}-terraform-${each.value.name_suffix}"
  sign_in_audience        = "AzureADMyOrg"
  prevent_duplicate_names = false
  owners                  = [data.azuread_client_config.current.object_id]

  tags = ["github-actions", "oidc", "terraform", each.value.name_suffix]
}

# Service Principals for the Applications
resource "azuread_service_principal" "github_oidc_multi" {
  for_each = azuread_application.github_oidc_multi

  client_id                    = each.value.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  tags = ["github-actions", "oidc", "terraform", local.needed_apps[each.key].name_suffix]
}

# Federated Identity Credentials for Branches (distributed across apps)
resource "azuread_application_federated_identity_credential" "branches_multi" {
  for_each = {
    for combo in flatten([
      for app_key, app_config in local.needed_apps : [
        for repo in var.github_repo : [
          for branch in var.branches : {
            key     = "${app_key}-${repo}-${branch}"
            app_key = app_key
            repo    = repo
            branch  = branch
            } if(
            contains(app_config.branches, branch) || (
              branch == "feature/*" && contains(app_config.branches, "feature")
              ) || (
              branch == "release/*" && contains(app_config.branches, "release")
            )
          ) && !can(regex(".*\\*", branch)) # Exclude wildcard patterns
        ]
      ]
    ]) : combo.key => combo
  }

  application_id = azuread_application.github_oidc_multi[each.value.app_key].id
  display_name   = "github-${var.github_owner}-${each.value.app_key}-${each.value.repo}-branch-${each.value.branch}"
  description    = "GitHub federated identity for ${each.value.repo} branch ${each.value.branch} (${each.value.app_key} app)"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "repo:${var.github_owner}/${each.value.repo}:ref:refs/heads/${each.value.branch}"
}

# Federated Identity Credentials for Environments (distributed across apps)
resource "azuread_application_federated_identity_credential" "environments_multi" {
  for_each = {
    for combo in flatten([
      for app_key, app_config in local.needed_apps : [
        for repo in var.github_repo : [
          for env in setintersection(var.environments, app_config.environments) : {
            key     = "${app_key}-${repo}-${env}"
            app_key = app_key
            repo    = repo
            env     = env
          }
        ]
      ]
    ]) : combo.key => combo
  }

  application_id = azuread_application.github_oidc_multi[each.value.app_key].id
  display_name   = "github-${var.github_owner}-${each.value.app_key}-${each.value.repo}-env-${each.value.env}"
  description    = "GitHub federated identity for ${each.value.repo} environment ${each.value.env} (${each.value.app_key} app)"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "repo:${var.github_owner}/${each.value.repo}:environment:${each.value.env}"
}

# Federated Identity Credentials for Pull Requests (distributed across apps)
resource "azuread_application_federated_identity_credential" "pull_request_multi" {
  for_each = {
    for combo in flatten([
      for app_key, app_config in local.needed_apps : [
        for repo in var.github_repo : {
          key     = "${app_key}-${repo}-pr"
          app_key = app_key
          repo    = repo
        } if var.pull_request && app_config.include_pr
      ]
    ]) : combo.key => combo
  }

  application_id = azuread_application.github_oidc_multi[each.value.app_key].id
  display_name   = "github-${var.github_owner}-${each.value.app_key}-${each.value.repo}-pr"
  description    = "GitHub federated identity for ${each.value.repo} pull requests (${each.value.app_key} app)"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "repo:${var.github_owner}/${each.value.repo}:pull_request"
}

# Output which apps were created
output "created_applications" {
  description = "Applications created for different environment groups"
  value = {
    for app_key, app_config in local.needed_apps : app_key => {
      application_name = "github-${var.github_owner}-terraform-${app_config.name_suffix}"
      application_id   = azuread_application.github_oidc_multi[app_key].client_id
      environments     = app_config.environments
      branches         = app_config.branches
      description      = app_config.description
    }
  }
}
