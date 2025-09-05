# Outputs for Multi-Application Setup

# Output all application IDs and their purposes
output "multi_app_client_ids" {
  description = "Client IDs for all created Azure AD applications"
  value = {
    for app_key, app in azuread_application.github_oidc_multi : app_key => {
      client_id = app.client_id
      application_id = app.id
      display_name = app.display_name
      environments = local.needed_apps[app_key].environments
      branches = local.needed_apps[app_key].branches
      include_pr = local.needed_apps[app_key].include_pr
    }
  }
}

# Service Principal Object IDs  
output "multi_app_service_principal_object_ids" {
  description = "Service Principal Object IDs for all applications"
  value = {
    for app_key, sp in azuread_service_principal.github_oidc_multi : app_key => sp.id
  }
}

# Backend configuration for different repositories (updated for multi-app)
output "multi_app_backend_config" {
  description = "Backend configurations for each repository with appropriate client IDs"
  sensitive   = true
  value = {
    for repo in var.github_repo : repo => {
      resource_group_name  = var.resource_group_name
      storage_account_name = var.storage_account_name
      container_name       = lower(replace(replace(replace(repo, "[^a-zA-Z0-9-]", "-"), "--+", "-"), "^-|-$", ""))
      key                  = "terraform.tfstate"
      subscription_id      = var.subscription_id
      tenant_id           = var.tenant_id
      # For backend config, use the first available client ID (repos can use any app)
      client_id           = try(values(azuread_application.github_oidc_multi)[0].client_id, "")
    }
  }
}

# GitHub secrets for all applications (for repository secrets setup)
output "multi_app_github_secrets" {
  description = "GitHub secrets configuration for all applications"
  sensitive   = true
  value = {
    for app_key, app in azuread_application.github_oidc_multi : app_key => {
      ARM_CLIENT_ID       = app.client_id
      ARM_SUBSCRIPTION_ID = var.subscription_id
      ARM_TENANT_ID       = var.tenant_id
      environments        = local.needed_apps[app_key].environments
      branches           = local.needed_apps[app_key].branches
      description        = local.needed_apps[app_key].description
    }
  }
}

# Summary of the multi-app setup
output "multi_app_setup_summary" {
  description = "Summary of the multi-application setup"
  value = {
    total_applications = length(azuread_application.github_oidc_multi)
    applications = {
      for app_key, config in local.needed_apps : app_key => {
        name = "github-${var.github_owner}-terraform-${config.name_suffix}"
        purpose = config.description
        environments = config.environments
        branches = config.branches
        handles_pr = config.include_pr
        managed_environments = length(setintersection(var.environments, config.environments))
        managed_branches = length([for branch in var.branches : branch if contains(config.branches, branch)])
        handles_repos = length(var.github_repo)
      }
    }
    total_repositories = length(var.github_repo)
    repositories = var.github_repo
  }
}